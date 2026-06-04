-- 게시물 마스터/변경로그 테이블에서 게시물종류·자료중요도 구분코드 컬럼 제거
-- 제거 대상:
--   * NAC_KD_TC   (게시물종류구분코드) — 게시물 종류 구분 기능 폐지
--   * MRL_PRIT_TC (자료중요도구분코드) — 게시물 중요도 기능 폐지
-- 멱등성: 컬럼 존재 시에만 DROP (재실행 안전).

DECLARE
    PROCEDURE drop_col_if_exists(p_table IN VARCHAR2, p_col IN VARCHAR2) IS
        v_cnt NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_cnt
          FROM USER_TAB_COLS
         WHERE TABLE_NAME = p_table
           AND COLUMN_NAME = p_col;
        IF v_cnt > 0 THEN
            EXECUTE IMMEDIATE 'ALTER TABLE "' || p_table || '" DROP COLUMN "' || p_col || '"';
        END IF;
    END;
BEGIN
    drop_col_if_exists('TPRMPP_CBLBCM', 'NAC_KD_TC');
    drop_col_if_exists('TPRMPP_CBLBCM', 'MRL_PRIT_TC');

    drop_col_if_exists('TPRMPP_CBLBCL', 'NAC_KD_TC');
    drop_col_if_exists('TPRMPP_CBLBCL', 'MRL_PRIT_TC');
END;
/
