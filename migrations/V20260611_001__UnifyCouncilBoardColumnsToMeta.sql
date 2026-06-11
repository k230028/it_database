-- V20260611_001__UnifyCouncilBoardColumnsToMeta.sql
-- 협의회(BASCT/BCHKL/BCMMT/BEVAL/BMQNA/BPERF/BPOVW/BPQNA/BRSLT/BSCHD)·게시판(CBLBC)
-- 컬럼을 메타DB(table.csv) 기준으로 통일 (rename / 폭 정렬 / 컬럼 추가·삭제)
--
-- 배경:
--  - DB 코멘트에 '(메타등록필요)'로 표시돼 있던 비표준 컬럼명들이 메타 용어사전에
--    표준 명칭(IT_PTL_* 등)으로 등재 완료됨에 따라 DB를 메타 기준으로 정렬한다.
--  - 구분코드(TC) 컬럼은 메타 정의 VARCHAR2(2)에 맞춰 축소하고, 기존 3자리 코드값은
--    SUBSTR(값, -2) 규칙('001'→'01')으로 변환한다. 연관 코드값(CCODEM의 CKG_ITM_C·
--    KPN_TC 그룹, BCHKLC.CKG_ITM_C 데이터)도 동일 규칙으로 변환해 도메인 일관성 유지.
--  - 메타에 없는 DB 컬럼(QTN_ENO/REP_ENO, GL_NV_CONE, MSM_MANR_CONE, MSM_STT_DT,
--    MSM_END_DT, PRJ_BG_AMR)은 드롭한다 (기능 축소 결정 완료, 데이터는 테스트 수준).
--
-- 예외(메타와 의도적 차이 유지):
--  - CBLBCM/CBLBCL.NAC_ID: 메타는 VARCHAR2(10)이나 실데이터('NAC-2026-0400', 13자)와
--    채번 형식(NAC-{YYYY}-{NNNN}, 13자)이 10자를 초과하므로 VARCHAR2(16) 유지.
--    메타 정정 대상으로 별도 추적.
--
-- 멱등성: 컬럼 존재 여부 가드(user_tab_columns) 후 실행하므로 재실행 안전.
-- 주의: 적용 시 NLS_LANG=.AL32UTF8 환경에서 실행할 것 (한글 코멘트 손상 방지).

-- =====================================================================
-- 0) 공통 헬퍼: 컬럼 존재 시에만 EXECUTE IMMEDIATE 수행하는 패턴을 인라인 사용
-- =====================================================================

DECLARE
    PROCEDURE run_if(p_tbl VARCHAR2, p_col VARCHAR2, p_sql VARCHAR2) IS
        v_cnt NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_cnt FROM user_tab_columns
         WHERE table_name = p_tbl AND column_name = p_col;
        IF v_cnt > 0 THEN
            EXECUTE IMMEDIATE p_sql;
        END IF;
    END;
    PROCEDURE add_if_absent(p_tbl VARCHAR2, p_col VARCHAR2, p_def VARCHAR2) IS
        v_cnt NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_cnt FROM user_tab_columns
         WHERE table_name = p_tbl AND column_name = p_col;
        IF v_cnt = 0 THEN
            EXECUTE IMMEDIATE 'ALTER TABLE ITPAPP.' || p_tbl || ' ADD (' || p_col || ' ' || p_def || ')';
        END IF;
    END;
