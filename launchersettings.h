#ifndef LAUNCHERSETTINGS_H
#define LAUNCHERSETTINGS_H

#include <QObject>
#include <QSettings>
#include <QDir>
#include <QStandardPaths>

class LauncherSettings : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool startHideLauncher READ startHideLauncher WRITE setStartHideLauncher NOTIFY settingsChanged)
    Q_PROPERTY(bool startOpenLog READ startOpenLog WRITE setStartOpenLog NOTIFY settingsChanged)
    Q_PROPERTY(bool disableGameLog READ disableGameLog WRITE setDisableGameLog NOTIFY settingsChanged)
    Q_PROPERTY(bool checkForUpdates READ checkForUpdates WRITE setCheckForUpdates NOTIFY settingsChanged)
    Q_PROPERTY(QUrl gameDataDir READ gameDataDir)

private:
    QSettings settings;

public:
    explicit LauncherSettings(QObject *parent = nullptr) : QObject(parent), settings() {}

    bool startHideLauncher() const { return settings.value("startHideLauncher", true).toBool(); }
    void setStartHideLauncher(bool value) { settings.setValue("startHideLauncher", value); emit settingsChanged(); }

    bool startOpenLog() const { return settings.value("startOpenLog", false).toBool(); }
    void setStartOpenLog(bool value) { settings.setValue("startOpenLog", value); emit settingsChanged(); }

    bool disableGameLog() const { return settings.value("disableGameLog", false).toBool(); }
    void setDisableGameLog(bool value) { settings.setValue("disableGameLog", value); emit settingsChanged(); }

    bool checkForUpdates() const { return settings.value("checkForUpdates", true).toBool(); }
    void setCheckForUpdates(bool value) { settings.setValue("checkForUpdates", value); emit settingsChanged(); }

    QUrl gameDataDir() {
        return QUrl::fromLocalFile(QDir(QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation)).filePath("mcpelauncher"));
    }
signals:
    void settingsChanged();

};

#endif // LAUNCHERSETTINGS_H
