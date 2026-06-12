# -*- coding: utf-8 -*-
"""운영DB 스펙(table.csv)과 로컬DB DDL(ITPOWN_DDL_live.sql) 비교 스크립트.

비교 항목: 테이블 존재 여부, 테이블 코멘트, 컬럼 순서, 컬럼명, 타입/길이/소수점,
NULL 여부, Default, PK 구성, 컬럼 코멘트.
"""
import csv
import re
import sys
from collections import OrderedDict

CSV_PATH = r"C:\it\table.csv"
DDL_PATH = r"C:\it\it_database\ITPOWN_DDL_live.sql"


def norm_default(v):
    if v is None:
        return None
    v = v.strip().rstrip()
    if v == "":
        return None
    v = v.upper() if not v.startswith("'") else v
    return v


def norm_type(dtype, length, scale):
    """타입 문자열 정규화. CHAR/BYTE 의미는 무시."""
    dtype = dtype.upper().strip()
    length = (length or "").strip()
    scale = (scale or "").strip()
    if dtype in ("DATE", "CLOB", "BLOB", "TIMESTAMP"):
        return dtype
    if dtype == "NUMBER":
        if length == "" or (length == "22" and scale == ""):
            return "NUMBER"
        if scale == "" or scale == "0":
            return f"NUMBER({length})"
        return f"NUMBER({length},{scale})"
    if length:
        return f"{dtype}({length})"
    return dtype


# ---------- 운영(CSV) 파싱 ----------
prod = OrderedDict()  # table -> dict(comment, cols=OrderedDict(name->col))
with open(CSV_PATH, encoding="utf-8-sig") as f:
    rdr = csv.reader(f)
    header = next(rdr)
    for row in rdr:
        if not row or not row[0].strip():
            continue
        tbl, tbl_cmt, col, col_cmt, pk, nullable, dflt, dtype, length, scale = (
            [c.strip() for c in row[:10]] + [""] * (10 - len(row))
        )[:10]
        t = prod.setdefault(tbl, {"comment": tbl_cmt, "cols": OrderedDict(), "pk": []})
        t["cols"][col] = {
            "comment": col_cmt,
            "type": norm_type(dtype, length, scale),
            "raw_type": (dtype, length, scale),
            "nullable": nullable.upper() != "N",
            "default": norm_default(dflt),
        }
        if pk.upper() == "Y":
            t["pk"].append(col)

# ---------- 로컬(DDL) 파싱 ----------
text = open(DDL_PATH, encoding="utf-8").read()

local = OrderedDict()
# CREATE TABLE 블록
for m in re.finditer(
    r'CREATE TABLE "ITPOWN"\."(\w+)"\s*\((.*?)\)\s*(?:DEFAULT COLLATION "USING_NLS_COMP")?\s*;',
    text, re.S):
    tbl, body = m.group(1), m.group(2)
    cols = OrderedDict()
    pk = []
    # 본문을 최상위 콤마 기준으로 분리
    depth = 0
    parts, cur = [], []
    for ch in body:
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
        if ch == "," and depth == 0:
            parts.append("".join(cur)); cur = []
        else:
            cur.append(ch)
    if cur:
        parts.append("".join(cur))
    for p in parts:
        p = p.strip()
        cm = re.match(r'^"(\w+)"\s+(.*)$', p, re.S)
        if p.startswith("CONSTRAINT"):
            pkm = re.search(r'PRIMARY KEY \(([^)]*)\)', p)
            if pkm:
                pk = [c.strip().strip('"') for c in pkm.group(1).split(",")]
            continue
        if not cm:
            continue
        name, rest = cm.group(1), cm.group(2)
        rest = re.sub(r'COLLATE "USING_NLS_COMP"', "", rest)
        tm = re.match(
            r'\s*([A-Z0-9_]+)\s*(?:\((\d+)(?:\s*(?:CHAR|BYTE))?(?:\s*,\s*(\d+))?\))?', rest)
        dtype, length, scale = tm.group(1), tm.group(2), tm.group(3)
        nullable = "NOT NULL" not in rest
        dm = re.search(r"DEFAULT\s+(.*?)(?:\s+NOT NULL|\s*$)", rest.strip(), re.S)
        dflt = norm_default(dm.group(1)) if dm else None
        if dtype == "NUMBER" and length and scale == "0":
            ntype = f"NUMBER({length})"
        else:
            ntype = norm_type(dtype, length or "", scale or "")
        cols[name] = {
            "type": ntype,
            "nullable": nullable,
            "default": dflt,
            "comment": None,
        }
    local[tbl] = {"comment": None, "cols": cols, "pk": pk}

