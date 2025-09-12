# CosmosFM-Qt

## Build

- Simulator (Windows, Qt SDK MinGW 4.4):

  - Debug: `./scripts/build_sim.ps1 -Config debug`
  - Release: `./scripts/build_sim.ps1 -Config release`
  - Add `-StageTlsDlls` to copy Qt4 + OpenSSL DLLs next to the exe when `deps/win32/qt4-openssl/<config>` exists. If `deps/win32/qt4-openssl/plugins` exists, matching Qt plugins are staged automatically.

- Symbian (RVCT):
  - Example debug build: `./scripts/build-symbian.ps1 -SdkRoot "C:\Symbian\Tools\PDK_3.0.4" -RvctBin "C:\Program Files\ARM\RVCT\Tools\4.0\arm\bin" -DebugOnly`
  - Output: `C:\Symbian\Tools\PDK_3.0.4\epoc32\release\armv5\udeb\CosmosFM.exe`

## Package (Symbian)

- Debug (udeb): `./scripts/package-selfsigned.ps1 -SdkRoot "C:\Symbian\Tools\PDK_3.0.4" -Pkg ./CosmosFM_template.pkg -Variant udeb -OutDir ./build/sis`
- Release (urel): `./scripts/package-selfsigned.ps1 -SdkRoot "C:\Symbian\Tools\PDK_3.0.4" -Pkg ./CosmosFM_template.pkg -Variant urel -OutDir ./build/sis`
- Smart Installer: `./scripts/package-selfsigned.ps1 -SdkRoot "C:\Symbian\Tools\PDK_3.0.4" -Pkg ./CosmosFM_installer.pkg -Variant urel`

Ensure the built binary exists under your SDK’s `epoc32/release/<armv5>/<udeb|urel>/CosmosFM.exe` before packaging.

## TLS 1.1/1.2 Verification (Windows / Qt Simulator)

- Probe: `./scripts/test_tls.ps1 -Config debug -StageTlsDlls`
  - Success prints “TLS 1.2 handshake ok” and exit code 0.
- Inspect runtime: `./scripts/inspect_sim_runtime.ps1 -Config debug`
  - Flags x86/x64, toolchain (MSVC/MinGW), and debug/release mismatches.

## QML Components

- The app imports `com.nokia.symbian 1.1` when available.
- Scripts stage components from `deps/win32/qt-components` into `build-simulator/<config>/imports`.
- If you see “module "com.nokia.symbian" is not installed”, ensure the module exists under `build-simulator/imports` or set `QML_IMPORT_PATH` accordingly.

## Troubleshooting

- -1073741511 (0xC0000139) on launch:

  - Use matching Qt plugins for the Core/Gui/Declarative you stage. When `deps/win32/qt4-openssl/plugins` exists, plugins are staged automatically by `build_sim.ps1`.
  - Verify runtime with `./scripts/inspect_sim_runtime.ps1 -Config debug`.

- General:
  - Prefer staging DLLs per-build over replacing files in the SDK. It’s safer and reproducible.

## Windows (Qt Simulator) runtime layout

For where to copy Windows DLLs, plugins, and QML components used by the scripts, see:

- `deps/win32/README.md`
