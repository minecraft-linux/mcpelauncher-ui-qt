#include "updatechecker.h"

#include <QNetworkReply>
#include <sstream>
#include <QObject>

UpdateChecker::UpdateChecker(QObject* parent) : QObject(parent) {
    connect(&netAccessManager, &QNetworkAccessManager::finished, this, &UpdateChecker::onRequestFinished);
    m_active = false;
}

#ifndef SPARKLE_UPDATE_CHECK
void UpdateChecker::checkForUpdates() {
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
#ifndef NDEBUG
                    printf("Appimage create updater\n");
#endif
                    this->updater = updater = std::make_shared<appimage::update::Updater>(appimage, true);
                } else {
#ifndef NDEBUG
                    printf("Appimage cannot be updated\n");
#endif
                    emit updateError(QObject::tr("Appimage cannot be updated<br/>Expected Environmentvariable 'APPIMAGE' to be set to the path of the AppImage"));
                    return;
                }
            }
            bool _updateAvailable = false;
#ifndef NDEBUG
            printf("Appimage check for changes\n");
#endif
            if (!updater->checkForChanges(_updateAvailable)) {
#ifndef NDEBUG
                printf("Appimage Error\n");
#endif
                std::stringstream errorstream;
                std::string nextMessage;
                while (updater->nextStatusMessage(nextMessage)) {
#ifndef NDEBUG
                    printf("appimage update error %s\n", nextMessage.data());
#endif
                    errorstream << nextMessage << "<br/>";
                }
                emit updateError(QObject::tr("Appimage cannot be updated") + "<br/>" + QString::fromStdString(errorstream.str()));
                return;
            }
#ifndef NDEBUG
            printf("Appimage Found Update? %d\n", (int)_updateAvailable);
#endif

            if (_updateAvailable) {
                emit updateAvailable("");
            }
            emit updateCheck(_updateAvailable);
        } catch (...) {
            emit updateError(QObject::tr("Appimage cannot be updated<br/>Unknown Error"));
        }
    });
#elif defined(UPDATE_CHECK)
    QNetworkRequest request(QStringLiteral(UPDATE_CHECK_URL));
    netAccessManager.get(request);
#else
        emit updateError(QObject::tr("Launcher cannot be updated<br/>You have to check your packagemanager for updates or recompile your Open Source build with newer sources"));
#endif
}

#endif

void UpdateChecker::onRequestFinished(QNetworkReply* reply) {
#ifdef UPDATE_CHECK
    if (reply->error() != QNetworkReply::NoError) {
        emit updateError(QObject::tr("Failed to check for update<br/>Failed to connect to update server"));
        return;
    }
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
#ifndef NDEBUG
    printf("server build id: %i\n", props["build_id"].toInt());
#endif
    bool updateavailable = props["build_id"].toInt() > UPDATE_CHECK_BUILD_ID;
    if (updateavailable)
        emit updateAvailable(props["download_url"]);
    emit updateCheck(updateavailable);
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
            std::stringstream errorstream;

            while (!updater->isDone()) {
                std::this_thread::sleep_for(std::chrono::milliseconds(100));

                double _progress;
                if (!updater->progress(_progress)) {
#ifndef NDEBUG
                    printf("appimage startUpdate Call to progress() failed\n");
#endif
                    m_active = false;
                    emit activeChanged();
                    return;
                }

                emit progress(_progress);

                // fetch all status messages
                // this is basically the same as before
                std::string nextMessage;
                while (updater->nextStatusMessage(nextMessage)) {
#ifndef NDEBUG
                    printf("appimage startUpdate %s\n", nextMessage.data());
#endif
                    errorstream << nextMessage << "<br/>";
                }
            }

            m_active = false;
            emit activeChanged();
            if (updater->hasError()) {
#ifndef NDEBUG
                printf("Error occurred. See previous messages for details.\n");
#endif
                emit updateError(QObject::tr("Appimage cannot be updated") + "<br/>" + QString::fromStdString(errorstream.str()));
            } else {
                updater->copyPermissionsToNewFile();
                emit requestRestart();
            }
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