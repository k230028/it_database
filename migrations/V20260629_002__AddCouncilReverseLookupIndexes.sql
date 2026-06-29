-- V20260629_002__AddCouncilReverseLookupIndexes.sql
-- 협의회 목록 역방향 조회(BASCTM/BCMMTM) 인덱스 (DB/JPA 최적화 P4 #8).
--   findByDepartment    : BPROJM→BASCTM 조인 a.ABUS_MNG_NO=p.ABUS_MNG_NO AND a.SNO=p.SNO, a.DEL_YN='N'
--   findByCommitteeMember: BCMMTM→BASCTM 조인 c.IT_PTL_ASCT_ID, 필터 c.ENO=:eno AND c.DEL_YN='N'
-- 물리 컬럼 검증(2026-06-29): BASCTM(ABUS_MNG_NO, SNO, DEL_YN), BCMMTM(ENO, DEL_YN, IT_PTL_ASCT_ID).
-- EXPLAIN 검증: #8 Q1 cost 5→4(FULL SCAN→INDEX SKIP SCAN), Q2 cost 4→3(단일 range scan 커버).
-- 가산형(추가만)·멱등: 동일 인덱스명 존재 시 생성을 건너뛴다.
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
    IF NOT idx_exists('IX_BASCTM_PRJ_DEL') THEN
        EXECUTE IMMEDIATE 'CREATE INDEX IX_BASCTM_PRJ_DEL ON TPRMPP_BASCTM (ABUS_MNG_NO, SNO, DEL_YN)';
    END IF;
    IF NOT idx_exists('IX_BCMMTM_ENO_DEL_ASCT') THEN
        EXECUTE IMMEDIATE 'CREATE INDEX IX_BCMMTM_ENO_DEL_ASCT ON TPRMPP_BCMMTM (ENO, DEL_YN, IT_PTL_ASCT_ID)';
    END IF;
END;
/
