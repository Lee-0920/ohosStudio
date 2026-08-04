// ConnectStatusBridge.h
#ifndef CONNECT_STATUS_BRIDGE_H
#define CONNECT_STATUS_BRIDGE_H

#include <napi/native_api.h>
#include "CommunicationPlugin/eCek/DNCP/Lai/IConnectStatusNotifiable.h"
#include <string>
#include <mutex>
#include <unordered_map>
#include "ControllerManager.h"
#include "hilog/log.h"

#undef LOG_DOMAIN
#undef LOG_TAG
#define LOG_DOMAIN 0x3200
#define LOG_TAG "ConnectBridge"

class ConnectStatusBridge : public IConnectStatusNotifiable {
public:
    explicit ConnectStatusBridge(napi_env env, napi_value jsCallback) {
        std::string asyncName = "OnConnectStatusChanged";
        napi_value name;
        napi_create_string_utf8(env, asyncName.c_str(), asyncName.length(), &name);

        napi_create_threadsafe_function(
            env, jsCallback, nullptr, name,
            0, 1, nullptr, nullptr, nullptr,
            CallJsCallback, &tsfn_
        );
    }

    ~ConnectStatusBridge() override {
        if (tsfn_ != nullptr) {
            napi_release_threadsafe_function(tsfn_, napi_tsfn_abort);
            tsfn_ = nullptr;
        }
    }

    // ✅ 通信线程回调：更新缓存 + 通知 JS
    void OnConnectStatusChanged(unsigned char pollingAddr, bool status) override {
        // 1. 线程安全地更新本地缓存
        {
            std::lock_guard<std::mutex> lock(statusMutex_);
            statusCache_[pollingAddr] = status;
            g_controller->SetConnectStatus(status);
        }

        OH_LOG_INFO(LOG_APP, "OnConnectStatusChanged: addr=%{public}u, status=%{public}d", 
                    pollingAddr, status);

        // 2. 推送到 JS 层
        if (tsfn_ == nullptr) return;
        auto* data = new ConnectEventData{pollingAddr, status};
        napi_status s = napi_call_threadsafe_function(tsfn_, data, napi_tsfn_nonblocking);
        if (s != napi_ok) {
            delete data;
        }
    }

    // ✅ 新增：查询指定设备的连接状态（线程安全）
    bool IsConnected(unsigned char pollingAddr) const {
        std::lock_guard<std::mutex> lock(statusMutex_);
        auto it = statusCache_.find(pollingAddr);
        return (it != statusCache_.end()) ? it->second : false;
    }

    // ✅ 新增：查询所有设备状态快照
    std::unordered_map<unsigned char, bool> GetAllStatus() const {
        std::lock_guard<std::mutex> lock(statusMutex_);
        return statusCache_;
    }

private:
    struct ConnectEventData {
        unsigned char pollingAddr;
        bool status;
    };

    static void CallJsCallback(napi_env env, napi_value jsCb, void*, void* rawData) {
        auto* data = static_cast<ConnectEventData*>(rawData);
        if (env == nullptr || jsCb == nullptr) {
            delete data;
            return;
        }
        napi_value argv[2];
        napi_create_uint32(env, data->pollingAddr, &argv[0]);
        napi_get_boolean(env, data->status, &argv[1]);
        napi_call_function(env, nullptr, jsCb, 2, argv, nullptr);
        delete data;
    }

    napi_threadsafe_function tsfn_ = nullptr;
    
    // ✅ 线程安全的状态缓存
    mutable std::mutex statusMutex_;
    std::unordered_map<unsigned char, bool> statusCache_;
};

#endif // CONNECT_STATUS_BRIDGE_H