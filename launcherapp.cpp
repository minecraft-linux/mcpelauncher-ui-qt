#include "launcherapp.h"

LauncherApp::LauncherApp(int &argc, char **argv) : QApplication(argc, argv) {
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
