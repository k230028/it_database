-- =====================================================================
-- 게시물ID(NAC_ID) 컬럼 폭 불일치 해소 (실제 저장값 기준 확대)
-- =====================================================================
-- 배경:
--   NAC_ID 는 그룹(원글) 식별자로 원글의 NAC_NO(VARCHAR2(16 CHAR))를 복사 저장한다.
--   (Cblbcm.initGroupAsRoot() → this.nacId = this.nacMngNo)
--   그러나 물리 컬럼이 VARCHAR2(10 CHAR)여서, NAC_NO 형식 'NAC-{YYYY}-{0001}'
--   (예: 'NAC-2026-0001' = 13자)을 저장할 때 ORA-12899(value too large)가 발생했다.
--   ddl-auto=update 는 기존 Oracle 컬럼 폭을 확대하지 않으므로 마이그레이션으로 보정한다.
--
--   1) TPRMPP_CBLBCM.NAC_ID  VARCHAR2(10) → VARCHAR2(16 CHAR)
--      게시물 마스터. 엔티티 Cblbcm.nacId 와 동일 폭(= NAC_NO 폭).
--   2) TPRMPP_CBLBCL.NAC_ID  VARCHAR2(10) → VARCHAR2(32 CHAR)
--      게시물 변경이력(감사로그) 미러. 엔티티 CblbcmL.nacId 선언 폭(32)에 맞춘다.
--
-- 멱등성: VARCHAR2 폭 확대 MODIFY 는 데이터 손실이 없고, 동일/더 큰 크기로
--         반복 실행해도 안전하다. (축소가 아니므로 ORA-01441 미발생)
-- =====================================================================

-- 1) 게시물 마스터
ALTER TABLE ITPAPP.TPRMPP_CBLBCM MODIFY ("NAC_ID" VARCHAR2(16 CHAR));

-- 2) 게시물 변경로그
ALTER TABLE ITPAPP.TPRMPP_CBLBCL MODIFY ("NAC_ID" VARCHAR2(32 CHAR));
