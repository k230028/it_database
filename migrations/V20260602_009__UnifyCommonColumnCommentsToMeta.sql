-- =====================================================================
-- V20260602_009 공통 컬럼 코멘트 전사 통일 (메타 용어사전 기준)
-- 출처: meta.csv 표준 한글명
-- 대상: 전 TPRMPP_* 테이블의 공통 감사/식별 컬럼
-- 멱등: COMMENT ON COLUMN 재실행 시 동일값 덮어쓰기 (안전)
-- 비고: 컬럼이 존재하는 테이블만 갱신 (로그 전용 컬럼은 *L 테이블만 해당)
-- =====================================================================

DECLARE
  TYPE t_map IS TABLE OF VARCHAR2(100) INDEX BY VARCHAR2(30);
  m t_map;
  k VARCHAR2(30);
BEGIN
  m('GUID')            := 'GUID';
  m('GUID_PRG_SNO')    := 'GUID진행일련번호';
  m('LOG_HIS_TGR_SNO') := '로그이력전문일련번호';
  m('CHG_DTT_YN')      := '변경구분여부';
  m('CHG_USID')        := '변경사용자ID';
  m('CHG_DTM')         := '변경일시';
  m('DEL_YN')          := '삭제여부';
  m('FST_ENR_USID')    := '최초등록사용자ID';
  m('FST_ENR_DTM')     := '최초등록일시';
  m('LST_CHG_USID')    := '최종변경사용자ID';
  m('LST_CHG_DTM')     := '최종변경일시';

  k := m.FIRST;
  WHILE k IS NOT NULL LOOP
    FOR c IN (SELECT table_name
                FROM user_tab_columns
               WHERE column_name = k
                 AND table_name LIKE 'TPRMPP\_%' ESCAPE '\') LOOP
      EXECUTE IMMEDIATE 'COMMENT ON COLUMN "'||c.table_name||'"."'||k||'" IS '''||m(k)||'''';
    END LOOP;
    k := m.NEXT(k);
  END LOOP;
END;
/

COMMIT;
