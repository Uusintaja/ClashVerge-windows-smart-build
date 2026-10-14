<#PSScriptInfo
.VERSION 1.0
.AUTHOR portable-wrapper
#>
<#
.SYNOPSIS
  Clash Verge Rev portable launcher (zero code changes, env-var redirection).
.DESCRIPTION
  Redirects APPDATA / LOCALAPPDATA / WEBVIEW2_USER_DATA_FOLDER into
  the Data/ folder next to the unpacked exe. Process-local only,
  the system environment is not modified.
  Usage: copy this file next to the unpacked exe (same folder as clash-verge.exe),
  right-click -> Run with PowerShell, or:
  powershell -ExecutionPolicy Bypass -File .\Start-Portable.ps1
.PARAMETER ExeName
  Main exe file name, auto-detects clash-verge.exe / Clash Verge.exe by default
.PARAMETER DataDir
  Portable data folder name, default Data (<exe dir>\Data)
.PARAMETER DryRun
  Print resolved paths without launching (troubleshooting)
.PARAMETER Admin
  Relaunch this script elevated (UAC prompt, needed for TUN); runs directly if already admin
.EXAMPLE
  .\Start-Portable.ps1 -DryRun
#>
[CmdletBinding()]
param(
  [string]$ExeName = "",
  [string]$DataDir = "Data",
  [switch]$DryRun,
  [switch]$Admin
)

$ErrorActionPreference = "Stop"
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
$AppId = "io.github.clash-verge-rev.clash-verge-rev"
$Base = $PSScriptRoot
if (-not $Base) { $Base = Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $Base) { throw "Cannot locate the script directory; run this script from a file." }
if (-not $DataDir) { $DataDir = "Data" }

# 0. Elevate on demand (TUN needs admin; same-user UAC elevation inherits env, and everything here is exe-relative)
if ($Admin) {
  $me = [Security.Principal.WindowsPrincipal]([Security.Principal.WindowsIdentity]::GetCurrent())
  if (-not $me.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $cmd = "-NoProfile -ExecutionPolicy Bypass -File " + '"' + $PSCommandPath + '"'
    if ($ExeName) { $cmd += ' -ExeName "' + $ExeName + '"' }
    if ($DataDir -ne "Data") { $cmd += ' -DataDir "' + $DataDir + '"' }
    if ($DryRun) { $cmd += " -DryRun" }
    foreach ($a in $args) { $cmd += " " + $a }
    if ($DryRun) {
      Write-Host "[ADMIN-DRYRUN] non-admin, would relaunch elevated:"
      Write-Host "  powershell $cmd"
      return
    }
    Start-Process -FilePath "powershell" -ArgumentList $cmd -Verb RunAs -WorkingDirectory $Base
    return
  }
}

# 1. Locate the main exe
$candidates = @()
if ($ExeName) { $candidates += $ExeName }
$candidates += "clash-verge.exe", "Clash Verge.exe"
$Exe = $null
foreach ($c in $candidates) {
  $p = Join-Path $Base $c
  if (Test-Path -LiteralPath $p) { $Exe = $p; break }
}
if (-not $Exe) {
  Write-Host "[Error] main exe not found in this folder: $($candidates -join ' / ')" -ForegroundColor Red
  Write-Host "Copy this file next to the unpacked exe (same folder) and run it."
  exit 1
}

# 2. Create portable data folders (Data/ mirrors a Windows profile:
#    Data/Roaming/<APP_ID> is the app home the patched build reads)
$Data = Join-Path $Base $DataDir
$Roaming = Join-Path $Data "Roaming"
$AppHome = Join-Path $Roaming $AppId
$Local = Join-Path $Data "Local"
$WebView = Join-Path $Data "EBWebView"
foreach ($d in @($AppHome, $Local, $WebView)) {
  if (-not (Test-Path -LiteralPath $d)) {
    New-Item -ItemType Directory -Path $d | Out-Null
  }
}

# 3. Redirect (process-local, Windows only)
$env:APPDATA = $Roaming
$env:LOCALAPPDATA = $Local
$env:WEBVIEW2_USER_DATA_FOLDER = $WebView

Write-Host ""
Write-Host "[Portable mode]" -ForegroundColor Green
Write-Host "  exe      : $Exe"
Write-Host "  data     : $(Join-Path $env:APPDATA $AppId)"
Write-Host "  cache    : $env:LOCALAPPDATA"
Write-Host "  WebView  : $env:WEBVIEW2_USER_DATA_FOLDER"
Write-Host ""

if ($DryRun) {
  Write-Host "[DRYRUN] main exe not launched."
  return
}

# 4. Launch (forward extra args)
if ($args.Count -eq 0) {
  Start-Process -FilePath $Exe -WorkingDirectory $Base
} else {
  Start-Process -FilePath $Exe -ArgumentList $args -WorkingDirectory $Base
}
