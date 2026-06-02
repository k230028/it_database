-- =====================================================================
-- V20260602_011 게시물 그룹 식별자를 NAC_GRP_NO → NAC_ID 로 일원화
-- - TPRMPP_CBLBCM/CBLBCL 의 NAC_GRP_NO 컬럼 제거
--   (그룹 식별은 NAC_ID 컬럼을 사용. 엔티티 initGroupAsRoot/Reply 가 NAC_ID 설정)
-- - 복합 인덱스 (NAC_GRP_NO, GRP_SQN_SNO) → (NAC_ID, GRP_SQN_SNO) 재구성
--   ※ DROP COLUMN 시 해당 컬럼이 포함된 인덱스는 Oracle 이 자동 삭제
-- 멱등: 존재 여부 확인 후 수행
-- =====================================================================

-- 1) 그룹 조회/정렬용 인덱스 재구성 (NAC_ID 기준 신규 생성)
DECLARE v NUMBER; BEGIN
  SELECT COUNT(*) INTO v FROM user_indexes WHERE index_name = 'IX_CBLBCM_NAC_ID_GRP_SQN_SNO';
  IF v = 0 THEN
    EXECUTE IMMEDIATE 'CREATE INDEX "IX_CBLBCM_NAC_ID_GRP_SQN_SNO" ON "TPRMPP_CBLBCM" ("NAC_ID", "GRP_SQN_SNO")';
  END IF;
END;
/

-- 2) NAC_GRP_NO 컬럼 제거 (마스터)
DECLARE v NUMBER; BEGIN
  SELECT COUNT(*) INTO v FROM user_tab_columns WHERE table_name = 'TPRMPP_CBLBCM' AND column_name = 'NAC_GRP_NO';
  IF v > 0 THEN
    EXECUTE IMMEDIATE 'ALTER TABLE "TPRMPP_CBLBCM" DROP COLUMN "NAC_GRP_NO"';
  END IF;
END;
/

-- 3) NAC_GRP_NO 컬럼 제거 (변경 로그)
DECLARE v NUMBER; BEGIN
  SELECT COUNT(*) INTO v FROM user_tab_columns WHERE table_name = 'TPRMPP_CBLBCL' AND column_name = 'NAC_GRP_NO';
  IF v > 0 THEN
    EXECUTE IMMEDIATE 'ALTER TABLE "TPRMPP_CBLBCL" DROP COLUMN "NAC_GRP_NO"';
  END IF;
END;
/

COMMIT;
