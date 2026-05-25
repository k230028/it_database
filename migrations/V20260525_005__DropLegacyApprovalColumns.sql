-- =====================================================================
-- V20260525_005__DropLegacyApprovalColumns.sql
--
-- Legacy 라벨 컬럼 제거 (코드 컬럼으로 전면 전환 완료):
--   - TPRMPP_CAPPLM.APF_STS  → APF_STS_C 단일 운영
--   - TPRMPP_CDECIM.DCD_TP   → 결재 행위 여부는 DCD_STS_C로 판단
--   - TPRMPP_CDECIM.DCD_STS  → DCD_STS_C 단일 운영
--
-- 사전 조건: V20260525_001~004 까지의 코드 컬럼 백필이 완료되어 있어야 함.
-- 본 스크립트는 멱등성을 위해 컬럼 존재 시에만 DROP 수행.
-- =====================================================================

-- 1. TPRMPP_CAPPLM.APF_STS 제거
DECLARE
  v_cnt NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_cnt
    FROM user_tab_columns
   WHERE table_name = 'TPRMPP_CAPPLM' AND column_name = 'APF_STS';
  IF v_cnt > 0 THEN
    EXECUTE IMMEDIATE 'ALTER TABLE TPRMPP_CAPPLM DROP COLUMN APF_STS';
  END IF;
END;
/

-- 2. TPRMPP_CDECIM.DCD_TP 제거
DECLARE
  v_cnt NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_cnt
    FROM user_tab_columns
   WHERE table_name = 'TPRMPP_CDECIM' AND column_name = 'DCD_TP';
  IF v_cnt > 0 THEN
    EXECUTE IMMEDIATE 'ALTER TABLE TPRMPP_CDECIM DROP COLUMN DCD_TP';
  END IF;
END;
/

-- 3. TPRMPP_CDECIM.DCD_STS 제거
DECLARE
  v_cnt NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_cnt
    FROM user_tab_columns
   WHERE table_name = 'TPRMPP_CDECIM' AND column_name = 'DCD_STS';
  IF v_cnt > 0 THEN
    EXECUTE IMMEDIATE 'ALTER TABLE TPRMPP_CDECIM DROP COLUMN DCD_STS';
  END IF;
END;
/
