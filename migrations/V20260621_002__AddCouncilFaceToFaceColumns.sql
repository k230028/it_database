-- V20260621_002__AddCouncilFaceToFaceColumns.sql
-- 정보화실무협의회 '서면개최' 분기 도입 (PRD_c_20260620 #1).
--
-- 추가 컬럼:
--   TPRMPP_BASCTM.CSF_HELD_YN  대면개최여부 (Y=대면개최 / N=서면개최)
--   TPRMPP_BCMMTM.CSF_HP_YN    대면희망여부 (위원이 일정 응답 시 입력, Y/N)
--   로그 테이블(BASCTL/BCMMTL)에도 동일 컬럼 추가 — *L 엔티티가 업무 컬럼을 미러링하므로.
--
-- 설계:
--   · 위원 전원의 CSF_HP_YN 중 하나라도 Y → 대면개최(CSF_HELD_YN='Y', 회의일자/장소/시간 확정)
--   · 전원 N → 서면개최(CSF_HELD_YN='N', 회의일자/장소/시간 null, 상태 05→07 직접 전이)
--   · 모두 nullable — @LogTarget 엔티티 NOT NULL 스냅샷 타이밍 트랩(it_backend/CLAUDE.md §5.12.1.1) 회피.
--
-- 멱등성: ALL_TAB_COLS로 존재 여부 확인 후 없을 때만 ADD.
-- 스키마: 객체 소유는 ITPOWN.

DECLARE
    PROCEDURE add_col_if_absent(
        p_table IN VARCHAR2,
        p_col   IN VARCHAR2,
        p_def   IN VARCHAR2,
        p_cmt   IN VARCHAR2
    ) IS
        v_cnt NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_cnt
          FROM all_tab_cols
         WHERE owner = 'ITPOWN' AND table_name = p_table AND column_name = p_col;
        IF v_cnt = 0 THEN
            EXECUTE IMMEDIATE 'ALTER TABLE ITPOWN.' || p_table || ' ADD (' || p_col || ' ' || p_def || ')';
        END IF;
        EXECUTE IMMEDIATE 'COMMENT ON COLUMN ITPOWN.' || p_table || '.' || p_col || ' IS ''' || p_cmt || '''';
    END;
BEGIN
    add_col_if_absent('TPRMPP_BASCTM', 'CSF_HELD_YN', 'VARCHAR2(1)', '대면개최여부');
    add_col_if_absent('TPRMPP_BASCTL', 'CSF_HELD_YN', 'VARCHAR2(1)', '대면개최여부');
    add_col_if_absent('TPRMPP_BCMMTM', 'CSF_HP_YN',   'VARCHAR2(1)', '대면희망여부');
    add_col_if_absent('TPRMPP_BCMMTL', 'CSF_HP_YN',   'VARCHAR2(1)', '대면희망여부');
END;
/
