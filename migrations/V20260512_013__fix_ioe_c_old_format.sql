-- V20260512_013__fix_ioe_c_old_format.sql
-- BCOSTM.IOE_C, BITEMM.IOE_C 구 C_ID 형식 → 새 CDVA 형식 변환
--
-- 배경:
--   V20260512_003에서 CCODEM을 V2 스키마로 변환 시
--     구 C_ID(예: 'IOE-001') → 새 C_ID='IOE', 새 CDVA='001'
--   V20260512_005/008에서 BPROJM/BITEMM의 일부 코드 컬럼은 변환됐으나
--   BCOSTM.IOE_C, BITEMM.IOE_C(구 GCL_DTT, V009에서 rename)는 처리되지 않음.
--
-- 영향:
--   CostService.setBudgetCategory()가 findByCIdWithValidDate("IOE", null)로 조회 후
--   response.getIoeC().equals(c.getCdva()) 비교 시 'IOE-001' != '001' → 항상 미매칭
--   → /budget/list, /budget/approval 화면의 devBg/machBg/intanBg 모두 0원
--
-- 변환 패턴: REGEXP_SUBSTR(REPLACE(IOE_C, '-', '_'), '[A-Z0-9]+$')
--   'IOE-001'      → '001'
--   'IOE_001'      → '001'
--   'IOE-CPIT-001' → '001'
--
-- 안전 조건:
--   NOT REGEXP_LIKE(IOE_C, '^[0-9]+$')          — 이미 숫자 형식인 신규 데이터 제외
--   REGEXP_LIKE(IOE_C, '^[A-Z][A-Z0-9]*[_-]..') — 구 형식(구분자 포함)만 대상

ALTER SESSION SET CURRENT_SCHEMA = ITPAPP;

-- ============================================================
-- STEP 1: BCOSTM.IOE_C 변환
-- ============================================================
UPDATE TAAABB_BCOSTM
   SET IOE_C = REGEXP_SUBSTR(REPLACE(IOE_C, '-', '_'), '[A-Z0-9]+$')
 WHERE IOE_C IS NOT NULL
   AND NOT REGEXP_LIKE(IOE_C, '^[0-9]+$')
   AND REGEXP_LIKE(IOE_C, '^[A-Z][A-Z0-9]*[_-][A-Z0-9]');

-- ============================================================
-- STEP 2: BITEMM.IOE_C 변환 (구 GCL_DTT, V009에서 rename)
-- ============================================================
UPDATE TAAABB_BITEMM
   SET IOE_C = REGEXP_SUBSTR(REPLACE(IOE_C, '-', '_'), '[A-Z0-9]+$')
 WHERE IOE_C IS NOT NULL
   AND NOT REGEXP_LIKE(IOE_C, '^[0-9]+$')
   AND REGEXP_LIKE(IOE_C, '^[A-Z][A-Z0-9]*[_-][A-Z0-9]');

COMMIT;
