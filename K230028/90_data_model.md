# 데이터 모델 — 20 테이블 (council 도메인)

## 도메인 그룹

### 1. 협의회 마스터 (BASCTM)
- **TPRMPP_BASCTM** — 정보화실무협의회 마스터. PK: `ASCT_ID`
  - 형식 `ASCT-{YYYY}-{4자리}`. 채번 `SEQ_BASCTM`
  - 외부 FK: `PRJ_MNG_NO`/`PRJ_SNO` → BPROJM(외부 도메인)
  - 상태(`ASCT_STS_C`) 14단계: 001 작성중 ~ 013 완료 (CCODEM `ASCT_STS_C`)

### 2. 협의회 부속 테이블 (BASCTM 자식)
| 테이블 | PK | 의미 |
|---|---|---|
| TPRMPP_BCHKLM | ASCT_ID, CKG_ITM_C | 타당성 자체점검 항목별 결과 |
| TPRMPP_BCMMTM | ASCT_ID, ENO | 협의회 평가위원 (위원유형 VLR_TC: 001/002/003) |
| TPRMPP_BEVALM | ASCT_ID, CKG_ITM_C, ENO | 위원 평가의견 (위원별 × 항목별) |
| TPRMPP_BSCHDM | ASCT_ID, DSD_DT, DSD_TM, ENO | 일정 슬롯 응답 |
| TPRMPP_BPOVWM | ASCT_ID | 사업개요 + 타당성검토표 본문 |
| TPRMPP_BPERFM | ASCT_ID, DTP_SNO | 성과지표 |
| TPRMPP_BPQNAM | QTN_ID | 사전 Q&A (`QTN-{ASCT_ID}-{2자리}`) |
| TPRMPP_BMQNAM | QTN_ID | 주요 Q&A (`MQT-{ASCT_ID}-{2자리}`, SEQ_BMQNAL 채번) |
| TPRMPP_BRSLTM | ASCT_ID | 협의회 결과서 |

### 3. 로그 테이블 (10개) — *L
모든 *L 테이블: PK `LOG_SNO` (NUMBER), 시퀀스 `SEQ_*L`로 채번.
공통 4컬럼: LOG_SNO / CHG_TP / CHG_DTM / CHG_USID + 대응 *M 컬럼 + 공통 7컬럼.

## 공통 컬럼 (모든 20 테이블 마지막 7컬럼)

| 컬럼 | 타입 | 의미 |
|---|---|---|
| DEL_YN | VARCHAR2(1 BYTE) | 삭제여부 (Y/N) |
| GUID | VARCHAR2(38 BYTE) | GUID (SYS_GUID()) |
| GUID_PRG_SNO | NUMBER(4) | GUID진행일련번호 |
| FST_ENR_USID | VARCHAR2(14 BYTE) | 최초등록사용자ID |
| FST_ENR_DTM | DATE | 최초등록일시 |
| LST_CHG_USID | VARCHAR2(14 BYTE) | 최종변경사용자ID |
| LST_CHG_DTM | DATE | 최종변경일시 |

## CCODEM 의존 (외부 테이블이지만 시드 포함)

| C_ID | 건수 | 용도 |
|---|---|---|
| ASCT_STS_C | 13 | 협의회 상태 (BASCTM.ASCT_STS_C) |
| DBR_TC | 5 | 심의유형 (BASCTM.DBR_TC) |
| VLR_TC | 3 | 위원유형 (BCMMTM.VLR_TC) — 001 당연 / 002 소집 / 003 간사 |
| CKG_ITM_C | 6 | 점검항목 코드 (BCHKLM/BEVALM) |
| KPN_TC | 2 | 저장구분 (BPOVWM.KPN_TC) — 001 임시 / 002 완료 |

## 시퀀스

**비즈니스 채번 (2개)**: SEQ_BASCTM, SEQ_BCHKLM
**감사로그 채번 (10개)**: SEQ_B*L (각 *L 테이블당 1개)
**미사용 (8개)**: SEQ_B*M 중 PK가 외부값을 따르는 테이블은 시퀀스 없음
