-- ============================================================
-- V20260512_001: TAAABB_CCODEM_V2 신규 스키마 생성
-- 공통코드 체계 개선 — PK = (C_ID, CDVA, STT_DT) 3-컬럼 복합키
-- ============================================================

CREATE TABLE TAAABB_CCODEM_V2 (
    C_ID        VARCHAR2(32)  NOT NULL,
    CDVA        VARCHAR2(32)  NOT NULL,
    STT_DT      DATE          NOT NULL,
    END_DT      DATE,
    C_NM        VARCHAR2(100),
    C_DES       VARCHAR2(500),
    CDVA_DTL    VARCHAR2(100),
    C_TP        VARCHAR2(100),
    C_TP_DES    VARCHAR2(500),
    HRK_C       VARCHAR2(65),
    C_SQN       NUMBER,
    DEL_YN      VARCHAR2(1)   DEFAULT 'N' NOT NULL,
    GUID        VARCHAR2(36),
    GUID_PRG_SNO NUMBER,
    FST_ENR_DTM TIMESTAMP,
    FST_ENR_USID VARCHAR2(20),
    LST_CHG_DTM TIMESTAMP,
    LST_CHG_USID VARCHAR2(20),
    CONSTRAINT PK_CCODEM_V2 PRIMARY KEY (C_ID, CDVA, STT_DT)
);

COMMENT ON TABLE  TAAABB_CCODEM_V2              IS '공통코드마스터 V2';
COMMENT ON COLUMN TAAABB_CCODEM_V2.C_ID         IS '코드ID (prefix만, _ 통일, 예: CUR, PRJ_TP)';
COMMENT ON COLUMN TAAABB_CCODEM_V2.CDVA         IS '코드값 (예: 001, STA, END)';
COMMENT ON COLUMN TAAABB_CCODEM_V2.STT_DT       IS '시작일자 (시점 버전 PK)';
COMMENT ON COLUMN TAAABB_CCODEM_V2.END_DT       IS '종료일자';
COMMENT ON COLUMN TAAABB_CCODEM_V2.C_NM         IS '코드명 (구 CDVA, 예: 1400, 신규개발)';
COMMENT ON COLUMN TAAABB_CCODEM_V2.C_DES        IS '코드설명 (구 CTT_TP_DES, 예: 환율, 사업유형)';
COMMENT ON COLUMN TAAABB_CCODEM_V2.CDVA_DTL     IS '코드값상세 (구 C_NM, 예: USD)';
COMMENT ON COLUMN TAAABB_CCODEM_V2.C_TP         IS '코드타입 (구 CTT_TP rename)';
COMMENT ON COLUMN TAAABB_CCODEM_V2.C_TP_DES     IS '코드타입설명 (구 CTT_TP_DES rename)';
COMMENT ON COLUMN TAAABB_CCODEM_V2.HRK_C        IS '상위코드 — {C_ID}_{CDVA} 합성 문자열';
COMMENT ON COLUMN TAAABB_CCODEM_V2.C_SQN        IS '코드순서';
COMMENT ON COLUMN TAAABB_CCODEM_V2.DEL_YN       IS '삭제여부 (N:정상, Y:삭제)';

-- 보조 인덱스: 카테고리 다건 조회용
CREATE INDEX IDX_CCODEM_V2_CID_VALID
    ON TAAABB_CCODEM_V2 (C_ID, DEL_YN, STT_DT, END_DT);
