-- =====================================================================
-- DDL-애플리케이션 컬럼 폭 불일치 해소 (실제 저장값 기준 확대)
-- =====================================================================
-- 배경:
--   엔티티/서비스가 실제로 저장하는 값이 DDL 컬럼 폭을 초과하여,
--   해당 값 INSERT/UPDATE 시 ORA-12899(value too large) 가 발생할 수 있다.
--   (DDL 정의가 잘못된 케이스이므로 DDL 측을 실제 저장값에 맞춰 확대한다.)
--
-- 1) TPRMPP_CDECIM.DCD_STS_C  VARCHAR2(1) → VARCHAR2(3)
--    DecisionStatus enum 이 '001'(미결재)/'002'(승인)/'003'(반려)/'004'(회수무효)
--    3자리 코드를 저장하나 물리 컬럼이 1자리였다.
--
-- 2) TPRMPP_CBLBMM / TPRMPP_CBLBML 의 INQ_DWN_ATH_TC, WRT_DWN_ATH_TC
--    VARCHAR2(2) → VARCHAR2(20)
--    게시판 메타 권한코드가 'ALL' / 'ROLE_ADMIN' / 'ROLE_USER' /
--    'ROLE_DEPT_MANAGER'(최대 17자) 를 저장하나 물리 컬럼이 2자리였다.
--    (컬럼 DEFAULT 가 'ALL'(3자)이라 기본값조차 폭을 초과하던 상태)
--    CBLBML 은 CBLBMM 변경이력(감사로그) 미러 테이블이므로 동일 폭으로 확대한다.
--
-- 멱등성: VARCHAR2 폭 확대 MODIFY 는 데이터 손실이 없고, 동일/더 큰 크기로
--         반복 실행해도 안전하다. (축소가 아니므로 ORA-01441 미발생)
-- =====================================================================

-- 1) 결재상태코드
ALTER TABLE ITPAPP.TPRMPP_CDECIM MODIFY ("DCD_STS_C" VARCHAR2(3 CHAR));

-- 2) 게시판 권한코드 (마스터 + 로그)
ALTER TABLE ITPAPP.TPRMPP_CBLBMM MODIFY (
    "INQ_DWN_ATH_TC" VARCHAR2(20 CHAR),
    "WRT_DWN_ATH_TC" VARCHAR2(20 CHAR)
);

ALTER TABLE ITPAPP.TPRMPP_CBLBML MODIFY (
    "INQ_DWN_ATH_TC" VARCHAR2(20 CHAR),
    "WRT_DWN_ATH_TC" VARCHAR2(20 CHAR)
);
