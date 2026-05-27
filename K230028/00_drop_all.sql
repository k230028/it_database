-- ============================================================
-- 20 테이블 + 관련 시퀀스 DROP (재적용 시 정리용)
-- ============================================================
-- 주의: 데이터 모두 손실. 재적용은 신규 환경에서만 권장.
-- 적용: SQL*Plus에서 @00_drop_all.sql
-- ============================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
WHENEVER SQLERROR CONTINUE;

-- 테이블 DROP (FK는 CASCADE CONSTRAINTS로 자동 정리)
BEGIN
  FOR r IN (
    SELECT table_name FROM user_tables
    WHERE  table_name IN (
      'TPRMPP_BASCTL','TPRMPP_BASCTM','TPRMPP_BCHKLL','TPRMPP_BCHKLM',
      'TPRMPP_BCMMTL','TPRMPP_BCMMTM','TPRMPP_BEVALL','TPRMPP_BEVALM',
      'TPRMPP_BMQNAL','TPRMPP_BMQNAM','TPRMPP_BPERFL','TPRMPP_BPERFM',
      'TPRMPP_BPOVWL','TPRMPP_BPOVWM','TPRMPP_BPQNAL','TPRMPP_BPQNAM',
      'TPRMPP_BRSLTL','TPRMPP_BRSLTM','TPRMPP_BSCHDL','TPRMPP_BSCHDM'
    )
  ) LOOP
    BEGIN
      EXECUTE IMMEDIATE 'DROP TABLE ' || r.table_name || ' CASCADE CONSTRAINTS PURGE';
      DBMS_OUTPUT.PUT_LINE('DROP TABLE: ' || r.table_name);
    EXCEPTION WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('FAIL TABLE: ' || r.table_name || ' / ' || SQLERRM);
    END;
  END LOOP;
END;
/

-- 시퀀스 DROP
BEGIN
  FOR r IN (
    SELECT sequence_name FROM user_sequences
    WHERE  sequence_name IN (
      'SEQ_BASCTM','SEQ_BCHKLM','SEQ_BCMMTM','SEQ_BEVALM','SEQ_BMQNAM',
      'SEQ_BPERFM','SEQ_BPOVWM','SEQ_BPQNAM','SEQ_BRSLTM','SEQ_BSCHDM',
      'SEQ_BASCTL','SEQ_BCHKLL','SEQ_BCMMTL','SEQ_BEVALL','SEQ_BMQNAL',
      'SEQ_BPERFL','SEQ_BPOVWL','SEQ_BPQNAL','SEQ_BRSLTL','SEQ_BSCHDL'
    )
  ) LOOP
    BEGIN
      EXECUTE IMMEDIATE 'DROP SEQUENCE ' || r.sequence_name;
      DBMS_OUTPUT.PUT_LINE('DROP SEQUENCE: ' || r.sequence_name);
    EXCEPTION WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('FAIL SEQ: ' || r.sequence_name || ' / ' || SQLERRM);
    END;
  END LOOP;
END;
/

COMMIT;
EXIT;
