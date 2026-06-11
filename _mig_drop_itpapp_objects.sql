-- ITPAPP 소유 중복 객체 삭제 (ITPOWN 이관 완료 + MIG_ITPOWN.DMP 백업 확보 후 실행)
-- ITPAPP은 접속 전용 계정으로 남고, 객체는 ITPOWN만 소유한다.
WHENEVER SQLERROR EXIT SQL.SQLCODE
SET SERVEROUTPUT ON SIZE UNLIMITED

DECLARE
    PROCEDURE drop_object(p_sql IN VARCHAR2) IS
    BEGIN
        EXECUTE IMMEDIATE p_sql;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('DROP skipped: ' || p_sql || ' - ' || SQLERRM);
    END;
BEGIN
    FOR item IN (
        SELECT object_type, object_name
        FROM user_objects
        WHERE object_name NOT LIKE 'BIN$%'
          AND object_type IN ('VIEW', 'SEQUENCE', 'TABLE')
        ORDER BY CASE object_type
            WHEN 'VIEW' THEN 1
            WHEN 'SEQUENCE' THEN 2
            WHEN 'TABLE' THEN 3
            ELSE 99
        END
    ) LOOP
        IF item.object_type = 'TABLE' THEN
            drop_object('DROP TABLE "' || item.object_name || '" CASCADE CONSTRAINTS PURGE');
        ELSE
            drop_object('DROP ' || item.object_type || ' "' || item.object_name || '"');
        END IF;
    END LOOP;
END;
/

PURGE RECYCLEBIN;

SELECT object_type, COUNT(*) AS remaining
FROM user_objects
GROUP BY object_type
ORDER BY object_type;
EXIT
