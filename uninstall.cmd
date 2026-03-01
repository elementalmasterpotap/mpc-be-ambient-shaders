@echo off
chcp 65001 >nul
setlocal
set ROOT=%~dp0
powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%uninstall.ps1" %*
if %ERRORLEVEL% neq 0 pause
endlocal
