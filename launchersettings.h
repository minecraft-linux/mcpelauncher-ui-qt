#ifndef LAUNCHERSETTINGS_H
#define LAUNCHERSETTINGS_H

#include <QObject>
#include <QSettings>
#include <QDir>
#include <QStandardPaths>
#include <QUrl>

class LauncherSettings : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool startHideLauncher READ startHideLauncher WRITE setStartHideLauncher NOTIFY settingsChanged)
    Q_PROPERTY(bool startOpenLog READ startOpenLog WRITE setStartOpenLog NOTIFY settingsChanged)
    Q_PROPERTY(bool disableGameLog READ disableGameLog WRITE setDisableGameLog NOTIFY settingsChanged)
    Q_PROPERTY(bool checkForUpdates READ checkForUpdates WRITE setCheckForUpdates NOTIFY settingsChanged)
    Q_PROPERTY(bool showUnverified READ showUnverified WRITE setShowUnverified NOTIFY settingsChanged)
    Q_PROPERTY(bool showUnsupported READ showUnsupported WRITE setShowUnsupported NOTIFY settingsChanged)
    Q_PROPERTY(bool showBetaVersions READ showBetaVersions WRITE setShowBetaVersions NOTIFY settingsChanged)
    Q_PROPERTY(int lastVersion READ lastVersion WRITE setLastVersion NOTIFY settingsChanged)
    Q_PROPERTY(QUrl gameDataDir READ gameDataDir)
    Q_PROPERTY(QString versionsFeedBaseUrl READ versionsFeedBaseUrl WRITE setVersionsFeedBaseUrl NOTIFY settingsChanged)

private:
    QSettings settings;

public:
    static bool disableDevMode;
    
    explicit LauncherSettings(QObject *parent = nullptr) : QObject(parent), settings() {}

    bool startHideLauncher() const { return settings.value("startHideLauncher", true).toBool(); }
    void setStartHideLauncher(bool value) { settings.setValue("startHideLauncher", value); emit settingsChanged(); }

    bool startOpenLog() const { return settings.value("startOpenLog", false).toBool(); }
    void setStartOpenLog(bool value) { settings.setValue("startOpenLog", value); emit settingsChanged(); }

    bool disableGameLog() const { return settings.value("disableGameLog", false).toBool(); }
    void setDisableGameLog(bool value) { settings.setValue("disableGameLog", value); emit settingsChanged(); }

    bool checkForUpdates() const { return settings.value("checkForUpdates", true).toBool(); }
    void setCheckForUpdates(bool value) { settings.setValue("checkForUpdates", value); emit settingsChanged(); }

    bool showUnverified() const { return !disableDevMode && settings.value("showUnverified", false).toBool(); }
    void setShowUnverified(bool value) { settings.setValue("showUnverified", value); emit settingsChanged(); }

    bool showUnsupported() const { return !disableDevMode && settings.value("showUnsupported", false).toBool(); }
    void setShowUnsupported(bool value) { settings.setValue("showUnsupported", value); emit settingsChanged(); }

    bool showBetaVersions() const { return !disableDevMode && settings.value("showBetaVersions", false).toBool(); }
    void setShowBetaVersions(bool value) { settings.setValue("showBetaVersions", value); emit settingsChanged(); }

    int lastVersion() const { return settings.value("lastVersion", 0).toInt(); }
    void setLastVersion(int value) { settings.setValue("lastVersion", value); emit settingsChanged(); }

    QUrl gameDataDir() {
        return QUrl::fromLocalFile(QDir(QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation)).filePath("mcpelauncher"));
    }

    QString versionsFeedBaseUrl() const { return !disableDevMode ? settings.value("versionsFeedBaseUrl", "").toString() : ""; }
    void setVersionsFeedBaseUrl(QString value) { settings.setValue("versionsFeedBaseUrl", value); emit settingsChanged(); }

public slots:
    void resetSettings() {
        settings.clear();
    }

signals:
    void settingsChanged();

};

#endif // LAUNCHERSETTINGS_H
