-- =====================================================================
-- 테스트 스키마 구축 (ITPAPP 로 실행)
--  - ITPAPP_TEST 유저 생성
--  - 모든 TPRMPP_* 테이블을 구조만 복제(WHERE 1=0; 제약/데이터 제외)
-- =====================================================================
SET SERVEROUTPUT ON
WHENEVER SQLERROR CONTINUE

BEGIN
  EXECUTE IMMEDIATE 'DROP USER ITPAPP_TEST CASCADE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

CREATE USER ITPAPP_TEST IDENTIFIED BY "test1234" QUOTA UNLIMITED ON USERS;
GRANT CREATE SESSION TO ITPAPP_TEST;

DECLARE
  n NUMBER := 0;
BEGIN
  FOR t IN (SELECT table_name FROM user_tables WHERE table_name LIKE 'TPRMPP\_%' ESCAPE '\') LOOP
    BEGIN
      EXECUTE IMMEDIATE 'CREATE TABLE ITPAPP_TEST.'||t.table_name||' AS SELECT * FROM '||t.table_name||' WHERE 1=0';
      n := n + 1;
    EXCEPTION WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('CLONE FAIL '||t.table_name||': '||SQLERRM);
    END;
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('cloned tables = '||n);
END;
/
EXIT
