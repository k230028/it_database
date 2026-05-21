-- ============================================================
-- ITPAPP 스키마 초기화 스크립트
--   - 대상: TPRMPP_* 테이블, SEQ_* 시퀀스, 리사이클빈 잔존 객체
--   - 용도: ddl.sql 재실행 전 깨끗한 상태로 되돌리기 (개발/테스트 DB 전용)
--   - 운영 DB 적용 금지
--
-- 실행:
--   DBeaver       : 블록 전체 드래그 → Ctrl+Enter (Execute SQL Statement)
--   SQL Developer : 끝에 "/" 한 줄 추가 후 F5
--   SQLcl/sqlplus : 끝에 "/" 한 줄 추가 후 실행
--
-- 주의:
--   - 접속 계정이 ITPAPP 가 아니어도 ALL_TABLES 권한이 있으면 동작.
--   - 접속 계정이 ITPAPP 스키마 객체에 대한 DROP 권한을 가져야 함.
--   - 실행 결과는 DBMS_OUTPUT 으로 표시 (DBeaver: Output 탭 활성화).
-- ============================================================
DECLARE
  v_dropped_tbl PLS_INTEGER := 0;
  v_dropped_seq PLS_INTEGER := 0;
BEGIN
  FOR r IN (SELECT owner, table_name
              FROM all_tables
             WHERE owner = 'ITPAPP'
               AND table_name LIKE 'TPRMPP\_%' ESCAPE '\') LOOP
    EXECUTE IMMEDIATE 'DROP TABLE "' || r.owner || '"."' || r.table_name || '" CASCADE CONSTRAINTS PURGE';
    v_dropped_tbl := v_dropped_tbl + 1;
  END LOOP;

  FOR r IN (SELECT sequence_owner, sequence_name
              FROM all_sequences
             WHERE sequence_owner = 'ITPAPP'
               AND sequence_name LIKE 'SEQ\_%' ESCAPE '\') LOOP
    EXECUTE IMMEDIATE 'DROP SEQUENCE "' || r.sequence_owner || '"."' || r.sequence_name || '"';
    v_dropped_seq := v_dropped_seq + 1;
  END LOOP;

  EXECUTE IMMEDIATE 'PURGE RECYCLEBIN';

  DBMS_OUTPUT.PUT_LINE('Dropped tables: ' || v_dropped_tbl
                       || ', sequences: ' || v_dropped_seq);
END;
