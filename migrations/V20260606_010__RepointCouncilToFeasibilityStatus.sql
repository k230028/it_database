-- V20260606_010__RepointCouncilToFeasibilityStatus.sql
-- 정보화실무협의회(정실협) 로직을 '정보기술부문계획 정실협'(21/29) → '타당성검토 정실협'(31/32/39)으로 이동함에 따라,
-- 기존 진행중 협의회가 걸린 사업의 상태를 21 → 32 로 이관.
--
-- 배경: CouncilService 의 진행중 상태 상수가 21 → 32(타당성검토 정실협 진행중)로 변경됨.
--       기존 데이터(진행중 협의회 ASCT-2026-0400 의 사업 PRJ-2026-0414)는 아직 21 이라
--       변경된 'applied(=32)' 필터에 안 잡혀 목록에서 빠지므로 함께 이관한다.
-- 범위: 활성 BASCTM(협의회)이 존재하는 사업만 21 → 32. (협의회 없는 21 사업은 그대로 둠.)
-- 멱등성: 재실행 시 이미 32라 WHERE(=21) 에 안 걸려 안전. 신청 시 32 전이/완료 39 는 신규 건만 적용.

UPDATE ITPAPP.TPRMPP_BPROJM p
   SET p.IT_PTL_STS_TC = '32'
 WHERE p.IT_PTL_STS_TC = '21'
   AND p.DEL_YN = 'N'
   AND EXISTS (
        SELECT 1 FROM ITPAPP.TPRMPP_BASCTM a
         WHERE a.PRJ_MNG_NO = p.ABUS_MNG_NO
           AND a.PRJ_SNO = p.SNO
           AND a.DEL_YN = 'N'
   );

COMMIT;
