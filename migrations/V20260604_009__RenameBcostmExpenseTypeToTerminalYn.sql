-- 전산관리비(TPRMPP_BCOSTM) 컬럼 의미·표준용어 정합
--   * BG_XP_TC → TMN_YN (단말여부, VARCHAR2(2)→VARCHAR2(1))
-- BG_XP_TC(전산업무비유형, 공통코드 IT_MNGC_TP)는 사실상 단말 여부 플래그로 사용되어 왔습니다
-- (CostService: BG_XP_TC='002'인 행에만 단말기 목록을 연결). 이를 단말여부(Y/N)로 정합합니다.
--   값 변환: '002'(단말) → 'Y', '001' → 'N', 그 외 → NULL
-- 변경 로그 테이블(TPRMPP_BCOSTL)은 컬럼명만 정합하고 과거 값/폭은 보존합니다(감사 무결성).
--
-- 타입 축소(2→1) 주의: 길이 1 초과 값이 남으면 MODIFY가 실패하므로 값 변환을 먼저 수행합니다.
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
BEGIN
    -- 1) 컬럼 리네임 (마스터 + 변경 로그)
    rename_col('TPRMPP_BCOSTM', 'BG_XP_TC', 'TMN_YN');
    rename_col('TPRMPP_BCOSTL', 'BG_XP_TC', 'TMN_YN');

    -- 2) 마스터 값 변환: 002→Y, 001→N, 그 외→NULL (이미 Y/N이면 보존)
    EXECUTE IMMEDIATE q'[
        UPDATE TPRMPP_BCOSTM
           SET TMN_YN = CASE TMN_YN
                            WHEN '002' THEN 'Y'
                            WHEN '001' THEN 'N'
                            WHEN 'Y'   THEN 'Y'
                            WHEN 'N'   THEN 'N'
                            ELSE NULL
                        END
         WHERE TMN_YN IS NOT NULL
    ]';

    -- 3) 마스터 타입 축소 VARCHAR2(2)→VARCHAR2(1) (현재 길이가 1 초과일 때만)
    DECLARE
        v_len USER_TAB_COLS.DATA_LENGTH%TYPE;
    BEGIN
        SELECT DATA_LENGTH INTO v_len FROM USER_TAB_COLS
         WHERE TABLE_NAME = 'TPRMPP_BCOSTM' AND COLUMN_NAME = 'TMN_YN';
        IF v_len > 1 THEN
            EXECUTE IMMEDIATE 'ALTER TABLE TPRMPP_BCOSTM MODIFY (TMN_YN VARCHAR2(1))';
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL; -- 대상 컬럼이 없으면(미예상 상태) 조용히 건너뜀
    END;

    -- 4) 컬럼 코멘트 표준용어 정합
    EXECUTE IMMEDIATE q'[COMMENT ON COLUMN TPRMPP_BCOSTM.TMN_YN IS '단말여부 (Y=단말, N=비단말; 구 IT_MNGC_TP 002→Y/001→N)']';
    EXECUTE IMMEDIATE q'[COMMENT ON COLUMN TPRMPP_BCOSTL.TMN_YN IS '단말여부']';
END;
/
