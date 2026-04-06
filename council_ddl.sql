-- ============================================================
-- 정보화실무협의회 테이블 DDL
-- Feature  : council
-- Schema   : ITPAPP
-- Created  : 2026-04-02
-- Design   : docs/02-design/features/council.design.md § 6
-- ============================================================

-- 1. 협의회 기본정보 (부모 테이블 - 먼저 생성)
CREATE TABLE TAAABB_BASCTM (
    ASCT_ID        VARCHAR2(32)   NOT NULL,   -- 협의회ID (ASCT-{연도}-{4자리})
    PRJ_MNG_NO     VARCHAR2(32),              -- 프로젝트관리번호 (FK → TAAABB_BPROJM)
    PRJ_SNO        NUMBER(10),                -- 프로젝트순번 (FK → TAAABB_BPROJM)
    ASCT_STS       VARCHAR2(20)   NOT NULL,   -- 협의회상태 (CouncilStatus Enum)
    DBR_TP         VARCHAR2(20),              -- 심의유형 (INFO_SYS/INFO_SEC/ETC)
    CNRC_DT        DATE,                      -- 회의일자
    CNRC_TM        VARCHAR2(10),              -- 회의시간 (10:00/14:00/15:00/16:00)
    CNRC_PLC       VARCHAR2(200),             -- 회의장소
    DEL_YN         VARCHAR2(1)    DEFAULT 'N' NOT NULL,
    GUID           VARCHAR2(38),
    GUID_PRG_SNO   NUMBER(10)     DEFAULT 1,
    FST_ENR_DTM    TIMESTAMP,
    FST_ENR_USID   VARCHAR2(14),
    LST_CHG_DTM    TIMESTAMP,
    LST_CHG_USID   VARCHAR2(14),
    CONSTRAINT PK_BASCTM PRIMARY KEY (ASCT_ID)
);

-- 2. 타당성검토표 (1:1 with BASCTM)
CREATE TABLE TAAABB_BPOVWM (
    ASCT_ID        VARCHAR2(32)   NOT NULL,   -- 협의회ID (FK → BASCTM, 1:1)
    PRJ_NM         VARCHAR2(200),             -- 사업명 (수정 가능)
    PRJ_TRM        VARCHAR2(100),             -- 사업기간
    NCS_MTA        VARCHAR2(2000),            -- 필요성
    SRP_BDT        VARCHAR2(100),             -- 소요예산
    DCSPE          VARCHAR2(200),             -- 결정자(전결권자)
    PRJ_CONE       VARCHAR2(4000),            -- 사업내용
    LGL_RGL_YN     VARCHAR2(1)    DEFAULT 'N',-- 법률규제대응여부 (Y/N)
    LGL_RGL_NM     VARCHAR2(500),             -- 관련법률규제명
    XPT_EFF        VARCHAR2(2000),            -- 기대효과
    KPN_TP         VARCHAR2(10)   DEFAULT 'TEMP', -- 저장유형 (TEMP/COMPLETE)
    FL_MNG_NO      VARCHAR2(32),              -- 첨부파일관리번호 (FK → TAAABB_CFILEM)
    DEL_YN         VARCHAR2(1)    DEFAULT 'N' NOT NULL,
    GUID           VARCHAR2(38),
    GUID_PRG_SNO   NUMBER(10)     DEFAULT 1,
    FST_ENR_DTM    TIMESTAMP,
    FST_ENR_USID   VARCHAR2(14),
    LST_CHG_DTM    TIMESTAMP,
    LST_CHG_USID   VARCHAR2(14),
    CONSTRAINT PK_BPOVWM PRIMARY KEY (ASCT_ID),
    CONSTRAINT FK_BPOVWM_ASCT FOREIGN KEY (ASCT_ID) REFERENCES TAAABB_BASCTM(ASCT_ID)
);

