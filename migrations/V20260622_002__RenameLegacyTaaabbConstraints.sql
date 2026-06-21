-- 과거 테이블명(TAAABB)이 남아 있는 PK 제약조건/인덱스 이름을 현재 테이블명 기준으로 정리합니다.
-- 이름만 변경하므로 데이터, 컬럼, PK 구성은 변경하지 않습니다.

DECLARE
    c_schema CONSTANT VARCHAR2(128) := SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA');

    -- 구 제약조건명이 존재하고 신규 제약조건명이 아직 없을 때만 이름을 변경합니다.
    PROCEDURE rename_constraint(p_table VARCHAR2, p_old VARCHAR2, p_new VARCHAR2) IS
        v_old NUMBER;
        v_new NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_old
          FROM ALL_CONSTRAINTS
         WHERE OWNER = c_schema
           AND TABLE_NAME = p_table
           AND CONSTRAINT_NAME = p_old;

        SELECT COUNT(*) INTO v_new
          FROM ALL_CONSTRAINTS
         WHERE OWNER = c_schema
           AND TABLE_NAME = p_table
           AND CONSTRAINT_NAME = p_new;

        IF v_old > 0 AND v_new = 0 THEN
            EXECUTE IMMEDIATE 'ALTER TABLE ' || p_table || ' RENAME CONSTRAINT ' || p_old || ' TO ' || p_new;
        END IF;
    END;

    -- 중복으로 남은 명시 CHECK 제약조건은 현재 DB에 존재할 때만 제거합니다.
    PROCEDURE drop_constraint(p_table VARCHAR2, p_name VARCHAR2) IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count
          FROM ALL_CONSTRAINTS
         WHERE OWNER = c_schema
           AND TABLE_NAME = p_table
           AND CONSTRAINT_NAME = p_name;

        IF v_count > 0 THEN
            EXECUTE IMMEDIATE 'ALTER TABLE ' || p_table || ' DROP CONSTRAINT ' || p_name;
        END IF;
    END;

    -- PK 제약조건을 받치는 인덱스도 구 이름이 남아 있으면 함께 정리합니다.
    PROCEDURE rename_index(p_old VARCHAR2, p_new VARCHAR2) IS
        v_old NUMBER;
        v_new NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_old
          FROM ALL_INDEXES
         WHERE OWNER = c_schema
           AND INDEX_NAME = p_old;

        SELECT COUNT(*) INTO v_new
          FROM ALL_INDEXES
         WHERE OWNER = c_schema
           AND INDEX_NAME = p_new;

        IF v_old > 0 AND v_new = 0 THEN
            EXECUTE IMMEDIATE 'ALTER INDEX ' || p_old || ' RENAME TO ' || p_new;
        END IF;
    END;

    -- 이름 없이 생성된 PK 제약조건은 테이블의 현재 PK를 찾아 표준 이름으로 변경합니다.
    PROCEDURE rename_primary_key(p_table VARCHAR2, p_new VARCHAR2) IS
        v_constraint_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
        v_index_name ALL_CONSTRAINTS.INDEX_NAME%TYPE;
        v_new_constraint_count NUMBER;
        v_new_index_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_new_constraint_count
          FROM ALL_CONSTRAINTS
         WHERE OWNER = c_schema
           AND TABLE_NAME = p_table
           AND CONSTRAINT_NAME = p_new;

        IF v_new_constraint_count > 0 THEN
            RETURN;
        END IF;

        SELECT CONSTRAINT_NAME, INDEX_NAME
          INTO v_constraint_name, v_index_name
          FROM ALL_CONSTRAINTS
         WHERE OWNER = c_schema
           AND TABLE_NAME = p_table
           AND CONSTRAINT_TYPE = 'P';

        EXECUTE IMMEDIATE 'ALTER TABLE ' || p_table || ' RENAME CONSTRAINT ' || v_constraint_name || ' TO ' || p_new;

        IF v_index_name IS NOT NULL AND v_index_name <> p_new THEN
            SELECT COUNT(*) INTO v_new_index_count
              FROM ALL_INDEXES
             WHERE OWNER = c_schema
               AND INDEX_NAME = p_new;

            IF v_new_index_count = 0 THEN
                EXECUTE IMMEDIATE 'ALTER INDEX ' || v_index_name || ' RENAME TO ' || p_new;
            END IF;
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
    END;
