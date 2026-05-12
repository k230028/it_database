-- ============================================================
-- V20260512_008: BPROJM / BITEMM / BCOSTM 누락 코드값 보정
--
-- 배경:
--   V20260512_003 에서 TAAABB_CCODEM 데이터를 V2 스키마로 변환:
--     구 C_ID(PRJ-TP-001) → 새 C_ID=PRJ_TP, 새 CDVA=001, 새 C_NM=구 CDVA(표시명)
--   V20260512_005 에서 하이픈/언더스코어 패턴 컬럼 일부만 변환.
--   V20260512_006 에서 TAAABB_CCODEM_V2 → TAAABB_CCODEM 으로 rename.
--
-- 이 스크립트는 V005 에서 누락된 컬럼을 처리합니다:
--   1. PRJ_TP  : 한글 구 CDVA(표시명) → 새 CDVA (C_NM 역조회)
--   2. PUL_DTT : 언더스코어 형식 구 C_ID → 마지막 숫자 세그먼트
--   3. BZ_DTT  : 하이픈 형식 구 C_ID  → 마지막 숫자 세그먼트
--   4. TCHN_TP : 하이픈 형식 구 C_ID  → 마지막 숫자 세그먼트
--   5. MN_USR  : 하이픈 형식 구 C_ID  → 마지막 숫자 세그먼트
--   6. RPR_STS : 한글 구 CDVA(표시명) → 새 CDVA (C_NM 역조회)
--   7. PRJ_PUL_PTT : 하이픈/언더스코어 형식 → 마지막 숫자 세그먼트
--   8. BITEMM.DFR_CLE : 한글 구 CDVA  → 새 CDVA (C_NM 역조회)
--   9. BCOSTM.DFR_CLE : 한글 구 CDVA  → 새 CDVA (C_NM 역조회)
--
-- 안전 조건: 각 UPDATE 에 WHERE 절을 적용하여 이미 새 형식인 행은 건드리지 않음.
--   - 순수 숫자 값(REGEXP_LIKE(col, '^[0-9]+$'))은 이미 변환된 것으로 간주하여 제외.
-- ============================================================

-- ============================================================
-- 1. BPROJM.PRJ_TP: 한글 표시명 → 새 CDVA
--    예: '편의성 개선' → '001'
--    (TAAABB_CCODEM 에서 C_ID='PRJ_TP' AND C_NM=B.PRJ_TP 로 역조회)
-- ============================================================
ALTER SESSION SET CURRENT_SCHEMA = ITPAPP;


UPDATE TAAABB_BPROJM B
SET B.PRJ_TP = (
    SELECT C.CDVA
    FROM TAAABB_CCODEM C
    WHERE C.C_ID  = 'PRJ_TP'
      AND C.C_NM  = B.PRJ_TP
      AND ROWNUM  = 1
)
WHERE B.PRJ_TP IS NOT NULL
  AND NOT REGEXP_LIKE(B.PRJ_TP, '^[0-9]+$')
  AND NOT REGEXP_LIKE(B.PRJ_TP, '^[A-Z][A-Z0-9_-]+$')
  AND EXISTS (
    SELECT 1 FROM TAAABB_CCODEM C
    WHERE C.C_ID = 'PRJ_TP' AND C.C_NM = B.PRJ_TP
  );

-- ============================================================
-- 2. BPROJM.PUL_DTT: 언더스코어 형식 구 C_ID → 마지막 숫자 세그먼트
--    예: 'PUL_DTT_001' → '001'
-- ============================================================
UPDATE TAAABB_BPROJM
SET PUL_DTT = REGEXP_SUBSTR(PUL_DTT, '[0-9]+$')
WHERE PUL_DTT IS NOT NULL
  AND NOT REGEXP_LIKE(PUL_DTT, '^[0-9]+$')
  AND REGEXP_LIKE(PUL_DTT, '^[A-Z][A-Z0-9_]+[0-9]+$');

-- ============================================================
-- 3. BPROJM.BZ_DTT: 하이픈 형식 구 C_ID → 마지막 숫자 세그먼트
--    예: 'BZ-DTT-001' → '001'
-- ============================================================
UPDATE TAAABB_BPROJM
SET BZ_DTT = REGEXP_SUBSTR(REPLACE(BZ_DTT, '-', '_'), '[0-9]+$')
WHERE BZ_DTT IS NOT NULL
  AND NOT REGEXP_LIKE(BZ_DTT, '^[0-9]+$')
  AND REGEXP_LIKE(BZ_DTT, '^[A-Z][A-Z0-9_-]+-[0-9]+$');

-- ============================================================
-- 4. BPROJM.TCHN_TP: 하이픈 형식 구 C_ID → 마지막 숫자 세그먼트
--    예: 'TCHN-TP-001' → '001'
-- ============================================================
UPDATE TAAABB_BPROJM
SET TCHN_TP = REGEXP_SUBSTR(REPLACE(TCHN_TP, '-', '_'), '[0-9]+$')
WHERE TCHN_TP IS NOT NULL
  AND NOT REGEXP_LIKE(TCHN_TP, '^[0-9]+$')
  AND REGEXP_LIKE(TCHN_TP, '^[A-Z][A-Z0-9_-]+-[0-9]+$');

