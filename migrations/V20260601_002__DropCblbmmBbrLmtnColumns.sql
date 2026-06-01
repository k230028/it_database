-- ============================================================
-- TPRMPP_CBLBMM 부점한정(부서한정) 컬럼 폐기
--   - BBR_LMTN_USE_YN (부점한정사용여부)
--   - BBR_LMTN_C      (부점한정코드)
--   - 게시판 단위 "담당부서 한정" 기능 제거에 따른 컬럼 삭제.
--   - 변경로그 테이블 TPRMPP_CBLBML도 동일 적용 (감사 복사가 @Column(name) 기준 매칭).
-- 멱등성(idempotent): 컬럼 존재 여부로 가드. 재실행/부분적용 상태에서도 안전.
-- ============================================================

-- ------------------------------------------------------------
-- 1. 마스터 TPRMPP_CBLBMM
-- ------------------------------------------------------------
DECLARE
    has_use_yn NUMBER;
    has_c      NUMBER;
BEGIN
    SELECT COUNT(*) INTO has_use_yn FROM user_tab_columns
     WHERE table_name = 'TPRMPP_CBLBMM' AND column_name = 'BBR_LMTN_USE_YN';
    SELECT COUNT(*) INTO has_c FROM user_tab_columns
     WHERE table_name = 'TPRMPP_CBLBMM' AND column_name = 'BBR_LMTN_C';

    IF has_use_yn = 1 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE TPRMPP_CBLBMM DROP COLUMN BBR_LMTN_USE_YN';
    END IF;
    IF has_c = 1 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE TPRMPP_CBLBMM DROP COLUMN BBR_LMTN_C';
    END IF;
END;
/

-- ------------------------------------------------------------
-- 2. 변경로그 TPRMPP_CBLBML
-- ------------------------------------------------------------
DECLARE
    has_use_yn NUMBER;
    has_c      NUMBER;
BEGIN
    SELECT COUNT(*) INTO has_use_yn FROM user_tab_columns
     WHERE table_name = 'TPRMPP_CBLBML' AND column_name = 'BBR_LMTN_USE_YN';
    SELECT COUNT(*) INTO has_c FROM user_tab_columns
     WHERE table_name = 'TPRMPP_CBLBML' AND column_name = 'BBR_LMTN_C';

    IF has_use_yn = 1 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE TPRMPP_CBLBML DROP COLUMN BBR_LMTN_USE_YN';
    END IF;
    IF has_c = 1 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE TPRMPP_CBLBML DROP COLUMN BBR_LMTN_C';
    END IF;
END;
/

COMMIT;
