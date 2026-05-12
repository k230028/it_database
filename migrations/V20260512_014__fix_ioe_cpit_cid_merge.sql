-- V20260512_014__fix_ioe_cpit_cid_merge.sql
-- IOE_CPIT 코드 그룹을 IOE 그룹으로 통합 (C_ID 정정)
--
-- 배경:
--   V20260512_003에서 구 C_ID='IOE-CPIT-101' 형식 코드가
--     REGEXP_REPLACE(REPLACE('IOE-CPIT-101','-','_'), '_[A-Z0-9]+$', '')
--     = 'IOE_CPIT' 로 변환됨.
--   V2 스키마 설계 의도: C_ID='IOE' 단일 그룹, C_TP 으로 자본/관리비 구분
--     자본예산(IOE_CPIT): C_TP='IOE_CPIT'
--     일반관리비: C_TP='IOE_IDR'/'IOE_SEVS'/'IOE_XPN'/'IOE_LEAFE'
--
-- 영향:
--   ProjectService.setBudgetSummaryFromItems()가
--     codeService.findCodeEntitiesByCId("IOE") 조회 후
--     c.getCTp()=="IOE_CPIT" 필터로 자본예산 코드 분류
--   → C_ID='IOE_CPIT' 행은 조회 자체가 안 되어 assetCodes=[] → devBg/machBg/intanBg 항상 0원
--   CostService.setBudgetCategory() 동일 원인으로 assetBg 항상 0원
--
-- CDVA 충돌 안전 확인:
--   IOE_CPIT 그룹: CDVA = 1xx 대역 (101, 102, 103, ...)
--   IOE 그룹(기존): CDVA = 0xx 대역 (001, 002, ..., 006)
--   → CDVA 겹침 없음, PK(C_ID, CDVA, STT_DT) 충돌 없음
--
-- 연쇄 수정:
--   C_ID 정정 후 C_DES도 재설정 (V20260512_010 WHERE C_ID='IOE' 조건이
--   C_ID='IOE_CPIT' 행에 적용되지 않아 C_DES 미수정된 문제 해소)

ALTER SESSION SET CURRENT_SCHEMA = ITPAPP;

-- ============================================================
-- STEP 1: IOE_CPIT 코드 그룹 C_ID 정정 (IOE_CPIT → IOE)
-- ============================================================
UPDATE TAAABB_CCODEM
   SET C_ID = 'IOE'
 WHERE C_ID = 'IOE_CPIT';

-- ============================================================
-- STEP 2: 방금 이동된 행들의 C_DES 재설정
--         (CDVA_DTL 내용 기준으로 개발비/기계장치/기타무형자산 분류)
-- ============================================================
UPDATE TAAABB_CCODEM
   SET C_DES = CASE
       WHEN CDVA_DTL LIKE '%기계장치%'    THEN '기계장치'
       WHEN CDVA_DTL LIKE '%개발비%'      THEN '개발비'
       WHEN CDVA_DTL LIKE '%기타무형자산%' THEN '기타무형자산'
       ELSE C_DES
   END
 WHERE C_ID = 'IOE'
   AND C_TP = 'IOE_CPIT';

COMMIT;
