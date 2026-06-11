param(
    [string]$HostName = "127.0.0.1",
    [int]$Port = 11521,
    [string]$ServiceName = "XEPDB1",
    [string]$Username = "ITPAPP",
    [string]$Password = "kdb1234!!",
    # 객체 소유 스키마 — 접속 계정(ITPAPP)과 분리. 전 환경 공통으로 ITPOWN이 객체를 소유한다.
    [string]$Schema = "ITPOWN",
    [string]$OutputPath = (Join-Path $PSScriptRoot "ITPOWN_DDL_live.sql"),
    [ValidateSet("auto", "sqlplus", "sql")]
    [string]$Client = "auto"
)

$ErrorActionPreference = "Stop"

function Get-OracleClient {
    param([string]$RequestedClient)

    if ($RequestedClient -ne "auto") {
        $command = Get-Command $RequestedClient -ErrorAction SilentlyContinue
        if ($null -eq $command) {
            throw "Oracle client '$RequestedClient' was not found. Add sqlplus or SQLcl(sql) to PATH."
        }
        return $command.Source
    }

    foreach ($candidate in @("sqlplus", "sql")) {
        $command = Get-Command $candidate -ErrorAction SilentlyContinue
        if ($null -ne $command) {
            return $command.Source
        }
    }

    throw "Oracle client was not found. Add sqlplus or SQLcl(sql) to PATH."
}

$oracleClient = Get-OracleClient -RequestedClient $Client
$connectString = "$Username/`"$Password`"@$HostName`:$Port/$ServiceName"
$resolvedOutputPath = [System.IO.Path]::GetFullPath($OutputPath)
$tempSqlPath = Join-Path ([System.IO.Path]::GetTempPath()) ("itpapp_export_ddl_{0}.sql" -f ([System.Guid]::NewGuid().ToString("N")))

# 기존 파일을 먼저 제거해서 실패 시 오래된 DDL을 새 결과로 오인하지 않게 합니다.
if (Test-Path -LiteralPath $resolvedOutputPath) {
    Remove-Item -LiteralPath $resolvedOutputPath -Force
}

