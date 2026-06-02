-- IT관리비일련번호 표준화: IT_MNGC_SNO/SNO -> BG_SNO, NUMBER(9)
-- 기존 표준화 마이그레이션에서 BCOSTL/BCOSTM은 SNO로 변경될 수 있으므로 두 이름을 모두 처리한다.

DECLARE
  has_it_mngc_sno NUMBER;
  has_sno NUMBER;
  has_bg_sno NUMBER;
BEGIN
  SELECT COUNT(*) INTO has_it_mngc_sno FROM user_tab_columns WHERE table_name='TPRMPP_BCOSTL' AND column_name='IT_MNGC_SNO';
  SELECT COUNT(*) INTO has_sno FROM user_tab_columns WHERE table_name='TPRMPP_BCOSTL' AND column_name='SNO';
  SELECT COUNT(*) INTO has_bg_sno FROM user_tab_columns WHERE table_name='TPRMPP_BCOSTL' AND column_name='BG_SNO';

  IF has_bg_sno=0 AND has_sno=1 THEN
    EXECUTE IMMEDIATE 'ALTER TABLE TPRMPP_BCOSTL RENAME COLUMN SNO TO BG_SNO';
  ELSIF has_bg_sno=0 AND has_it_mngc_sno=1 THEN
    EXECUTE IMMEDIATE 'ALTER TABLE TPRMPP_BCOSTL RENAME COLUMN IT_MNGC_SNO TO BG_SNO';
  END IF;
END;
/

DECLARE
  has_it_mngc_sno NUMBER;
  has_sno NUMBER;
  has_bg_sno NUMBER;
BEGIN
  SELECT COUNT(*) INTO has_it_mngc_sno FROM user_tab_columns WHERE table_name='TPRMPP_BCOSTM' AND column_name='IT_MNGC_SNO';
  SELECT COUNT(*) INTO has_sno FROM user_tab_columns WHERE table_name='TPRMPP_BCOSTM' AND column_name='SNO';
  SELECT COUNT(*) INTO has_bg_sno FROM user_tab_columns WHERE table_name='TPRMPP_BCOSTM' AND column_name='BG_SNO';

  IF has_bg_sno=0 AND has_sno=1 THEN
    EXECUTE IMMEDIATE 'ALTER TABLE TPRMPP_BCOSTM RENAME COLUMN SNO TO BG_SNO';
  ELSIF has_bg_sno=0 AND has_it_mngc_sno=1 THEN
    EXECUTE IMMEDIATE 'ALTER TABLE TPRMPP_BCOSTM RENAME COLUMN IT_MNGC_SNO TO BG_SNO';
  END IF;
END;
/

DECLARE
  has_it_mngc_sno NUMBER;
  has_bg_sno NUMBER;
BEGIN
  SELECT COUNT(*) INTO has_it_mngc_sno FROM user_tab_columns WHERE table_name='TPRMPP_BTERML' AND column_name='IT_MNGC_SNO';
  SELECT COUNT(*) INTO has_bg_sno FROM user_tab_columns WHERE table_name='TPRMPP_BTERML' AND column_name='BG_SNO';

  IF has_bg_sno=0 AND has_it_mngc_sno=1 THEN
    EXECUTE IMMEDIATE 'ALTER TABLE TPRMPP_BTERML RENAME COLUMN IT_MNGC_SNO TO BG_SNO';
  END IF;
END;
/

DECLARE
  has_it_mngc_sno NUMBER;
  has_bg_sno NUMBER;
BEGIN
  SELECT COUNT(*) INTO has_it_mngc_sno FROM user_tab_columns WHERE table_name='TPRMPP_BTERMM' AND column_name='IT_MNGC_SNO';
  SELECT COUNT(*) INTO has_bg_sno FROM user_tab_columns WHERE table_name='TPRMPP_BTERMM' AND column_name='BG_SNO';

  IF has_bg_sno=0 AND has_it_mngc_sno=1 THEN
    EXECUTE IMMEDIATE 'ALTER TABLE TPRMPP_BTERMM RENAME COLUMN IT_MNGC_SNO TO BG_SNO';
  END IF;
END;
/

DECLARE
  has_col NUMBER;
BEGIN
  FOR c IN (
    SELECT DISTINCT uc.constraint_name
      FROM user_constraints uc
      JOIN user_cons_columns ucc
        ON ucc.constraint_name = uc.constraint_name
       AND ucc.table_name = uc.table_name
     WHERE uc.table_name='TPRMPP_BTERMM'
       AND uc.constraint_type='R'
       AND ucc.column_name='BG_SNO'
  ) LOOP
    EXECUTE IMMEDIATE 'ALTER TABLE TPRMPP_BTERMM DISABLE CONSTRAINT "' || c.constraint_name || '"';
  END LOOP;

  FOR t IN (
    SELECT 'TPRMPP_BTERMM' table_name FROM dual UNION ALL
    SELECT 'TPRMPP_BTERML' table_name FROM dual UNION ALL
    SELECT 'TPRMPP_BCOSTL' table_name FROM dual UNION ALL
    SELECT 'TPRMPP_BCOSTM' table_name FROM dual
  ) LOOP
    SELECT COUNT(*) INTO has_col FROM user_tab_columns WHERE table_name=t.table_name AND column_name='BG_SNO';
    IF has_col=1 THEN
      EXECUTE IMMEDIATE 'ALTER TABLE ' || t.table_name || ' MODIFY (BG_SNO NUMBER(9))';
      EXECUTE IMMEDIATE 'COMMENT ON COLUMN ' || t.table_name || '.BG_SNO IS ''예산일련번호''';
    END IF;
  END LOOP;

  FOR c IN (
    SELECT DISTINCT uc.constraint_name
      FROM user_constraints uc
      JOIN user_cons_columns ucc
        ON ucc.constraint_name = uc.constraint_name
       AND ucc.table_name = uc.table_name
     WHERE uc.table_name='TPRMPP_BTERMM'
       AND uc.constraint_type='R'
       AND ucc.column_name='BG_SNO'
  ) LOOP
    EXECUTE IMMEDIATE 'ALTER TABLE TPRMPP_BTERMM ENABLE CONSTRAINT "' || c.constraint_name || '"';
  END LOOP;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'ALTER TABLE TPRMPP_BCOSTM RENAME CONSTRAINT "PK_TAAABB_BCOSTM_IT_MNGC_NO_IT_MNGC_SNO" TO "PK_BCOSTM_BG_NO_BG_SNO"';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'ALTER INDEX "PK_TAAABB_BCOSTM_IT_MNGC_NO_IT_MNGC_SNO" RENAME TO "PK_BCOSTM_BG_NO_BG_SNO"';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'ALTER TABLE TPRMPP_BTERMM RENAME CONSTRAINT "FK_TAAABB_BTERMM_IT_MNGC_NO_IT_MNGC_SNO" TO "FK_BTERMM_BG_NO_BG_SNO"';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'ALTER INDEX "IX_BTERMM_BG_NO_IT_MNGC_SNO" RENAME TO "IX_BTERMM_BG_NO_BG_SNO"';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
