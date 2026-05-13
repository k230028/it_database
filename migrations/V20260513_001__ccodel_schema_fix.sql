-- ============================================================
-- V20260513_001: TAAABB_CCODEL BaseLogEntity V2 현행화
--
-- 배경:
--   V20260512_002에서 TAAABB_CCODEL_V2를 생성할 때 LOG_SNO=NUMBER,
--   CHG_TP=VARCHAR2(10), CHG_DTM 컬럼 없이 생성됨.
--   이후 BaseLogEntity가 String PK + CHG_TP(1) + CHG_DTM(not null)로
--   정의되어 Hibernate ddl-auto=update가 세 컬럼 변경에 실패.
--
-- 변경 내역:
--   1. LOG_SNO  : NUMBER → VARCHAR2(32 CHAR), CCODEL-{22자리} 형식으로 데이터 변환
--   2. CHG_TP   : VARCHAR2(10) → VARCHAR2(1 CHAR), INSERT→C / UPDATE→U / DELETE→D
--   3. CHG_DTM  : 신규 컬럼 추가 (NOT NULL, 기존 행은 FST_ENR_DTM으로 채움)
--   4. C_DES    : CDVA_DES로 rename (엔티티 컬럼명 현행화)
--   5. S_CCODEL : AuditLogIdGenerator 전용 시퀀스 생성
-- ============================================================

-- ============================================================
-- STEP 1: LOG_SNO — NUMBER → VARCHAR2(32 CHAR)
-- ============================================================

-- 1-1. 임시 컬럼 추가
ALTER TABLE TAAABB_CCODEL ADD LOG_SNO_TMP VARCHAR2(32 CHAR);

-- 1-2. 기존 숫자값 → 'CCODEL-{22자리}' 형식으로 변환
UPDATE TAAABB_CCODEL
   SET LOG_SNO_TMP = 'CCODEL-' || LPAD(TO_CHAR(LOG_SNO), 22, '0');

-- 1-3. PK 제약 제거
ALTER TABLE TAAABB_CCODEL DROP CONSTRAINT PK_CCODEL_V2;

-- 1-4. 기존 NUMBER 컬럼 삭제
ALTER TABLE TAAABB_CCODEL DROP COLUMN LOG_SNO;

-- 1-5. 임시 컬럼을 LOG_SNO로 rename 후 NOT NULL + PK 재설정
ALTER TABLE TAAABB_CCODEL RENAME COLUMN LOG_SNO_TMP TO LOG_SNO;
ALTER TABLE TAAABB_CCODEL MODIFY LOG_SNO VARCHAR2(32 CHAR) NOT NULL;
ALTER TABLE TAAABB_CCODEL ADD CONSTRAINT PK_CCODEL PRIMARY KEY (LOG_SNO);

-- ============================================================
-- STEP 2: CHG_TP — VARCHAR2(10) 값 정규화 후 VARCHAR2(1 CHAR)로 축소
-- ============================================================

-- 2-1. 기존 영문 변경유형 → 단일 코드로 변환
UPDATE TAAABB_CCODEL
   SET CHG_TP = CASE TRIM(CHG_TP)
       WHEN 'INSERT'    THEN 'C'
       WHEN 'UPDATE'    THEN 'U'
       WHEN 'DELETE'    THEN 'D'
       WHEN 'MIGRATION' THEN 'C'
       ELSE SUBSTR(TRIM(CHG_TP), 1, 1)
   END
 WHERE CHG_TP IS NOT NULL;

-- 2-2. 컬럼 타입 축소 및 NOT NULL 설정
ALTER TABLE TAAABB_CCODEL MODIFY CHG_TP VARCHAR2(1 CHAR) NOT NULL;

-- ============================================================
-- STEP 3: CHG_DTM — 신규 컬럼 추가 (데이터 있는 테이블이므로 단계적 처리)
-- ============================================================

-- 3-1. NULL 허용으로 컬럼 추가
ALTER TABLE TAAABB_CCODEL ADD CHG_DTM TIMESTAMP(9);

-- 3-2. 기존 행에 변경일시 채우기 (FST_ENR_DTM 우선, 없으면 현재 시각)
UPDATE TAAABB_CCODEL
   SET CHG_DTM = NVL(FST_ENR_DTM, SYSTIMESTAMP)
 WHERE CHG_DTM IS NULL;

-- 3-3. NOT NULL 제약 추가
ALTER TABLE TAAABB_CCODEL MODIFY CHG_DTM TIMESTAMP(9) NOT NULL;

-- ============================================================
-- STEP 4: C_DES → CDVA_DES rename
--         (V2 스키마에서 컬럼명이 엔티티와 달랐던 것 수정)
--         CDVA_DES가 이미 존재하면 skip (Hibernate가 먼저 ADD했을 경우)
-- ============================================================
DECLARE
    v_cdva_des NUMBER;
    v_c_des    NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_cdva_des
      FROM USER_TAB_COLUMNS
     WHERE TABLE_NAME = 'TAAABB_CCODEL' AND COLUMN_NAME = 'CDVA_DES';

    SELECT COUNT(*) INTO v_c_des
      FROM USER_TAB_COLUMNS
     WHERE TABLE_NAME = 'TAAABB_CCODEL' AND COLUMN_NAME = 'C_DES';

    -- CDVA_DES 없고 C_DES 있을 때만 rename
    IF v_cdva_des = 0 AND v_c_des = 1 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE TAAABB_CCODEL RENAME COLUMN C_DES TO CDVA_DES';
    -- CDVA_DES와 C_DES 모두 있으면: C_DES에 있는 데이터를 CDVA_DES로 복사 후 C_DES 삭제
    ELSIF v_cdva_des = 1 AND v_c_des = 1 THEN
        EXECUTE IMMEDIATE 'UPDATE TAAABB_CCODEL SET CDVA_DES = NVL(CDVA_DES, C_DES) WHERE C_DES IS NOT NULL';
        EXECUTE IMMEDIATE 'ALTER TABLE TAAABB_CCODEL DROP COLUMN C_DES';
    END IF;
END;
/

-- ============================================================
-- STEP 5: S_CCODEL 시퀀스 생성
--         AuditLogIdGenerator가 S_{POSTFIX} 규칙으로 NEXTVAL 조회
--         기존 행의 최대 순번 + 100 이후부터 시작
-- ============================================================
DECLARE
    v_start NUMBER;
    v_cnt   NUMBER;
BEGIN
    -- S_CCODEL이 이미 존재하면 skip
    SELECT COUNT(*) INTO v_cnt
      FROM USER_SEQUENCES
     WHERE SEQUENCE_NAME = 'S_CCODEL';

    IF v_cnt = 0 THEN
        -- 기존 LOG_SNO에서 숫자 부분 최대값 추출 후 +100 마진
        BEGIN
            SELECT NVL(MAX(TO_NUMBER(REGEXP_SUBSTR(LOG_SNO, '[0-9]+$'))), 0) + 100
              INTO v_start
              FROM TAAABB_CCODEL;
        EXCEPTION
            WHEN OTHERS THEN v_start := 1;
        END;

        EXECUTE IMMEDIATE
            'CREATE SEQUENCE S_CCODEL START WITH ' || v_start ||
            ' INCREMENT BY 1 MAXVALUE 9999999999999999999999 CYCLE NOCACHE';
    END IF;
END;
/

COMMIT;
