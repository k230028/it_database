-- =====================================================================
-- 게시물 그룹 식별자 컬럼 물리명 정합: NAC_ID → NAC_UNQ_ID
-- =====================================================================
-- 배경:
--   답변글 트리의 그룹(원글) 식별자 컬럼을 메타사전 표준 용어인
--   8820 '게시물고유ID'(NAC_UNQ_ID, VARCHAR2(16))로 정합한다.
--   기존 물리명 NAC_ID('게시물ID')는 엔티티 필드 nacId 와 함께 nacUnqId 로
--   리네임되었다(Cblbcm.nacUnqId / CblbcmL.nacUnqId).
--
--   대상 테이블:
--     1) TPRMPP_CBLBCM.NAC_ID → NAC_UNQ_ID   (게시물 마스터, 엔티티 Cblbcm)
--     2) TPRMPP_CBLBCL.NAC_ID → NAC_UNQ_ID   (변경이력 미러, 엔티티 CblbcmL)
--
--   컬럼 폭은 직전 마이그레이션(V20260605_006)에서 마스터 VARCHAR2(16),
--   로그 VARCHAR2(32)로 확대되어 있었으나, 게시물고유ID 표준 폭(16)으로
--   통일하기 위해 본 스크립트에서 RENAME 후 로그 컬럼을 VARCHAR2(16)으로
--   축소한다. 저장값(원글 NAC_NO, 예: 'NAC-2026-0001' = 13자)이 16자 이내이므로
--   축소해도 데이터 손실이 없다(ORA-01441 미발생).
--
--   감사 로그 복사기(AuditLogPersister.copyColumnFields)는 @Column(name)
--   물리컬럼명 기준으로 마스터→로그를 매핑하므로, 두 테이블을 동일 물리명
--   (NAC_UNQ_ID)으로 정합해야 그룹 식별자 변경 이력 복사가 정상 연결된다.
--
-- 멱등성: 구 컬럼(NAC_ID)이 존재하고 신 컬럼(NAC_UNQ_ID)이 아직 없을 때만
--         RENAME 하므로 재실행/부분적용에도 안전하다.
-- =====================================================================

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
    -- 1) 게시물 마스터
    rename_col('TPRMPP_CBLBCM', 'NAC_ID', 'NAC_UNQ_ID');
    EXECUTE IMMEDIATE q'[COMMENT ON COLUMN TPRMPP_CBLBCM.NAC_UNQ_ID IS '게시물고유ID']';

    -- 2) 게시물 변경로그 (RENAME 후 표준 폭 16으로 통일)
    rename_col('TPRMPP_CBLBCL', 'NAC_ID', 'NAC_UNQ_ID');
    EXECUTE IMMEDIATE 'ALTER TABLE TPRMPP_CBLBCL MODIFY ("NAC_UNQ_ID" VARCHAR2(16 CHAR))';
    EXECUTE IMMEDIATE q'[COMMENT ON COLUMN TPRMPP_CBLBCL.NAC_UNQ_ID IS '게시물고유ID']';
END;
/
