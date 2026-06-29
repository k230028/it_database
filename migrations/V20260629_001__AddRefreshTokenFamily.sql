-- V20260629_001__AddRefreshTokenFamily.sql
-- Refresh Token 재사용 탐지(T10)용 컬럼 추가: FAM_NM(가족명=토큰패밀리, 로그인 1회), AVL_YN(유효여부; N=회전된 구토큰).
-- 가산형(추가만)·멱등: 동일 컬럼 존재 시 건너뜀.
DECLARE
    FUNCTION col_exists(p_tab VARCHAR2, p_col VARCHAR2) RETURN BOOLEAN IS
        n NUMBER;
    BEGIN
        SELECT COUNT(*) INTO n FROM ALL_TAB_COLUMNS
         WHERE OWNER = SYS_CONTEXT('USERENV','CURRENT_SCHEMA')
           AND TABLE_NAME = p_tab AND COLUMN_NAME = p_col;
        RETURN n > 0;
    END;
BEGIN
    IF NOT col_exists('TPRMPP_CRTOKM', 'FAM_NM') THEN
        EXECUTE IMMEDIATE 'ALTER TABLE TPRMPP_CRTOKM ADD (FAM_NM VARCHAR2(100 CHAR) DEFAULT ''LEGACY'' NOT NULL)';
        EXECUTE IMMEDIATE 'COMMENT ON COLUMN TPRMPP_CRTOKM.FAM_NM IS ''가족명(토큰패밀리=로그인 1회, 재사용 탐지용)''';
    END IF;
    IF NOT col_exists('TPRMPP_CRTOKM', 'AVL_YN') THEN
        EXECUTE IMMEDIATE 'ALTER TABLE TPRMPP_CRTOKM ADD (AVL_YN VARCHAR2(1 CHAR) DEFAULT ''Y'' NOT NULL)';
        EXECUTE IMMEDIATE 'COMMENT ON COLUMN TPRMPP_CRTOKM.AVL_YN IS ''유효여부(Y=활성 토큰, N=회전된 구토큰 → 재제출 시 재사용 탐지)''';
    END IF;
END;
/
