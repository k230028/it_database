-- 전결권(IT_PTL_EDRT_TC) 레거시 라벨 정리
--   * 구 버전은 직급 라벨('부장' 등)을 저장했으나, 현재는 공통코드 CDVA(2자리: 1x/2x)를 저장한다.
--   * 잔존 라벨 '부장'(최하위 등급)을 공통코드의 최하위 등급 '부서장' 코드 '24'(자본예산 부서장,
--     기준 미상 시 앱 기본값과 동일)로 정규화한다.
--   * 대상: TPRMPP_BPROJM(마스터) + TPRMPP_BPROJL(변경 로그 미러).
-- 멱등성: 라벨 '부장'인 행만 갱신하므로 재실행해도 안전하며, 이미 코드값(숫자)인 행은 영향 없음.
-- 참고: 해당 사업(PRJ-2026-0414)은 소요자원 품목이 없어 자본/일반관리비 모두 0 → 앱 산정 시 '24'(부서장).

BEGIN
    UPDATE TPRMPP_BPROJM SET IT_PTL_EDRT_TC = '24' WHERE IT_PTL_EDRT_TC = '부장';
    UPDATE TPRMPP_BPROJL SET IT_PTL_EDRT_TC = '24' WHERE IT_PTL_EDRT_TC = '부장';
    COMMIT;
END;
/
