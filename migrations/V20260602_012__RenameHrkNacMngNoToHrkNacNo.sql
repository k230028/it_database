-- =====================================================================
-- V20260602_012 상위게시물 참조 컬럼 메타 정합화
-- HRK_NAC_MNG_NO(미등록) → HRK_NAC_NO(상위게시물번호, 메타등록) VARCHAR2(16)
-- 대상: TPRMPP_CBLBCM(마스터), TPRMPP_CBLBCL(변경로그)
--   ※ 변경로그 복사는 컬럼명 기준이므로 마스터/로그 컬럼명을 함께 변경
-- 멱등: 존재 여부 확인 후 수행
-- =====================================================================

-- 1) 마스터 CBLBCM : 컬럼명 변경 → 타입 축소 → 코멘트
DECLARE v NUMBER; BEGIN
  SELECT COUNT(*) INTO v FROM user_tab_columns WHERE table_name='TPRMPP_CBLBCM' AND column_name='HRK_NAC_MNG_NO';
  IF v > 0 THEN EXECUTE IMMEDIATE 'ALTER TABLE "TPRMPP_CBLBCM" RENAME COLUMN "HRK_NAC_MNG_NO" TO "HRK_NAC_NO"'; END IF;
END;
/
DECLARE v NUMBER; BEGIN
  SELECT COUNT(*) INTO v FROM user_tab_columns WHERE table_name='TPRMPP_CBLBCM' AND column_name='HRK_NAC_NO';
  IF v > 0 THEN EXECUTE IMMEDIATE 'ALTER TABLE "TPRMPP_CBLBCM" MODIFY ("HRK_NAC_NO" VARCHAR2(16 CHAR))'; END IF;
END;
/
COMMENT ON COLUMN "TPRMPP_CBLBCM"."HRK_NAC_NO" IS '상위게시물번호';

-- 2) 변경로그 CBLBCL : 동일 처리
DECLARE v NUMBER; BEGIN
  SELECT COUNT(*) INTO v FROM user_tab_columns WHERE table_name='TPRMPP_CBLBCL' AND column_name='HRK_NAC_MNG_NO';
  IF v > 0 THEN EXECUTE IMMEDIATE 'ALTER TABLE "TPRMPP_CBLBCL" RENAME COLUMN "HRK_NAC_MNG_NO" TO "HRK_NAC_NO"'; END IF;
END;
/
DECLARE v NUMBER; BEGIN
  SELECT COUNT(*) INTO v FROM user_tab_columns WHERE table_name='TPRMPP_CBLBCL' AND column_name='HRK_NAC_NO';
  IF v > 0 THEN EXECUTE IMMEDIATE 'ALTER TABLE "TPRMPP_CBLBCL" MODIFY ("HRK_NAC_NO" VARCHAR2(16 CHAR))'; END IF;
END;
/
COMMENT ON COLUMN "TPRMPP_CBLBCL"."HRK_NAC_NO" IS '상위게시물번호';

-- 3) 마스터 인덱스명 정합화 (컬럼 RENAME 후 인덱스 정의는 자동 추종, 인덱스명만 갱신)
DECLARE v NUMBER; BEGIN
  SELECT COUNT(*) INTO v FROM user_indexes WHERE index_name='IX_CBLBCM_HRK_NAC_MNG_NO';
  IF v > 0 THEN EXECUTE IMMEDIATE 'ALTER INDEX "IX_CBLBCM_HRK_NAC_MNG_NO" RENAME TO "IX_CBLBCM_HRK_NAC_NO"'; END IF;
END;
/

COMMIT;