BEGIN
    -- =================================================================
    -- 1) 공통: ASCT_ID → IT_PTL_ASCT_ID (협의회 전 테이블, 폭 32 유지)
    -- =================================================================
    FOR t IN (SELECT column_value tbl FROM TABLE(SYS.ODCIVARCHAR2LIST(
        'TPRMPP_BASCTM','TPRMPP_BASCTL','TPRMPP_BCHKLM','TPRMPP_BCHKLL',
        'TPRMPP_BCMMTM','TPRMPP_BCMMTL','TPRMPP_BEVALM','TPRMPP_BEVALL',
        'TPRMPP_BMQNAM','TPRMPP_BMQNAL','TPRMPP_BPERFM','TPRMPP_BPERFL',
        'TPRMPP_BPOVWM','TPRMPP_BPOVWL','TPRMPP_BPQNAM','TPRMPP_BPQNAL',
        'TPRMPP_BRSLTM','TPRMPP_BRSLTL','TPRMPP_BSCHDM','TPRMPP_BSCHDL'))) LOOP
        run_if(t.tbl, 'ASCT_ID',
            'ALTER TABLE ITPAPP.' || t.tbl || ' RENAME COLUMN ASCT_ID TO IT_PTL_ASCT_ID');
    END LOOP;

    -- =================================================================
    -- 2) BASCTM / BASCTL (협의회 기본)
    -- =================================================================
    FOR t IN (SELECT column_value tbl FROM TABLE(SYS.ODCIVARCHAR2LIST('TPRMPP_BASCTM','TPRMPP_BASCTL'))) LOOP
        -- 상태코드: 3자리 → 2자리 변환 후 rename + 축소
        run_if(t.tbl, 'ASCT_STS_C',
            'UPDATE ITPAPP.' || t.tbl || ' SET ASCT_STS_C = SUBSTR(ASCT_STS_C, -2) WHERE LENGTH(ASCT_STS_C) > 2');
        run_if(t.tbl, 'ASCT_STS_C',
            'ALTER TABLE ITPAPP.' || t.tbl || ' MODIFY (ASCT_STS_C VARCHAR2(2 CHAR))');
        run_if(t.tbl, 'ASCT_STS_C',
            'ALTER TABLE ITPAPP.' || t.tbl || ' RENAME COLUMN ASCT_STS_C TO IT_PTL_ASCT_PRG_STS_TC');
        -- 심의구분코드: 동일 규칙
        run_if(t.tbl, 'DBR_TC',
            'UPDATE ITPAPP.' || t.tbl || ' SET DBR_TC = SUBSTR(DBR_TC, -2) WHERE LENGTH(DBR_TC) > 2');
        run_if(t.tbl, 'DBR_TC',
            'ALTER TABLE ITPAPP.' || t.tbl || ' MODIFY (DBR_TC VARCHAR2(2 CHAR))');
        run_if(t.tbl, 'DBR_TC',
            'ALTER TABLE ITPAPP.' || t.tbl || ' RENAME COLUMN DBR_TC TO IT_PTL_ASCT_DBR_TC');
        -- 회의시간 → 회의시작시각 (폭 6 동일)
        run_if(t.tbl, 'CNRC_TM',
            'ALTER TABLE ITPAPP.' || t.tbl || ' RENAME COLUMN CNRC_TM TO CNRC_STT_TM');
        -- 프로젝트관리번호 → 사업관리번호 (32→30, 데이터 최대 13자)
        run_if(t.tbl, 'PRJ_MNG_NO',
            'ALTER TABLE ITPAPP.' || t.tbl || ' MODIFY (PRJ_MNG_NO VARCHAR2(30 CHAR))');
        run_if(t.tbl, 'PRJ_MNG_NO',
            'ALTER TABLE ITPAPP.' || t.tbl || ' RENAME COLUMN PRJ_MNG_NO TO ABUS_MNG_NO');
        -- 프로젝트순번 → 일련번호 (NUMBER(10)→NUMBER(9): 정밀도 축소는 빈 컬럼 필요 → 신규 컬럼 스왑)
        run_if(t.tbl, 'PRJ_SNO',
            'ALTER TABLE ITPAPP.' || t.tbl || ' ADD (SNO NUMBER(9,0))');
        run_if(t.tbl, 'PRJ_SNO',
            'UPDATE ITPAPP.' || t.tbl || ' SET SNO = PRJ_SNO');
        run_if(t.tbl, 'PRJ_SNO',
            'ALTER TABLE ITPAPP.' || t.tbl || ' DROP COLUMN PRJ_SNO');
        -- 메타 신규 컬럼
        add_if_absent(t.tbl, 'PRTY_IVG_OMT_YN', 'VARCHAR2(1 CHAR)');
        add_if_absent(t.tbl, 'PRTY_IVG_OMT_RSN', 'VARCHAR2(200 CHAR)');
    END LOOP;

    -- =================================================================
    -- 3) BCHKLM / BCHKLL (사전점검) — 엔티티 미존재, DB만 정렬
    -- =================================================================
    FOR t IN (SELECT column_value tbl FROM TABLE(SYS.ODCIVARCHAR2LIST('TPRMPP_BCHKLM','TPRMPP_BCHKLL'))) LOOP
        run_if(t.tbl, 'CKG_ITM_C',
            'UPDATE ITPAPP.' || t.tbl || ' SET CKG_ITM_C = SUBSTR(CKG_ITM_C, -2) WHERE LENGTH(CKG_ITM_C) > 2');
        run_if(t.tbl, 'CKG_ITM_C',
            'ALTER TABLE ITPAPP.' || t.tbl || ' MODIFY (CKG_ITM_C VARCHAR2(2 CHAR))');
        run_if(t.tbl, 'CKG_ITM_C',
            'ALTER TABLE ITPAPP.' || t.tbl || ' RENAME COLUMN CKG_ITM_C TO IT_PTL_CKG_ITM_TC');
        run_if(t.tbl, 'CKG_RCRD',
            'ALTER TABLE ITPAPP.' || t.tbl || ' RENAME COLUMN CKG_RCRD TO QUEL_RCRD');
        run_if(t.tbl, 'CKG_CONE',
            'ALTER TABLE ITPAPP.' || t.tbl || ' MODIFY (CKG_CONE VARCHAR2(1000 CHAR))');
        run_if(t.tbl, 'CKG_CONE',
            'ALTER TABLE ITPAPP.' || t.tbl || ' RENAME COLUMN CKG_CONE TO CKG_OPNN_CONE');
    END LOOP;

    -- =================================================================
    -- 4) BCMMTM / BCMMTL (위원회 구성원)
    -- =================================================================
    FOR t IN (SELECT column_value tbl FROM TABLE(SYS.ODCIVARCHAR2LIST('TPRMPP_BCMMTM','TPRMPP_BCMMTL'))) LOOP
        run_if(t.tbl, 'VLR_TC',
            'UPDATE ITPAPP.' || t.tbl || ' SET VLR_TC = SUBSTR(VLR_TC, -2) WHERE LENGTH(VLR_TC) > 2');
        run_if(t.tbl, 'VLR_TC',
            'ALTER TABLE ITPAPP.' || t.tbl || ' MODIFY (VLR_TC VARCHAR2(2 CHAR))');
        run_if(t.tbl, 'VLR_TC',
            'ALTER TABLE ITPAPP.' || t.tbl || ' RENAME COLUMN VLR_TC TO IT_PTL_ASCT_MEB_TC');
    END LOOP;
    -- 로그 테이블 누락 컬럼 보강 (마스터 BCMMTM에는 CNFM_YN 기존재)
    add_if_absent('TPRMPP_BCMMTL', 'CNFM_YN', 'VARCHAR2(1 CHAR)');

    -- =================================================================
    -- 5) BEVALM / BEVALL (평가)
    -- =================================================================
    FOR t IN (SELECT column_value tbl FROM TABLE(SYS.ODCIVARCHAR2LIST('TPRMPP_BEVALM','TPRMPP_BEVALL'))) LOOP
        run_if(t.tbl, 'CKG_ITM_C',
            'UPDATE ITPAPP.' || t.tbl || ' SET CKG_ITM_C = SUBSTR(CKG_ITM_C, -2) WHERE LENGTH(CKG_ITM_C) > 2');
        run_if(t.tbl, 'CKG_ITM_C',
            'ALTER TABLE ITPAPP.' || t.tbl || ' MODIFY (CKG_ITM_C VARCHAR2(2 CHAR))');
        run_if(t.tbl, 'CKG_ITM_C',
            'ALTER TABLE ITPAPP.' || t.tbl || ' RENAME COLUMN CKG_ITM_C TO IT_PTL_CKG_ITM_TC');
        run_if(t.tbl, 'CKG_RCRD',
            'ALTER TABLE ITPAPP.' || t.tbl || ' RENAME COLUMN CKG_RCRD TO QUEL_RCRD');
    END LOOP;

    -- =================================================================
    -- 6) BMQNAM/L, BPQNAM/L (QnA) — rename + ENO 컬럼 드롭
    -- =================================================================
    FOR t IN (SELECT column_value tbl FROM TABLE(SYS.ODCIVARCHAR2LIST(
        'TPRMPP_BMQNAM','TPRMPP_BMQNAL','TPRMPP_BPQNAM','TPRMPP_BPQNAL'))) LOOP
        run_if(t.tbl, 'QTN_USID',
            'ALTER TABLE ITPAPP.' || t.tbl || ' RENAME COLUMN QTN_USID TO QTN_DWU_USID');
        run_if(t.tbl, 'REP_USID',
            'ALTER TABLE ITPAPP.' || t.tbl || ' RENAME COLUMN REP_USID TO REP_DWU_USID');
        run_if(t.tbl, 'REP_YN',
            'ALTER TABLE ITPAPP.' || t.tbl || ' RENAME COLUMN REP_YN TO QTN_RPD_RLT_YN');
        run_if(t.tbl, 'QTN_ENO',
            'ALTER TABLE ITPAPP.' || t.tbl || ' DROP COLUMN QTN_ENO');
        run_if(t.tbl, 'REP_ENO',
            'ALTER TABLE ITPAPP.' || t.tbl || ' DROP COLUMN REP_ENO');
    END LOOP;

    -- =================================================================
    -- 7) BPERFM / BPERFL (성과지표)
    --    M의 PK(IT_PTL_ASCT_ID, DTP_SNO)는 정밀도 축소 스왑을 위해 재생성
    -- =================================================================
    run_if('TPRMPP_BPERFM', 'DTP_SNO',
        'ALTER TABLE ITPAPP.TPRMPP_BPERFM DROP CONSTRAINT PK_BPERFM');
    FOR t IN (SELECT column_value tbl FROM TABLE(SYS.ODCIVARCHAR2LIST('TPRMPP_BPERFM','TPRMPP_BPERFL'))) LOOP
        -- 지표일련번호: NUMBER(10)→NUMBER(9) 스왑
        run_if(t.tbl, 'DTP_SNO',
            'ALTER TABLE ITPAPP.' || t.tbl || ' ADD (EVL_DTP_SNO NUMBER(9,0))');
        run_if(t.tbl, 'DTP_SNO',
            'UPDATE ITPAPP.' || t.tbl || ' SET EVL_DTP_SNO = DTP_SNO');
        run_if(t.tbl, 'DTP_SNO',
            'ALTER TABLE ITPAPP.' || t.tbl || ' DROP COLUMN DTP_SNO');
        -- rename + 폭 정렬
        run_if(t.tbl, 'DTP_NM',
            'ALTER TABLE ITPAPP.' || t.tbl || ' MODIFY (DTP_NM VARCHAR2(100 CHAR))');
        run_if(t.tbl, 'DTP_NM',
            'ALTER TABLE ITPAPP.' || t.tbl || ' RENAME COLUMN DTP_NM TO EVL_DTP_NM');
        run_if(t.tbl, 'DTP_CONE',
            'ALTER TABLE ITPAPP.' || t.tbl || ' MODIFY (DTP_CONE VARCHAR2(4000 CHAR))');
        run_if(t.tbl, 'DTP_CONE',
            'ALTER TABLE ITPAPP.' || t.tbl || ' RENAME COLUMN DTP_CONE TO EVL_DTP_DFNT_CONE');
        run_if(t.tbl, 'CLF',
            'ALTER TABLE ITPAPP.' || t.tbl || ' MODIFY (CLF VARCHAR2(4000 CHAR))');
        run_if(t.tbl, 'CLF',
            'ALTER TABLE ITPAPP.' || t.tbl || ' RENAME COLUMN CLF TO EVL_DTP_CLF_CONE');
        run_if(t.tbl, 'MSM_PTM_CONE',
            'ALTER TABLE ITPAPP.' || t.tbl || ' MODIFY (MSM_PTM_CONE VARCHAR2(300 CHAR))');
        run_if(t.tbl, 'MSM_PTM_CONE',
            'ALTER TABLE ITPAPP.' || t.tbl || ' RENAME COLUMN MSM_PTM_CONE TO EVL_DTP_MSM_PTM_CONE');
        run_if(t.tbl, 'MSM_CLE',
            'ALTER TABLE ITPAPP.' || t.tbl || ' MODIFY (MSM_CLE VARCHAR2(300 CHAR))');
        run_if(t.tbl, 'MSM_CLE',
            'ALTER TABLE ITPAPP.' || t.tbl || ' RENAME COLUMN MSM_CLE TO EVL_DTP_MSM_CLE_CONE');
        -- 메타 미등재 컬럼 드롭 (기능 축소 결정 완료)
        run_if(t.tbl, 'GL_NV_CONE',
            'ALTER TABLE ITPAPP.' || t.tbl || ' DROP COLUMN GL_NV_CONE');
        run_if(t.tbl, 'MSM_MANR_CONE',
            'ALTER TABLE ITPAPP.' || t.tbl || ' DROP COLUMN MSM_MANR_CONE');
        run_if(t.tbl, 'MSM_STT_DT',
            'ALTER TABLE ITPAPP.' || t.tbl || ' DROP COLUMN MSM_STT_DT');
        run_if(t.tbl, 'MSM_END_DT',
            'ALTER TABLE ITPAPP.' || t.tbl || ' DROP COLUMN MSM_END_DT');
    END LOOP;
    -- PK 재생성 (멱등: 미존재 시에만)
    DECLARE
        v_cnt NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_cnt FROM user_constraints
         WHERE table_name = 'TPRMPP_BPERFM' AND constraint_name = 'PK_BPERFM';
        IF v_cnt = 0 THEN
            EXECUTE IMMEDIATE 'ALTER TABLE ITPAPP.TPRMPP_BPERFM MODIFY (EVL_DTP_SNO NUMBER(9,0) NOT NULL)';
            EXECUTE IMMEDIATE 'ALTER TABLE ITPAPP.TPRMPP_BPERFM ADD CONSTRAINT PK_BPERFM PRIMARY KEY (IT_PTL_ASCT_ID, EVL_DTP_SNO)';
        END IF;
    END;

    -- =================================================================
    -- 8) BPOVWM / BPOVWL (사업개요)
    -- =================================================================
    FOR t IN (SELECT column_value tbl FROM TABLE(SYS.ODCIVARCHAR2LIST('TPRMPP_BPOVWM','TPRMPP_BPOVWL'))) LOOP
        run_if(t.tbl, 'PRJ_NM',
            'ALTER TABLE ITPAPP.' || t.tbl || ' MODIFY (PRJ_NM VARCHAR2(100 CHAR))');
        run_if(t.tbl, 'PRJ_NM',
            'ALTER TABLE ITPAPP.' || t.tbl || ' RENAME COLUMN PRJ_NM TO ABUS_NM');
        run_if(t.tbl, 'PRJ_TRM_CONE',
            'ALTER TABLE ITPAPP.' || t.tbl || ' MODIFY (PRJ_TRM_CONE VARCHAR2(300 CHAR))');
        run_if(t.tbl, 'PRJ_TRM_CONE',
            'ALTER TABLE ITPAPP.' || t.tbl || ' RENAME COLUMN PRJ_TRM_CONE TO ABUS_TRM_CONE');
        run_if(t.tbl, 'PRJ_DES',
            'ALTER TABLE ITPAPP.' || t.tbl || ' RENAME COLUMN PRJ_DES TO ABUS_CONE');
        run_if(t.tbl, 'NCS_CONE',
            'ALTER TABLE ITPAPP.' || t.tbl || ' MODIFY (NCS_CONE VARCHAR2(300 CHAR))');
        run_if(t.tbl, 'NCS_CONE',
            'ALTER TABLE ITPAPP.' || t.tbl || ' RENAME COLUMN NCS_CONE TO ABUS_NCS_CONE');
        run_if(t.tbl, 'XPT_EFF_CONE',
            'ALTER TABLE ITPAPP.' || t.tbl || ' MODIFY (XPT_EFF_CONE VARCHAR2(4000 CHAR))');
        run_if(t.tbl, 'XPT_EFF_CONE',
            'ALTER TABLE ITPAPP.' || t.tbl || ' RENAME COLUMN XPT_EFF_CONE TO DGOG_PPO_CONE');
        -- 예산금액: NUMBER(18,3)→NUMBER(18,0) 스왑 (소수점 절사 없이 반올림)
        run_if(t.tbl, 'PRJ_BG_AMT',
            'ALTER TABLE ITPAPP.' || t.tbl || ' ADD (RQM_BG_AMT NUMBER(18,0))');
        run_if(t.tbl, 'PRJ_BG_AMT',
            'UPDATE ITPAPP.' || t.tbl || ' SET RQM_BG_AMT = ROUND(PRJ_BG_AMT)');
        run_if(t.tbl, 'PRJ_BG_AMT',
            'ALTER TABLE ITPAPP.' || t.tbl || ' DROP COLUMN PRJ_BG_AMT');
        -- 전결권: 명칭 컬럼이 실제로는 2자리 코드값을 보유 → 코드 컬럼으로 rename
        run_if(t.tbl, 'EDRT_NM',
            'ALTER TABLE ITPAPP.' || t.tbl || ' MODIFY (EDRT_NM VARCHAR2(2 CHAR))');
        run_if(t.tbl, 'EDRT_NM',
            'ALTER TABLE ITPAPP.' || t.tbl || ' RENAME COLUMN EDRT_NM TO IT_PTL_EDRT_TC');
        run_if(t.tbl, 'LGL_RGL_YN',
            'ALTER TABLE ITPAPP.' || t.tbl || ' RENAME COLUMN LGL_RGL_YN TO LW_RGL_YN');
        run_if(t.tbl, 'LGL_RGL_NM',
            'ALTER TABLE ITPAPP.' || t.tbl || ' MODIFY (LGL_RGL_NM VARCHAR2(300 CHAR))');
        run_if(t.tbl, 'LGL_RGL_NM',
            'ALTER TABLE ITPAPP.' || t.tbl || ' RENAME COLUMN LGL_RGL_NM TO LW_FDTN');
        run_if(t.tbl, 'FL_MNG_NO',
            'ALTER TABLE ITPAPP.' || t.tbl || ' MODIFY (FL_MNG_NO VARCHAR2(36 CHAR))');
        run_if(t.tbl, 'FL_MNG_NO',
            'ALTER TABLE ITPAPP.' || t.tbl || ' RENAME COLUMN FL_MNG_NO TO FL_MPN_ID');
        run_if(t.tbl, 'KPN_TC',
            'UPDATE ITPAPP.' || t.tbl || ' SET KPN_TC = SUBSTR(KPN_TC, -2) WHERE LENGTH(KPN_TC) > 2');
        run_if(t.tbl, 'KPN_TC',
            'ALTER TABLE ITPAPP.' || t.tbl || ' MODIFY (KPN_TC VARCHAR2(2 CHAR))');
        run_if(t.tbl, 'KPN_TC',
            'ALTER TABLE ITPAPP.' || t.tbl || ' RENAME COLUMN KPN_TC TO KPN_TP_TC');
        run_if(t.tbl, 'PRJ_BG_AMR',
            'ALTER TABLE ITPAPP.' || t.tbl || ' DROP COLUMN PRJ_BG_AMR');
    END LOOP;

    -- =================================================================
    -- 9) BRSLTM / BRSLTL (결과)
    -- =================================================================
    FOR t IN (SELECT column_value tbl FROM TABLE(SYS.ODCIVARCHAR2LIST('TPRMPP_BRSLTM','TPRMPP_BRSLTL'))) LOOP
        run_if(t.tbl, 'FL_MNG_NO',
            'ALTER TABLE ITPAPP.' || t.tbl || ' MODIFY (FL_MNG_NO VARCHAR2(36 CHAR))');
        run_if(t.tbl, 'FL_MNG_NO',
            'ALTER TABLE ITPAPP.' || t.tbl || ' RENAME COLUMN FL_MNG_NO TO FL_MPN_ID');
    END LOOP;

    -- =================================================================
    -- 10) BSCHDM / BSCHDL (일정) — PK 컬럼 rename은 제약 유지됨
    -- =================================================================
    FOR t IN (SELECT column_value tbl FROM TABLE(SYS.ODCIVARCHAR2LIST('TPRMPP_BSCHDM','TPRMPP_BSCHDL'))) LOOP
        run_if(t.tbl, 'DSD_DT',
            'ALTER TABLE ITPAPP.' || t.tbl || ' RENAME COLUMN DSD_DT TO CNRC_DT');
        run_if(t.tbl, 'DSD_TM',
            'ALTER TABLE ITPAPP.' || t.tbl || ' MODIFY (DSD_TM VARCHAR2(6 CHAR))');
        run_if(t.tbl, 'DSD_TM',
            'ALTER TABLE ITPAPP.' || t.tbl || ' RENAME COLUMN DSD_TM TO CNRC_STT_TM');
        run_if(t.tbl, 'PSB_YN',
            'ALTER TABLE ITPAPP.' || t.tbl || ' RENAME COLUMN PSB_YN TO USE_PSB_YN');
    END LOOP;

    -- =================================================================
    -- 11) CBLBCM / CBLBCL (게시물) — 폭은 16 유지 (메타 10은 실데이터와 비호환)
    -- =================================================================
    FOR t IN (SELECT column_value tbl FROM TABLE(SYS.ODCIVARCHAR2LIST('TPRMPP_CBLBCM','TPRMPP_CBLBCL'))) LOOP
        run_if(t.tbl, 'NAC_UNQ_ID',
            'ALTER TABLE ITPAPP.' || t.tbl || ' RENAME COLUMN NAC_UNQ_ID TO NAC_ID');
    END LOOP;

    -- =================================================================
    -- 12) 연관 코드값 2자리 변환 (도메인 일관성)
    -- =================================================================
    -- 공통코드: 점검항목·저장유형 그룹 코드값
    EXECUTE IMMEDIATE q'[UPDATE ITPAPP.TPRMPP_CCODEM SET CDVA_ID = SUBSTR(CDVA_ID, -2)
        WHERE CO_C_ID IN ('CKG_ITM_C','KPN_TC') AND LENGTH(CDVA_ID) > 2]';
    EXECUTE IMMEDIATE q'[UPDATE ITPAPP.TPRMPP_CCODEL SET CDVA_ID = SUBSTR(CDVA_ID, -2)
        WHERE CO_C_ID IN ('CKG_ITM_C','KPN_TC') AND LENGTH(CDVA_ID) > 2]';
    -- 사전점검 항목코드 데이터 (BCHKLC 테이블 자체는 메타 미등재로 스코프 외, 값만 일관화)
    EXECUTE IMMEDIATE q'[UPDATE ITPAPP.TPRMPP_BCHKLC SET CKG_ITM_C = SUBSTR(CKG_ITM_C, -2)
        WHERE LENGTH(CKG_ITM_C) > 2]';
