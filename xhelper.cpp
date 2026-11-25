#include "xhelper.h"

#include <xloginwindow.h>
#include <QStandardPaths>
#include <QDir>
#include <QWindow>
#include <QtConcurrent>
#include "supportedandroidabis.h"
#include "launchersettings.h"
#include "encryption.h"
#include <dlfcn.h>

using namespace XSignInUiQt;

std::string XHelper::getTokenCachePath() {
    return QDir(QStandardPaths::writableLocation(QStandardPaths::CacheLocation)).filePath("playapi_token_cache.conf").toStdString();
}

LibXApi::LibXApi() {
    const char* path = std::getenv("X_API_PATH");
    if (!path) {
        handle = nullptr;
        return;
    }
    handle = dlopen(path, RTLD_LAZY);
    if (!handle) {
        return;
    }

    initialize = (decltype(initialize))dlsym(handle, "initialize");
    uninitialize = (decltype(uninitialize))dlsym(handle, "uninitialize");
    fetch_package = (decltype(fetch_package))dlsym(handle, "fetch_package");
    destroy_package = (decltype(destroy_package))dlsym(handle, "destroy_package");
    package_dump = (decltype(package_dump))dlsym(handle, "package_dump");
    user_export = (decltype(user_export))dlsym(handle, "user_export");
    user_import = (decltype(user_import))dlsym(handle, "user_import");
    user_release = (decltype(user_release))dlsym(handle, "user_release");
    device_release = (decltype(device_release))dlsym(handle, "device_release");
    user_webview_submit = (decltype(user_webview_submit))dlsym(handle, "user_webview_submit");
    user_refresh = (decltype(user_refresh))dlsym(handle, "user_refresh");
    get_device_key_chain = (decltype(get_device_key_chain))dlsym(handle, "get_device_key_chain");
    download_all = (decltype(download_all))dlsym(handle, "download_all");
    get_progress_all = (decltype(get_progress_all))dlsym(handle, "get_progress_all");
    run_game = (decltype(run_game))dlsym(handle, "run_game");
    get_game_versions = (decltype(get_game_versions))dlsym(handle, "get_game_versions");
}

LibXApi::~LibXApi() {
    if (handle != nullptr) {
        dlclose(handle);
    }
}

XUser::~XUser() noexcept {
    if (user != nullptr) 
        helper->api.user_release(user);
}

XHelper::XHelper() {
    if (!api.isValid()) {
        return;
    }
    runtime = api.initialize();
    device = api.get_device_key_chain();
    unlockkey = settings.value("key").toString();
    loadAccount();
}

XHelper::~XHelper() {
    if (window != nullptr) {
        delete window;
    }
    loginCache.clear();
    packages.clear();
    if (!api.isValid()) {
        return;
    }
    api.device_release(device);
    api.uninitialize(runtime);
}

void XHelper::loadAccount() {
    if (!api.isValid()) {
        return;
    }
    if (hasAccount) {
        return;
    }
    hasEncryptedCredentials = false;
    Encryption enc;

    int entries = settings.beginReadArray("msaccounts");
    for(int entry = 0; entry < entries; entry++) {
        settings.setArrayIndex(entry);
        auto got = settings.value("encrypted", "true").toString().toStdString();
        if(enc.Decrypt(got, unlockkey.toStdString()) == "true") {
            auto identifier = enc.Decrypt(settings.value("identifier").toString().toStdString(), unlockkey.toStdString());
            auto serialized = enc.Decrypt(settings.value("serialized").toString().toStdString(), unlockkey.toStdString());
            auto u = new XUser(this);
            u->setAccountName(QString::fromStdString(identifier));
            u->user = api.user_import(serialized.data());
            loginCache[QString::fromStdString(identifier)] = u;
            accountInfoChanged();

            struct Data {
                XHelper* helper;
                const void* user;
                QTimer *timer;
            };

            auto d = new Data{this, u->user, nullptr};
            // "1.26.3301.0.657f39f1-dcd0-491b-9bb7-c799d208f75e"
            api.get_game_versions(runtime, device, "7792d9ce-355a-493c-afbd-768f4a77c3b0", nullptr, (uint64_t)d, [](uint64_t context, const char* version){
                QJsonDocument doc = QJsonDocument::fromJson(QByteArray::fromStdString(version));
                auto ver = doc.object()["Version"].toString();
                auto cid = doc.object()["ContentId"].toString();
                qDebug() << "Success: " << cid << "/" << ver;
                auto d = (Data*)context;
                QMetaObject::invokeMethod(d->helper, [context, cid, ver]() {
                    auto d = (Data*)context;

                    auto pkg = new XPackage();
                    pkg->setVersion(ver);
                    d->helper->packages[cid] = pkg;
                    d->helper->packagesChanged();
                });
            }, [](uint64_t context, const char* version){
                qDebug() << "Failure:" << QString::fromUtf8(version);
            });
        } else {
            hasEncryptedCredentials = true;
        }
    }
    settings.endArray();

    loadDeviceState();
    updateDevice();
}

