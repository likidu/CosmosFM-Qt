<#
Create a self-signed SIS package using Symbian SDK tools (makesis/signsis).

Examples:
  # Use default template PKG, assume release build exists
  .\scripts\package-selfsigned.ps1 -SdkRoot "C:\\Symbian\\Tools\\PDK_3.0.4"

  # Specify PKG explicitly and output directory
  .\scripts\package-selfsigned.ps1 -Pkg .\CosmosFM_template.pkg -OutDir .\build\sis

  # Package debug binary (udeb)
  .\scripts\package-selfsigned.ps1 -Variant udeb

  # Use the installer PKG (wraps app SIS + Qt Smart Installer)
  .\scripts\package-selfsigned.ps1 -Pkg .\CosmosFM_installer.pkg

Notes:
  - Requires EPOCROOT SDK with makesis/signsis under epoc32\tools.
  - Defaults to PLATFORM=armv5 and Variant=urel (TARGET).
#>

[CmdletBinding()]
param(
  [string]$SdkRoot,
  [string]$Pkg,
  [string]$OutDir = "build/sis",
  [ValidateSet('armv5','armv6','winscw')]
  [string]$Platform = 'armv5',
  [ValidateSet('udeb','urel')]
  [string]$Variant = 'urel',
  [string]$OutputName
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

if (-not $env:EPOCROOT) {
  throw "EPOCROOT is not set. Pass -SdkRoot or set EPOCROOT."
}

# Tools on PATH
Add-ToPath (Join-Path $env:EPOCROOT 'epoc32\tools')

# Locate tools
$makesis = (Get-Command makesis.exe -ErrorAction SilentlyContinue)?.Source
if (-not $makesis) { $makesis = (Get-Command makesis -ErrorAction SilentlyContinue)?.Source }
$signsis = (Get-Command signsis.exe -ErrorAction SilentlyContinue)?.Source
if (-not $signsis) { $signsis = (Get-Command signsis -ErrorAction SilentlyContinue)?.Source }
if (-not $makesis) { throw "makesis not found on PATH (expected under %EPOCROOT%epoc32\\tools)." }
if (-not $signsis) { throw "signsis not found on PATH (expected under %EPOCROOT%epoc32\\tools)." }

# Resolve PKG file
if (-not $Pkg) {
  if (Test-Path -LiteralPath '.\CosmosFM_template.pkg') { $Pkg = '.\CosmosFM_template.pkg' }
  elseif (Test-Path -LiteralPath '.\CosmosFM_installer.pkg') { $Pkg = '.\CosmosFM_installer.pkg' }
  else { throw "No PKG specified and default PKG files not found." }
}
if (-not (Test-Path -LiteralPath $Pkg)) { throw "PKG not found: $Pkg" }
$Pkg = (Resolve-Path -LiteralPath $Pkg).Path

# Ensure output dir
$OutDirFull = (Resolve-Path -LiteralPath (New-Item -ItemType Directory -Force -Path $OutDir)).Path

# Set macros used by PKG
$env:PLATFORM = $Platform
$env:TARGET = $Variant

# Output name
if (-not $OutputName) {
  $base = [IO.Path]::GetFileNameWithoutExtension($Pkg)
  $OutputName = "$base"
}

$unsigned = Join-Path $OutDirFull ("{0}_unsigned.sis" -f $OutputName)
$signed   = Join-Path $OutDirFull ("{0}_selfsigned.sis" -f $OutputName)
$pkgWork  = Join-Path $OutDirFull ("{0}_work.pkg" -f $OutputName)

Write-Host "Using EPOCROOT: $env:EPOCROOT"
Write-Host "PKG: $Pkg"
Write-Host "PLATFORM: $Platform  TARGET: $Variant"
Write-Host "makesis: $makesis"
Write-Host "signsis: $signsis"

# Prepare a working PKG copy and normalize header version triplet if needed
$content = Get-Content -LiteralPath $Pkg -Raw
# Regex to ensure three-part version numbers in header
$content = [System.Text.RegularExpressions.Regex]::Replace($content,
  '^\s*(#\{[^\}]+\}\s*,\s*\(0x[0-9A-Fa-f]+\)\s*,\s*)(\d+)\s*,\s*(\d+)\s*(\r?\n)',
  '$1$2,$3,0$4',
  [System.Text.RegularExpressions.RegexOptions]::Multiline)
# Replace simple macros for PLATFORM and TARGET if present
$content = $content -replace '\$\(PLATFORM\)', $Platform -replace '\$\(TARGET\)', $Variant
Set-Content -LiteralPath $pkgWork -Encoding UTF8 -NoNewline -Value $content

# Create unsigned SIS (define PKG variables used inside PKG)
& $makesis -v -DPLATFORM=$Platform -DTARGET=$Variant $pkgWork $unsigned
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $unsigned)) {
  throw "makesis failed to produce $unsigned"
}

# Self-sign
& $signsis -s $unsigned $signed | Out-Null
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $signed)) {
  throw "signsis failed to produce $signed"
}

Write-Host "Created: $signed" -ForegroundColor Cyan
