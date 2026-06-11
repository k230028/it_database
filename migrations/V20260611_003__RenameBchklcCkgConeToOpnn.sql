-- V20260611_003__RenameBchklcCkgConeToOpnn.sql
-- 사전점검 항목(BCHKLC) 점검내용 컬럼을 로그 테이블(BCHKLL)과 동일 명칭으로 정렬
--
-- 배경:
--  - V20260611_001에서 로그 테이블 BCHKLL.CKG_CONE은 메타 기준 CKG_OPNN_CONE(1000)으로
--    변경됐으나 마스터 BCHKLC.CKG_CONE은 유지되어 명칭이 어긋났다.
--  - 감사 로그 스냅샷(AuditLogPersister)은 마스터↔로그 @Column 이름 일치 기준으로
--    값을 복사하므로, 이름이 다르면 점검내용이 로그에 복사되지 않는다.
--    마스터도 CKG_OPNN_CONE으로 정렬한다 (폭도 로그와 동일하게 1000으로 축소, 데이터 최대 3자).
--
-- 멱등성: 컬럼 존재 여부 가드 후 실행하므로 재실행 안전.

DECLARE
    v_cnt NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_cnt FROM user_tab_columns
     WHERE table_name = 'TPRMPP_BCHKLC' AND column_name = 'CKG_CONE';
    IF v_cnt > 0 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE ITPAPP.TPRMPP_BCHKLC MODIFY (CKG_CONE VARCHAR2(1000 CHAR))';
        EXECUTE IMMEDIATE 'ALTER TABLE ITPAPP.TPRMPP_BCHKLC RENAME COLUMN CKG_CONE TO CKG_OPNN_CONE';
    END IF;
END;
/

COMMENT ON COLUMN ITPAPP.TPRMPP_BCHKLC.CKG_OPNN_CONE IS '점검의견내용';

COMMIT;
