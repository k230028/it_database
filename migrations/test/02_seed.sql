-- =====================================================================
-- 엣지케이스 시드 (ITPAPP_TEST 로 실행)
-- =====================================================================
SET FEEDBACK OFF

-- 테스트 편의를 위해 모든 컬럼 NOT NULL 해제(부분 INSERT 허용)
BEGIN
  FOR c IN (SELECT table_name, column_name FROM user_tab_columns WHERE nullable='N') LOOP
    BEGIN
      EXECUTE IMMEDIATE 'ALTER TABLE '||c.table_name||' MODIFY ("'||c.column_name||'" NULL)';
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
  END LOOP;
END;
/

-- [길이정규화] ABUS_C(100->BG_UNT_ABUS_C 3): 패딩 trim으로 맞음
-- [오버플로우 SKIP] PUL_DTT(100->ABUS_TC 2): 'ABC' 길이3 -> MODIFY 보류
-- [타입만변환] FST_DFR_DT(DATE->VARCHAR2 8): 20260115
-- [길이정규화] IT_MNGC_NO(32->BG_NO 15)
INSERT INTO TPRMPP_BCOSTM (ABUS_C, PUL_DTT, FST_DFR_DT, IT_MNGC_NO, XCR_BSE_DT)
  VALUES (RPAD('1',6), 'ABC', DATE '2026-01-15', 'COST0001', DATE '2026-02-20');
INSERT INTO TPRMPP_BCOSTM (ABUS_C, PUL_DTT, FST_DFR_DT, IT_MNGC_NO)
  VALUES ('001', 'Z', DATE '2026-01-16', 'COST0002');

-- [타입변경 rename] CMMT_MNG_NO(VARCHAR2->CMMT_SNO NUMBER) 등
INSERT INTO TPRMPP_CCMMTM (CMMT_MNG_NO, CMMT_GRP_NO, HRK_CMMT_MNG_NO)
  VALUES ('12345', '67', '89');

-- [타입변경 rename] FSG_TLM(DATE->RVW_FSG_TLM_DT VARCHAR2 8)
INSERT INTO TPRMPP_BRDOCM (FSG_TLM, REQ_NM) VALUES (DATE '2026-02-01', 'doc-A');

-- [진짜 충돌: 둘 다 데이터 -> 보류, 변경 안 됨]
INSERT INTO TPRMPP_BITEMM (GCL_SNO, PRJ_SNO) VALUES (10, 20);

-- [빈 중복 해소] IDC_ID 데이터/MARK_ID 빈값, QOT_CONE 데이터/QTD_CONE 빈값
INSERT INTO TPRMPP_BRIVGM (IDC_ID, MARK_ID, QOT_CONE, QTD_CONE)
  VALUES ('IDA', NULL, 'hello', NULL);

-- [빈 중복 해소] CBLBCL: END_DT/END_YMD/STT_DT/STT_YMD 전부 NULL (행만 존재)
INSERT INTO TPRMPP_CBLBCL (NAC_MNG_NO) VALUES ('post-1');

-- [drop] CBLBCM.KD_C
INSERT INTO TPRMPP_CBLBCM (KD_C) VALUES ('k');

COMMIT;
EXIT
