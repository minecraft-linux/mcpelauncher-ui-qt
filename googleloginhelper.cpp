#include "googleloginhelper.h"

#include <googleloginwindow.h>
#include <QWindow>

GoogleLoginHelper::GoogleLoginHelper() {
    settings.beginGroup("googlelogin");

    if (settings.contains("identifier")) {
        currentAccount.setAccountIdentifier(settings.value("identifier").toString());
        currentAccount.setAccountUserId(settings.value("userId").toString());
        currentAccount.setAccountToken(settings.value("token").toString());
        hasAccount = true;
    }
}

GoogleLoginHelper::~GoogleLoginHelper() {
    delete window;
}

void GoogleLoginHelper::acquireAccount(QWindow *parent) {
    if (window)
        return;
    window = new GoogleLoginWindow();
    window->setAttribute(Qt::WA_DeleteOnClose);
    window->winId();
    window->windowHandle()->setTransientParent(parent);
    window->move(parent->x() + parent->width() / 2 - window->width() / 2, parent->y() + parent->height() / 2 - window->height() / 2);
    window->show();
    connect(window, &QDialog::finished, this, &GoogleLoginHelper::onLoginFinished);
}

void GoogleLoginHelper::onLoginFinished(int code) {
    if (code == QDialog::Accepted) {
        currentAccount.setAccountIdentifier(window->accountIdentifier());
        currentAccount.setAccountUserId(window->accountUserId());
        currentAccount.setAccountToken(window->accountToken());
        settings.setValue("identifier", currentAccount.accountIdentifier());
        settings.setValue("userId", currentAccount.accountUserId());
        settings.setValue("token", currentAccount.accountToken());
        hasAccount = true;
        accountAcquireFinished(&currentAccount);
    } else {
        accountAcquireFinished(nullptr);
    }
    window = nullptr;
}
