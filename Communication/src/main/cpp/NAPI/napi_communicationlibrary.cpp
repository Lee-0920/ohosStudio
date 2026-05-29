// main/cpp/App/napi_communication.cpp
#include "napi/native_api.h"
#include "ControllerManager.h" // 假设你的控制器类在这里声明
#include "Module/napi_dncp.h"
#include "Module/napi_pump.h"
#include "Module/napi_valveMap.h"
#include "Module/napi_valve.h"
#include "Module/napi_temp.h"
#include "Module/napi_meter.h"
#include "Module/napi_meterPoints.h"
#include "Module/napi_optical.h"
#include "Module/napi_event.h"

#undef LOG_DOMAIN
#undef LOG_TAG
#define LOG_DOMAIN 0x3200  // 全局domain宏，标识业务领域
#define LOG_TAG "MY_TAG"   // 全局tag宏，标识模块日志tag

using namespace Communication;

EXTERN_C_START
// 模块初始化：注册所有函数
static napi_value Init(napi_env env, napi_value exports) {
    RegisterDncpModule(env, exports);
    RegisterPumpModule(env, exports);
    RegisterValveMapModule(env, exports);
    RegisterValveModule(env, exports);
    RegisterTempModule(env, exports);
    RegisterMeterPointsModule(env, exports);
    RegisterMeterModule(env, exports);
    RegisterOpticalModule(env, exports);
    RegisterEventModule(env, exports);
    return exports;
}
EXTERN_C_END

// 模块注册
static napi_module module = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "communication", // ← 必须与 ETS import 名一致
    .nm_priv = nullptr,
    .reserved = {0}
};

extern "C" __attribute__((constructor)) void RegisterModule(void) {
    napi_module_register(&module);
}