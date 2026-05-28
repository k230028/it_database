# K230028 작업분 변경 이력

## 1. 컬럼명 정합 (PRD_c_20260518 §1 메타 통일)

### Master/Child 18개 테이블 — 32 RENAME
| 옛 접미어 → 새 접미어 | 예시 |
|---|---|
| `_STS` → `_STS_C` | BASCTM.ASCT_STS → ASCT_STS_C |
| `_TP` → `_TC` | DBR_TP → DBR_TC, VLR_TP → VLR_TC, KPN_TP → KPN_TC |
| `_PLC` → `_PLC_NM` | BASCTM.CNRC_PLC → CNRC_PLC_NM |
| `_OPNN` → `_OPNN_CONE` | BEVALM/BRSLTM CKG_OPNN/SYN_OPNN |
| `_NV` → `_NV_CONE` | BPERFM.GL_NV → GL_NV_CONE |
| `_MANR` → `_MANR_CONE` | BPERFM.MSM_MANR → MSM_MANR_CONE |
| `_TPM` → `_PTM_CONE` (오타 PTM 정정 + CONE) | BPERFM.MSM_TPM → MSM_PTM_CONE |
| `EDRT` → `EDRT_NM` | BPOVWM.EDRT → EDRT_NM |
| `NCS` → `NCS_CONE` | BPOVWM.NCS → NCS_CONE |
| `_BG` → `_BG_AMT` | BPOVWM.PRJ_BG → PRJ_BG_AMT |
| `_TRM` → `_TRM_CONE` | BPOVWM.PRJ_TRM → PRJ_TRM_CONE |
| `_EFF` → `_EFF_CONE` | BPOVWM.XPT_EFF → XPT_EFF_CONE |

### Q&A 4개 테이블
- `QTN_ENO` → `QTN_USID` (질의사용자ID)
- `REP_ENO` → `REP_USID` (답변사용자ID)

## 2. 데이터타입 정합 (50건)

| 패턴 | 변경 |
|---|---|
| `GUID_PRG_SNO` | NUMBER(22) → NUMBER(4) (CUSERI 기준) |
| `CKG_RCRD` | NUMBER(10) → NUMBER(5) |
| `_DT` (CNRC_DT/MSM_*_DT) | VARCHAR2(255 CHAR) → VARCHAR2(8 CHAR) |
| `DSD_TM` | VARCHAR2(10 CHAR) → VARCHAR2(6 CHAR) |
| NM/CLF | (60/100/255) 표준 |
| DES (PRJ_DES) | VARCHAR2(300 CHAR) |
| CONE | (20/100/300/600/2000/4000/8000) 표준 |

## 3. 공통 7컬럼 타입/comment 정합 (CUSERI 기준, 140건)
- DEL_YN VARCHAR2(1 BYTE)
- GUID VARCHAR2(38 BYTE)
- GUID_PRG_SNO NUMBER(4)
- FST_ENR_USID VARCHAR2(14 BYTE)
- FST_ENR_DTM DATE (TIMESTAMP(9)에서 변환)
- LST_CHG_USID VARCHAR2(14 BYTE)
- LST_CHG_DTM DATE

## 4. 컬럼 순서 정렬 (INVISIBLE/VISIBLE 토글)
- *M/*C 10개: PK → 일반 컬럼(ABC) → 공통 7
- *L 10개: 로그 4컬럼(LOG_SNO/CHG_TP/CHG_DTM/CHG_USID) → 대응 *M 순서 → 공통 7

## 5. PK 인덱스/제약 이름 표준화 (22 RENAME)
- `PK_TAAABB_*` → `PK_{접미}` (9개)
- `SYS_C00XXXX` → `PK_BMQNAM/PK_BMQNAL` (2개)

## 6. 테이블 RENAME
- `TPRMPP_BCHKLC` → `TPRMPP_BCHKLM` (마지막 글자 표준 M)
- 관련 시퀀스 `SEQ_BCHKLC` → 없음 → 신규 `SEQ_BCHKLM` 생성

## 7. *L 테이블 공통 4컬럼 정합 (CHG_TP/CHG_DTM/CHG_USID)
- CHG_TP VARCHAR2(4 CHAR) → VARCHAR2(1 BYTE), comment '변경유형'
- CHG_DTM TIMESTAMP(9) → DATE, comment '변경일시'
- CHG_USID VARCHAR2(56 CHAR) → VARCHAR2(14 BYTE), comment '변경사용자ID'
- LOG_SNO comment '로그일련번호'

## 8. CHG_TC 컬럼 DROP
- 메타 반영 시도(gonnabe88)에서 추가된 *L 24개 테이블의 CHG_TC 모두 DROP
- 코드 측은 CHG_TP 그대로 유지 (당분간 CHG_TP 사용 결정)

## 9. Q&A USID 길이 통일 (BMQNAM/BMQNAL/BPQNAM/BPQNAL × 2컬럼 = 8건)
- QTN_USID/REP_USID 모두 VARCHAR2(14 BYTE)
