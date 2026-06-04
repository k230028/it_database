-- 메뉴 도메인 화면구분코드 컬럼 물리명/타입 정합
--   * TPRMPP_CMENUM.SRE_TC → SYS_HRK_MNU_ID (VARCHAR2(2) → VARCHAR2(10))  [메뉴 마스터]
--   * TPRMPP_CMENUL.SRE_TC → SYS_HRK_MNU_ID (VARCHAR2(2) → VARCHAR2(10))  [변경 로그 테이블]
--   * TPRMPP_CMENUD.SRE_TC → SYS_HRK_MNU_ID (VARCHAR2(2) → VARCHAR2(10))  [화면상세/라우트 카탈로그]
--
-- 사유: 메타사전 표준용어(41283 '시스템상위메뉴ID', SYS_HRK_MNU_ID, VARCHAR2(10))로 정합.
--       통합관리자 시스템 화면의 상위레벨 시스템메뉴ID 용도에 맞춰 물리명과 길이를 변경합니다.
--
-- 변경 로그 테이블(TPRMPP_CMENUL)도 함께 변경합니다. 감사 로그 복사기
-- (AuditLogPersister.copyColumnFields)는 @Column(name) 물리컬럼명 기준으로 원본→로그를
-- 매핑하므로, 마스터만 변경하면 해당 필드의 로그 복사가 조용히 끊깁니다.
--
-- 인덱스 IDX_CMENUM_TREE(SRE_TC, HRK_MNU_ID, MNU_SOT_SQN_SNO)는 RENAME COLUMN 시
-- 컬럼 참조가 자동으로 갱신되므로 별도 재생성이 필요 없습니다.
--
-- 멱등성: 구 컬럼이 존재하고 신 컬럼이 아직 없을 때만 RENAME 하며, MODIFY는 신 컬럼 기준으로
--         동일/확장 길이를 지정하므로 재실행/부분적용에도 안전합니다.

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

    -- 컬럼 길이 확장: 신 컬럼이 존재할 때만 VARCHAR2(10 CHAR)로 MODIFY (확장은 멱등)
    PROCEDURE widen_col(p_table VARCHAR2, p_col VARCHAR2) IS
        v_cnt NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_cnt FROM USER_TAB_COLS
         WHERE TABLE_NAME = p_table AND COLUMN_NAME = p_col;
        IF v_cnt > 0 THEN
            EXECUTE IMMEDIATE 'ALTER TABLE ' || p_table ||
                              ' MODIFY (' || p_col || ' VARCHAR2(10 CHAR))';
        END IF;
    END;
BEGIN
    -- 1) 컬럼 리네임 (SRE_TC → SYS_HRK_MNU_ID)
    rename_col('TPRMPP_CMENUM', 'SRE_TC', 'SYS_HRK_MNU_ID');
    rename_col('TPRMPP_CMENUL', 'SRE_TC', 'SYS_HRK_MNU_ID');
    rename_col('TPRMPP_CMENUD', 'SRE_TC', 'SYS_HRK_MNU_ID');

    -- 2) 컬럼 길이 확장 (VARCHAR2(2) → VARCHAR2(10))
    widen_col('TPRMPP_CMENUM', 'SYS_HRK_MNU_ID');
    widen_col('TPRMPP_CMENUL', 'SYS_HRK_MNU_ID');
    widen_col('TPRMPP_CMENUD', 'SYS_HRK_MNU_ID');

    -- 3) 컬럼 코멘트 정합 (화면구분코드 → 시스템상위메뉴ID)
    EXECUTE IMMEDIATE q'[COMMENT ON COLUMN TPRMPP_CMENUM.SYS_HRK_MNU_ID IS '시스템상위메뉴ID']';
    EXECUTE IMMEDIATE q'[COMMENT ON COLUMN TPRMPP_CMENUL.SYS_HRK_MNU_ID IS '시스템상위메뉴ID']';
    EXECUTE IMMEDIATE q'[COMMENT ON COLUMN TPRMPP_CMENUD.SYS_HRK_MNU_ID IS '시스템상위메뉴ID']';
END;
/
