#include "xhelper.h"

#include <xloginwindow.h>
#include <QStandardPaths>
#include <QDir>
#include <QWindow>
#include <QtConcurrent>
#include "supportedandroidabis.h"
#include "launchersettings.h"
#include "encryption.h"

using namespace XSignInUiQt;

std::string XHelper::getTokenCachePath() {
    return QDir(QStandardPaths::writableLocation(QStandardPaths::CacheLocation)).filePath("playapi_token_cache.conf").toStdString();
}

extern "C" void* initialize();
extern "C" void uninitialize(void*);
extern "C" void fetch_package(void* runtime, const char* url, void *user,
    void (*success)(void *user, const void*pkg),
    void (*failure)(void *user, const char*s)
);
extern "C" void destroy_package(const void* pkg);
extern "C" void demo();
extern "C" void package_dump(const void* pkg);


//pub extern "system" fn user_export(user: *const User, callback: unsafe extern "system" fn(serialized: *const c_char))
extern "C" void user_export(const void* user, void*ctx, void (*callback)(void*ctx, const char* serialized));
extern "C" void* user_import(const char* serialized);

// pub extern "system" fn user_webview_submit(context: *const UserWebviewContext, payload: *const c_char);
// pub extern "system" fn user_refresh(runtime: *const Runtime, device: *const Device, user: *const User, ucontext: u64, webview: unsafe extern "system" fn(u64, context: *const UserWebviewContext, start_url: *const c_char, end_url: *const c_char), success: unsafe extern "system" fn(u64, *const User),

extern "C" void user_webview_submit(const void* context, const char* payload);
extern "C" void user_refresh(const void* runtime, const void* device, const void* user, uint64_t ucontext,
    void (*webview)(uint64_t, const void* context, const char* start_url, const char* end_url),
    void (*success)(uint64_t, const void*),
    void (*failure)(uint64_t, const char*)
);

extern "C" const void* get_device_key_chain();

// pub extern "system" fn download_all(
//     runtime: *const Runtime,
//     package: *const Package,
//     device: *const Device,
//     user: *const User,
//     url: *const c_char,
//     destination: *const c_char,
//     ucontext: u64,
//     success: unsafe extern "system" fn(c: u64),
//     failure: unsafe extern "system" fn(c: u64, error: *const c_char),
// ) {

extern "C" void download_all(const void* runtime, const void* package, const void* device, const void* user,
    const char* url, const char* destination, uint64_t ucontext,
    void (*success)(uint64_t),
    void (*failure)(uint64_t, const char*)
);

// #[repr(C)]
// pub struct CProgress {
//     cur: usize,
//     total: usize,
// }

// #[unsafe(no_mangle)]
// pub extern "system" fn get_progress_all(package: *const Package) -> CProgress {
//     let package = unsafe { &*package };
//     let Ok((c, t)) = package.get_progress(vec![]) else {
//         return CProgress { cur: 0, total: 0 };
//     };
//     CProgress { cur: c, total: t }
// }

struct CProgress {
    size_t cur;
    size_t total;
};

extern "C" CProgress get_progress_all(const void* package);

// pub extern "system" fn run_game(runtime: *const Runtime, device: *const Device, user: *const User, source: *const c_char, wine: *const c_char) -> i32 {

extern "C" int run_game(const void* runtime, const void* device, const void* user, const char* source, const char* wine);

// pub extern "system" fn get_game_versions(runtime: *const Runtime, device: *const Device, content_id: *const c_char, version: *const c_char, context: u64, success: unsafe extern "system" fn(context: u64, version: *const c_char), failure: unsafe extern "system" fn(context: u64, version: *const c_char) ) {

extern "C" void get_game_versions(const void* runtime, const void* device, const char* content_id, const char* version, uint64_t context,
    void (*success)(uint64_t, const char*),
    void (*failure)(uint64_t, const char*)
);

XHelper::XHelper() {
    runtime = initialize();
    unlockkey = settings.value("key").toString();
    loadAccount();
}

XHelper::~XHelper() {
    delete window;
    uninitialize(runtime);
}

