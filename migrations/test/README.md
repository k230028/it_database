# 표준명칭 마이그레이션 검증 하네스

`docs/meta-compliance-report.md` 기반으로 생성되는 컬럼 표준화 마이그레이션을
**운영/개발 데이터를 건드리지 않고** 격리 스키마 `ITPAPP_TEST`에서 검증한다.

## 실행

```bash
# 루트(C:\it)에서
bash it_database/migrations/test/run_test.sh
```

기대 결과: `PASS=12  FAIL=0  / RESULT: ALL PASS`

정리(테스트 스키마 삭제):
```bash
"/c/app/KDB/product/21c/dbhomeXE/bin/sqlplus.exe" -S ITPAPP/'kdb1234!!'@127.0.0.1:1521/XEPDB1 @it_database/migrations/test/99_teardown.sql
```

## 구성

| 파일 | 실행 계정 | 역할 |
|------|----------|------|
| `01_setup.sql` | ITPAPP | `ITPAPP_TEST` 유저 생성 + 모든 `TPRMPP_*` 구조 복제(데이터/제약 제외) |
| `02_seed.sql` | ITPAPP_TEST | NOT NULL 해제 후 엣지케이스 행 시드 |
| `03_assert.sql` | ITPAPP_TEST | 12개 검증(PASS/FAIL 출력) |
| `99_teardown.sql` | ITPAPP | 테스트 스키마 삭제 |
| `run_test.sh` | - | 1~5 단계 일괄 실행 |

## 검증 항목 (12)

| # | 시나리오 | 대상 |
|---|---------|------|
| 1~2 | 단순 rename + VARCHAR2 길이정규화 | ABUS_C→BG_UNT_ABUS_C(3) |
| 3 | 패딩 자동 trim(길이 초과분만) | `'1     '`→`'1'` |
| 4 | 길이정규화(축소) | IT_MNGC_NO→BG_NO(15) |
| 5 | 길이축소 오버플로우 → MODIFY 보류(값 보존) | PUL_DTT→ABUS_TC(2), `'ABC'` 유지 |
| 6 | 타입만 변환 DATE→VARCHAR2(8) 값변환 | FST_DFR_DT=20260115 |
| 7 | 타입변경 rename VARCHAR2→NUMBER 값변환 | CMMT_MNG_NO→CMMT_SNO=12345 |
| 8 | 타입변경 rename DATE→VARCHAR2(8) | FSG_TLM→RVW_FSG_TLM_DT=20260201 |
| 9 | 진짜 충돌(양쪽 데이터) → 보류(미변경) | BITEMM GCL_SNO/PRJ_SNO 유지, SNO 미생성 |
| 10 | 빈 중복 해소(한쪽 NULL) | BRIVGM IDC_ID→RFR_ID, MARK_ID drop |
| 11 | 빈 중복 해소 | CBLBCL END_DT→END_DTM, END_YMD drop |
| 12 | 컬럼 drop | CBLBCM.KD_C |