# 코멘트 파싱
for m in re.finditer(r'COMMENT ON TABLE "ITPOWN"\."(\w+)"\s+IS \'((?:[^\']|\'\')*)\'', text):
    if m.group(1) in local:
        local[m.group(1)]["comment"] = m.group(2).replace("''", "'")
for m in re.finditer(r'COMMENT ON COLUMN "ITPOWN"\."(\w+)"\."(\w+)" IS \'((?:[^\']|\'\')*)\'', text):
    t, c = m.group(1), m.group(2)
    if t in local and c in local[t]["cols"]:
        local[t]["cols"][c]["comment"] = m.group(3).replace("''", "'")

# CSV의 NUMBER 정규화 보정: 운영 CSV에서 scale 공란 + 길이=22 → NUMBER 로 간주했으나
# 로컬과 비교 시 NUMBER(22)일 수도 있으므로 그대로 둠 (리포트에서 식별)

# ---------- 비교 ----------
out = []
prod_tables = set(prod)
local_tables = set(local)

only_prod = sorted(prod_tables - local_tables)
only_local = sorted(local_tables - prod_tables)
common = sorted(prod_tables & local_tables)

out.append(f"운영 테이블 수: {len(prod_tables)}, 로컬 테이블 수: {len(local_tables)}")
out.append(f"운영에만 존재: {len(only_prod)} -> {only_prod}")
out.append(f"로컬에만 존재: {len(only_local)} -> {only_local}")
out.append("")

for tbl in common:
    p, l = prod[tbl], local[tbl]
    diffs = []
    if p["comment"] != (l["comment"] or ""):
        diffs.append(f"  [테이블코멘트] 운영='{p['comment']}' / 로컬='{l['comment']}'")
    pcols, lcols = list(p["cols"]), list(l["cols"])
    if set(pcols) - set(lcols):
        diffs.append(f"  [운영에만 있는 컬럼] {sorted(set(pcols)-set(lcols))}")
    if set(lcols) - set(pcols):
        diffs.append(f"  [로컬에만 있는 컬럼] {sorted(set(lcols)-set(pcols))}")
    commoncols = [c for c in pcols if c in l["cols"]]
    p_order = [c for c in pcols if c in set(lcols)]
    l_order = [c for c in lcols if c in set(pcols)]
    if p_order != l_order:
        diffs.append(f"  [컬럼순서 다름]\n    운영: {p_order}\n    로컬: {l_order}")
    if sorted(p["pk"]) != sorted(l["pk"]):
        diffs.append(f"  [PK] 운영={p['pk']} / 로컬={l['pk']}")
    for c in commoncols:
        pc, lc = p["cols"][c], l["cols"][c]
        sub = []
        if pc["type"] != lc["type"]:
            sub.append(f"타입 운영={pc['type']} 로컬={lc['type']}")
        if pc["nullable"] != lc["nullable"]:
            sub.append(f"NULL허용 운영={pc['nullable']} 로컬={lc['nullable']}")
        if (pc["default"] or "") != (lc["default"] or ""):
            sub.append(f"DEFAULT 운영={pc['default']} 로컬={lc['default']}")
        if pc["comment"] != (lc["comment"] or ""):
            sub.append(f"코멘트 운영='{pc['comment']}' 로컬='{lc['comment']}'")
        if sub:
            diffs.append(f"  [컬럼 {c}] " + " | ".join(sub))
    if diffs:
        out.append(f"### {tbl}")
        out.extend(diffs)
        out.append("")

report = "\n".join(out)
with open(r"C:\it\it_database\tools\diff_report.txt", "w", encoding="utf-8") as f:
    f.write(report)
print(report[:6000])
print(f"\n... (전체 리포트: diff_report.txt, {len(report)}자)")
