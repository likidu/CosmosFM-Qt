# CosmosFM-Qt

Build run complete — the debug build succeeded using RVCT 4.0.

What I did

- Ran scripts/build-symbian.ps1 for debug with your SDK/RVCT paths.
- Fixed env/tooling issues by updating the script:
  - Adds RVCT include/lib auto-detection.
  - Mirrors RVCT22* vars to RVCT40* to satisfy Raptor checks.
  - Makes -DebugOnly flow robust; prints outputs; exits cleanly.
  - Enables verbose sbs to aid diagnosis.

Build

- `.\scripts\build-symbian.ps1 -SdkRoot "C:\Symbian\Tools\PDK_3.0.4" -RvctBin "C:\Program Files\ARM\RVCT\Tools\4.0\arm\bin" -DebugOnly`

Result

- Outputs: `C:\Symbian\Tools\PDK_3.0.4\epoc32\release\armv5\udeb\CosmosFM.exe`

Changes

scripts/build-symbian.ps1

Want me to:

Build the release variant as well?
Add a packaging step (makesis/signsis) using CosmosFM_installer.pkg and output a signed SIS?
