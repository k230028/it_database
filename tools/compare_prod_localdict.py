# -*- coding: utf-8 -*-
"""운영DB 스펙(table.csv) vs 로컬DB 딕셔너리(local_dict.csv + local_defaults.txt) 비교.

DDL 파일 파싱 대신 ALL_TAB_COLUMNS 등 실제 딕셔너리 기준으로 비교한다.
- DEFAULT NULL(명시적)과 default 없음은 기능적으로 동일하므로 같다고 본다.
- NUMBER: 운영 CSV의 '길이'는 data_precision, '소수점'은 data_scale(공란=0)로 해석.
"""
import csv
from collections import OrderedDict

PROD_CSV = r"C:\it\table.csv"
DICT_CSV = r"C:\it\it_database\tools\local_dict.csv"
DEF_TXT = r"C:\it\it_database\tools\local_defaults.txt"
OUT = r"C:\it\it_database\tools\diff_report2.txt"


def norm_default(v):
    if v is None:
        return None
    v = v.strip()
    if v == "" or v.upper() == "NULL":
        return None
    if not v.startswith("'"):
        v = v.upper()
    return v


# ---------- 운영(CSV) ----------
prod = OrderedDict()
with open(PROD_CSV, encoding="utf-8-sig") as f:
    rdr = csv.reader(f)
    next(rdr)
    for row in rdr:
        if not row or not row[0].strip():
            continue
        tbl, tbl_cmt, col, col_cmt, pk, nullable, dflt, dtype, length, scale = (
            [c.strip() for c in row[:10]] + [""] * 10)[:10]
        t = prod.setdefault(tbl, {"comment": tbl_cmt, "cols": OrderedDict()})
        t["cols"][col] = {
            "comment": col_cmt,
            "dtype": dtype.upper(),
            "length": length,
            "scale": scale,
            "pk": pk.upper() == "Y",
            "nullable": nullable.upper() != "N",
            "default": norm_default(dflt),
        }

# ---------- 로컬(딕셔너리) ----------
local = OrderedDict()
with open(DICT_CSV, encoding="utf-8-sig") as f:
    rdr = csv.DictReader(line for line in f if line.strip())
    for r in rdr:
        tbl = r["TABLE_NAME"]
        t = local.setdefault(tbl, {"comment": r["TABLE_COMMENT"] or "", "cols": OrderedDict()})
        t["cols"][r["COLUMN_NAME"]] = {
            "comment": r["COLUMN_COMMENT"] or "",
            "dtype": r["DATA_TYPE"].upper(),
            "precision": r["DATA_PRECISION"],
            "scale": r["DATA_SCALE"],
            "char_length": r["CHAR_LENGTH"],
            "data_length": r["DATA_LENGTH"],
            "pk": r["PK_YN"] == "Y",
            "nullable": r["NULLABLE"] == "Y",
            "default": None,
        }
with open(DEF_TXT, encoding="utf-8") as f:
    for line in f:
        line = line.rstrip("\n")
        if not line.strip() or "|" not in line:
            continue
        tbl, col, val = line.split("|", 2)
        if tbl in local and col in local[tbl]["cols"]:
            local[tbl]["cols"][col]["default"] = norm_default(val)


def prod_type(c):
    d, ln, sc = c["dtype"], c["length"], c["scale"]
    if d in ("DATE", "CLOB", "BLOB"):
        return d
    if d == "NUMBER":
        if ln == "":
            return "NUMBER"
        sc = sc or "0"
        return f"NUMBER({ln},{sc})" if sc != "0" else f"NUMBER({ln})"
    return f"{d}({ln})"


def local_type(c):
    d = c["dtype"]
    if d in ("DATE", "CLOB", "BLOB"):
        return d
    if d == "NUMBER":
        p, s = c["precision"], c["scale"]
        if p == "":
            return "NUMBER"
        s = s or "0"
        return f"NUMBER({p},{s})" if s != "0" else f"NUMBER({p})"
    return f"{d}({c['char_length']})"


out = []
pt, lt = set(prod), set(local)
out.append(f"운영 테이블 {len(pt)}개 / 로컬 테이블 {len(lt)}개")
out.append(f"운영에만: {sorted(pt - lt)}")
out.append(f"로컬에만: {sorted(lt - pt)}")
out.append("")

total_diff = 0
for tbl in sorted(pt & lt):
    p, l = prod[tbl], local[tbl]
    diffs = []
    if p["comment"] != l["comment"]:
        diffs.append(f"  [테이블코멘트] 운영='{p['comment']}' / 로컬='{l['comment']}'")
    pcols, lcols = list(p["cols"]), list(l["cols"])
    if set(pcols) - set(lcols):
        diffs.append(f"  [운영에만 있는 컬럼] {sorted(set(pcols) - set(lcols))}")
    if set(lcols) - set(pcols):
        diffs.append(f"  [로컬에만 있는 컬럼] {sorted(set(lcols) - set(pcols))}")
    p_order = [c for c in pcols if c in l["cols"]]
    l_order = [c for c in lcols if c in p["cols"]]
    if p_order != l_order:
        diffs.append(f"  [컬럼순서]\n    운영: {p_order}\n    로컬: {l_order}")
    ppk = sorted(c for c in pcols if p["cols"][c]["pk"])
    lpk = sorted(c for c in lcols if l["cols"][c]["pk"])
    if ppk != lpk:
        diffs.append(f"  [PK] 운영={ppk} / 로컬={lpk}")
    for c in p_order:
        pc, lc = p["cols"][c], l["cols"][c]
        sub = []
        if prod_type(pc) != local_type(lc):
            sub.append(f"타입 운영={prod_type(pc)} 로컬={local_type(lc)}")
        if pc["nullable"] != lc["nullable"]:
            sub.append(f"NULL허용 운영={pc['nullable']} 로컬={lc['nullable']}")
        if (pc["default"] or "") != (lc["default"] or ""):
            sub.append(f"DEFAULT 운영={pc['default']} 로컬={lc['default']}")
        if pc["comment"] != lc["comment"]:
            sub.append(f"코멘트 운영='{pc['comment']}' 로컬='{lc['comment']}'")
        if sub:
            diffs.append(f"  [컬럼 {c}] " + " | ".join(sub))
    if diffs:
        total_diff += len(diffs)
        out.append(f"### {tbl}")
        out.extend(diffs)
        out.append("")

out.append(f"총 차이 항목: {total_diff}")
report = "\n".join(out)
with open(OUT, "w", encoding="utf-8") as f:
    f.write(report)
print(f"diff items: {total_diff} -> {OUT}")
