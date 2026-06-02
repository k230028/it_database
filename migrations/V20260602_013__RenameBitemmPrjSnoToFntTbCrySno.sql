-- =====================================================================
-- V20260602_013 BITEMM 품목 컬럼 메타 정합화
-- PRJ_SNO(사업일련번호) → FNT_TB_CRY_SNO(원천테이블적재일련번호, NUMBER(10), 메타등록)
-- 대상: TPRMPP_BITEMM(마스터), TPRMPP_BITEML(변경로그)
--   ※ Java 필드명(prjSno)은 유지(컬럼 매핑만 변경) — 품목↔사업 연관 쿼리 영향 없음
--   ※ 변경로그 복사는 컬럼명 기준이므로 마스터/로그 컬럼명을 함께 변경
-- 멱등: 존재 여부 확인 후 수행
-- =====================================================================

-- 1) 마스터 BITEMM
DECLARE v NUMBER; BEGIN
  SELECT COUNT(*) INTO v FROM user_tab_columns WHERE table_name='TPRMPP_BITEMM' AND column_name='PRJ_SNO';
  IF v > 0 THEN EXECUTE IMMEDIATE 'ALTER TABLE "TPRMPP_BITEMM" RENAME COLUMN "PRJ_SNO" TO "FNT_TB_CRY_SNO"'; END IF;
END;
/
DECLARE v NUMBER; BEGIN
  SELECT COUNT(*) INTO v FROM user_tab_columns WHERE table_name='TPRMPP_BITEMM' AND column_name='FNT_TB_CRY_SNO';
  IF v > 0 THEN EXECUTE IMMEDIATE 'ALTER TABLE "TPRMPP_BITEMM" MODIFY ("FNT_TB_CRY_SNO" NUMBER(10,0))'; END IF;
END;
/
COMMENT ON COLUMN "TPRMPP_BITEMM"."FNT_TB_CRY_SNO" IS '원천테이블적재일련번호';

-- 2) 변경로그 BITEML
DECLARE v NUMBER; BEGIN
  SELECT COUNT(*) INTO v FROM user_tab_columns WHERE table_name='TPRMPP_BITEML' AND column_name='PRJ_SNO';
  IF v > 0 THEN EXECUTE IMMEDIATE 'ALTER TABLE "TPRMPP_BITEML" RENAME COLUMN "PRJ_SNO" TO "FNT_TB_CRY_SNO"'; END IF;
END;
/
DECLARE v NUMBER; BEGIN
  SELECT COUNT(*) INTO v FROM user_tab_columns WHERE table_name='TPRMPP_BITEML' AND column_name='FNT_TB_CRY_SNO';
  IF v > 0 THEN EXECUTE IMMEDIATE 'ALTER TABLE "TPRMPP_BITEML" MODIFY ("FNT_TB_CRY_SNO" NUMBER(10,0))'; END IF;
END;
/
COMMENT ON COLUMN "TPRMPP_BITEML"."FNT_TB_CRY_SNO" IS '원천테이블적재일련번호';

-- 3) 인덱스명 정합화 (컬럼 RENAME 후 인덱스 정의는 자동 추종, 인덱스명만 갱신)
DECLARE v NUMBER; BEGIN
  SELECT COUNT(*) INTO v FROM user_indexes WHERE index_name='IX_BITEMM_ABUS_MNG_NO_PRJ_SNO_DEL_YN_LST_YN';
  IF v > 0 THEN EXECUTE IMMEDIATE 'ALTER INDEX "IX_BITEMM_ABUS_MNG_NO_PRJ_SNO_DEL_YN_LST_YN" RENAME TO "IX_BITEMM_ABUS_MNG_NO_FNT_TB_CRY_SNO_DEL_YN_LST_YN"'; END IF;
END;
/

COMMIT;
