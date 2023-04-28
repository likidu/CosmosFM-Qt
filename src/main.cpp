#include <QtGui/QApplication>
#include <QtDeclarative>
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

    // viewer->rootContext()->setContextProperty("user", &user);

    viewer->setOrientation(QmlApplicationViewer::ScreenOrientationLockPortrait);
    viewer->setMainQmlFile(QLatin1String("qml/CosmosFM/main.qml"));
    viewer->showExpanded();

    return app->exec();
}
