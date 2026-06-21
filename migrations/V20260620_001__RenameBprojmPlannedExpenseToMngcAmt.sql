-- 정보화사업 예정비용금액 → 예정관리비금액 컬럼명 정합 (마스터 + 변경로그 미러 동시 적용)
--   * TPRMPP_BPROJM.MPL_XP_AMT(예정비용금액) → MPL_MNGC_AMT(예정관리비금액)
--   * TPRMPP_BPROJL.MPL_XP_AMT(예정비용금액) → MPL_MNGC_AMT(예정관리비금액)  [변경 로그 테이블]
--
-- 배경: 'FP 산출' 변경에서 엔티티 필드 mplXpAmt → mplMngcAmt 로 표준용어를 변경했으나
--   짝이 되는 DB 컬럼 RENAME 마이그레이션이 누락되어, ddl-auto=validate 가
--   TPRMPP_BPROJL 의 missing column [mpl_mngc_amt] 로 기동 실패했습니다.
--   (V20260614_002 가 만든 MPL_XP_AMT 를 동일 타입으로 이름만 변경합니다.)
--
-- 타입: 기존 MPL_XP_AMT 와 동일한 NUMBER(18,3). RENAME 이므로 데이터 손실 없음.
-- 멱등성: 구 컬럼(MPL_XP_AMT)이 존재하고 신규 컬럼(MPL_MNGC_AMT)이 없을 때만 RENAME 하므로
--   재실행/부분적용 후에도 안전합니다.
-- 스키마: 객체 소유 스키마는 ITPOWN 이고 접속 계정(ITPAPP)과 분리되므로, 존재 여부 판정은
--   접속 계정 기준 USER_TAB_COLS 가 아니라 현재 세션 스키마(CURRENT_SCHEMA) 기준 ALL_TAB_COLS 로 합니다.

DECLARE
    c_schema CONSTANT VARCHAR2(128) := SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA');

    -- 컬럼명 변경: 구 컬럼이 존재하고 신규 컬럼이 아직 없을 때만 수행
    PROCEDURE rename_col(p_table VARCHAR2, p_old VARCHAR2, p_new VARCHAR2) IS
        v_old NUMBER;
        v_new NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_old FROM ALL_TAB_COLS
         WHERE OWNER = c_schema AND TABLE_NAME = p_table AND COLUMN_NAME = p_old;
        SELECT COUNT(*) INTO v_new FROM ALL_TAB_COLS
         WHERE OWNER = c_schema AND TABLE_NAME = p_table AND COLUMN_NAME = p_new;
        IF v_old > 0 AND v_new = 0 THEN
            EXECUTE IMMEDIATE 'ALTER TABLE ' || p_table ||
                              ' RENAME COLUMN ' || p_old || ' TO ' || p_new;
        END IF;
    END;
BEGIN
    -- 1) 컬럼명 변경 (마스터 + 변경 로그 미러)
    rename_col('TPRMPP_BPROJM', 'MPL_XP_AMT', 'MPL_MNGC_AMT');
    rename_col('TPRMPP_BPROJL', 'MPL_XP_AMT', 'MPL_MNGC_AMT');

    -- 2) 컬럼 코멘트 표준용어 정합 (엔티티 @Column comment 와 동기화)
    EXECUTE IMMEDIATE q'[COMMENT ON COLUMN TPRMPP_BPROJM.MPL_MNGC_AMT IS '예정관리비금액']';
    EXECUTE IMMEDIATE q'[COMMENT ON COLUMN TPRMPP_BPROJL.MPL_MNGC_AMT IS '예정관리비금액']';
END;
/