BEGIN
    rename_index('PK_TPRMPP_BESTIDL', 'PK_TPRMPP_BESTTL');

    rename_constraint('TPRMPP_BBUGTM', 'PK_TAAABB_BBUGTM_BG_MNG_NO_BG_SNO', 'PK_BBUGTM');
    rename_index('PK_TAAABB_BBUGTM_BG_MNG_NO_BG_SNO', 'PK_BBUGTM');

    rename_constraint('TPRMPP_BGDOCM', 'PK_TAAABB_BGDOCM_DOC_MNG_NO', 'PK_BGDOCM');
    rename_index('PK_TAAABB_BGDOCM_DOC_MNG_NO', 'PK_BGDOCM');

    rename_index('PK_TAAABB_BPROJA_PRJ_MNG_NO_BZ_MNG_NO', 'PK_TPRMPP_BPLANA');

    rename_constraint('TPRMPP_BPLANM', 'PK_TAAABB_BPLANM_PLN_MNG_NO', 'PK_BPLANM');
    rename_index('PK_TAAABB_BPLANM_PLN_MNG_NO', 'PK_BPLANM');

    rename_constraint('TPRMPP_BPROJM', 'PK_TAAABB_BPROJM_PRJ_MNG_NO_PRJ_SNO', 'PK_BPROJM');
    rename_index('PK_TAAABB_BPROJM_PRJ_MNG_NO_PRJ_SNO', 'PK_BPROJM');

    rename_constraint('TPRMPP_BRDOCM', 'PK_TAAABB_BRDOCM_DOC_MNG_NO_DOC_VRS', 'PK_BRDOCM');
    rename_index('PK_TAAABB_BRDOCM_DOC_MNG_NO_DOC_VRS', 'PK_BRDOCM');

    rename_constraint('TPRMPP_BTERMM', 'PK_TAAABB_BTERMM_TMN', 'PK_BTERMM');
    rename_index('PK_TAAABB_BTERMM_TMN', 'PK_BTERMM');

    rename_constraint('TPRMPP_CAPPLM', 'PK_TAAABB_CAPPLM_APF_MNG_NO', 'PK_CAPPLM');
    rename_index('PK_TAAABB_CAPPLM_APF_MNG_NO', 'PK_CAPPLM');

    rename_constraint('TPRMPP_CAUTHI', 'PK_TAAABB_CAUTHI_ATH_ID', 'PK_CAUTHI');
    rename_index('PK_TAAABB_CAUTHI_ATH_ID', 'PK_CAUTHI');

    rename_constraint('TPRMPP_CBLBCM', 'PK_TAAABB_CBLBCM_NAC_MNG_NO', 'PK_CBLBCM');
    rename_index('PK_TAAABB_CBLBCM_NAC_MNG_NO', 'PK_CBLBCM');

    rename_constraint('TPRMPP_CBLBMM', 'PK_TAAABB_CBLBMM_BLB_MNG_NO', 'PK_CBLBMM');
    rename_index('PK_TAAABB_CBLBMM_BLB_MNG_NO', 'PK_CBLBMM');

    rename_constraint('TPRMPP_CCODEM', 'PK_TAAABB_CCODEM_C_ID_CDVA_STT_DT', 'PK_CCODEM');
    rename_index('PK_TAAABB_CCODEM_C_ID_CDVA_STT_DT', 'PK_CCODEM');

    rename_constraint('TPRMPP_CDECIM', 'PK_TAAABB_CDECIM_DCD_MNG_NO_DCD_SQN', 'PK_CDECIM');
    rename_index('PK_TAAABB_CDECIM_DCD_MNG_NO_DCD_SQN', 'PK_CDECIM');

    rename_constraint('TPRMPP_CFILEM', 'PK_TAAABB_CFILEM_FL_MNG_NO', 'PK_CFILEM');
    rename_index('PK_TAAABB_CFILEM_FL_MNG_NO', 'PK_CFILEM');

    rename_constraint('TPRMPP_CLOGNH', 'PK_TAAABB_CLOGNH_LGN_SNO', 'PK_CLOGNH');
    rename_index('PK_TAAABB_CLOGNH_LGN_SNO', 'PK_CLOGNH');

    rename_constraint('TPRMPP_CORGNI', 'PK_TAAABB_CORGNI_PRLM_OGZ_C_CONE', 'PK_CORGNI');
    rename_index('PK_TAAABB_CORGNI_PRLM_OGZ_C_CONE', 'PK_CORGNI');

    rename_constraint('TPRMPP_CROLEI', 'PK_TAAABB_CROLEI_ATH_ID_ENO', 'PK_CROLEI');
    rename_index('PK_TAAABB_CROLEI_ATH_ID_ENO', 'PK_CROLEI');

    rename_constraint('TPRMPP_CRTOKM', 'PK_TAAABB_CRTOKM_TOK_SNO', 'PK_CRTOKM');
    rename_index('PK_TAAABB_CRTOKM_TOK_SNO', 'PK_CRTOKM');

    rename_constraint('TPRMPP_CUSERI', 'PK_TAAABB_CUSERI_ENO', 'PK_CUSERI');
    rename_index('PK_TAAABB_CUSERI_ENO', 'PK_CUSERI');

    rename_primary_key('TPRMPP_CBLBML', 'PK_CBLBML');
    rename_primary_key('TPRMPP_CCMMTL', 'PK_CCMMTL');
    rename_primary_key('TPRMPP_CCODEL', 'PK_CCODEL');

    drop_constraint('TPRMPP_CUSERI', 'SYS_C0011168');
    drop_constraint('TPRMPP_CUSERI', 'SYS_C0011169');
END;
/
