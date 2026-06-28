
# 1. 데이터베이스 사전 세팅

#### DB 설치
Oracle Database 21c Express Edition
https://www.oracle.com/kr/database/technologies/xe-downloads.html

#### DB 접속 및 버전 확인
```bash
C:\Users\gonna>sqlplus / as sysdba

SQL*Plus: Release 21.0.0.0.0 - Production on 일 1월 18 23:14:07 2026
Version 21.3.0.0.0

Copyright (c) 1982, 2021, Oracle.  All rights reserved.


다음에 접속됨:
Oracle Database 21c Express Edition Release 21.0.0.0.0 - Production
Version 21.3.0.0.0
```

#### 애플리케이션 계정 접속
```powershell
C:\it>.\it_database\connect-db.ps1
```

cmd.exe 환경에서는 아래 배치 래퍼를 사용할 수 있습니다.
```bat
C:\it>.\it_database\connect-db.bat
```

기본 접속 대상은 `ITPAPP@127.0.0.1:11521/XEPDB1`이며, Spring Boot 개발 설정과 동일합니다.

> **스키마 분리 (전 환경 공통)**: 접속 계정은 `ITPAPP`, 테이블/시퀀스 소유 스키마는 `ITPOWN`입니다.
> 수동 SQL에서 ITPOWN 객체를 다루려면 접속 후 `ALTER SESSION SET CURRENT_SCHEMA = ITPOWN;`을 실행하거나
> `ITPOWN.테이블명`으로 접근합니다. (애플리케이션은 HikariCP `connection-init-sql`이 자동 전환)

#### VARCHAR2 4000자 초과 사용 설정(MAX_STRING_SIZE=EXTENDED)
`VARCHAR2(4000)`을 초과하는 컬럼(예: `VARCHAR2(6000 CHAR)`)을 사용하려면 Oracle DB 전체 설정을 `MAX_STRING_SIZE=EXTENDED`로 전환해야 합니다.
이 작업은 SYSDBA 권한과 DB 재기동이 필요하며, 전환 후 `STANDARD`로 되돌릴 수 없으므로 로컬 개발 DB 또는 DBA 승인된 환경에서만 수행합니다.

현재 설정을 확인합니다.
```sql
C:\Users\KDB> sqlplus / as sysdba

SQL> SELECT name, value FROM v$parameter WHERE name = 'max_string_size';
SQL> SELECT name, open_mode FROM v$pdbs;
```

CDB 루트에서 SPFILE 설정을 변경하고 upgrade 모드로 재기동합니다.
```sql
SQL> ALTER SYSTEM SET max_string_size = EXTENDED SCOPE = SPFILE;
SQL> SHUTDOWN IMMEDIATE;
SQL> STARTUP UPGRADE;
SQL> ALTER PLUGGABLE DATABASE XEPDB1 OPEN UPGRADE;
SQL> ALTER SESSION SET CONTAINER = XEPDB1;
SQL> @?/rdbms/admin/utl32k.sql
```

`utl32k.sql` 실행이 끝나면 CDB 루트로 돌아가 정상 모드로 재기동합니다.
```sql
SQL> ALTER SESSION SET CONTAINER = CDB$ROOT;
SQL> SHUTDOWN IMMEDIATE;
SQL> STARTUP;
SQL> ALTER PLUGGABLE DATABASE ALL OPEN;
```

전환 결과를 확인합니다.
```sql
SQL> ALTER SESSION SET CONTAINER = XEPDB1;
SQL> SELECT name, value FROM v$parameter WHERE name = 'max_string_size';

NAME             VALUE
---------------- --------
max_string_size  EXTENDED
```

전환 후 `utl32k.sql`이 긴 문자열 인덱스를 `UNUSABLE` 상태로 만들 수 있으므로 반드시 점검합니다.
```sql
SQL> SELECT owner, index_name, table_name, status
     FROM dba_indexes
     WHERE owner = 'ITPAPP'
       AND status <> 'VALID'
     ORDER BY table_name, index_name;
```

키 길이 초과로 재빌드가 불가능한 비고유 보조 인덱스는 삭제 후, 필요 시 prefix/function-based/hash 컬럼 인덱스로 재설계합니다.

