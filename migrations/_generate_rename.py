# -*- coding: utf-8 -*-
"""docs/meta-compliance-report.md → 멱등 Flyway SQL 생성. 루트(C:\\it)에서 실행."""
import re
from collections import defaultdict

REPORT = 'docs/meta-compliance-report.md'
OUT = 'it_database/migrations'

RETYPE_CONV = {
    'CMMT_SNO':       ('NUMBER(9,0)',     "TO_NUMBER({old})"),
    'CMMT_TGT_SNO':   ('NUMBER(9,0)',     "TO_NUMBER({old})"),
    'HRK_CMMT_SNO':   ('NUMBER(9,0)',     "TO_NUMBER({old})"),
    'RVW_FSG_TLM_DT': ('VARCHAR2(8 CHAR)', "TO_CHAR({old},'YYYYMMDD')"),
    'FLF_FSG_DT':     ('VARCHAR2(8 CHAR)', "TO_CHAR({old},'YYYYMMDD')"),
}
RETYPE_COLS = {'CMMT_MNG_NO','CMMT_GRP_NO','HRK_CMMT_MNG_NO','FSG_TLM','LBL_FSG_TLM'}

def parse_report():
    rows=[]; sec=None
    for ln in open(REPORT,encoding='utf-8').read().splitlines():
        h=re.match(r'## \d+[a-z]?\.\s*(.+)',ln)
        if h: sec=h.group(1); continue
        if not ln.startswith('| `'): continue
        c=[x.strip() for x in ln.strip().strip('|').split('|')]
        if not c or not c[0].startswith('`'): continue
        col=c[0].strip('`')
        if sec and sec.startswith('지정(전문가)'):
            newcol=re.split(r'\s*/\s*',c[3])[0].strip().upper()
            tables=[t.strip() for t in c[2].split(',')]
            mt=re.search(r'\((VARCHAR2|NUMBER|CLOB|DATE)(\d+)?\)',c[3])
            ttype=mt.group(1) if mt else None
            tlen=int(mt.group(2)) if (mt and mt.group(2)) else None
            rows.append(dict(col=col,newcol=newcol,tables=tables,kind='rename',
                ttype=ttype,tlen=tlen,
                typechange=(col in RETYPE_COLS) or ('타입변경' in c[4])))
        elif sec and sec.startswith('표준명(타입변경)'):
            tables=[t.strip() for t in c[1].split(',')]
            rows.append(dict(col=col,newcol=col,tables=tables,kind='retype',ttype='VARCHAR2',tlen=8,typechange=True))
        elif sec and sec.startswith('삭제후보'):
            tables=[t.strip() for t in c[2].split(',')]
            rows.append(dict(col=col,newcol=None,tables=tables,kind='drop',ttype=None,tlen=None,typechange=False))
    return rows

def expand(rows):
    out=[]
    for r in rows:
        for short in r['tables']:
            out.append(dict(table=f'TPRMPP_{short}',col=r['col'],newcol=r['newcol'],
                kind=r['kind'],typechange=r['typechange'],ttype=r.get('ttype'),tlen=r.get('tlen')))
    return out

def detect_conflicts(items):
    grp=defaultdict(list)
    for it in items:
        if it['kind'] in('rename','retype'):
            grp[(it['table'],it['newcol'])].append(it['col'])
    return {k for k,v in grp.items() if len(set(v))>1}

def guard_rename(table,old,new,newtype=None):
    s=(f"DECLARE\n  has_old NUMBER; has_new NUMBER;\nBEGIN\n"
       f"  SELECT COUNT(*) INTO has_old FROM user_tab_columns WHERE table_name='{table}' AND column_name='{old}';\n"
       f"  SELECT COUNT(*) INTO has_new FROM user_tab_columns WHERE table_name='{table}' AND column_name='{new}';\n"
       f"  IF has_old=1 AND has_new=0 THEN\n"
       f"    EXECUTE IMMEDIATE 'ALTER TABLE {table} RENAME COLUMN {old} TO {new}';\n"
       f"  END IF;\nEND;\n/")
    if newtype: s+=f"\nALTER TABLE {table} MODIFY ({new} {newtype});"
    return s