void XHelper::loadAccount() {
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
            auto u = new XUser();
            u->setAccountName(QString::fromStdString(identifier));
            u->user = user_import(serialized.data());
            loginCache[QString::fromStdString(identifier)] = u;
            accountInfoChanged();

            struct Data {
                XHelper* helper;
                const void* user;
                QTimer *timer;
            };

            auto d = new Data{this, u->user, nullptr};
            // "1.26.3301.0.657f39f1-dcd0-491b-9bb7-c799d208f75e"
            get_game_versions(runtime, get_device_key_chain(), "7792d9ce-355a-493c-afbd-768f4a77c3b0", nullptr, (uint64_t)d, [](uint64_t context, const char* version){
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

            // std::thread([runtime = runtime, user = u->user](){
            //     run_game(runtime, get_device_key_chain(), user, "/tmp/Microsoft.MinecraftUWP_1.26.6201.0_x64__8wekyb3d8bbwe.msixvc", "/Users/christopher/Documents/minecraft/crossover/sources/gdk-min/usr/local/bin/wine");
            // }).detach();

            // fetch_package(runtime, "http://assets2.xboxlive.com/10/90cabc1f-237a-477d-8c9d-38a76810a793/7792d9ce-355a-493c-afbd-768f4a77c3b0/1.26.6201.0.805550f5-bc84-493d-8f34-c57cadd9eccf/Microsoft.MinecraftUWP_1.26.6201.0_x64__8wekyb3d8bbwe.msixvc", new Data{this, u->user}, [](void *user, const void* pkg){
            //     auto data = (Data*)user;
            //     qDebug() << "fetch success for handle:" << pkg;
            //     package_dump(pkg);
            //     destroy_package(pkg);
            //     delete data;
            // //     auto qapp = QCoreApplication::instance();
            // //     QMetaObject::invokeMethod(qapp, [data, pkg]() {
            // //         data->timer = new QTimer(data->helper);

            // //         // Connect the timer's timeout signal to a periodic lambda execution loop
            // //         QObject::connect(data->timer, &QTimer::timeout, data->helper, [pkg]() {
            // //             // qDebug() << "This runs every 1000 milliseconds!";
            // //             auto progress = get_progress_all(pkg);
            // //             qDebug() << "Progress:" << progress.cur << "/" << progress.total;
            // //         });

            // //         // Start the timer with your periodic interval in milliseconds
            // //         data->timer->start(1000); 

            // //         download_all(data->helper->runtime, pkg, get_device_key_chain(), data->user, "http://assets2.xboxlive.com/10/90cabc1f-237a-477d-8c9d-38a76810a793/7792d9ce-355a-493c-afbd-768f4a77c3b0/1.26.6201.0.805550f5-bc84-493d-8f34-c57cadd9eccf/Microsoft.MinecraftUWP_1.26.6201.0_x64__8wekyb3d8bbwe.msixvc", "/tmp/Microsoft.MinecraftUWP_1.26.6201.0_x64__8wekyb3d8bbwe.msixvc", reinterpret_cast<uint64_t>(data),
            // //             [](uint64_t ucontext){
            // //                 auto data = (Data*)ucontext;
            // //                 qDebug() << "Download success for context:" << ucontext << "user:" << data->user;
            // //                 data->timer->stop();
            // //                 delete data;
            // //             },
            // //             [](uint64_t ucontext, const char* error){
            // //                 auto data = (Data*)ucontext;
            // //                 qDebug() << "Download failed for context:" << ucontext << "error:" << error << "user:" << data->user;
            // //                 data->timer->stop();
            // //                 delete data;
            // //             }
            // //         );
            // //     });
            // //     // abort();
            // }, [](void *user, const char* error){
            //     qDebug() << "Failed to fetch package:" << error;
            //     // abort();
            // });

        } else {
            hasEncryptedCredentials = true;
        }
    }
    settings.endArray();

    loadDeviceState();
    updateDevice();
}

void XHelper::loadDeviceState() {
    // settings.beginGroup("device_state");
    // device.generated_mac_addr = settings.value("generated_mac_addr").toString().toStdString();
    // device.generated_meid = settings.value("generated_meid").toString().toStdString();
    // device.generated_serial_number = settings.value("generated_serial_number").toString().toStdString();
    // device.random_logging_id = settings.value("generated_serial_number").toLongLong();
    // settings.endGroup();
}