END;
/

-- =====================================================================
-- 13) 컬럼 코멘트 (메타 한글명 기준)
-- =====================================================================
COMMENT ON COLUMN ITPAPP.TPRMPP_BASCTM.IT_PTL_ASCT_ID IS 'IT포탈협의회ID';
COMMENT ON COLUMN ITPAPP.TPRMPP_BASCTM.IT_PTL_ASCT_PRG_STS_TC IS 'IT포탈협의회진행상태구분코드';
COMMENT ON COLUMN ITPAPP.TPRMPP_BASCTM.IT_PTL_ASCT_DBR_TC IS 'IT포탈협의회심의구분코드';
COMMENT ON COLUMN ITPAPP.TPRMPP_BASCTM.CNRC_STT_TM IS '회의시작시각';
COMMENT ON COLUMN ITPAPP.TPRMPP_BASCTM.ABUS_MNG_NO IS '사업관리번호';
COMMENT ON COLUMN ITPAPP.TPRMPP_BASCTM.SNO IS '일련번호';
COMMENT ON COLUMN ITPAPP.TPRMPP_BASCTM.PRTY_IVG_OMT_YN IS '타당성검토생략여부';
COMMENT ON COLUMN ITPAPP.TPRMPP_BASCTM.PRTY_IVG_OMT_RSN IS '타당성검토생략사유';
COMMENT ON COLUMN ITPAPP.TPRMPP_BASCTL.IT_PTL_ASCT_ID IS 'IT포탈협의회ID';
COMMENT ON COLUMN ITPAPP.TPRMPP_BASCTL.IT_PTL_ASCT_PRG_STS_TC IS 'IT포탈협의회진행상태구분코드';
COMMENT ON COLUMN ITPAPP.TPRMPP_BASCTL.IT_PTL_ASCT_DBR_TC IS 'IT포탈협의회심의구분코드';
COMMENT ON COLUMN ITPAPP.TPRMPP_BASCTL.CNRC_STT_TM IS '회의시작시각';
COMMENT ON COLUMN ITPAPP.TPRMPP_BASCTL.ABUS_MNG_NO IS '사업관리번호';
COMMENT ON COLUMN ITPAPP.TPRMPP_BASCTL.SNO IS '일련번호';
COMMENT ON COLUMN ITPAPP.TPRMPP_BASCTL.PRTY_IVG_OMT_YN IS '타당성검토생략여부';
COMMENT ON COLUMN ITPAPP.TPRMPP_BASCTL.PRTY_IVG_OMT_RSN IS '타당성검토생략사유';
COMMENT ON COLUMN ITPAPP.TPRMPP_BCHKLM.IT_PTL_ASCT_ID IS 'IT포탈협의회ID';
COMMENT ON COLUMN ITPAPP.TPRMPP_BCHKLM.IT_PTL_CKG_ITM_TC IS 'IT포탈점검항목구분코드';
COMMENT ON COLUMN ITPAPP.TPRMPP_BCHKLM.QUEL_RCRD IS '문항점수';
COMMENT ON COLUMN ITPAPP.TPRMPP_BCHKLM.CKG_OPNN_CONE IS '점검의견내용';
COMMENT ON COLUMN ITPAPP.TPRMPP_BCHKLL.IT_PTL_ASCT_ID IS 'IT포탈협의회ID';
COMMENT ON COLUMN ITPAPP.TPRMPP_BCHKLL.IT_PTL_CKG_ITM_TC IS 'IT포탈점검항목구분코드';
COMMENT ON COLUMN ITPAPP.TPRMPP_BCHKLL.QUEL_RCRD IS '문항점수';
COMMENT ON COLUMN ITPAPP.TPRMPP_BCHKLL.CKG_OPNN_CONE IS '점검의견내용';
COMMENT ON COLUMN ITPAPP.TPRMPP_BCMMTM.IT_PTL_ASCT_ID IS 'IT포탈협의회ID';
COMMENT ON COLUMN ITPAPP.TPRMPP_BCMMTM.IT_PTL_ASCT_MEB_TC IS 'IT포탈협의회구성원구분코드';
COMMENT ON COLUMN ITPAPP.TPRMPP_BCMMTL.IT_PTL_ASCT_ID IS 'IT포탈협의회ID';
COMMENT ON COLUMN ITPAPP.TPRMPP_BCMMTL.IT_PTL_ASCT_MEB_TC IS 'IT포탈협의회구성원구분코드';
COMMENT ON COLUMN ITPAPP.TPRMPP_BCMMTL.CNFM_YN IS '확인여부';
COMMENT ON COLUMN ITPAPP.TPRMPP_BEVALM.IT_PTL_ASCT_ID IS 'IT포탈협의회ID';
COMMENT ON COLUMN ITPAPP.TPRMPP_BEVALM.IT_PTL_CKG_ITM_TC IS 'IT포탈점검항목구분코드';
COMMENT ON COLUMN ITPAPP.TPRMPP_BEVALM.QUEL_RCRD IS '문항점수';
COMMENT ON COLUMN ITPAPP.TPRMPP_BEVALL.IT_PTL_ASCT_ID IS 'IT포탈협의회ID';
COMMENT ON COLUMN ITPAPP.TPRMPP_BEVALL.IT_PTL_CKG_ITM_TC IS 'IT포탈점검항목구분코드';
COMMENT ON COLUMN ITPAPP.TPRMPP_BEVALL.QUEL_RCRD IS '문항점수';
COMMENT ON COLUMN ITPAPP.TPRMPP_BMQNAM.IT_PTL_ASCT_ID IS 'IT포탈협의회ID';
COMMENT ON COLUMN ITPAPP.TPRMPP_BMQNAM.QTN_DWU_USID IS '질의작성사용자ID';
COMMENT ON COLUMN ITPAPP.TPRMPP_BMQNAM.REP_DWU_USID IS '답변작성사용자ID';
COMMENT ON COLUMN ITPAPP.TPRMPP_BMQNAM.QTN_RPD_RLT_YN IS '질의응답결과여부';
COMMENT ON COLUMN ITPAPP.TPRMPP_BMQNAL.IT_PTL_ASCT_ID IS 'IT포탈협의회ID';
COMMENT ON COLUMN ITPAPP.TPRMPP_BMQNAL.QTN_DWU_USID IS '질의작성사용자ID';
COMMENT ON COLUMN ITPAPP.TPRMPP_BMQNAL.REP_DWU_USID IS '답변작성사용자ID';
COMMENT ON COLUMN ITPAPP.TPRMPP_BMQNAL.QTN_RPD_RLT_YN IS '질의응답결과여부';
COMMENT ON COLUMN ITPAPP.TPRMPP_BPQNAM.IT_PTL_ASCT_ID IS 'IT포탈협의회ID';
COMMENT ON COLUMN ITPAPP.TPRMPP_BPQNAM.QTN_DWU_USID IS '질의작성사용자ID';
COMMENT ON COLUMN ITPAPP.TPRMPP_BPQNAM.REP_DWU_USID IS '답변작성사용자ID';
COMMENT ON COLUMN ITPAPP.TPRMPP_BPQNAM.QTN_RPD_RLT_YN IS '질의응답결과여부';
COMMENT ON COLUMN ITPAPP.TPRMPP_BPQNAL.IT_PTL_ASCT_ID IS 'IT포탈협의회ID';
COMMENT ON COLUMN ITPAPP.TPRMPP_BPQNAL.QTN_DWU_USID IS '질의작성사용자ID';
COMMENT ON COLUMN ITPAPP.TPRMPP_BPQNAL.REP_DWU_USID IS '답변작성사용자ID';
COMMENT ON COLUMN ITPAPP.TPRMPP_BPQNAL.QTN_RPD_RLT_YN IS '질의응답결과여부';
COMMENT ON COLUMN ITPAPP.TPRMPP_BPERFM.IT_PTL_ASCT_ID IS 'IT포탈협의회ID';
COMMENT ON COLUMN ITPAPP.TPRMPP_BPERFM.EVL_DTP_SNO IS '평가지표일련번호';
COMMENT ON COLUMN ITPAPP.TPRMPP_BPERFM.EVL_DTP_NM IS '평가지표명';
COMMENT ON COLUMN ITPAPP.TPRMPP_BPERFM.EVL_DTP_DFNT_CONE IS '평가지표정의내용';
COMMENT ON COLUMN ITPAPP.TPRMPP_BPERFM.EVL_DTP_CLF_CONE IS '평가지표계산식내용';
COMMENT ON COLUMN ITPAPP.TPRMPP_BPERFM.EVL_DTP_MSM_PTM_CONE IS '평가지표측정시점내용';
COMMENT ON COLUMN ITPAPP.TPRMPP_BPERFM.EVL_DTP_MSM_CLE_CONE IS '평가지표측정주기내용';
COMMENT ON COLUMN ITPAPP.TPRMPP_BPERFL.IT_PTL_ASCT_ID IS 'IT포탈협의회ID';
COMMENT ON COLUMN ITPAPP.TPRMPP_BPERFL.EVL_DTP_SNO IS '평가지표일련번호';
COMMENT ON COLUMN ITPAPP.TPRMPP_BPERFL.EVL_DTP_NM IS '평가지표명';
COMMENT ON COLUMN ITPAPP.TPRMPP_BPERFL.EVL_DTP_DFNT_CONE IS '평가지표정의내용';
COMMENT ON COLUMN ITPAPP.TPRMPP_BPERFL.EVL_DTP_CLF_CONE IS '평가지표계산식내용';
COMMENT ON COLUMN ITPAPP.TPRMPP_BPERFL.EVL_DTP_MSM_PTM_CONE IS '평가지표측정시점내용';
COMMENT ON COLUMN ITPAPP.TPRMPP_BPERFL.EVL_DTP_MSM_CLE_CONE IS '평가지표측정주기내용';
COMMENT ON COLUMN ITPAPP.TPRMPP_BPOVWM.IT_PTL_ASCT_ID IS 'IT포탈협의회ID';
COMMENT ON COLUMN ITPAPP.TPRMPP_BPOVWM.ABUS_NM IS '사업명';
COMMENT ON COLUMN ITPAPP.TPRMPP_BPOVWM.ABUS_TRM_CONE IS '사업기간내용';
COMMENT ON COLUMN ITPAPP.TPRMPP_BPOVWM.ABUS_CONE IS '사업내용';
COMMENT ON COLUMN ITPAPP.TPRMPP_BPOVWM.ABUS_NCS_CONE IS '사업필요성내용';
COMMENT ON COLUMN ITPAPP.TPRMPP_BPOVWM.DGOG_PPO_CONE IS '효과성목적내용';
COMMENT ON COLUMN ITPAPP.TPRMPP_BPOVWM.RQM_BG_AMT IS '소요예산금액';
COMMENT ON COLUMN ITPAPP.TPRMPP_BPOVWM.IT_PTL_EDRT_TC IS 'IT포탈전결권구분코드';
COMMENT ON COLUMN ITPAPP.TPRMPP_BPOVWM.LW_RGL_YN IS '법률규제여부';
COMMENT ON COLUMN ITPAPP.TPRMPP_BPOVWM.LW_FDTN IS '법률근거';
COMMENT ON COLUMN ITPAPP.TPRMPP_BPOVWM.FL_MPN_ID IS '파일매핑ID';
COMMENT ON COLUMN ITPAPP.TPRMPP_BPOVWM.KPN_TP_TC IS '저장유형구분코드';
COMMENT ON COLUMN ITPAPP.TPRMPP_BPOVWL.IT_PTL_ASCT_ID IS 'IT포탈협의회ID';
COMMENT ON COLUMN ITPAPP.TPRMPP_BPOVWL.ABUS_NM IS '사업명';
COMMENT ON COLUMN ITPAPP.TPRMPP_BPOVWL.ABUS_TRM_CONE IS '사업기간내용';
COMMENT ON COLUMN ITPAPP.TPRMPP_BPOVWL.ABUS_CONE IS '사업내용';
COMMENT ON COLUMN ITPAPP.TPRMPP_BPOVWL.ABUS_NCS_CONE IS '사업필요성내용';
COMMENT ON COLUMN ITPAPP.TPRMPP_BPOVWL.DGOG_PPO_CONE IS '효과성목적내용';
COMMENT ON COLUMN ITPAPP.TPRMPP_BPOVWL.RQM_BG_AMT IS '소요예산금액';
COMMENT ON COLUMN ITPAPP.TPRMPP_BPOVWL.IT_PTL_EDRT_TC IS 'IT포탈전결권구분코드';
COMMENT ON COLUMN ITPAPP.TPRMPP_BPOVWL.LW_RGL_YN IS '법률규제여부';
COMMENT ON COLUMN ITPAPP.TPRMPP_BPOVWL.LW_FDTN IS '법률근거';
COMMENT ON COLUMN ITPAPP.TPRMPP_BPOVWL.FL_MPN_ID IS '파일매핑ID';
COMMENT ON COLUMN ITPAPP.TPRMPP_BPOVWL.KPN_TP_TC IS '저장유형구분코드';
COMMENT ON COLUMN ITPAPP.TPRMPP_BRSLTM.IT_PTL_ASCT_ID IS 'IT포탈협의회ID';
COMMENT ON COLUMN ITPAPP.TPRMPP_BRSLTM.FL_MPN_ID IS '파일매핑ID';
COMMENT ON COLUMN ITPAPP.TPRMPP_BRSLTL.IT_PTL_ASCT_ID IS 'IT포탈협의회ID';
COMMENT ON COLUMN ITPAPP.TPRMPP_BRSLTL.FL_MPN_ID IS '파일매핑ID';
COMMENT ON COLUMN ITPAPP.TPRMPP_BSCHDM.IT_PTL_ASCT_ID IS 'IT포탈협의회ID';
COMMENT ON COLUMN ITPAPP.TPRMPP_BSCHDM.CNRC_DT IS '회의일자';
COMMENT ON COLUMN ITPAPP.TPRMPP_BSCHDM.CNRC_STT_TM IS '회의시작시각';
COMMENT ON COLUMN ITPAPP.TPRMPP_BSCHDM.USE_PSB_YN IS '사용가능여부';
COMMENT ON COLUMN ITPAPP.TPRMPP_BSCHDL.IT_PTL_ASCT_ID IS 'IT포탈협의회ID';
COMMENT ON COLUMN ITPAPP.TPRMPP_BSCHDL.CNRC_DT IS '회의일자';
COMMENT ON COLUMN ITPAPP.TPRMPP_BSCHDL.CNRC_STT_TM IS '회의시작시각';
COMMENT ON COLUMN ITPAPP.TPRMPP_BSCHDL.USE_PSB_YN IS '사용가능여부';
COMMENT ON COLUMN ITPAPP.TPRMPP_CBLBCM.NAC_ID IS '게시물ID';
COMMENT ON COLUMN ITPAPP.TPRMPP_CBLBCL.NAC_ID IS '게시물ID';

COMMIT;
