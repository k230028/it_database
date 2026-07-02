-- =============================================================================
-- V20260702_002__FixBaskplSequenceName.sql
-- 감사로그 시퀀스명 정정: S_BASKPL → SEQ_BASKPL.
--
--  - 버그: V20260630_002가 로그 시퀀스를 S_BASKPL로 생성했으나, AuditLogIdGenerator는
--          SEQ_{Postfix} 규칙으로 조회한다(TPRMPP_BASKPL → SEQ_BASKPL). 다른 로그 시퀀스도
--          실제로는 SEQ_BASCTL/SEQ_BASCTM 형태.
--          → Baskpm INSERT 시 SEQ_BASKPL 미존재(ORA-02289)로 감사로그 실패, 트랜잭션 롤백되어
--            '생략 판정 요청' 생성이 불가했음.
--  - 조치: 잘못된 S_BASKPL을 DROP하고 SEQ_BASKPL을 생성(멱등). Oracle은 시퀀스 RENAME을
--          지원하지 않으므로(ORA-03001) DROP+CREATE 사용. S_BASKPL은 미사용이라 안전.
--
-- 소유 스키마 ITPOWN(세션 CURRENT_SCHEMA=ITPOWN). 적용 후 수정 금지(Flyway 체크섬).
-- =============================================================================

DECLARE
    n_new NUMBER;
    n_old NUMBER;
BEGIN
    SELECT COUNT(*) INTO n_old FROM ALL_SEQUENCES
     WHERE SEQUENCE_OWNER = 'ITPOWN' AND SEQUENCE_NAME = 'S_BASKPL';
    IF n_old > 0 THEN
        EXECUTE IMMEDIATE 'DROP SEQUENCE ITPOWN.S_BASKPL';
    END IF;

    SELECT COUNT(*) INTO n_new FROM ALL_SEQUENCES
     WHERE SEQUENCE_OWNER = 'ITPOWN' AND SEQUENCE_NAME = 'SEQ_BASKPL';
    IF n_new = 0 THEN
        EXECUTE IMMEDIATE 'CREATE SEQUENCE ITPOWN.SEQ_BASKPL START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE';
    END IF;
END;
/

COMMIT;
