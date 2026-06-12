-- V20260612_003__RenameNacIdToNacUnqIdAndRestoreDfrDt.sql
-- 1) CBLBCM/CBLBCL.NAC_ID → NAC_UNQ_ID 변경 (메타용어사전 표준: 게시물고유ID, VARCHAR2(16))
--    - 운영 메타(table.csv)의 NAC_ID VARCHAR2(10)은 채번 형식 NAC-{YYYY}-{NNNN}(13자)을
--      담지 못해 stale — 메타용어사전의 NAC_UNQ_ID(16자)가 올바른 표준 용어.
-- 2) BPAYTL/BPAYTM.DFR_DT(지급일자, VARCHAR2(8)) 복원
--    - V20260612_002가 운영 CSV 기준으로 드롭했으나 Bpaymt/BpaymtL 엔티티가 사용 중인 컬럼.
--      운영 CSV 미등재는 메타 등재 지연(TASK.md '메타 미등재 테이블 13종' 참조).
-- 멱등성: 컬럼 존재 여부 가드 후 실행. 재실행 안전.
-- 주의: 익명 블록은 호출자(ITPAPP) 권한으로 실행되므로 USER_* 뷰가 아닌
--       ALL_* 뷰(owner='ITPOWN')로 딕셔너리를 조회해야 한다.
-- 주의: 적용 시 NLS_LANG=.AL32UTF8 환경에서 실행할 것 (한글 코멘트 손상 방지).

SET SERVEROUTPUT ON SIZE UNLIMITED

ALTER SESSION SET CURRENT_SCHEMA = ITPOWN;

-- ============================================================
-- 1. NAC_ID → NAC_UNQ_ID (CBLBCM, CBLBCL)
-- ============================================================
DECLARE
  PROCEDURE rename_nac(p_tab IN VARCHAR2) IS
    v_old NUMBER; v_new NUMBER; v_len NUMBER; v_data NUMBER;
  BEGIN
    SELECT COUNT(*) INTO v_old FROM all_tab_columns WHERE owner = 'ITPOWN' AND table_name = p_tab AND column_name = 'NAC_ID';
    SELECT COUNT(*) INTO v_new FROM all_tab_columns WHERE owner = 'ITPOWN' AND table_name = p_tab AND column_name = 'NAC_UNQ_ID';
    IF v_old = 1 AND v_new = 1 THEN
      -- 비정상 중간 상태(빈 NAC_UNQ_ID가 중복 생성된 경우) 복구
      EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM ITPOWN.' || p_tab || ' WHERE NAC_UNQ_ID IS NOT NULL' INTO v_data;
      IF v_data = 0 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE ITPOWN.' || p_tab || ' DROP COLUMN NAC_UNQ_ID';
        v_new := 0;
        DBMS_OUTPUT.PUT_LINE('DROP ' || p_tab || '.NAC_UNQ_ID (빈 중복 컬럼 정리)');
      ELSE
        DBMS_OUTPUT.PUT_LINE('SKIP ' || p_tab || ': NAC_ID/NAC_UNQ_ID 모두 데이터 보유 — 수동 확인 필요');
        RETURN;
      END IF;
    END IF;
    IF v_old = 1 AND v_new = 0 THEN
      EXECUTE IMMEDIATE 'ALTER TABLE ITPOWN.' || p_tab || ' RENAME COLUMN NAC_ID TO NAC_UNQ_ID';
      DBMS_OUTPUT.PUT_LINE('RENAME ' || p_tab || '.NAC_ID -> NAC_UNQ_ID');
    ELSIF v_old = 0 AND v_new = 0 THEN
      EXECUTE IMMEDIATE 'ALTER TABLE ITPOWN.' || p_tab || ' ADD (NAC_UNQ_ID VARCHAR2(16 CHAR))';
      DBMS_OUTPUT.PUT_LINE('ADD ' || p_tab || '.NAC_UNQ_ID');
    END IF;
    -- 폭 16 보장 (V20260612_002 이전 상태 등에서 10으로 남아 있으면 확장)
    SELECT char_length INTO v_len FROM all_tab_columns WHERE owner = 'ITPOWN' AND table_name = p_tab AND column_name = 'NAC_UNQ_ID';
    IF v_len < 16 THEN
      EXECUTE IMMEDIATE 'ALTER TABLE ITPOWN.' || p_tab || ' MODIFY (NAC_UNQ_ID VARCHAR2(16 CHAR))';
      DBMS_OUTPUT.PUT_LINE('WIDEN ' || p_tab || '.NAC_UNQ_ID -> VARCHAR2(16 CHAR)');
    END IF;
  END;
BEGIN
  rename_nac('TPRMPP_CBLBCM');
  rename_nac('TPRMPP_CBLBCL');
END;
/

COMMENT ON COLUMN TPRMPP_CBLBCM.NAC_UNQ_ID IS '게시물고유ID';
COMMENT ON COLUMN TPRMPP_CBLBCL.NAC_UNQ_ID IS '게시물고유ID';

-- 옛 컬럼명을 담은 인덱스명 정리
DECLARE
  v_cnt NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_cnt FROM all_indexes WHERE owner = 'ITPOWN' AND index_name = 'IX_CBLBCM_NAC_ID_GRP_SQN_SNO';
  IF v_cnt = 1 THEN
    EXECUTE IMMEDIATE 'ALTER INDEX ITPOWN.IX_CBLBCM_NAC_ID_GRP_SQN_SNO RENAME TO IX_CBLBCM_NAC_UNQ_ID_GRP_SQN';
    DBMS_OUTPUT.PUT_LINE('RENAME INDEX -> IX_CBLBCM_NAC_UNQ_ID_GRP_SQN');
  END IF;
END;
/

-- ============================================================
-- 2. DFR_DT(지급일자) 복원 (BPAYTL, BPAYTM)
-- ============================================================
DECLARE
  PROCEDURE add_dfr_dt(p_tab IN VARCHAR2) IS
    v_cnt NUMBER;
  BEGIN
    SELECT COUNT(*) INTO v_cnt FROM all_tab_columns WHERE owner = 'ITPOWN' AND table_name = p_tab AND column_name = 'DFR_DT';
    IF v_cnt = 0 THEN
      EXECUTE IMMEDIATE 'ALTER TABLE ITPOWN.' || p_tab || ' ADD (DFR_DT VARCHAR2(8 CHAR))';
      DBMS_OUTPUT.PUT_LINE('ADD ' || p_tab || '.DFR_DT');
    END IF;
  END;
BEGIN
  add_dfr_dt('TPRMPP_BPAYTL');
  add_dfr_dt('TPRMPP_BPAYTM');
END;
/

COMMENT ON COLUMN TPRMPP_BPAYTL.DFR_DT IS '지급일자';
COMMENT ON COLUMN TPRMPP_BPAYTM.DFR_DT IS '지급일자';
