-- =============================================================================
-- V20260630_001__AddInfoSecAdminRole.sql
-- 정보보호관리자(ITPAD002) 자격등급 신설 + 정보보호기획팀(TEM_C=18301) 현직 직원에게 부여.
-- (PRD_c_20260620 #3 — Phase 1: 자격등급/권한)
--
--  - 용도: 정보보호기획팀이 정보보호시스템 사업(IT_PTL_ASCT_DBR_TC='04')의
--          협의회 개최준비를 IT관리자처럼 수행하기 위한 전용 자격등급.
--  - Spring Security Role 매핑: ITPAD002 → ROLE_INFOSEC_ADMIN (CustomUserDetails).
--  - 신규 입사/이동 인원은 관리자 역할관리 화면에서 별도 부여.
--
-- 멱등: NOT EXISTS 가드로 재적용 안전. 소유 스키마 ITPOWN.
-- =============================================================================

-- 1) 자격등급 등록 (TPRMPP_CAUTHI)
INSERT INTO ITPOWN.TPRMPP_CAUTHI
    (ATH_ID, QLF_GR_NM, QLF_GR_MAT, USE_YN,
     FST_ENR_USID, FST_ENR_DTM, DEL_YN, GUID, GUID_PRG_SNO, LST_CHG_USID, LST_CHG_DTM)
SELECT 'ITPAD002', '정보보호관리자',
       '정보보호기획팀 — 정보보호시스템 사업(IT_PTL_ASCT_DBR_TC=04) 협의회 개최준비 권한', 'Y',
       'MIGRATION', SYSDATE, 'N', RAWTOHEX(SYS_GUID()), 0, 'MIGRATION', SYSDATE
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM ITPOWN.TPRMPP_CAUTHI WHERE ATH_ID = 'ITPAD002');

-- 2) 정보보호기획팀(TEM_C=18301) 현직 직원에게 ITPAD002 부여 (TPRMPP_CROLEI)
INSERT INTO ITPOWN.TPRMPP_CROLEI
    (ATH_ID, ENO, USE_YN,
     FST_ENR_USID, FST_ENR_DTM, DEL_YN, GUID, GUID_PRG_SNO, LST_CHG_USID, LST_CHG_DTM)
SELECT 'ITPAD002', u.ENO, 'Y',
       'MIGRATION', SYSDATE, 'N', RAWTOHEX(SYS_GUID()), 0, 'MIGRATION', SYSDATE
FROM ITPOWN.TPRMPP_CUSERI u
WHERE u.TEM_C = '18301'
  AND NVL(u.DEL_YN, 'N') = 'N'
  AND NOT EXISTS (
        SELECT 1 FROM ITPOWN.TPRMPP_CROLEI r
        WHERE r.ATH_ID = 'ITPAD002' AND r.ENO = u.ENO
  );

COMMIT;
