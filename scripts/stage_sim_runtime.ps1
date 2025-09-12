<#
Stages Qt4 + OpenSSL runtime DLLs from deps/win32/qt4-openssl/<config>
into the simulator build output directory so the built app uses your
custom TLS-enabled Qt at runtime.

Usage examples:
  # Stage for debug build
  ./scripts/stage_sim_runtime.ps1 -Config debug

  # Stage for release build to a custom out dir
  ./scripts/stage_sim_runtime.ps1 -Config release -OutDir 'build-simulator\\release'
#>

Param(
    [ValidateSet('debug','release')]
    [string]$Config = 'debug',
    [string]$OutDir,
    # When set, only stage QtNetwork + OpenSSL DLLs (keep SDK's Core/Gui/Declarative)
    [switch]$OnlyNetSsl,
    # When provided, copy Qt plugin folders from this path into OutDir\plugins
    # Example: C:\Qt\4.7.4-mingw\plugins or C:\Symbian\QtSDK\Simulator\Qt\mingw\plugins (if you rebuilt there)
    [string]$QtPluginsSrc
)

$ErrorActionPreference = 'Stop'

try {
    $repoRoot = Split-Path -Parent $PSScriptRoot
    if (-not $OutDir) {
        $OutDir = Join-Path $repoRoot (Join-Path 'build-simulator' $Config)
    } elseif (-not [IO.Path]::IsPathRooted($OutDir)) {
        $OutDir = Join-Path $repoRoot $OutDir
    }

    if (-not (Test-Path $OutDir)) { throw "OutDir not found: $OutDir" }

    $src = Join-Path $repoRoot (Join-Path 'deps\\win32\\qt4-openssl' $Config)
    if (-not (Test-Path $src)) { throw "Deps folder not found: $src" }

    if ($OnlyNetSsl) {
        $dlls = @('QtNetwork4.dll','QtNetworkd4.dll','QtNetwork4d.dll','ssleay32.dll','libeay32.dll')
    } else {
        $dlls = @(
            # core Qt set used by CosmosFM
            'QtCore4.dll','QtCored4.dll','QtGui4.dll','QtGuid4.dll',
            'QtDeclarative4.dll','QtDeclaratived4.dll','QtNetwork4.dll','QtNetworkd4.dll',
            # OpenSSL pair for Qt 4
            'ssleay32.dll','libeay32.dll',
            # optional extras some QtDeclarative builds depend on
            'QtScript4.dll','QtScriptd4.dll',
            'QtXmlPatterns4.dll','QtXmlPatternsd4.dll',
            'QtOpenGL4.dll','QtOpenGLd4.dll',
            # others you might have built (copy if present)
            'QtSvg4.dll','QtSvgd4.dll','QtSql4.dll','QtSqld4.dll'
        )
    }

    New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

    foreach ($name in $dlls) {
        $path = Join-Path $src $name
        if (Test-Path $path) {
            Copy-Item -Force $path $OutDir
            Write-Host "Staged: $name"
        }
    }

    # Optionally stage Qt plugin directories (must match the same Qt build as the DLLs)
    if (-not $QtPluginsSrc) {
        # Auto-detect from deps if present
        $autoPlugins = Join-Path $repoRoot 'deps\win32\qt4-openssl\plugins'
        if (Test-Path $autoPlugins) {
            $QtPluginsSrc = $autoPlugins
            Write-Host "Auto-detected QtPluginsSrc: $QtPluginsSrc"
        }
    }

    if ($QtPluginsSrc) {
        if (-not (Test-Path $QtPluginsSrc)) { throw "QtPluginsSrc not found: $QtPluginsSrc" }
        $pluginsDst = Join-Path $OutDir 'plugins'
        New-Item -ItemType Directory -Path $pluginsDst -Force | Out-Null
        Write-Host "Staging Qt plugins from: $QtPluginsSrc -> $pluginsDst"
        # Copy common subfolders if present; otherwise copy everything under plugins
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
    }

    # Stage optional QML imports (e.g., com.nokia.symbian components) if present
    $importsSrc = Join-Path $repoRoot 'deps\win32\qt-components'
    if (Test-Path $importsSrc) {
        $importsDst1 = Join-Path $OutDir 'imports'
        New-Item -ItemType Directory -Path $importsDst1 -Force | Out-Null
        Copy-Item -Recurse -Force (Join-Path $importsSrc '*') $importsDst1

        # Also stage to the build root, which is often the working directory for QML paths
        $buildRoot = Split-Path -Parent $OutDir
        $importsDst2 = Join-Path $buildRoot 'imports'
        New-Item -ItemType Directory -Path $importsDst2 -Force | Out-Null
        Copy-Item -Recurse -Force (Join-Path $importsSrc '*') $importsDst2

        Write-Host "Staged QML imports to: $importsDst1 and $importsDst2"
    } else {
        Write-Host "No custom QML imports found at: $importsSrc (skipping)"
    }

    Write-Host "Done. DLLs staged to: $OutDir" -ForegroundColor Green
} catch {
    Write-Error $_
    exit 1
}
