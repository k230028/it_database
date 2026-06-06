// code.csv → code-mapping.reviewed.csv 생성기 (재현 가능, SoT 산출)
// 규칙: 값ID join(현재 code.csv는 행 정렬 정합). TMN_USG는 009/010/011/999로 재번호(병합 충돌 해소).
// 실행: node it_database/migrations/_data/_gen-mapping.mjs
import { readFileSync, writeFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import { dirname, join } from 'node:path'

const here = dirname(fileURLToPath(import.meta.url))
const srcPath = join(here, '..', '..', '..', 'code.csv')
const outPath = join(here, 'code-mapping.reviewed.csv')

// 한 줄을 따옴표 인식하여 필드 배열로 분해
function parseLine(line) {
  const out = []
  let cur = ''
  let inQ = false
  for (let i = 0; i < line.length; i++) {
    const c = line[i]
    if (inQ) {
      if (c === '"') {
        if (line[i + 1] === '"') { cur += '"'; i++ }
        else inQ = false
      } else cur += c
    } else {
      if (c === '"') inQ = true
      else if (c === ',') { out.push(cur); cur = '' }
      else cur += c
    }
  }
  out.push(cur)
  return out
}

const NULLS = new Set(['[NULL]', '', undefined, null])
const norm = (v) => (NULLS.has(v) ? '' : String(v).trim())

// 날짜 'YYYY-MM-DD H:MM:SS' → 'YYYY-MM-DD'
const dateOnly = (v) => {
  const s = norm(v)
  if (!s) return ''
  const m = s.match(/^(\d{4}-\d{2}-\d{2})/)
  return m ? m[1] : s
}

// TMN_USG 재번호 매핑
const TMN_USG_REMAP = { '001': '009', '002': '010', '003': '011', '999': '999' }

const text = readFileSync(srcPath, 'utf8')
const lines = text.split(/\r?\n/).filter((l) => l.length > 0)

// 0,1행은 헤더(기존,,,, / CO_C_ID,...). 데이터는 2행부터
const rows = []
for (let i = 2; i < lines.length; i++) {
  const f = parseLine(lines[i])
  if (f.length < 27) continue
  const oldCid = norm(f[0])
  const oldCdva = norm(f[1])
  if (!oldCid || !oldCdva) continue
  // 우측(변경) 영역: index 14~26
  let newCid = norm(f[14])
  let newCdva = norm(f[15])
  const newStt = dateOnly(f[16])
  const newEnd = dateOnly(f[17])
  const newCoCdvaNm = norm(f[18])
  const newCoCNm = norm(f[19])
  const newCdvaNm = norm(f[20])
  const newSeq = norm(f[21])
  const newHrk = norm(f[26])
  if (!newCid) continue

  // TMN_USG 재번호 적용(병합 충돌 해소)
  if (oldCid === 'TMN_USG') {
    newCdva = TMN_USG_REMAP[oldCdva] ?? newCdva
  }
  const valueChanged = oldCdva !== newCdva ? 'Y' : 'N'
  const cdvaNm = newCdvaNm || newCoCdvaNm
  rows.push([oldCid, oldCdva, newCid, newCdva, cdvaNm, newCoCNm, newSeq, newHrk, newStt, newEnd, valueChanged])
}

const csvEscape = (v) => {
  const s = String(v ?? '')
  return /[",\n]/.test(s) ? '"' + s.replaceAll('"', '""') + '"' : s
}
const header = 'old_cid,old_cdva,new_cid,new_cdva,new_cdva_nm,new_c_nm,new_seq,new_hrk,new_stt,new_end,value_changed'
const body = rows.map((r) => r.map(csvEscape).join(',')).join('\n')
writeFileSync(outPath, header + '\n' + body + '\n', 'utf8')

// 요약 출력
const groups = new Map()
for (const r of rows) groups.set(`${r[0]}->${r[2]}`, (groups.get(`${r[0]}->${r[2]}`) || 0) + 1)
console.error(`rows=${rows.length}, groups=${groups.size}`)
const tmn = rows.filter((r) => r[2] === 'IT_PTL_TMN_SVC_TC').map((r) => r[3]).sort()
console.error('IT_PTL_TMN_SVC_TC cdvas:', tmn.join(','))
const seen = new Set(); let dup = 0
for (const c of tmn) { if (seen.has(c)) dup++; seen.add(c) }
console.error('TMN_SVC dup count:', dup)
