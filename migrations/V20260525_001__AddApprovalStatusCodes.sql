-- ─────────────────────────────────────────────────────────────────────────────
-- V20260525_001 — 결재 상태 및 결재선 상태, 회수 알림 종류 공통코드 등록
--
-- 목적:
--   1) APF_STS — 결재상태 (결재중/결재완료/반려/회수)
--   2) DCD_STS — 결재선상태 (미결재/승인/반려/회수무효)
--   3) INF_TP  — 알림종류구분에 '006 결재회수' 추가
--
-- 컬럼 매핑 주의(TPRMPP_CCODEM 실제 스키마):
--   - 코드값        : CDVA      (템플릿의 C_VL 아님)
--   - 코드순서      : C_SQN     (템플릿의 SORT_NO 아님)
--   - 사용여부 컬럼 없음, 삭제여부(DEL_YN)만 존재
--   - PK 구성: (C_ID, CDVA, STT_DT) — STT_DT NOT NULL
--   - 감사 컬럼  : FST_ENR_DTM/USID, LST_CHG_DTM/USID, GUID
--
-- 멱등성:
--   - MERGE 사용. (C_ID, CDVA, STT_DT) 기준 미존재 시에만 INSERT.
-- ─────────────────────────────────────────────────────────────────────────────

-- ── 1) APF_STS — 결재상태 ────────────────────────────────────────────────────
MERGE INTO TPRMPP_CCODEM tgt
USING (
    SELECT 'APF_STS' AS C_ID, '001' AS CDVA, '결재중'   AS C_NM, 1 AS C_SQN, DATE '2026-01-01' AS STT_DT FROM DUAL UNION ALL
    SELECT 'APF_STS',         '002',         '결재완료',       2,           DATE '2026-01-01'           FROM DUAL UNION ALL
    SELECT 'APF_STS',         '003',         '반려',           3,           DATE '2026-01-01'           FROM DUAL UNION ALL
    SELECT 'APF_STS',         '004',         '회수',           4,           DATE '2026-01-01'           FROM DUAL
) src
ON (tgt.C_ID = src.C_ID AND tgt.CDVA = src.CDVA AND tgt.STT_DT = src.STT_DT)
WHEN NOT MATCHED THEN INSERT (
    C_ID, CDVA, CDVA_NM, STT_DT, C_NM, C_SQN,
    DEL_YN, GUID, GUID_PRG_SNO,
    FST_ENR_DTM, FST_ENR_USID, LST_CHG_DTM, LST_CHG_USID
) VALUES (
    src.C_ID, src.CDVA, src.C_NM, src.STT_DT, src.C_NM, src.C_SQN,
    'N', RAWTOHEX(SYS_GUID()), 1,
    SYSTIMESTAMP, 'SYSTEM', SYSTIMESTAMP, 'SYSTEM'
);

-- ── 2) DCD_STS — 결재선상태 ──────────────────────────────────────────────────
MERGE INTO TPRMPP_CCODEM tgt
USING (
    SELECT 'DCD_STS' AS C_ID, '001' AS CDVA, '미결재'   AS C_NM, 1 AS C_SQN, DATE '2026-01-01' AS STT_DT FROM DUAL UNION ALL
    SELECT 'DCD_STS',         '002',         '승인',           2,           DATE '2026-01-01'           FROM DUAL UNION ALL
    SELECT 'DCD_STS',         '003',         '반려',           3,           DATE '2026-01-01'           FROM DUAL UNION ALL
    SELECT 'DCD_STS',         '004',         '회수무효',       4,           DATE '2026-01-01'           FROM DUAL
) src
ON (tgt.C_ID = src.C_ID AND tgt.CDVA = src.CDVA AND tgt.STT_DT = src.STT_DT)
WHEN NOT MATCHED THEN INSERT (
    C_ID, CDVA, CDVA_NM, STT_DT, C_NM, C_SQN,
    DEL_YN, GUID, GUID_PRG_SNO,
    FST_ENR_DTM, FST_ENR_USID, LST_CHG_DTM, LST_CHG_USID
) VALUES (
    src.C_ID, src.CDVA, src.C_NM, src.STT_DT, src.C_NM, src.C_SQN,
    'N', RAWTOHEX(SYS_GUID()), 1,
    SYSTIMESTAMP, 'SYSTEM', SYSTIMESTAMP, 'SYSTEM'
);

-- ── 3) INF_TP — 알림종류구분에 '006 결재회수' 추가 ───────────────────────────
MERGE INTO TPRMPP_CCODEM tgt
USING (
    SELECT 'INF_TP' AS C_ID, '006' AS CDVA, '결재회수' AS C_NM, 6 AS C_SQN, DATE '2026-01-01' AS STT_DT FROM DUAL
) src
ON (tgt.C_ID = src.C_ID AND tgt.CDVA = src.CDVA AND tgt.STT_DT = src.STT_DT)
WHEN NOT MATCHED THEN INSERT (
    C_ID, CDVA, CDVA_NM, STT_DT, C_NM, C_SQN,
    DEL_YN, GUID, GUID_PRG_SNO,
    FST_ENR_DTM, FST_ENR_USID, LST_CHG_DTM, LST_CHG_USID
) VALUES (
    src.C_ID, src.CDVA, src.C_NM, src.STT_DT, src.C_NM, src.C_SQN,
    'N', RAWTOHEX(SYS_GUID()), 1,
    SYSTIMESTAMP, 'SYSTEM', SYSTIMESTAMP, 'SYSTEM'
);

COMMIT;
