-- DB-05: BITEMM PRJ_MNG_NO 인덱스 추가
-- BudgetWorkQueryRepositoryImpl.findApprovedItemAmountByGclDtt() 내
-- BITEMM JOIN BPROJM 조건 성능 개선
CREATE INDEX IDX_BITEMM_PRJ_MNG_NO
    ON TAAABB_BITEMM (PRJ_MNG_NO);
