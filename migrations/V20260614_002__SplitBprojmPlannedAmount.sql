-- 정보화사업 예정금액(MPL_AMT) 분리 (마스터 + 변경로그 미러 동시 적용)
--   * TPRMPP_BPROJM.MPL_AMT(예정금액) → MPL_CPIT_AMT(예정자본금액) + MPL_XP_AMT(예정비용금액)
--   * TPRMPP_BPROJL.MPL_AMT(예정금액) → MPL_CPIT_AMT(예정자본금액) + MPL_XP_AMT(예정비용금액)  [변경 로그 테이블]
--
-- 배경: 단일 예정금액을 자본/비용으로 나누어 입력받도록 개선합니다.
--   기존 단일 합계값은 자본·비용으로 자동 분할할 근거가 없어 폐기하고 신규 두 컬럼은 빈 값으로 시작합니다.
--   (현재 애플리케이션 코드가 MPL_AMT를 참조하지 않는 신규 기능이므로 기존 값 손실 영향이 없습니다.)
--
-- 타입: 두 신규 컬럼 모두 기존 MPL_AMT와 동일한 NUMBER(18,3).
-- 멱등성: 신규 컬럼은 부재 시에만 ADD, 구 컬럼은 존재 시에만 DROP 하므로 재실행/부분적용 후에도 안전합니다.
-- 스키마: 객체 소유 스키마는 ITPOWN이고 접속 계정(ITPAPP)과 분리되므로, 존재 여부 판정은
--   접속 계정 기준 USER_TAB_COLS가 아니라 현재 세션 스키마(CURRENT_SCHEMA) 기준 ALL_TAB_COLS로 합니다.
--   (ITPOWN으로 직접 접속하든, ITPAPP에서 ALTER SESSION SET CURRENT_SCHEMA=ITPOWN으로 적용하든 동일하게 동작)

DECLARE
    c_schema CONSTANT VARCHAR2(128) := SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA');

    -- 신규 컬럼 추가: 해당 컬럼이 아직 없을 때만 수행
    PROCEDURE add_col(p_table VARCHAR2, p_col VARCHAR2, p_def VARCHAR2) IS
        v_cnt NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_cnt FROM ALL_TAB_COLS
         WHERE OWNER = c_schema AND TABLE_NAME = p_table AND COLUMN_NAME = p_col;
        IF v_cnt = 0 THEN
            EXECUTE IMMEDIATE 'ALTER TABLE ' || p_table ||
                              ' ADD (' || p_col || ' ' || p_def || ')';
        END IF;
    END;

    -- 구 컬럼 삭제: 해당 컬럼이 존재할 때만 수행
    PROCEDURE drop_col(p_table VARCHAR2, p_col VARCHAR2) IS
        v_cnt NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_cnt FROM ALL_TAB_COLS
         WHERE OWNER = c_schema AND TABLE_NAME = p_table AND COLUMN_NAME = p_col;
        IF v_cnt > 0 THEN
            EXECUTE IMMEDIATE 'ALTER TABLE ' || p_table || ' DROP COLUMN ' || p_col;
        END IF;
    END;
BEGIN
    -- 1) 신규 컬럼 추가 (마스터 + 변경 로그 미러)
    add_col('TPRMPP_BPROJM', 'MPL_CPIT_AMT', 'NUMBER(18,3)');
    add_col('TPRMPP_BPROJM', 'MPL_XP_AMT',   'NUMBER(18,3)');
    add_col('TPRMPP_BPROJL', 'MPL_CPIT_AMT', 'NUMBER(18,3)');
    add_col('TPRMPP_BPROJL', 'MPL_XP_AMT',   'NUMBER(18,3)');

    -- 2) 구 컬럼 삭제 (기존 합계값 폐기)
    drop_col('TPRMPP_BPROJM', 'MPL_AMT');
    drop_col('TPRMPP_BPROJL', 'MPL_AMT');

    -- 3) 컬럼 코멘트 표준용어 정합 (엔티티 @Column comment 와 동기화)
    EXECUTE IMMEDIATE q'[COMMENT ON COLUMN TPRMPP_BPROJM.MPL_CPIT_AMT IS '예정자본금액']';
    EXECUTE IMMEDIATE q'[COMMENT ON COLUMN TPRMPP_BPROJM.MPL_XP_AMT IS '예정비용금액']';
    EXECUTE IMMEDIATE q'[COMMENT ON COLUMN TPRMPP_BPROJL.MPL_CPIT_AMT IS '예정자본금액']';
    EXECUTE IMMEDIATE q'[COMMENT ON COLUMN TPRMPP_BPROJL.MPL_XP_AMT IS '예정비용금액']';
END;
/
