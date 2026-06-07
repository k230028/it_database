-- 소요예산 산정(Stage 1) 메뉴/라우트/권한 시드
-- 배치 순서: 라우트(CMENUD) → 메뉴(CMENUM). 권한 행 없음 = 전체 공개.
-- 멱등성: MERGE WHEN NOT MATCHED. 재실행 안전.
-- 한글 포함: NLS_LANG=KOREAN_KOREA.AL32UTF8 환경에서 실행.
--
-- 배치 결정:
--   - 헤더: MHED0002 "사업/예산" (기존)
--   - 부모 GRP: MINF0015 "정보화사업" (depth 2, MHED0002 하위)
--   - 신규 LNK: MINF0023 "소요예산 산정" → /project/estimate (depth 3, SNO 80)
--   - 권한: CMENUA 행 없음 → 전체 인증 사용자 접근 (MINF0016~MINF0022와 동일 정책)
SET DEFINE OFF;
SET SQLBLANKLINES ON;

-- =====================================================================
-- 1) 라우트 카탈로그
-- =====================================================================
MERGE INTO TPRMPP_CMENUD t
USING (
  SELECT '/project/estimate' AS SRE_PTH,
         '소요예산 산정'     AS SRE_MNU_NM,
         '01'               AS SYS_HRK_MNU_ID
  FROM DUAL
) s ON (t.SRE_PTH = s.SRE_PTH)
WHEN NOT MATCHED THEN
  INSERT (SRE_PTH, SRE_MNU_NM, SYS_HRK_MNU_ID, USE_YN, DEL_YN,
          GUID, GUID_PRG_SNO, FST_ENR_DTM, FST_ENR_USID)
  VALUES (s.SRE_PTH, s.SRE_MNU_NM, s.SYS_HRK_MNU_ID, 'Y', 'N',
          RAWTOHEX(SYS_GUID()), 1, SYSDATE, 'SYSTEM');

-- =====================================================================
-- 2) 메뉴 트리
--    MINF0023: LNK, depth 3, MINF0015(정보화사업 GRP) 하위, SNO 80
--    WHL_MNU_PTH: /MHED0002/MINF0015/MINF0023
-- =====================================================================
MERGE INTO TPRMPP_CMENUM t
USING (
  SELECT 'MINF0023'                     AS MNU_ID,
         'MINF0015'                     AS HRK_MNU_ID,
         '소요예산 산정'                AS MNU_NM,
         'LNK'                          AS MNU_TP_C,
         '/project/estimate'            AS SRE_PTH,
         80                             AS MNU_SOT_SQN_SNO,
         'N'                            AS HID_YN,
         3                              AS MNU_DEP,
         '/MHED0002/MINF0015/MINF0023'  AS WHL_MNU_PTH
  FROM DUAL
) s ON (t.MNU_ID = s.MNU_ID)
WHEN NOT MATCHED THEN
  INSERT (MNU_ID, HRK_MNU_ID, MNU_NM, MNU_TP_C, SRE_PTH,
          MNU_SOT_SQN_SNO, HID_YN, MNU_DEP, WHL_MNU_PTH,
          DEL_YN, GUID, GUID_PRG_SNO, FST_ENR_DTM, FST_ENR_USID)
  VALUES (s.MNU_ID, s.HRK_MNU_ID, s.MNU_NM, s.MNU_TP_C, s.SRE_PTH,
          s.MNU_SOT_SQN_SNO, s.HID_YN, s.MNU_DEP, s.WHL_MNU_PTH,
          'N', RAWTOHEX(SYS_GUID()), 1, SYSDATE, 'SYSTEM');

-- =====================================================================
-- 3) 권한 매핑: 없음.
--    CMENUA 행 없음 = 전체 인증 사용자 접근 (사업 목록/정보화실무협의회/과업심의위원회 등과 동일).
-- =====================================================================

COMMIT;
