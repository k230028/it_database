-- V20260629_004__AddBrivgmCommentListIndex.sql
-- 문서 검토의견 목록 조회(findByDocMngNoAndDocVrsSnoAndDelYnOrderByFstEnrDtmAsc) 인덱스 (DB/JPA 최적화 P4 #10).
-- 필터: (DOC_MNG_NO, DOC_VRS_SNO, DEL_YN) 등치 + ORDER BY FST_ENR_DTM ASC.
-- 기존 IX_BRIVGM_DOC_DEL_FSG(DOC_MNG_NO, DEL_YN, FSG_YN)는 대시보드 EXISTS용 별개 인덱스로
-- DOC_VRS_SNO/FST_ENR_DTM 미포함 → 본 정렬을 커버하지 못함(검증 2026-06-29).
-- EXPLAIN 검증: cost 3→2 + SORT ORDER BY 제거(인덱스가 FST_ENR_DTM 순서로 행 반환).
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
    IF NOT idx_exists('IX_BRIVGM_DOC_VRS_DEL_FED') THEN
        EXECUTE IMMEDIATE 'CREATE INDEX IX_BRIVGM_DOC_VRS_DEL_FED ON TPRMPP_BRIVGM (DOC_MNG_NO, DOC_VRS_SNO, DEL_YN, FST_ENR_DTM)';
    END IF;
END;
/
