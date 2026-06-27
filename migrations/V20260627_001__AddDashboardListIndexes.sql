-- V20260627_001__AddDashboardListIndexes.sql
-- 결재 대기/대시보드(CDECIM/CAPPLM)·요구사항 대시보드(BRDOCM/BRIVGM) 목록·집계 쿼리용 인덱스.
-- 가산형(추가만) 변경이며 멱등성: 동일 인덱스명 존재 시 생성을 건너뛴다.
-- 컬럼은 실제 쿼리 술어 기준 (ApplicationRepository / ServiceRequestDocRepository 대조, 2026-06-27).
--   CDECIM : 결재대기 조인/필터 d.DCR_ENO=:eno AND d.DCD_STS_C='1' (+조인키 APF_DCM_NO)
--   CAPPLM : 기안자 기준 진행중/반려/월별 a.DCD_REQ_USID + a.APF_PRG_STS_C + a.DCD_REQ_DTM
--   BRDOCM : 대시보드 조인 b.FST_ENR_USID=u.ENO + b.DEL_YN='N'
--   BRIVGM : 미해결 검토의견 EXISTS r.DOC_MNG_NO + r.DEL_YN + r.FSG_YN
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
    IF NOT idx_exists('IX_CDECIM_PENDING') THEN
        EXECUTE IMMEDIATE 'CREATE INDEX IX_CDECIM_PENDING ON TPRMPP_CDECIM (DCR_ENO, DCD_STS_C, APF_DCM_NO)';
    END IF;
    IF NOT idx_exists('IX_CAPPLM_USER_STS') THEN
        EXECUTE IMMEDIATE 'CREATE INDEX IX_CAPPLM_USER_STS ON TPRMPP_CAPPLM (DCD_REQ_USID, APF_PRG_STS_C, DCD_REQ_DTM)';
    END IF;
    IF NOT idx_exists('IX_BRDOCM_ENR_DEL') THEN
        EXECUTE IMMEDIATE 'CREATE INDEX IX_BRDOCM_ENR_DEL ON TPRMPP_BRDOCM (FST_ENR_USID, DEL_YN)';
    END IF;
    IF NOT idx_exists('IX_BRIVGM_DOC_DEL_FSG') THEN
        EXECUTE IMMEDIATE 'CREATE INDEX IX_BRIVGM_DOC_DEL_FSG ON TPRMPP_BRIVGM (DOC_MNG_NO, DEL_YN, FSG_YN)';
    END IF;
END;
/
