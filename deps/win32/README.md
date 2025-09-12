Windows runtime deps for Qt Simulator

Where to place your custom files so scripts can stage them alongside the built app/tests.

Qt 4 + OpenSSL DLLs

- Debug DLLs → `deps/win32/qt4-openssl/debug`
  - QtCored4.dll, QtGuid4.dll, QtDeclaratived4.dll
  - QtNetworkd4.dll (or QtNetwork4d.dll)
  - ssleay32.dll, libeay32.dll (OpenSSL 1.0.x)
- Release DLLs → `deps/win32/qt4-openssl/release`
  - QtCore4.dll, QtGui4.dll, QtDeclarative4.dll
  - QtNetwork4.dll
  - ssleay32.dll, libeay32.dll

Qt plugins (recommended when replacing Core/Gui/Declarative)

- Copy the entire plugins folder from your custom Qt build to:
  - `deps/win32/qt4-openssl/plugins`
- Typical subfolders: `imageformats`, `codecs`, `bearer`, `sqldrivers`, `iconengines`, `phonon_backend`, `graphicssystems`.
- These must match the same Qt build as your DLLs to avoid startup loader errors. (copy from `C:\Symbian\qt-everywhere-opensource-src-4.7.4\plugins`)

QML components for Simulator/Desktop

- Place required QML modules under:
  - `deps/win32/qt-components`
- Example for CosmosFM on Qt 4.7.x:
  - `deps/win32/qt-components/com/nokia/symbian` (copy from `C:\Symbian\QtSDK\Simulator\Qt\mingw\imports\com\nokia\symbian.1.1`)

Using the scripts

- Build and auto-stage DLLs and plugins next to the exe:
  - Debug: `./scripts/build_sim.ps1 -Config debug -StageTlsDlls`
  - Release: `./scripts/build_sim.ps1 -Config release -StageTlsDlls`
  - When `deps/win32/qt4-openssl/plugins` exists, plugins are staged by default.
  - Add `-OnlyNetSsl` to swap only QtNetwork + OpenSSL and keep SDK Core/Gui/Declarative.
- Stage into an existing output directory:
  - `./scripts/stage_sim_runtime.ps1 -Config debug`
  - Detects and stages plugins from `deps/win32/qt4-openssl/plugins` if present.

Troubleshooting

- Use `./scripts/inspect_sim_runtime.ps1 -Config debug` to verify bitness/toolchain and debug/release matches.
- If you replace Core/Gui/Declarative without matching plugins, you may see exit code -1073741511 (0xC0000139).
