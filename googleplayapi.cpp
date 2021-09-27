#include "googleplayapi.h"

#include "googleloginhelper.h"
#include "supportedandroidabis.h"
#include <QtConcurrent>

GooglePlayApi::GooglePlayApi(QObject *parent) : QObject(parent) {
}

void GooglePlayApi::setLogin(GoogleLoginHelper *helper) {
    if (loginHelper != helper) {
        setStatus(GooglePlayApiStatus::NOT_READY);
        if (loginHelper) {
            disconnect(loginHelper, &GoogleLoginHelper::accountInfoChanged, this, &GooglePlayApi::updateLogin);
        }
        loginHelper = helper;
        if (loginHelper) {
            api.reset(new playapi::api(loginHelper->getDevice()));
            connect(loginHelper, &GoogleLoginHelper::accountInfoChanged, this, &GooglePlayApi::updateLogin);
            updateLogin();
        }
    }
}

void GooglePlayApi::requestAppInfo(const QString &packageName) {
    if (status == GooglePlayApiStatus::SUCCEDED) {
        api->details(packageName.toStdString())->call([this, packageName](playapi::proto::finsky::response::ResponseWrapper&& resp) {
            auto details = resp.payload().detailsresponse().docv2();
            emit appInfoReceived(packageName, QString::fromStdString(details.details().appdetails().versionstring()), details.details().appdetails().versioncode(), details.details().appdetails().testingprograminfo().subscribed() || details.details().appdetails().testingprograminfo().subscribed1() );
        }, [this, packageName](std::exception_ptr e) {
            try {
                std::rethrow_exception(e);
            } catch (std::exception&ex) {
                emit appInfoFailed(packageName, ex.what());
            }
        });
    } else {
        emit appInfoFailed(packageName, tr("GooglePlayApi not Ready status=%1").arg((int)status));
    }
}

QString GooglePlayApi::CheckinInfoGroup() {
    std::stringstream ss;
    ss << "checkin_";
    for (auto&& abi : loginHelper->getDevice().config_native_platforms) {
        ss << "__" << abi;
    }
    return QString::fromStdString(ss.str());
}

void GooglePlayApi::loadCheckinInfo() {
    QSettings settings;
    settings.beginGroup(CheckinInfoGroup());
    checkinResult.time = settings.value("time").toLongLong();
    checkinResult.android_id = settings.value("android_id").toULongLong();
    checkinResult.security_token = settings.value("security_token").toULongLong();
    checkinResult.device_data_version_info = settings.value("device_data_version_info").toString().toStdString();
    settings.endGroup();
}

void GooglePlayApi::saveCheckinInfo() {
    QSettings settings;
    settings.beginGroup(CheckinInfoGroup());
    settings.setValue("time", checkinResult.time);
    settings.setValue("android_id", checkinResult.android_id);
    settings.setValue("security_token", checkinResult.security_token);
    settings.setValue("device_data_version_info", QString::fromStdString(checkinResult.device_data_version_info));
    settings.endGroup();
}

void GooglePlayApi::loadApiInfo() {
    std::lock_guard<std::mutex> lock (api->info_mutex);

    QSettings settings;
    settings.beginGroup("playapi");
    api->device_config_token = settings.value("device_config_token").toString().toStdString();
    api->toc_cookie = settings.value("toc_cookie").toString().toStdString();
    api->experiments.set_targets(settings.value("experiments").toString().toStdString());
    settings.endGroup();
}

void GooglePlayApi::saveApiInfo() {
    std::lock_guard<std::mutex> lock (api->info_mutex);

    QSettings settings;
    settings.beginGroup("playapi");
    settings.setValue("device_config_token", QString::fromStdString(api->device_config_token));
    settings.setValue("toc_cookie", QString::fromStdString(api->toc_cookie));
    settings.setValue("experiments", QString::fromStdString(api->experiments.get_comma_separated_target_list()));
    settings.endGroup();
}

void GooglePlayApi::cleanupLogin() {
    QSettings settings;
    settings.remove("playapi");
    for (auto && group : settings.childGroups()) {
        if (group.startsWith("checkin")) {
            settings.remove(group);
        }
    }
}

void GooglePlayApi::updateLogin() {
    QtConcurrent::run([this]() {
        try {
            QMutexLocker checkinMutexLocker (&checkinMutex);
            if (status == GooglePlayApiStatus::PENDING) {
                emit initError(tr("<b>Please report this error</b><br>GooglePlayApi already in progress status reporting not working status=%1").arg((int)status));
            }
            setStatus(GooglePlayApiStatus::PENDING);
            loadCheckinInfo();
            if (!loginHelper) {
                setStatus(GooglePlayApiStatus::FAILED);
                emit initError(tr("<b>Please report this error</b><br>GooglePlayApi needs the loginHelper"));
                return;
            } else if (loginHelper->account() == nullptr) {
                setStatus(GooglePlayApiStatus::NOT_READY);
                cleanupLogin();
                return;
            } else if (checkinResult.android_id == 0) {
                playapi::checkin_api checkin(loginHelper->getDevice());
                checkin.add_auth(loginHelper->getLoginApi())->call();
                checkinResult = checkin.perform_checkin()->call();
                saveCheckinInfo();
            }
            api->set_checkin_data(checkinResult);
            checkinMutexLocker.unlock();
            api->set_auth(loginHelper->getLoginApi())->call();

            loadApiInfo();

            api->info_mutex.lock();
            bool needsAcceptTos = api->toc_cookie.empty() || api->device_config_token.empty();
            api->info_mutex.unlock();
            if (needsAcceptTos) {
                api->fetch_user_settings()->call();
                auto toc = api->fetch_toc()->call();
                if (toc.payload().tocresponse().has_cookie())
                    api->set_toc_cookie(toc.payload().tocresponse().cookie());

                if (api->fetch_toc()->call().payload().tocresponse().requiresuploaddeviceconfig()) {
                    auto resp = api->upload_device_config()->call();
                    api->set_device_config_token(resp.payload().uploaddeviceconfigresponse().uploaddeviceconfigtoken());

                    toc = api->fetch_toc()->call();
                    if (toc.payload().tocresponse().requiresuploaddeviceconfig() || !toc.payload().tocresponse().has_cookie())
                        throw std::runtime_error("Invalid state");
                    api->set_toc_cookie(toc.payload().tocresponse().cookie());
                    if (toc.payload().tocresponse().has_toscontent() && toc.payload().tocresponse().has_tostoken()) {
                        auto tos = api->accept_tos(toc.payload().tocresponse().tostoken(), false)->call();
                        if (!tos.payload().has_accepttosresponse())
                            throw std::runtime_error("Invalid state");
                        saveApiInfo();
                    }
                }
            }

            setStatus(GooglePlayApiStatus::SUCCEDED);
            emit ready();
        } catch (const std::exception& ex) {
            setStatus(GooglePlayApiStatus::FAILED);
            cleanupLogin();
            emit initError(ex.what());
        }
    });
}

void GooglePlayApi::validateLicense(std::string packagename, int versionscode, std::function<void(bool)> callback) {
    api->delivery(packagename, versionscode, std::string())->call([callback](playapi::proto::finsky::response::ResponseWrapper&& resp) {
        auto dd = resp.payload().deliveryresponse().appdeliverydata();
        callback((dd.has_gzippeddownloadurl() ? dd.gzippeddownloadurl() : dd.downloadurl()) != "");
    }, [callback](std::exception_ptr e) {
        callback(false);
    });
}
