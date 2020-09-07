#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

#include "googleloginhelper.h"
#include "googleplayapi.h"
#include "versionmanager.h"
#include "apkextractiontask.h"
#include "googleapkdownloadtask.h"
#include "googleversionchannel.h"
#include "gamelauncher.h"
#include "profilemanager.h"
#include "qmlurlutils.h"
#include "launchersettings.h"
#include "launcherapp.h"
#include "troubleshooter.h"
#include "updatechecker.h"
#include <curl/curl.h>

int main(int argc, char *argv[])
{
#ifdef LAUNCHER_INIT_PATCH
    LAUNCHER_INIT_PATCH
#endif
    curl_global_init(CURL_GLOBAL_ALL);
    Q_INIT_RESOURCE(googlesigninui);
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QCoreApplication::setOrganizationName("Minecraft Linux Launcher");
    QCoreApplication::setOrganizationDomain("mrarm.io");
    QCoreApplication::setApplicationName("Minecraft Linux Launcher UI");

    LauncherApp app(argc, argv);

    app.setQuitOnLastWindowClosed(false);
    qmlRegisterType<QEvent>();
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
    qmlRegisterType<ArchivalVersionInfo>("io.mrarm.mcpelauncher", 1, 0, "ArchivalVersionInfo");
    qmlRegisterType<LauncherSettings>("io.mrarm.mcpelauncher", 1, 0, "LauncherSettings");
    qmlRegisterType<Troubleshooter>("io.mrarm.mcpelauncher", 1, 0, "Troubleshooter");
    qmlRegisterType<UpdateChecker>("io.mrarm.mcpelauncher", 1, 0, "UpdateChecker");
    qmlRegisterSingletonType<QmlUrlUtils>("io.mrarm.mcpelauncher", 1, 0, "QmlUrlUtils", &QmlUrlUtils::createInstance);

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("application", &app);
#ifdef LAUNCHER_VERSION_NAME
    engine.rootContext()->setContextProperty("LAUNCHER_VERSION_NAME", QVariant(LAUNCHER_VERSION_NAME));
#else
    engine.rootContext()->setContextProperty("LAUNCHER_VERSION_NAME", QVariant("Unknown OpenSource Build"));
#endif
#ifdef LAUNCHER_VERSION_CODE
    engine.rootContext()->setContextProperty("LAUNCHER_VERSION_CODE", QVariant(LAUNCHER_VERSION_CODE));
#else
    engine.rootContext()->setContextProperty("LAUNCHER_VERSION_CODE", QVariant(0));
#endif
#ifdef LAUNCHER_VERSION_LOG
    engine.rootContext()->setContextProperty("LAUNCHER_CHANGE_LOG", QVariant(LAUNCHER_CHANGE_LOG));
#else
    engine.rootContext()->setContextProperty("LAUNCHER_CHANGE_LOG", QVariant(""));
#endif
    engine.load(QUrl(QStringLiteral("qrc:/qml/main.qml")));
    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
