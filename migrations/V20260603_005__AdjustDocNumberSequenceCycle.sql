-- =====================================================================
-- 문서번호 채번 시퀀스 정합성 개선
-- =====================================================================
-- 배경:
--   문서번호(관리번호)를 채번하는 마스터(M) 계열 시퀀스가 모두 CYCLE 로
--   정의되어 있어, 시퀀스가 MAXVALUE 에 도달하면 1 로 순환한다.
--   채번 포맷은 대부분 {접두사}-{연도}-{NNNN}(%04d) 이지만 시퀀스는
--   연도별로 리셋되지 않고 누적 증가하므로, 순환 시점에 과거에 발급한
--   문서번호가 재사용되어 PK/UNIQUE 충돌(ORA-00001)이 발생한다.
--   특히 연도 접두사가 없는 BLBM-%04d(게시판 메타) / FL_%08d(파일) 은
--   순환 즉시 충돌이 확정된다.
--
-- 조치:
--   1) 모든 채번 시퀀스를 NOCYCLE 로 전환 → 시퀀스값이 영구적으로 유일.
--      포맷 자릿수를 초과하면 번호가 한 자리 늘어날 뿐 유일성은 유지된다.
--   2) MAXVALUE 를 "각 PK 컬럼 폭에 포맷이 들어갈 수 있는 최대 자릿수"
--      로 확대. 컬럼 폭을 넘는 번호가 생성되지 않도록 상한을 컬럼 기준으로
--      산정한다(아래 표 참조). NOCYCLE 이므로 상한 도달 시 조용한 충돌 대신
--      ORA-08004 로 즉시 실패하여 운영 인지가 가능하다.
--
--   시퀀스        포맷           PK컬럼(폭)         접두사+자릿수   MAXVALUE
--   SEQ_BCOSTM    COST-y-%04d    BG_NO(15)          10+5 = 15       99999
--   SEQ_CBLBMM    BLBM-%04d      BLB_ID(10)          5+5 = 10       99999
--   SEQ_BBUGTM    BG-y-%04d      BG_NO(15)           8+7 = 15       9999999
--   SEQ_BITEMM    GCL-y-%04d     GCL_MNG_NO(16)      9+7 = 16       9999999
--   SEQ_BTERMM    TER-y-%04d     TMN_MNG_NO(16)      9+7 = 16       9999999
--   SEQ_CBLBCM    NAC-y-%04d     NAC_NO(16)          9+7 = 16       9999999
--   SEQ_BASCTM    ASCT-y-%04d    ASCT_ID(32)         여유            99999999
--   SEQ_BGDOCM    GDOC-y-%04d    DOC_MNG_NO(20)      여유            99999999
--   SEQ_BPLANM    PLN-y-%04d     REQ_DOC_NO(30)      여유            99999999
--   SEQ_BPROJM    PRJ-y-%04d     ABUS_MNG_NO(30)     여유            99999999
--   SEQ_BRDOCM    DOC-y-%04d     DOC_MNG_NO(20)      여유            99999999
--   SEQ_CAPPLM    APF-y-%08d     APF_DCM_NO(64)      여유            99999999(유지)
--   SEQ_CFILEM    FL_%08d        FL_MNG_NO(32)       여유            9999999999
--   SEQ_CINFMM    INF-y-%08d     INFM_MSG_NO(30)     여유            9999999999
--
-- 멱등성: ALTER SEQUENCE 는 동일 상태로 반복 실행해도 안전하다.
--         현재 시퀀스값(최대 수백)이 모든 신규 MAXVALUE 보다 작으므로
--         MAXVALUE 축소 충돌(ORA-04009)은 발생하지 않는다.
-- =====================================================================

-- 5자리 상한(컬럼 폭이 빠듯한 경우)
ALTER SEQUENCE ITPAPP.SEQ_BCOSTM NOCYCLE MAXVALUE 99999;
ALTER SEQUENCE ITPAPP.SEQ_CBLBMM NOCYCLE MAXVALUE 99999;

-- 7자리 상한
ALTER SEQUENCE ITPAPP.SEQ_BBUGTM NOCYCLE MAXVALUE 9999999;
ALTER SEQUENCE ITPAPP.SEQ_BITEMM NOCYCLE MAXVALUE 9999999;
ALTER SEQUENCE ITPAPP.SEQ_BTERMM NOCYCLE MAXVALUE 9999999;
ALTER SEQUENCE ITPAPP.SEQ_CBLBCM NOCYCLE MAXVALUE 9999999;

-- 8자리 상한(여유 컬럼)
ALTER SEQUENCE ITPAPP.SEQ_BASCTM NOCYCLE MAXVALUE 99999999;
ALTER SEQUENCE ITPAPP.SEQ_BGDOCM NOCYCLE MAXVALUE 99999999;
ALTER SEQUENCE ITPAPP.SEQ_BPLANM NOCYCLE MAXVALUE 99999999;
ALTER SEQUENCE ITPAPP.SEQ_BPROJM NOCYCLE MAXVALUE 99999999;
ALTER SEQUENCE ITPAPP.SEQ_BRDOCM NOCYCLE MAXVALUE 99999999;

-- 8자리 포맷(%08d) — CYCLE만 제거, 기존 MAXVALUE 유지
ALTER SEQUENCE ITPAPP.SEQ_CAPPLM NOCYCLE MAXVALUE 99999999;

-- 고볼륨 채널 — 10자리로 확대
ALTER SEQUENCE ITPAPP.SEQ_CFILEM NOCYCLE MAXVALUE 9999999999;
ALTER SEQUENCE ITPAPP.SEQ_CINFMM NOCYCLE MAXVALUE 9999999999;
