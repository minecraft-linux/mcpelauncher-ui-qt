// modmanager.h

#pragma once

#include <QObject>
#include <QVariantMap>
#include <QVector>
#include <QDir>

struct ModInfo {
    Q_GADGET
    Q_PROPERTY(QString name MEMBER name)
    Q_PROPERTY(QString version MEMBER version)
    Q_PROPERTY(QString arch MEMBER arch)
    Q_PROPERTY(QVariantMap metadata MEMBER metadata)

public:
    QString      name;
    QString      version;
    QString      arch;
    QVariantMap  metadata;
};

Q_DECLARE_METATYPE(ModInfo)

class ModManager : public QObject
{
    Q_OBJECT
public:
    explicit ModManager(QObject* parent = nullptr);

    // Scan the mods directory and return a list of all found mods.
    Q_INVOKABLE QVector<ModInfo> listMods() const;

    // Load metadata for one mod.
    Q_INVOKABLE QVariantMap loadMod(const QString& name,
                                    const QString& version,
                                    const QString& arch) const;

    // Save or overwrite metadata for one mod.
    Q_INVOKABLE bool saveMod(const QString& name,
                             const QString& version,
                             const QString& arch,
                             const QVariantMap& metadata);

    // Remove one mod completely (folder + metadata).
    Q_INVOKABLE bool removeMod(const QString& name,
                               const QString& version,
                               const QString& arch);

    // Check if a mod folder exists.
    Q_INVOKABLE bool modExists(const QString& name,
                               const QString& version,
                               const QString& arch) const;
    
    Q_INVOKABLE QString         getFolderPathForMod(const QString& name,
                                                    const QString& version,
                                                    const QString& arch) const;

    Q_INVOKABLE QString         getRoot() const;

private:
    QDir    m_root;            // points to .../mcpelauncher/mods
    QString modFolderPath(const QString& name,
                          const QString& version,
                          const QString& arch) const;
    QString modJsonPath(const QString& name,
                        const QString& version,
                        const QString& arch) const;
};
