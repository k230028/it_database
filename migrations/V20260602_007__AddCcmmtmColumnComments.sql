-- =====================================================================
-- V20260602_007 TPRMPP_CCMMTM 컬럼 코멘트 누락 보강
-- 출처: 백엔드 엔티티 @Column(comment=...) / BaseEntity SoT
-- 멱등: COMMENT ON COLUMN 은 재실행 시 동일값 덮어쓰기 (안전)
-- =====================================================================

COMMENT ON COLUMN "TPRMPP_CCMMTM"."CMMT_SNO"      IS '댓글관리번호';
COMMENT ON COLUMN "TPRMPP_CCMMTM"."CMMT_TGT_SNO"  IS '댓글그룹번호';
COMMENT ON COLUMN "TPRMPP_CCMMTM"."HRK_CMMT_SNO"  IS '상위댓글관리번호';
COMMENT ON COLUMN "TPRMPP_CCMMTM"."GUID"          IS '전역고유식별자';
COMMENT ON COLUMN "TPRMPP_CCMMTM"."GUID_PRG_SNO"  IS '진행일련번호';
COMMENT ON COLUMN "TPRMPP_CCMMTM"."FST_ENR_USID"  IS '최초등록자사번';
COMMENT ON COLUMN "TPRMPP_CCMMTM"."FST_ENR_DTM"   IS '최초등록일시';
COMMENT ON COLUMN "TPRMPP_CCMMTM"."LST_CHG_USID"  IS '최종변경자사번';
COMMENT ON COLUMN "TPRMPP_CCMMTM"."LST_CHG_DTM"   IS '최종변경일시';

COMMIT;
