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

#include <QTranslator>
#include <QCommandLineParser>
#include <QCommandLineOption>
#include <curl/curl.h>
#include <QObject>
#include <QCoreApplication>
#include <QtConcurrent>
#include "gamepad.h"
#ifdef LAUNCHER_ENABLE_GLFW
#include <QTimer>
#include <QKeyEvent>
#include <QWindow>
#include <GLFW/glfw3.h>
#endif

#ifdef LAUNCHER_DISABLE_DEV_MODE
bool LauncherSettings::disableDevMode = 1;
#else
bool LauncherSettings::disableDevMode = 0;
#endif

#ifdef GOOGLEPLAYDOWNLOADER_USEQT
Q_DECLARE_METATYPE(playapi::proto::finsky::download::AndroidAppDeliveryData)
#endif

int main(int argc, char *argv[])
{
#ifdef LAUNCHER_INIT_PATCH
    LAUNCHER_INIT_PATCH
#endif
    curl_global_init(CURL_GLOBAL_ALL);
    Q_INIT_RESOURCE(googlesigninui);
    // Issues with qt5.9 for ubuntu 16.04 in AppImages, random scale 2 or 3
    // Removed and enabled by default in qt6
    // QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QCoreApplication::setOrganizationName("Minecraft Linux Launcher");
    QCoreApplication::setOrganizationDomain("mrarm.io");
    QCoreApplication::setApplicationName("Minecraft Linux Launcher UI");

    LauncherApp app(argc, argv);
    QCommandLineParser parser;
    parser.setApplicationDescription("Minecraft Linux Launcher UI");
    parser.addPositionalArgument("file", "file or uri to open with the default profile");
    parser.addHelpOption();
    QCommandLineOption devmodeOption(QStringList() << "d" << "enable-devmode", 
        QCoreApplication::translate("main", "Developer Mode - Enable unsafe Launcher Settings"));
    parser.addOption(devmodeOption);

    QCommandLineOption verboseOption(QStringList() << "v" << "verbose", 
        QCoreApplication::translate("main", "Verbose log Qt Messages to stdout"));
    parser.addOption(verboseOption);

    QCommandLineOption profileOption(QStringList() << "p" << "profile", 
        QCoreApplication::translate("main", "directly start the game launcher with the specified profile"));
    parser.addOption(profileOption);

    parser.process(app);

    bool hasFileOrUri = parser.positionalArguments().count() == 1;

    if(parser.isSet(profileOption) || hasFileOrUri) {
        VersionManager vmanager;
        ProfileManager manager;
        auto profileName = parser.value(profileOption);
        ProfileInfo * profile = nullptr;
        if(profileName.length() > 0) {
            for(auto&& pro : manager.profiles()) {
                if(((ProfileInfo *)pro)->name == profileName) {
                    profile = (ProfileInfo *)pro;
                }
            }
            if(profile == nullptr) {
                printf("Profile not found: %s\n", profileName.toStdString().data());
                return 1;
            }
        } else {
            profile = manager.activeProfile();
        }

        GameLauncher launcher;
        launcher.logAttached();
        QObject::connect(&launcher, &GameLauncher::logAppended, [](QString str) {
            printf("%s", str.toStdString().data());
        });
        QObject::connect(&launcher, &GameLauncher::stateChanged, [&]() {
            if(!launcher.running()) {
                app.exit(launcher.crashed() ? 1 : 0);
            }
        });
        QObject::connect(&launcher, &GameLauncher::fileStarted, [&](bool success) {
            if(success) {
                app.exit(success ? 0 : 1);
            } else {
                launcher.start(false, profile->arch, true, parser.positionalArguments().at(0));
            }
        });
        launcher.setProfile(profile);
        if(profile->versionType == ProfileInfo::LATEST_GOOGLE_PLAY) {
            GoogleVersionChannel playChannel;
            launcher.setGameDir(vmanager.getDirectoryFor(vmanager.versionList()->get(playChannel.latestVersionCode())));
        } else if(profile->versionType == ProfileInfo::LOCKED_NAME) {
            launcher.setGameDir(vmanager.getDirectoryFor(profile->versionDirName));
        } else if(profile->versionType == ProfileInfo::LOCKED_CODE && profile->versionCode) {
            launcher.setGameDir(vmanager.getDirectoryFor(vmanager.versionList()->get(profile->versionCode)));
        }
        
        if(hasFileOrUri) {
            launcher.startFile(parser.positionalArguments().at(0));
        } else {
            launcher.start(false, profile->arch, true);
        }
        return app.exec();
    }

    auto verbose = parser.isSet(verboseOption);

    if(!verbose) {
        // Silence console
        qInstallMessageHandler([](QtMsgType type, const QMessageLogContext &context, const QString &msg) {});
    }

    QTranslator translator;
    if (translator.load(QLocale(), QLatin1String("mcpelauncher"), QLatin1String("_"), QLatin1String(":/translations"))) {
        app.installTranslator(&translator);
    }
#ifndef NDEBUG
    else {
        qDebug() << "cannot load translator " << QLocale().name() << " check content of translations.qrc";
    }
#endif

    app.setQuitOnLastWindowClosed(false);
#ifdef GOOGLEPLAYDOWNLOADER_USEQT
    qRegisterMetaType<playapi::proto::finsky::download::AndroidAppDeliveryData>();
#endif
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
    static GamepadManager gamepadManager;
    qmlRegisterSingletonType<Gamepad>("io.mrarm.mcpelauncher", 1, 0, "Gamepad", +[](QQmlEngine*, QJSEngine*) -> QObject* {
        return &gamepadManager;
    });

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("application", &app);
#ifdef LAUNCHER_VERSION_NAME
    engine.rootContext()->setContextProperty("LAUNCHER_VERSION_NAME", QVariant(LAUNCHER_VERSION_NAME));
#else
    engine.rootContext()->setContextProperty("LAUNCHER_VERSION_NAME", QVariant(""));
#endif
#ifdef LAUNCHER_VERSION_CODE
    engine.rootContext()->setContextProperty("LAUNCHER_VERSION_CODE", QVariant(LAUNCHER_VERSION_CODE));
#else
    engine.rootContext()->setContextProperty("LAUNCHER_VERSION_CODE", QVariant(0));
#endif
    QString license;
    QFile lfile(":/LICENSE");
    if(lfile.open(QIODevice::ReadOnly)) {
        license = lfile.readAll();
        lfile.close();
    }
#ifdef LAUNCHER_CHANGE_LOG
    engine.rootContext()->setContextProperty("LAUNCHER_CHANGE_LOG", QVariant(QString(LAUNCHER_CHANGE_LOG) + "\n" + license.replace("\n", "<br/>")));
#else
    engine.rootContext()->setContextProperty("LAUNCHER_CHANGE_LOG", QVariant(license.replace("\n", "<br/>")));
#endif
#ifdef LAUNCHER_ENABLE_GOOGLE_PLAY_LICENCE_CHECK
    engine.rootContext()->setContextProperty("LAUNCHER_ENABLE_GOOGLE_PLAY_LICENCE_CHECK", QVariant(true));
#else
    engine.rootContext()->setContextProperty("LAUNCHER_ENABLE_GOOGLE_PLAY_LICENCE_CHECK", QVariant(false));
#endif
#ifdef __APPLE__
    engine.rootContext()->setContextProperty("SHOW_ANGLEBACKEND", QVariant(true));
#else
    engine.rootContext()->setContextProperty("SHOW_ANGLEBACKEND", QVariant(false));
#endif
    engine.rootContext()->setContextProperty("DISABLE_DEV_MODE", QVariant(LauncherSettings::disableDevMode &= !parser.isSet(devmodeOption)));
    engine.load(QUrl(QStringLiteral("qrc:/qml/main.qml")));
    if (engine.rootObjects().isEmpty())
        return -1;

#ifdef LAUNCHER_ENABLE_GLFW
    glfwInitHint(GLFW_JOYSTICK_HAT_BUTTONS, GLFW_TRUE);
    glfwInit();
    QTimer *timer = new QTimer(&app);
    GLFWgamepadstate oldstate;
    memset(&oldstate, 0, sizeof(oldstate));
    //glfwSetJoystickUserPointer()
    auto addRemoveGamePad = +[](int jid, int event) {
        if(event == GLFW_CONNECTED) {
            glfwSetJoystickUserPointer(jid, nullptr);
            //gamepadManager.gamepads().emplace_back(new Gamepad(gamepadManagerRef, ))
        }
    };
    glfwSetJoystickCallback(addRemoveGamePad);
    QObject::connect(timer, &QTimer::timeout, [&]() {
        glfwPollEvents();
        if(gamepadManager.enabled()) {
            GLFWgamepadstate state;
            if(glfwGetGamepadState(0, &state) == GLFW_TRUE) {
                QObject* window = QGuiApplication::focusWindow();
                if(window) {
                    if(oldstate.buttons[GLFW_GAMEPAD_BUTTON_A] != state.buttons[GLFW_GAMEPAD_BUTTON_A]) {
                        QCoreApplication::postEvent(window, new QKeyEvent(state.buttons[GLFW_GAMEPAD_BUTTON_A] ? QEvent::Type::KeyPress : QEvent::Type::KeyRelease, Qt::Key_Enter, Qt::NoModifier), Qt::NormalEventPriority);
                    }
                    if(oldstate.buttons[GLFW_GAMEPAD_BUTTON_DPAD_LEFT] != state.buttons[GLFW_GAMEPAD_BUTTON_DPAD_LEFT]) {
                        QCoreApplication::postEvent(window, new QKeyEvent(state.buttons[GLFW_GAMEPAD_BUTTON_DPAD_LEFT] ? QEvent::Type::KeyPress : QEvent::Type::KeyRelease, Qt::Key_Backtab, Qt::NoModifier), Qt::NormalEventPriority);
                    }
                    if(oldstate.buttons[GLFW_GAMEPAD_BUTTON_DPAD_RIGHT] != state.buttons[GLFW_GAMEPAD_BUTTON_DPAD_RIGHT]) {
                        QCoreApplication::postEvent(window, new QKeyEvent(state.buttons[GLFW_GAMEPAD_BUTTON_DPAD_RIGHT] ? QEvent::Type::KeyPress : QEvent::Type::KeyRelease, Qt::Key_Tab, Qt::NoModifier), Qt::NormalEventPriority);
                    }
                    if(oldstate.buttons[GLFW_GAMEPAD_BUTTON_DPAD_DOWN] != state.buttons[GLFW_GAMEPAD_BUTTON_DPAD_DOWN]) {
                        QCoreApplication::postEvent(window, new QKeyEvent(state.buttons[GLFW_GAMEPAD_BUTTON_DPAD_DOWN] ? QEvent::Type::KeyPress : QEvent::Type::KeyRelease, Qt::Key_Down, Qt::NoModifier), Qt::NormalEventPriority);
                    }
                    if(oldstate.buttons[GLFW_GAMEPAD_BUTTON_DPAD_UP] != state.buttons[GLFW_GAMEPAD_BUTTON_DPAD_UP]) {
                        QCoreApplication::postEvent(window, new QKeyEvent(state.buttons[GLFW_GAMEPAD_BUTTON_DPAD_UP] ? QEvent::Type::KeyPress : QEvent::Type::KeyRelease, Qt::Key_Up, Qt::NoModifier), Qt::NormalEventPriority);
                    }
                    oldstate = state;
                }
            }
        } else {

        }
    });
    timer->setInterval(50);
    timer->start();
#endif

    return app.exec();
}
