-- ============================================================
-- TPRMPP_CAPPLL: CHG_TP 컬럼 → CHG_DTT_YN 으로 변경
-- 변경구분여부(CHG_DTT_YN)는 공통신청서기본변경로그 테이블에서
-- BaseLogEntity의 CHG_TP(변경유형구분코드) 대신 사용되는 컬럼명입니다.
-- ============================================================

ALTER TABLE TPRMPP_CAPPLL RENAME COLUMN CHG_TP TO CHG_DTT_YN;
