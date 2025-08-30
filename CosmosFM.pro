VERSION = 0.1
DEFINES += VER=\"$$VERSION\"

# Add more folders to ship with the application, here
folder_01.source = qml/CosmosFM
folder_01.target = qml
DEPLOYMENTFOLDERS = folder_01

# Additional import path used to resolve QML modules in Creator's code model
QML_IMPORT_PATH =

symbian:TARGET.UID3 = 0xE0882321

# Smart Installer package's UID
# This UID is from the protected range and therefore the package will
# fail to install if self-signed. By default qmake uses the unprotected
# range value if unprotected UID is defined for the application and
# 0x2002CCCF value if protected UID is given to the application
#symbian:DEPLOYMENT.installer_header = 0x2002CCCF

# Allow network access on Symbian
symbian:TARGET.CAPABILITY += NetworkServices

# If your application uses the Qt Mobility libraries, uncomment the following
# lines and add the respective components to the MOBILITY variable.
CONFIG += mobility
MOBILITY += systeminfo

# Speed up launching on MeeGo/Harmattan when using applauncherd daemon
# CONFIG += qdeclarative-boostable

# Add dependency to Symbian components
CONFIG += qt-components

HEADERS += \
    src/user.h \
    src/api.h  \
    src/client.h

# The .cpp file which was generated for your project. Feel free to hack it.
SOURCES += \
    src/main.cpp \
    src/user.cpp \
    src/client.cpp

include(lib/qjson/qjson.pri)
DEFINES += QJSON_MAKEDLL

# Please do not modify the following two lines. Required for deployment.
QT += network
include(qmlapplicationviewer/qmlapplicationviewer.pri)

# Avoid Qt Creator emulator deployment make fragments when building via SBSv2 on Symbian
symbian: {
    # Rely on standard Symbian build without qtcAddDeployment to prevent flm errors
} else {
    qtcAddDeployment()
}
