-- DB-04: CAPPLA 복합 인덱스 추가
-- BudgetWorkService.getSummary() 내 결재완료 서브쿼리 성능 개선
-- (ORC_TB_CD, ORC_PK_VL, ORC_SNO_VL, APF_REL_SNO) 조건 최적화
CREATE INDEX IDX_CAPPLA_ORC_COMP
    ON TAAABB_CAPPLA (ORC_TB_CD, ORC_PK_VL, ORC_SNO_VL, APF_REL_SNO);
