#include <QApplication>
#include <QQmlApplicationEngine>

#include "googleloginhelper.h"

int main(int argc, char *argv[])
{
    Q_INIT_RESOURCE(googlesigninui);
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);

    QApplication app(argc, argv);

    qmlRegisterType<GoogleAccount>("io.mrarm.mcpelauncher", 1, 0, "GoogleAccount");
    qmlRegisterType<GoogleLoginHelper>("io.mrarm.mcpelauncher", 1, 0, "GoogleLoginHelper");

    QQmlApplicationEngine engine;
    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));
    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
