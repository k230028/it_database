-- =============================================================================
-- V20260528_004__RefactorCapplaColumns.sql
-- TPRMPP_CAPPLA 컬럼 리팩터링
--   복합 PK (APF_REL_SNO + APF_MNG_NO) → 단일 PK (APF_SNO)
--   APF_MNG_NO(32)  → APF_DCM_NO(64)
--   ORC_TB_CD(10)   → FNT_TB_NM(120)
--   ORC_PK_VL(32)   → PK_COL_NM(32)
--   ORC_SNO_VL(4)   → FNT_TB_CRY_SNO(4)
--   GUID_PRG_SNO    신규 추가
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1단계: 기존 인덱스 / PK 제약 삭제
-- -----------------------------------------------------------------------------
DECLARE
  v_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_count FROM USER_INDEXES
   WHERE INDEX_NAME = 'IDX_TPRMPP_CAPPLA_APF_MNG_NO_ORC_TB_CD';
  IF v_count > 0 THEN
    EXECUTE IMMEDIATE 'DROP INDEX IDX_TPRMPP_CAPPLA_APF_MNG_NO_ORC_TB_CD';
  END IF;
END;
/

DECLARE
  v_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_count FROM USER_CONSTRAINTS
   WHERE TABLE_NAME = 'TPRMPP_CAPPLA' AND CONSTRAINT_NAME = 'PK_CAPPLA';
  IF v_count > 0 THEN
    EXECUTE IMMEDIATE 'ALTER TABLE TPRMPP_CAPPLA DROP CONSTRAINT PK_CAPPLA';
  END IF;
END;
/

-- -----------------------------------------------------------------------------
-- 2단계: APF_SNO 신규 컬럼 추가 및 채번 시퀀스 생성
-- -----------------------------------------------------------------------------
DECLARE
  v_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_count FROM USER_TAB_COLUMNS
   WHERE TABLE_NAME = 'TPRMPP_CAPPLA' AND COLUMN_NAME = 'APF_SNO';
  IF v_count = 0 THEN
    EXECUTE IMMEDIATE 'ALTER TABLE TPRMPP_CAPPLA ADD APF_SNO NUMBER(9,0)';
  END IF;
END;
/

DECLARE
  v_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_count FROM USER_SEQUENCES WHERE SEQUENCE_NAME = 'SEQ_CAPPLA';
  IF v_count = 0 THEN
    EXECUTE IMMEDIATE 'CREATE SEQUENCE SEQ_CAPPLA START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE';
  END IF;
END;
/

-- 기존 데이터 APF_SNO 백필
UPDATE TPRMPP_CAPPLA SET APF_SNO = SEQ_CAPPLA.NEXTVAL WHERE APF_SNO IS NULL;
COMMIT;

-- -----------------------------------------------------------------------------
-- 3단계: APF_MNG_NO → APF_DCM_NO (타입 VARCHAR2(32) → VARCHAR2(64))
-- -----------------------------------------------------------------------------
DECLARE
  v_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_count FROM USER_TAB_COLUMNS
   WHERE TABLE_NAME = 'TPRMPP_CAPPLA' AND COLUMN_NAME = 'APF_MNG_NO';
  IF v_count > 0 THEN
    -- 임시 컬럼으로 타입 확장 후 이름 변경
    EXECUTE IMMEDIATE 'ALTER TABLE TPRMPP_CAPPLA ADD APF_DCM_NO_TMP VARCHAR2(64)';
    EXECUTE IMMEDIATE 'UPDATE TPRMPP_CAPPLA SET APF_DCM_NO_TMP = APF_MNG_NO';
    EXECUTE IMMEDIATE 'ALTER TABLE TPRMPP_CAPPLA DROP COLUMN APF_MNG_NO';
    EXECUTE IMMEDIATE 'ALTER TABLE TPRMPP_CAPPLA RENAME COLUMN APF_DCM_NO_TMP TO APF_DCM_NO';
  ELSE
    -- 이미 APF_DCM_NO 인 경우 길이만 보장
    EXECUTE IMMEDIATE 'ALTER TABLE TPRMPP_CAPPLA MODIFY APF_DCM_NO VARCHAR2(64)';
  END IF;
END;
/
COMMIT;

