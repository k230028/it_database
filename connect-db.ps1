<#
.SYNOPSIS
IT Portal 로컬 Oracle DB 접속 스크립트입니다.

.DESCRIPTION
Spring Boot 개발 설정과 동일한 Oracle 접속 정보로 SQL*Plus 또는 SQLcl에 접속합니다.
기본 접속 대상은 127.0.0.1:1521/XEPDB1, 계정은 ITPAPP입니다.
#>
[CmdletBinding()]
param(
    [string]$HostName = "127.0.0.1",
    [int]$Port = 1521,
    [string]$ServiceName = "XEPDB1",
    [string]$Username = "ITPAPP",
    [string]$Password = "kdb1234!!",
    [ValidateSet("auto", "sqlplus", "sql")]
    [string]$Client = "auto"
)

$ErrorActionPreference = "Stop"

function Resolve-OracleClient {
    param([string]$PreferredClient)

    $candidates = if ($PreferredClient -eq "auto") {
        @("sqlplus", "sql")
    } else {
        @($PreferredClient)
    }

    foreach ($candidate in $candidates) {
        $command = Get-Command $candidate -ErrorAction SilentlyContinue
        if ($null -ne $command) {
            return $command
        }
    }

    throw "Oracle 접속 클라이언트를 찾을 수 없습니다. SQL*Plus(sqlplus) 또는 SQLcl(sql)을 PATH에 추가하세요."
}

$oracleClient = Resolve-OracleClient -PreferredClient $Client
$connectIdentifier = "${HostName}:${Port}/${ServiceName}"
$connectString = "${Username}/${Password}@${connectIdentifier}"

Write-Host "Oracle DB 접속: ${Username}@${connectIdentifier}"
Write-Host "종료하려면 SQL 프롬프트에서 exit를 입력하세요."

& $oracleClient.Source -L $connectString
exit $LASTEXITCODE
