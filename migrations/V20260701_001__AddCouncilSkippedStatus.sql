-- =============================================================================
-- V20260701_001__AddCouncilSkippedStatus.sql
-- 협의회 진행상태 '생략' 코드 신설. (리뷰 C-1 수정)
--
--  - 버그: CouncilService.skipCouncil()이 VARCHAR2(2) 컬럼(IT_PTL_ASCT_PRG_STS_TC)에
--          문자열 "SKIPPED"(7자)를 저장 시도 → ORA-12899로 트랜잭션 롤백,
--          '협의회 생략' 기능이 실제로 동작하지 않음.
--  - 조치: 선형 흐름(01~13) 밖의 종료 상태로 '99'(생략) 코드를 CCODEM에 신설.
--          skipCouncil()은 changeStatus("99")로 전이하도록 소스에서 함께 수정.
--          (생략 시 사업상태가 39로 바뀌어 목록에서 사라지므로 종료 성격의 코드가 적절)
--
-- 멱등: NOT EXISTS 가드. 소유 스키마 ITPOWN. 적용 후 수정 금지(Flyway 체크섬).
-- =============================================================================

INSERT INTO ITPOWN.TPRMPP_CCODEM
    (CO_C_ID_NM,CDVA_ID,STT_DT,END_DT,CO_CDVA_NM,CO_C_NM,CDVA_NM,C_SQN_SNO,
     CO_C_INTN_NM,CO_C_INTN_CONE,CO_CDVA_ABV_NM,CO_CDVA_SPS,HRK_CDVA_ID,
     FST_ENR_USID,FST_ENR_DTM,DEL_YN)
SELECT 'IT_PTL_ASCT_PRG_STS_TC','99','20260101','99991231',NULL,'협의회진행상태','생략',99,
       NULL,NULL,NULL,NULL,NULL,'MIGRATION',SYSDATE,'N'
FROM DUAL
WHERE NOT EXISTS (
    SELECT 1 FROM ITPOWN.TPRMPP_CCODEM
    WHERE CO_C_ID_NM='IT_PTL_ASCT_PRG_STS_TC' AND CDVA_ID='99'
);

COMMIT;
