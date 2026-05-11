-- ============================================================
-- V20260512_004: 사전 검증 (0건 아니면 RAISE)
-- ============================================================
DECLARE
    v_cnt NUMBER;
BEGIN
    -- PK 중복 탐지
    SELECT COUNT(*) INTO v_cnt
    FROM (
        SELECT REGEXP_REPLACE(REPLACE(C_ID,''-'',''_''), ''_[A-Z0-9]+$'', '') c_id_new,
               REGEXP_SUBSTR (REPLACE(C_ID,''-'',''_''), ''[A-Z0-9]+$'')       cdva_new,
               STT_DT
        FROM TAAABB_CCODEM
        WHERE DEL_YN = ''N''
    )
    GROUP BY c_id_new, cdva_new, STT_DT
    HAVING COUNT(*) > 1;

    IF v_cnt > 0 THEN
        RAISE_APPLICATION_ERROR(-20001,
            ''[V20260512_004] PK 중복 '' || v_cnt || ''건 발견 — 마이그레이션 중단'');
    END IF;

    -- V2 적재 건수 일치 확인
    SELECT COUNT(*) INTO v_cnt FROM TAAABB_CCODEM_V2;
    DECLARE v_src NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_src FROM TAAABB_CCODEM;
        IF v_cnt <> v_src THEN
            RAISE_APPLICATION_ERROR(-20002,
                ''[V20260512_004] V2 건수('' || v_cnt || '') <> 원본('' || v_src || '') — 마이그레이션 중단'');
        END IF;
    END;
END;
/
