#include "googleplayapi.h"

#include "googleloginhelper.h"
#include <QtConcurrent>

GooglePlayApi::GooglePlayApi(QObject *parent) : QObject(parent) {
}

void GooglePlayApi::setLogin(GoogleLoginHelper *helper) {
    loginHelper = helper;
    api.reset(new playapi::api(helper->getDevice()));
    updateLogin();
}

void GooglePlayApi::updateLogin() {
}

void GooglePlayApi::requestAppInfo(const QString &packageName) {
    api->details(packageName.toStdString())->call([this, packageName](playapi::proto::finsky::response::ResponseWrapper&& resp) {
        auto details = resp.payload().detailsresponse().docv2();
        emit appInfoReceived(packageName, QString::fromStdString(details.details().appdetails().versionstring()), details.details().appdetails().versioncode());
    }, [](std::exception_ptr e) {
        //
    });
}

void GooglePlayApi::loadCheckinInfo() {
    QSettings settings;
    settings.beginGroup("checkin");
    checkinResult.time = settings.value("time").toLongLong();
    checkinResult.android_id = settings.value("android_id").toULongLong();
    checkinResult.security_token = settings.value("security_token").toULongLong();
    checkinResult.device_data_version_info = settings.value("device_data_version_info").toString().toStdString();
    settings.endGroup();
}

void GooglePlayApi::saveCheckinInfo() {
    QSettings settings;
    settings.beginGroup("checkin");
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

void GooglePlayApi::handleCheckinAndTos() {
    QtConcurrent::run([this]() {
        QMutexLocker checkinMutexLocker (&checkinMutex);
        loadCheckinInfo();
        if (checkinResult.android_id == 0 && loginHelper->account() != nullptr) {
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
                    tosApprovalPromise = std::promise<std::pair<bool, bool>>();
                    auto future = tosApprovalPromise.get_future();
                    emit tosApprovalRequired(QString::fromStdString(toc.payload().tocresponse().toscontent()),
                                             QString::fromStdString(toc.payload().tocresponse().toscheckboxtextmarketingemails()));
                    auto state = future.get();
                    if (!state.first)
                        throw std::runtime_error("Rejected TOS");
                    auto tos = api->accept_tos(toc.payload().tocresponse().tostoken(), state.second)->call();
                    if (!tos.payload().has_accepttosresponse())
                        throw std::runtime_error("Invalid state");
                    saveApiInfo();
                }
            }
        }

        emit ready();
    });
}

