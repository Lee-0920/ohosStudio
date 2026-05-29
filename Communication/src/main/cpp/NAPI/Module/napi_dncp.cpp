#include "napi_dncp.h"
#include "App/AsyncScheduler.h"
#include "App/CommunicationLibrary.h"
#include "Dscp/DscpPacket.h" // 如果 DscpCmdTable 在此定义
#include "Stack/DncpStack.h"
#include "hilog/log.h"
#undef LOG_DOMAIN
#undef LOG_TAG
#define LOG_DOMAIN 0x3200  // 全局domain宏，标识业务领域
#define LOG_TAG "MY_TAG"   // 全局tag宏，标识模块日志tag

using namespace Communication;
// 全局唯一实例（初始为 nullptr）
std::unique_ptr<Controller::PT63DriveController> g_controller;
std::mutex g_mutex; 

static DscpAddress s_addr = {1,1,1,0};

// 辅助函数：从 JS 获取字符串
static std::string GetStringFromJS(napi_env env, napi_value value) {
    size_t len = 0;
    napi_get_value_string_utf8(env, value, nullptr, 0, &len);
    std::string str(len + 1, '\0');
    napi_get_value_string_utf8(env, value, &str[0], str.size(), &len);
    str.resize(len); // 去掉末尾 \0
    return str;
}

// 1. GetVersion()
static napi_value NapiGetVersion(napi_env env, napi_callback_info info) {
    napi_value jsVersion;
    std::string version = CommunicationLibrary::Instance()->GetVersion();
    napi_create_string_utf8(env, version.c_str(), version.length(), &jsVersion);
    sleep(3);
    return jsVersion;
}

// 2. Init()
static napi_value NapiCreatePlugin(napi_env env, napi_callback_info info) {
    std::lock_guard<std::mutex> lock(g_mutex);

    // 检查是否已存在
    if (g_controller == nullptr)
    {
        g_controller = std::make_unique<Controller::PT63DriveController>(s_addr);
        OH_LOG_INFO(LOG_APP, "PT63DriveController created");
    }
    else
    {
        OH_LOG_INFO(LOG_APP, "PT63DriveController created failed");   
    }
    
    bool result = CommunicationLibrary::Instance()->Init();
    napi_value jsResult;
    napi_get_boolean(env, result, &jsResult);
    return jsResult;
}

// 3. Uninit()
static napi_value NapiUninit(napi_env env, napi_callback_info info) {
    CommunicationLibrary::Instance()->Uninit();
    napi_value jsUndefined;
    napi_get_undefined(env, &jsUndefined);
    return jsUndefined;
}

// 4. Proxy() — 注意：Proxy 是关键字，改名为 DoProxy
static napi_value NapiDoProxy(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiDoProxy");
    CommunicationLibrary::Instance()->Proxy();
    napi_value jsUndefined;
    napi_get_undefined(env, &jsUndefined);
    return jsUndefined;
}

// 5. AddSlaveNode(int addr)
static napi_value NapiAddSlaveNode(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    int32_t addr = 0;
    napi_get_value_int32(env, args[0], &addr);

    CommunicationLibrary::Instance()->AddSlaveNode(static_cast<int>(addr));

    napi_value jsUndefined;
    napi_get_undefined(env, &jsUndefined);
    return jsUndefined;
}

// 这里先实现前三个参数，忽略 handle（或用全局回调）
static napi_value NapiInitDncpStack(napi_env env, napi_callback_info info) {
    size_t argc = 3;
    napi_value args[3];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    std::string serialPort = GetStringFromJS(env, args[0]);
    bool bridgeMode = false;
    napi_get_value_bool(env, args[1], &bridgeMode);
    std::string bridgeIP = GetStringFromJS(env, args[2]);

     OH_LOG_INFO(LOG_APP, "NapiInitDncpStack");
    // 注意：handle 参数暂时传 nullptr（需后续完善）
    bool result = CommunicationLibrary::Instance()->InitDncpStack(
        const_cast<char*>(serialPort.c_str()),
        bridgeMode,
        bridgeIP.c_str(),
        nullptr  // ← IConnectStatusNotifiable* 需要额外桥接
    );
    //注册事件
    if (g_controller != nullptr)
    {
        g_controller->Init();
    }
    

    napi_value jsResult;
    napi_get_boolean(env, result, &jsResult);
    return jsResult;
}

void RegisterDncpModule(napi_env env, napi_value exports) {
        // 1. 创建 pump 子对象
    napi_value pumpObj;
    napi_create_object(env, &pumpObj);

    // 2. 定义方法描述符
    napi_property_descriptor descriptors[] = {
        {"getVersion", nullptr, NapiGetVersion, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"createPlugin", nullptr, NapiCreatePlugin, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"uninit", nullptr, NapiUninit, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"doProxy", nullptr, NapiDoProxy, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"addSlaveNode", nullptr, NapiAddSlaveNode, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"initDncpStack", nullptr, NapiInitDncpStack, nullptr, nullptr, nullptr, napi_default, nullptr},
    };

    // 3. 将方法绑定到 pumpObj
    napi_define_properties(
        env,
        pumpObj,
        sizeof(descriptors) / sizeof(descriptors[0]),
        descriptors
    );

    // 4. 【关键】将 pumpObj 挂到 parentObj 上，属性名为 "pump"
    napi_set_named_property(env, exports, "dncp", pumpObj);
}