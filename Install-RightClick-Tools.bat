@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "HEIC_SCRIPT=%SCRIPT_DIR%Convert-HeicToJpg.ps1"
set "MOV_SCRIPT=%SCRIPT_DIR%Convert-MovToMp4.ps1"

if not exist "%HEIC_SCRIPT%" (
  echo FAIL: Missing Convert-HeicToJpg.ps1 beside this installer.
  echo.
  pause
  exit /b 1
)

if not exist "%MOV_SCRIPT%" (
  echo FAIL: Missing Convert-MovToMp4.ps1 beside this installer.
  echo.
  pause
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$heic = '%HEIC_SCRIPT%';" ^
  "$mov = '%MOV_SCRIPT%';" ^
  "New-Item -Path 'HKCU:\Software\Classes\SystemFileAssociations\.heic\shell\iPhotocopyConvertToJpg\command' -Force | Out-Null;" ^
  "Set-Item -Path 'HKCU:\Software\Classes\SystemFileAssociations\.heic\shell\iPhotocopyConvertToJpg' -Value 'Convert HEIC to JPG';" ^
  "New-ItemProperty -Path 'HKCU:\Software\Classes\SystemFileAssociations\.heic\shell\iPhotocopyConvertToJpg' -Name 'Icon' -Value 'imageres.dll,-70' -PropertyType String -Force | Out-Null;" ^
  "Set-Item -Path 'HKCU:\Software\Classes\SystemFileAssociations\.heic\shell\iPhotocopyConvertToJpg\command' -Value ('powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"' + $heic + '\" \"%%1\"');" ^
  "New-Item -Path 'HKCU:\Software\Classes\SystemFileAssociations\.heif\shell\iPhotocopyConvertToJpg\command' -Force | Out-Null;" ^
  "Set-Item -Path 'HKCU:\Software\Classes\SystemFileAssociations\.heif\shell\iPhotocopyConvertToJpg' -Value 'Convert HEIF to JPG';" ^
  "New-ItemProperty -Path 'HKCU:\Software\Classes\SystemFileAssociations\.heif\shell\iPhotocopyConvertToJpg' -Name 'Icon' -Value 'imageres.dll,-70' -PropertyType String -Force | Out-Null;" ^
  "Set-Item -Path 'HKCU:\Software\Classes\SystemFileAssociations\.heif\shell\iPhotocopyConvertToJpg\command' -Value ('powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"' + $heic + '\" \"%%1\"');" ^
  "New-Item -Path 'HKCU:\Software\Classes\SystemFileAssociations\.mov\shell\iPhotocopyCompressToMp4\command' -Force | Out-Null;" ^
  "Set-Item -Path 'HKCU:\Software\Classes\SystemFileAssociations\.mov\shell\iPhotocopyCompressToMp4' -Value 'Compress MOV to MP4';" ^
  "New-ItemProperty -Path 'HKCU:\Software\Classes\SystemFileAssociations\.mov\shell\iPhotocopyCompressToMp4' -Name 'Icon' -Value 'imageres.dll,-68' -PropertyType String -Force | Out-Null;" ^
  "Set-Item -Path 'HKCU:\Software\Classes\SystemFileAssociations\.mov\shell\iPhotocopyCompressToMp4\command' -Value ('powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"' + $mov + '\" \"%%1\"');"

if errorlevel 1 (
  echo.
  echo FAIL: Could not install right-click tools.
  echo.
  pause
  exit /b 1
)

echo.
echo Installed right-click tools for this Windows user.
echo.
echo HEIC/HEIF: Convert HEIC to JPG
echo MOV:       Compress MOV to MP4
echo.
echo If the menu does not appear immediately, close and reopen File Explorer.
echo.
pause
