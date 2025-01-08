#ifndef LAUNCHERSETTINGS_H
#define LAUNCHERSETTINGS_H

#include <QObject>
#include <QSettings>
#include <QDir>
#include <QStandardPaths>
#include <QUrl>
#include <QClipboard>
#include <QApplication>


class LauncherSettings : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool startHideLauncher READ startHideLauncher WRITE setStartHideLauncher NOTIFY settingsChanged)
    Q_PROPERTY(bool startOpenLog READ startOpenLog WRITE setStartOpenLog NOTIFY settingsChanged)
    Q_PROPERTY(bool disableGameLog READ disableGameLog WRITE setDisableGameLog NOTIFY settingsChanged)
    Q_PROPERTY(bool checkForUpdates READ checkForUpdates WRITE setCheckForUpdates NOTIFY settingsChanged)
    Q_PROPERTY(bool showExitButton READ showExitButton WRITE setShowExitButton NOTIFY settingsChanged)
    Q_PROPERTY(bool showUnverified READ showUnverified WRITE setShowUnverified NOTIFY settingsChanged)
    Q_PROPERTY(bool showUnsupported READ showUnsupported WRITE setShowUnsupported NOTIFY settingsChanged)
    Q_PROPERTY(bool showBetaVersions READ showBetaVersions WRITE setShowBetaVersions NOTIFY settingsChanged)
    Q_PROPERTY(bool downloadOnly READ downloadOnly WRITE setDownloadOnly NOTIFY settingsChanged)
    Q_PROPERTY(QString singleArch READ singleArch WRITE setSingleArch NOTIFY settingsChanged)
    Q_PROPERTY(long long lastVersion READ lastVersion WRITE setLastVersion NOTIFY settingsChanged)
    Q_PROPERTY(QUrl gameDataDir READ gameDataDir)
    Q_PROPERTY(QString versionsFeedBaseUrl READ versionsFeedBaseUrl WRITE setVersionsFeedBaseUrl NOTIFY settingsChanged)
    Q_PROPERTY(bool showNotifications READ showNotifications WRITE setShowNotifications NOTIFY settingsChanged)
    Q_PROPERTY(QString clipboard READ clipboard WRITE setClipboard NOTIFY clipboardChanged)
    Q_PROPERTY(bool chromeOSMode READ chromeOSMode WRITE setChromeOSMode NOTIFY settingsChanged)
    Q_PROPERTY(bool keepApks READ keepApks WRITE setKeepApks NOTIFY settingsChanged)
    Q_PROPERTY(bool trialMode READ trialMode WRITE setTrialMode NOTIFY settingsChanged)

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

    bool showExitButton() const { return settings.value("showExitButton", false).toBool(); }
    void setShowExitButton(bool value) { settings.setValue("showExitButton", value); emit settingsChanged(); }

    bool showUnverified() const { return !disableDevMode && settings.value("showUnverified", false).toBool(); }
    void setShowUnverified(bool value) { settings.setValue("showUnverified", value); emit settingsChanged(); }

    bool showUnsupported() const { return !disableDevMode && settings.value("showUnsupported", false).toBool(); }
    void setShowUnsupported(bool value) { settings.setValue("showUnsupported", value); emit settingsChanged(); }

    bool downloadOnly() const { return !disableDevMode && settings.value("downloadOnly", false).toBool(); }
    void setDownloadOnly(bool value) { settings.setValue("downloadOnly", value); emit settingsChanged(); }

    QString singleArch() const { return !disableDevMode ? settings.value("singleArch", "").toString() : ""; }
    void setSingleArch(QString value) { settings.setValue("singleArch", value); emit settingsChanged(); }

    bool showBetaVersions() const { return !disableDevMode && settings.value("showBetaVersions", false).toBool(); }
    void setShowBetaVersions(bool value) { settings.setValue("showBetaVersions", value); emit settingsChanged(); }

    long long lastVersion() const { return settings.value("lastVersion", 0).toLongLong(); }
    void setLastVersion(long long value) { settings.setValue("lastVersion", QVariant(value)); emit settingsChanged(); }

    bool showNotifications() const { return settings.value("showNotifications", true).toBool(); }
    void setShowNotifications(bool value) { settings.setValue("showNotifications", value); emit settingsChanged(); }

    QUrl gameDataDir() {
        return QUrl::fromLocalFile(QDir(QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation)).filePath("mcpelauncher"));
    }

    QString versionsFeedBaseUrl() const { return !disableDevMode ? settings.value("versionsFeedBaseUrl", "").toString() : ""; }
    void setVersionsFeedBaseUrl(QString value) { settings.setValue("versionsFeedBaseUrl", value); emit settingsChanged(); }

    QString clipboard() const {
        return QApplication::clipboard()->text();
    }

    void setClipboard(QString text) const {
        return QApplication::clipboard()->setText(text);
    }

    bool chromeOSMode() const { return settings.value("chromeOSMode", false).toBool(); }
    void setChromeOSMode(bool value) { settings.setValue("chromeOSMode", value); emit settingsChanged(); }

    bool keepApks() const { return settings.value("keepApks", false).toBool(); }
    void setKeepApks(bool value) { settings.setValue("keepApks", value); emit settingsChanged(); }

    bool trialMode() const { return settings.value("trialMode", false).toBool(); }
    void setTrialMode(bool value) { settings.setValue("trialMode", value); emit settingsChanged(); }

public slots:
    void resetSettings() {
        settings.clear();
    }

signals:
    void settingsChanged();

    void clipboardChanged();

};

#endif // LAUNCHERSETTINGS_H
