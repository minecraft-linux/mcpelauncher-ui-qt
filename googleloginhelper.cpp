#include "googleloginhelper.h"

#include <googleloginwindow.h>
#include <QWindow>

GoogleLoginHelper::~GoogleLoginHelper() {
    delete window;
}

void GoogleLoginHelper::acquireAccount(QWindow *parent) {
    if (window)
        return;
    window = new GoogleLoginWindow();
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
        accountAcquireFinished(&currentAccount);
    } else {
        accountAcquireFinished(nullptr);
    }

    delete window;
    window = nullptr;
}
