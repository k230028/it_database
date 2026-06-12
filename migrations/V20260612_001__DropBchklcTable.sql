-- V20260612_001__DropBchklcTable.sql
-- 타당성 자체점검(BCHKLC) 테이블 및 기능 제거
--
-- 배경:
--  - 타당성검토표의 자체점검 체크리스트 기능 폐기 결정에 따라 마스터 테이블을 제거한다.
--    (백엔드 Bchklc/BchklcId/BchklcL 엔티티, FeasibilityCheckRepository,
--     FeasibilityService 자체점검 로직, 프론트 FeasibilityChecklist.vue 동시 제거)
--  - 로그 테이블 BCHKLL·점검 마스터 BCHKLM은 메타 용어사전 등재 테이블이므로 유지한다.
--    (기록 주체가 사라져 신규 적재는 없음 — 메타 정비 시 존치 여부 재검토)
--  - 백업 스키마(ITPAPP_BAK, ITPAPP_TEST)의 동명 테이블은 건드리지 않는다.
--
-- 멱등성: 테이블 존재 여부 가드 후 DROP. 재실행 안전.
-- 주의: ITPAPP 계정으로 접속 시 ITPOWN 소유 객체이므로 스키마 접두어 명시.

DECLARE
    v_cnt NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_cnt FROM all_tables
     WHERE owner = 'ITPOWN' AND table_name = 'TPRMPP_BCHKLC';
    IF v_cnt > 0 THEN
        EXECUTE IMMEDIATE 'DROP TABLE ITPOWN.TPRMPP_BCHKLC CASCADE CONSTRAINTS';
    END IF;
END;
/

COMMIT;
