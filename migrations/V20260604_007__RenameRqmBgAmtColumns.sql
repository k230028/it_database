-- 소요예산금액(RQM_BG_AMT) 컬럼 메타사전 표준용어 정합
--   * TPRMPP_BBUGTM.RQM_BG_AMT → BG_DUP_AMT (예산편성금액, NUMBER(18,3))  [기존 타입 유지]
--   * TPRMPP_BBUGTL.RQM_BG_AMT → BG_DUP_AMT (예산편성금액, NUMBER(18,3))  [변경 로그 테이블]
--   * TPRMPP_BPROJM.RQM_BG_AMT → TOT_RQM_AMT (총소요금액, NUMBER(18,2)→(18,3))
--   * TPRMPP_BPROJL.RQM_BG_AMT → TOT_RQM_AMT (총소요금액, NUMBER(18,2)→(18,3))  [변경 로그 테이블]
-- 동일 물리컬럼명 RQM_BG_AMT가 BBUGTM/BPROJM/BTERMM 3개 테이블에서 서로 다른 의미로 재사용되던
-- 충돌을 해소합니다. BTERMM(단말기금액)은 본 변경 대상이 아닙니다.
--
-- 타입 변경 주의: NUMBER(18,2)→NUMBER(18,3)은 precision은 같으나 정수부 자릿수가 16→15로
-- 줄어들어 Oracle MODIFY가 채워진 컬럼을 거부합니다(ORA-01440). 따라서 CLAUDE.md §5.2.1의
-- "타입 변경" 패턴(임시 컬럼 추가 → 값 복사 → 옛 컬럼 DROP → 임시 컬럼 RENAME)으로 재구축합니다.
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

    -- scale을 3으로 확대(채워진 컬럼 대응): 임시 컬럼 재구축. 이미 scale=3이면 건너뜀.
    PROCEDURE ensure_scale3(p_table VARCHAR2, p_col VARCHAR2) IS
        v_scale USER_TAB_COLS.DATA_SCALE%TYPE;
        v_tmp   NUMBER;
        c_tmp   CONSTANT VARCHAR2(30) := p_col || '_T3';
    BEGIN
        SELECT DATA_SCALE INTO v_scale FROM USER_TAB_COLS
         WHERE TABLE_NAME = p_table AND COLUMN_NAME = p_col;
        IF v_scale = 3 THEN
            RETURN;
        END IF;
        SELECT COUNT(*) INTO v_tmp FROM USER_TAB_COLS
         WHERE TABLE_NAME = p_table AND COLUMN_NAME = c_tmp;
        IF v_tmp = 0 THEN
            EXECUTE IMMEDIATE 'ALTER TABLE ' || p_table ||
                              ' ADD (' || c_tmp || ' NUMBER(18,3))';
        END IF;
        EXECUTE IMMEDIATE 'UPDATE ' || p_table ||
                          ' SET ' || c_tmp || ' = ' || p_col;
        EXECUTE IMMEDIATE 'ALTER TABLE ' || p_table || ' DROP COLUMN ' || p_col;
        EXECUTE IMMEDIATE 'ALTER TABLE ' || p_table ||
                          ' RENAME COLUMN ' || c_tmp || ' TO ' || p_col;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL; -- 대상 컬럼이 없으면(미예상 상태) 조용히 건너뜀
    END;
BEGIN
    -- 1) 컬럼 리네임
    rename_col('TPRMPP_BBUGTM', 'RQM_BG_AMT', 'BG_DUP_AMT');
    rename_col('TPRMPP_BBUGTL', 'RQM_BG_AMT', 'BG_DUP_AMT');
    rename_col('TPRMPP_BPROJM', 'RQM_BG_AMT', 'TOT_RQM_AMT');
    rename_col('TPRMPP_BPROJL', 'RQM_BG_AMT', 'TOT_RQM_AMT');

    -- 2) 정보화사업 총소요금액 scale 확대 (18,2 → 18,3)
    ensure_scale3('TPRMPP_BPROJM', 'TOT_RQM_AMT');
    ensure_scale3('TPRMPP_BPROJL', 'TOT_RQM_AMT');

    -- 3) 컬럼 코멘트 표준용어 정합
    EXECUTE IMMEDIATE q'[COMMENT ON COLUMN TPRMPP_BBUGTM.BG_DUP_AMT IS '편성예산금액 (물리컬럼 BG_DUP_AMT=예산편성금액)']';
    EXECUTE IMMEDIATE q'[COMMENT ON COLUMN TPRMPP_BBUGTL.BG_DUP_AMT IS '편성예산금액']';
    EXECUTE IMMEDIATE q'[COMMENT ON COLUMN TPRMPP_BPROJM.TOT_RQM_AMT IS '프로젝트예산 (물리컬럼 TOT_RQM_AMT=총소요금액)']';
    EXECUTE IMMEDIATE q'[COMMENT ON COLUMN TPRMPP_BPROJL.TOT_RQM_AMT IS '프로젝트예산']';
END;
/
