<#
Qt Simulator (MinGW 4.4) build helper for Windows

Usage examples (PowerShell):
  # Build Debug with default SDK root
  .\scripts\build_sim.ps1 -Config debug

  # Build Release
  .\scripts\build_sim.ps1 -Config release

  # Clean rebuild
  .\scripts\build_sim.ps1 -Clean -Config debug

  # Clean only
  .\scripts\build_sim.ps1 -Clean

  # Override Qt SDK root
  .\scripts\build_sim.ps1 -QtSdkRoot 'C:\\symbian\\qtsdk' -Config debug

  # Use a custom build directory
  .\scripts\build_sim.ps1 -BuildDir 'C:\\Users\\Liki\\Repos\\CosmosFM-build-simulator-Simulator_Qt_for_MinGW_4_4__Qt_SDK__Debug'

Params:
  -Config     : 'debug'|'release' (default 'debug').
  -Clean      : Run 'make clean' in the build dir.
  -QtSdkRoot  : Qt SDK root containing 'simulator\\qt\\mingw' and 'mingw'.
  -BuildDir   : Build directory (default '<repo>\\build-simulator').
#>

Param(
    [ValidateSet('debug','release')]
    [string]$Config = 'debug',
    [switch]$Clean,
    [string]$QtSdkRoot = 'c:\symbian\qtsdk',
    [string]$BuildDir,
    # When present, copy TLS/OpenSSL runtime DLLs from deps folder to the output dir
    [switch]$StageTlsDlls,
    # When staging, only copy QtNetwork + OpenSSL (keep SDK's Core/Gui/Declarative)
    [switch]$OnlyNetSsl,
    # Stage Qt plugin folders from this source into <out>\plugins (must match your Qt DLL build)
    [switch]$StageQtPlugins,
    [string]$QtPluginsSrc
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

    # Ensure required tools and Qt DLLs are on PATH for this session
    Add-ToPathFront @($qtBin, $gccBin)

    # Resolve build directory (default to repoRoot\build-simulator)
    if ($BuildDir) {
        $buildDir = if ([IO.Path]::IsPathRooted($BuildDir)) { $BuildDir } else { Join-Path $repoRoot $BuildDir }
    } else {
        $buildDir = Join-Path $repoRoot 'build-simulator'
    }

    if ($Clean) {
        if (Test-Path $buildDir) {
            try {
                Push-Location $buildDir
                Write-Host "clean step: \"$make\" clean (cwd: $buildDir)"
                & $make clean | Write-Output
            } catch {
                Write-Warning "Clean via make failed: $($_.Exception.Message)"
            } finally {
                Pop-Location
            }
        }
        # If -Config was not explicitly provided, this is a clean-only run
        if (-not $PSBoundParameters.ContainsKey('Config')) {
            Write-Host "Clean-only requested; skipping build steps."
            exit 0
        }
    }

    if (-not (Test-Path $buildDir)) { New-Item -ItemType Directory -Path $buildDir | Out-Null }

    Push-Location $buildDir
    try {
        # Generate Makefiles per Qt Creator settings
        $cfgArg = if ($Config -ieq 'release') { 'CONFIG+=release' } else { 'CONFIG+=debug' }
        $proPath = Join-Path $repoRoot 'CosmosFM.pro'
        Write-Host "qmake step: `"$qmake`" `"$proPath`" -r -spec win32-g++ $cfgArg"
        & $qmake $proPath '-r' '-spec' 'win32-g++' $cfgArg

        # Build with parallel jobs
        $jobs = if ($env:NUMBER_OF_PROCESSORS) { [int]$env:NUMBER_OF_PROCESSORS } else { 2 }
        Write-Host "make step: `"$make`" -j $jobs (cwd: $buildDir)"
        & $make '-j' $jobs

        # Find the produced executable
        $exePath = Join-Path (Join-Path $buildDir $Config) 'CosmosFM.exe'
        if (-not (Test-Path $exePath)) {
            # Fallback: search for a plausible exe under config dir first, then anywhere in build dir
            $cand = Get-ChildItem -Recurse -File -Filter *.exe -ErrorAction SilentlyContinue |
                Where-Object { $_.FullName -like (Join-Path $buildDir $Config + '*') } |
                Select-Object -First 1
            if (-not $cand) {
                $cand = Get-ChildItem -Recurse -File -Filter *.exe -ErrorAction SilentlyContinue |
                    Where-Object { $_.Name -notmatch 'moc|uic|rcc' } |
                    Select-Object -First 1
            }
            if ($cand) { $exePath = $cand.FullName }
        }

        if (Test-Path $exePath) {
            Write-Host "Built: $exePath"
            # Optionally stage TLS/OpenSSL DLLs next to the exe to ensure runtime support
            if ($StageTlsDlls) {
                $depsRoot = Join-Path $repoRoot 'deps\win32\qt4-openssl'
                $cfgDir = if ($Config -ieq 'release') { 'release' } else { 'debug' }
                $dllSrc = Join-Path $depsRoot $cfgDir
                if (Test-Path $dllSrc) {
                    if ($OnlyNetSsl) {
                        $dlls = @('QtNetwork4.dll','QtNetworkd4.dll','QtNetwork4d.dll','ssleay32.dll','libeay32.dll')
                    } else {
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
                    }
                    foreach ($name in $dlls) {
                        $src = Join-Path $dllSrc $name
                        if (Test-Path $src) {
                            try {
                                Copy-Item -Force $src (Split-Path -Parent $exePath)
                                Write-Host "Staged: $name"
                            } catch {
                                Write-Warning "Failed to stage ${name}: $($_.Exception.Message)"
                            }
                        }
                    }
                    # Stage plugins from matching Qt build by default when detected
                    $autoPlugins = Join-Path $depsRoot 'plugins'
                    $shouldStagePlugins = $StageQtPlugins -or $QtPluginsSrc -or (Test-Path $autoPlugins)
                    if ($shouldStagePlugins) {
                        if (-not $QtPluginsSrc) { if (Test-Path $autoPlugins) { $QtPluginsSrc = $autoPlugins } }
                        if ($QtPluginsSrc -and (Test-Path $QtPluginsSrc)) {
                            $pluginsDst = Join-Path (Split-Path -Parent $exePath) 'plugins'
                            New-Item -ItemType Directory -Path $pluginsDst -Force | Out-Null
                            Write-Host "Staging Qt plugins from: $QtPluginsSrc -> $pluginsDst"
                            $common = @('imageformats','codecs','bearer','sqldrivers','phonon_backend','iconengines','graphicssystems')
                            $copiedAny = $false
                            foreach ($sub in $common) {
                                $srcDir = Join-Path $QtPluginsSrc $sub
                                if (Test-Path $srcDir) {
                                    Copy-Item -Recurse -Force (Join-Path $srcDir '*') (Join-Path $pluginsDst $sub)
                                    Write-Host "Staged plugins: $sub"
                                    $copiedAny = $true
                                }
                            }
                            if (-not $copiedAny) {
                                Copy-Item -Recurse -Force (Join-Path $QtPluginsSrc '*') $pluginsDst
                                Write-Host "Staged all plugin contents under: $QtPluginsSrc"
                            }
                        } else {
                            Write-Warning "QtPluginsSrc not found: $QtPluginsSrc (skipping plugin staging)"
                        }
                    }
                } else {
                    Write-Warning "TLS deps folder not found: $dllSrc"
                }

                # Also stage optional QML imports (e.g., com.nokia.symbian)
                $importsSrc = Join-Path $repoRoot 'deps\win32\qt-components'
                if (Test-Path $importsSrc) {
                    $outDir = Split-Path -Parent $exePath
                    $importsDst1 = Join-Path $outDir 'imports'
                    New-Item -ItemType Directory -Path $importsDst1 -Force | Out-Null
                    Copy-Item -Recurse -Force (Join-Path $importsSrc '*') $importsDst1

                    # Also stage to the build root (often the working directory)
                    $buildRoot = Split-Path -Parent $outDir
                    $importsDst2 = Join-Path $buildRoot 'imports'
                    New-Item -ItemType Directory -Path $importsDst2 -Force | Out-Null
                    Copy-Item -Recurse -Force (Join-Path $importsSrc '*') $importsDst2

                    Write-Host "Staged QML imports to: $importsDst1 and $importsDst2"
                }
            }
        } else {
            throw "Build finished but no executable was found under $buildDir"
        }
    } finally {
        Pop-Location
    }
} catch {
    Write-Error $_
    exit 1
}
