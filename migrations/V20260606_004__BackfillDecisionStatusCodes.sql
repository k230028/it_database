-- V20260606_004__BackfillDecisionStatusCodes.sql
-- 결재선 결재상태(TPRMPP_CDECIM.DCD_STS_C)를 현행 1자리 체계(1~4)로 정규화.
-- 현행 CCODEM DCD_STS_C: 1=미결재, 2=승인, 3=반려, 4=회수무효 (컬럼 VARCHAR2(1)).
-- 레거시: 0-based('0'=미결재) 및 3자리('001'~'004'). 멱등(대상값만 WHERE).
SET DEFINE OFF

UPDATE ITPAPP.TPRMPP_CDECIM SET DCD_STS_C = CASE TRIM(DCD_STS_C)
  WHEN '0'   THEN '1'   -- 레거시 0-based 미결재
  WHEN '001' THEN '1'
  WHEN '002' THEN '2'
  WHEN '003' THEN '3'
  WHEN '004' THEN '4'
  ELSE DCD_STS_C END
WHERE TRIM(DCD_STS_C) IN ('0','001','002','003','004');

COMMIT;
