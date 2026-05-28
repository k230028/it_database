-- ============================================================
-- 전체 *L 로그 테이블 공통 컬럼 정리 (멱등성 보장)
--
-- 처리 내용:
--   - LOG_SNO가 PK이고 LOG_HIS_TGR_SNO가 공존하는 경우:
--       기존 PK 제거 → LOG_HIS_TGR_SNO로 PK 재설정 → LOG_SNO 제거
--   - LOG_SNO만 있는 경우 (Hibernate 미개입):
--       RENAME LOG_SNO → LOG_HIS_TGR_SNO
--   - LOG_HIS_TGR_SNO가 이미 PK인 경우: 무시
--   - CHG_TP: CAPPLL 제외 전 테이블에서 제거
--   - CAPPLL: LOG_SNO만 제거 (CHG_TP는 19번 컬럼으로 유지)
-- ============================================================

DECLARE
    -- 로그 테이블 공통 PK·CHG_TP 정리 프로시저
    PROCEDURE fix_log_table(
        p_table       IN VARCHAR2,
        p_pk_name     IN VARCHAR2,
        p_keep_chg_tp IN BOOLEAN DEFAULT FALSE
    ) IS
        v_has_log_sno NUMBER := 0;
        v_has_log_his NUMBER := 0;
        v_has_chg_tp  NUMBER := 0;
    BEGIN
        SELECT COUNT(*) INTO v_has_log_sno
        FROM user_tab_columns
        WHERE table_name = p_table AND column_name = 'LOG_SNO';

        SELECT COUNT(*) INTO v_has_log_his
        FROM user_tab_columns
        WHERE table_name = p_table AND column_name = 'LOG_HIS_TGR_SNO';

        SELECT COUNT(*) INTO v_has_chg_tp
        FROM user_tab_columns
        WHERE table_name = p_table AND column_name = 'CHG_TP';

        -- Case 1: PK=LOG_SNO, LOG_HIS_TGR_SNO 공존 → PK 전환 후 LOG_SNO 제거
        IF v_has_log_sno = 1 AND v_has_log_his = 1 THEN
            EXECUTE IMMEDIATE
                'UPDATE ' || p_table ||
                ' SET LOG_HIS_TGR_SNO = LOG_SNO WHERE LOG_HIS_TGR_SNO IS NULL';
            COMMIT;
            EXECUTE IMMEDIATE 'ALTER TABLE ' || p_table || ' DROP CONSTRAINT ' || p_pk_name;
            EXECUTE IMMEDIATE 'ALTER TABLE ' || p_table ||
                ' ADD CONSTRAINT ' || p_pk_name || ' PRIMARY KEY (LOG_HIS_TGR_SNO)';
            EXECUTE IMMEDIATE 'ALTER TABLE ' || p_table || ' DROP COLUMN LOG_SNO';

        -- Case 2: LOG_SNO만 존재 → RENAME으로 전환
        ELSIF v_has_log_sno = 1 AND v_has_log_his = 0 THEN
            EXECUTE IMMEDIATE
                'ALTER TABLE ' || p_table || ' RENAME COLUMN LOG_SNO TO LOG_HIS_TGR_SNO';

        -- Case 3: LOG_HIS_TGR_SNO 이미 PK → 아무것도 하지 않음
        END IF;

        -- CHG_TP 제거 (유지 플래그가 아닌 경우)
        IF v_has_chg_tp = 1 AND NOT p_keep_chg_tp THEN
            EXECUTE IMMEDIATE 'ALTER TABLE ' || p_table || ' DROP COLUMN CHG_TP';
        END IF;

    END fix_log_table;

BEGIN
    fix_log_table('TPRMPP_BASCTL', 'PK_BASCTL');
    fix_log_table('TPRMPP_BBUGTL', 'PK_BBUGTL');
    fix_log_table('TPRMPP_BCHKLL', 'PK_BCHKLL');
    fix_log_table('TPRMPP_BCMMTL', 'PK_BCMMTL');
    fix_log_table('TPRMPP_BCOSTL', 'PK_BCOSTL');
    fix_log_table('TPRMPP_BEVALL', 'PK_BEVALL');
    fix_log_table('TPRMPP_BGDOCL', 'PK_BGDOCL');
    fix_log_table('TPRMPP_BITEML', 'PK_BITEML');
    fix_log_table('TPRMPP_BMQNAL', 'PK_BMQNAL');
    fix_log_table('TPRMPP_BPERFL', 'PK_BPERFL');
    fix_log_table('TPRMPP_BPLANL', 'PK_BPLANL');
    fix_log_table('TPRMPP_BPOVWL', 'PK_BPOVWL');
    fix_log_table('TPRMPP_BPQNAL', 'PK_BPQNAL');
    fix_log_table('TPRMPP_BPROJL', 'PK_BPROJL');
    fix_log_table('TPRMPP_BRDOCL', 'PK_BRDOCL');
    fix_log_table('TPRMPP_BRIVGL', 'PK_BRIVGL');
    fix_log_table('TPRMPP_BRSLTL', 'PK_BRSLTL');
    fix_log_table('TPRMPP_BSCHDL', 'PK_BSCHDL');
    fix_log_table('TPRMPP_BTERML', 'PK_BTERML');
    fix_log_table('TPRMPP_CAPPLL', 'PK_CAPPLL');
    fix_log_table('TPRMPP_CBLBCL', 'PK_CBLBCL');
    fix_log_table('TPRMPP_CBLBML', 'PK_CBLBML');
    fix_log_table('TPRMPP_CCMMTL', 'PK_CCMMTL');
    fix_log_table('TPRMPP_CCODEL', 'PK_CCODEL');
END;
/
