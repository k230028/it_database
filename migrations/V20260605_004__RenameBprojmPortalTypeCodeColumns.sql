-- 정보화사업(TPRMPP_BPROJM) / 변경 로그(TPRMPP_BPROJL) 구분코드 컬럼에 포탈 표준 접두어(IT_PTL_) 부여
--   * EDRT_TC    → IT_PTL_EDRT_TC    (전결권,       VARCHAR2(2))
--   * RPR_STS_TC → IT_PTL_RPR_STS_TC (보고상태,     마스터 VARCHAR2(1)→VARCHAR2(2))
--   * SKL_TP_TC  → IT_PTL_SKL_TP_TC  (기술유형,     VARCHAR2(2))
--   * STS_TC     → IT_PTL_STS_TC     (프로젝트상태, VARCHAR2(2))
-- 변경 로그 테이블(TPRMPP_BPROJL)도 동일하게 컬럼명을 정합하고, 코드 컬럼 폭을 VARCHAR2(2)로 통일합니다.
--
-- ddl-auto=update는 RENAME/타입축소를 지원하지 않으므로(CLAUDE.md §5.2.1) 마이그레이션으로 처리합니다.
-- 멱등성: 각 단계는 현재 상태를 확인해 미완료 단계만 수행하므로 재실행/부분적용 후에도 안전합니다.

DECLARE
    -- 컬럼 리네임: 구 컬럼이 존재하고 신 컬럼이 아직 없을 때만 수행
    PROCEDURE rename_col(p_table VARCHAR2, p_old VARCHAR2, p_new VARCHAR2) IS
        v_old NUMBER;
        v_new NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_old FROM USER_TAB_COLS
         WHERE TABLE_NAME = p_table AND COLUMN_NAME = p_old;
        SELECT COUNT(*) INTO v_new FROM USER_TAB_COLS
         WHERE TABLE_NAME = p_table AND COLUMN_NAME = p_new;
        IF v_old > 0 AND v_new = 0 THEN
            EXECUTE IMMEDIATE 'ALTER TABLE ' || p_table ||
                              ' RENAME COLUMN ' || p_old || ' TO ' || p_new;
        END IF;
    END;

    -- VARCHAR2 길이 정합: 현재 길이가 목표와 다를 때만 MODIFY.
    -- 축소 시에는 실제 저장된 최대 길이가 목표 이하인 경우에만 수행해 데이터 손실을 방지(재실행 안전).
    PROCEDURE set_len(p_table VARCHAR2, p_col VARCHAR2, p_len NUMBER) IS
        v_len     USER_TAB_COLS.DATA_LENGTH%TYPE;
        v_max_len NUMBER;
    BEGIN
        SELECT DATA_LENGTH INTO v_len FROM USER_TAB_COLS
         WHERE TABLE_NAME = p_table AND COLUMN_NAME = p_col;
        IF v_len = p_len THEN
            RETURN;
        END IF;
        IF v_len < p_len THEN
            -- 길이 확대는 항상 안전
            EXECUTE IMMEDIATE 'ALTER TABLE ' || p_table ||
                              ' MODIFY (' || p_col || ' VARCHAR2(' || p_len || '))';
        ELSE
            -- 길이 축소는 데이터가 목표 폭에 들어맞을 때만
            EXECUTE IMMEDIATE 'SELECT NVL(MAX(LENGTH(' || p_col || ')), 0) FROM ' || p_table
                INTO v_max_len;
            IF v_max_len <= p_len THEN
                EXECUTE IMMEDIATE 'ALTER TABLE ' || p_table ||
                                  ' MODIFY (' || p_col || ' VARCHAR2(' || p_len || '))';
            END IF;
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL; -- 대상 컬럼이 없으면(미예상 상태) 조용히 건너뜀
    END;
BEGIN
    -- 1) 컬럼 리네임 (마스터 + 변경 로그)
    rename_col('TPRMPP_BPROJM', 'EDRT_TC',    'IT_PTL_EDRT_TC');
    rename_col('TPRMPP_BPROJL', 'EDRT_TC',    'IT_PTL_EDRT_TC');
    rename_col('TPRMPP_BPROJM', 'RPR_STS_TC', 'IT_PTL_RPR_STS_TC');
    rename_col('TPRMPP_BPROJL', 'RPR_STS_TC', 'IT_PTL_RPR_STS_TC');
    rename_col('TPRMPP_BPROJM', 'SKL_TP_TC',  'IT_PTL_SKL_TP_TC');
    rename_col('TPRMPP_BPROJL', 'SKL_TP_TC',  'IT_PTL_SKL_TP_TC');
    rename_col('TPRMPP_BPROJM', 'STS_TC',     'IT_PTL_STS_TC');
    rename_col('TPRMPP_BPROJL', 'STS_TC',     'IT_PTL_STS_TC');

    -- 2) 코드 컬럼 폭을 VARCHAR2(2)로 정합 (마스터 RPR_STS_TC 확대 + 로그 4개 축소)
    set_len('TPRMPP_BPROJM', 'IT_PTL_EDRT_TC',    2);
    set_len('TPRMPP_BPROJM', 'IT_PTL_RPR_STS_TC', 2);
    set_len('TPRMPP_BPROJM', 'IT_PTL_SKL_TP_TC',  2);
    set_len('TPRMPP_BPROJM', 'IT_PTL_STS_TC',     2);
    set_len('TPRMPP_BPROJL', 'IT_PTL_EDRT_TC',    2);
    set_len('TPRMPP_BPROJL', 'IT_PTL_RPR_STS_TC', 2);
    set_len('TPRMPP_BPROJL', 'IT_PTL_SKL_TP_TC',  2);
    set_len('TPRMPP_BPROJL', 'IT_PTL_STS_TC',     2);

    -- 3) 컬럼 코멘트 유지
    EXECUTE IMMEDIATE q'[COMMENT ON COLUMN TPRMPP_BPROJM.IT_PTL_EDRT_TC IS '전결권']';
    EXECUTE IMMEDIATE q'[COMMENT ON COLUMN TPRMPP_BPROJL.IT_PTL_EDRT_TC IS '전결권']';
    EXECUTE IMMEDIATE q'[COMMENT ON COLUMN TPRMPP_BPROJM.IT_PTL_RPR_STS_TC IS '보고상태']';
    EXECUTE IMMEDIATE q'[COMMENT ON COLUMN TPRMPP_BPROJL.IT_PTL_RPR_STS_TC IS '보고상태']';
    EXECUTE IMMEDIATE q'[COMMENT ON COLUMN TPRMPP_BPROJM.IT_PTL_SKL_TP_TC IS '기술유형']';
    EXECUTE IMMEDIATE q'[COMMENT ON COLUMN TPRMPP_BPROJL.IT_PTL_SKL_TP_TC IS '기술유형']';
    EXECUTE IMMEDIATE q'[COMMENT ON COLUMN TPRMPP_BPROJM.IT_PTL_STS_TC IS '프로젝트상태']';
    EXECUTE IMMEDIATE q'[COMMENT ON COLUMN TPRMPP_BPROJL.IT_PTL_STS_TC IS '프로젝트상태']';
END;
/
