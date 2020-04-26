#include "launcherapp.h"
#include <QIcon>

LauncherApp::LauncherApp(int &argc, char **argv) : QApplication(argc, argv) {
    auto appdir = getenv("APPDIR");
    if(appdir != nullptr)
        setWindowIcon(QIcon(QString::fromUtf8(appdir) + "/mcpelauncher-ui-qt.png"));
}

bool LauncherApp::event(QEvent *event) {
    if (event->type() == QEvent::Close) {
        AppCloseEvent qmlEvent;
        emit closing(&qmlEvent);
        if (!qmlEvent.isAccepted()) {
            event->setAccepted(false);
            return true;
        }
    }
    return QApplication::event(event);
}


#ifndef __APPLE__
void LauncherApp::setVisibleInDock(bool) {
    // stub
}
#endif
