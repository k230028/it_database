-- TPRMPP_BRIVGM(문서 검토의견) 잔존 컬럼 정리
--
-- 배경: 해결여부 컬럼이 RSLV_YN -> FSG_YN 으로 엔티티에서 개명되었으나,
-- ddl-auto=update 는 RENAME 을 지원하지 않아 신규 FSG_YN 컬럼만 추가되고
-- 기존 RSLV_YN(NOT NULL, DB 기본값 없음)이 그대로 남았습니다.
-- INSERT 시 RSLV_YN 미지정으로 ORA-01400(NULL 삽입 불가)이 발생합니다.
-- 코드베이스는 전부 FSG_YN 으로 전환되었으므로 잔존 RSLV_YN 을 제거합니다.
--
-- 멱등성: 컬럼이 이미 없으면 무시(ORA-00904)합니다.
BEGIN
    EXECUTE IMMEDIATE 'ALTER TABLE ITPAPP.TPRMPP_BRIVGM DROP COLUMN RSLV_YN';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -904 THEN
            RAISE;
        END IF;
END;
/