#### PDB 또는 CDB 여부 확인 후 PDB가 아닌 경우 PDB로 전환
```bash
SQL> SHOW CON_NAME;

CON_NAME
------------------------------
CDB$ROOT

SQL> SELECT name, open_mode FROM v$pdbs;

NAME
--------------------------------------------------------------------------------
OPEN_MODE
--------------------
PDB$SEED
READ ONLY

XEPDB1
READ WRITE

SQL> ALTER SESSION SET CONTAINER = XEPDB1;

세션이 변경되었습니다.

SQL> SHOW CON_NAME;

CON_NAME
------------------------------
XEPDB1

SQL> ALTER SESSION SET "_ORACLE_SCRIPT" = true;

세션이 변경되었습니다.
```

#### 스키마가 없는 경우 스키마 생성
접속 계정(`ITPAPP`)과 객체 소유 스키마(`ITPOWN`)를 모두 생성합니다.
```bash
SQL> ALTER SESSION SET CONTAINER = XEPDB1;

SQL> CREATE USER ITPAPP IDENTIFIED BY "kdb1234!!";

사용자가 생성되었습니다.

SQL> GRANT CONNECT, RESOURCE, DBA TO ITPAPP;

SQL> CREATE USER ITPOWN IDENTIFIED BY "kdb1234!!";

사용자가 생성되었습니다.

SQL> GRANT CONNECT, RESOURCE TO ITPOWN;
SQL> ALTER USER ITPOWN QUOTA UNLIMITED ON USERS;
```
운영처럼 ITPAPP에 DBA를 주지 않는 환경에서는 ITPOWN 객체에 대한
`SELECT/INSERT/UPDATE/DELETE`(테이블·뷰)와 `SELECT`(시퀀스) 권한을 ITPAPP에 부여해야 합니다.

#### dump 디렉토리 설정 및 권한 부여
```bash
SQL> SELECT directory_name, directory_path FROM dba_directories WHERE directory_name = 'MY_DUMP_DIR';

선택된 레코드가 없습니다.

SQL> CREATE OR REPLACE DIRECTORY my_dump_dir AS 'C:\it\it_database';

디렉토리가 생성되었습니다.

SQL> SELECT directory_name, directory_path FROM dba_directories WHERE directory_name = 'MY_DUMP_DIR';

DIRECTORY_NAME
--------------------------------------------------------------------------------
DIRECTORY_PATH
--------------------------------------------------------------------------------
MY_DUMP_DIR
C:\it\it_database

SQL> GRANT READ, WRITE ON DIRECTORY MY_DUMP_DIR TO ITPAPP;

권한이 부여되었습니다.
```

# 3. 리스너 포트 변경 가이드 (예: 1521 → 11521)

기본 리스너 포트(1521)를 다른 포트로 변경하는 절차입니다. DB 쪽 변경과 애플리케이션 설정 변경을 모두 수행해야 합니다.

#### 사전 확인: 대상 포트 사용 여부
```powershell
netstat -ano | findstr :11521
```
출력이 없으면 해당 포트는 사용 가능합니다.

#### 3.1 listener.ora 수정
파일 위치는 `lsnrctl status` 출력의 "리스너 매개변수 파일" 항목으로 확인합니다.
Oracle 21c는 read-only Oracle Home 구조이므로 네트워크 설정이 `dbhomeXE\network\admin`이 아니라
`C:\app\KDB\product\21c\homes\OraDB21Home1\network\admin\listener.ora`에 있습니다. (`dbhomeXE` 쪽에 파일을 만들어도 리스너가 읽지 않습니다.)

```
LISTENER =
  (DESCRIPTION_LIST =
    (DESCRIPTION =
      (ADDRESS = (PROTOCOL = TCP)(HOST = localhost)(PORT = 11521))
      (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1521))
    )
  )
```

같은 디렉토리의 `tnsnames.ora`에 `PORT = 1521`이 있으면 함께 수정합니다.

#### 3.2 리스너 재시작
관리자 권한 터미널에서 실행합니다.
```powershell
lsnrctl stop
lsnrctl start
```
또는 Windows 서비스(`OracleOraDB21Home1TNSListener`, 환경에 따라 이름이 다를 수 있음)를 재시작합니다.