-- ============================================================
-- 5. BPROJM.MN_USR: 하이픈 형식 구 C_ID → 마지막 숫자 세그먼트
--    예: 'MN-USR-003' → '003'
-- ============================================================
UPDATE TAAABB_BPROJM
SET MN_USR = REGEXP_SUBSTR(REPLACE(MN_USR, '-', '_'), '[0-9]+$')
WHERE MN_USR IS NOT NULL
  AND NOT REGEXP_LIKE(MN_USR, '^[0-9]+$')
  AND REGEXP_LIKE(MN_USR, '^[A-Z][A-Z0-9_-]+-[0-9]+$');

-- ============================================================
-- 6. BPROJM.RPR_STS: 한글 표시명 → 새 CDVA
--    예: '부장' → '003'
--    (TAAABB_CCODEM 에서 C_ID='RPR_STS' AND C_NM=B.RPR_STS 로 역조회)
-- ============================================================
UPDATE TAAABB_BPROJM B
SET B.RPR_STS = (
    SELECT C.CDVA
    FROM TAAABB_CCODEM C
    WHERE C.C_ID  = 'RPR_STS'
      AND C.C_NM  = B.RPR_STS
      AND ROWNUM  = 1
)
WHERE B.RPR_STS IS NOT NULL
  AND NOT REGEXP_LIKE(B.RPR_STS, '^[0-9]+$')
  AND NOT REGEXP_LIKE(B.RPR_STS, '^[A-Z][A-Z0-9_-]+$')
  AND EXISTS (
    SELECT 1 FROM TAAABB_CCODEM C
    WHERE C.C_ID = 'RPR_STS' AND C.C_NM = B.RPR_STS
  );

-- ============================================================
-- 7. BPROJM.PRJ_PUL_PTT: 하이픈/언더스코어 형식 → 마지막 숫자 세그먼트
--    예: 'PRJ-PUL-PTT-001' 또는 'PRJ_PUL_PTT_001' → '001'
-- ============================================================
UPDATE TAAABB_BPROJM
SET PRJ_PUL_PTT = REGEXP_SUBSTR(REPLACE(PRJ_PUL_PTT, '-', '_'), '[0-9]+$')
WHERE PRJ_PUL_PTT IS NOT NULL
  AND NOT REGEXP_LIKE(TO_CHAR(PRJ_PUL_PTT), '^[0-9]+$')
  AND REGEXP_LIKE(TO_CHAR(PRJ_PUL_PTT), '^[A-Z][A-Z0-9_-]+-?[0-9]+$');

-- ============================================================
-- 8. BITEMM.DFR_CLE: 한글 표시명 → 새 CDVA
--    예: '분기' → '004'
--    (TAAABB_CCODEM 에서 C_ID='DFR_CLE' AND C_NM=B.DFR_CLE 로 역조회)
--    ※ 하이픈 형식(V005에서 처리 완료)은 이미 새 형식이므로 한글만 대상
-- ============================================================
UPDATE TAAABB_BITEMM B
SET B.DFR_CLE = (
    SELECT C.CDVA
    FROM TAAABB_CCODEM C
    WHERE C.C_ID  = 'DFR_CLE'
      AND C.C_NM  = B.DFR_CLE
      AND ROWNUM  = 1
)
WHERE B.DFR_CLE IS NOT NULL
  AND NOT REGEXP_LIKE(B.DFR_CLE, '^[0-9]+$')
  AND NOT REGEXP_LIKE(B.DFR_CLE, '^[A-Z][A-Z0-9_-]+$')
  AND EXISTS (
    SELECT 1 FROM TAAABB_CCODEM C
    WHERE C.C_ID = 'DFR_CLE' AND C.C_NM = B.DFR_CLE
  );

-- ============================================================
-- 9. BCOSTM.DFR_CLE: 한글 표시명 → 새 CDVA
--    예: '분기' → '004'
-- ============================================================
UPDATE TAAABB_BCOSTM B
SET B.DFR_CLE = (
    SELECT C.CDVA
    FROM TAAABB_CCODEM C
    WHERE C.C_ID  = 'DFR_CLE'
      AND C.C_NM  = B.DFR_CLE
      AND ROWNUM  = 1
)
WHERE B.DFR_CLE IS NOT NULL
  AND NOT REGEXP_LIKE(B.DFR_CLE, '^[0-9]+$')
  AND NOT REGEXP_LIKE(B.DFR_CLE, '^[A-Z][A-Z0-9_-]+$')
  AND EXISTS (
    SELECT 1 FROM TAAABB_CCODEM C
    WHERE C.C_ID = 'DFR_CLE' AND C.C_NM = B.DFR_CLE
  );

COMMIT;
