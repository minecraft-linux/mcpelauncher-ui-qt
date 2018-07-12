#ifndef LAUNCHERSETTINGS_H
#define LAUNCHERSETTINGS_H

#include <QObject>
#include <QSettings>

class LauncherSettings : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool startHideLauncher READ startHideLauncher WRITE setStartHideLauncher NOTIFY settingsChanged)
    Q_PROPERTY(bool startOpenLog READ startOpenLog WRITE setStartOpenLog NOTIFY settingsChanged)

private:
    QSettings settings;

public:
    explicit LauncherSettings(QObject *parent = nullptr) : QObject(parent), settings() {}

    bool startHideLauncher() const { return settings.value("startHideLauncher", true).toBool(); }
    void setStartHideLauncher(bool value) { settings.setValue("startHideLauncher", value); emit settingsChanged(); }

    bool startOpenLog() const { return settings.value("startOpenLog", false).toBool(); }
    void setStartOpenLog(bool value) { settings.setValue("startOpenLog", value); emit settingsChanged(); }

signals:
    void settingsChanged();

};

#endif // LAUNCHERSETTINGS_H
