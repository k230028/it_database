-- 정보화사업(TPRMPP_BPROJM) 컬럼 메타사전 표준용어 정합
--   * PRJ_BZ_TC        → BZ_TP_C       (업무유형코드, VARCHAR2(2)→VARCHAR2(6))
--   * PRJ_TGT_RNG_CONE → ABUS_RNG_CONE (사업범위내용, VARCHAR2(300)→VARCHAR2(600))
--   * PRJ_NM           → ABUS_NM       (사업명,       VARCHAR2(100) 유지)
-- 변경 로그 테이블(TPRMPP_BPROJL)도 동일하게 컬럼명을 정합합니다(로그 컬럼 폭은 기존 유지).
--
-- ddl-auto=update는 RENAME/타입축소를 지원하지 않으므로(CLAUDE.md §5.2.1) 마이그레이션으로 처리합니다.
-- 길이 확대(VARCHAR2 widen)는 채워진 컬럼에도 안전합니다.
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

    -- VARCHAR2 길이 확대: 현재 길이가 목표보다 작을 때만 MODIFY (재실행 안전)
    PROCEDURE widen(p_table VARCHAR2, p_col VARCHAR2, p_len NUMBER) IS
        v_len USER_TAB_COLS.DATA_LENGTH%TYPE;
    BEGIN
        SELECT DATA_LENGTH INTO v_len FROM USER_TAB_COLS
         WHERE TABLE_NAME = p_table AND COLUMN_NAME = p_col;
        IF v_len < p_len THEN
            EXECUTE IMMEDIATE 'ALTER TABLE ' || p_table ||
                              ' MODIFY (' || p_col || ' VARCHAR2(' || p_len || '))';
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL; -- 대상 컬럼이 없으면(미예상 상태) 조용히 건너뜀
    END;
BEGIN
    -- 1) 컬럼 리네임 (마스터 + 변경 로그)
    rename_col('TPRMPP_BPROJM', 'PRJ_BZ_TC',        'BZ_TP_C');
    rename_col('TPRMPP_BPROJL', 'PRJ_BZ_TC',        'BZ_TP_C');
    rename_col('TPRMPP_BPROJM', 'PRJ_TGT_RNG_CONE', 'ABUS_RNG_CONE');
    rename_col('TPRMPP_BPROJL', 'PRJ_TGT_RNG_CONE', 'ABUS_RNG_CONE');
    rename_col('TPRMPP_BPROJM', 'PRJ_NM',           'ABUS_NM');
    rename_col('TPRMPP_BPROJL', 'PRJ_NM',           'ABUS_NM');

    -- 2) 마스터 컬럼 길이 확대
    widen('TPRMPP_BPROJM', 'BZ_TP_C',       6);
    widen('TPRMPP_BPROJM', 'ABUS_RNG_CONE', 600);

    -- 3) 컬럼 코멘트 표준용어 정합
    EXECUTE IMMEDIATE q'[COMMENT ON COLUMN TPRMPP_BPROJM.BZ_TP_C IS '업무유형코드']';
    EXECUTE IMMEDIATE q'[COMMENT ON COLUMN TPRMPP_BPROJL.BZ_TP_C IS '업무유형코드']';
    EXECUTE IMMEDIATE q'[COMMENT ON COLUMN TPRMPP_BPROJM.ABUS_RNG_CONE IS '사업범위내용']';
    EXECUTE IMMEDIATE q'[COMMENT ON COLUMN TPRMPP_BPROJL.ABUS_RNG_CONE IS '사업범위내용']';
    EXECUTE IMMEDIATE q'[COMMENT ON COLUMN TPRMPP_BPROJM.ABUS_NM IS '사업명']';
    EXECUTE IMMEDIATE q'[COMMENT ON COLUMN TPRMPP_BPROJL.ABUS_NM IS '사업명']';
END;
/