void XHelper::loadDeviceState() {
}

void XHelper::saveDeviceState() {
}

void XHelper::acquireAccount(QWindow *parent) {
    if (!api.isValid()) {
        return;
    }
    if (window)
        return;
    struct Data {
        XHelper* helper;
        QWindow* parent;
        std::string accountName;
    };
    api.user_refresh(runtime, device, nullptr, (uint64_t)(new Data{this, parent}), [](uint64_t context, const void* webview_context, const char* start_url, const char* end_url) {
        auto qapp = QCoreApplication::instance();
        QMetaObject::invokeMethod(qapp, [data = (Data*)context, webview_context, start_url, end_url]() {
            XHelper* helper = data->helper;
            QWindow* parent = data->parent;
            helper->window = new XLoginWindow();
            if(start_url) {
                helper->window->setUrl(QString::fromUtf8(start_url));
            }
            helper->window->setAttribute(Qt::WA_DeleteOnClose);
            helper->window->winId();
            helper->window->windowHandle()->setTransientParent(parent);
            helper->window->move(parent->x() + parent->width() / 2 - helper->window->width() / 2, parent->y() + parent->height() / 2 - helper->window->height() / 2);
            helper->window->show();
            connect(helper->window, &QDialog::finished, helper, [helper, data, webview_context](int code) {
                data->accountName = helper->window->accountIdentifier().toStdString();
                helper->api.user_webview_submit(webview_context, helper->window->accountServerData().toStdString().c_str());
                XHelper* helper = data->helper;
                if(helper->window) {
                    helper->window = nullptr;
                }
            });
        });
    }, [](uint64_t context, const void* user) {
        auto qapp = QCoreApplication::instance();
        QMetaObject::invokeMethod(qapp, [data = (Data*)context, user]() {
            auto u = new XUser(data->helper);
            u->setAccountName(QString::fromStdString(data->accountName));
            u->user = (void*)user;
            data->helper->loginCache[QString::fromStdString(data->accountName)] = u;
            data->helper->accountInfoChanged();
            data->helper->api.user_export(user, data, [](void* ctx, const char* serialized) {
                Data* data = (Data*)ctx;
                Encryption enc;
                if(data->helper->unlockkey.isEmpty()) {
                    data->helper->unlockkey = data->helper->settings.value("key", "").toString();
                    if(data->helper->unlockkey.isEmpty()) {
                        data->helper->unlockkey = QString::fromStdString(enc.RandomKey());
                        data->helper->settings.setValue("key", data->helper->unlockkey);
                    }
                }
                int entries = data->helper->settings.beginReadArray("msaccounts");
                data->helper->settings.endArray();
                data->helper->settings.beginWriteArray("msaccounts");
                data->helper->settings.setArrayIndex(entries);
                data->helper->settings.setValue("encrypted", QString::fromStdString(enc.Encrypt("true", data->helper->unlockkey.toStdString())));
                data->helper->settings.setValue("identifier", QString::fromStdString(enc.Encrypt(data->accountName, data->helper->unlockkey.toStdString())));
                data->helper->settings.setValue("serialized", QString::fromStdString(enc.Encrypt(serialized, data->helper->unlockkey.toStdString())));
                data->helper->settings.endArray();

                delete data;
            });
        });
    }, [](uint64_t context, const char* error) {
        Data* data = (Data*)context;
        delete data;
    });
}

