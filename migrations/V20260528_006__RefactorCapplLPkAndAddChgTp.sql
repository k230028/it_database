-- ============================================================
-- TPRMPP_CAPPLL 구조 변경
--
-- 1. PK 컬럼 LOG_SNO → LOG_HIS_TGR_SNO 이름 변경
--    (로그이력전문일련번호, NUMBER(9) → NUMBER(18) 타입 확장)
-- 참고: CHG_TP → CHG_DTT_YN 변경은 V20260528_005에서 적용됨
-- ============================================================

-- 1) PK 컬럼 이름 변경 (Oracle: PK 제약 유지된 채 RENAME 가능)
ALTER TABLE TPRMPP_CAPPLL RENAME COLUMN LOG_SNO TO LOG_HIS_TGR_SNO;

-- 2) NUMBER(9) → NUMBER(18) 타입 확장 (기존 데이터 범위 포함, 안전)
ALTER TABLE TPRMPP_CAPPLL MODIFY LOG_HIS_TGR_SNO NUMBER(18, 0);
