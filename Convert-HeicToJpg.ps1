<#
Convert-HeicToJpg.ps1

Converts one or more HEIC/HEIF files to JPG beside the original file.

Used by the optional Windows right-click menu entry:
  Convert HEIC to JPG
#>

param(
  [Parameter(Mandatory = $true, ValueFromRemainingArguments = $true)]
  [string[]]$Path,

  [switch]$Force,
  [switch]$NoPause
)

function Get-Tool {
  param(
    [string]$Name,
    [string[]]$FallbackPaths = @()
  )

  $command = Get-Command $Name -ErrorAction SilentlyContinue
  if ($command) { return $command.Source }

  foreach ($fallbackPath in $FallbackPaths) {
    $match = Get-ChildItem -Path $fallbackPath -ErrorAction SilentlyContinue |
      Sort-Object FullName -Descending |
      Select-Object -First 1
    if ($match) { return $match.FullName }
  }

  return $null
}

$magickPath = Get-Tool -Name "magick" -FallbackPaths @(
  "C:\Program Files\ImageMagick-*\magick.exe",
  "C:\Program Files (x86)\ImageMagick-*\magick.exe"
)
$heifConvert = Get-Command heif-convert -ErrorAction SilentlyContinue

if (-not $magickPath -and -not $heifConvert) {
  Write-Host "FAIL: No HEIC converter was found on PATH."
  Write-Host "Install ImageMagick, then try again."
  Write-Host "Tip: Run Install-ImageMagick-Admin.bat from the iPhotocopy folder."
  exit 20
}

$converted = 0
$skipped = 0
$failed = 0

foreach ($inputPath in $Path) {
  $file = Get-Item -LiteralPath $inputPath -ErrorAction SilentlyContinue
  if (-not $file -or $file.PSIsContainer) {
    Write-Host "SKIP: File not found:" $inputPath
    $skipped++
    continue
  }

  if ($file.Extension -notmatch '^\.(heic|heif)$') {
    Write-Host "SKIP: Not a HEIC/HEIF file:" $file.FullName
    $skipped++
    continue
  }

  $outputPath = Join-Path $file.DirectoryName ($file.BaseName + ".jpg")
  if ((Test-Path -LiteralPath $outputPath) -and -not $Force) {
    Write-Host "SKIP: JPG already exists:" $outputPath
    $skipped++
    continue
  }

  Write-Host "Converting:" $file.FullName

  if ($magickPath) {
    & $magickPath $file.FullName -quality 92 $outputPath
  } elseif ($heifConvert) {
    if ((Test-Path -LiteralPath $outputPath) -and $Force) {
      Remove-Item -LiteralPath $outputPath -Force
    }
    & $heifConvert.Source -q 92 $file.FullName $outputPath
  }

  if ($LASTEXITCODE -eq 0 -and (Test-Path -LiteralPath $outputPath)) {
    Write-Host "DONE:" $outputPath
    $converted++
  } else {
    Write-Host "FAIL: Could not convert:" $file.FullName
    $failed++
  }
}

Write-Host ""
Write-Host "Converted:" $converted
Write-Host "Skipped:" $skipped
Write-Host "Failed:" $failed

if ($failed -gt 0) {
  Write-Host ""
  if (-not $NoPause) {
    Write-Host "Press any key to close this window."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
  }
  exit 1
}
