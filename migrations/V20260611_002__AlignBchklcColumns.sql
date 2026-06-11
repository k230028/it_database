-- V20260611_002__AlignBchklcColumns.sql
-- 사전점검 항목(BCHKLC) 컬럼을 메타 용어사전 표준 명칭으로 정렬
--
-- 배경:
--  - BCHKLC 테이블 자체는 메타 미등재(추후 등재 대상)이나, BCHKLM/BEVALM과 동일한
--    협의회ID·점검항목코드 도메인을 공유하므로 V20260611_001과 같은 표준 명칭으로
--    정렬해 코드/스키마 일관성을 유지한다. (코드값 2자리 변환은 _001에서 완료)
--  - CKG_CONE(점검내용)은 항목 설명 텍스트로 BCHKLM의 점검의견(CKG_OPNN_CONE)과
--    의미가 달라 유지한다.
--
-- 멱등성: 컬럼 존재 여부 가드 후 실행하므로 재실행 안전.

DECLARE
    PROCEDURE run_if(p_col VARCHAR2, p_sql VARCHAR2) IS
        v_cnt NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_cnt FROM user_tab_columns
         WHERE table_name = 'TPRMPP_BCHKLC' AND column_name = p_col;
        IF v_cnt > 0 THEN
            EXECUTE IMMEDIATE p_sql;
        END IF;
    END;
BEGIN
    run_if('ASCT_ID', 'ALTER TABLE ITPAPP.TPRMPP_BCHKLC RENAME COLUMN ASCT_ID TO IT_PTL_ASCT_ID');
    run_if('CKG_ITM_C', 'ALTER TABLE ITPAPP.TPRMPP_BCHKLC MODIFY (CKG_ITM_C VARCHAR2(2 CHAR))');
    run_if('CKG_ITM_C', 'ALTER TABLE ITPAPP.TPRMPP_BCHKLC RENAME COLUMN CKG_ITM_C TO IT_PTL_CKG_ITM_TC');
    run_if('CKG_RCRD', 'ALTER TABLE ITPAPP.TPRMPP_BCHKLC RENAME COLUMN CKG_RCRD TO QUEL_RCRD');
END;
/

COMMENT ON COLUMN ITPAPP.TPRMPP_BCHKLC.IT_PTL_ASCT_ID IS 'IT포탈협의회ID';
COMMENT ON COLUMN ITPAPP.TPRMPP_BCHKLC.IT_PTL_CKG_ITM_TC IS 'IT포탈점검항목구분코드';
COMMENT ON COLUMN ITPAPP.TPRMPP_BCHKLC.QUEL_RCRD IS '문항점수';

COMMIT;
