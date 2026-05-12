-- IOE_CPIT 비목 코드의 C_DES를 CDVA_DTL 기반으로 재설정
-- V003 마이그레이션에서 C_DES = old.CTT_TP_DES(="비목")로 일괄 설정되어
-- CostService의 개발비/기계장치/기타무형자산 switch 분기가 항상 0원이 되는 문제 수정
ALTER SESSION SET CURRENT_SCHEMA = ITPAPP;

UPDATE TAAABB_CCODEM
SET C_DES = CASE
    WHEN CDVA_DTL LIKE '%기계장치%'   THEN '기계장치'
    WHEN CDVA_DTL LIKE '%개발비%'     THEN '개발비'
    WHEN CDVA_DTL LIKE '%기타무형자산%' THEN '기타무형자산'
    ELSE C_DES
END
WHERE C_ID = 'IOE' AND C_TP = 'IOE_CPIT';

COMMIT;
