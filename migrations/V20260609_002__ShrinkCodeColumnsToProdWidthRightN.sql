-- V20260609_002__ShrinkCodeColumnsToProdWidthRightN.sql
-- 코드컬럼 5종을 운영 폭으로 정합. 값은 RIGHT(N)(오른쪽 N자리)만 남겨 변환 후 컬럼 축소.
--   EXE_PTT_YN            : VARCHAR2(3) → (1),  값 RIGHT(1)  (예 '001'→'1', '002'→'2')
--   IT_PTL_RPR_STS_TC     : VARCHAR2(3) → (2),  값 RIGHT(2)  (예 '001'→'01', '999'→'99')
--   IT_PTL_TCHN_TP_TC     : VARCHAR2(3) → (2),  값 RIGHT(2)
--   IT_PTL_TMN_SVC_TC     : VARCHAR2(3) → (2),  값 RIGHT(2)
--   IT_PTL_TMN_KD_TC      : VARCHAR2(3) → (2),  값 RIGHT(2)
--
-- 배경:
--  - V20260609_001 에서는 로컬 데이터에 3자리 값이 있어 축소 불가(ORA-01441)로 제외했었다.
--  - 사용자 결정: 폭이 다른 코드컬럼은 RIGHT(N)으로 값을 잘라 운영 폭에 맞춘다.
--  - 코드값 하드코딩 없음(백엔드 CommonCodeGroups는 그룹ID만 상수, 값은 CCODEM 동적 조회).
--    따라서 CCODEM 코드값과 데이터 컬럼을 함께 RIGHT(N) 변환하면 라벨 조회 정합이 유지된다.
--  - RIGHT(N) 그룹 내 충돌 없음(사전 검증). HRK_CDVA_ID 부모참조 없음.
--  - 부수효과: BTERMM(3)↔BTERML(2) 폭 불일치로 깨지던 단말 변경로그도 본 변환으로 해소.
--
-- 적용 후: CodeService 캐시(codesByCid) 무효화 필요 → 백엔드 재기동 또는 캐시 evict.
-- 멱등성: 이미 짧은 값/폭은 LENGTH·char_length 확인으로 건너뛴다.

-- ============================================================
-- A. 공통코드(CCODEM) 코드값 변환  (CDVA_ID = RIGHT(N))
-- ============================================================
UPDATE ITPAPP.TPRMPP_CCODEM SET CDVA_ID = SUBSTR(CDVA_ID, -1)
 WHERE CO_C_ID = 'EXE_PTT_YN' AND LENGTH(CDVA_ID) > 1;

UPDATE ITPAPP.TPRMPP_CCODEM SET CDVA_ID = SUBSTR(CDVA_ID, -2)
 WHERE CO_C_ID IN ('IT_PTL_RPR_STS_TC','IT_PTL_TCHN_TP_TC','IT_PTL_TMN_SVC_TC','IT_PTL_TMN_KD_TC')
   AND LENGTH(CDVA_ID) > 2;