void XHelper::saveDeviceState() {
    // settings.beginGroup("device_state");
    // settings.setValue("generated_mac_addr", QString::fromStdString(device.generated_mac_addr));
    // settings.setValue("generated_meid", QString::fromStdString(device.generated_meid));
    // settings.setValue("generated_serial_number", QString::fromStdString(device.generated_serial_number));
    // settings.setValue("random_logging_id", device.random_logging_id);
    // // Continue to write it for backward compatibility
    // settings.beginWriteArray("native_platforms", device.config_native_platforms.size());
    // for (int i = 0; i < device.config_native_platforms.size(); ++i) {
    //     settings.setArrayIndex(i);
    //     settings.setValue("platform", QString::fromStdString(device.config_native_platforms[i]));
    // }
    // settings.endArray();
    // settings.endGroup();
}

void XHelper::acquireAccount(QWindow *parent) {
    if (window)
        return;
    struct Data {
        XHelper* helper;
        QWindow* parent;
        std::string accountName;
    };
    user_refresh(runtime, get_device_key_chain(), nullptr, (uint64_t)(new Data{this, parent}), [](uint64_t context, const void* webview_context, const char* start_url, const char* end_url) {
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
                user_webview_submit(webview_context, helper->window->accountServerData().toStdString().c_str());
                XHelper* helper = data->helper;
                if(helper->window) {
                    helper->window = nullptr;
                }
            });
        });
    }, [](uint64_t context, const void* user) {
        auto qapp = QCoreApplication::instance();
        QMetaObject::invokeMethod(qapp, [data = (Data*)context, user]() {
            auto u = new XUser();
            u->setAccountName(QString::fromStdString(data->accountName));
            u->user = (void*)user;
            data->helper->loginCache[QString::fromStdString(data->accountName)] = u;
            data->helper->accountInfoChanged();
            user_export(user, data, [](void* ctx, const char* serialized) {
                Data* data = (Data*)ctx;
                // unlockkey = data->helper->window->encryptionToken();
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
                // saveDeviceState();
                // accountAcquireFinished(&currentAccount);

                delete data;
            });
        });
    }, [](uint64_t context, const char* error) {
        Data* data = (Data*)context;
        delete data;
    });
}

void XHelper::onLoginFinished(int code) {
    accountAcquireFinished(nullptr);
    
    // if (code == QDialog::Accepted) {
    //     try {
    //         unlockkey = window->encryptionToken();
    //         Encryption enc;
    //         if(unlockkey.isEmpty()) {
    //             unlockkey = QString::fromStdString(enc.RandomKey());
    //             settings.setValue("key", unlockkey);
    //         }
    //         loginCache.clear();
    //         loginCache.setKey(unlockkey.toStdString());
    //         login.perform_with_access_token(window->accountToken().toStdString(), window->accountIdentifier().toStdString(), true)->call();
    //         currentAccount.setAccountIdentifier(QString::fromStdString(login.get_email()));
    //         currentAccount.setAccountUserId(window->accountUserId());
    //         currentAccount.setAccountToken(QString::fromStdString(login.get_token()));
    //         hasAccount = currentAccount.isValid();
    //         if (hasAccount) {
    //             settings.beginGroup("googlelogin");
    //             settings.setValue("encrypted", QString::fromStdString(enc.Encrypt("true", unlockkey.toStdString())));
    //             settings.setValue("identifier", QString::fromStdString(enc.Encrypt(currentAccount.accountIdentifier().toStdString(), unlockkey.toStdString())));
    //             settings.setValue("userId", QString::fromStdString(enc.Encrypt(currentAccount.accountUserId().toStdString(), unlockkey.toStdString())));
    //             settings.setValue("token", QString::fromStdString(enc.Encrypt(currentAccount.accountToken().toStdString(), unlockkey.toStdString())));
    //             settings.endGroup();
    //             saveDeviceState();
    //             accountAcquireFinished(&currentAccount);
    //         } else {
    //             loginError("Login failed");
    //             accountAcquireFinished(nullptr);
    //         }
    //     } catch (const std::exception& ex) {
    //         loginError(ex.what());
    //         accountAcquireFinished(nullptr);
    //     }
    // } else {
    //     accountAcquireFinished(nullptr);
    // }
    emit accountInfoChanged();
    window = nullptr;
}

void XHelper::updateDevice() {

    emit accountInfoChanged();
}

