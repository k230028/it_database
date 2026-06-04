-- 정보화사업(TPRMPP_BPROJM) 담당자/팀장 컬럼 메타사전 표준용어 정합
--   * SVN_DPM_USID     → USID         (주관부서담당자, 물리컬럼 USID=사용자ID)
--   * SVN_DPM_DCD_USID 제거            (주관부서담당팀장은 TLR_USID로 이관)
--   * TLR_USID         의미 변경        (IT부서담당팀장 → 주관부서담당팀장)
--   * DVM_TLR_USID     신규 추가        (IT부서담당팀장, 물리컬럼 DVM_TLR_USID=개발팀장사용자ID)
-- 변경 로그 테이블(TPRMPP_BPROJL)도 구조를 동일하게 정합합니다(로그는 이력이므로 데이터 스왑은 하지 않음).
--
-- [데이터 이관 — 마스터 한정]
--   기존: TLR_USID=IT부서담당팀장,  SVN_DPM_DCD_USID=주관부서담당팀장
--   변경: TLR_USID=주관부서담당팀장, DVM_TLR_USID=IT부서담당팀장
--   → 의미가 보존되도록 (1) IT팀장(TLR_USID) → DVM_TLR_USID,
--                      (2) 주관팀장(SVN_DPM_DCD_USID) → TLR_USID 순으로 값을 이동합니다.
--
-- ddl-auto=update는 RENAME/DROP을 지원하지 않으므로(CLAUDE.md §5.2.1) 마이그레이션으로 처리합니다.
-- 멱등성: 각 단계는 현재 상태를 확인해 미완료 단계만 수행하므로 재실행/부분적용 후에도 안전합니다.
--   특히 데이터 이관은 구 컬럼(SVN_DPM_DCD_USID)이 남아 있는 최초 1회에만 수행됩니다.

DECLARE
    -- 컬럼 추가: 신 컬럼이 아직 없을 때만 수행
    PROCEDURE add_col(p_table VARCHAR2, p_col VARCHAR2, p_def VARCHAR2) IS
        v_cnt NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_cnt FROM USER_TAB_COLS
         WHERE TABLE_NAME = p_table AND COLUMN_NAME = p_col;
        IF v_cnt = 0 THEN
            EXECUTE IMMEDIATE 'ALTER TABLE ' || p_table ||
                              ' ADD (' || p_col || ' ' || p_def || ')';
        END IF;
    END;

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

    -- 컬럼 삭제: 구 컬럼이 존재할 때만 수행
    PROCEDURE drop_col(p_table VARCHAR2, p_col VARCHAR2) IS
        v_cnt NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_cnt FROM USER_TAB_COLS
         WHERE TABLE_NAME = p_table AND COLUMN_NAME = p_col;
        IF v_cnt > 0 THEN
            EXECUTE IMMEDIATE 'ALTER TABLE ' || p_table ||
                              ' DROP COLUMN ' || p_col;
        END IF;
    END;

    -- 컬럼 존재 여부
    FUNCTION has_col(p_table VARCHAR2, p_col VARCHAR2) RETURN BOOLEAN IS
        v_cnt NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_cnt FROM USER_TAB_COLS
         WHERE TABLE_NAME = p_table AND COLUMN_NAME = p_col;
        RETURN v_cnt > 0;
    END;
BEGIN
    -- 1) 신규 컬럼(DVM_TLR_USID=IT부서담당팀장) 추가 (마스터 + 변경 로그)
    add_col('TPRMPP_BPROJM', 'DVM_TLR_USID', 'VARCHAR2(14 CHAR)');
    add_col('TPRMPP_BPROJL', 'DVM_TLR_USID', 'VARCHAR2(14 CHAR)');

    -- 2) 마스터 데이터 이관 (구 컬럼이 남아 있는 최초 1회만)
    IF has_col('TPRMPP_BPROJM', 'SVN_DPM_DCD_USID') THEN
        -- (1) 기존 IT부서담당팀장(TLR_USID) → DVM_TLR_USID
        EXECUTE IMMEDIATE 'UPDATE TPRMPP_BPROJM SET DVM_TLR_USID = TLR_USID';
        -- (2) 기존 주관부서담당팀장(SVN_DPM_DCD_USID) → TLR_USID
        EXECUTE IMMEDIATE 'UPDATE TPRMPP_BPROJM SET TLR_USID = SVN_DPM_DCD_USID';
        COMMIT;
    END IF;

    -- 3) 구 컬럼(SVN_DPM_DCD_USID) 삭제 (마스터 + 변경 로그)
    drop_col('TPRMPP_BPROJM', 'SVN_DPM_DCD_USID');
    drop_col('TPRMPP_BPROJL', 'SVN_DPM_DCD_USID');

    -- 4) 주관부서담당자 컬럼 리네임 SVN_DPM_USID → USID (마스터 + 변경 로그)
    rename_col('TPRMPP_BPROJM', 'SVN_DPM_USID', 'USID');
    rename_col('TPRMPP_BPROJL', 'SVN_DPM_USID', 'USID');

    -- 5) 컬럼 코멘트 표준용어 정합
    EXECUTE IMMEDIATE q'[COMMENT ON COLUMN TPRMPP_BPROJM.USID IS '주관부서담당자']';
    EXECUTE IMMEDIATE q'[COMMENT ON COLUMN TPRMPP_BPROJL.USID IS '주관부서담당자']';
    EXECUTE IMMEDIATE q'[COMMENT ON COLUMN TPRMPP_BPROJM.TLR_USID IS '주관부서담당팀장']';
    EXECUTE IMMEDIATE q'[COMMENT ON COLUMN TPRMPP_BPROJL.TLR_USID IS '주관부서담당팀장']';
    EXECUTE IMMEDIATE q'[COMMENT ON COLUMN TPRMPP_BPROJM.DVM_TLR_USID IS 'IT부서담당팀장']';
    EXECUTE IMMEDIATE q'[COMMENT ON COLUMN TPRMPP_BPROJL.DVM_TLR_USID IS 'IT부서담당팀장']';
END;
/