#### 3.3 LOCAL_LISTENER 설정 및 서비스 등록
리스너가 기본 포트(1521)가 아니면 DB가 리스너에 자동 등록되지 않으므로 SYSDBA로 설정합니다.
```sql
C:\Users\KDB> sqlplus / as sysdba

SQL> ALTER SYSTEM SET LOCAL_LISTENER='(ADDRESS=(PROTOCOL=TCP)(HOST=localhost)(PORT=11521))' SCOPE=BOTH;
SQL> ALTER SYSTEM REGISTER;
```

#### 3.4 변경 확인
```powershell
lsnrctl status
```
출력에서 `PORT=11521`과 `Service "xepdb1"` 등록을 확인합니다. 서비스가 보이지 않으면 1~2분 대기 후 `ALTER SYSTEM REGISTER;`를 다시 실행합니다.

접속 테스트:
```powershell
C:\it>.\it_database\connect-db.ps1 -Port 11521
```

#### 3.5 애플리케이션 설정 변경
포트를 변경하면 저장소에서 1521을 참조하는 곳도 함께 수정해야 합니다.

| 대상 | 위치 | 변경 내용 |
|------|------|----------|
| 백엔드 datasource | `it_backend/src/main/resources/application.properties` | `jdbc:oracle:thin:@127.0.0.1:1521/XEPDB1`의 포트 |
| DB 접속 스크립트 | `it_database/connect-db.ps1` | 기본 `-Port` 값 (수정 없이 `-Port 11521` 오버라이드도 가능) |
| 문서 | 루트 `CLAUDE.md`, `AGENTS.md`, `README.md` | 접속 정보 표기 (`127.0.0.1:1521/XEPDB1`) |



# 2. 가져오기
```powershell
C:\it>impdp parfile=.\it_database\import.par
```

## 2.1 스키마만 가져오기
```powershell
C:\it>.\it_database\apply-ddl-live.ps1 -DropExisting -StripCollation
```

## 2.2 데이터만 가져오기
```powershell
C:\it>impdp parfile=.\it_database\import_data_only.par
```

## 2.3 Flyway 마이그레이션
로컬 증분 DDL/DML 변경은 Spring Boot 백엔드의 `local-ext`/`local-int` 프로파일 기동 시 Flyway가 적용합니다.
`dev`/`prod` DB는 DBA가 마이그레이션 스크립트를 검토하고 수동 적용합니다.
백엔드 Gradle `processResources`가 이 디렉토리의 `migrations/V*.sql` 파일을
`classpath:db/migration`으로 복사하고, 애플리케이션이 시작될 때 신규 버전만 실행합니다.

```text
it_database/migrations/V{YYYYMMDD_NNN}__{CamelCaseDescription}.sql
```

- 기존 non-empty 로컬 `ITPOWN` 스키마는 `baseline-version=20260620.001`로 기준선을 등록하고 이후 신규 스크립트부터 적용합니다.
- 빈 스키마는 `migrations/`의 전체 V* 스크립트를 버전 순서대로 적용합니다.
- 운영처럼 애플리케이션 계정(`ITPAPP`)에 DDL 권한을 주지 않는 환경은 백엔드 실행 시 `FLYWAY_USER`/`FLYWAY_PASSWORD`에 DDL 권한 계정을 지정합니다.
- 이미 적용된 스크립트는 Flyway 체크섬 추적 대상이므로 수정하지 않습니다. 변경이 필요하면 새 버전 파일을 추가합니다.
- `apply-ddl-live.ps1`은 스키마 부트스트랩/수동 재생성용 도구이며, 평상시 증분 변경 경로는 Flyway입니다.

# 4. 내보내기
```powershell
C:\it>expdp parfile=.\it_database\export.par
```

## 4.1 스키마만 내보내기
아래 명령은 현재 `ITPOWN` 스키마의 전체 DDL을 조회해 `ITPOWN_DDL_live.sql`을 매번 새로 생성합니다.
(접속은 `ITPAPP`, 대상 스키마는 `-Schema` 파라미터로 오버라이드 가능)

```powershell
C:\it>.\it_database\export-ddl-live.ps1
```