@echo off
rem Portable launcher entry, elevated: delegates to Start-Portable.ps1 -Admin (one UAC prompt, for TUN).
setlocal
set "PS1=%~dp0Start-Portable.ps1"
if not exist "%PS1%" (
  echo [Error] Start-Portable.ps1 not found next to this bat.
  pause
  exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" -Admin %*
exit /b %ERRORLEVEL%
