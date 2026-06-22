-- V20260622_005__RenameCcodemIdAndDateColumns.sql
-- 공통코드 마스터/변경로그 컬럼 변경 (마스터 + 로그 미러 동시 적용)
--   1) CO_C_ID            -> CO_C_ID_NM  VARCHAR2(100)   (PK 첫 컬럼)
--   2) STT_DTM (DATE)     -> STT_DT      VARCHAR2(8)     'YYYYMMDD'  (PK 셋째 컬럼)
--   3) END_DTM (DATE)     -> END_DT      VARCHAR2(8)     'YYYYMMDD'
--
-- 배경: 엔티티/DTO/API 의 sttDt·endDt 를 LocalDate -> String('YYYYMMDD') 으로 전환하고
--   PK 첫 컬럼명을 CO_C_ID_NM(폭 100)으로 변경. ddl-auto 는 RENAME/타입변경을 지원하지 않으므로
--   본 마이그레이션으로 컬럼명·타입을 함께 정합한다. (it_backend/CLAUDE.md §5.2.1)
--
-- 타입 변경(DATE -> VARCHAR2(8)): 신규 컬럼 추가 -> TO_CHAR 변환 복사 -> 구 컬럼 DROP 패턴.
--   STT_DTM 은 PK 구성 컬럼이므로 마스터(CCODEM)는 PK 를 먼저 DROP 후 신규 컬럼으로 재생성한다.
--   STT_DTM/END_DTM 을 포함한 인덱스는 컬럼 DROP 시 함께 삭제되므로 신규 컬럼명으로 재생성한다.
--
-- 스키마: 객체 소유 스키마(ITPOWN)와 접속 계정(ITPAPP)이 분리되므로 존재 판정은
--   CURRENT_SCHEMA 기준 ALL_* 뷰로 한다. (V20260620_001 동일 패턴)
-- 멱등성: 구 컬럼/제약/인덱스 존재 여부를 매 단계 확인하여 재실행/부분적용 후에도 안전하다.

DECLARE
    c_schema CONSTANT VARCHAR2(128) := SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA');

    FUNCTION col_exists(p_table VARCHAR2, p_col VARCHAR2) RETURN BOOLEAN IS
        n NUMBER;
    BEGIN
        SELECT COUNT(*) INTO n FROM ALL_TAB_COLS
         WHERE OWNER = c_schema AND TABLE_NAME = p_table AND COLUMN_NAME = p_col;
        RETURN n > 0;
    END;

    FUNCTION obj_exists(p_view VARCHAR2, p_name VARCHAR2) RETURN BOOLEAN IS
        n NUMBER;
    BEGIN
        EXECUTE IMMEDIATE
            'SELECT COUNT(*) FROM ' || p_view || ' WHERE OWNER = :1 AND ' ||
            CASE p_view WHEN 'ALL_CONSTRAINTS' THEN 'CONSTRAINT_NAME' ELSE 'INDEX_NAME' END ||
            ' = :2'
            INTO n USING c_schema, p_name;
        RETURN n > 0;
    END;

    -- DATE 컬럼을 VARCHAR2(8) 'YYYYMMDD' 컬럼으로 재타입(컬럼명도 변경)
    PROCEDURE retype_date_to_str(p_table VARCHAR2, p_old VARCHAR2, p_new VARCHAR2, p_notnull BOOLEAN) IS
    BEGIN
        IF col_exists(p_table, p_old) AND NOT col_exists(p_table, p_new) THEN
            EXECUTE IMMEDIATE 'ALTER TABLE ' || p_table || ' ADD (' || p_new || ' VARCHAR2(8))';
            EXECUTE IMMEDIATE 'UPDATE ' || p_table || ' SET ' || p_new ||
                              ' = TO_CHAR(' || p_old || ', ''YYYYMMDD'')';
            IF p_notnull THEN
                EXECUTE IMMEDIATE 'ALTER TABLE ' || p_table || ' MODIFY (' || p_new || ' VARCHAR2(8) NOT NULL)';
            END IF;
            EXECUTE IMMEDIATE 'ALTER TABLE ' || p_table || ' DROP COLUMN ' || p_old;
        END IF;
    END;

    -- CO_C_ID -> CO_C_ID_NM 변경 + VARCHAR2(100) 확장
    PROCEDURE rename_widen_id(p_table VARCHAR2) IS
    BEGIN
        IF col_exists(p_table, 'CO_C_ID') AND NOT col_exists(p_table, 'CO_C_ID_NM') THEN
            EXECUTE IMMEDIATE 'ALTER TABLE ' || p_table || ' RENAME COLUMN CO_C_ID TO CO_C_ID_NM';
        END IF;
        IF col_exists(p_table, 'CO_C_ID_NM') THEN
            -- 폭 확장은 멱등(이미 100 이어도 무해)
            EXECUTE IMMEDIATE 'ALTER TABLE ' || p_table || ' MODIFY (CO_C_ID_NM VARCHAR2(100))';
        END IF;
    END;

    PROCEDURE drop_index_if_exists(p_idx VARCHAR2) IS
    BEGIN
        IF obj_exists('ALL_INDEXES', p_idx) THEN
            EXECUTE IMMEDIATE 'DROP INDEX ' || p_idx;
        END IF;
    END;
