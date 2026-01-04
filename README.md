# iPhotocopy (Windows)

Lightweight PowerShell tool to copy photos and videos from an iPhone to Windows over USB.

Uses the same mechanism as Windows File Explorer (Shell / MTP).  
No iTunes SDK, no WIA, no third-party tools.

---

## What it does

- Copies **photos and videos** from an iPhone to Windows
- Copies everything **older than a given cutoff date** (Set cutoff date in script or parameters)
- Preserves Apple’s **YYYYMM bucket folders** (e.g. `202306__`, `202306_a`)
- Safe to re-run (already copied files are skipped)
- Waits for copy completion (or exits immediately if nothing new)

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
  -cutoff "2023-07-01" `
  -destRoot "D:\iPhoneArchive"



  .\iPhotocopy.ps1
iPhotocopy
Cutoff date: 2023-07-01
Cutoff month: 202307
Destination: C:\Users\htcxyz\Pictures\iPhoneArchive
Queueing 2 files from 201908__...
Queueing 1 files from 202302__...
Queueing 5 files from 202303__...
Queueing 80 files from 202305__...
Queueing 178 files from 202306__...
Queueing 94 files from 202306_a...
DONE. Queued for copy: 0
Nothing to copy. Exiting.