void XHelper::signOut() {

    hasEncryptedCredentials = false;
    emit accountInfoChanged();
}

XProgress *XHelper::downloadPackage(const QString &packageId, const QString &version) {
    XProgress* progress = new XProgress();
    progress->setProgress(0);
    progress->setMaximum(100);

    struct Data {
        XHelper* helper;
        const void* user;
        QTimer *timer;
        XProgress* progress;
    };

    auto d = new Data{this, this->loginCache.first()->user, nullptr, progress};
    
    fetch_package(runtime, "http://assets2.xboxlive.com/10/90cabc1f-237a-477d-8c9d-38a76810a793/7792d9ce-355a-493c-afbd-768f4a77c3b0/1.26.6201.0.805550f5-bc84-493d-8f34-c57cadd9eccf/Microsoft.MinecraftUWP_1.26.6201.0_x64__8wekyb3d8bbwe.msixvc", d, [](void *user, const void* pkg){
    auto data = (Data*)user;
    qDebug() << "fetch success for handle:" << pkg;
    package_dump(pkg);
    auto qapp = QCoreApplication::instance();
    QMetaObject::invokeMethod(qapp, [data, pkg]() {
        data->timer = new QTimer(data->helper);

        // Connect the timer's timeout signal to a periodic lambda execution loop
        QObject::connect(data->timer, &QTimer::timeout, data->helper, [pkg, data]() {
            // qDebug() << "This runs every 1000 milliseconds!";
            auto progress = get_progress_all(pkg);
            qDebug() << "Progress:" << progress.cur << "/" << progress.total;
            data->progress->setProgress(progress.cur);
            data->progress->setMaximum(progress.total);
        });

        // Start the timer with your periodic interval in milliseconds
        data->timer->start(1000); 

        download_all(data->helper->runtime, pkg, get_device_key_chain(), data->user, "http://assets2.xboxlive.com/10/90cabc1f-237a-477d-8c9d-38a76810a793/7792d9ce-355a-493c-afbd-768f4a77c3b0/1.26.6201.0.805550f5-bc84-493d-8f34-c57cadd9eccf/Microsoft.MinecraftUWP_1.26.6201.0_x64__8wekyb3d8bbwe.msixvc", "/tmp/Microsoft.MinecraftUWP_1.26.6201.0_x64__8wekyb3d8bbwe.msixvc", reinterpret_cast<uint64_t>(data),
            [](uint64_t ucontext){
                auto data = (Data*)ucontext;
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
//     // abort();
}, [](void *user, const char* error){
    qDebug() << "Failed to fetch package:" << error;
    // abort();
});


    return progress;
}

void XHelper::runPackage(const QString &packageId, const QString &version) {
    std::thread([runtime = runtime, user = this->loginCache.first()->user](){
        run_game(runtime, get_device_key_chain(), user, "/tmp/Microsoft.MinecraftUWP_1.26.6201.0_x64__8wekyb3d8bbwe.msixvc", "/Users/christopher/Documents/minecraft/crossover/sources/gdk-min/usr/local/bin/wine");
    }).detach();
}

XAsyncVariant* XHelper::resolvePackage(const QString &packageId, const QString &version) {
    XAsyncVariant* progress = new XAsyncVariant();
    auto user = this->loginCache.first()->user;
    struct Data {
        XHelper* helper;
        void* user;
        XAsyncVariant* progress; 
    } *d = new Data{this, user, progress};
    // "1.26.3301.0.657f39f1-dcd0-491b-9bb7-c799d208f75e"
    get_game_versions(runtime, get_device_key_chain(), packageId.toStdString().c_str(), version.isEmpty() ? nullptr : version.toStdString().c_str(), (uint64_t)d, [](uint64_t context, const char* version){
        std::string sver = version;
        auto d = (Data*)context;
        QMetaObject::invokeMethod(d->helper, [context, sver]() {
            auto d = (Data*)context;
            QJsonDocument doc = QJsonDocument::fromJson(QByteArray::fromStdString(sver));
            d->progress->setVersion(QVariant::fromValue(doc.object()));
            delete d;
        });
    }, [](uint64_t context, const char* version){
        qDebug() << "Failure:" << QString::fromUtf8(version);
        auto d = (Data*)context;
        delete d;
    });
    return progress;
}
