#include "updatechecker.h"

#include <QNetworkReply>

UpdateChecker::UpdateChecker(QObject* parent) : QObject(parent) {
    connect(&netAccessManager, &QNetworkAccessManager::finished, this, &UpdateChecker::onRequestFinished);
}

void UpdateChecker::sendRequest() {
#ifdef UPDATE_CHECK
    QNetworkRequest request(QStringLiteral(UPDATE_CHECK_URL));
    netAccessManager.get(request);
#endif
}

void UpdateChecker::onRequestFinished(QNetworkReply* reply) {
#ifdef UPDATE_CHECK
    if (reply->error() != QNetworkReply::NoError)
        return;
    QMap<QString, QString> props;
    QString replyText = QString::fromUtf8(reply->readAll());
    for (QStringRef const& line : replyText.splitRef('\n')) {
        auto iof = line.indexOf('=');
        if (iof == -1)
            continue;
        props[line.left(iof).toString()] = line.mid(iof + 1).trimmed().toString();
    }
    printf("server build id: %i\n", props["build_id"].toInt());
    if (props["build_id"].toInt() > UPDATE_CHECK_BUILD_ID)
        emit updateAvailable(props["download_url"]);
#endif
}
