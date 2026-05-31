<#
.SYNOPSIS
  Recreate a WSL distro from a .tar snapshot (run on the Windows host).

.DESCRIPTION
  Imports a snapshot made by snapshot.ps1 into a fresh distro registration.
  If a distro with the target name already exists, you must pass -Force, which
  UNREGISTERS (deletes) it first. That is destructive and irreversible for any
  data living only inside that distro — back up first if unsure.

.EXAMPLE
  .\restore.ps1 -Tar C:\wsl\snapshots\archlinux-20260531-2143.tar
  .\restore.ps1 -Tar ...\arch.tar -Distro arch-test -InstallDir C:\wsl\arch-test
  .\restore.ps1 -Tar ...\arch.tar -Force          # replace existing 'archlinux'
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$Tar,
  [string]$Distro     = "archlinux",
  [string]$InstallDir = "C:\wsl\$Distro",
  [switch]$Force
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $Tar)) { Write-Error "Snapshot not found: $Tar"; exit 1 }

$distros = (wsl --list --quiet) -replace "`0", "" | ForEach-Object { $_.Trim() } | Where-Object { $_ }
if ($distros -contains $Distro) {
  if (-not $Force) {
    Write-Error "Distro '$Distro' already exists. Re-run with -Force to replace it (this DELETES it), or choose another -Distro name."
    exit 1
  }
  Write-Host "==> -Force given: unregistering existing '$Distro' (destructive)..." -ForegroundColor Yellow
  wsl --shutdown
  wsl --unregister $Distro
}

New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
Write-Host "==> Importing '$Distro' from $Tar into $InstallDir ..." -ForegroundColor Cyan
wsl --import $Distro $InstallDir $Tar

Write-Host "==> Done. Launch with:  wsl -d $Distro" -ForegroundColor Green
Write-Host "    Note: imported distros default to the root user. If you set a" -ForegroundColor DarkGray
Write-Host "    default user via /etc/wsl.conf inside the image, that is preserved." -ForegroundColor DarkGray
