<#
.SYNOPSIS
IT Portal 로컬 Oracle DB 에 dml 디렉토리의 모든 SQL 을 일괄 반영합니다.

.DESCRIPTION
스크립트가 위치한 디렉토리(C:\it\it_database\dml)의 모든 *.sql 파일을 파일명
오름차순으로 정렬해 단일 SQL*Plus / SQLcl 세션에서 순차 실행합니다.

  - 1 세션으로 처리하여 접속 오버헤드 최소화
  - 일부 파일에서 오류가 나도 계속 진행 (WHENEVER SQLERROR CONTINUE)
  - 끝에서 COMMIT 수행
  - 임시 마스터 SQL 파일은 실행 후 자동 삭제

.PARAMETER HostName
DB 호스트. 기본 127.0.0.1

.PARAMETER Port
DB 포트. 기본 1521

.PARAMETER ServiceName
서비스명. 기본 XEPDB1

.PARAMETER Username
접속 계정. 기본 ITPAPP

.PARAMETER Password
접속 비밀번호. 기본 kdb1234!!

.PARAMETER Client
auto / sqlplus / sql. 기본 auto (sqlplus 우선)

.PARAMETER LogFile
실행 로그를 기록할 파일 경로. 미지정 시 콘솔 출력만.

.EXAMPLE
  .\apply-all.ps1
  .\apply-all.ps1 -LogFile .\apply-all.log
#>
[CmdletBinding()]
param(
    [string]$HostName    = "127.0.0.1",
    [int]   $Port        = 1521,
    [string]$ServiceName = "XEPDB1",
    [string]$Username    = "ITPAPP",
    [string]$Password    = "kdb1234!!",
    [ValidateSet("auto", "sqlplus", "sql")]
    [string]$Client      = "auto",
    [string]$LogFile
)

$ErrorActionPreference = "Stop"

function Resolve-OracleClient {
    param([string]$PreferredClient)
    $candidates = if ($PreferredClient -eq "auto") { @("sqlplus", "sql") } else { @($PreferredClient) }
    foreach ($c in $candidates) {
        $cmd = Get-Command $c -ErrorAction SilentlyContinue
        if ($null -ne $cmd) { return $cmd }
    }
    throw "Oracle 접속 클라이언트를 찾을 수 없습니다. SQL*Plus(sqlplus) 또는 SQLcl(sql)을 PATH에 추가하세요."
}

$dmlDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$sqlFiles = Get-ChildItem -Path $dmlDir -Filter "*.sql" -File |
            Where-Object { $_.Name -ne "_apply-all.master.sql" } |
            Sort-Object Name

if ($sqlFiles.Count -eq 0) {
    Write-Warning "반영할 *.sql 파일이 없습니다: $dmlDir"
    exit 0
}

$oracleClient      = Resolve-OracleClient -PreferredClient $Client
$connectIdentifier = "${HostName}:${Port}/${ServiceName}"
$connectString     = "${Username}/${Password}@${connectIdentifier}"

$master = Join-Path $dmlDir "_apply-all.master.sql"

# 마스터 스크립트 작성 (UTF-8, BOM 없음)
$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("-- 자동 생성된 마스터 스크립트. apply-all.ps1 종료 시 삭제됩니다.")
[void]$sb.AppendLine("SET DEFINE OFF")
[void]$sb.AppendLine("SET ECHO OFF")
[void]$sb.AppendLine("SET FEEDBACK OFF")
[void]$sb.AppendLine("SET SERVEROUTPUT ON SIZE UNLIMITED")
[void]$sb.AppendLine("WHENEVER SQLERROR CONTINUE")
[void]$sb.AppendLine("WHENEVER OSERROR  CONTINUE")
[void]$sb.AppendLine("ALTER SESSION SET NLS_LANGUAGE = 'KOREAN' NLS_TERRITORY = 'KOREA';")
foreach ($f in $sqlFiles) {
    [void]$sb.AppendLine("PROMPT >>> $($f.Name)")
    [void]$sb.AppendLine("@@`"$($f.Name)`"")
}
[void]$sb.AppendLine("COMMIT;")
[void]$sb.AppendLine("PROMPT === apply-all 완료 ===")
[void]$sb.AppendLine("EXIT;")

[System.IO.File]::WriteAllText($master, $sb.ToString(), (New-Object System.Text.UTF8Encoding($false)))

Write-Host "Oracle DB 접속: ${Username}@${connectIdentifier}"
Write-Host "반영 대상: $($sqlFiles.Count) 파일"
Write-Host "마스터 스크립트: $master"

$code = 0
try {
    Push-Location $dmlDir
    if ($LogFile) {
        & $oracleClient.Source -L -S $connectString "@$master" 2>&1 | Tee-Object -FilePath $LogFile
    } else {
        & $oracleClient.Source -L -S $connectString "@$master"
    }
    $code = $LASTEXITCODE
}
finally {
    Pop-Location
    if (Test-Path $master) { Remove-Item $master -Force }
}

exit $code
