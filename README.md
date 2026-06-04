#FAST

edit/set cutoff month in iPhotocopy.ps1 
param(
  [string]$cutoffMonth = "202412",
  [string]$destRoot = "$env:USERPROFILE\Pictures\iPhotoCopy",
  [Alias("m")]
  [switch]$CurrentMonth
)

Open Windows powershell as admin.

cd "path\to\iPhotocopy"
./iPhotocopy.ps1

#BASICS
Phone must be connected USB and Unlocked with code 
- you will be able to see an click on your Phone in Windows Explorer as a drive if youre phone is securely connected.
Cutoff month = last iPhone month folder to copy, in YYYYMM format. Example: 202412 copies through December 2024.
CurrentMonth switch = copy only this calendar month's iPhone folder to the PC. Short form: `-m`.
Does not delete on image your Phone - It just copies / backup to destRoot Folder.
Manually delete at your discression on the phone.

#GPT 
https://chatgpt.com/c/695a3ae0-a1d8-832a-a5e8-01c0f8bef1fd

#GITHUB
https://github.com/htcxyz/iPhotocopy


# iPhotocopy (Windows)

Lightweight PowerShell tool to copy photos and videos from an iPhone to Windows over USB.

Uses the same mechanism as Windows File Explorer (Shell / MTP).  
No iTunes SDK, no WIA, no third-party tools.

---

## What it does

- Copies **photos and videos** from an iPhone to Windows
- Copies everything through a given **cutoff month** (set cutoff month in script or parameters)
- Or copies only the current calendar month with `-CurrentMonth`
- Preserves Apple’s **YYYYMM bucket folders** (e.g. `202306__`, `202306_a`)
- Safe to re-run (already copied files are skipped)
- Waits for copy completion (or exits immediately if nothing new)

It does partial folder copies correctly.

For each iPhone folder, it checks every individual file:

$target = Join-Path $destFolderPath $f.Name
if (Test-Path $target) { continue }

$destFolderShell.CopyHere($f, $copyFlags)
So if a destination folder already has 80 of 100 files, it skips those 80 and queues only the missing 20.

The one caveat: Test-Path only means “a file with this name exists.” It does not verify the file finished copying, has the right size, or matches the phone copy.

One important nuance: queued is what the script asked Windows Explorer/MTP to copy. copied is inferred afterward by checking how many new files appeared in that destination folder. That’s the best we can do with CopyHere() because Windows runs the actual transfer asynchronously.

Parse check passed.
---

## Requirements

- Windows 10 / 11
- iPhone connected via USB cable
- iPhone **unlocked** and **trusted**
- iPhone visible in Explorer as:  
  `This PC → Apple iPhone → Internal Storage`

---

## What it does NOT do

- ❌ Delete files from the iPhone  
- ❌ Access app storage or the real iOS filesystem  
- ❌ Transcode, recompress, or modify files  

---

## Usage

### New machine setup:

Copy or download the iPhotocopy folder, then use:

- `iPhotocopy-current Month.bat` to copy the current month
- `iPhotocopy-YYYYMM.bat` style files to copy through a month
- `Install-RightClick-Tools.bat` to install right-click HEIC-to-JPG and MOV-to-MP4 tools for the current Windows user

The copy scripts create `%USERPROFILE%\Pictures\iPhotoCopy` automatically.

Right-click HEIC conversion needs ImageMagick. Run `Install-ImageMagick-Admin.bat` once if ImageMagick is not installed.

Right-click MOV compression needs `ffmpeg`.

### Command line (recommended)

From the folder containing the files:

```powershell

##Easy

iPhotocopy.cmd

Double-click `current.bat` to copy only the current month, then open the archive folder in Explorer.

### Or call PowerShell directly:

powershell -ExecutionPolicy Bypass -File iPhotocopy.ps1

### Copy current month only:

powershell -ExecutionPolicy Bypass -File iPhotocopy.ps1 -CurrentMonth

### Short form:

powershell -ExecutionPolicy Bypass -File iPhotocopy.ps1 -m

### Double-click current month:

current.bat

### Double-click through a cutoff month:

Rename `iPhotocopy-202412.bat` to the month you want, for example `iPhotocopy-202503.bat`, then double-click it.

The batch file reads the `YYYYMM` from its own filename and runs:

powershell -ExecutionPolicy Bypass -File iPhotocopy.ps1 -cutoffMonth "YYYYMM"

`YYYY` is the 4 digit year, for example `2025`. `MM` is the 2 digit month to copy through, for example `03`. `iPhotocopy-202503.bat` copies all photos from the oldest photo on your phone up to the end of March 2025.

The window stays open after the run so you can read the summary.

### Right-click HEIC to JPG:

Double-click `Install-RightClick-Tools.bat`, then right-click a `.HEIC` or `.HEIF` file and choose `Convert HEIC to JPG`.

The JPG is created beside the original file. The original HEIC/HEIF file is not changed.

For correct iPhone HEIC color conversion, use ImageMagick. If conversion says no HEIC converter was found, double-click `Install-ImageMagick-Admin.bat`, approve the admin prompt, then try the right-click conversion again.

To remove the menu item, double-click `Uninstall-RightClick-Tools.bat`.

### Right-click MOV to MP4:

Double-click `Install-RightClick-Tools.bat`, then right-click a `.MOV` file and choose `Compress MOV to MP4`.

The MP4 is created beside the original file. The original MOV file is not changed.

MOV compression is tuned for messaging: up to 1280px wide, 30fps, about 900k video plus 96k audio. That keeps normal-screen playback usable while making files much smaller.

To remove the menu item, double-click `Uninstall-RightClick-Tools.bat`.

### With parameters:

powershell -ExecutionPolicy Bypass -File iPhotocopy.ps1 `
  -cutoffMonth "202307" `
  -destRoot "D:\iPhotoCopy"



  .\iPhotocopy.ps1
iPhotocopy
Copy through month: 202307
Destination: C:\Users\htcxyz\Pictures\iPhotoCopy
Open in Explorer: file:///C:/Users/htcxyz/Pictures/iPhotoCopy
Explorer command: explorer.exe "C:\Users\htcxyz\Pictures\iPhotoCopy"
Scanned '201908__': 2 found, 2 already present, 0 queued for copy
Scanned '202302__': 1 found, 1 already present, 0 queued for copy
Scanned '202303__': 5 found, 5 already present, 0 queued for copy
DONE.
Files scanned: 8
Already present before copy: 8
Queued for copy this run: 0
Files copied this run: 0
Nothing to copy. Exiting.
