-- 게시판 메타/변경로그 테이블에서 조회권한·등록권한·상위고정사용여부 컬럼 제거
-- 제거 대상:
--   * INQ_DWN_ATH_TC (조회권한구분코드) — 게시판 단위 조회권한 게이트 폐지 (인증 사용자 전체 공개)
--   * WRT_DWN_ATH_TC (쓰기권한구분코드) — 등록권한 게이트 폐지 (공지사항 BLB_TC='001'은 ADMIN, 그 외 전체 등록)
--   * IOA_TC         (상위고정사용여부) — 게시판별 상위고정 토글 폐지 (상위고정 기능 자체는 유지)
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
    drop_col_if_exists('TPRMPP_CBLBMM', 'INQ_DWN_ATH_TC');
    drop_col_if_exists('TPRMPP_CBLBMM', 'WRT_DWN_ATH_TC');
    drop_col_if_exists('TPRMPP_CBLBMM', 'IOA_TC');

    drop_col_if_exists('TPRMPP_CBLBML', 'INQ_DWN_ATH_TC');
    drop_col_if_exists('TPRMPP_CBLBML', 'WRT_DWN_ATH_TC');
    drop_col_if_exists('TPRMPP_CBLBML', 'IOA_TC');
END;
/
