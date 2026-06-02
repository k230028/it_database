# -*- coding: utf-8 -*-
"""보고서 rename 매핑으로 JPA @Column(name) 치환. 루트(C:\\it)에서 실행."""
import re
from collections import defaultdict

REPORT='docs/meta-compliance-report.md'
BK='it_backend/src/main/java/com/kdb/it'
ENT={
 'BCOSTM':[f'{BK}/domain/budget/cost/entity/Bcostm.java'],'BCOSTL':[f'{BK}/domain/log/entity/BcostmL.java'],
 'BPROJM':[f'{BK}/domain/budget/project/entity/Bprojm.java'],'BPROJL':[f'{BK}/domain/log/entity/BprojmL.java'],
 'BPROJA':[f'{BK}/domain/budget/plan/entity/Bproja.java'],
 'BPLANM':[f'{BK}/domain/budget/plan/entity/Bplanm.java'],'BPLANL':[f'{BK}/domain/log/entity/BplanmL.java'],
 'BBUGTM':[f'{BK}/domain/budget/work/entity/Bbugtm.java'],'BBUGTL':[f'{BK}/domain/log/entity/BbugtL.java'],
 'BITEMM':[f'{BK}/domain/budget/project/entity/Bitemm.java'],'BITEML':[f'{BK}/domain/log/entity/BitemmL.java'],
 'BTERMM':[f'{BK}/domain/budget/cost/entity/Btermm.java'],'BTERML':[f'{BK}/domain/log/entity/BtermmL.java'],
 'BGDOCM':[f'{BK}/domain/budget/document/entity/Bgdocm.java'],'BGDOCL':[f'{BK}/domain/log/entity/BgdocmL.java'],
 'BRDOCM':[f'{BK}/domain/budget/document/entity/Brdocm.java'],'BRDOCL':[f'{BK}/domain/log/entity/BrdocmL.java'],
 'BRIVGM':[f'{BK}/domain/budget/document/entity/Brivgm.java'],'BRIVGL':[f'{BK}/domain/log/entity/BrivgmL.java'],
 'CBLBMM':[f'{BK}/common/board/entity/Cblbmm.java'],'CBLBML':[f'{BK}/domain/log/entity/CblbmmL.java'],
 'CBLBCM':[f'{BK}/common/board/entity/Cblbcm.java'],'CBLBCL':[f'{BK}/domain/log/entity/CblbcmL.java'],
 'CCMMTM':[f'{BK}/common/board/entity/Ccmmtm.java'],'CCMMTL':[f'{BK}/domain/log/entity/CcmmtmL.java'],
 'CRTOKM':[f'{BK}/common/system/entity/Crtokm.java'],
}

def parse():
    rows=[]; sec=None
    for ln in open(REPORT,encoding='utf-8').read().splitlines():
        h=re.match(r'## \d+[a-z]?\.\s*(.+)',ln)
        if h: sec=h.group(1); continue
        if not ln.startswith('| `'): continue
        c=[x.strip() for x in ln.strip().strip('|').split('|')]
        if sec and sec.startswith('지정(전문가)'):
            rows.append((c[0].strip('`'),re.split(r'\s*/\s*',c[3])[0].strip().upper(),[t.strip() for t in c[2].split(',')]))
    return rows

def main():
    rows=parse()
    grp=defaultdict(set); exp=[]
    for col,new,tables in rows:
        for t in tables: grp[(t,new)].add(col); exp.append((t,col,new))
    conflict={k for k,v in grp.items() if len(v)>1}
    changed=0; skipped=[]
    for t,col,new in exp:
        if (t,new) in conflict: skipped.append((t,col,'충돌보류')); continue
        for fp in ENT.get(t,[]):
            try: txt=open(fp,encoding='utf-8').read()
            except FileNotFoundError: skipped.append((t,col,'파일없음')); continue
            pat=f'@Column(name = "{col}"'; pat2=f'@Column(name="{col}"'
            if pat in txt: txt=txt.replace(pat,f'@Column(name = "{new}"'); changed+=1
            elif pat2 in txt: txt=txt.replace(pat2,f'@Column(name="{new}"'); changed+=1
            else: skipped.append((t,col,f'미발견@{fp.split("/")[-1]}')); continue
            open(fp,'w',encoding='utf-8').write(txt)
    print(f'changed={changed}')
    for s in skipped:
        if s[2] not in('충돌보류',): print('  SKIP',s)
    print(f'충돌보류 skip = {sum(1 for s in skipped if s[2]=="충돌보류")}')

if __name__=='__main__': main()
