-- ============================================================
-- 정보화실무협의회 테이블 변경 DDL (ALTER)
-- Date    : 2026-04-02
-- Changes :
--   1. BREVWM → BPOVWM : 테이블명 변경 (사업개요 의미 명확화)
-- ============================================================

-- 기존 FK 제약조건 먼저 제거
ALTER TABLE TAAABB_BREVWM DROP CONSTRAINT FK_BPOVWM_ASCT;

-- 테이블명 변경
ALTER TABLE TAAABB_BREVWM RENAME TO TAAABB_BPOVWM;

-- PK 이름 변경 (Oracle은 PK명 직접 RENAME 불가 → drop & add)
ALTER TABLE TAAABB_BPOVWM DROP CONSTRAINT PK_BPOVWM;
ALTER TABLE TAAABB_BPOVWM ADD CONSTRAINT PK_BPOVWM PRIMARY KEY (ASCT_ID);

-- FK 재생성
ALTER TABLE TAAABB_BPOVWM ADD CONSTRAINT FK_BPOVWM_ASCT
    FOREIGN KEY (ASCT_ID) REFERENCES TAAABB_BASCTM(ASCT_ID);

COMMIT;
