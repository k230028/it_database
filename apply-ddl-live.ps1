param(
    [string]$HostName = "127.0.0.1",
    [int]$Port = 1521,
    [string]$ServiceName = "XEPDB1",
    [string]$Username = "ITPAPP",
    [string]$Password = "kdb1234!!",
    [string]$DdlPath = (Join-Path $PSScriptRoot "ITPAPP_DDL_live.sql"),
    [string]$LogPath = (Join-Path $PSScriptRoot "apply-ddl-live.log"),
    [ValidateSet("auto", "sqlplus", "sql")]
    [string]$Client = "auto",
    [string]$NlsLang = "KOREAN_KOREA.AL32UTF8",
    [switch]$DropExisting,
    [switch]$StripCollation,
    [switch]$SkipComments
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

function Convert-ToSqlPath {
    param([string]$Path)

    return [System.IO.Path]::GetFullPath($Path).Replace("\", "/")
}

function Write-Utf8NoBomFile {
    param(
        [string]$Path,
        [string]$Value
    )

    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Value, $encoding)
}

function Read-Utf8File {
    param([string]$Path)

    $encoding = New-Object System.Text.UTF8Encoding($false, $true)
    return [System.IO.File]::ReadAllText($Path, $encoding)
}

function Split-InlineForeignKeys {
    param([string]$DdlText)

    $lines = $DdlText -split "\r?\n"
    $outputLines = New-Object System.Collections.Generic.List[string]
    $foreignKeyStatements = New-Object System.Collections.Generic.List[string]
    $currentTable = $null
    $skipForeignKey = $false
    $foreignKeyLines = New-Object System.Collections.Generic.List[string]

    foreach ($line in $lines) {
        if ($line -match 'CREATE\s+TABLE\s+"[^"]+"\."(?<table>[^"]+)"') {
            $currentTable = $matches.table
        }

        if (-not $skipForeignKey -and $currentTable -and $line -match 'CONSTRAINT\s+"[^"]+"\s+FOREIGN\s+KEY') {
            if ($outputLines.Count -gt 0) {
                $lastLineIndex = $outputLines.Count - 1
                $outputLines[$lastLineIndex] = $outputLines[$lastLineIndex] -replace ',\s*$', ''
            }

            $skipForeignKey = $true
            $foreignKeyLines.Clear()
            $foreignKeyLines.Add(($line -replace '^\s*,?\s*', '').TrimEnd())
            continue
        }

        if ($skipForeignKey) {
            $foreignKeyLines.Add($line.TrimEnd())

            if ($line -match '\bENABLE\b') {
                $statement = "ALTER TABLE ""$Username"".""$currentTable"" ADD " + (($foreignKeyLines | ForEach-Object { $_.Trim() }) -join [Environment]::NewLine) + ";"
                $foreignKeyStatements.Add($statement)
                $skipForeignKey = $false
            }

            continue
        }

        if ($line -match '^\s*\)\s*.*;\s*$') {
            $currentTable = $null
        }

        $outputLines.Add($line)
    }

    if ($foreignKeyStatements.Count -eq 0) {
        return $DdlText
    }

    return (($outputLines -join [Environment]::NewLine) +
        [Environment]::NewLine +
        [Environment]::NewLine +
        "-- FOREIGN KEYS" +
        [Environment]::NewLine +
        ($foreignKeyStatements -join ([Environment]::NewLine + [Environment]::NewLine)) +
        [Environment]::NewLine)
}

function Remove-CommentStatements {
    param([string]$DdlText)

    $pattern = '(?ms)^\s*COMMENT\s+ON\s+(?:COLUMN|TABLE)\s+.*?;\s*$'
    return [System.Text.RegularExpressions.Regex]::Replace($DdlText, $pattern, '')
}

if (-not (Test-Path -LiteralPath $DdlPath)) {
    throw "DDL file was not found: $DdlPath"
}

$oracleClient = Get-OracleClient -RequestedClient $Client
$resolvedLogPath = Convert-ToSqlPath -Path $LogPath
$tempSqlPath = Join-Path ([System.IO.Path]::GetTempPath()) ("itpapp_apply_ddl_{0}.sql" -f ([System.Guid]::NewGuid().ToString("N")))
$tempDdlPath = Join-Path ([System.IO.Path]::GetTempPath()) ("itpapp_ddl_live_{0}.sql" -f ([System.Guid]::NewGuid().ToString("N")))
$resolvedDdlPath = Convert-ToSqlPath -Path $tempDdlPath
$connectString = "$Username/`"$Password`"@$HostName`:$Port/$ServiceName"
$dropBlock = ""
$sourceDdlText = Read-Utf8File -Path ([System.IO.Path]::GetFullPath($DdlPath))
$applyDdlText = $sourceDdlText

if ($StripCollation) {
    $applyDdlText = [System.Text.RegularExpressions.Regex]::Replace(
        $applyDdlText,
        '\s+DEFAULT\s+COLLATION\s+"[^"]+"',
        '',
        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
    )
    $applyDdlText = [System.Text.RegularExpressions.Regex]::Replace(
        $applyDdlText,
        '\s+COLLATE\s+"[^"]+"',
        '',
        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
    )
}

if ($SkipComments) {
    $applyDdlText = Remove-CommentStatements -DdlText $applyDdlText
}

$applyDdlText = Split-InlineForeignKeys -DdlText $applyDdlText
$requiresExtendedStringSize = $sourceDdlText -match '\bCOLLATE\b'

if ($DropExisting) {
    $dropBlock = @"
PROMPT Dropping existing objects in $Username

DECLARE
    PROCEDURE drop_object(p_sql IN VARCHAR2) IS
    BEGIN
        EXECUTE IMMEDIATE p_sql;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('DROP skipped: ' || p_sql || ' - ' || SQLERRM);
    END;
BEGIN
    FOR item IN (
        SELECT object_type, object_name
        FROM user_objects
        WHERE object_name NOT LIKE 'BIN$%'
          AND object_type IN (
              'VIEW',
              'MATERIALIZED VIEW',
              'TRIGGER',
              'PACKAGE',
              'PROCEDURE',
              'FUNCTION',
              'TYPE',
              'SEQUENCE',
              'SYNONYM',
              'TABLE'
          )
        ORDER BY CASE object_type
            WHEN 'VIEW' THEN 1
            WHEN 'MATERIALIZED VIEW' THEN 2
            WHEN 'TRIGGER' THEN 3
            WHEN 'PACKAGE' THEN 4
            WHEN 'PROCEDURE' THEN 5
            WHEN 'FUNCTION' THEN 6
            WHEN 'TYPE' THEN 7
            WHEN 'SEQUENCE' THEN 8
            WHEN 'SYNONYM' THEN 9
            WHEN 'TABLE' THEN 10
            ELSE 99
        END
    ) LOOP
        IF item.object_type = 'TABLE' THEN
            drop_object('DROP TABLE "' || item.object_name || '" CASCADE CONSTRAINTS PURGE');
        ELSE
            drop_object('DROP ' || item.object_type || ' "' || item.object_name || '"');
        END IF;
    END LOOP;
END;
/

PURGE RECYCLEBIN;

"@
}

$maxStringSizeCheck = ""
if ($requiresExtendedStringSize -and -not $StripCollation) {
    $maxStringSizeCheck = @"
PROMPT Checking MAX_STRING_SIZE for COLLATE clauses

DECLARE
    v_max_string_size VARCHAR2(128) := 'UNKNOWN';
BEGIN
    BEGIN
        SELECT property_value
        INTO v_max_string_size
        FROM database_properties
        WHERE property_name = 'MAX_STRING_SIZE';
    EXCEPTION
        WHEN OTHERS THEN
            BEGIN
                SELECT value
                INTO v_max_string_size
                FROM v`$parameter
                WHERE name = 'max_string_size';
            EXCEPTION
                WHEN OTHERS THEN
                    v_max_string_size := 'UNKNOWN';
            END;
    END;

    DBMS_OUTPUT.PUT_LINE('MAX_STRING_SIZE=' || v_max_string_size);

    IF UPPER(v_max_string_size) <> 'EXTENDED' THEN
        RAISE_APPLICATION_ERROR(
            -20000,
            'ITPAPP_DDL_live.sql contains COLLATE clauses. Set Oracle MAX_STRING_SIZE=EXTENDED before applying this DDL.'
        );
    END IF;
END;
/

"@
}

$sql = @"
SET ECHO ON
SET FEEDBACK ON
SET HEADING ON
SET LINESIZE 32767
SET LONG 1000000000
SET LONGCHUNKSIZE 32767
SET PAGESIZE 50000
SET SERVEROUTPUT ON SIZE UNLIMITED
SET TERMOUT ON
SET TIMING ON
SET TRIMSPOOL ON
SET VERIFY OFF
WHENEVER OSERROR EXIT FAILURE
WHENEVER SQLERROR EXIT SQL.SQLCODE

SPOOL "$resolvedLogPath"

PROMPT Applying DDL file: $resolvedDdlPath
PROMPT Target schema: $Username@$HostName`:$Port/$ServiceName

ALTER SESSION SET CURRENT_SCHEMA = "$Username";

$maxStringSizeCheck
$dropBlock
@"$resolvedDdlPath"

PROMPT DDL apply completed.

SPOOL OFF
EXIT SUCCESS
"@

try {
    Write-Utf8NoBomFile -Path $tempDdlPath -Value $applyDdlText
    Write-Utf8NoBomFile -Path $tempSqlPath -Value $sql

    Write-Host "Oracle client: $oracleClient"
    Write-Host "DDL file: $(Convert-ToSqlPath -Path $DdlPath)"
    Write-Host "Log file: $resolvedLogPath"
    Write-Host "NLS_LANG: $NlsLang"
    if ($DropExisting) {
        Write-Host "DropExisting: enabled"
    }
    if ($StripCollation) {
        Write-Host "StripCollation: enabled"
    }
    if ($SkipComments) {
        Write-Host "SkipComments: enabled"
    }

    $previousNlsLang = $env:NLS_LANG
    $env:NLS_LANG = $NlsLang
    & $oracleClient -L -S $connectString "@$tempSqlPath"
    if ($LASTEXITCODE -ne 0) {
        throw "DDL apply failed. Check log: $resolvedLogPath"
    }
}
finally {
    if (Get-Variable -Name previousNlsLang -Scope Local -ErrorAction SilentlyContinue) {
        $env:NLS_LANG = $previousNlsLang
    }
    if (Test-Path -LiteralPath $tempSqlPath) {
        Remove-Item -LiteralPath $tempSqlPath -Force
    }
    if (Test-Path -LiteralPath $tempDdlPath) {
        Remove-Item -LiteralPath $tempDdlPath -Force
    }
}
