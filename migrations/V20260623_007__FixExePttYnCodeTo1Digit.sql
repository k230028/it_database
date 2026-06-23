-- =============================================================================
-- V20260623_007__FixExePttYnCodeTo1Digit.sql
-- EXE_PTT_YN(프로젝트 추진가능성) 공통코드 CDVA_ID를 구 3자리(001/002) → 1자리(1/2)로 정정.
--
-- [배경]
--   V004~V006(2자리 컬럼)과 달리, 저장 컬럼 ITPOWN.TPRMPP_BPROJM/BPROJL.EXE_PTT_YN 은
--   VARCHAR2(1 CHAR)이고 엔티티(Bprojm/BprojmL)도 length=1 "공통코드 EXE_PTT_YN 1자리, 예 '1','2'"로
--   선언되어 있다. 그런데 마스터(TPRMPP_CCODEM)의 해당 그룹 CDVA_ID만 구 3자리(001/002)로 남아,
--   드롭다운이 3자리 값을 전송 → 사업 저장(PUT) 시 ORA-12899("실제 3, 최대 1")가 발생했다.
--   → 컬럼이 1자리이므로 2자리가 아닌 **1자리**로 정정해야 한다(2자리도 오버플로).
--   기존 적재값은 이미 '1'(2건, 확정) 등 1자리이며, '0'(17건)은 매칭 없는 레거시 기본값이다.
--
-- [매핑] CDVA_NM 등 나머지 컬럼은 보존(UPDATE만 수행)
--   001 → 1 (확정)
--   002 → 2 (미정(검토중))
--
-- [참고] 프론트 일부 주석이 'PRJ_PUL_PTT cdva, VARCHAR2(3)'로 기재되어 있으나,
--        PRJ_PUL_PTT 그룹은 비어 있고 실제 운용 그룹은 EXE_PTT_YN(1자리)이다.
--
-- [멱등] 구 3자리 행이 없으면 각 UPDATE는 0건 처리된다. 재실행 안전.
-- 소유 스키마 ITPOWN. PK = (CO_C_ID_NM, CDVA_ID, STT_DT).
-- =============================================================================

UPDATE ITPOWN.TPRMPP_CCODEM SET CDVA_ID = '1' WHERE CO_C_ID_NM = 'EXE_PTT_YN' AND CDVA_ID = '001';
UPDATE ITPOWN.TPRMPP_CCODEM SET CDVA_ID = '2' WHERE CO_C_ID_NM = 'EXE_PTT_YN' AND CDVA_ID = '002';