void XHelper::onLoginFinished(int code) {
    if (!api.isValid()) {
        return;
    }
    accountAcquireFinished(nullptr);
    emit accountInfoChanged();
    window = nullptr;
}

void XHelper::updateDevice() {

    emit accountInfoChanged();
}

void XHelper::signOut(const QString& accountName) {
    if (!api.isValid()) {
        return;
    }
    if (loginCache.contains(accountName)) {
        loginCache.take(accountName)->deleteLater();
        settings.beginWriteArray("msaccounts", loginCache.size());
        Encryption enc;
        if(unlockkey.isEmpty()) {
            unlockkey = settings.value("key", "").toString();
        }

        for (int i = 0; i < loginCache.size(); ++i) {
            settings.setArrayIndex(i);
            settings.setValue("encrypted", QString::fromStdString(enc.Encrypt("true", unlockkey.toStdString())));
            settings.setValue("identifier", QString::fromStdString(enc.Encrypt(loginCache.values().at(i)->getAccountName().toStdString(), unlockkey.toStdString())));
            std::string serialized;
            api.user_export(loginCache.values().at(i)->user, &serialized, [](void* ctx, const char* serialized) {
                *reinterpret_cast<std::string*>(ctx) = serialized;
            });
            settings.setValue("serialized", QString::fromStdString(enc.Encrypt(serialized, unlockkey.toStdString())));
        }
        settings.endArray();
    }
    if(loginCache.empty()) {
        hasEncryptedCredentials = false;
    }
    emit accountInfoChanged();
}

