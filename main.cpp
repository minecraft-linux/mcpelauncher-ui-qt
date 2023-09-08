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
#include <fstream>
#include <sstream>
#include <mcpelauncher/path_helper.h>

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

    QCommandLineOption profileOptionLegacy(QStringList() << "p" << "profile", 
        QCoreApplication::translate("main", "directly start the game launcher with the specified profile"));

    QCommandLineOption profileOption(QStringList() << "p" << "profile", 
        QCoreApplication::translate("main", "directly start the game launcher with the specified profile"), "profileName", "");
    parser.addOption(profileOption);

    if(!parser.parse(app.arguments())) {
        // TODO remove legacyParser once the old -p flag is deprecated
        parser.~QCommandLineParser();
        new (&parser) QCommandLineParser();
        parser.addPositionalArgument("file", "file or uri to open with the default profile");
        parser.addHelpOption();
        parser.addOption(devmodeOption);
        parser.addOption(verboseOption);
        parser.addOption(profileOptionLegacy);
        parser.process(app);
    } else if(parser.isSet("help") || parser.isSet("help-all")) {
        parser.process(app);
    }
    
    bool hasFileOrUri = parser.positionalArguments().count() == 1;

    if(parser.isSet(profileOption) || parser.isSet(profileOptionLegacy) || hasFileOrUri) {
        return app.launchProfileFile(parser.value(profileOption), hasFileOrUri ? parser.positionalArguments().at(0) : "");
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
    static GamepadManager* gamepadManager = new GamepadManager();
    qmlRegisterSingletonType<GamepadManager>("io.mrarm.mcpelauncher", 1, 0, "GamepadManager", +[](QQmlEngine*, QJSEngine*) -> QObject* {
        return gamepadManager;
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
    glfwInitHint(GLFW_JOYSTICK_HAT_BUTTONS, GLFW_FALSE);
    glfwInit();
    std::vector<std::string> controllerDbPaths;
    PathHelper::findAllDataFiles("gamecontrollerdb.txt", [&controllerDbPaths](std::string const& path) {
        controllerDbPaths.push_back(path);
    });
    // Bugfix: allow users to change internal gamepad layouts
    std::reverse(controllerDbPaths.begin(), controllerDbPaths.end());
    for(std::string const& path : controllerDbPaths) {
        printf("Loading gamepad mappings: %s\n", path.c_str());
        std::ifstream mapping(path.data(), std::ios::binary);
        if(mapping.is_open()) {
            std::stringstream file;
            file << mapping.rdbuf();
            glfwUpdateGamepadMappings(file.str().data());
        }
    }
    QTimer *timer = new QTimer(&app);
    GLFWgamepadstate oldstate;
    memset(&oldstate, 0, sizeof(oldstate));
    auto addRemoveGamePad = +[](int jid, int event) {
        if(event == GLFW_CONNECTED) {
            auto guid = glfwGetJoystickGUID(jid);
            auto name = glfwGetJoystickName(jid);
            int axescount, hatscount, buttonscount;
            if (!glfwGetJoystickAxes(jid, &axescount)) {
                axescount = 0;
            }
            if (!glfwGetJoystickHats(jid, &hatscount)) {
                hatscount = 0;
            }
            if (!glfwGetJoystickButtons(jid, &buttonscount)) {
                buttonscount = 0;
            }
            std::ostringstream mapping;
            mapping << guid << "," << name;
            const char* btns[] = { "a", "b", "x", "y", "leftshoulder", "rightshoulder", "righttrigger", "lefttrigger", "back", "start", "leftstick", "rightstick", "guide", "dpleft", "dpdown", "dpright", "dpup" };
            const char* axes[] = { "leftx", "lefty", "rightx", "righty", "lefttrigger", "righttrigger" };
            if (axescount) {
                std::ostringstream submap;
                for (size_t i = 0; i < axescount && i < sizeof(axes) / sizeof(axes[0]); i++) {
                    submap << "," << axes[i] << ":a" << i;
                }
                mapping << submap.str();
            }
            const char* hats[] = { "dpup", "dpright", "dpdown", "dpleft" };
            if (hatscount) {
                std::ostringstream submap;
                for (size_t i = 0; i < hatscount && i < sizeof(hats) / sizeof(hats[0]) / 4; i++) {
                   for (size_t j = 0; j < 4; j++) {
                       submap << "," << hats[i*4 + j] << ":h" << i << "." << (1 << j);
                   }
                }
                mapping << submap.str();
            }
            if (buttonscount) {
                std::ostringstream submap;
                for (size_t i = 0; i < buttonscount && i < sizeof(btns) / sizeof(btns[0]); i++) {
                    submap << "," << btns[i] << ":b" << i;
                }
                mapping << submap.str();
            }
            auto mapstr = mapping.str();
            mapstr = mapstr + ",platform:Linux,\n" + mapstr + ",platform:Mac OS X,";
            auto gamepad = new Gamepad(gamepadManager, jid, guid, name, QString::fromStdString(mapstr));
            glfwSetJoystickUserPointer(jid, gamepad);
            ((Gamepad*)gamepad)->setHasMapping(glfwJoystickIsGamepad(jid));
            gamepadManager->gamepads().append(gamepad);
        } else {
            auto gamepad = (Gamepad*)glfwGetJoystickUserPointer(jid);
            gamepadManager->gamepads().removeOne(gamepad);
        }
        gamepadManager->gamepadsChanged();
    };
    glfwSetJoystickCallback(addRemoveGamePad);
    for(int i = GLFW_JOYSTICK_1; i < GLFW_JOYSTICK_LAST; i++) {
        if(glfwJoystickPresent(i)) {
            addRemoveGamePad(i, GLFW_CONNECTED);
        }
    }
    QObject::connect(timer, &QTimer::timeout, [&]() {
        glfwPollEvents();
        if(gamepadManager->enabled()) {
            for(auto&& gamepad : gamepadManager->gamepads()) {
                GLFWgamepadstate state;
                if(glfwGetGamepadState(((Gamepad*)gamepad)->id(), &state) == GLFW_TRUE) {
                    QObject* window = QGuiApplication::focusWindow();
                    if(window) {
                        if(oldstate.buttons[GLFW_GAMEPAD_BUTTON_A] != state.buttons[GLFW_GAMEPAD_BUTTON_A]) {
                            QCoreApplication::postEvent(window, new QKeyEvent(state.buttons[GLFW_GAMEPAD_BUTTON_A] ? QEvent::Type::KeyPress : QEvent::Type::KeyRelease, Qt::Key_Space, Qt::NoModifier), Qt::NormalEventPriority);
                        }
                        if(oldstate.buttons[GLFW_GAMEPAD_BUTTON_B] != state.buttons[GLFW_GAMEPAD_BUTTON_B]) {
                            QCoreApplication::postEvent(window, new QKeyEvent(state.buttons[GLFW_GAMEPAD_BUTTON_B] ? QEvent::Type::KeyPress : QEvent::Type::KeyRelease, Qt::Key_Escape, Qt::NoModifier), Qt::NormalEventPriority);
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
            }
        }
        for(auto&& gamepad : gamepadManager->gamepads()) {
            auto joystick = ((Gamepad*)gamepad)->id();
            int axesCount, hatsCount, buttonsCount;
            auto axes = glfwGetJoystickAxes(joystick, &axesCount);  
            auto hats = glfwGetJoystickHats(joystick, &hatsCount);
            auto buttons = glfwGetJoystickButtons(joystick, &buttonsCount);
            ((Gamepad*)gamepad)->updateInput(buttons, buttonsCount, hats, hatsCount, axes, axesCount);
            ((Gamepad*)gamepad)->setHasMapping(glfwJoystickIsGamepad(joystick));
        }
    });
    timer->setInterval(50);
    timer->start();
#endif

    return app.exec();
}
