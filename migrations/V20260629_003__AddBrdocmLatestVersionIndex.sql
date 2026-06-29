-- V20260629_003__AddBrdocmLatestVersionIndex.sql
-- 요구사항정의서 목록 최신버전 조회(findLatestVersionsAll) 인덱스 (DB/JPA 최적화 P4 #9).
-- 쿼리: DEL_YN='N' + 상관서브쿼리 MAX(DOC_VRS_SNO) per DOC_MNG_NO + ORDER BY FST_ENR_DTM DESC.
-- 물리 컬럼 검증(2026-06-29): 버전 컬럼은 DOC_VRS_SNO(NUMBER).
-- EXPLAIN 검증(2026-06-29): cost 9→7. 인덱스는 상관 서브쿼리 MAX(DOC_VRS_SNO)를
--   (DEL_YN, DOC_MNG_NO, DOC_VRS_SNO) 선두 컬럼 기반 INDEX RANGE SCAN으로 해소한다(기존 index-join 대체).
--   단, 외부 쿼리의 ORDER BY FST_ENR_DTM DESC SORT는 제거되지 않는다 — 외부가 SELECT * 라
--   테이블 페치가 필요하고(소규모 행수), 옵티마이저가 별도 SORT ORDER BY를 유지한다.
--   FST_ENR_DTM은 향후 커버링 활용 여지를 위해 후행 컬럼으로 포함했을 뿐, 본 시점 정렬 제거 효과는 없다.
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
