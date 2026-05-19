# iPhotocopy Agent Instructions

This repo contains `iPhotocopy`, a Windows PowerShell CLI tool for copying iPhone photos/videos over USB.

## Project facts

- Main script: `iPhotocopy.ps1`
- Wrapper: `iPhotocopy.cmd`
- Docs: `README.md`
- Target OS: Windows 10/11
- Mechanism: Windows Explorer Shell / MTP
- Do not use WIA.
- Do not assume `DCIM`.
- Do not claim iPhone files can be reliably deleted by script.
- Do not add dependencies.

## How the tool works

The script finds:

`This PC → Apple iPhone → Internal Storage`

It reads Apple’s virtual month folders, such as:

`202306__`, `202306_a`, `202307__`

It copies folders where the leading `YYYYMM` is before the cutoff month.

Example:

`-cutoff "2023-07-01"` means copy folders `< 202307`.

So it includes June 2023 and earlier, and skips July 2023 onward.

## Required behaviour

Keep the tool lightweight.

Preserve these behaviours:

- safe to re-run
- skip existing files
- copy photos and videos
- preserve Apple month folders
- use `Shell.CopyHere()` for MTP items
- exit immediately if queued count is zero
- wait for copy completion only when files were queued

## Common commands

Run from repo folder:

```powershell
.\iPhotocopy.ps1