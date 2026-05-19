#FAST

edit/set cutoff month in iPhotocopy.ps1 
param(
  [string]$cutoffMonth = "202412",
  [string]$destRoot = "$env:USERPROFILE\Pictures\iPhoneCopyArchive"
)

Open Windows powershell as admin.

cd "C:\Users\egank\Documents\GitHub\iPhotocopy"
./iPhotocopy.ps1

#BASICS
Phone must be connected USB and Unlocked with code 
- you will be able to see an click on your Phone in Windows Explorer as a drive if youre phone is securely connected.
Cutoff month = last iPhone month folder to copy, in YYYYMM format. Example: 202412 copies through December 2024.
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
- Copies everything through a given **cutoff month** (Set cutoff month in script or parameters)
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

### Command line (recommended)

From the folder containing the files:

```powershell

##Easy

iPhotocopy.cmd

### Or call PowerShell directly:

powershell -ExecutionPolicy Bypass -File iPhotocopy.ps1

### With parameters:

powershell -ExecutionPolicy Bypass -File iPhotocopy.ps1 `
  -cutoffMonth "202307" `
  -destRoot "D:\iPhoneCopyArchive"



  .\iPhotocopy.ps1
iPhotocopy
Copy through month: 202307
Destination: C:\Users\htcxyz\Pictures\iPhoneCopyArchive
Scanned '201908__': 2 found, 2 already present, 0 queued for copy
Scanned '202302__': 1 found, 1 already present, 0 queued for copy
Scanned '202303__': 5 found, 5 already present, 0 queued for copy
DONE.
Files scanned: 8
Already present before copy: 8
Queued for copy this run: 0
Files copied this run: 0
Nothing to copy. Exiting.
