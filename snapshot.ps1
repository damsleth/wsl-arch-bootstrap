<#
.SYNOPSIS
  Export a WSL distro to a timestamped .tar snapshot (run on the Windows host).

.DESCRIPTION
  Creates a warm backup of your provisioned Arch-on-WSL box so future spin-ups
  start from a finished image instead of re-running bootstrap.sh from scratch.

.EXAMPLE
  .\snapshot.ps1
  .\snapshot.ps1 -Distro archlinux -OutDir C:\wsl\snapshots
#>
[CmdletBinding()]
param(
  [string]$Distro = "archlinux",
  [string]$OutDir = "C:\wsl\snapshots"
)

$ErrorActionPreference = "Stop"

# Confirm the distro exists (wsl outputs UTF-16; normalize before matching).
$distros = (wsl --list --quiet) -replace "`0", "" | ForEach-Object { $_.Trim() } | Where-Object { $_ }
if ($distros -notcontains $Distro) {
  Write-Error "Distro '$Distro' not found. Installed: $($distros -join ', ')"
  exit 1
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$out   = Join-Path $OutDir "$Distro-$stamp.tar"

Write-Host "==> Exporting '$Distro' to $out ..." -ForegroundColor Cyan
wsl --export $Distro $out

$sizeGB = [math]::Round((Get-Item $out).Length / 1GB, 2)
Write-Host "==> Done. Snapshot is $sizeGB GB." -ForegroundColor Green
Write-Host "    Restore with:  .\restore.ps1 -Tar `"$out`"" -ForegroundColor DarkGray
