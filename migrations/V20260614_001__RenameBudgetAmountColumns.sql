-- 예산 금액 컬럼 메타사전 표준용어 정합 (마스터 + 변경로그 미러 동시 적용)
--   * TPRMPP_BPLANM.CPIT_BG_APV_AMT → TOT_CPIT_AMT (총자본금액, NUMBER(18,3))
--   * TPRMPP_BPLANL.CPIT_BG_APV_AMT → TOT_CPIT_AMT (변경 로그 테이블, NUMBER(15,2))
--   * TPRMPP_BTERMM.RQM_BG_AMT      → AMT          (금액, NUMBER(18,3))
--   * TPRMPP_BTERML.RQM_BG_AMT      → AMT          (변경 로그 테이블, NUMBER(18,3))
--   * TPRMPP_BCOSTM.TOT_XP_AMT      → AMT          (금액, NUMBER(18,3))
--   * TPRMPP_BCOSTL.TOT_XP_AMT      → AMT          (변경 로그 테이블, NUMBER(18,3))
--
-- 배경: 동일 물리컬럼명이 서로 다른 테이블에서 재사용되던 잔여 충돌을 해소합니다.
--   - RQM_BG_AMT 는 BESTTM(소요예산금액)·BPOVWM(소요예산금액)에서 계속 사용되므로 그대로 둡니다.
--     BTERMM(단말기금액)만 AMT 로 분리합니다.
--   - TOT_XP_AMT 는 BPLANM(일반관리비)에서 계속 사용되므로 그대로 둡니다.
--     BCOSTM(전산업무비예산금액)만 AMT 로 분리합니다.
--
-- 타입 변경 없음: 모든 항목이 단순 컬럼 RENAME 이므로 CLAUDE.md §5.2.1 "컬럼명만 변경" 패턴을 사용합니다.
-- 멱등성: 구 컬럼이 존재하고 신 컬럼이 아직 없을 때만 RENAME 하므로 재실행/부분적용 후에도 안전합니다.

DECLARE
    -- 객체 소유 스키마: 접속 계정(ITPAPP)과 분리되어 ITPOWN이 소유하므로, 세션의
    -- CURRENT_SCHEMA(=ITPOWN, 베이스/런너에서 설정)를 기준으로 컬럼 존재 여부를 판정한다.
    -- USER_TAB_COLS는 접속 사용자(ITPAPP) 소유 객체만 보여 ITPOWN 테이블을 못 찾으므로 사용하지 않는다.
    v_owner VARCHAR2(128) := SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA');

    -- 컬럼 리네임: 구 컬럼이 존재하고 신 컬럼이 아직 없을 때만 수행
    PROCEDURE rename_col(p_table VARCHAR2, p_old VARCHAR2, p_new VARCHAR2) IS
        v_old NUMBER;
        v_new NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_old FROM ALL_TAB_COLS
         WHERE OWNER = v_owner AND TABLE_NAME = p_table AND COLUMN_NAME = p_old;
        SELECT COUNT(*) INTO v_new FROM ALL_TAB_COLS
         WHERE OWNER = v_owner AND TABLE_NAME = p_table AND COLUMN_NAME = p_new;
        IF v_old > 0 AND v_new = 0 THEN
            EXECUTE IMMEDIATE 'ALTER TABLE ' || v_owner || '.' || p_table ||
                              ' RENAME COLUMN ' || p_old || ' TO ' || p_new;
        END IF;
    END;
BEGIN
    -- 1) 컬럼 리네임 (마스터 + 변경 로그 미러)
    rename_col('TPRMPP_BPLANM', 'CPIT_BG_APV_AMT', 'TOT_CPIT_AMT');
    rename_col('TPRMPP_BPLANL', 'CPIT_BG_APV_AMT', 'TOT_CPIT_AMT');
    rename_col('TPRMPP_BTERMM', 'RQM_BG_AMT', 'AMT');
    rename_col('TPRMPP_BTERML', 'RQM_BG_AMT', 'AMT');
    rename_col('TPRMPP_BCOSTM', 'TOT_XP_AMT', 'AMT');
    rename_col('TPRMPP_BCOSTL', 'TOT_XP_AMT', 'AMT');

    -- 2) 컬럼 코멘트 표준용어 정합 (엔티티 @Column comment 와 동기화)
    EXECUTE IMMEDIATE q'[COMMENT ON COLUMN TPRMPP_BPLANM.TOT_CPIT_AMT IS '자본예산 (물리컬럼 TOT_CPIT_AMT=총자본금액)']';
    EXECUTE IMMEDIATE q'[COMMENT ON COLUMN TPRMPP_BPLANL.TOT_CPIT_AMT IS '자본예산']';
    EXECUTE IMMEDIATE q'[COMMENT ON COLUMN TPRMPP_BTERMM.AMT IS '단말기금액 (물리컬럼 AMT=금액)']';
    EXECUTE IMMEDIATE q'[COMMENT ON COLUMN TPRMPP_BTERML.AMT IS '단말기금액']';
    EXECUTE IMMEDIATE q'[COMMENT ON COLUMN TPRMPP_BCOSTM.AMT IS '전산업무비예산금액 (물리컬럼 AMT=금액)']';
    EXECUTE IMMEDIATE q'[COMMENT ON COLUMN TPRMPP_BCOSTL.AMT IS '전산업무비예산금액']';
END;
/
