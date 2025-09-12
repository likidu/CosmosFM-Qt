Place desktop/simulator copies of QML modules required by the app here.

Typical need for CosmosFM on Qt 4.7.x:

- com.nokia.symbian 1.1 (Qt Quick Components for Symbian)

All the files at `C:\Symbian\QtSDK\Simulator\Qt\mingw\imports\com\nokia\symbian.1.1`

Layout:

- deps/win32/qt-components/
  - com
    - nokia
      - symbian
        - qmldir
        - \*.qml
        - (any plugin .dll/.qml if provided by your components build)

How to obtain:

- From your Qt Components for Symbian (Desktop) installation, copy the
  module folder (usually named like above) into this directory, preserving
  its structure.

Runtime staging:

- scripts/build_sim.ps1 with -StageTlsDlls and scripts/stage_sim_runtime.ps1
  will copy everything under deps/win32/qt-components into
  build-simulator/<config>/imports so the app can import it at runtime.
