#ifndef GOOGLEACCOUNT_H
#define GOOGLEACCOUNT_H

#include <QObject>

class GoogleAccount : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString accountIdentifier READ accountIdentifier WRITE setAccountIdentifier)
    Q_PROPERTY(QString accountUserId READ accountUserId WRITE setAccountUserId)
    Q_PROPERTY(QString accountToken READ accountToken WRITE setAccountToken)

private:
    QString m_accountIdentifier;
    QString m_accountUserId;
    QString m_accountToken;

public:
    QString const& accountIdentifier() const { return m_accountIdentifier; }
    QString const& accountUserId() const { return m_accountUserId; }
    QString const& accountToken() const { return m_accountToken; }

    void setAccountIdentifier(QString const& value) { m_accountIdentifier = value; }
    void setAccountUserId(QString const& value) { m_accountUserId = value; }
    void setAccountToken(QString const& value) { m_accountToken = value; }

    bool isValid() {
        return m_accountIdentifier.size() > 0 && m_accountUserId.size()> 0 && m_accountToken.size() > 0;
    }
};

#endif // GOOGLEACCOUNT_H
