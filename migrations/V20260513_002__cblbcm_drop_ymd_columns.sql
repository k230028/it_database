-- ============================================================
-- V20260513_002: TAAABB_CBLBCM 잔존 STT_YMD/END_YMD 컬럼 제거
--
-- 배경:
--   초기 게시판 설계 시 컬럼명이 STT_YMD/END_YMD였으나 이후 STT_DT/END_DT로 rename.
--   Hibernate ddl-auto=update가 신규 컬럼만 ADD하고 기존 컬럼은 보존해
--   두 쌍의 컬럼이 공존(STT_YMD/END_YMD: 항상 NULL, STT_DT/END_DT: 신규 데이터).
--   엔티티는 STT_DT/END_DT만 매핑하므로 YMD 컬럼은 사용 흔적 없는 데드 컬럼.
-- ============================================================

DECLARE
    v_cnt NUMBER;
BEGIN
    -- STT_YMD 존재 시 DROP
    SELECT COUNT(*) INTO v_cnt
      FROM USER_TAB_COLUMNS
     WHERE TABLE_NAME = 'TAAABB_CBLBCM' AND COLUMN_NAME = 'STT_YMD';
    IF v_cnt = 1 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE TAAABB_CBLBCM DROP COLUMN STT_YMD';
    END IF;

    -- END_YMD 존재 시 DROP
    SELECT COUNT(*) INTO v_cnt
      FROM USER_TAB_COLUMNS
     WHERE TABLE_NAME = 'TAAABB_CBLBCM' AND COLUMN_NAME = 'END_YMD';
    IF v_cnt = 1 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE TAAABB_CBLBCM DROP COLUMN END_YMD';
    END IF;
END;
/

COMMIT;
