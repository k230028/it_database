
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

기본 접속 대상은 `ITPAPP@127.0.0.1:1521/XEPDB1`이며, Spring Boot 개발 설정과 동일합니다.

#### VARCHAR2 4000자 초과 사용 설정(MAX_STRING_SIZE=EXTENDED)
`VARCHAR2(4000)`을 초과하는 컬럼(예: `VARCHAR2(6000 CHAR)`)을 사용하려면 Oracle DB 전체 설정을 `MAX_STRING_SIZE=EXTENDED`로 전환해야 합니다.
이 작업은 SYSDBA 권한과 DB 재기동이 필요하며, 전환 후 `STANDARD`로 되돌릴 수 없으므로 로컬 개발 DB 또는 DBA 승인된 환경에서만 수행합니다.

현재 설정을 확인합니다.
```sql
SQL> sqlplus / as sysdba

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
```bash
SQL> CREATE USER ITPAPP IDENTIFIED BY "kdb1234!!";

사용자가 생성되었습니다.

SQL> GRANT CONNECT, RESOURCE, DBA TO ITPAPP;
```

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

# 2. 가져오기
C:\it>impdp parfile=.\it_database\import.par

## 2.1 데이티만 가져오기
C:\it>impdp parfile=.\it_database\import_data_only.par

## 2.2 스키마만 가져오기
C:\it>.\it_database\apply-ddl-live.ps1 -DropExisting -StripCollation

# 3. 내보내기
C:\it>expdp parfile=.\it_database\export.par

## 3.1 라이브 DDL 새로 생성
아래 명령은 현재 `ITPAPP` 스키마의 전체 DDL을 조회해 `ITPAPP_DDL_live.sql`을 매번 새로 생성합니다.

```powershell
C:\it>.\it_database\export-ddl-live.ps1
```

접속 정보가 다른 경우 인자로 오버라이드합니다.

```powershell
C:\it>.\it_database\export-ddl-live.ps1 -HostName 127.0.0.1 -Port 1521 -ServiceName XEPDB1 -Username ITPAPP -Password "kdb1234!!"
```
