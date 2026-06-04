-- 정보기술부문계획 계획구분 컬럼 물리명 정합
--   * TPRMPP_BPLANM.PLN_TP_C → IT_PTL_PLN_TP_C (VARCHAR2(2))  [마스터]
--   * TPRMPP_BPLANL.PLN_TP_C → IT_PTL_PLN_TP_C (VARCHAR2(2))  [변경 로그 테이블]
--
-- 사유: 물리컬럼 PLN_TP_C는 메타사전 표준용어상 '계획유형코드'(연금성 코드: 확정급여형,
--       퇴직부채_사업결합 등)와 의미가 충돌합니다. IT포탈 도메인 접두사(IT_PTL_)를 부여해
--       '계획구분(신규/조정)' 용도와 분리합니다.
--
-- 변경 로그 테이블(TPRMPP_BPLANL)도 함께 변경합니다. 감사 로그 복사기
-- (AuditLogPersister.copyColumnFields)는 @Column(name) 물리컬럼명 기준으로 원본→로그를
-- 매핑하므로, 마스터만 변경하면 해당 필드의 로그 복사가 조용히 끊깁니다.
--
-- 멱등성: 구 컬럼이 존재하고 신 컬럼이 아직 없을 때만 RENAME 하므로 재실행/부분적용에도 안전합니다.

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
    -- 1) 컬럼 리네임
    rename_col('TPRMPP_BPLANM', 'PLN_TP_C', 'IT_PTL_PLN_TP_C');
    rename_col('TPRMPP_BPLANL', 'PLN_TP_C', 'IT_PTL_PLN_TP_C');

    -- 2) 컬럼 코멘트 정합 (계획유형코드 → 계획구분)
    EXECUTE IMMEDIATE q'[COMMENT ON COLUMN TPRMPP_BPLANM.IT_PTL_PLN_TP_C IS '계획구분']';
    EXECUTE IMMEDIATE q'[COMMENT ON COLUMN TPRMPP_BPLANL.IT_PTL_PLN_TP_C IS '계획구분']';
END;
/
