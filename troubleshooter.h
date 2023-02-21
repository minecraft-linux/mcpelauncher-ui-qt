#ifndef TROUBLESHOOTER_H
#define TROUBLESHOOTER_H

#include <QObject>

class TroubleshooterIssue : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString shortDesc MEMBER shortDesc CONSTANT)
    Q_PROPERTY(QString longDesc MEMBER longDesc CONSTANT)
    Q_PROPERTY(QString wikiUrl MEMBER wikiUrl CONSTANT)

public:
    enum Type {
        TYPE_LAUNCHER_NOT_FOUND,
        TYPE_LAUNCHER_VERSION_QUERY_FAILED,
        TYPE_LAUNCHER_SOFTWARE_RENDERER,
        TYPE_LAUNCHER_MSA_NOT_FOUND,

        TYPE_LAUNCHER_ZENITY_NOT_FOUND
    };
    Q_ENUM(Type)

private:
    Type type;
    QString shortDesc;
    QString longDesc;
    QString wikiUrl;

public:
    explicit TroubleshooterIssue(Type type, QString shortDesc, QString longDesc, QObject *parent = nullptr) :
        QObject(parent), type(type), shortDesc(shortDesc), longDesc(longDesc) {}

    TroubleshooterIssue* addWikiUrl(QString wikiUrl) {
        this->wikiUrl = std::move(wikiUrl);
        return this;
    }

};

class Troubleshooter : public QObject {
    Q_OBJECT
public:
    explicit Troubleshooter(QObject *parent = nullptr);

public slots:
    QList<QObject*> findIssues();

private:
    void findLauncherIssues(QList<QObject*>& ret);
};

#endif // TROUBLESHOOTER_H
