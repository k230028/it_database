-- ============================================================================
-- 전산예산 외화금액(FC_AMT) 컬럼 추가 및 백필
-- ============================================================================
-- 목적:
--   3개 마스터(BCOSTM/BTERMM/BITEMM) + 3개 이력(BCOSTL/BTERML/BITEML)
--   테이블에 FC_AMT NUMBER(18,3) 컬럼을 추가하고,
--   외화 행에 한해 FC_AMT = ROUND(원화금액 / XCR, 3)으로 백필한다.
--   환율 변경 시 원본 외화금액 보존, 매번 곱셈 재계산 제거의 토대 마련.
--
-- 결정 근거 (.planning/phases/03-fcamt/03-CONTEXT.md):
--   - 결정 A: 단일 스크립트(DDL + DML + 검증). 멱등성 PL/SQL 가드는 생략한다.
--             (기존 18개 마이그레이션과 동일 패턴 — Flyway history 추적 신뢰)
--   - 결정 B: 원화(KRW) 행 및 데이터 불완전 행은 FC_AMT = NULL 유지.
--             (외화 개념 부재 → NULL이 의미론적으로 정확)
--             ※ REQUIREMENTS.md R2.1의 KRW=동기화 문구는 본 결정으로 정정됨.
--   - 결정 D: 외화이나 XCR/원화금액 NULL/0인 이상치 행은 NULL 유지 +
--             DBMS_OUTPUT 식별자 로그. 마이그레이션은 SUCCESS로 종료.
--
-- 이력 테이블(BCOSTL/BTERML/BITEML)에도 동반 추가:
--   @LogTarget AOP가 마스터→이력 1:1 컬럼 거울 적재를 수행하므로,
--   이력 테이블에 FC_AMT가 없으면 외화 수정 시 런타임 매핑 실패 가능.
--   과거 이력 행의 FC_AMT는 NULL 유지 (소급 백필 없음).
--
-- 금액 컬럼 매핑:
--   BCOSTM/BCOSTL → IT_MNGC_BG_AMT
--   BTERMM/BTERML → TML_AMT
--   BITEMM/BITEML → GCL_AMT
-- ============================================================================

-- ── 1. 컬럼 추가 (마스터 3 + 이력 3) ────────────────────────────────────────
ALTER TABLE ITPAPP.TPRMPP_BCOSTM ADD (FC_AMT NUMBER(18,3));
ALTER TABLE ITPAPP.TPRMPP_BTERMM ADD (FC_AMT NUMBER(18,3));
ALTER TABLE ITPAPP.TPRMPP_BITEMM ADD (FC_AMT NUMBER(18,3));
ALTER TABLE ITPAPP.TPRMPP_BCOSTL ADD (FC_AMT NUMBER(18,3));
ALTER TABLE ITPAPP.TPRMPP_BTERML ADD (FC_AMT NUMBER(18,3));
ALTER TABLE ITPAPP.TPRMPP_BITEML ADD (FC_AMT NUMBER(18,3));

-- ── 2. 컬럼 코멘트 ──────────────────────────────────────────────────────────
COMMENT ON COLUMN ITPAPP.TPRMPP_BCOSTM.FC_AMT IS '외화금액';
COMMENT ON COLUMN ITPAPP.TPRMPP_BTERMM.FC_AMT IS '외화금액';
COMMENT ON COLUMN ITPAPP.TPRMPP_BITEMM.FC_AMT IS '외화금액';
COMMENT ON COLUMN ITPAPP.TPRMPP_BCOSTL.FC_AMT IS '외화금액';
COMMENT ON COLUMN ITPAPP.TPRMPP_BTERML.FC_AMT IS '외화금액';
COMMENT ON COLUMN ITPAPP.TPRMPP_BITEML.FC_AMT IS '외화금액';

-- ── 3. 외화 행 백필 (마스터 3건 — KRW 및 데이터 불완전 행은 NULL 유지) ───
--    이력 테이블은 백필하지 않는다 (과거 이력은 NULL 유지).

