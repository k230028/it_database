-- ============================================================
-- V20260512_006: TAAABB_CCODEM 이름 교체
--   TAAABB_CCODEM    -> TAAABB_CCODEM_OLD
--   TAAABB_CCODEM_V2 -> TAAABB_CCODEM
-- ============================================================
RENAME TAAABB_CCODEM    TO TAAABB_CCODEM_OLD;
RENAME TAAABB_CCODEM_V2 TO TAAABB_CCODEM;
RENAME IDX_CCODEM_V2_CID_VALID TO IDX_CCODEM_CID_VALID;
