-- =============================================================================
-- V20260623_004__FixRprStsCodeTo2Digit.sql
-- IT_PTL_RPR_STS_TC(보고상태) 공통코드 CDVA_ID를 구 3자리(001~999) → 표준 2자리(01~99)로 정정.
--
-- [배경]
--   저장 컬럼 ITPOWN.TPRMPP_BPROJM/BPROJL.IT_PTL_RPR_STS_TC 는 VARCHAR2(2 CHAR)이고
--   엔티티(Bprojm/BprojmL)도 length=2 "공통코드 2자리"로 선언되어 있다.
--   그러나 공통코드 마스터(TPRMPP_CCODEM)의 해당 그룹 CDVA_ID만 구 3자리 형식으로 남아 있어,
--   드롭다운이 '005' 같은 3자리 값을 전송 → 사업 저장(PUT) 시 BPROJL INSERT에서
--   ORA-12899("값이 너무 큼: 실제 3, 최대 2")가 발생했다.
--   형제 그룹(IT_PTL_ASCT_*, IT_PTL_EDRT_TC 등)은 모두 2자리가 표준이며,
--   기존 적재값도 '05'(2자리)로 이미 2자리 규약을 따르고 있었다.
--
-- [매핑] CDVA_NM 등 나머지 컬럼은 보존(UPDATE만 수행)
--   001 → 01 (이사회)
--   002 → 02 (회장)
--   003 → 03 (전무이사)
--   004 → 04 (부문(본부)장)
--   005 → 05 (부서장)
--   999 → 99 (기타)
--
-- [효과] 코드 정정 후 기존 적재값 '05'가 마스터와 정상 조인되어 보고상태명이 표시된다.
--        별도 업무데이터 백필은 불필요(기존 저장값은 이미 2자리).
--
-- [멱등] 구 3자리 행이 없으면 각 UPDATE는 0건 처리된다. 재실행 안전.
-- 소유 스키마 ITPOWN. PK = (CO_C_ID_NM, CDVA_ID, STT_DT).
-- =============================================================================

UPDATE ITPOWN.TPRMPP_CCODEM SET CDVA_ID = '01' WHERE CO_C_ID_NM = 'IT_PTL_RPR_STS_TC' AND CDVA_ID = '001';
UPDATE ITPOWN.TPRMPP_CCODEM SET CDVA_ID = '02' WHERE CO_C_ID_NM = 'IT_PTL_RPR_STS_TC' AND CDVA_ID = '002';
UPDATE ITPOWN.TPRMPP_CCODEM SET CDVA_ID = '03' WHERE CO_C_ID_NM = 'IT_PTL_RPR_STS_TC' AND CDVA_ID = '003';
UPDATE ITPOWN.TPRMPP_CCODEM SET CDVA_ID = '04' WHERE CO_C_ID_NM = 'IT_PTL_RPR_STS_TC' AND CDVA_ID = '004';
UPDATE ITPOWN.TPRMPP_CCODEM SET CDVA_ID = '05' WHERE CO_C_ID_NM = 'IT_PTL_RPR_STS_TC' AND CDVA_ID = '005';
UPDATE ITPOWN.TPRMPP_CCODEM SET CDVA_ID = '99' WHERE CO_C_ID_NM = 'IT_PTL_RPR_STS_TC' AND CDVA_ID = '999';
