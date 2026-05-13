@echo off
rem IT Portal 로컬 Oracle DB 접속 PowerShell 스크립트를 실행합니다.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0connect-db.ps1" %*
