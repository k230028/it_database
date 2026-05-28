# 외부 의존 (사전 조건)

이 산출물(01~04)은 **20 테이블만 다루며**, 다음 외부 도메인은 main 환경에 미리 존재해야 합니다.

## 1. 사용자/조직/권한 (필수)
| 테이블 | 용도 |
|---|---|
| `TPRMPP_CUSERI` | 사용자 (FST_ENR_USID/LST_CHG_USID 참조, 로그인) |
| `TPRMPP_CORGNI` | 조직 (CUSERI.BBR_C 참조) |
| `TPRMPP_CROLEI` | 권한 매핑 |
| `TPRMPP_CAUTHI` | 자격등급 |

→ `04_user_seed.sql`로 council 작업용 테스트 계정 14명 추가 (MERGE 멱등)

## 2. 공통코드 (필수)
| 테이블 | 용도 |
|---|---|
| `TPRMPP_CCODEM` | 공통코드 (council 4 cId: ASCT_STS_C/DBR_TC/VLR_TC/CKG_ITM_C + KPN_TC) |
| `TPRMPP_CCODEL` | 공통코드 변경 로그 |

→ `03_ccodem_seed.sql`로 council 도메인 코드값 추가 (MERGE 멱등)

## 3. 사업/예산 (참조, 데이터는 별도)
| 테이블 | 참조 위치 |
|---|---|
| `TPRMPP_BPROJM` | BASCTM.PRJ_MNG_NO/PRJ_SNO |
| `TPRMPP_BITEMM` | (간접 — 예산 품목) |

→ 본 산출물에 시드 없음. main dump 또는 화면 신규 등록으로 확보.

## 4. 결재 (참조, 데이터는 별도)
| 테이블 | 참조 위치 |
|---|---|
| `TPRMPP_CAPPLM` | 협의회 결재 (CouncilApprovalService) |
| `TPRMPP_CAPPLA` | 결재 첨부 |

→ 시드 없음. main에서 결재 도메인 확보 필요.

## 5. 파일 (참조, 데이터는 별도)
| 테이블 | 참조 위치 |
|---|---|
| `TPRMPP_CFILEM` | BPOVWM.FL_MNG_NO, BRSLTM.FL_MNG_NO |

→ 시드 없음.

## 6. 알림 (옵션)
| 테이블 | 참조 위치 |
|---|---|
| `TPRMPP_CINFMM` | 협의회 통보/알림 발송 |

## 적용 순서 권장

```
1. main 환경 dump 적용 (CUSERI/CORGNI/CCODEM/BPROJM/CAPPLM/CFILEM 등 기본 스키마 + 데이터)
2. K230028 산출물 적용
   - @00_drop_all.sql       (재적용 시만)
   - @01_tables_ddl.sql
   - @02_sequences_ddl.sql
   - @03_ccodem_seed.sql    (council 4 cId 추가)
   - @04_user_seed.sql      (테스트 계정 보강)
   - @05_verify.sql         (검증)
3. 백엔드 재기동
```
