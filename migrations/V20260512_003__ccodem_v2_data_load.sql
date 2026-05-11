-- ============================================================
-- V20260512_003: TAAABB_CCODEM 데이터 변환 INSERT (V2로 적재)
-- 변환 규칙:
--   C_ID     = REGEXP_REPLACE(REPLACE(old.C_ID,'-','_'), '_[A-Z0-9]+$', '')
--   CDVA     = REGEXP_SUBSTR(REPLACE(old.C_ID,'-','_'), '[A-Z0-9]+$')
--   C_NM     = old.CDVA
--   C_DES    = old.CTT_TP_DES
--   CDVA_DTL = old.C_NM
--   C_TP     = old.CTT_TP
--   C_TP_DES = old.CTT_TP_DES
-- ============================================================

INSERT INTO TAAABB_CCODEM_V2 (
    C_ID, CDVA, STT_DT, END_DT,
    C_NM, C_DES, CDVA_DTL,
    C_TP, C_TP_DES, HRK_C, C_SQN,
    DEL_YN, GUID, GUID_PRG_SNO,
    FST_ENR_DTM, FST_ENR_USID,
    LST_CHG_DTM, LST_CHG_USID
)
SELECT
    REGEXP_REPLACE(REPLACE(C_ID,'-','_'), '_[A-Z0-9]+$', ''),
    REGEXP_SUBSTR (REPLACE(C_ID,'-','_'), '[A-Z0-9]+$'),
    STT_DT, END_DT,
    CDVA,        -- C_NM <- 구 CDVA
    CTT_TP_DES,  -- C_DES <- 구 CTT_TP_DES
    C_NM,        -- CDVA_DTL <- 구 C_NM
    CTT_TP,      -- C_TP <- 구 CTT_TP
    CTT_TP_DES,  -- C_TP_DES <- 구 CTT_TP_DES
    NULL,        -- HRK_C: 후속 별도 UPDATE
    C_SQN,
    DEL_YN, GUID, GUID_PRG_SNO,
    FST_ENR_DTM, FST_ENR_USID,
    LST_CHG_DTM, LST_CHG_USID
FROM TAAABB_CCODEM;

INSERT INTO TAAABB_CCODEL_V2 (
    LOG_SNO, CHG_TP,
    C_ID, CDVA, STT_DT, END_DT,
    C_NM, C_DES, CDVA_DTL,
    C_TP, C_TP_DES, HRK_C, C_SQN,
    DEL_YN, GUID,
    FST_ENR_DTM, FST_ENR_USID,
    LST_CHG_DTM, LST_CHG_USID
)
SELECT
    SEQ_CCODEL_V2.NEXTVAL,
    'SCHEMA_MIGRATION_20260512',
    REGEXP_REPLACE(REPLACE(C_ID,'-','_'), '_[A-Z0-9]+$', ''),
    REGEXP_SUBSTR (REPLACE(C_ID,'-','_'), '[A-Z0-9]+$'),
    STT_DT, END_DT,
    CDVA, CTT_TP_DES, C_NM,
    CTT_TP, CTT_TP_DES, NULL, C_SQN,
    DEL_YN, GUID,
    SYSTIMESTAMP, FST_ENR_USID,
    SYSTIMESTAMP, LST_CHG_USID
FROM TAAABB_CCODEM;

COMMIT;
