<#
Symbian/Qt build helper for SBSv2 (sbs) with RVCT 4.0

Usage examples (PowerShell):
  # Set paths explicitly
  .\scripts\build-symbian.ps1 -SdkRoot "C:\\Symbian\\Tools\\PDK_3.0.4" -RvctBin "C:\\Program Files\\ARM\\RVCT\\Tools\\4.0\\arm\\bin"

  # Use existing environment (EPOCROOT/RVCT40BIN), build both configs
  .\scripts\build-symbian.ps1

Params:
  -SdkRoot  : Path to the SDK root (EPOCROOT). Trailing backslash added.
  -RvctBin  : Path to RVCT 4.0 bin folder (contains armcc.exe).
  -Config   : Base CPU config; default 'armv5'.
  -DebugOnly / -ReleaseOnly: Build only one variant.
#>

[CmdletBinding()]
param(
  [string]$SdkRoot,
  [string]$RvctBin,
  [string]$Config = 'armv5',
  [switch]$DebugOnly,
  [switch]$ReleaseOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Add-ToPath([string]$path) {
  if ([string]::IsNullOrWhiteSpace($path)) { return }
  if (-not (Test-Path -LiteralPath $path)) { return }
  if ($env:PATH.Split([IO.Path]::PathSeparator) -notcontains $path) {
    $env:PATH = $env:PATH + [IO.Path]::PathSeparator + $path
  }
}

function Ensure-TrailingBackslash([string]$p) {
  if ([string]::IsNullOrWhiteSpace($p)) { return $p }
  if ($p[-1] -ne '\\') { return ($p + '\\') }
  return $p
}

# Resolve SDK root (EPOCROOT)
if (-not $SdkRoot) {
  if ($env:EPOCROOT) { $SdkRoot = $env:EPOCROOT }
}
if ($SdkRoot) {
  $SdkRoot = Ensure-TrailingBackslash $SdkRoot
  $env:EPOCROOT = $SdkRoot
}

# Resolve RVCT 4.0 bin
if (-not $RvctBin) {
  if ($env:RVCT40BIN) { $RvctBin = $env:RVCT40BIN }
  elseif ($env:RVCT_BIN) { $RvctBin = $env:RVCT_BIN }
}

# Put tools on PATH
if ($env:EPOCROOT) { Add-ToPath (Join-Path $env:EPOCROOT 'epoc32\tools') }
if ($RvctBin) { Add-ToPath $RvctBin }

# Try to deduce RVCT include/lib if only BIN provided
function Resolve-RvctDataPaths([string]$binPath) {
  try {
    if (-not $binPath) { return $null }
    $bin = Resolve-Path -LiteralPath $binPath -ErrorAction Stop
    $armDir = Split-Path -Parent $bin              # ...\arm\bin
    $toolsVerDir = Split-Path -Parent $armDir      # ...\Tools\4.0\arm
    $toolsDir = Split-Path -Parent $toolsVerDir    # ...\Tools
    $rvctRoot = Split-Path -Parent $toolsDir       # ...\RVCT
    $dataDir = Join-Path $rvctRoot 'Data'
    if (-not (Test-Path -LiteralPath $dataDir)) { return $null }
    $verDir = Get-ChildItem -LiteralPath $dataDir -Directory -Filter '4.0' -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $verDir) { return $null }
    # Prefer highest numeric subversion under 4.0 (e.g., 400, 401, 500)
    $sub = Get-ChildItem -LiteralPath $verDir.FullName -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1
    if (-not $sub) { return $null }
    $base = $sub.FullName
    $inc = Join-Path $base 'include'
    $lib = Join-Path $base 'lib'
    if ((Test-Path $inc) -and (Test-Path $lib)) { return @{ INC=$inc; LIB=$lib } }
  } catch {}
  return $null
}

# Set RVCT40 variables
if ($RvctBin) {
  if (-not $env:RVCT40BIN) { $env:RVCT40BIN = $RvctBin }
  $rvctData = Resolve-RvctDataPaths $RvctBin
  if ($rvctData) {
    if (-not $env:RVCT40INC) { $env:RVCT40INC = $rvctData.INC }
    if (-not $env:RVCT40LIB) { $env:RVCT40LIB = $rvctData.LIB }
  }
}

