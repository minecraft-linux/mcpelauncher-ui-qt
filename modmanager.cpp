// modmanager.cpp

#include "modmanager.h"
#include <QCoreApplication>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QStandardPaths>

ModManager::ModManager(QObject* parent)
    : QObject(parent)
{
    // // Define root folder: <appdir>/mcpelauncher/mods
    // QString base = QCoreApplication::applicationDirPath()
    //              + QDir::separator()
    //              + "mcpelauncher"
    //              + QDir::separator()
    //              + "mods";
    QString base = QDir(QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation)).filePath("mcpelauncher/mods");
    m_root = QDir(base);
    if (!m_root.exists())
        m_root.mkpath(".");
}

QString ModManager::modFolderPath(const QString& name,
                                  const QString& version,
                                  const QString& arch) const
{
    return m_root.filePath(name + "/" + version + "/" + arch);
}

QString ModManager::modJsonPath(const QString& name,
                                const QString& version,
                                const QString& arch) const
{
    return modFolderPath(name, version, arch) + "/mod.json";
}

QVector<ModInfo> ModManager::listMods() const
{
    QVector<ModInfo> out;
    const auto names = m_root.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
    for (const QString& name : names) {
        QDir d1(m_root.filePath(name));
        for (const QString& ver : d1.entryList(QDir::Dirs | QDir::NoDotAndDotDot)) {
            QDir d2(d1.filePath(ver));
            for (const QString& arch : d2.entryList(QDir::Dirs | QDir::NoDotAndDotDot)) {
                QString jsonFile = modJsonPath(name, ver, arch);
                QFile f(jsonFile);
                QVariantMap meta;
                if (f.open(QIODevice::ReadOnly)) {
                    auto doc = QJsonDocument::fromJson(f.readAll());
                    meta = doc.object().toVariantMap();
                }
                ModInfo info;
                info.name     = name;
                info.version  = ver;
                info.arch     = arch;
                info.metadata = meta;
                out.append(info);
            }
        }
    }
    return out;
}

QVariantMap ModManager::loadMod(const QString& name,
                                const QString& version,
                                const QString& arch) const
{
    QString path = modJsonPath(name, version, arch);
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly))
        return {};
    auto doc = QJsonDocument::fromJson(f.readAll());
    return doc.object().toVariantMap();
}

bool ModManager::saveMod(const QString& name,
                         const QString& version,
                         const QString& arch,
                         const QVariantMap& metadata)
{
    QString folder = modFolderPath(name, version, arch);
    if (!QDir().mkpath(folder))
        return false;

    QJsonObject obj = QJsonObject::fromVariantMap(metadata);
    QJsonDocument doc(obj);

    QString filePath = modJsonPath(name, version, arch);
    QFile f(filePath);
    if (!f.open(QIODevice::WriteOnly))
        return false;
    f.write(doc.toJson(QJsonDocument::Indented));
    return true;
}

bool ModManager::removeMod(const QString& name,
                           const QString& version,
                           const QString& arch)
{
    QString folder = modFolderPath(name, version, arch);
    return QDir(folder).removeRecursively();
}

bool ModManager::modExists(const QString& name,
                           const QString& version,
                           const QString& arch) const
{
    return QDir(modFolderPath(name, version, arch)).exists();
}

QString ModManager::getFolderPathForMod(const ModInfo& info) const
{
    return modFolderPath(info.name, info.version, info.arch);
}

QString ModManager::getRoot() const
{
    return m_root.absolutePath();
}
