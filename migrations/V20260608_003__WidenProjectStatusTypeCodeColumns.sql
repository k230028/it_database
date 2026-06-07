-- V20260608_003__WidenProjectStatusTypeCodeColumns.sql
-- 정보화사업 코드 컬럼 폭 확장: IT_PTL_RPR_STS_TC(보고상태)·IT_PTL_TCHN_TP_TC(기술유형) VARCHAR2(2) → VARCHAR2(3)
--
-- 배경:
--  - 공통코드 IT_PTL_RPR_STS_TC / IT_PTL_TCHN_TP_TC 의 코드값은 3자리이나,
--    BPROJM/BPROJL 의 해당 컬럼이 VARCHAR2(2)로 남아 있어 사업 저장 시 3자리 코드를
--    기록하면 ORA-12899(값이 너무 큼)가 발생한다. (EXE_PTT_YN 과 동일 패턴 — V20260608_002 참고)
--  - 마스터/로그 엔티티(Bprojm, BprojmL) length 도 3으로 정합화한다.
--
-- 멱등성: 동일/더 큰 폭으로의 MODIFY 는 재실행 안전(축소가 아니므로 데이터 손실 없음).

ALTER TABLE ITPAPP.TPRMPP_BPROJM MODIFY (IT_PTL_RPR_STS_TC VARCHAR2(3 CHAR));
ALTER TABLE ITPAPP.TPRMPP_BPROJM MODIFY (IT_PTL_TCHN_TP_TC VARCHAR2(3 CHAR));
ALTER TABLE ITPAPP.TPRMPP_BPROJL MODIFY (IT_PTL_RPR_STS_TC VARCHAR2(3 CHAR));
ALTER TABLE ITPAPP.TPRMPP_BPROJL MODIFY (IT_PTL_TCHN_TP_TC VARCHAR2(3 CHAR));

COMMIT;
