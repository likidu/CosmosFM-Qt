#include <QtGui/QApplication>
#include <QtDeclarative>
#include <QtCore/QFileInfo>
#include <QtCore/QDir>
#include <QtCore/QByteArray>
#include <QtCore/QDebug>
#include "qmlapplicationviewer.h"
#include "user.h"

#define RegisterPlugin(Plugin) \
    qmlRegisterType<Plugin>("design.liya.cosmosfm", 1, 0, #Plugin)

Q_DECL_EXPORT int main(int argc, char *argv[])
{
    QScopedPointer<QApplication> app(createApplication(argc, argv));

    app->setApplicationName("CosmosFM");
    app->setOrganizationName("Liya.Design");
    // app->setApplicationVersion(VER);

    // Register the User class as a QML type
    RegisterPlugin(User);

    // QmlApplicationViewer viewer;
    QScopedPointer<QmlApplicationViewer> viewer(new QmlApplicationViewer());

    // Allow loading QML modules (e.g., com.nokia.symbian) from a local 'imports' dir
    // next to the executable when running in the Simulator/Desktop.
    viewer->addImportPath(QLatin1String("imports"));

    // viewer->rootContext()->setContextProperty("user", &user);

    viewer->setOrientation(QmlApplicationViewer::ScreenOrientationLockPortrait);

    // Choose QML entrypoint:
    // - Prefer Symbian Components if their plugin exists in staged imports
    // - Otherwise fall back to Qt.labs.components for desktop/simulator
    // - Allow forcing desktop via env var COSMOSFM_FORCE_DESKTOP=1
    const bool forceDesktop = qgetenv("COSMOSFM_FORCE_DESKTOP").toLower() == "1"
                           || qgetenv("COSMOSFM_FORCE_DESKTOP").toLower() == "true";

    QString appDir = QCoreApplication::applicationDirPath();
    // Consider both the exe dir and its parent (Qt Creator often runs with the
    // build root as working directory and we stage imports in both places).
    QStringList baseDirs;
    baseDirs << appDir;
    baseDirs << QDir(appDir).absoluteFilePath(QLatin1String("../"));

    // Detect Symbian Components plugin (com.nokia.symbian)
    const QStringList symbianRel = QStringList()
        << QLatin1String("imports/com/nokia/symbian/symbianplugin_1_1d.dll")
        << QLatin1String("imports/com/nokia/symbian/symbianplugin_1_1.dll")
        << QLatin1String("imports/com/nokia/symbian/qtcomponentsplugin_1_1d.dll")
        << QLatin1String("imports/com/nokia/symbian/qtcomponentsplugin_1_1.dll");
    bool haveSymbianComponents = false;
    if (!forceDesktop) {
        for (int i = 0; i < baseDirs.size() && !haveSymbianComponents; ++i) {
            const QString &bd = baseDirs.at(i);
            for (int j = 0; j < symbianRel.size(); ++j) {
                const QString candidate = QDir(bd).absoluteFilePath(symbianRel.at(j));
                if (QFileInfo(candidate).exists()) { haveSymbianComponents = true; break; }
            }
        }
    }
    const QString mainQml = haveSymbianComponents && !forceDesktop
        ? QLatin1String("qml/CosmosFM/main.qml")
        : QLatin1String("qml/CosmosFM/main_desktop.qml");

    qWarning() << "Using QML:" << mainQml
               << "forceDesktop=" << forceDesktop
               << "haveSymbianComponents=" << haveSymbianComponents
               << "appDir=" << appDir;

    viewer->setMainQmlFile(mainQml);
    viewer->showExpanded();

    return app->exec();
}
