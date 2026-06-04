@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "DEST_ROOT=%USERPROFILE%\Pictures\iPhotoCopy"
set "BATCH_NAME=%~n0"
set "CUTOFF_MONTH=%BATCH_NAME:iPhotocopy-=%"

echo %CUTOFF_MONTH%| findstr /r "^[0-9][0-9][0-9][0-9][0-9][0-9]$" >nul
if errorlevel 1 (
  echo FAIL: Filename must be iPhotocopy-YYYYMM.bat
  echo.
  echo YYYY = 4 digit year, for example 2025
  echo MM   = 2 digit month to copy through, for example 03
  echo.
  echo Example: iPhotocopy-202503.bat
  echo This copies all photos from the oldest photo on your phone up to the end of March 2025.
  echo.
  echo Current filename: %~nx0
  echo Parsed YYYYMM: %CUTOFF_MONTH%
  echo.
  echo Press any key to close this window.
  pause
  exit /b 10
)

set "MONTH_PART=%CUTOFF_MONTH:~4,2%"
if "%MONTH_PART%"=="00" goto badmonth
if %MONTH_PART% GTR 12 goto badmonth
goto validmonth

:badmonth
echo FAIL: Month must be 01 to 12.
echo.
echo Filename must be iPhotocopy-YYYYMM.bat
echo YYYY = 4 digit year, for example 2025
echo MM   = 2 digit month to copy through, for example 03
echo.
echo Example: iPhotocopy-202503.bat
echo This copies all photos from the oldest photo on your phone up to the end of March 2025.
echo.
echo Current filename: %~nx0
echo Parsed YYYYMM: %CUTOFF_MONTH%
echo Parsed MM: %MONTH_PART%
echo.
echo Press any key to close this window.
pause
exit /b 10

:validmonth

powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%iPhotocopy.ps1" -cutoffMonth "%CUTOFF_MONTH%"
if errorlevel 1 (
  echo.
  echo iPhotocopy failed. Press any key to close this window.
  pause >nul
  exit /b %errorlevel%
)

start "" explorer.exe "%DEST_ROOT%"
echo.
echo iPhotocopy finished. Press any key to close this window.
pause >nul
