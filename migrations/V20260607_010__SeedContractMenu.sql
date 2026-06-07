-- 입찰/계약(Stage 3) 메뉴/라우트 시드
-- 배치 순서: 라우트(CMENUD) → 메뉴(CMENUM). 권한 행 없음 = 전체 공개.
-- 멱등성: MERGE WHEN NOT MATCHED. 재실행 안전.
-- 한글 포함: NLS_LANG=KOREAN_KOREA.AL32UTF8 환경에서 실행.
--
-- 배치 결정:
--   - 헤더: MHED0002 "사업/예산" (기존)
--   - 부모 GRP: MINF0015 "정보화사업" (depth 2, MHED0002 하위)
--   - 신규 LNK: MINF0025 "입찰/계약" → /project/contract (depth 3, SNO 100)
--   - 권한: CMENUA 행 없음 → 전체 인증 사용자 접근 (과업심의위원회/MINF0024와 동일 정책)
SET DEFINE OFF;
SET SQLBLANKLINES ON;

-- =====================================================================
-- 1) 라우트 카탈로그
-- =====================================================================
MERGE INTO TPRMPP_CMENUD t
USING (
  SELECT '/project/contract' AS SRE_PTH,
         '입찰/계약'         AS SRE_MNU_NM,
         '01'                AS SYS_HRK_MNU_ID
  FROM DUAL
) s ON (t.SRE_PTH = s.SRE_PTH)
WHEN NOT MATCHED THEN
  INSERT (SRE_PTH, SRE_MNU_NM, SYS_HRK_MNU_ID, USE_YN, DEL_YN,
          GUID, GUID_PRG_SNO, FST_ENR_DTM, FST_ENR_USID)
  VALUES (s.SRE_PTH, s.SRE_MNU_NM, s.SYS_HRK_MNU_ID, 'Y', 'N',
          RAWTOHEX(SYS_GUID()), 1, SYSDATE, 'SYSTEM');

-- =====================================================================
-- 2) 메뉴 트리
--    MINF0025: LNK, depth 3, MINF0015(정보화사업 GRP) 하위, SNO 100
--    WHL_MNU_PTH: /MHED0002/MINF0015/MINF0025
-- =====================================================================
MERGE INTO TPRMPP_CMENUM t
USING (
  SELECT 'MINF0025'                    AS MNU_ID,
         'MINF0015'                    AS HRK_MNU_ID,
         '입찰/계약'                   AS MNU_NM,
         'LNK'                         AS MNU_TP_C,
         '/project/contract'           AS SRE_PTH,
         100                           AS MNU_SOT_SQN_SNO,
         'N'                           AS HID_YN,
         3                             AS MNU_DEP,
         '/MHED0002/MINF0015/MINF0025' AS WHL_MNU_PTH
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
--    CMENUA 행 없음 = 전체 인증 사용자 접근 (과업심의위원회/MINF0024와 동일).
-- =====================================================================

COMMIT;
