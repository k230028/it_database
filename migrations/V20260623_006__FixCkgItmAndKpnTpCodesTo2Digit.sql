-- =============================================================================
-- V20260623_006__FixCkgItmAndKpnTpCodesTo2Digit.sql
-- IT_PTL_CKG_ITM_TC(점검항목)·KPN_TP_TC(저장구분) 공통코드 CDVA_ID를
-- 구 3자리(001~) → 표준 2자리(01~)로 정정.
--
-- [배경]
--   V20260623_004(IT_PTL_RPR_STS_TC)·V20260623_005(IT_PTL_TCHN_TP_TC)와 동일한 자릿수 불일치.
--   아래 컬럼은 모두 VARCHAR2(2 CHAR)인데 마스터(TPRMPP_CCODEM) CDVA_ID만 3자리로 남아,
--   해당 화면 저장 시 ORA-12899("값이 너무 큼: 실제 3, 최대 2")가 발생할 수 있다.
--     IT_PTL_CKG_ITM_TC → TPRMPP_BCHKLM/BCHKLL, TPRMPP_BEVALM/BEVALL (점검·평가)
--     KPN_TP_TC         → TPRMPP_BPOVWM/BPOVWL (개요)
--
-- [적재 데이터 확인] CKG_ITM 적재행 0건(고아 없음), KPN_TP 적재값 '02'(이미 2자리) — 방향 일치.
--
-- [매핑] CDVA_NM 등 나머지 컬럼은 보존(UPDATE만 수행)
--   IT_PTL_CKG_ITM_TC: 001→01(경영전략 부합성) 002→02(재무적 효과) 003→03(리스크 영향도)
--                      004→04(평판 영향도) 005→05(중복 시스템 여부) 006→06(기타)
--   KPN_TP_TC        : 001→01(임시저장) 002→02(저장)
--
-- [멱등] 구 3자리 행이 없으면 각 UPDATE는 0건 처리된다. 재실행 안전.
-- 소유 스키마 ITPOWN. PK = (CO_C_ID_NM, CDVA_ID, STT_DT).
-- =============================================================================

-- IT_PTL_CKG_ITM_TC (점검항목)
UPDATE ITPOWN.TPRMPP_CCODEM SET CDVA_ID = '01' WHERE CO_C_ID_NM = 'IT_PTL_CKG_ITM_TC' AND CDVA_ID = '001';
UPDATE ITPOWN.TPRMPP_CCODEM SET CDVA_ID = '02' WHERE CO_C_ID_NM = 'IT_PTL_CKG_ITM_TC' AND CDVA_ID = '002';
UPDATE ITPOWN.TPRMPP_CCODEM SET CDVA_ID = '03' WHERE CO_C_ID_NM = 'IT_PTL_CKG_ITM_TC' AND CDVA_ID = '003';
UPDATE ITPOWN.TPRMPP_CCODEM SET CDVA_ID = '04' WHERE CO_C_ID_NM = 'IT_PTL_CKG_ITM_TC' AND CDVA_ID = '004';
UPDATE ITPOWN.TPRMPP_CCODEM SET CDVA_ID = '05' WHERE CO_C_ID_NM = 'IT_PTL_CKG_ITM_TC' AND CDVA_ID = '005';
UPDATE ITPOWN.TPRMPP_CCODEM SET CDVA_ID = '06' WHERE CO_C_ID_NM = 'IT_PTL_CKG_ITM_TC' AND CDVA_ID = '006';

-- KPN_TP_TC (저장구분)
UPDATE ITPOWN.TPRMPP_CCODEM SET CDVA_ID = '01' WHERE CO_C_ID_NM = 'KPN_TP_TC' AND CDVA_ID = '001';
UPDATE ITPOWN.TPRMPP_CCODEM SET CDVA_ID = '02' WHERE CO_C_ID_NM = 'KPN_TP_TC' AND CDVA_ID = '002';