def guard_rename_resize(table,old,new,tlen):
    return (guard_rename(table,old,new)+"\n"
            f"UPDATE {table} SET {new}=TRIM({new})\n"
            f"  WHERE {new} IS NOT NULL AND LENGTH({new})>{tlen} AND LENGTH(TRIM({new}))<={tlen};\n"
            f"DECLARE over_cnt NUMBER;\nBEGIN\n"
            f"  SELECT COUNT(*) INTO over_cnt FROM {table} WHERE {new} IS NOT NULL AND LENGTH({new})>{tlen};\n"
            f"  IF over_cnt=0 THEN\n"
            f"    BEGIN\n"
            f"      EXECUTE IMMEDIATE 'ALTER TABLE {table} MODIFY ({new} VARCHAR2({tlen} CHAR))';\n"
            f"    EXCEPTION WHEN OTHERS THEN\n"
            f"      DBMS_OUTPUT.PUT_LINE('SKIP MODIFY {table}.{new}: '||SQLERRM);\n"
            f"    END;\n"
            f"  ELSE\n"
            f"    DBMS_OUTPUT.PUT_LINE('SKIP MODIFY {table}.{new}: 실데이터 '||over_cnt||'행이 길이 {tlen} 초과 — 코드/값 매핑 필요');\n"
            f"  END IF;\nEND;\n/")

def guard_retype_rename(table,old,new,newtype,conv):
    convexpr=conv.format(old=old)
    return (f"DECLARE\n  has_new NUMBER;\nBEGIN\n"
            f"  SELECT COUNT(*) INTO has_new FROM user_tab_columns WHERE table_name='{table}' AND column_name='{new}';\n"
            f"  IF has_new=0 THEN EXECUTE IMMEDIATE 'ALTER TABLE {table} ADD ({new} {newtype})'; END IF;\n"
            f"END;\n/\n"
            f"UPDATE {table} SET {new}={convexpr} WHERE {old} IS NOT NULL AND {new} IS NULL;\n"
            f"DECLARE has_old NUMBER;\nBEGIN\n"
            f"  SELECT COUNT(*) INTO has_old FROM user_tab_columns WHERE table_name='{table}' AND column_name='{old}';\n"
            f"  IF has_old=1 THEN EXECUTE IMMEDIATE 'ALTER TABLE {table} DROP COLUMN {old}'; END IF;\n"
            f"END;\n/")

def guard_drop(table,col):
    return (f"DECLARE\n  has_col NUMBER;\nBEGIN\n"
            f"  SELECT COUNT(*) INTO has_col FROM user_tab_columns WHERE table_name='{table}' AND column_name='{col}';\n"
            f"  IF has_col=1 THEN\n    EXECUTE IMMEDIATE 'ALTER TABLE {table} DROP COLUMN {col}';\n  END IF;\nEND;\n/")

def header(title):
    return (f"-- ============================================================\n"
            f"-- {title}\n-- 생성: _generate_rename.py (보고서 기반, 멱등). 직접 수정 금지.\n"
            f"-- ============================================================\n")

