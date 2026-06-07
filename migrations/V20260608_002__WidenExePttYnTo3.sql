-- V20260608_002__WidenExePttYnTo3.sql
-- 프로젝트 추진가능성(EXE_PTT_YN) 컬럼 폭 확장: VARCHAR2(1) → VARCHAR2(3)
--
-- 배경:
--  - 공통코드 EXE_PTT_YN 의 코드값은 3자리('001'=확정, '002'=미정(검토중))이나,
--    BPROJM/BPROJL 의 EXE_PTT_YN 컬럼은 VARCHAR2(1)로 남아 있어 사업 저장 시
--    로그(BPROJL) INSERT에서 ORA-12899(값이 너무 큼)가 발생했다.
--  - 로그 엔티티(BprojmL)는 이미 length=3 이나 마스터 엔티티(Bprojm)와 DB 컬럼이
--    1자리로 남아 있던 불일치를 정리한다.
--
-- 멱등성: 동일/더 큰 폭으로의 MODIFY 는 재실행 안전(축소가 아니므로 데이터 손실 없음).

ALTER TABLE ITPAPP.TPRMPP_BPROJM MODIFY (EXE_PTT_YN VARCHAR2(3 CHAR));
ALTER TABLE ITPAPP.TPRMPP_BPROJL MODIFY (EXE_PTT_YN VARCHAR2(3 CHAR));

COMMIT;
