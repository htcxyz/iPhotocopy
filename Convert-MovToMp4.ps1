<#
Convert-MovToMp4.ps1

Converts one or more MOV files to compressed MP4 files beside the original file.

Used by the optional Windows right-click menu entry:
  Compress MOV to MP4
#>

param(
  [Parameter(Mandatory = $true, ValueFromRemainingArguments = $true)]
  [string[]]$Path,

  [switch]$Force,
  [switch]$NoPause
)

$ffmpeg = Get-Command ffmpeg -ErrorAction SilentlyContinue
if (-not $ffmpeg) {
  Write-Host "FAIL: ffmpeg was not found on PATH."
  Write-Host "Install ffmpeg, then try again."
  exit 20
}

$ffprobe = Get-Command ffprobe -ErrorAction SilentlyContinue

function Quote-Argument {
  param(
    [string]$Value
  )

  return '"' + ($Value -replace '"', '\"') + '"'
}

function Get-MediaDurationSeconds {
  param(
    [string]$InputPath
  )

  if (-not $ffprobe) { return $null }

  $durationText = & $ffprobe.Source -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $InputPath 2>$null
  if ($LASTEXITCODE -ne 0) { return $null }

  $duration = 0.0
  if ([double]::TryParse($durationText, [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$duration)) {
    return $duration
  }

  return $null
}

function Get-FfmpegProgress {
  param(
    [string]$ProgressPath
  )

  if (-not (Test-Path -LiteralPath $ProgressPath)) { return $null }

  $lines = Get-Content -LiteralPath $ProgressPath -ErrorAction SilentlyContinue
  $outTimeMsLine = $lines | Where-Object { $_ -like "out_time_ms=*" } | Select-Object -Last 1
  if (-not $outTimeMsLine) { return $null }

  $outTimeMs = 0.0
  $value = $outTimeMsLine.Substring("out_time_ms=".Length)
  if ([double]::TryParse($value, [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$outTimeMs)) {
    return ($outTimeMs / 1000000.0)
  }

  return $null
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

  if ($file.Extension -notmatch '^\.mov$') {
    Write-Host "SKIP: Not a MOV file:" $file.FullName
    $skipped++
    continue
  }

  $outputPath = Join-Path $file.DirectoryName ($file.BaseName + ".mp4")
  if ((Test-Path -LiteralPath $outputPath) -and -not $Force) {
    $existingOutput = Get-Item -LiteralPath $outputPath -ErrorAction SilentlyContinue
    if ($existingOutput -and $existingOutput.Length -eq 0) {
      Write-Host "Removing failed 0-byte MP4:" $outputPath
      Remove-Item -LiteralPath $outputPath -Force
    } else {
      Write-Host "SKIP: MP4 already exists:" $outputPath
      $skipped++
      continue
    }
  }

  Write-Host "Compressing:" $file.FullName
  $tempOutputPath = Join-Path $file.DirectoryName ($file.BaseName + ".tmp.mp4")
  $errorLogPath = Join-Path $env:TEMP ("iPhotocopy-ffmpeg-{0}.log" -f ([guid]::NewGuid().ToString("N")))
  $progressPath = Join-Path $env:TEMP ("iPhotocopy-ffmpeg-progress-{0}.txt" -f ([guid]::NewGuid().ToString("N")))
  $durationSeconds = Get-MediaDurationSeconds -InputPath $file.FullName

  if (Test-Path -LiteralPath $tempOutputPath) {
    Remove-Item -LiteralPath $tempOutputPath -Force
  }
  if (Test-Path -LiteralPath $progressPath) {
    Remove-Item -LiteralPath $progressPath -Force
  }

  $ffmpegArgs = @(
    "-hide_banner",
    "-nostats",
    "-loglevel", "error",
    "-progress", (Quote-Argument $progressPath),
    "-y",
    "-i", (Quote-Argument $file.FullName),
    "-map", "0:v:0",
    "-map", "0:a?",
    "-vf", (Quote-Argument "scale='min(1280,iw)':-2,fps=30"),
    "-c:v", "libx264",
    "-preset", "veryfast",
    "-b:v", "900k",
    "-maxrate", "1200k",
    "-bufsize", "2400k",
    "-pix_fmt", "yuv420p",
    "-c:a", "aac",
    "-b:a", "96k",
    "-movflags", "+faststart",
    (Quote-Argument $tempOutputPath)
  ) -join " "

  $process = Start-Process -FilePath $ffmpeg.Source -ArgumentList $ffmpegArgs -NoNewWindow -PassThru -RedirectStandardError $errorLogPath
  $lastPercent = -1
  $lastHeartbeat = Get-Date

  while (-not $process.HasExited) {
    Start-Sleep -Seconds 2
    $processedSeconds = Get-FfmpegProgress -ProgressPath $progressPath

    if ($durationSeconds -and $processedSeconds -ne $null) {
      $percent = [math]::Min(99, [math]::Floor(($processedSeconds / $durationSeconds) * 100))
      if ($percent -ne $lastPercent) {
        Write-Progress -Activity "Compressing MOV to MP4" -Status ("{0}% complete" -f $percent) -PercentComplete $percent
        Write-Host ("Progress: {0}%" -f $percent)
        $lastPercent = $percent
      }
    } elseif (((Get-Date) - $lastHeartbeat).TotalSeconds -ge 10) {
      Write-Host "Progress: still working..."
      $lastHeartbeat = Get-Date
    }
  }

  $process.WaitForExit()
  Write-Progress -Activity "Compressing MOV to MP4" -Completed

  $tempOutput = Get-Item -LiteralPath $tempOutputPath -ErrorAction SilentlyContinue
  if ($process.ExitCode -eq 0 -and $tempOutput -and $tempOutput.Length -gt 0) {
    if ((Test-Path -LiteralPath $outputPath) -and $Force) {
      Remove-Item -LiteralPath $outputPath -Force
    }
    Move-Item -LiteralPath $tempOutputPath -Destination $outputPath -Force
    $inputSizeMb = [math]::Round($file.Length / 1MB, 1)
    $outputSizeMb = [math]::Round((Get-Item -LiteralPath $outputPath).Length / 1MB, 1)
    Write-Host "DONE:" $outputPath
    Write-Host ("Size: {0} MB -> {1} MB" -f $inputSizeMb, $outputSizeMb)
    $converted++
  } else {
    if (Test-Path -LiteralPath $tempOutputPath) {
      Remove-Item -LiteralPath $tempOutputPath -Force
    }
    Write-Host "FAIL: Could not convert:" $file.FullName
    if (Test-Path -LiteralPath $errorLogPath) {
      $errorText = (Get-Content -LiteralPath $errorLogPath -Raw).Trim()
      if ($errorText) {
        Write-Host ""
        Write-Host "ffmpeg said:"
        Write-Host $errorText
      }
    }
    $failed++
  }

  if (Test-Path -LiteralPath $errorLogPath) {
    Remove-Item -LiteralPath $errorLogPath -Force
  }
  if (Test-Path -LiteralPath $progressPath) {
    Remove-Item -LiteralPath $progressPath -Force
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