$escapedOutputPath = $resolvedOutputPath.Replace("\", "\\")
$generatedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz"

$sql = @"
SET ECHO OFF
SET FEEDBACK OFF
SET HEADING OFF
SET LINESIZE 32767
SET LONG 1000000000
SET LONGCHUNKSIZE 32767
SET PAGESIZE 0
SET SERVEROUTPUT ON SIZE UNLIMITED
SET TERMOUT OFF
SET TRIMSPOOL ON
SET VERIFY OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE

SPOOL "$escapedOutputPath"

DECLARE
    v_schema VARCHAR2(128) := UPPER('$Schema');
    v_generated_at VARCHAR2(64) := '$generatedAt';

    PROCEDURE put_line(p_text IN VARCHAR2) IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE(p_text);
    END;

    PROCEDURE put_clob(p_text IN CLOB) IS
        v_offset PLS_INTEGER := 1;
        v_chunk VARCHAR2(32767);
    BEGIN
        IF p_text IS NULL THEN
            RETURN;
        END IF;

        WHILE v_offset <= DBMS_LOB.GETLENGTH(p_text) LOOP
            v_chunk := DBMS_LOB.SUBSTR(p_text, 32767, v_offset);
            DBMS_OUTPUT.PUT_LINE(v_chunk);
            v_offset := v_offset + 32767;
        END LOOP;
    END;

    PROCEDURE print_object_ddl(p_object_type IN VARCHAR2, p_object_name IN VARCHAR2) IS
        v_ddl CLOB;
    BEGIN
        v_ddl := DBMS_METADATA.GET_DDL(p_object_type, p_object_name, v_schema);
        put_clob(v_ddl);
        put_line('');
    EXCEPTION
        WHEN OTHERS THEN
            put_line('-- DDL export failed: ' || p_object_type || ' ' || p_object_name || ' - ' || SQLERRM);
            put_line('');
    END;

    PROCEDURE print_dependent_ddl(p_section IN VARCHAR2, p_metadata_type IN VARCHAR2, p_base_type IN VARCHAR2, p_base_name IN VARCHAR2) IS
        v_ddl CLOB;
    BEGIN
        v_ddl := DBMS_METADATA.GET_DEPENDENT_DDL(p_metadata_type, p_base_name, v_schema);
        put_clob(v_ddl);
        put_line('');
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE NOT IN (-31608, -31603) THEN
                put_line('-- dependent DDL export failed: ' || p_section || ' ' || p_base_type || ' ' || p_base_name || ' - ' || SQLERRM);
                put_line('');
            END IF;
    END;
BEGIN
    DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'SQLTERMINATOR', TRUE);
    DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'PRETTY', TRUE);
    DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'SEGMENT_ATTRIBUTES', FALSE);
    DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'STORAGE', FALSE);
    DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'TABLESPACE', FALSE);
    DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'CONSTRAINTS', TRUE);
    DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'REF_CONSTRAINTS', TRUE);
    DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'CONSTRAINTS_AS_ALTER', FALSE);

    put_line('-- ' || v_schema || ' schema DDL backup (comments included)');
    put_line('-- Generated at: ' || v_generated_at);
    put_line('-- Source: ' || SYS_CONTEXT('USERENV', 'DB_NAME') || '/' || SYS_CONTEXT('USERENV', 'SERVICE_NAME') || ', user=' || v_schema);
    put_line('');
    put_line('-- DBMS_METADATA transform configured');
    put_line('');

    put_line('-- TABLES');
    put_line('');
    FOR item IN (
        SELECT object_name
        FROM all_objects
        WHERE owner = v_schema
          AND object_type = 'TABLE'
          AND object_name NOT LIKE 'BIN$%'
        ORDER BY object_name
    ) LOOP
        print_object_ddl('TABLE', item.object_name);
    END LOOP;

    put_line('-- COMMENTS');
    put_line('');
    FOR item IN (
        SELECT table_name
        FROM all_tables
        WHERE owner = v_schema
          AND table_name NOT LIKE 'BIN$%'
        ORDER BY table_name
    ) LOOP
        print_dependent_ddl('COMMENT', 'COMMENT', 'TABLE', item.table_name);
    END LOOP;

    put_line('-- INDEXES');
    put_line('');
    FOR item IN (
        SELECT index_name
        FROM all_indexes
        WHERE owner = v_schema
          AND generated = 'N'
          AND index_name NOT LIKE 'BIN$%'
          AND (table_owner, index_name) NOT IN (
              SELECT owner, index_name
              FROM all_constraints
              WHERE owner = v_schema
                AND index_name IS NOT NULL
          )
        ORDER BY index_name
    ) LOOP
        print_object_ddl('INDEX', item.index_name);
    END LOOP;

    put_line('-- SEQUENCES');
    put_line('');
    FOR item IN (
        SELECT sequence_name
        FROM all_sequences
        WHERE sequence_owner = v_schema
        ORDER BY sequence_name
    ) LOOP
        print_object_ddl('SEQUENCE', item.sequence_name);
    END LOOP;

    put_line('-- VIEWS');
    put_line('');
    FOR item IN (
        SELECT view_name
        FROM all_views
        WHERE owner = v_schema
        ORDER BY view_name
    ) LOOP
        print_object_ddl('VIEW', item.view_name);
    END LOOP;

    put_line('-- MATERIALIZED VIEWS');
    put_line('');
    FOR item IN (
        SELECT mview_name
        FROM all_mviews
        WHERE owner = v_schema
        ORDER BY mview_name
    ) LOOP
        print_object_ddl('MATERIALIZED_VIEW', item.mview_name);
    END LOOP;

    put_line('-- SYNONYMS');
    put_line('');
    FOR item IN (
        SELECT synonym_name
        FROM all_synonyms
        WHERE owner = v_schema
        ORDER BY synonym_name
    ) LOOP
        print_object_ddl('SYNONYM', item.synonym_name);
    END LOOP;

    put_line('-- TYPES');
    put_line('');
    FOR item IN (
        SELECT object_name
        FROM all_objects
        WHERE owner = v_schema
          AND object_type = 'TYPE'
        ORDER BY object_name
    ) LOOP
        print_object_ddl('TYPE', item.object_name);
    END LOOP;

    put_line('-- PACKAGES');
    put_line('');
    FOR item IN (
        SELECT object_name
        FROM all_objects
        WHERE owner = v_schema
          AND object_type = 'PACKAGE'
        ORDER BY object_name
    ) LOOP
        print_object_ddl('PACKAGE', item.object_name);
    END LOOP;

    put_line('-- PROCEDURES');
    put_line('');
    FOR item IN (
        SELECT object_name
        FROM all_objects
        WHERE owner = v_schema
          AND object_type = 'PROCEDURE'
        ORDER BY object_name
    ) LOOP
        print_object_ddl('PROCEDURE', item.object_name);
    END LOOP;

    put_line('-- FUNCTIONS');
    put_line('');
    FOR item IN (
        SELECT object_name
        FROM all_objects
        WHERE owner = v_schema
          AND object_type = 'FUNCTION'
        ORDER BY object_name
    ) LOOP
        print_object_ddl('FUNCTION', item.object_name);
    END LOOP;

    put_line('-- TRIGGERS');
    put_line('');
    FOR item IN (
        SELECT trigger_name
        FROM all_triggers
        WHERE owner = v_schema
        ORDER BY trigger_name
    ) LOOP
        print_object_ddl('TRIGGER', item.trigger_name);
    END LOOP;
END;
/

SPOOL OFF
EXIT
"@

try {
    [System.IO.File]::WriteAllText($tempSqlPath, $sql, [System.Text.Encoding]::ASCII)

    Write-Host "DDL export started: $Username@$HostName`:$Port/$ServiceName (schema: $Schema)"
    $previousNlsLang = $env:NLS_LANG
    $env:NLS_LANG = "KOREAN_KOREA.AL32UTF8"
    try {
        & $oracleClient -S $connectString "@$tempSqlPath"
    } finally {
        if ($null -eq $previousNlsLang) {
            Remove-Item Env:\NLS_LANG -ErrorAction SilentlyContinue
        } else {
            $env:NLS_LANG = $previousNlsLang
        }
    }
    if ($LASTEXITCODE -ne 0) {
        throw "Oracle client returned exit code $LASTEXITCODE during DDL export."
    }

    if (-not (Test-Path -LiteralPath $resolvedOutputPath)) {
        throw "DDL output file was not created: $resolvedOutputPath"
    }

    # VSCode와 Windows PowerShell 5가 인코딩을 오인하지 않도록 UTF-8 BOM을 보장합니다.
    $outputBytes = [System.IO.File]::ReadAllBytes($resolvedOutputPath)
    $hasBom = $outputBytes.Length -ge 3 -and $outputBytes[0] -eq 0xEF -and $outputBytes[1] -eq 0xBB -and $outputBytes[2] -eq 0xBF
    if (-not $hasBom) {
        $bomBytes = [byte[]](0xEF, 0xBB, 0xBF)
        [System.IO.File]::WriteAllBytes($resolvedOutputPath, $bomBytes + $outputBytes)
    }

    Write-Host "DDL export completed: $resolvedOutputPath"
} finally {
    if (Test-Path -LiteralPath $tempSqlPath) {
        Remove-Item -LiteralPath $tempSqlPath -Force
    }
}
