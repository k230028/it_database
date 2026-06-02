-- =====================================================================
-- 마이그레이션 결과 검증 (ITPAPP_TEST 로 실행). 각 줄 PASS/FAIL.
-- =====================================================================
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
SET LINESIZE 200
SET DEFINE OFF

-- helper: 컬럼 존재수
-- 1) 단순 길이정규화: ABUS_C -> BG_UNT_ABUS_C, 길이 3, 패딩 trim
SELECT '1 ABUS_C->BG_UNT_ABUS_C rename: '||CASE WHEN
  (SELECT COUNT(*) FROM user_tab_columns WHERE table_name='TPRMPP_BCOSTM' AND column_name='ABUS_C')=0
  AND (SELECT COUNT(*) FROM user_tab_columns WHERE table_name='TPRMPP_BCOSTM' AND column_name='BG_UNT_ABUS_C')=1
  THEN 'PASS' ELSE 'FAIL' END FROM dual;
SELECT '2 BG_UNT_ABUS_C 길이=3: '||CASE WHEN
  (SELECT char_length FROM user_tab_columns WHERE table_name='TPRMPP_BCOSTM' AND column_name='BG_UNT_ABUS_C')=3
  THEN 'PASS' ELSE 'FAIL' END FROM dual;
SELECT '3 패딩 trim (1+공백->1): '||CASE WHEN
  (SELECT COUNT(*) FROM TPRMPP_BCOSTM WHERE BG_UNT_ABUS_C='1')=1
  THEN 'PASS' ELSE 'FAIL' END FROM dual;
-- 4) 길이정규화: IT_MNGC_NO -> BG_NO 15
SELECT '4 IT_MNGC_NO->BG_NO(15): '||CASE WHEN
  (SELECT COUNT(*) FROM user_tab_columns WHERE table_name='TPRMPP_BCOSTM' AND column_name='IT_MNGC_NO')=0
  AND (SELECT char_length FROM user_tab_columns WHERE table_name='TPRMPP_BCOSTM' AND column_name='BG_NO')=15
  THEN 'PASS' ELSE 'FAIL' END FROM dual;
-- 5) 오버플로우 SKIP: PUL_DTT -> ABUS_TC, rename 됐으나 길이 100 유지(축소 보류), 값 보존
SELECT '5 PUL_DTT->ABUS_TC rename+길이보류(100): '||CASE WHEN
  (SELECT COUNT(*) FROM user_tab_columns WHERE table_name='TPRMPP_BCOSTM' AND column_name='PUL_DTT')=0
  AND (SELECT char_length FROM user_tab_columns WHERE table_name='TPRMPP_BCOSTM' AND column_name='ABUS_TC')=100
  AND (SELECT COUNT(*) FROM TPRMPP_BCOSTM WHERE ABUS_TC='ABC')=1
  THEN 'PASS' ELSE 'FAIL' END FROM dual;
-- 6) 타입만변환: FST_DFR_DT DATE->VARCHAR2(8), 값 20260115
SELECT '6 FST_DFR_DT DATE->VARCHAR2(8)=20260115: '||CASE WHEN
  (SELECT data_type FROM user_tab_columns WHERE table_name='TPRMPP_BCOSTM' AND column_name='FST_DFR_DT')='VARCHAR2'
  AND (SELECT COUNT(*) FROM TPRMPP_BCOSTM WHERE FST_DFR_DT='20260115')=1
  THEN 'PASS' ELSE 'FAIL' END FROM dual;
-- 7) 타입변경 rename: CMMT_MNG_NO -> CMMT_SNO NUMBER, 값 12345
SELECT '7 CMMT_MNG_NO->CMMT_SNO(NUMBER)=12345: '||CASE WHEN
  (SELECT COUNT(*) FROM user_tab_columns WHERE table_name='TPRMPP_CCMMTM' AND column_name='CMMT_MNG_NO')=0
  AND (SELECT data_type FROM user_tab_columns WHERE table_name='TPRMPP_CCMMTM' AND column_name='CMMT_SNO')='NUMBER'
  AND (SELECT COUNT(*) FROM TPRMPP_CCMMTM WHERE CMMT_SNO=12345)=1
  THEN 'PASS' ELSE 'FAIL' END FROM dual;
-- 8) 타입변경 rename: FSG_TLM -> RVW_FSG_TLM_DT VARCHAR2(8) 20260201
SELECT '8 FSG_TLM->RVW_FSG_TLM_DT(VARCHAR2 8)=20260201: '||CASE WHEN
  (SELECT data_type FROM user_tab_columns WHERE table_name='TPRMPP_BRDOCM' AND column_name='RVW_FSG_TLM_DT')='VARCHAR2'
  AND (SELECT COUNT(*) FROM TPRMPP_BRDOCM WHERE RVW_FSG_TLM_DT='20260201')=1
  THEN 'PASS' ELSE 'FAIL' END FROM dual;
-- 9) 진짜 충돌 보류: BITEMM GCL_SNO/PRJ_SNO 둘 다 유지, SNO 미생성
SELECT '9 BITEMM 충돌보류(GCL_SNO&PRJ_SNO 유지, SNO 없음): '||CASE WHEN
  (SELECT COUNT(*) FROM user_tab_columns WHERE table_name='TPRMPP_BITEMM' AND column_name IN ('GCL_SNO','PRJ_SNO'))=2
  AND (SELECT COUNT(*) FROM user_tab_columns WHERE table_name='TPRMPP_BITEMM' AND column_name='SNO')=0
  THEN 'PASS' ELSE 'FAIL' END FROM dual;
-- 10) 빈중복 해소: BRIVGM IDC_ID->RFR_ID, MARK_ID drop, QOT_CONE->RFR_CONE, QTD_CONE drop
SELECT '10 BRIVGM 빈중복 해소: '||CASE WHEN
  (SELECT COUNT(*) FROM user_tab_columns WHERE table_name='TPRMPP_BRIVGM' AND column_name IN ('IDC_ID','MARK_ID','QOT_CONE','QTD_CONE'))=0
  AND (SELECT COUNT(*) FROM user_tab_columns WHERE table_name='TPRMPP_BRIVGM' AND column_name IN ('RFR_ID','RFR_CONE'))=2
  AND (SELECT COUNT(*) FROM TPRMPP_BRIVGM WHERE RFR_ID='IDA' AND RFR_CONE='hello')=1
  THEN 'PASS' ELSE 'FAIL' END FROM dual;
-- 11) 빈중복 해소: CBLBCL END_DT->END_DTM, END_YMD drop, STT_DT->STT_DTM, STT_YMD drop
SELECT '11 CBLBCL 빈중복 해소: '||CASE WHEN
  (SELECT COUNT(*) FROM user_tab_columns WHERE table_name='TPRMPP_CBLBCL' AND column_name IN ('END_YMD','STT_YMD','END_DT','STT_DT'))=0
  AND (SELECT COUNT(*) FROM user_tab_columns WHERE table_name='TPRMPP_CBLBCL' AND column_name IN ('END_DTM','STT_DTM'))=2
  THEN 'PASS' ELSE 'FAIL' END FROM dual;
-- 12) drop: CBLBCM.KD_C 제거
SELECT '12 CBLBCM.KD_C drop: '||CASE WHEN
  (SELECT COUNT(*) FROM user_tab_columns WHERE table_name='TPRMPP_CBLBCM' AND column_name='KD_C')=0
  THEN 'PASS' ELSE 'FAIL' END FROM dual;
EXIT
