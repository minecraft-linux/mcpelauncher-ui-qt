#ifndef GOOGLELOGINHELPER_H
#define GOOGLELOGINHELPER_H

#include <QObject>

class QWindow;
class GoogleLoginWindow;

class GoogleLoginHelper : public QObject {
    Q_OBJECT

private:
    GoogleLoginWindow* window = nullptr;

    void onLoginFinished(int code);

public:
    ~GoogleLoginHelper();

public slots:
    void acquireAccount(QWindow *parent);

};

#endif // GOOGLELOGINHELPER_H
