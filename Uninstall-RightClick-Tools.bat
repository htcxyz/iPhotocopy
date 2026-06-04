@echo off
setlocal

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "Remove-Item -Path 'HKCU:\Software\Classes\SystemFileAssociations\.heic\shell\iPhotocopyConvertToJpg' -Recurse -Force -ErrorAction SilentlyContinue;" ^
  "Remove-Item -Path 'HKCU:\Software\Classes\SystemFileAssociations\.heif\shell\iPhotocopyConvertToJpg' -Recurse -Force -ErrorAction SilentlyContinue;" ^
  "Remove-Item -Path 'HKCU:\Software\Classes\SystemFileAssociations\.mov\shell\iPhotocopyCompressToMp4' -Recurse -Force -ErrorAction SilentlyContinue;"

echo.
echo Removed iPhotocopy right-click tools for this Windows user.
echo.
pause
