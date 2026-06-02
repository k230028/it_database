-- =====================================================================
-- V20260602_010 TPRMPP_CBLBCL(게시물 변경 로그) 도메인 컬럼 코멘트 보강
-- 출처: 메타 용어사전(meta.csv) 표준 한글명
-- 미등록 용어: HRK_NAC_MNG_NO / NAC_GRP_NO / CHG_TC → (메타등록필요) 표기
-- 공통 감사 컬럼은 V20260602_009에서 메타 통일 완료 (여기서 제외)
-- 멱등: COMMENT ON COLUMN 재실행 시 동일값 덮어쓰기 (안전)
-- =====================================================================

COMMENT ON COLUMN "TPRMPP_CBLBCL"."NAC_NO"          IS '게시물번호';
COMMENT ON COLUMN "TPRMPP_CBLBCL"."BLB_ID"          IS '게시판ID';
COMMENT ON COLUMN "TPRMPP_CBLBCL"."ANC_YN"          IS '공지여부';
COMMENT ON COLUMN "TPRMPP_CBLBCL"."APG_FL_NBR"      IS '첨부파일수';
COMMENT ON COLUMN "TPRMPP_CBLBCL"."BBR_C"           IS '부점코드';
COMMENT ON COLUMN "TPRMPP_CBLBCL"."END_DTM"         IS '종료일시';
COMMENT ON COLUMN "TPRMPP_CBLBCL"."FL_APG_YN"       IS '파일첨부여부';
COMMENT ON COLUMN "TPRMPP_CBLBCL"."GRP_SQN_SNO"     IS '그룹순서일련번호';
COMMENT ON COLUMN "TPRMPP_CBLBCL"."MRL_PRIT_TC"     IS '자료중요도구분코드';
COMMENT ON COLUMN "TPRMPP_CBLBCL"."NAC_CONE"        IS '게시물내용';
COMMENT ON COLUMN "TPRMPP_CBLBCL"."NAC_ID"          IS '게시물ID';
COMMENT ON COLUMN "TPRMPP_CBLBCL"."NAC_INQ_NBR"     IS '게시물조회수';
COMMENT ON COLUMN "TPRMPP_CBLBCL"."NAC_KD_TC"       IS '게시물종류구분코드';
COMMENT ON COLUMN "TPRMPP_CBLBCL"."NAC_LEV_MNG_SNO" IS '게시물레벨관리일련번호';
COMMENT ON COLUMN "TPRMPP_CBLBCL"."NAC_TTL"         IS '게시물제목';
COMMENT ON COLUMN "TPRMPP_CBLBCL"."SRE_USE_YN"      IS '화면사용여부';
COMMENT ON COLUMN "TPRMPP_CBLBCL"."STT_DTM"         IS '시작일시';

-- 메타 미등록 (후속 메타 등록 필요)
COMMENT ON COLUMN "TPRMPP_CBLBCL"."HRK_NAC_MNG_NO"  IS '상위게시물관리번호(메타등록필요)';
COMMENT ON COLUMN "TPRMPP_CBLBCL"."NAC_GRP_NO"      IS '게시물그룹번호(메타등록필요)';
COMMENT ON COLUMN "TPRMPP_CBLBCL"."CHG_TC"          IS '변경구분코드(메타등록필요)';

COMMIT;