-- -----------------------------------------------------------------------------
-- 4단계: ORC_TB_CD → FNT_TB_NM (타입 VARCHAR2(10) → VARCHAR2(120))
-- -----------------------------------------------------------------------------
DECLARE
  v_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_count FROM USER_TAB_COLUMNS
   WHERE TABLE_NAME = 'TPRMPP_CAPPLA' AND COLUMN_NAME = 'ORC_TB_CD';
  IF v_count > 0 THEN
    EXECUTE IMMEDIATE 'ALTER TABLE TPRMPP_CAPPLA ADD FNT_TB_NM_TMP VARCHAR2(120)';
    EXECUTE IMMEDIATE 'UPDATE TPRMPP_CAPPLA SET FNT_TB_NM_TMP = ORC_TB_CD';
    EXECUTE IMMEDIATE 'ALTER TABLE TPRMPP_CAPPLA DROP COLUMN ORC_TB_CD';
    EXECUTE IMMEDIATE 'ALTER TABLE TPRMPP_CAPPLA RENAME COLUMN FNT_TB_NM_TMP TO FNT_TB_NM';
  ELSE
    EXECUTE IMMEDIATE 'ALTER TABLE TPRMPP_CAPPLA MODIFY FNT_TB_NM VARCHAR2(120)';
  END IF;
END;
/
COMMIT;

-- -----------------------------------------------------------------------------
-- 5단계: ORC_PK_VL → PK_COL_NM (동일 타입 VARCHAR2(32))
-- -----------------------------------------------------------------------------
DECLARE
  v_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_count FROM USER_TAB_COLUMNS
   WHERE TABLE_NAME = 'TPRMPP_CAPPLA' AND COLUMN_NAME = 'ORC_PK_VL';
  IF v_count > 0 THEN
    EXECUTE IMMEDIATE 'ALTER TABLE TPRMPP_CAPPLA RENAME COLUMN ORC_PK_VL TO PK_COL_NM';
  END IF;
END;
/

-- -----------------------------------------------------------------------------
-- 6단계: ORC_SNO_VL → FNT_TB_CRY_SNO (동일 타입 NUMBER(4,0))
-- -----------------------------------------------------------------------------
DECLARE
  v_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_count FROM USER_TAB_COLUMNS
   WHERE TABLE_NAME = 'TPRMPP_CAPPLA' AND COLUMN_NAME = 'ORC_SNO_VL';
  IF v_count > 0 THEN
    EXECUTE IMMEDIATE 'ALTER TABLE TPRMPP_CAPPLA RENAME COLUMN ORC_SNO_VL TO FNT_TB_CRY_SNO';
  END IF;
END;
/

-- -----------------------------------------------------------------------------
-- 7단계: APF_REL_SNO 컬럼 삭제
-- -----------------------------------------------------------------------------
DECLARE
  v_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_count FROM USER_TAB_COLUMNS
   WHERE TABLE_NAME = 'TPRMPP_CAPPLA' AND COLUMN_NAME = 'APF_REL_SNO';
  IF v_count > 0 THEN
    EXECUTE IMMEDIATE 'ALTER TABLE TPRMPP_CAPPLA DROP COLUMN APF_REL_SNO';
  END IF;
END;
/

-- -----------------------------------------------------------------------------
-- 8단계: GUID_PRG_SNO 신규 컬럼 추가
-- -----------------------------------------------------------------------------
DECLARE
  v_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_count FROM USER_TAB_COLUMNS
   WHERE TABLE_NAME = 'TPRMPP_CAPPLA' AND COLUMN_NAME = 'GUID_PRG_SNO';
  IF v_count = 0 THEN
    EXECUTE IMMEDIATE 'ALTER TABLE TPRMPP_CAPPLA ADD GUID_PRG_SNO NUMBER(4,0)';
  END IF;
END;
/

-- -----------------------------------------------------------------------------
-- 9단계: NOT NULL 제약 및 단일 PK 재생성
-- -----------------------------------------------------------------------------
ALTER TABLE TPRMPP_CAPPLA MODIFY APF_SNO NUMBER(9,0) NOT NULL;
ALTER TABLE TPRMPP_CAPPLA MODIFY APF_DCM_NO VARCHAR2(64) NOT NULL;

ALTER TABLE TPRMPP_CAPPLA ADD CONSTRAINT PK_CAPPLA PRIMARY KEY (APF_SNO);

-- -----------------------------------------------------------------------------
-- 10단계: APF_DCM_NO 기준 인덱스 생성
-- -----------------------------------------------------------------------------
DECLARE
  v_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_count FROM USER_INDEXES
   WHERE INDEX_NAME = 'IDX_CAPPLA_APF_DCM_NO';
  IF v_count = 0 THEN
    EXECUTE IMMEDIATE 'CREATE INDEX IDX_CAPPLA_APF_DCM_NO ON TPRMPP_CAPPLA (APF_DCM_NO)';
  END IF;
END;
/
