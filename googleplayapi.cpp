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

static QString CheckinInfoGroup() {
    std::stringstream ss;
    ss << "checkin";
    for (auto&& abi : SupportedAndroidAbis::getAbis()) {
        if(abi.second.compatible) {
            ss << "_" << abi.first;
        }
    }
    for (auto&& abi : SupportedAndroidAbis::getAbis()) {
        if(!abi.second.compatible) {
            ss << "_" << abi.first;
        }
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
    api->experiments.set_targets(settings.value("experiments").toString().toStdString());
    settings.endGroup();
}

void GooglePlayApi::saveApiInfo() {
    std::lock_guard<std::mutex> lock (api->info_mutex);

    QSettings settings;
    settings.beginGroup("playapi");
    settings.setValue("device_config_token", QString::fromStdString(api->device_config_token));
    settings.setValue("experiments", QString::fromStdString(api->experiments.get_comma_separated_target_list()));
    settings.endGroup();
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
            if (checkinResult.android_id == 0) {
                if (!loginHelper) {
                    setStatus(GooglePlayApiStatus::FAILED);
                    emit initError(tr("<b>Please report this error</b><br>GooglePlayApi needs the loginHelper"));
                    return;
                } else if (loginHelper->account() == nullptr) {
                    return;
                }
                playapi::checkin_api checkin(loginHelper->getDevice());
                checkin.add_auth(loginHelper->getLoginApi())->call();
                checkinResult = checkin.perform_checkin()->call();
                saveCheckinInfo();
            }
            api->set_checkin_data(checkinResult);
            checkinMutexLocker.unlock();
            api->set_auth(loginHelper->getLoginApi())->call();

            loadApiInfo();
            saveApiInfo();
            setStatus(GooglePlayApiStatus::SUCCEDED);
            emit ready();
        } catch (const std::exception& ex) {
            setStatus(GooglePlayApiStatus::FAILED);
            emit initError(ex.what());
        }
    });
}

