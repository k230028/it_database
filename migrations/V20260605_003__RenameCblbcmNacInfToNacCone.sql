-- 게시판 본문(게시물) 마스터 테이블 본문 컬럼 물리명 정합
--   * TPRMPP_CBLBCM.NAC_INF → NAC_CONE (VARCHAR2(4000), 길이 동일)  [게시물 마스터]
--
-- 사유: 게시물 본문 컬럼의 표준 물리명은 메타사전 8811 '게시물내용'(NAC_CONE, VARCHAR2(4000))이며,
--       엔티티 Cblbcm.nacCone / 로그 엔티티 CblbcmL.nacCone, 변경 로그 테이블 TPRMPP_CBLBCL,
--       공통게시판 설계 문서가 모두 NAC_CONE을 사용합니다. 운영 덤프 임포트 과정에서 마스터
--       테이블 한 곳만 NAC_INF(8842 '게시물정보')로 어긋나 ddl-auto=validate 기동이 실패합니다.
--       유일하게 어긋난 마스터 컬럼을 표준 물리명으로 되돌려 정합합니다.
--
-- 로그 테이블(TPRMPP_CBLBCL)은 이미 NAC_CONE이므로 변경 대상이 아닙니다. 감사 로그 복사기
-- (AuditLogPersister.copyColumnFields)는 @Column(name) 물리컬럼명 기준으로 마스터→로그를
-- 매핑하므로, 마스터를 NAC_CONE으로 정합하면 본문 변경 이력 복사가 정상 연결됩니다.
--
-- 타입/길이는 VARCHAR2(4000)로 동일하여 RENAME만 수행합니다.
--
-- 멱등성: 구 컬럼(NAC_INF)이 존재하고 신 컬럼(NAC_CONE)이 아직 없을 때만 RENAME 하므로
--         재실행/부분적용에도 안전합니다.

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
    -- 1) 컬럼 리네임 (NAC_INF → NAC_CONE), 마스터 테이블만 대상
    rename_col('TPRMPP_CBLBCM', 'NAC_INF', 'NAC_CONE');

    -- 2) 컬럼 코멘트 정합 (게시물정보 → 게시물내용)
    EXECUTE IMMEDIATE q'[COMMENT ON COLUMN TPRMPP_CBLBCM.NAC_CONE IS '게시물내용']';
END;
/
