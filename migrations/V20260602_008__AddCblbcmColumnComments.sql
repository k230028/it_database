-- =====================================================================
-- V20260602_008 TPRMPP_CBLBCM 컬럼 코멘트 누락 보강
-- 출처: 메타 용어사전(meta.csv) 표준 한글명
-- 등록 여부: 대상 10개 컬럼 모두 meta.csv 등록 확인 → (메타등록필요) 없음
-- 멱등: COMMENT ON COLUMN 은 재실행 시 동일값 덮어쓰기 (안전)
-- =====================================================================

-- 도메인 컬럼 (meta.csv 표준명)
COMMENT ON COLUMN "TPRMPP_CBLBCM"."STT_DTM"       IS '시작일시';
COMMENT ON COLUMN "TPRMPP_CBLBCM"."END_DTM"       IS '종료일시';
COMMENT ON COLUMN "TPRMPP_CBLBCM"."MRL_PRIT_TC"   IS '자료중요도구분코드';
COMMENT ON COLUMN "TPRMPP_CBLBCM"."NAC_KD_TC"     IS '게시물종류구분코드';

-- 공통 컬럼 (meta.csv 표준명)
COMMENT ON COLUMN "TPRMPP_CBLBCM"."GUID"          IS 'GUID';
COMMENT ON COLUMN "TPRMPP_CBLBCM"."GUID_PRG_SNO"  IS 'GUID진행일련번호';
COMMENT ON COLUMN "TPRMPP_CBLBCM"."FST_ENR_USID"  IS '최초등록사용자ID';
COMMENT ON COLUMN "TPRMPP_CBLBCM"."FST_ENR_DTM"   IS '최초등록일시';
COMMENT ON COLUMN "TPRMPP_CBLBCM"."LST_CHG_USID"  IS '최종변경사용자ID';
COMMENT ON COLUMN "TPRMPP_CBLBCM"."LST_CHG_DTM"   IS '최종변경일시';

COMMIT;
