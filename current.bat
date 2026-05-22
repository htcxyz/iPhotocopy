@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "DEST_ROOT=%USERPROFILE%\Pictures\iPhoneCopyArchive"

powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%iPhotocopy.ps1" -m
if errorlevel 1 (
  echo.
  echo iPhotocopy failed. Press any key to close this window.
  pause >nul
  exit /b %errorlevel%
)

start "" explorer.exe "%DEST_ROOT%"
