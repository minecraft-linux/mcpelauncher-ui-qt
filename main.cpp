#include <QApplication>
#include <QQmlApplicationEngine>

#include "googleloginhelper.h"
#include "googleplayapi.h"
#include "versionmanager.h"
#include "apkextractiontask.h"
#include "googleapkdownloadtask.h"
#include "googleversionchannel.h"
#include "gamelauncher.h"
#include "profilemanager.h"

int main(int argc, char *argv[])
{
    Q_INIT_RESOURCE(googlesigninui);
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QCoreApplication::setOrganizationName("Minecraft Linux Launcher");
    QCoreApplication::setOrganizationDomain("mrarm.io");
    QCoreApplication::setApplicationName("Minecraft Linux Launcher UI");

    QApplication app(argc, argv);

    qmlRegisterType<GoogleAccount>("io.mrarm.mcpelauncher", 1, 0, "GoogleAccount");
    qmlRegisterType<GoogleLoginHelper>("io.mrarm.mcpelauncher", 1, 0, "GoogleLoginHelper");
    qmlRegisterType<GooglePlayApi>("io.mrarm.mcpelauncher", 1, 0, "GooglePlayApi");
    qmlRegisterType<VersionInfo>("io.mrarm.mcpelauncher", 1, 0, "VersionInfo");
    qmlRegisterType<VersionManager>("io.mrarm.mcpelauncher", 1, 0, "VersionManager");
    qmlRegisterType<ApkExtractionTask>("io.mrarm.mcpelauncher", 1, 0, "ApkExtractionTask");
    qmlRegisterType<GoogleApkDownloadTask>("io.mrarm.mcpelauncher", 1, 0, "GoogleApkDownloadTask");
    qmlRegisterType<GoogleVersionChannel>("io.mrarm.mcpelauncher", 1, 0, "GoogleVersionChannel");
    qmlRegisterType<GameLauncher>("io.mrarm.mcpelauncher", 1, 0, "GameLauncher");
    qmlRegisterType<ProfileManager>("io.mrarm.mcpelauncher", 1, 0, "ProfileManager");
    qmlRegisterType<ProfileInfo>("io.mrarm.mcpelauncher", 1, 0, "ProfileInfo");

    QQmlApplicationEngine engine;
    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));
    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
