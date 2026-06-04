-- 정보기술부문계획 관계 테이블/컬럼 리네임 (구조 정합)
--   * 테이블 : TPRMPP_BPROJA → TPRMPP_BPLANA (정보기술부문계획 관계)
--   * 컬럼   : DOC_MNG_NO → REQ_DOC_NO (요청문서번호, 메타사전 표준용어)
--   * PK제약 : 실제 PK 제약명(시스템 생성명 포함) → PK_TPRMPP_BPLANA
-- 복합키 첫 번째 키 ABUS_MNG_NO(프로젝트관리번호)는 변경하지 않습니다.
-- REQ_DOC_NO 길이는 기존 컬럼 길이(VARCHAR2(32))를 유지합니다(RENAME은 길이 미변경, 데이터 보존).
-- 멱등성: 변경 전 상태일 때만 각 단계를 수행 (재실행 안전, 부분 적용 상태도 복구).

DECLARE
    v_cnt NUMBER;
    v_pk  VARCHAR2(128);
    v_tbl VARCHAR2(128);
BEGIN
    -- 1) 컬럼 리네임: DOC_MNG_NO → REQ_DOC_NO
    --    구(TPRMPP_BPROJA)/신(TPRMPP_BPLANA) 어느 테이블이 보유하든 처리.
    FOR t IN (SELECT table_name FROM user_tables
               WHERE table_name IN ('TPRMPP_BPROJA', 'TPRMPP_BPLANA')) LOOP
        SELECT COUNT(*) INTO v_cnt
          FROM user_tab_cols
         WHERE table_name = t.table_name AND column_name = 'DOC_MNG_NO';
        IF v_cnt > 0 THEN
            SELECT COUNT(*) INTO v_cnt
              FROM user_tab_cols
             WHERE table_name = t.table_name AND column_name = 'REQ_DOC_NO';
            IF v_cnt = 0 THEN
                EXECUTE IMMEDIATE 'ALTER TABLE ' || t.table_name
                                  || ' RENAME COLUMN DOC_MNG_NO TO REQ_DOC_NO';
            END IF;
        END IF;
    END LOOP;

    -- 2) PK 제약 리네임 → PK_TPRMPP_BPLANA
    --    실제 PK 제약명(시스템 생성명 SYS_Cxxxx 포함)을 조회하여 표준명으로 통일.
    BEGIN
        SELECT constraint_name, table_name INTO v_pk, v_tbl
          FROM user_constraints
         WHERE table_name IN ('TPRMPP_BPROJA', 'TPRMPP_BPLANA')
           AND constraint_type = 'P';
        IF v_pk <> 'PK_TPRMPP_BPLANA' THEN
            EXECUTE IMMEDIATE 'ALTER TABLE ' || v_tbl
                              || ' RENAME CONSTRAINT ' || v_pk || ' TO PK_TPRMPP_BPLANA';
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN NULL;  -- PK 없음(예상 밖) → 건너뜀
    END;

    -- 3) 테이블 리네임: TPRMPP_BPROJA → TPRMPP_BPLANA
    SELECT COUNT(*) INTO v_cnt FROM user_tables WHERE table_name = 'TPRMPP_BPROJA';
    IF v_cnt > 0 THEN
        SELECT COUNT(*) INTO v_cnt FROM user_tables WHERE table_name = 'TPRMPP_BPLANA';
        IF v_cnt = 0 THEN
            EXECUTE IMMEDIATE 'ALTER TABLE TPRMPP_BPROJA RENAME TO TPRMPP_BPLANA';
        END IF;
    END IF;
END;
/
