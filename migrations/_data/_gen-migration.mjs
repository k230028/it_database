// code.csv → V20260606_001__MigrateCommonCodes.sql 생성기 (전체 컬럼 보존)
// 신규측 13컬럼(임계금액 CO_CDVA_NM, 정렬 C_SQN_SNO, 계층 HRK 포함)을 그대로 INSERT.
// TMN_USG는 CDVA_ID를 009/010/011/999로 재번호(병합 충돌 해소).
// 실행: node it_database/migrations/_data/_gen-migration.mjs
import { readFileSync, writeFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import { dirname, join } from 'node:path'

const here = dirname(fileURLToPath(import.meta.url))
const srcPath = join(here, '..', '..', '..', 'code.csv')
const outPath = join(here, '..', 'V20260606_001__MigrateCommonCodes.sql')

function parseLine(line) {
  const out = []; let cur = ''; let inQ = false
  for (let i = 0; i < line.length; i++) {
    const c = line[i]
    if (inQ) { if (c === '"') { if (line[i + 1] === '"') { cur += '"'; i++ } else inQ = false } else cur += c }
    else { if (c === '"') inQ = true; else if (c === ',') { out.push(cur); cur = '' } else cur += c }
  }
  out.push(cur); return out
}
const NULLS = new Set(['[NULL]', '', undefined, null])
const norm = (v) => (NULLS.has(v) ? '' : String(v).trim())
const dateOnly = (v) => { const s = norm(v); if (!s) return ''; const m = s.match(/^(\d{4}-\d{2}-\d{2})/); return m ? m[1] : s }
const sq = (v) => { const s = norm(v); return s === '' ? 'NULL' : `'${s.replaceAll("'", "''")}'` }
const sqDate = (v) => { const s = dateOnly(v); return s === '' ? 'NULL' : `DATE '${s}'` }
const sqNum = (v) => { const s = norm(v); return s === '' ? 'NULL' : (s.replace(/[^0-9.]/g, '') || 'NULL') }

const TMN_USG_REMAP = { '001': '009', '002': '010', '003': '011', '999': '999' }

const text = readFileSync(srcPath, 'utf8')
const lines = text.split(/\r?\n/).filter((l) => l.length > 0)

const inserts = []
const oldCids = new Set(); const newCids = new Set()
for (let i = 2; i < lines.length; i++) {
  const f = parseLine(lines[i])
  if (f.length < 27) continue
  const oldCid = norm(f[0]); const oldCdva = norm(f[1])
  if (!oldCid || !oldCdva) continue
  const newCid = norm(f[14]); if (!newCid) continue
  let newCdva = norm(f[15])
  if (oldCid === 'TMN_USG') newCdva = TMN_USG_REMAP[oldCdva] ?? newCdva
  oldCids.add(oldCid); newCids.add(newCid)
  const vals = [
    sq(newCid), sq(newCdva), sqDate(f[16]), sqDate(f[17]),
    sq(f[18]), sq(f[19]), sq(f[20]), sqNum(f[21]),
    sq(f[22]), sq(f[23]), sq(f[24]), sq(f[25]), sq(f[26]),
    "'MIGRATION'", 'SYSDATE', "'N'",
  ]
  inserts.push(
    `INSERT INTO ITPAPP.TPRMPP_CCODEM (CO_C_ID,CDVA_ID,STT_DTM,END_DTM,CO_CDVA_NM,CO_C_NM,CDVA_NM,C_SQN_SNO,CO_C_INTN_NM,CO_C_INTN_CONE,CO_CDVA_ABV_NM,CO_CDVA_SPS,HRK_CDVA_ID,FST_ENR_USID,FST_ENR_DTM,DEL_YN) VALUES (${vals.join(',')});`
  )
}

const affected = [...new Set([...oldCids, ...newCids])].sort()
const inList = affected.map((g) => `'${g}'`).join(',')

const sql = `-- V20260606_001__MigrateCommonCodes.sql
-- [자동생성: _data/_gen-migration.mjs] 공통코드 그룹ID/값ID 신규 체계 재적재.
-- 멱등: 영향 그룹 전체 DELETE 후 재INSERT. FST_ENR_USID='MIGRATION' 표식.
-- 신규측 전체 컬럼(임계금액 CO_CDVA_NM, 정렬 C_SQN_SNO, 계층 HRK 포함) 보존.

-- 1) 백업 (이미 있으면 건너뜀)
DECLARE v NUMBER;
BEGIN
  SELECT COUNT(*) INTO v FROM USER_TABLES WHERE TABLE_NAME='TPRMPP_CCODEM_BAK_20260606';
  IF v=0 THEN
    EXECUTE IMMEDIATE 'CREATE TABLE ITPAPP.TPRMPP_CCODEM_BAK_20260606 AS SELECT * FROM ITPAPP.TPRMPP_CCODEM';
  END IF;
END;
/

-- 2) 영향 old+new 그룹 제거(재실행 대비 클린 슬레이트)
DELETE FROM ITPAPP.TPRMPP_CCODEM WHERE CO_C_ID IN (${inList});

-- 3) 신규 목표 상태 재적재 (${inserts.length}행)
${inserts.join('\n')}

-- 4) 변경 스냅샷(감사) — CCODEL
INSERT INTO ITPAPP.TPRMPP_CCODEL
  (LOG_HIS_TGR_SNO, CO_C_ID, CDVA_ID, STT_DTM, END_DTM, CO_CDVA_NM, CO_C_NM, CDVA_NM, C_SQN_SNO, HRK_CDVA_ID, CHG_DTT_YN, CHG_DTM, CHG_USID, DEL_YN)
SELECT ITPAPP.SEQ_CCODEL.NEXTVAL, CO_C_ID, CDVA_ID, STT_DTM, END_DTM, CO_CDVA_NM, CO_C_NM, CDVA_NM, C_SQN_SNO, HRK_CDVA_ID, 'Y', SYSDATE, 'MIGRATION', 'N'
FROM ITPAPP.TPRMPP_CCODEM WHERE FST_ENR_USID='MIGRATION';

COMMIT;
`
writeFileSync(outPath, sql, 'utf8')
console.error(`inserts=${inserts.length}, affectedGroups=${affected.length}`)
console.error('affected:', affected.join(','))
