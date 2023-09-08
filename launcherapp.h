#ifndef LAUNCHERAPP_H
#define LAUNCHERAPP_H

#include <QApplication>

class AppCloseEvent : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool accepted READ isAccepted WRITE setAccepted)

    bool accepted;

public:
    AppCloseEvent(bool accepted = true) : accepted(accepted) {}

    void setAccepted(bool accepted) { this->accepted = accepted; }

    bool isAccepted() const { return accepted; }

};

class LauncherApp : public QApplication {
    Q_OBJECT

public:
    LauncherApp(int &argc, char **argv);

    int launchProfileFile(QString profileName, QString filePath, bool startEventLoop = true);

public slots:
    void setVisibleInDock(bool visible);

protected:
    bool event(QEvent*) override;

signals:
    void closing(AppCloseEvent* close);

};

#endif // LAUNCHERAPP_H
