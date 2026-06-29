-- V20260629_003__AddBrdocmLatestVersionIndex.sql
-- 요구사항정의서 목록 최신버전 조회(findLatestVersionsAll) 인덱스 (DB/JPA 최적화 P4 #9).
-- 쿼리: DEL_YN='N' + 상관서브쿼리 MAX(DOC_VRS_SNO) per DOC_MNG_NO + ORDER BY FST_ENR_DTM DESC.
-- 물리 컬럼 검증(2026-06-29): 버전 컬럼은 DOC_VRS_SNO(NUMBER).
-- EXPLAIN 검증: cost 9→7, 상관 MAX 서브쿼리가 INDEX RANGE SCAN으로 해소(index-join 대체).
-- 가산형(추가만)·멱등.
DECLARE
    FUNCTION idx_exists(p_idx VARCHAR2) RETURN BOOLEAN IS
        n NUMBER;
    BEGIN
        SELECT COUNT(*) INTO n FROM ALL_INDEXES
         WHERE OWNER = SYS_CONTEXT('USERENV','CURRENT_SCHEMA')
           AND INDEX_NAME = p_idx;
        RETURN n > 0;
    END;
BEGIN
    IF NOT idx_exists('IX_BRDOCM_DEL_DOC_VRS_FED') THEN
        EXECUTE IMMEDIATE 'CREATE INDEX IX_BRDOCM_DEL_DOC_VRS_FED ON TPRMPP_BRDOCM (DEL_YN, DOC_MNG_NO, DOC_VRS_SNO, FST_ENR_DTM)';
    END IF;
END;
/
