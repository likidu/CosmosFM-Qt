<#
Builds and runs a tiny Qt4 console app that verifies TLS 1.2 works at runtime.

It uses the same Qt SDK toolchain as scripts/build_sim.ps1 and will optionally
stage TLS/OpenSSL runtime DLLs from deps/win32/qt4-openssl/<config> next to the test exe.

Usage:
  .\scripts\test_tls.ps1 -Config debug -StageTlsDlls
  .\scripts\test_tls.ps1 -Config release -QtSdkRoot 'C:\\symbian\\qtsdk' -StageTlsDlls
#>

Param(
    [ValidateSet('debug','release')]
    [string]$Config = 'debug',
    [string]$QtSdkRoot = 'c:\symbian\qtsdk',
    [switch]$StageTlsDlls
)

$ErrorActionPreference = 'Stop'

function Add-ToPathFront([string[]]$paths) {
    $front = ($paths | Where-Object { $_ -and (Test-Path $_) }) -join ';'
    if (-not [string]::IsNullOrWhiteSpace($front)) {
        $env:PATH = "$front;$env:PATH"
    }
}

try {
    $repoRoot = Split-Path -Parent $PSScriptRoot
    Set-Location $repoRoot

    $qmake = Join-Path $QtSdkRoot 'simulator\qt\mingw\bin\qmake.exe'
    $make  = Join-Path $QtSdkRoot 'mingw\bin\mingw32-make.exe'
    $qtBin = Join-Path $QtSdkRoot 'simulator\qt\mingw\bin'
    $gccBin = Join-Path $QtSdkRoot 'mingw\bin'

    if (-not (Test-Path $qmake)) { throw "qmake not found: $qmake" }
    if (-not (Test-Path $make))  { throw "mingw32-make not found: $make" }

    Add-ToPathFront @($qtBin, $gccBin)

    $buildDir = Join-Path $repoRoot 'build-simulator\tlscheck'
    if (-not (Test-Path $buildDir)) { New-Item -ItemType Directory -Path $buildDir | Out-Null }

    Push-Location $buildDir
    try {
        $cfgArg = if ($Config -ieq 'release') { 'CONFIG+=release' } else { 'CONFIG+=debug' }
        $proPath = Join-Path $repoRoot 'tests\tlscheck\tlscheck.pro'
        Write-Host "qmake: `"$qmake`" `"$proPath`" -r -spec win32-g++ $cfgArg"
        & $qmake $proPath '-r' '-spec' 'win32-g++' $cfgArg
        if ($LASTEXITCODE -ne 0) { throw "qmake failed with exit code $LASTEXITCODE" }

        $jobs = if ($env:NUMBER_OF_PROCESSORS) { [int]$env:NUMBER_OF_PROCESSORS } else { 2 }
        Write-Host "make: `"$make`" -j $jobs (cwd: $buildDir)"
        & $make '-j' $jobs
        if ($LASTEXITCODE -ne 0) { throw "mingw32-make failed with exit code $LASTEXITCODE" }

        # Locate built exe under config subdir
        $exe = Join-Path (Join-Path $buildDir $Config) 'tlscheck.exe'
        if (-not (Test-Path $exe)) {
            $cand = Get-ChildItem -Recurse -File -Filter tlscheck.exe -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($cand) { $exe = $cand.FullName }
        }
        if (-not (Test-Path $exe)) { throw "tlscheck.exe not found under $buildDir" }

        if ($StageTlsDlls) {
            $depsRoot = Join-Path $repoRoot 'deps\win32\qt4-openssl'
            $cfgDir = if ($Config -ieq 'release') { 'release' } else { 'debug' }
            $dllSrc = Join-Path $depsRoot $cfgDir
            if (Test-Path $dllSrc) {
                $dlls = @(
                    'QtNetwork4.dll','QtNetworkd4.dll','QtNetwork4d.dll',
                    'QtCore4.dll','QtCored4.dll','QtGui4.dll','QtGuid4.dll',
                    'QtDeclarative4.dll','QtDeclaratived4.dll',
                    # optional extras if your build needs them
                    'QtScript4.dll','QtScriptd4.dll',
                    'QtXmlPatterns4.dll','QtXmlPatternsd4.dll',
                    'QtOpenGL4.dll','QtOpenGLd4.dll',
                    'ssleay32.dll','libeay32.dll'
                )
                foreach ($name in $dlls) {
                    $src = Join-Path $dllSrc $name
                    if (Test-Path $src) {
                        Copy-Item -Force $src (Split-Path -Parent $exe)
                        Write-Host "Staged: $name"
                    }
                }
            } else {
                Write-Warning "TLS deps folder not found: $dllSrc"
            }
        }

        Write-Host "Running: $exe"
        & $exe
        $code = $LASTEXITCODE
        if ($code -eq 0) {
            Write-Host "TLS check: SUCCESS (TLS 1.2 handshake ok)" -ForegroundColor Green
        } else {
            Write-Error "TLS check: FAILED with exit code $code"
            exit $code
        }
    } finally {
        Pop-Location
    }
} catch {
    Write-Error $_
    exit 1
}
