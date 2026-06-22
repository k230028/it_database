-- V20260622_007__DropBprojmPlannedAmtColumns.sql
-- 정보화사업(TPRMPP_BPROJM) 및 로그(TPRMPP_BPROJL)에서 합계성 금액 3종 삭제.
--   TOT_RQM_AMT / MPL_CPIT_AMT / MPL_MNGC_AMT
-- 사유: 프로젝트 단위 저장값을 품목(BITEMM.MPL_AMT) 합산 파생값으로 대체.
-- 멱등성: 컬럼 존재 시에만 DROP.
DECLARE
    FUNCTION col_exists(p_table VARCHAR2, p_col VARCHAR2) RETURN BOOLEAN IS
        n NUMBER;
    BEGIN
        SELECT COUNT(*) INTO n FROM ALL_TAB_COLS
         WHERE OWNER = SYS_CONTEXT('USERENV','CURRENT_SCHEMA')
           AND TABLE_NAME = p_table AND COLUMN_NAME = p_col;
        RETURN n > 0;
    END;
    PROCEDURE drop_col(p_table VARCHAR2, p_col VARCHAR2) IS
    BEGIN
        IF col_exists(p_table, p_col) THEN
            EXECUTE IMMEDIATE 'ALTER TABLE ' || p_table || ' DROP COLUMN ' || p_col;
        END IF;
    END;
BEGIN
    drop_col('TPRMPP_BPROJM', 'TOT_RQM_AMT');
    drop_col('TPRMPP_BPROJM', 'MPL_CPIT_AMT');
    drop_col('TPRMPP_BPROJM', 'MPL_MNGC_AMT');
    drop_col('TPRMPP_BPROJL', 'TOT_RQM_AMT');
    drop_col('TPRMPP_BPROJL', 'MPL_CPIT_AMT');
    drop_col('TPRMPP_BPROJL', 'MPL_MNGC_AMT');
END;
/
