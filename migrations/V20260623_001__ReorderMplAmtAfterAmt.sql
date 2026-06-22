-- V20260623_001__ReorderMplAmtAfterAmt.sql
-- TPRMPP_BITEMM / TPRMPP_BITEML 에서 MPL_AMT 컬럼을 AMT 컬럼 바로 뒤로 물리 재배치.
--   V20260622_006 의 ADD 는 Oracle 특성상 컬럼을 테이블 맨 끝에 추가하므로,
--   업무 의도(품목금액 AMT 다음에 익년 이후 예정분 MPL_AMT)대로 가시 순서를 맞춘다.
-- 기법: Oracle은 ALTER TABLE ... ADD 위치 지정을 지원하지 않으므로,
--   AMT 뒤의 모든 컬럼을 INVISIBLE 처리한 뒤 원하는 순서(MPL_AMT 먼저)로 VISIBLE 로 되돌린다.
--   컬럼을 VISIBLE 로 전환하면 가시 컬럼 순서의 맨 뒤로 이동하는 특성을 이용한다.
--   메타데이터 전용 작업으로 데이터·제약(NOT NULL/DEFAULT/인덱스)은 보존된다.
-- 멱등성: MPL_AMT 가 이미 AMT 바로 다음(column_id = AMT + 1)이면 건너뛴다.
-- 이식성: AMT 뒤 트레일링 컬럼 목록을 하드코딩하지 않고 데이터 사전에서 동적 수집한다.
DECLARE
    PROCEDURE reorder_mpl_after_amt(p_table VARCHAR2) IS
        v_amt_id NUMBER;
        v_mpl_id NUMBER;
        TYPE name_list IS TABLE OF VARCHAR2(128);
        v_cols name_list;
    BEGIN
        SELECT MAX(CASE WHEN column_name = 'AMT'     THEN column_id END),
               MAX(CASE WHEN column_name = 'MPL_AMT' THEN column_id END)
          INTO v_amt_id, v_mpl_id
          FROM all_tab_columns
         WHERE owner = SYS_CONTEXT('USERENV','CURRENT_SCHEMA')
           AND table_name = p_table;

        -- 대상 컬럼이 없거나 이미 정렬되어 있으면 종료
        IF v_amt_id IS NULL OR v_mpl_id IS NULL THEN RETURN; END IF;
        IF v_mpl_id = v_amt_id + 1 THEN RETURN; END IF;

        -- AMT 뒤의 컬럼(MPL_AMT 제외)을 현재 순서대로 수집
        SELECT column_name BULK COLLECT INTO v_cols
          FROM all_tab_columns
         WHERE owner = SYS_CONTEXT('USERENV','CURRENT_SCHEMA')
           AND table_name = p_table
           AND column_id > v_amt_id
           AND column_name <> 'MPL_AMT'
         ORDER BY column_id;

        -- 1) AMT 뒤 컬럼 전체를 INVISIBLE 로 (가시 순서가 AMT 에서 끝나도록)
        EXECUTE IMMEDIATE 'ALTER TABLE ' || p_table || ' MODIFY (MPL_AMT INVISIBLE)';
        FOR i IN 1 .. v_cols.COUNT LOOP
            EXECUTE IMMEDIATE 'ALTER TABLE ' || p_table || ' MODIFY ("' || v_cols(i) || '" INVISIBLE)';
        END LOOP;

        -- 2) 원하는 순서로 VISIBLE: MPL_AMT 를 먼저 되돌려 AMT 바로 뒤에 오게 한 뒤 나머지 복원
        EXECUTE IMMEDIATE 'ALTER TABLE ' || p_table || ' MODIFY (MPL_AMT VISIBLE)';
        FOR i IN 1 .. v_cols.COUNT LOOP
            EXECUTE IMMEDIATE 'ALTER TABLE ' || p_table || ' MODIFY ("' || v_cols(i) || '" VISIBLE)';
        END LOOP;
    END;
BEGIN
    reorder_mpl_after_amt('TPRMPP_BITEMM');
    reorder_mpl_after_amt('TPRMPP_BITEML');
END;
/
