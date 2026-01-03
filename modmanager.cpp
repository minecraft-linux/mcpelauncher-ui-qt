// modmanager.cpp

#include "modmanager.h"
#include <QCoreApplication>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QStandardPaths>
#include <qnetworkaccessmanager.h>
#include <qnetworkreply.h>
#include <qjsonarray.h>

ModManager::ModManager(QObject* parent)
    : QObject(parent)
{
    QString base = QDir(QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation)).filePath("mcpelauncher/mods/");
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

ModInfo ModManager::loadModInfoByPath(const QString &path) const
{
    // TODO try to extract the mod info from the folder structure if mod.json is missing
    QFile f(QDir(getRoot()).absoluteFilePath(path + "/mod.json"));
    ModInfo info;
    if (!f.open(QIODevice::ReadOnly))
        return info;
    auto doc = QJsonDocument::fromJson(f.readAll());
    QVariantMap meta = doc.object().toVariantMap();
    info.name     = meta.value("name").toString();
    info.version  = meta.value("version").toString();
    info.arch     = meta.value("arch").toString();
    info.metadata = meta;
    return info;
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

QString ModManager::getFolderPathForMod(const QString& name,
                                        const QString& version,
                                        const QString& arch) const
{
    return modFolderPath(name, version, arch);
}

QString ModManager::getRoot() const
{
    return m_root.absolutePath();
}

void ModManager::downloadModList() {
    // Download mod list from remote server and save to mods directory
    // https://github.com/minecraft-linux/mcpelauncher-moddb/raw/main/moddb.json
    QString url = "https://github.com/minecraft-linux/mcpelauncher-moddb/raw/main/moddb.json";
    QNetworkAccessManager* manager = new QNetworkAccessManager(this);
    QNetworkRequest request({QUrl(url)});
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);
    QNetworkReply* reply = manager->get(request);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        if (reply->error() == QNetworkReply::NoError) {
            auto data = reply->readAll();
            QJsonDocument doc = QJsonDocument::fromJson(data);
            m_remoteMods.clear();
            for(auto&& entry : doc.array()) {
                QVariantMap modMap = entry.toObject().toVariantMap();
                ModInfo info;
                info.name = modMap.value("name").toString();
                info.metadata = modMap;
                m_remoteMods.append(info);
            }
            reply->deleteLater();
        }
        modListUpdated();
    });
}

QVector<ModInfo> ModManager::remoteMods() {
    return m_remoteMods;
}
