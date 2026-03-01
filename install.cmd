@echo off
chcp 65001 >nul
setlocal
set ROOT=%~dp0
powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%install.ps1" %*
endlocal