# Some Raptor builds demand RVCT22 vars exist; mirror 4.0 if missing
if (-not $env:RVCT22BIN -and $env:RVCT40BIN) { $env:RVCT22BIN = $env:RVCT40BIN }
if (-not $env:RVCT22INC -and $env:RVCT40INC) { $env:RVCT22INC = $env:RVCT40INC }
if (-not $env:RVCT22LIB -and $env:RVCT40LIB) { $env:RVCT22LIB = $env:RVCT40LIB }

# Locate sbs command
$sbs = (Get-Command sbs -ErrorAction SilentlyContinue)?.Source
if (-not $sbs -and $env:EPOCROOT) {
  $candidate = Join-Path $env:EPOCROOT 'epoc32\tools\sbs.bat'
  if (Test-Path -LiteralPath $candidate) { $sbs = $candidate }
}
if (-not $sbs) {
  throw "sbs not found. Ensure '%EPOCROOT%\\epoc32\\tools' is on PATH or pass -SdkRoot."
}

Write-Host "Using sbs: $sbs"
if ($env:EPOCROOT) { Write-Host "EPOCROOT: $env:EPOCROOT" }
if ($RvctBin) { Write-Host "RVCT bin: $RvctBin" }

function Invoke-SbsBuild {
  param(
    [string[]]$Configs,
    [string]$Label
  )

  foreach ($cfg in $Configs) {
    Write-Host "=== Building $Label with configuration: $cfg ==="
    & $sbs -b 'bld.inf' -c $cfg -v -k
    $code = $LASTEXITCODE
    if ($code -eq 0) {
      Write-Host "=== $Label build succeeded ($cfg) ==="
      return @{ Succeeded = $true; Config = $cfg }
    }
    Write-Warning "Build failed for '$cfg' with exit code $code"
  }
  return @{ Succeeded = $false }
}

# Prepare candidate configurations (rvct4_0 first, then generic)
$debugCandidates   = @("${Config}_udeb.rvct4_0",  "${Config}_udeb")
$releaseCandidates = @("${Config}_urel.rvct4_0",  "${Config}_urel")

$debugResult = $null
$releaseResult = $null

if (-not $ReleaseOnly) {
  $dr = Invoke-SbsBuild -Configs $debugCandidates -Label 'debug'
  if ($dr -is [array]) { $debugResult = $dr[-1] } else { $debugResult = $dr }
}
if (-not $DebugOnly) {
  $rr = Invoke-SbsBuild -Configs $releaseCandidates -Label 'release'
  if ($rr -is [array]) { $releaseResult = $rr[-1] } else { $releaseResult = $rr }
}

# Summarize outputs (best-effort paths)
$target = 'CosmosFM.exe'  # from CosmosFM_0xE0882321.mmp
$out = @()
if ($env:EPOCROOT) {
  if ($debugResult -and ($debugResult -is [hashtable]) -and $debugResult.ContainsKey('Succeeded') -and $debugResult['Succeeded']) {
    $out += (Join-Path $env:EPOCROOT "epoc32\\release\\$Config\\udeb\\$target")
  }
  if ($releaseResult -and ($releaseResult -is [hashtable]) -and $releaseResult.ContainsKey('Succeeded') -and $releaseResult['Succeeded']) {
    $out += (Join-Path $env:EPOCROOT "epoc32\\release\\$Config\\urel\\$target")
  }
}

if ($out.Count -gt 0) {
  Write-Host "Outputs:" -ForegroundColor Cyan
  $out | ForEach-Object { Write-Host "  $_" }
}

# Exit code reflects whether any build failed (only consider attempted builds)
$anyFailed = $false
if ($debugResult -and ($debugResult -is [hashtable]) -and $debugResult.ContainsKey('Succeeded') -and -not $debugResult['Succeeded']) { $anyFailed = $true }
if ($releaseResult -and ($releaseResult -is [hashtable]) -and $releaseResult.ContainsKey('Succeeded') -and -not $releaseResult['Succeeded']) { $anyFailed = $true }
if ($anyFailed) { exit 1 } else { exit 0 }