def main():
    items=expand(parse_report()); conflicts=detect_conflicts(items)
    simple=[]; rt_rename=[]; rt_only=[]; drops=[]; deferred=[]
    for it in items:
        if it['kind'] in('rename','retype') and (it['table'],it['newcol']) in conflicts:
            deferred.append(it); continue
        if it['kind']=='drop': drops.append(it)
        elif it['kind']=='retype': rt_only.append(it)
        elif it['typechange']: rt_rename.append(it)
        else: simple.append(it)

    with open(f'{OUT}/V20260602_001__RenameStdColumns.sql','w',encoding='utf-8') as f:
        f.write(header('표준명칭 변경: RENAME + VARCHAR2 표준길이 정규화(패딩 자동 trim)'))
        f.write("SET SERVEROUTPUT ON\n")
        for it in sorted(simple,key=lambda x:(x['table'],x['col'])):
            f.write(f"\n-- {it['table']}: {it['col']} -> {it['newcol']}")
            if it['ttype']=='VARCHAR2' and it['tlen']:
                f.write(f" (VARCHAR2 길이 {it['tlen']} 정규화)\n"+guard_rename_resize(it['table'],it['col'],it['newcol'],it['tlen'])+"\n")
            else:
                f.write("\n"+guard_rename(it['table'],it['col'],it['newcol'])+"\n")
        f.write("\nCOMMIT;\n")

    with open(f'{OUT}/V20260602_002__RenameStdColumnsRetype.sql','w',encoding='utf-8') as f:
        f.write(header('표준명칭 변경: 타입변경 동반 (데이터 보존: ADD→UPDATE→DROP)'))
        for it in sorted(rt_rename,key=lambda x:(x['table'],x['col'])):
            spec=RETYPE_CONV.get(it['newcol']); assert spec,f"RETYPE_CONV 누락: {it['newcol']}"
            nt,conv=spec
            f.write(f"\n-- {it['table']}: {it['col']} -> {it['newcol']} ({nt})\n"+guard_retype_rename(it['table'],it['col'],it['newcol'],nt,conv)+"\n")
        f.write("\nCOMMIT;\n")

    with open(f'{OUT}/V20260602_003__RetypeStdColumns.sql','w',encoding='utf-8') as f:
        f.write(header('타입만 변환 (DATE -> VARCHAR2(8), 값 YYYYMMDD 변환)'))
        for it in sorted(rt_only,key=lambda x:(x['table'],x['col'])):
            t,c=it['table'],it['col']
            f.write(f"\n-- {t}: {c} DATE -> VARCHAR2(8)\n")
            f.write(f"DECLARE has_tmp NUMBER; BEGIN\n"
                    f"  SELECT COUNT(*) INTO has_tmp FROM user_tab_columns WHERE table_name='{t}' AND column_name='{c}_TMP';\n"
                    f"  IF has_tmp=0 THEN EXECUTE IMMEDIATE 'ALTER TABLE {t} ADD ({c}_TMP VARCHAR2(8 CHAR))'; END IF;\nEND;\n/\n")
            f.write(f"UPDATE {t} SET {c}_TMP=TO_CHAR({c},'YYYYMMDD') WHERE {c} IS NOT NULL AND {c}_TMP IS NULL;\n")
            f.write(f"ALTER TABLE {t} DROP COLUMN {c};\n")
            f.write(f"ALTER TABLE {t} RENAME COLUMN {c}_TMP TO {c};\n")
        f.write("\nCOMMIT;\n")

    with open(f'{OUT}/V20260602_004__DropUnusedColumns.sql','w',encoding='utf-8') as f:
        f.write(header('삭제후보 컬럼 DROP'))
        for it in sorted(drops,key=lambda x:(x['table'],x['col'])):
            f.write(f"\n-- {it['table']}: DROP {it['col']}\n"+guard_drop(it['table'],it['col'])+"\n")
        f.write("\nCOMMIT;\n")

    g=defaultdict(list)
    for it in deferred: g[(it['table'],it['newcol'])].append(it['col'])
    with open(f'{OUT}/_rename_conflicts.txt','w',encoding='utf-8') as f:
        f.write("동일 테이블 타깃 충돌 (보류 — 사용자 쌍별 지정 필요)\n")
        for (t,n),cs in sorted(g.items()): f.write(f"  {t}: {' , '.join(sorted(set(cs)))} -> {n}\n")
    print(f"simple={len(simple)} retype_rename={len(rt_rename)} retype_only={len(rt_only)} drops={len(drops)} deferred={len(deferred)}")

if __name__=='__main__': main()