BEGIN
    -- ============================================================
    -- 1) 마스터: TPRMPP_CCODEM (PK + 인덱스 포함)
    -- ============================================================
    -- STT_DTM(구 컬럼)이 남아 있으면 PK 를 먼저 제거 (타입 변경 위해)
    IF col_exists('TPRMPP_CCODEM', 'STT_DTM') AND obj_exists('ALL_CONSTRAINTS', 'PK_CCODEM') THEN
        EXECUTE IMMEDIATE 'ALTER TABLE TPRMPP_CCODEM DROP CONSTRAINT PK_CCODEM';
    END IF;

    rename_widen_id('TPRMPP_CCODEM');
    retype_date_to_str('TPRMPP_CCODEM', 'STT_DTM', 'STT_DT', TRUE);
    retype_date_to_str('TPRMPP_CCODEM', 'END_DTM', 'END_DT', FALSE);

    -- 구 컬럼 DROP 으로 자동 삭제되지만, 잔존 시를 대비해 명시적 제거
    drop_index_if_exists('IX_CCODEM_CO_C_ID_DEL_YN_STT_DTM_END_DTM');
    drop_index_if_exists('IX_CCODEM_CO_C_INTN_NM_DEL_YN_STT_DTM_END_DTM');

    -- PK 재생성 (없을 때만)
    IF NOT obj_exists('ALL_CONSTRAINTS', 'PK_CCODEM') THEN
        EXECUTE IMMEDIATE 'ALTER TABLE TPRMPP_CCODEM ADD CONSTRAINT PK_CCODEM ' ||
                          'PRIMARY KEY (CO_C_ID_NM, CDVA_ID, STT_DT)';
    END IF;

    -- 인덱스 재생성 (신규 컬럼명)
    IF NOT obj_exists('ALL_INDEXES', 'IX_CCODEM_CO_C_ID_NM_DEL_YN_STT_DT_END_DT') THEN
        EXECUTE IMMEDIATE 'CREATE INDEX IX_CCODEM_CO_C_ID_NM_DEL_YN_STT_DT_END_DT ' ||
                          'ON TPRMPP_CCODEM (CO_C_ID_NM, DEL_YN, STT_DT, END_DT)';
    END IF;
    IF NOT obj_exists('ALL_INDEXES', 'IX_CCODEM_CO_C_INTN_NM_DEL_YN_STT_DT_END_DT') THEN
        EXECUTE IMMEDIATE 'CREATE INDEX IX_CCODEM_CO_C_INTN_NM_DEL_YN_STT_DT_END_DT ' ||
                          'ON TPRMPP_CCODEM (CO_C_INTN_NM, DEL_YN, STT_DT, END_DT)';
    END IF;

    -- ============================================================
    -- 2) 변경로그: TPRMPP_CCODEL (PK 는 LOG_HIS_TGR_SNO 이므로 컬럼 변경만)
    -- ============================================================
    rename_widen_id('TPRMPP_CCODEL');
    retype_date_to_str('TPRMPP_CCODEL', 'STT_DTM', 'STT_DT', TRUE);
    retype_date_to_str('TPRMPP_CCODEL', 'END_DTM', 'END_DT', FALSE);

    -- ============================================================
    -- 3) 컬럼 코멘트 동기화 (엔티티 @Column comment 와 정합)
    -- ============================================================
    EXECUTE IMMEDIATE q'[COMMENT ON COLUMN TPRMPP_CCODEM.CO_C_ID_NM IS '공통코드ID']';
    EXECUTE IMMEDIATE q'[COMMENT ON COLUMN TPRMPP_CCODEM.STT_DT IS '시작일자']';
    EXECUTE IMMEDIATE q'[COMMENT ON COLUMN TPRMPP_CCODEM.END_DT IS '종료일자']';
    EXECUTE IMMEDIATE q'[COMMENT ON COLUMN TPRMPP_CCODEL.CO_C_ID_NM IS '공통코드ID']';
    EXECUTE IMMEDIATE q'[COMMENT ON COLUMN TPRMPP_CCODEL.STT_DT IS '시작일자']';
    EXECUTE IMMEDIATE q'[COMMENT ON COLUMN TPRMPP_CCODEL.END_DT IS '종료일자']';
END;
/