XProgress *XHelper::downloadPackage(const QString &packageId, const QString &version) {
    if (!api.isValid()) {
        return nullptr;
    }
    XProgress* progress = new XProgress();
    progress->setProgress(0);
    progress->setMaximum(100);

    auto baseDir = QDir(QDir(QDir(QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation)).filePath("mcpelauncher/versions")).filePath(packageId)).filePath(version);
    QDir().mkpath(baseDir);

    if(QDir(baseDir).exists(".xodus-streaming.msixvc")) {
        QMetaObject::invokeMethod(this, [progress]() {
            progress->finished();
        }, Qt::QueuedConnection);
        return progress;
    }

    struct Data {
        XHelper* helper;
        const void* user;
        QTimer *timer;
        XProgress* progress;
        std::string url;
        std::string baseDir;
    };

    auto d = new Data{this, this->loginCache.first()->user, nullptr, progress, "", baseDir.toStdString()};

    d->helper->api.get_game_versions(runtime, d->helper->device, packageId.toStdString().c_str(), version.isEmpty() ? nullptr : version.toStdString().c_str(), (uint64_t)d, [](uint64_t context, const char* version){
        std::string sver = version;
        auto d = (Data*)context;
        QMetaObject::invokeMethod(d->helper, [context, sver]() {
            auto d = (Data*)context;
            QJsonDocument doc = QJsonDocument::fromJson(QByteArray::fromStdString(sver));
            auto packageFiles = doc.object().value("PackageFiles").toArray();
            for (const auto& file : packageFiles) {
                if (file.toObject().value("FileName").toString().endsWith(".msixvc")) {
                    QString cdnroot = file.toObject().value("CdnRootPaths").toArray().first().toString();
                    QString relativeUrl = file.toObject().value("RelativeUrl").toString();
                    qDebug() << "Fetching package from URL:" << (cdnroot + relativeUrl);

                    d->url = (cdnroot + relativeUrl).toStdString();

                    d->helper->api.fetch_package(d->helper->runtime, d->url.c_str(), d, [](void *user, const void* pkg){
                        auto data = (Data*)user;
                        qDebug() << "fetch success for handle:" << pkg;
                        data->helper->api.package_dump(pkg);
                        auto qapp = QCoreApplication::instance();
                        QMetaObject::invokeMethod(qapp, [data, pkg]() {
                            data->timer = new QTimer(data->helper);

                            QObject::connect(data->timer, &QTimer::timeout, data->helper, [pkg, data]() {
                                auto progress = data->helper->api.get_progress_all(pkg);
                                data->progress->setProgress(progress.cur);
                                data->progress->setMaximum(progress.total);
                            });

                            data->timer->start(100);

                            data->helper->api.download_all(data->helper->runtime, pkg, data->helper->device, data->user, data->url.c_str(), data->baseDir.c_str(), reinterpret_cast<uint64_t>(data),
                                [](uint64_t ucontext){
                                    auto data = (Data*)ucontext;
                                    data->progress->finished();
                                    qDebug() << "Download success for context:" << ucontext << "user:" << data->user;
                                    QMetaObject::invokeMethod(data->timer, [data]() {
                                        data->timer->stop();
                                        delete data->timer;
                                        delete data;
                                    });
                                },
                                [](uint64_t ucontext, const char* error){
                                    auto data = (Data*)ucontext;
                                    qDebug() << "Download failed for context:" << ucontext << "error:" << error << "user:" << data->user;
                                    QMetaObject::invokeMethod(data->timer, [data]() {
                                        data->timer->stop();
                                        delete data->timer;
                                        delete data;
                                    });
                                }
                            );
                        });
                    }, [](void *user, const char* error){
                        qDebug() << "Failed to fetch package:" << error;
                    });

                }
            }

        });
    }, [](uint64_t context, const char* version){
        qDebug() << "Failure:" << QString::fromUtf8(version);
        auto d = (Data*)context;
        delete d;
    });

    return progress;
}

void XHelper::runPackage(const QString &packageId, const QString &version, const QString& user) {
    if (!api.isValid()) {
        return;
    }
    auto baseDir = QDir(QDir(QDir(QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation)).filePath("mcpelauncher/versions")).filePath(packageId)).filePath(version);

    auto suser = this->loginCache.first();
    auto xuser = this->loginCache.value(user, suser);

    std::thread([runtime = runtime, device = device, user = suser->user, xuser = xuser->user, baseDir, d = this](){
        const char* wine = std::getenv("X_API_WINE");
        if (!wine) {
            wine = "wine";
        }

        d->api.run_game(runtime, device, user, xuser, baseDir.toStdString().c_str(), wine);
    }).detach();
}

XAsyncVariant* XHelper::resolvePackage(const QString &packageId, const QString &version) {
    if (!api.isValid()) {
        return nullptr;
    }
    XAsyncVariant* progress = new XAsyncVariant();
    auto user = this->loginCache.first()->user;
    auto device = this->device;
    struct Data {
        XHelper* helper;
        void* user;
        XAsyncVariant* progress; 
        const void* device;
    } *d = new Data{this, user, progress, device};
    d->helper->api.get_game_versions(runtime, d->helper->device, packageId.toStdString().c_str(), version.isEmpty() ? nullptr : version.toStdString().c_str(), (uint64_t)d, [](uint64_t context, const char* version){
        std::string sver = version;
        auto d = (Data*)context;
        QMetaObject::invokeMethod(d->helper, [context, sver]() {
            auto d = (Data*)context;
            QJsonDocument doc = QJsonDocument::fromJson(QByteArray::fromStdString(sver));
            d->progress->setVariant(QVariant::fromValue(doc.object()));
            delete d;
        });
    }, [](uint64_t context, const char* version){
        qDebug() << "Failure:" << QString::fromUtf8(version);
        auto d = (Data*)context;
        delete d;
    });
    return progress;
}
