-- V20260622_001__AlignSchemaWithMeta.sql
-- 메타DB(table.csv) 기준으로 로컬DB(ITPOWN) 스키마 정렬.
-- 비교 출처: schema_diff_report.md (ITPOWN_DDL_live.sql vs table.csv, 2026-06-22)
-- 정렬 항목:
--   A. 컬럼 타입   2건  : BTERML.AMT / BTERMM.AMT  NUMBER(18,0) -> NUMBER(18,3)
--   B. 컬럼 코멘트 6건  : 메타DB 한글명으로 환원
--   C. 컬럼 순서   2개  : BPROJL / BPROJM  (MPL_CPIT_AMT, MPL_MNGC_AMT 를 TOT_RQM_AMT 뒤로)
-- 방식(C): INVISIBLE->VISIBLE 토글로 대상 컬럼을 메타 순서대로 말미 재배치(데이터/제약/인덱스 보존).
--          익명 블록은 ITPAPP 권한 실행 -> ALL_* 뷰(owner=ITPOWN) 조회. 멱등(현재순서 다를 때만).
--          토글 중 SELECT * 결과에서 컬럼이 잠시 빠지므로 앱 무중단 적용 불가(로컬 전용).

SET SERVEROUTPUT ON SIZE UNLIMITED

-- ============================================================
-- A. 컬럼 타입 정렬 (NUMBER(18,0) -> NUMBER(18,3))
--    기존 데이터가 있어 scale 직접 축소는 ORA-01440. 임시컬럼 라운드트립으로 변환.
--    (AMT 컬럼 자체는 drop하지 않으므로 위치/코멘트 보존. 임시컬럼은 추가 후 제거.)
--    멱등: 현재 scale 이 3이면 skip. AMT는 nullable 확인됨 -> NULL 경유 가능.
-- ============================================================
DECLARE
  PROCEDURE align_amt(p_tab VARCHAR2) IS
    v_scale all_tab_columns.data_scale%TYPE;
  BEGIN
    SELECT data_scale INTO v_scale FROM all_tab_columns
     WHERE owner='ITPOWN' AND table_name=p_tab AND column_name='AMT';
    IF v_scale = 3 THEN RETURN; END IF;
    EXECUTE IMMEDIATE 'ALTER TABLE ITPOWN.'||p_tab||' ADD ("AMT__MIG" NUMBER(18,3))';
    EXECUTE IMMEDIATE 'UPDATE ITPOWN.'||p_tab||' SET "AMT__MIG" = "AMT"';
    EXECUTE IMMEDIATE 'UPDATE ITPOWN.'||p_tab||' SET "AMT" = NULL';
    EXECUTE IMMEDIATE 'ALTER TABLE ITPOWN.'||p_tab||' MODIFY ("AMT" NUMBER(18,3))';
    EXECUTE IMMEDIATE 'UPDATE ITPOWN.'||p_tab||' SET "AMT" = "AMT__MIG"';
    EXECUTE IMMEDIATE 'ALTER TABLE ITPOWN.'||p_tab||' DROP COLUMN "AMT__MIG"';
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('RETYPE '||p_tab||'.AMT -> NUMBER(18,3)');
  END;
BEGIN
  align_amt('TPRMPP_BTERML');
  align_amt('TPRMPP_BTERMM');
END;
/

-- ============================================================
-- B. 컬럼 코멘트 정렬 (메타DB 한글명으로 환원)
-- ============================================================
COMMENT ON COLUMN ITPOWN.TPRMPP_BCOSTL."AMT"          IS '금액';
COMMENT ON COLUMN ITPOWN.TPRMPP_BCOSTM."AMT"          IS '금액';
COMMENT ON COLUMN ITPOWN.TPRMPP_BPLANL."TOT_CPIT_AMT" IS '총자본금액';
COMMENT ON COLUMN ITPOWN.TPRMPP_BPLANM."TOT_CPIT_AMT" IS '총자본금액';
COMMENT ON COLUMN ITPOWN.TPRMPP_BTERML."AMT"          IS '금액';
COMMENT ON COLUMN ITPOWN.TPRMPP_BTERMM."AMT"          IS '금액';

-- ============================================================
-- C. 컬럼 순서 정렬 - TPRMPP_BPROJL (50 cols, 메타 순서)
--    TOT_RQM_AMT 이후 컬럼을 메타 순서대로 재토글 -> MPL_CPIT_AMT/MPL_MNGC_AMT 가 중간 복귀.
-- ============================================================
DECLARE
  v_cur VARCHAR2(4000);
