#include "updatechecker.h"

#include <QNetworkReply>

UpdateChecker::UpdateChecker(QObject* parent) : QObject(parent) {
    connect(&netAccessManager, &QNetworkAccessManager::finished, this, &UpdateChecker::onRequestFinished);
    m_active = false;
}

#ifndef SPARKLE_UPDATE_CHECK
void UpdateChecker::sendRequest() {
#ifdef APPIMAGE_UPDATE_CHECK
    auto updater = this->updater;
    auto oldthread = std::make_shared<std::thread>();
    std::swap(*oldthread, updatethread);
    updatethread = std::thread([this, updater, oldthread]() mutable  {
        try {
            if (oldthread->joinable()) {
                oldthread->join();
            }
            if (!updater) {
                char * appimage = getenv("APPIMAGE");
                if (appimage) {
                    printf("Appimage create updater\n");
                    this->updater = updater = std::make_shared<appimage::update::Updater>(appimage, true);
                } else {
                    printf("Appimage cannot be updated\n");
                    return;
                }
            }
            bool _updateAvailable = false;
            printf("Appimage check for changes\n");
            /*
            if (!updater->checkForChanges(_updateAvailable)) {
                std::string nextMessage;
                while (updater->nextStatusMessage(nextMessage)) {
                    printf("appimage update error %s\n", nextMessage.data());
                }
                return;
            }*/
            printf("Appimage Found Update? %d\n", (int)_updateAvailable);

            if (_updateAvailable) {
                emit updateAvailable("");
            }
        }
    });
#elif defined(UPDATE_CHECK)
    QNetworkRequest request(QStringLiteral(UPDATE_CHECK_URL));
    netAccessManager.get(request);
#endif
}

void UpdateChecker::checkForUpdates() {
    sendRequest();
}
#endif

void UpdateChecker::onRequestFinished(QNetworkReply* reply) {
#ifdef UPDATE_CHECK
    if (reply->error() != QNetworkReply::NoError)
        return;
    auto redirect = reply->attribute(QNetworkRequest::RedirectionTargetAttribute).toUrl();
    if (redirect.isValid()) {
        QNetworkRequest request(redirect);
        netAccessManager.get(request);
        return;
    }
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

void UpdateChecker::startUpdate() {
#ifdef APPIMAGE_UPDATE_CHECK
    if (updater) {
        auto oldthread = std::make_shared<std::thread>();
        std::swap(*oldthread, updatethread);
        updatethread = std::thread([this, oldthread] {
            if (oldthread->joinable()) {
                oldthread->join();
            }
            m_active = true;
            emit activeChanged();
            updater->start();

            while (!updater->isDone()) {
                std::this_thread::sleep_for(std::chrono::milliseconds(100));

                double _progress;
                if (!updater->progress(_progress)) {
                    printf("appimage startUpdate Call to progress() failed\n");
                    m_active = false;
                    emit activeChanged();
                    return;
                }

                emit progress(_progress);

                // fetch all status messages
                // this is basically the same as before
                std::string nextMessage;
                while (updater->nextStatusMessage(nextMessage)) {
                    printf("appimage startUpdate %s\n", nextMessage.data());
                }
            }

            if (updater->hasError()) {
                printf("Error occurred. See previous messages for details.\n");
            } else {
                updater->copyPermissionsToNewFile();
            }

            m_active = false;
            emit activeChanged();
            emit requestRestart();
        });
    }
    #endif
}

#ifdef APPIMAGE_UPDATE_CHECK
UpdateChecker::~UpdateChecker() {
    if (updatethread.joinable()) {
        updatethread.join();
    }
}
#endif