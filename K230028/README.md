# K230028 작업분 DB 산출물

정보화실무협의회(council) 도메인 — **20개 테이블** + 관련 시퀀스 + 시드 + 검증/문서.

## 파일 구성 (11개)

| # | 파일 | 용도 |
|---|---|---|
| 00 | `00_drop_all.sql` | 재적용 시 정리 (테이블 + 시퀀스 DROP, 신규 환경 외 사용 금지) |
| 01 | `01_tables_ddl.sql` | 20 테이블 DDL (PK/제약/컬럼 COMMENT 330건 포함) |
| 02 | `02_sequences_ddl.sql` | 시퀀스 12개 (비즈니스 채번 2 + 감사로그 10) |
| 03 | `03_ccodem_seed.sql` | CCODEM 협의회 코드 (ASCT_STS_C/DBR_TC/VLR_TC/CKG_ITM_C/KPN_TC) |
| 04 | `04_user_seed.sql` | 테스트 사용자 14명 + 조직/권한 (비밀번호 `1q2w3e4r!`) |
| 05 | `05_verify.sql` | 적용 후 검증 (테이블 수/PK 명명/시드 카운트) |
| - | `90_data_model.md` | 데이터 모델 요약 (PK·도메인·외부 FK) |
| - | `91_change_log.md` | 본 작업 변경 이력 (RENAME/타입/순서/PK 명명 등) |
| - | `92_dependencies.md` | 외부 의존 테이블 (BPROJM/CAPPLM/CUSERI 등) |
| - | `MIGRATION_NOTES.md` | 기존 DB에 적용 시 마이그레이션 패턴 |
| - | `README.md` | 본 문서 |

## 대상 20 테이블

**Master/Child (10개)**: BASCTM, BCHKLM, BCMMTM, BEVALM, BMQNAM, BPERFM, BPOVWM, BPQNAM, BRSLTM, BSCHDM
**Log (10개)**: BASCTL, BCHKLL, BCMMTL, BEVALL, BMQNAL, BPERFL, BPOVWL, BPQNAL, BRSLTL, BSCHDL

## 적용 절차 (신규 환경)

```bash
cd C:\it\it_database\K230028
sqlplus ITPAPP/kdb1234!!@127.0.0.1:1521/XEPDB1
```
```sql
SQL> @00_drop_all.sql       -- 재적용 시만 (기존 데이터 손실)
SQL> @01_tables_ddl.sql
SQL> @02_sequences_ddl.sql
SQL> @03_ccodem_seed.sql
SQL> @04_user_seed.sql
SQL> @05_verify.sql         -- 검증
```

**사전 조건**: main 환경에 BPROJM/CAPPLM/CUSERI/CORGNI/CFILEM 등 외부 도메인이 이미 있어야 함 (→ `92_dependencies.md`)

## 적용 절차 (기존 환경 마이그레이션)

→ `MIGRATION_NOTES.md` 참조 (옛 컬럼 RENAME, 타입 변환, 컬럼 순서 재배치 패턴)

## 주요 정합 사항

→ `91_change_log.md` 참조. 요약:
- 컬럼명 메타 통일 (PRD_c_20260518 §1): 약 32건 RENAME
- 데이터타입 정합: 50건 + 공통 7컬럼 × 20 = 140건
- 컬럼 순서: PK → ABC → 공통 7
- PK 인덱스/제약 이름: `PK_{접미}` 표준 (22 RENAME)
- 테이블: `BCHKLC` → `BCHKLM`
- *L 공통 4컬럼 (LOG_SNO/CHG_TP/CHG_DTM/CHG_USID) 타입/comment 정합
- Q&A USID 통일 (BMQNAM/BMQNAL/BPQNAM/BPQNAL × QTN_USID/REP_USID)