-- 3. 타당성 자체점검 (1:N, 6개 고정항목)
CREATE TABLE TAAABB_BCHKLC (
    ASCT_ID        VARCHAR2(32)   NOT NULL,   -- 협의회ID (FK → BASCTM)
    CKG_ITM_C      VARCHAR2(20)   NOT NULL,   -- 점검항목코드 (MGMT_STR/FIN_EFC/RISK_IMP/REP_IMP/DUP_SYS/ETC)
    CKG_CONE       VARCHAR2(2000),            -- 점검내용
    CKG_RCRD       NUMBER(1),                 -- 점검점수 (1~5)
    DEL_YN         VARCHAR2(1)    DEFAULT 'N' NOT NULL,
    GUID           VARCHAR2(38),
    GUID_PRG_SNO   NUMBER(10)     DEFAULT 1,
    FST_ENR_DTM    TIMESTAMP,
    FST_ENR_USID   VARCHAR2(14),
    LST_CHG_DTM    TIMESTAMP,
    LST_CHG_USID   VARCHAR2(14),
    CONSTRAINT PK_BCHKLC PRIMARY KEY (ASCT_ID, CKG_ITM_C)
);

-- 4. 성과지표 (1:N)
CREATE TABLE TAAABB_BPERFM (
    ASCT_ID        VARCHAR2(32)   NOT NULL,   -- 협의회ID (FK → BASCTM)
    DTP_SNO        NUMBER(10)     NOT NULL,   -- 지표순번 (1부터 시작)
    DTP_NM         VARCHAR2(200),             -- 지표명
    DTP_CONE       VARCHAR2(1000),            -- 지표정의
    MSM_MANR       VARCHAR2(1000),            -- 측정방법/산식/목표치
    MSM_STT_DT     DATE,                      -- 측정시작일
    MSM_END_DT     DATE,                      -- 측정종료일
    MSM_CYC        VARCHAR2(100),             -- 측정주기 (매년말 등)
    DEL_YN         VARCHAR2(1)    DEFAULT 'N' NOT NULL,
    GUID           VARCHAR2(38),
    GUID_PRG_SNO   NUMBER(10)     DEFAULT 1,
    FST_ENR_DTM    TIMESTAMP,
    FST_ENR_USID   VARCHAR2(14),
    LST_CHG_DTM    TIMESTAMP,
    LST_CHG_USID   VARCHAR2(14),
    CONSTRAINT PK_BPERFM PRIMARY KEY (ASCT_ID, DTP_SNO)
);

-- 5. 평가위원 (1:N)
CREATE TABLE TAAABB_BCMMTM (
    ASCT_ID        VARCHAR2(32)   NOT NULL,   -- 협의회ID (FK → BASCTM)
    ENO            VARCHAR2(32)   NOT NULL,   -- 사번 (FK → TAAABB_CUSERI)
    CM_TP          VARCHAR2(10)   NOT NULL,   -- 위원유형 (MAND:당연/CALL:소집/SECR:간사)
    DEL_YN         VARCHAR2(1)    DEFAULT 'N' NOT NULL,
    GUID           VARCHAR2(38),
    GUID_PRG_SNO   NUMBER(10)     DEFAULT 1,
    FST_ENR_DTM    TIMESTAMP,
    FST_ENR_USID   VARCHAR2(14),
    LST_CHG_DTM    TIMESTAMP,
    LST_CHG_USID   VARCHAR2(14),
    CONSTRAINT PK_BCMMTM PRIMARY KEY (ASCT_ID, ENO)
);

-- 6. 일정 (1:N, 복합키)
CREATE TABLE TAAABB_BSCHDM (
    ASCT_ID        VARCHAR2(32)   NOT NULL,   -- 협의회ID (FK → BASCTM)
    ENO            VARCHAR2(32)   NOT NULL,   -- 사번 (FK → TAAABB_CUSERI)
    DSD_DT         DATE           NOT NULL,   -- 일정일자
    DSD_TM         VARCHAR2(10)   NOT NULL,   -- 일정시간 (10:00/14:00/15:00/16:00)
    PSB_YN         VARCHAR2(1)    DEFAULT 'N',-- 가능여부 (Y/N)
    DEL_YN         VARCHAR2(1)    DEFAULT 'N' NOT NULL,
    GUID           VARCHAR2(38),
    GUID_PRG_SNO   NUMBER(10)     DEFAULT 1,
    FST_ENR_DTM    TIMESTAMP,
    FST_ENR_USID   VARCHAR2(14),
    LST_CHG_DTM    TIMESTAMP,
    LST_CHG_USID   VARCHAR2(14),
    CONSTRAINT PK_BSCHDM PRIMARY KEY (ASCT_ID, ENO, DSD_DT, DSD_TM)
);

