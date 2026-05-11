-- ============================================================
-- V20260512_005: 다운스트림 FK 값 변환
-- 예: TAAABB_BPROJM.PRJ_TP = 'PRJ-TP-001' → '001'
--     TAAABB_BITEMM.CUR    = 'CUR-001'    → '001'
--     TAAABB_BITEMM.DFR_CLE = 'DFR-CLE-001' → '001'
--     TAAABB_BTERMM.CUR    = 'CUR-001'    → '001'
-- 패턴: 하이픈/언더바가 포함된 코드값을 마지막 숫자/별칭 세그먼트만 남김
-- ============================================================

-- BPROJM.PRJ_TP
UPDATE TAAABB_BPROJM
SET PRJ_TP = REGEXP_SUBSTR(REPLACE(PRJ_TP,''-'',''_''), ''[A-Z0-9]+$'')
WHERE PRJ_TP IS NOT NULL
  AND REGEXP_LIKE(PRJ_TP, ''^[A-Z_]+-[A-Z0-9-]+$'');

-- BPROJM.PUL_DTT
UPDATE TAAABB_BPROJM
SET PUL_DTT = REGEXP_SUBSTR(REPLACE(PUL_DTT,''-'',''_''), ''[A-Z0-9]+$'')
WHERE PUL_DTT IS NOT NULL
  AND REGEXP_LIKE(PUL_DTT, ''^[A-Z_]+-[A-Z0-9-]+$'');

-- BPROJM.BZ_DTT
UPDATE TAAABB_BPROJM
SET BZ_DTT = REGEXP_SUBSTR(REPLACE(BZ_DTT,''-'',''_''), ''[A-Z0-9]+$'')
WHERE BZ_DTT IS NOT NULL
  AND REGEXP_LIKE(BZ_DTT, ''^[A-Z_]+-[A-Z0-9-]+$'');

-- BITEMM.CUR
UPDATE TAAABB_BITEMM
SET CUR = REGEXP_SUBSTR(REPLACE(CUR,''-'',''_''), ''[A-Z0-9]+$'')
WHERE CUR IS NOT NULL
  AND REGEXP_LIKE(CUR, ''^[A-Z_]+-[A-Z0-9-]+$'');

-- BITEMM.DFR_CLE
UPDATE TAAABB_BITEMM
SET DFR_CLE = REGEXP_SUBSTR(REPLACE(DFR_CLE,''-'',''_''), ''[A-Z0-9]+$'')
WHERE DFR_CLE IS NOT NULL
  AND REGEXP_LIKE(DFR_CLE, ''^[A-Z_]+-[A-Z0-9-]+$'');

-- BTERMM.CUR
UPDATE TAAABB_BTERMM
SET CUR = REGEXP_SUBSTR(REPLACE(CUR,''-'',''_''), ''[A-Z0-9]+$'')
WHERE CUR IS NOT NULL
  AND REGEXP_LIKE(CUR, ''^[A-Z_]+-[A-Z0-9-]+$'');

COMMIT;