-- ============================================================
-- B. 데이터 컬럼 값 변환  (RIGHT(N))
-- ============================================================
-- 정보화사업 마스터/로그
UPDATE ITPAPP.TPRMPP_BPROJM SET EXE_PTT_YN        = SUBSTR(EXE_PTT_YN, -1)        WHERE EXE_PTT_YN        IS NOT NULL AND LENGTH(EXE_PTT_YN)        > 1;
UPDATE ITPAPP.TPRMPP_BPROJL SET EXE_PTT_YN        = SUBSTR(EXE_PTT_YN, -1)        WHERE EXE_PTT_YN        IS NOT NULL AND LENGTH(EXE_PTT_YN)        > 1;
UPDATE ITPAPP.TPRMPP_BPROJM SET IT_PTL_RPR_STS_TC = SUBSTR(IT_PTL_RPR_STS_TC, -2) WHERE IT_PTL_RPR_STS_TC IS NOT NULL AND LENGTH(IT_PTL_RPR_STS_TC) > 2;
UPDATE ITPAPP.TPRMPP_BPROJL SET IT_PTL_RPR_STS_TC = SUBSTR(IT_PTL_RPR_STS_TC, -2) WHERE IT_PTL_RPR_STS_TC IS NOT NULL AND LENGTH(IT_PTL_RPR_STS_TC) > 2;
UPDATE ITPAPP.TPRMPP_BPROJM SET IT_PTL_TCHN_TP_TC = SUBSTR(IT_PTL_TCHN_TP_TC, -2) WHERE IT_PTL_TCHN_TP_TC IS NOT NULL AND LENGTH(IT_PTL_TCHN_TP_TC) > 2;
UPDATE ITPAPP.TPRMPP_BPROJL SET IT_PTL_TCHN_TP_TC = SUBSTR(IT_PTL_TCHN_TP_TC, -2) WHERE IT_PTL_TCHN_TP_TC IS NOT NULL AND LENGTH(IT_PTL_TCHN_TP_TC) > 2;
-- 전산업무비 단말기 마스터/로그
UPDATE ITPAPP.TPRMPP_BTERMM SET IT_PTL_TMN_SVC_TC = SUBSTR(IT_PTL_TMN_SVC_TC, -2) WHERE IT_PTL_TMN_SVC_TC IS NOT NULL AND LENGTH(IT_PTL_TMN_SVC_TC) > 2;
UPDATE ITPAPP.TPRMPP_BTERML SET IT_PTL_TMN_SVC_TC = SUBSTR(IT_PTL_TMN_SVC_TC, -2) WHERE IT_PTL_TMN_SVC_TC IS NOT NULL AND LENGTH(IT_PTL_TMN_SVC_TC) > 2;
UPDATE ITPAPP.TPRMPP_BTERMM SET IT_PTL_TMN_KD_TC  = SUBSTR(IT_PTL_TMN_KD_TC, -2)  WHERE IT_PTL_TMN_KD_TC  IS NOT NULL AND LENGTH(IT_PTL_TMN_KD_TC)  > 2;
UPDATE ITPAPP.TPRMPP_BTERML SET IT_PTL_TMN_KD_TC  = SUBSTR(IT_PTL_TMN_KD_TC, -2)  WHERE IT_PTL_TMN_KD_TC  IS NOT NULL AND LENGTH(IT_PTL_TMN_KD_TC)  > 2;

COMMIT;

-- ============================================================
-- C. 컬럼 폭 축소 (값 변환 후, 멱등)
-- ============================================================
DECLARE
  TYPE t_rec IS RECORD (tbl VARCHAR2(30), col VARCHAR2(30), newlen NUMBER);
  TYPE t_arr IS TABLE OF t_rec;
  v t_arr := t_arr(
    t_rec('TPRMPP_BPROJM','EXE_PTT_YN',1),
    t_rec('TPRMPP_BPROJL','EXE_PTT_YN',1),
    t_rec('TPRMPP_BPROJM','IT_PTL_RPR_STS_TC',2),
    t_rec('TPRMPP_BPROJL','IT_PTL_RPR_STS_TC',2),
    t_rec('TPRMPP_BPROJM','IT_PTL_TCHN_TP_TC',2),
    t_rec('TPRMPP_BPROJL','IT_PTL_TCHN_TP_TC',2),
    t_rec('TPRMPP_BTERMM','IT_PTL_TMN_SVC_TC',2),
    t_rec('TPRMPP_BTERMM','IT_PTL_TMN_KD_TC',2)
  );
  v_cur NUMBER;
BEGIN
  FOR i IN 1..v.COUNT LOOP
    BEGIN
      SELECT char_length INTO v_cur FROM user_tab_columns
        WHERE table_name = v(i).tbl AND column_name = v(i).col;
      IF v_cur > v(i).newlen THEN
        EXECUTE IMMEDIATE 'ALTER TABLE ITPAPP.'||v(i).tbl||' MODIFY ("'||v(i).col
          ||'" VARCHAR2('||v(i).newlen||' CHAR))';
      END IF;
    EXCEPTION WHEN NO_DATA_FOUND THEN NULL;
    END;
  END LOOP;
END;
/

COMMIT;
