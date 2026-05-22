@echo off
setlocal

net session >nul 2>&1
if not "%errorlevel%"=="0" (
  echo Requesting administrator rights to install ImageMagick...
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)

where choco >nul 2>&1
if errorlevel 1 (
  echo FAIL: Chocolatey was not found on PATH.
  echo Install ImageMagick manually from https://imagemagick.org, then try HEIC conversion again.
  echo.
  pause
  exit /b 1
)

choco install imagemagick -y --no-progress
if errorlevel 1 (
  echo.
  echo FAIL: ImageMagick install failed.
  echo Try running this file again, or install ImageMagick manually.
  echo.
  pause
  exit /b 1
)

echo.
echo ImageMagick installed.
echo Close and reopen File Explorer if the right-click converter still cannot find magick.exe.
echo.
pause
