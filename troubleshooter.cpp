#include "troubleshooter.h"

#include <QMap>
#include <QFileInfo>
#include "gamelauncher.h"

Troubleshooter::Troubleshooter(QObject *parent) : QObject(parent) {
}

QList<QObject*> Troubleshooter::findIssues() {
    QList<QObject*> ret;
    findLauncherIssues(ret);
#ifndef __APPLE__
    if (!QFileInfo("/usr/bin/zenity").exists()) {
        ret.append((new TroubleshooterIssue(TroubleshooterIssue::TYPE_LAUNCHER_ZENITY_NOT_FOUND, "Zenity utility not found", "You may be unable to pick files in the launcher."))
                           ->addWikiUrl("https://github.com/minecraft-linux/mcpelauncher-manifest/wiki/Troubleshooting#file-picking-doesnt-work-or-crashes"));
    }
#endif
    return ret;
}

void Troubleshooter::findLauncherIssues(QList<QObject *> &ret) {
    auto path = GameLauncher::findLauncher();
    if (path.empty()) {
        ret.append((new TroubleshooterIssue(TroubleshooterIssue::TYPE_LAUNCHER_NOT_FOUND, "Game launcher not found", "Could not find the game launcher. Please make sure it's properly installed (it must exist in the PATH variable used when starting this program)."))
                           ->addWikiUrl("https://github.com/minecraft-linux/mcpelauncher-ui-manifest/wiki/Troubleshooting#could-not-find-the-game-launcher"));
        return;
    }
    QProcess process;
    process.start(path.c_str(), {"-v"});
    if (!process.waitForFinished()) {
        ret.append(new TroubleshooterIssue(TroubleshooterIssue::TYPE_LAUNCHER_VERSION_QUERY_FAILED, "Failed to query game launcher version information", "An error occurred while trying to run `mcpelauncher-client -v`: " + process.errorString()));
        return;
    }
    QStringList lines = QString::fromUtf8(process.readAll()).split("\n");
    QMap<QString, QString> versionInfo;
    bool skipFirst = true;
    for (QString const& line : lines) {
        if (skipFirst) {
            skipFirst = false;
            continue;
        }
        auto iof = line.indexOf(": ");
        if (iof == -1)
            break;
        versionInfo[line.left(iof)] = line.mid(iof + 2).trimmed();
    }
    if (versionInfo["SSSE3 support"] != "YES")
        ret.append((new TroubleshooterIssue(TroubleshooterIssue::TYPE_LAUNCHER_NO_SSSE3_SUPPORT, "No CPU SSSE3 support", "Your CPU may be unsupported and the game may crash on startup."))
                           ->addWikiUrl("https://github.com/minecraft-linux/mcpelauncher-manifest/wiki/Troubleshooting#graphics-performance-issues-software-rendering"));
    if (versionInfo["GL Renderer"].count("llvmpipe") > 0)
        ret.append((new TroubleshooterIssue(TroubleshooterIssue::TYPE_LAUNCHER_SOFTWARE_RENDERER, "Software rendering", "The game is using the software (CPU) rendering. This will negatively impact performance."))
                           ->addWikiUrl("https://github.com/minecraft-linux/mcpelauncher-manifest/wiki/Troubleshooting#graphics-performance-issues-software-rendering"));
    if (versionInfo["MSA daemon path"].isEmpty())
        ret.append((new TroubleshooterIssue(TroubleshooterIssue::TYPE_LAUNCHER_MSA_NOT_FOUND, "MSA daemon could not be found", "The MSA component has not been installed properly. Xbox Live login may not work."))
                           ->addWikiUrl("https://github.com/minecraft-linux/mcpelauncher-manifest/wiki/Troubleshooting#msa-daemon-could-not-be-found"));
}