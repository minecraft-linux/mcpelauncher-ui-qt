#ifndef GOOGLELOGINHELPER_H
#define GOOGLELOGINHELPER_H

#include <QObject>
#include "googleaccount.h"

class QWindow;
class GoogleLoginWindow;

class GoogleLoginHelper : public QObject {
    Q_OBJECT
    Q_PROPERTY(GoogleAccount* account READ account)

private:
    GoogleLoginWindow* window = nullptr;
    GoogleAccount currentAccount;
    bool hasAccount = false;

    void onLoginFinished(int code);

public:
    ~GoogleLoginHelper();

    GoogleAccount* account() {
        return hasAccount ? &currentAccount : nullptr;
    }

public slots:
    void acquireAccount(QWindow *parent);

signals:
    void accountAcquireFinished(GoogleAccount* account);

};

#endif // GOOGLELOGINHELPER_H
