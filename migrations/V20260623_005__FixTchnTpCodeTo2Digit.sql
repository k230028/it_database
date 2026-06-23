-- =============================================================================
-- V20260623_005__FixTchnTpCodeTo2Digit.sql
-- IT_PTL_TCHN_TP_TC(기술유형) 공통코드 CDVA_ID를 구 3자리(001~999) → 표준 2자리(01~99)로 정정.
--
-- [배경]
--   V20260623_004(IT_PTL_RPR_STS_TC)와 동일한 자릿수 불일치 사례.
--   저장 컬럼 ITPOWN.TPRMPP_BPROJM/BPROJL.IT_PTL_TCHN_TP_TC 는 VARCHAR2(2 CHAR)이고
--   엔티티도 2자리 규약이나, 공통코드 마스터(TPRMPP_CCODEM)의 해당 그룹 CDVA_ID만
--   구 3자리 형식으로 남아 있어, 드롭다운이 '002' 같은 3자리 값을 전송 → 사업 저장(PUT) 시
--   BPROJL INSERT에서 ORA-12899("값이 너무 큼: 실제 3, 최대 2")가 발생했다.
--   기존 적재값은 이미 '01'/'99'(2자리)로 2자리 규약을 따르고 있었다.
--
-- [매핑] CDVA_NM 등 나머지 컬럼은 보존(UPDATE만 수행)
--   001 → 01 (빅데이터)
--   002 → 02 (AI)
--   003 → 03 (클라우드)
--   004 → 04 (블록체인)
--   005 → 05 (플랫폼)
--   006 → 06 (핀테크)
--   999 → 99 (기타)
--
-- [효과] 코드 정정 후 기존 적재값('01' 등)이 마스터와 정상 조인된다. 업무데이터 백필 불필요.
-- [멱등] 구 3자리 행이 없으면 각 UPDATE는 0건 처리된다. 재실행 안전.
-- 소유 스키마 ITPOWN. PK = (CO_C_ID_NM, CDVA_ID, STT_DT).
-- =============================================================================

UPDATE ITPOWN.TPRMPP_CCODEM SET CDVA_ID = '01' WHERE CO_C_ID_NM = 'IT_PTL_TCHN_TP_TC' AND CDVA_ID = '001';
UPDATE ITPOWN.TPRMPP_CCODEM SET CDVA_ID = '02' WHERE CO_C_ID_NM = 'IT_PTL_TCHN_TP_TC' AND CDVA_ID = '002';
UPDATE ITPOWN.TPRMPP_CCODEM SET CDVA_ID = '03' WHERE CO_C_ID_NM = 'IT_PTL_TCHN_TP_TC' AND CDVA_ID = '003';
UPDATE ITPOWN.TPRMPP_CCODEM SET CDVA_ID = '04' WHERE CO_C_ID_NM = 'IT_PTL_TCHN_TP_TC' AND CDVA_ID = '004';
UPDATE ITPOWN.TPRMPP_CCODEM SET CDVA_ID = '05' WHERE CO_C_ID_NM = 'IT_PTL_TCHN_TP_TC' AND CDVA_ID = '005';
UPDATE ITPOWN.TPRMPP_CCODEM SET CDVA_ID = '06' WHERE CO_C_ID_NM = 'IT_PTL_TCHN_TP_TC' AND CDVA_ID = '006';
UPDATE ITPOWN.TPRMPP_CCODEM SET CDVA_ID = '99' WHERE CO_C_ID_NM = 'IT_PTL_TCHN_TP_TC' AND CDVA_ID = '999';
