#!/usr/bin/env bash
# =====================================================================
# 표준명칭 마이그레이션 검증 하네스 (격리 스키마 ITPAPP_TEST)
#   루트(C:\it)에서 실행:  bash it_database/migrations/test/run_test.sh
#   1) 보고서로 마이그레이션 SQL 재생성
#   2) ITPAPP_TEST 스키마 구축 + 구조 복제
#   3) 엣지케이스 시드
#   4) V001~V004 적용
#   5) 검증(12 PASS 기대)
# =====================================================================
set -e
cd "$(dirname "$0")/../../.."   # -> C:\it
SQLPLUS="/c/app/KDB/product/21c/dbhomeXE/bin/sqlplus.exe"
APP="ITPAPP/kdb1234!!@127.0.0.1:1521/XEPDB1"
TST="ITPAPP_TEST/test1234@127.0.0.1:1521/XEPDB1"
M=it_database/migrations

echo "[1/5] 마이그레이션 SQL 생성"
python "$M/_generate_rename.py"

echo "[2/5] 테스트 스키마 구축"
"$SQLPLUS" -S "$APP" @"$M/test/01_setup.sql" >/dev/null

echo "[3/5] 엣지케이스 시드"
"$SQLPLUS" -S "$TST" @"$M/test/02_seed.sql" >/dev/null

echo "[4/5] 마이그레이션 적용"
for f in V20260602_001__RenameStdColumns V20260602_002__RenameStdColumnsRetype \
         V20260602_003__RetypeStdColumns V20260602_004__DropUnusedColumns; do
  "$SQLPLUS" -S "$TST" @"$M/$f.sql" >/dev/null
done

echo "[5/5] 검증"
OUT=$("$SQLPLUS" -S "$TST" @"$M/test/03_assert.sql" 2>&1)
echo "$OUT"
PASS=$(echo "$OUT" | grep -c "PASS" || true)
FAIL=$(echo "$OUT" | grep -c "FAIL" || true)
echo "----------------------------------------"
echo "PASS=$PASS  FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && echo "RESULT: ALL PASS" || { echo "RESULT: FAILURE"; exit 1; }
