-- V20260629_005__AddRealtimeLogFeedIndex.sql
-- 실시간 로그 피드(V_ITPAPP_LOG_FEED) 집계 보강 인덱스 (DB/JPA 최적화 P4 #11, 범위 재정의).
--
-- 계획 정정(2026-06-29): V_ITPAPP_LOG_FEED는 20개 *L 로그 테이블의 UNION ALL이라 단일 기반 테이블이
--   없으며, 단일 커버링 인덱스(IX_LOGFEED_CHGDTM_CURSOR)는 부적합하다. EXPLAIN 결과 20개 중 19개
--   테이블은 이미 IX_*_CHG_DTM (단일 컬럼 CHG_DTM) 인덱스를 보유해 5분/30분 집계가 INDEX (FAST) FULL
--   SCAN을 사용한다. 유일한 격차는 TPRMPP_CCODEL(CHG_DTM 인덱스 부재 → TABLE ACCESS FULL)이다.
--
-- 본 스크립트는 누락된 CCODEL에만 기존 19개 테이블과 동일한 (CHG_DTM) 인덱스를 추가해
--   집계 패턴을 대칭화한다. EXPLAIN 검증: 5분/30분 집계 cost 24→22
--   (CCODEL TABLE ACCESS FULL[cost 3] → INDEX FULL SCAN[cost 1]).
-- 참고: 피드 스냅샷(WHERE 없는 전체 + UNION 전역 WINDOW SORT) 경로는 어떤 인덱스로도 개선 불가하여 감내.
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
    IF NOT idx_exists('IX_CCODEL_CHG_DTM') THEN
        EXECUTE IMMEDIATE 'CREATE INDEX IX_CCODEL_CHG_DTM ON TPRMPP_CCODEL (CHG_DTM)';
    END IF;
END;
/
