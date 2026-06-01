-- ============================================================
-- TPRMPP_CBLBMM.BLB_TP → BLB_TC 전환
--   - 컬럼명: BLB_TP → BLB_TC
--   - 타입:   VARCHAR2(32) → VARCHAR2(3)
--   - 값:     'BLB_TP_001' → '001', 'BLB_TP_002' → '002' (공통코드 BLB_TC 체계)
--   - 변경로그 테이블 TPRMPP_CBLBML도 동일 적용 (감사 복사가 @Column(name) 기준 매칭)
-- 멱등성(idempotent): 컬럼 존재 여부로 가드. 재실행/부분적용 상태에서도 안전.
-- 주의:
--   1) ddl-auto=update는 RENAME/타입축소/NOT NULL 신규추가를 못 하므로 본 스크립트 선행 필요.
--   2) 기존 NOT NULL은 유지되므로 MODIFY 시 NOT NULL을 다시 선언하지 않는다(ORA-01442 회피).
--   3) EXECUTE IMMEDIATE 문자열 안에 한글을 넣으면 클라이언트 인코딩에 따라 파싱 실패(ORA-01756).
--      → 한글이 들어가는 COMMENT 는 PL/SQL 밖 최상위 문장으로 둔다.
--   4) 한글 COMMENT 적용을 위해 SQL*Plus 실행 시 UTF-8 인코딩 권장:
--      set NLS_LANG=.AL32UTF8  (미설정 시 구조 변경은 적용되나 COMMENT 만 ORA-01756 로 건너뜀)
-- ============================================================

-- ------------------------------------------------------------
-- 1. 마스터 TPRMPP_CBLBMM — 컬럼 RENAME / 구컬럼 폐기
-- ------------------------------------------------------------
DECLARE
    has_tp NUMBER;
    has_tc NUMBER;
BEGIN
    SELECT COUNT(*) INTO has_tp FROM user_tab_columns
     WHERE table_name = 'TPRMPP_CBLBMM' AND column_name = 'BLB_TP';
    SELECT COUNT(*) INTO has_tc FROM user_tab_columns
     WHERE table_name = 'TPRMPP_CBLBMM' AND column_name = 'BLB_TC';

    IF has_tp = 1 AND has_tc = 0 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE TPRMPP_CBLBMM RENAME COLUMN BLB_TP TO BLB_TC';
    ELSIF has_tp = 1 AND has_tc = 1 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE TPRMPP_CBLBMM DROP COLUMN BLB_TP';
    END IF;
END;
/

-- 값 변환 (구 'BLB_TP_NNN' → 마지막 3자리 'NNN'). 이미 3자리면 미변경.
UPDATE TPRMPP_CBLBMM
   SET BLB_TC = SUBSTR(BLB_TC, -3)
 WHERE LENGTH(BLB_TC) > 3;

-- 타입 축소 VARCHAR2(3) (기존 NOT NULL 유지)
DECLARE
    cur_len NUMBER;
BEGIN
    SELECT char_length INTO cur_len FROM user_tab_columns
     WHERE table_name = 'TPRMPP_CBLBMM' AND column_name = 'BLB_TC';
    IF cur_len <> 3 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE TPRMPP_CBLBMM MODIFY (BLB_TC VARCHAR2(3))';
    END IF;
END;
/

-- ------------------------------------------------------------
-- 2. 변경로그 TPRMPP_CBLBML (로그 컬럼은 nullable 유지)
-- ------------------------------------------------------------
DECLARE
    has_tp NUMBER;
    has_tc NUMBER;
BEGIN
    SELECT COUNT(*) INTO has_tp FROM user_tab_columns
     WHERE table_name = 'TPRMPP_CBLBML' AND column_name = 'BLB_TP';
    SELECT COUNT(*) INTO has_tc FROM user_tab_columns
     WHERE table_name = 'TPRMPP_CBLBML' AND column_name = 'BLB_TC';

    IF has_tp = 1 AND has_tc = 0 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE TPRMPP_CBLBML RENAME COLUMN BLB_TP TO BLB_TC';
    ELSIF has_tp = 1 AND has_tc = 1 THEN
        -- 둘 다 존재: 구 BLB_TP 값을 신규 BLB_TC로 이관(미설정 행만) 후 폐기
        EXECUTE IMMEDIATE 'UPDATE TPRMPP_CBLBML SET BLB_TC = SUBSTR(BLB_TP, -3) WHERE BLB_TC IS NULL AND BLB_TP IS NOT NULL';
        EXECUTE IMMEDIATE 'ALTER TABLE TPRMPP_CBLBML DROP COLUMN BLB_TP';
    END IF;
END;
/

UPDATE TPRMPP_CBLBML
   SET BLB_TC = SUBSTR(BLB_TC, -3)
 WHERE BLB_TC IS NOT NULL AND LENGTH(BLB_TC) > 3;

DECLARE
    cur_len NUMBER;
BEGIN
    SELECT char_length INTO cur_len FROM user_tab_columns
     WHERE table_name = 'TPRMPP_CBLBML' AND column_name = 'BLB_TC';
    IF cur_len <> 3 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE TPRMPP_CBLBML MODIFY (BLB_TC VARCHAR2(3))';
    END IF;
END;
/

-- ------------------------------------------------------------
-- 3. 주석 (한글 — PL/SQL 밖 최상위 문장)
-- ------------------------------------------------------------
COMMENT ON COLUMN TPRMPP_CBLBMM.BLB_TC IS '게시판구분코드';
COMMENT ON COLUMN TPRMPP_CBLBML.BLB_TC IS '게시판구분코드';

COMMIT;
