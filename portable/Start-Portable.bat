@echo off
rem Portable launcher entry for Clash Verge Rev.
rem Real logic lives in Start-Portable.ps1 next to this file.
rem Usage: copy both files next to the unpacked exe and double-click this bat.
setlocal
set "PS1=%~dp0Start-Portable.ps1"
if not exist "%PS1%" (
  echo [Error] Start-Portable.ps1 not found next to this bat.
  pause
  exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" %*
exit /b %ERRORLEVEL%
