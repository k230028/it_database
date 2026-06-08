-- V20260608_005__AddSysHrkMnuIdToCmenum.sql
-- 공통메뉴기본(CMENUM)·로그(CMENUL)에 시스템상위메뉴ID(SYS_HRK_MNU_ID) 컬럼 추가 + 백필
--
-- 배경:
--  - 메타DB(table.csv)에는 CMENUM/CMENUL 모두 SYS_HRK_MNU_ID(시스템상위메뉴ID)가
--    등재되어 있으나 실제 DB/엔티티에는 없어 스키마 불일치 상태였다.
--  - SYS_HRK_MNU_ID 는 해당 메뉴가 속한 트리 최상위(루트, HED) 조상의 MNU_ID 를 저장한다.
--    루트 노드(MNU_DEP=1) 자기 자신은 상위가 없으므로 NULL 로 둔다.
--  - 값은 WHL_MNU_PTH(예: /MHED0001/MDOC0002/MDOC0003)의 첫 세그먼트와 동일하다.
--
-- 적용 순서: 본 스크립트를 먼저 적용해야 한다. 백엔드는 ddl-auto=validate 이므로
--           엔티티에 SYS_HRK_MNU_ID 필드를 추가하기 전 DB 컬럼이 존재해야 기동 검증을 통과한다.
--
-- 멱등성: 컬럼 존재 여부를 user_tab_columns 로 확인 후 추가하므로 재실행 안전.
--         백필 UPDATE 역시 동일 결과를 재산출하므로 재실행 안전.

-- 1) 컬럼 추가 (멱등)
DECLARE
    v_cnt NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_cnt FROM user_tab_columns
     WHERE table_name = 'TPRMPP_CMENUM' AND column_name = 'SYS_HRK_MNU_ID';
    IF v_cnt = 0 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE ITPAPP.TPRMPP_CMENUM ADD (SYS_HRK_MNU_ID VARCHAR2(10 CHAR))';
    END IF;

    SELECT COUNT(*) INTO v_cnt FROM user_tab_columns
     WHERE table_name = 'TPRMPP_CMENUL' AND column_name = 'SYS_HRK_MNU_ID';
    IF v_cnt = 0 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE ITPAPP.TPRMPP_CMENUL ADD (SYS_HRK_MNU_ID VARCHAR2(10 CHAR))';
    END IF;
END;
/

-- 2) 컬럼 코멘트
COMMENT ON COLUMN ITPAPP.TPRMPP_CMENUM.SYS_HRK_MNU_ID IS '시스템상위메뉴ID';
COMMENT ON COLUMN ITPAPP.TPRMPP_CMENUL.SYS_HRK_MNU_ID IS '시스템상위메뉴ID';

-- 3) 기존 데이터 백필 (루트 제외, WHL_MNU_PTH 첫 세그먼트 = 최상위 메뉴 ID)
UPDATE ITPAPP.TPRMPP_CMENUM
   SET SYS_HRK_MNU_ID = REGEXP_SUBSTR(WHL_MNU_PTH, '[^/]+', 1, 1)
 WHERE MNU_DEP > 1
   AND WHL_MNU_PTH IS NOT NULL;

UPDATE ITPAPP.TPRMPP_CMENUL
   SET SYS_HRK_MNU_ID = REGEXP_SUBSTR(WHL_MNU_PTH, '[^/]+', 1, 1)
 WHERE MNU_DEP > 1
   AND WHL_MNU_PTH IS NOT NULL;

COMMIT;
