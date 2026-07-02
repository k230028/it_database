-- =============================================================================
-- V20260702_001__RenameBaskpmApprovalColumn.sql
-- BASKPM/BASKPL 전자결재 식별번호 컬럼명을 공통 결재 테이블과 동일하게 정리합니다.
--
--  - 기존: APF_MNG_NO
--  - 변경: APF_DCM_NO
--  - 기준: CAPPLM, CAPPLA, CDECIM 모두 신청서식별번호 물리 컬럼으로 APF_DCM_NO를 사용합니다.
-- =============================================================================

DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO v_count
      FROM ALL_TAB_COLUMNS
     WHERE OWNER = 'ITPOWN'
       AND TABLE_NAME = 'TPRMPP_BASKPM'
       AND COLUMN_NAME = 'APF_MNG_NO';

    IF v_count > 0 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE ITPOWN.TPRMPP_BASKPM RENAME COLUMN APF_MNG_NO TO APF_DCM_NO';
    END IF;

    EXECUTE IMMEDIATE 'ALTER TABLE ITPOWN.TPRMPP_BASKPM MODIFY (APF_DCM_NO VARCHAR2(64 CHAR))';
    EXECUTE IMMEDIATE q'[COMMENT ON COLUMN ITPOWN.TPRMPP_BASKPM.APF_DCM_NO IS '신청서식별번호(전자결재)']';
END;
/

DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO v_count
      FROM ALL_TAB_COLUMNS
     WHERE OWNER = 'ITPOWN'
       AND TABLE_NAME = 'TPRMPP_BASKPL'
       AND COLUMN_NAME = 'APF_MNG_NO';

    IF v_count > 0 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE ITPOWN.TPRMPP_BASKPL RENAME COLUMN APF_MNG_NO TO APF_DCM_NO';
    END IF;

    EXECUTE IMMEDIATE 'ALTER TABLE ITPOWN.TPRMPP_BASKPL MODIFY (APF_DCM_NO VARCHAR2(64 CHAR))';
    EXECUTE IMMEDIATE q'[COMMENT ON COLUMN ITPOWN.TPRMPP_BASKPL.APF_DCM_NO IS '신청서식별번호(전자결재)']';
END;
/

COMMIT;