-- 7. 사전질의응답 (1:N)
CREATE TABLE TAAABB_BPQNAM (
    QTN_ID         VARCHAR2(32)   NOT NULL,   -- 질의응답ID (PK)
    ASCT_ID        VARCHAR2(32)   NOT NULL,   -- 협의회ID (FK → BASCTM)
    QTN_ENO        VARCHAR2(32),              -- 질의자사번 (FK → TAAABB_CUSERI)
    QTN_CONE       VARCHAR2(4000),            -- 질의내용
    REP_ENO        VARCHAR2(32),              -- 답변자사번 (FK → TAAABB_CUSERI)
    REP_CONE       VARCHAR2(4000),            -- 답변내용
    REP_YN         VARCHAR2(1)    DEFAULT 'N',-- 답변여부 (Y/N)
    DEL_YN         VARCHAR2(1)    DEFAULT 'N' NOT NULL,
    GUID           VARCHAR2(38),
    GUID_PRG_SNO   NUMBER(10)     DEFAULT 1,
    FST_ENR_DTM    TIMESTAMP,
    FST_ENR_USID   VARCHAR2(14),
    LST_CHG_DTM    TIMESTAMP,
    LST_CHG_USID   VARCHAR2(14),
    CONSTRAINT PK_BPQNAM PRIMARY KEY (QTN_ID)
);

-- 8. 평가의견 (1:N, 복합키)
CREATE TABLE TAAABB_BEVALM (
    ASCT_ID        VARCHAR2(32)   NOT NULL,   -- 협의회ID (FK → BASCTM)
    ENO            VARCHAR2(32)   NOT NULL,   -- 사번 (FK → TAAABB_CUSERI)
    CKG_ITM_C      VARCHAR2(20)   NOT NULL,   -- 점검항목코드 (BCHKLC와 동일 코드체계)
    CKG_RCRD       NUMBER(1),                 -- 점검점수 (1~5)
    CKG_OPNN       VARCHAR2(2000),            -- 점검의견 (1~2점 시 필수)
    DEL_YN         VARCHAR2(1)    DEFAULT 'N' NOT NULL,
    GUID           VARCHAR2(38),
    GUID_PRG_SNO   NUMBER(10)     DEFAULT 1,
    FST_ENR_DTM    TIMESTAMP,
    FST_ENR_USID   VARCHAR2(14),
    LST_CHG_DTM    TIMESTAMP,
    LST_CHG_USID   VARCHAR2(14),
    CONSTRAINT PK_BEVALM PRIMARY KEY (ASCT_ID, ENO, CKG_ITM_C)
);

-- 9. 결과서 (1:1 with BASCTM)
CREATE TABLE TAAABB_BRSLTM (
    ASCT_ID        VARCHAR2(32)   NOT NULL,   -- 협의회ID (FK → BASCTM, 1:1)
    SYN_OPNN       VARCHAR2(4000),            -- 종합의견
    CKG_OPNN       VARCHAR2(4000),            -- 타당성검토의견
    FL_MNG_NO      VARCHAR2(32),              -- 관련자료 첨부파일관리번호 (FK → TAAABB_CFILEM)
    DEL_YN         VARCHAR2(1)    DEFAULT 'N' NOT NULL,
    GUID           VARCHAR2(38),
    GUID_PRG_SNO   NUMBER(10)     DEFAULT 1,
    FST_ENR_DTM    TIMESTAMP,
    FST_ENR_USID   VARCHAR2(14),
    LST_CHG_DTM    TIMESTAMP,
    LST_CHG_USID   VARCHAR2(14),
    CONSTRAINT PK_BRSLTM PRIMARY KEY (ASCT_ID),
    CONSTRAINT FK_BRSLTM_ASCT FOREIGN KEY (ASCT_ID) REFERENCES TAAABB_BASCTM(ASCT_ID)
);

COMMIT;
