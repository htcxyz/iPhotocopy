<#
iPhotocopy.ps1

Copies photos and videos from an iPhone to Windows using the Explorer (Shell/MTP) interface.

- Copies all media older than a given cutoff date
- Preserves Apple’s YYYYMM bucket folders
- Safe to re-run (skips existing files)
- No iTunes SDK, no WIA, no third-party tools

Requirements:
- Windows 10/11
- iPhone unlocked and trusted
- iPhone visible in Explorer as "Apple iPhone"

License: MIT
#>

param(
  [string]$cutoff = "2023-07-01",
  [string]$destRoot = "$env:USERPROFILE\Pictures\iPhoneArchive"
)

$dt = [datetime]$cutoff
$cutoffMonth = $dt.ToString("yyyyMM")

Write-Host "iPhotocopy"
Write-Host "Cutoff date:" $dt.ToString("yyyy-MM-dd")
Write-Host "Cutoff month:" $cutoffMonth
Write-Host "Destination:" $destRoot

$sh = New-Object -ComObject Shell.Application
$pc = $sh.Namespace(17)   # This PC

$iphone = $pc.Items() | Where-Object { $_.Name -like "*iPhone*" } | Select-Object -First 1
if (-not $iphone) { Write-Host "FAIL: iPhone not found in This PC"; exit 1 }

$root = $iphone.GetFolder()
$internal = $root.Items() | Where-Object { $_.Name -eq "Internal Storage" } | Select-Object -First 1
if (-not $internal) { Write-Host "FAIL: Internal Storage not found (unlock + Trust iPhone)"; exit 2 }

$internalFolder = $internal.GetFolder()

$monthFolders = @(
  $internalFolder.Items() |
    Where-Object { $_.IsFolder -and $_.Name -match '^\d{6}' } |
    Sort-Object Name
)

if ($monthFolders.Count -eq 0) { Write-Host "FAIL: No YYYYMM folders found"; exit 3 }

New-Item -ItemType Directory -Path $destRoot -Force | Out-Null

$copyFlags = 16 + 1024
$queued = 0

foreach ($mf in $monthFolders) {
  $m = $mf.Name.Substring(0,6)
  if ($m -ge $cutoffMonth) { continue }

  $srcFolder = $mf.GetFolder()

  $destFolderPath = Join-Path $destRoot $mf.Name
  New-Item -ItemType Directory -Path $destFolderPath -Force | Out-Null
  $destFolderShell = $sh.Namespace($destFolderPath)
  if (-not $destFolderShell) { Write-Host "FAIL: Cannot open destination folder: $destFolderPath"; exit 4 }

  $files = @($srcFolder.Items() | Where-Object { -not $_.IsFolder })
  Write-Host ("Queueing {0} files from {1}..." -f $files.Count, $mf.Name)

  foreach ($f in $files) {
    $target = Join-Path $destFolderPath $f.Name
    if (Test-Path $target) { continue }

    $destFolderShell.CopyHere($f, $copyFlags)
    $queued++
  }
}

Write-Host "DONE. Queued for copy:" $queued

if ($queued -eq 0) {
  Write-Host "Nothing to copy. Exiting."
  exit 0
}

Write-Host "Waiting for copy to complete..."

$stableSeconds = 30
$pollInterval = 1
$lastCount = -1
$stableFor = 0

while ($true) {
  $count = (Get-ChildItem -Path $destRoot -Recurse -File -ErrorAction SilentlyContinue).Count

  if ($count -eq $lastCount) {
    $stableFor += $pollInterval
    if ($stableFor -ge $stableSeconds) { break }
  } else {
    $stableFor = 0
    $lastCount = $count
  }

  Start-Sleep -Seconds $pollInterval
}

Write-Host "COPY COMPLETE. Files present:" $lastCount
