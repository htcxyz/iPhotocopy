<#
iPhotocopy.ps1

Copies photos and videos from an iPhone to Windows using the Explorer (Shell/MTP) interface.

- Copies all media through a given cutoff month, or only the current month
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
  [string]$cutoffMonth = "202412",
  [string]$destRoot = "$env:USERPROFILE\Pictures\iPhoneCopyArchive",
  [Alias("m")]
  [switch]$CurrentMonth
)

$currentMonthValue = Get-Date -Format "yyyyMM"
$selectedMonth = if ($CurrentMonth) { $currentMonthValue } else { $cutoffMonth }

if ($selectedMonth -notmatch '^\d{6}$') {
  Write-Host "FAIL: cutoffMonth must be in YYYYMM format, for example 202412"
  exit 10
}

$selectedMonthNumber = [int]$selectedMonth.Substring(4,2)
if ($selectedMonthNumber -lt 1 -or $selectedMonthNumber -gt 12) {
  Write-Host "FAIL: cutoffMonth must use a valid month from 01 to 12"
  exit 10
}

$copyMode = if ($CurrentMonth) { "current month only" } else { "through cutoff month" }
$destRootFullPath = [System.IO.Path]::GetFullPath($destRoot)
$destRootUri = ([System.Uri]$destRootFullPath).AbsoluteUri

Write-Host "iPhotocopy"
Write-Host "Copy mode:" $copyMode
Write-Host "Selected month:" $selectedMonth
Write-Host "Destination:" $destRootFullPath
Write-Host "Open in Explorer:" $destRootUri
Write-Host "Explorer command:" ("explorer.exe `"{0}`"" -f $destRootFullPath)

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

if ($monthFolders.Count -eq 0) {
  $dcim = $internalFolder.Items() | Where-Object { $_.IsFolder -and $_.Name -eq "DCIM" } | Select-Object -First 1
  if ($dcim) {
    $dcimFolder = $dcim.GetFolder()
    $monthFolders = @(
      $dcimFolder.Items() |
        Where-Object { $_.IsFolder -and $_.Name -match '^\d{6}' } |
        Sort-Object Name
    )
  }
}

if ($monthFolders.Count -eq 0) {
  $internalFolders = @($internalFolder.Items() | Where-Object { $_.IsFolder } | ForEach-Object { $_.Name })
  Write-Host "FAIL: No YYYYMM folders found"
  if ($internalFolders.Count -gt 0) {
    Write-Host "Folders found under Internal Storage:" ($internalFolders -join ", ")
  } else {
    Write-Host "No folders were visible under Internal Storage."
  }

  if ($dcimFolder) {
    $dcimFolders = @($dcimFolder.Items() | Where-Object { $_.IsFolder } | ForEach-Object { $_.Name })
    if ($dcimFolders.Count -gt 0) {
      Write-Host "Folders found under Internal Storage\DCIM:" ($dcimFolders -join ", ")
    } else {
      Write-Host "No folders were visible under Internal Storage\DCIM."
    }
  }

  Write-Host "Tip: If the iPhone was recently connected, unlock it and reconnect the USB cable; stale MTP connections can return empty folder lists."
  exit 3
}

New-Item -ItemType Directory -Path $destRootFullPath -Force | Out-Null

$copyFlags = 16 + 1024
$scanned = 0
$alreadyPresent = 0
$queued = 0
$startingCount = (Get-ChildItem -Path $destRootFullPath -Recurse -File -ErrorAction SilentlyContinue).Count
$folderResults = @()

foreach ($mf in $monthFolders) {
  $m = $mf.Name.Substring(0,6)
  if ($CurrentMonth) {
    if ($m -ne $selectedMonth) { continue }
  } elseif ($m -gt $selectedMonth) {
    continue
  }

  $srcFolder = $mf.GetFolder()

  $destFolderPath = Join-Path $destRootFullPath $mf.Name
  New-Item -ItemType Directory -Path $destFolderPath -Force | Out-Null
  $destFolderShell = $sh.Namespace($destFolderPath)
  if (-not $destFolderShell) { Write-Host "FAIL: Cannot open destination folder: $destFolderPath"; exit 4 }
  $folderStartingCount = (Get-ChildItem -LiteralPath $destFolderPath -File -ErrorAction SilentlyContinue).Count

  $files = @($srcFolder.Items() | Where-Object { -not $_.IsFolder })
  $folderAlreadyPresent = 0
  $folderQueued = 0

  foreach ($f in $files) {
    $scanned++
    $target = Join-Path $destFolderPath $f.Name
    if (Test-Path $target) {
      $alreadyPresent++
      $folderAlreadyPresent++
      continue
    }

    $destFolderShell.CopyHere($f, $copyFlags)
    $queued++
    $folderQueued++
  }

  $folderResults += [PSCustomObject]@{
    Name = $mf.Name
    Path = $destFolderPath
    Scanned = $files.Count
    AlreadyPresent = $folderAlreadyPresent
    Queued = $folderQueued
    StartingCount = $folderStartingCount
  }

  Write-Host ("Scanned '{0}': {1} found, {2} already present, {3} queued for copy" -f $mf.Name, $files.Count, $folderAlreadyPresent, $folderQueued)
}

Write-Host "DONE."
Write-Host "Files scanned:" $scanned
Write-Host "Already present before copy:" $alreadyPresent
Write-Host "Queued for copy this run:" $queued
Write-Host "Files present before copy:" $startingCount

if ($queued -eq 0) {
  Write-Host "Files copied this run: 0"
  Write-Host "Nothing to copy. Exiting."
  exit 0
}

Write-Host "Waiting for copy to complete..."

$stableSeconds = 30
$pollInterval = 1
$lastCount = -1
$stableFor = 0

while ($true) {
  $count = (Get-ChildItem -Path $destRootFullPath -Recurse -File -ErrorAction SilentlyContinue).Count

  if ($count -eq $lastCount) {
    $stableFor += $pollInterval
    if ($stableFor -ge $stableSeconds) { break }
  } else {
    $stableFor = 0
    $lastCount = $count
  }

  Start-Sleep -Seconds $pollInterval
}

Write-Host "COPY COMPLETE."
Write-Host "Files present after copy:" $lastCount
Write-Host "Copy result by folder:"
foreach ($result in $folderResults) {
  $folderFinalCount = (Get-ChildItem -LiteralPath $result.Path -File -ErrorAction SilentlyContinue).Count
  $folderCopied = $folderFinalCount - $result.StartingCount
  if ($result.Queued -gt 0 -or $folderCopied -gt 0) {
    Write-Host ("'{0}': {1} already present | {2} queued for copy | {3} copied" -f $result.Name, $result.AlreadyPresent, $result.Queued, $folderCopied)
  }
}
Write-Host "Files copied this run:" ($lastCount - $startingCount)
