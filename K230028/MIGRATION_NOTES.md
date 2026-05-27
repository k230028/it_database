# 마이그레이션 노트 (운영/main DB 적용 시)

이 문서는 **이미 K230028 옛 스키마(TAAABB / *_TP / TIMESTAMP 등)를 가진 환경**에 본 산출물의 변경을 적용할 때 참고용입니다. 신규 환경이면 `00→04`로 충분.

## 1. 스키마명 변경 (TAAABB → TPRMPP)

이미 main에 적용되어 있을 가능성 큼. 미적용 시:
```sql
BEGIN
  FOR r IN (SELECT table_name FROM user_tables WHERE table_name LIKE 'TAAABB\_%' ESCAPE '\') LOOP
    EXECUTE IMMEDIATE 'ALTER TABLE ' || r.table_name || ' RENAME TO TPRMPP_' || SUBSTR(r.table_name, 8);
  END LOOP;
END;
/
```

## 2. 옛 컬럼 → 새 컬럼 RENAME + 옛 컬럼 DROP

본 작업 패턴 ("COPY+DROP" — 옛/새 둘 다 존재 시):
```sql
-- 예: ASCT_STS → ASCT_STS_C
UPDATE TPRMPP_BASCTM SET ASCT_STS_C = ASCT_STS WHERE ASCT_STS_C IS NULL AND ASCT_STS IS NOT NULL;
ALTER TABLE TPRMPP_BASCTM MODIFY (ASCT_STS NULL);
ALTER TABLE TPRMPP_BASCTM DROP COLUMN ASCT_STS;
```

옛/새 매핑은 `91_change_log.md` §1 참조.

## 3. 데이터타입 변경

| 변경 유형 | 패턴 |
|---|---|
| VARCHAR2(N) 길이 변경 (동일 semantics) | `ALTER TABLE T MODIFY COL VARCHAR2(M ...)` — 데이터 길이 ≤ M이면 OK |
| CHAR ↔ BYTE semantics 변경 | `MODIFY COL VARCHAR2(N BYTE)` — 데이터가 1바이트 문자만이면 OK |
| TIMESTAMP → DATE | Oracle 21c는 데이터 있어도 직접 MODIFY 가능 |
| NUMBER ↔ VARCHAR2 | **임시 컬럼 패턴 필수** (ORA-01439) |

## 4. 컬럼 순서 재배치 (INVISIBLE/VISIBLE 토글)

```sql
-- 1. 모든 컬럼 INVISIBLE (마지막 1개는 ORA-54039로 거부 — 정상)
-- 2. 새 순서대로 VISIBLE
-- 3. INVISIBLE 거부된 컬럼도 토글로 끝으로
```

자세한 스크립트는 PowerShell 자동화 권장. 본 작업에서 사용한 패턴:
- *M: PK → 일반(ABC) → 공통 7컬럼
- *L: 로그 4컬럼 → 대응 *M 순서 → 공통 7컬럼

## 5. PK 인덱스/제약 RENAME

```sql
ALTER INDEX PK_TAAABB_BASCTM_ASCT_ID RENAME TO PK_BASCTM;
ALTER TABLE TPRMPP_BASCTM RENAME CONSTRAINT PK_TAAABB_BASCTM_ASCT_ID TO PK_BASCTM;
```

자동 생성 이름(SYS_C00XXXX)도 동일 패턴.

## 6. *L 테이블 CHG_TC 컬럼 정리

당분간 옛 `CHG_TP`를 사용하는 결정에 따라:
```sql
BEGIN
  FOR r IN (SELECT table_name FROM user_tab_columns WHERE column_name='CHG_TC' AND table_name LIKE 'TPRMPP_%L') LOOP
    EXECUTE IMMEDIATE 'ALTER TABLE ' || r.table_name || ' DROP COLUMN CHG_TC';
  END LOOP;
END;
/
```

## 7. 백엔드 코드 정합 후속 (별도 PR)

본 산출물은 DB만 다룸. 코드 측은 다음 정정이 필요할 수 있음:
- `BaseLogEntity.@Column(name="CHG_TP")` 그대로 유지 (이미 적용)
- 엔티티의 옛 매핑 (`@Column(name="ASCT_STS")` 등) → `_STS_C/_TC/_CONE` 등으로 변경
- 새 컬럼명에 맞춘 native query 정정 (CouncilRepository 등)

## 8. 운영 적용 시 주의
- `00_drop_all.sql`은 운영 환경 사용 금지 (데이터 손실)
- ALTER 작업은 백엔드 정지 상태에서 실행 권장 (lock 충돌 방지)
- 운영 DB 백업 먼저 (`expdp parfile=export.par`)
