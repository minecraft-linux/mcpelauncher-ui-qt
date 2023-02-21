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
        ret.append((new TroubleshooterIssue(TroubleshooterIssue::TYPE_LAUNCHER_ZENITY_NOT_FOUND, tr("Zenity utility not found"), tr("You may be unable to pick files in the launcher.")))
                           ->addWikiUrl("https://mcpelauncher.readthedocs.io/en/latest/troubleshooting.html#file-picking-doesn-t-work-or-crashes"));
    }
#endif
    return ret;
}

void Troubleshooter::findLauncherIssues(QList<QObject *> &ret) {
    auto path = GameLauncher::findLauncher("mcpelauncher-client");
    if (path.empty()) {
        ret.append((new TroubleshooterIssue(TroubleshooterIssue::TYPE_LAUNCHER_NOT_FOUND, tr("Game launcher not found"), tr("Could not find the game launcher. Please make sure it's properly installed (it must exist in the PATH variable used when starting this program).")))
                           ->addWikiUrl("https://mcpelauncher.readthedocs.io/en/latest/troubleshooting.html#could-not-find-the-game-launcher"));
        return;
    }
    QProcess process;
    process.start(path.c_str(), {"-v"});
    if (!process.waitForFinished()) {
        ret.append(new TroubleshooterIssue(TroubleshooterIssue::TYPE_LAUNCHER_VERSION_QUERY_FAILED, tr("Failed to query game launcher version information"), tr("An error occurred while trying to run `mcpelauncher-client -v`: %1").arg(process.errorString())));
        return;
    }
    QString output = QString::fromUtf8(process.readAll());
    int exitCode = process.exitCode();
    if(exitCode != 0) {
        ret.append(new TroubleshooterIssue(TroubleshooterIssue::TYPE_LAUNCHER_VERSION_QUERY_FAILED, tr("Failed to query game launcher version information"), tr("An error occurred while trying to run `mcpelauncher-client -v` exit code: %1, log:\n%2").arg(exitCode).arg(output)));
        return;
    }
    QStringList lines = output.split("\n");
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
    if (versionInfo["GL Renderer"].count("llvmpipe") > 0)
        ret.append((new TroubleshooterIssue(TroubleshooterIssue::TYPE_LAUNCHER_SOFTWARE_RENDERER, tr("Software rendering"), ("The game is using the software (CPU) rendering. This will negatively impact performance.")))
                           ->addWikiUrl("https://mcpelauncher.readthedocs.io/en/latest/troubleshooting.html#graphics-performance-issues-software-rendering"));
    if (versionInfo["MSA daemon path"].isEmpty())
        ret.append((new TroubleshooterIssue(TroubleshooterIssue::TYPE_LAUNCHER_MSA_NOT_FOUND, tr("MSA daemon could not be found"), tr("The MSA component has not been installed properly. Xbox Live login may not work.")))
                           ->addWikiUrl("https://mcpelauncher.readthedocs.io/en/latest/troubleshooting.html#msa-daemon-could-not-be-found"));
}