BEGIN
  SELECT LISTAGG(column_name, ',') WITHIN GROUP (ORDER BY column_id) INTO v_cur
  FROM all_tab_columns WHERE owner = 'ITPOWN' AND table_name = 'TPRMPP_BPROJL';
  IF v_cur <> 'LOG_HIS_TGR_SNO,ABUS_MNG_NO,SNO,ABUS_NM,ABUS_CONE,ABUS_NCS_CONE,ABUS_TC,BSE_YY,BZ_DTT_NM,CNCD_RFR_NO,CPN_SAF_CONE,CST_TP_TC,DGOG_PPO_CONE,DPL_YN,STT_DTM,END_DTM,EXE_PTT_YN,FLF_FSG_DT,HRF_PLN_CONE,LST_YN,MN_PRG_CONE,TOT_RQM_AMT,MPL_CPIT_AMT,MPL_MNGC_AMT,ODN_YN,PLM_DES,PRLM_HRK_OGZ_C_CONE,SVN_DPM_C,TLR_USID,USID,DVM_DPM_C,DVM_TEM_C,DVM_TLR_USID,DVM_USID,BZ_TP_C,IT_PTL_EDRT_TC,IT_PTL_RPR_STS_TC,IT_PTL_TCHN_TP_TC,IT_PTL_STS_TC,ABUS_RNG_CONE,CHG_DTT_YN,CHG_DTM,CHG_USID,FST_ENR_USID,FST_ENR_DTM,DEL_YN,GUID,GUID_PRG_SNO,LST_CHG_USID,LST_CHG_DTM' THEN
    FOR r IN (
      SELECT column_value AS col, ROWNUM AS rn FROM TABLE(sys.odcivarchar2list(
        'MPL_CPIT_AMT','MPL_MNGC_AMT','ODN_YN','PLM_DES','PRLM_HRK_OGZ_C_CONE','SVN_DPM_C',
        'TLR_USID','USID','DVM_DPM_C','DVM_TEM_C','DVM_TLR_USID','DVM_USID','BZ_TP_C',
        'IT_PTL_EDRT_TC','IT_PTL_RPR_STS_TC','IT_PTL_TCHN_TP_TC','IT_PTL_STS_TC','ABUS_RNG_CONE',
        'CHG_DTT_YN','CHG_DTM','CHG_USID','FST_ENR_USID','FST_ENR_DTM','DEL_YN','GUID',
        'GUID_PRG_SNO','LST_CHG_USID','LST_CHG_DTM')) ORDER BY rn
    ) LOOP
      EXECUTE IMMEDIATE 'ALTER TABLE ITPOWN.TPRMPP_BPROJL MODIFY ("'||r.col||'" INVISIBLE)';
      EXECUTE IMMEDIATE 'ALTER TABLE ITPOWN.TPRMPP_BPROJL MODIFY ("'||r.col||'" VISIBLE)';
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('REORDER TPRMPP_BPROJL');
  END IF;
END;
/

-- ============================================================
-- C. 컬럼 순서 정렬 - TPRMPP_BPROJM (46 cols, 메타 순서)
-- ============================================================
DECLARE
  v_cur VARCHAR2(4000);
BEGIN
  SELECT LISTAGG(column_name, ',') WITHIN GROUP (ORDER BY column_id) INTO v_cur
  FROM all_tab_columns WHERE owner = 'ITPOWN' AND table_name = 'TPRMPP_BPROJM';
  IF v_cur <> 'ABUS_MNG_NO,SNO,ABUS_NM,ABUS_CONE,ABUS_NCS_CONE,ABUS_TC,BSE_YY,BZ_DTT_NM,CNCD_RFR_NO,CPN_SAF_CONE,CST_TP_TC,DGOG_PPO_CONE,DPL_YN,STT_DTM,END_DTM,EXE_PTT_YN,FLF_FSG_DT,HRF_PLN_CONE,LST_YN,MN_PRG_CONE,TOT_RQM_AMT,MPL_CPIT_AMT,MPL_MNGC_AMT,ODN_YN,PLM_DES,PRLM_HRK_OGZ_C_CONE,SVN_DPM_C,TLR_USID,USID,DVM_DPM_C,DVM_TEM_C,DVM_TLR_USID,DVM_USID,BZ_TP_C,IT_PTL_EDRT_TC,IT_PTL_RPR_STS_TC,IT_PTL_TCHN_TP_TC,IT_PTL_STS_TC,ABUS_RNG_CONE,FST_ENR_USID,FST_ENR_DTM,DEL_YN,GUID,GUID_PRG_SNO,LST_CHG_USID,LST_CHG_DTM' THEN
    FOR r IN (
      SELECT column_value AS col, ROWNUM AS rn FROM TABLE(sys.odcivarchar2list(
        'MPL_CPIT_AMT','MPL_MNGC_AMT','ODN_YN','PLM_DES','PRLM_HRK_OGZ_C_CONE','SVN_DPM_C',
        'TLR_USID','USID','DVM_DPM_C','DVM_TEM_C','DVM_TLR_USID','DVM_USID','BZ_TP_C',
        'IT_PTL_EDRT_TC','IT_PTL_RPR_STS_TC','IT_PTL_TCHN_TP_TC','IT_PTL_STS_TC','ABUS_RNG_CONE',
        'FST_ENR_USID','FST_ENR_DTM','DEL_YN','GUID','GUID_PRG_SNO','LST_CHG_USID','LST_CHG_DTM')) ORDER BY rn
    ) LOOP
      EXECUTE IMMEDIATE 'ALTER TABLE ITPOWN.TPRMPP_BPROJM MODIFY ("'||r.col||'" INVISIBLE)';
      EXECUTE IMMEDIATE 'ALTER TABLE ITPOWN.TPRMPP_BPROJM MODIFY ("'||r.col||'" VISIBLE)';
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('REORDER TPRMPP_BPROJM');
  END IF;
END;
/
