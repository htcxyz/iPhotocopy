<#
Test-iPhoneDelete.ps1

Tests whether Windows Shell/MTP exposes a delete action for one file or folder on the iPhone.

By default this only inspects one file and prints available verbs. It deletes only
when -Delete is provided.
#>

param(
  [string]$folderName = "202303__",
  [int]$BatchSize = 1,
  [switch]$FolderLevel,
  [switch]$AutoConfirm,
  [switch]$DirectInvoke,
  [switch]$Delete
)

Write-Host "iPhone delete capability test"
Write-Host "Folder:" $folderName
Write-Host "Target:" $(if ($FolderLevel) { "folder" } elseif ($BatchSize -gt 1) { "$BatchSize files" } else { "one file" })
Write-Host "Mode:" $(if ($Delete) { "DELETE" } else { "inspect only" })
Write-Host "Auto-confirm:" $(if ($AutoConfirm) { "on" } else { "off" })
Write-Host "Direct invoke:" $(if ($DirectInvoke) { "on" } else { "off" })

$sh = New-Object -ComObject Shell.Application
$pc = $sh.Namespace(17)   # This PC

$iphone = $pc.Items() | Where-Object { $_.Name -like "*iPhone*" } | Select-Object -First 1
if (-not $iphone) { Write-Host "FAIL: iPhone not found in This PC"; exit 1 }

$root = $iphone.GetFolder()
$internal = $root.Items() | Where-Object { $_.Name -eq "Internal Storage" } | Select-Object -First 1
if (-not $internal) { Write-Host "FAIL: Internal Storage not found (unlock + Trust iPhone)"; exit 2 }

$internalFolder = $internal.GetFolder()
$folder = $internalFolder.Items() | Where-Object { $_.IsFolder -and $_.Name -eq $folderName } | Select-Object -First 1

if (-not $folder) {
  $dcim = $internalFolder.Items() | Where-Object { $_.IsFolder -and $_.Name -eq "DCIM" } | Select-Object -First 1
  if ($dcim) {
    $folder = $dcim.GetFolder().Items() | Where-Object { $_.IsFolder -and $_.Name -eq $folderName } | Select-Object -First 1
  }
}

if (-not $folder) {
  Write-Host "FAIL: Folder not found:" $folderName
  exit 3
}

if ($FolderLevel) {
  $verbs = @($folder.Verbs())
  Write-Host "Available folder verbs:"
  foreach ($verb in $verbs) {
    Write-Host " -" ($verb.Name -replace '&','')
  }

  $deleteVerb = $verbs | Where-Object { ($_.Name -replace '&','') -match '^Delete$' } | Select-Object -First 1
  if (-not $deleteVerb) {
    Write-Host "RESULT: Delete verb not available for this iPhone folder."
    exit 0
  }

  Write-Host "RESULT: Delete verb is available for this folder."

  if (-not $Delete) {
    Write-Host "No folder deleted. Re-run with -FolderLevel -Delete to try deleting this folder."
    exit 0
  }

  Write-Host "Deleting folder:" $folderName
  if ($DirectInvoke) {
    $folder.InvokeVerb("delete")
  } else {
    $deleteVerb.DoIt()
  }
  Write-Host "Delete command sent. Check the iPhone to confirm the result."
  exit 0
}

$folderShell = $folder.GetFolder()
$items = @($folderShell.Items() | Where-Object { -not $_.IsFolder } | Select-Object -First $BatchSize)
$item = $items | Select-Object -First 1
if (-not $item) {
  Write-Host "FAIL: No files found in folder:" $folderName
  exit 4
}

if ($BatchSize -gt 1) {
  Write-Host "Test batch:"
  foreach ($batchItem in $items) {
    Write-Host " -" $batchItem.Name
  }
} else {
  Write-Host "Test item:" $item.Name
}

$verbs = @($item.Verbs())
Write-Host "Available verbs:"
foreach ($verb in $verbs) {
  Write-Host " -" ($verb.Name -replace '&','')
}

$deleteVerb = $verbs | Where-Object { ($_.Name -replace '&','') -match '^Delete$' } | Select-Object -First 1
if (-not $deleteVerb) {
  Write-Host "RESULT: Delete verb not available for this iPhone file."
  exit 0
}

Write-Host "RESULT: Delete verb is available."

if (-not $Delete) {
  if ($BatchSize -gt 1) {
    Write-Host "No files deleted. Re-run with -BatchSize $BatchSize -Delete to try deleting this batch."
  } else {
    Write-Host "No file deleted. Re-run with -Delete to try deleting this one test item."
  }
  exit 0
}

if ($BatchSize -gt 1) {
  Write-Host "Trying repeated single-file delete for $($items.Count) files."
  $wshell = $null
  if ($AutoConfirm) {
    $wshell = New-Object -ComObject WScript.Shell
    Write-Host "Auto-confirm will send Enter after each delete command."
  }

  foreach ($batchItem in $items) {
    $batchVerbs = @($batchItem.Verbs())
    $batchDeleteVerb = $batchVerbs | Where-Object { ($_.Name -replace '&','') -match '^Delete$' } | Select-Object -First 1
    if (-not $batchDeleteVerb) {
      Write-Host "SKIP: Delete verb not available for" $batchItem.Name
      continue
    }

    Write-Host "Deleting:" $batchItem.Name
    $batchDeleteVerb.DoIt()
    if ($AutoConfirm) {
      Start-Sleep -Milliseconds 750
      $wshell.SendKeys("{ENTER}")
    }
    Start-Sleep -Milliseconds 500
  }
  Write-Host "Delete commands sent. Windows may ask for confirmation for each file."
} else {
  Write-Host "Deleting one test item:" $item.Name
  $deleteVerb.DoIt()
  if ($AutoConfirm) {
    Start-Sleep -Milliseconds 750
    $wshell = New-Object -ComObject WScript.Shell
    $wshell.SendKeys("{ENTER}")
  }
  Write-Host "Delete command sent. Check the iPhone folder to confirm the result."
}