-- BCOSTM: 원화금액 = IT_MNGC_BG_AMT
UPDATE ITPAPP.TPRMPP_BCOSTM
   SET FC_AMT = ROUND(IT_MNGC_BG_AMT / XCR, 3)
 WHERE CUR_C IS NOT NULL
   AND CUR_C != 'KRW'
   AND XCR IS NOT NULL
   AND XCR > 0
   AND IT_MNGC_BG_AMT IS NOT NULL;

-- BTERMM: 원화금액 = TML_AMT (단말기 금액)
UPDATE ITPAPP.TPRMPP_BTERMM
   SET FC_AMT = ROUND(TML_AMT / XCR, 3)
 WHERE CUR_C IS NOT NULL
   AND CUR_C != 'KRW'
   AND XCR IS NOT NULL
   AND XCR > 0
   AND TML_AMT IS NOT NULL;

-- BITEMM: 원화금액 = GCL_AMT (품목 금액)
UPDATE ITPAPP.TPRMPP_BITEMM
   SET FC_AMT = ROUND(GCL_AMT / XCR, 3)
 WHERE CUR_C IS NOT NULL
   AND CUR_C != 'KRW'
   AND XCR IS NOT NULL
   AND XCR > 0
   AND GCL_AMT IS NOT NULL;

-- ── 4. 검증 SELECT (정상 행만 대상 — 1원 오차 허용) ─────────────────────
--    카운트가 0이어야 정상. Flyway 콘솔에서 결과 확인.
SELECT COUNT(*) AS BCOSTM_INCONSISTENT
  FROM ITPAPP.TPRMPP_BCOSTM
 WHERE FC_AMT IS NOT NULL
   AND ABS(FC_AMT * XCR - IT_MNGC_BG_AMT) >= 1;

SELECT COUNT(*) AS BTERMM_INCONSISTENT
  FROM ITPAPP.TPRMPP_BTERMM
 WHERE FC_AMT IS NOT NULL
   AND ABS(FC_AMT * XCR - TML_AMT) >= 1;

SELECT COUNT(*) AS BITEMM_INCONSISTENT
  FROM ITPAPP.TPRMPP_BITEMM
 WHERE FC_AMT IS NOT NULL
   AND ABS(FC_AMT * XCR - GCL_AMT) >= 1;

-- ── 5. 이상치 식별자 로그 (외화이나 백필 누락된 행 — 결정 D) ──────────────
--    XCR NULL/0 또는 원화금액 NULL 등으로 FC_AMT 계산이 불가한 행을
--    DBMS_OUTPUT으로 식별자 출력. 마이그레이션은 SUCCESS 유지.

-- BCOSTM 이상치: 식별자 = IT_MNGC_NO/IT_MNGC_SNO
BEGIN
  FOR r IN (
    SELECT IT_MNGC_NO, IT_MNGC_SNO
      FROM ITPAPP.TPRMPP_BCOSTM
     WHERE CUR_C IS NOT NULL
       AND CUR_C != 'KRW'
       AND FC_AMT IS NULL
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('[BCOSTM 백필누락] ' || r.IT_MNGC_NO || '/' || r.IT_MNGC_SNO);
  END LOOP;
END;
/

-- BTERMM 이상치: 식별자 = TMN_MNG_NO/TMN_SNO
BEGIN
  FOR r IN (
    SELECT TMN_MNG_NO, TMN_SNO
      FROM ITPAPP.TPRMPP_BTERMM
     WHERE CUR_C IS NOT NULL
       AND CUR_C != 'KRW'
       AND FC_AMT IS NULL
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('[BTERMM 백필누락] ' || r.TMN_MNG_NO || '/' || r.TMN_SNO);
  END LOOP;
END;
/

-- BITEMM 이상치: 식별자 = GCL_MNG_NO/GCL_SNO
BEGIN
  FOR r IN (
    SELECT GCL_MNG_NO, GCL_SNO
      FROM ITPAPP.TPRMPP_BITEMM
     WHERE CUR_C IS NOT NULL
       AND CUR_C != 'KRW'
       AND FC_AMT IS NULL
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('[BITEMM 백필누락] ' || r.GCL_MNG_NO || '/' || r.GCL_SNO);
  END LOOP;
END;
/

COMMIT;
