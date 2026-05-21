-- =============================================================================
-- TPRMPP_CLOGNH 컬럼명 변경: LGN_SNO → LGN_HIS_SNO
-- Migration: V20260521_007__rename_clognh_lgn_sno_to_lgn_his_sno.sql
-- Date: 2026-05-21
-- =============================================================================

ALTER TABLE ITPAPP.TPRMPP_CLOGNH RENAME COLUMN LGN_SNO TO LGN_HIS_SNO;

COMMIT;
