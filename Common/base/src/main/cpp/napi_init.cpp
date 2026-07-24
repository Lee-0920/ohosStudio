#include "napi/native_api.h"
#include <thread>
#include <chrono>

// C++ 原生 Sleep
static napi_value NativeSleep(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    int32_t ms;
    napi_status status = napi_get_value_int32(env, args[0], &ms);
    if (status != napi_ok || ms < 0) {
        napi_throw_error(env, nullptr, "Sleep参数为负");
        return nullptr;
    }
    
    // 真正的线程 Sleep
    std::this_thread::sleep_for(std::chrono::milliseconds(ms));
    
    napi_value result;
    napi_get_undefined(env, &result);
    return result;
}

// long GetOSRunTime();
static napi_value NativeGetOSRunTime(napi_env env, napi_callback_info info) {
    napi_value result;
    napi_create_int64(env, std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::system_clock::now().time_since_epoch()).count(), &result);
    return result;
}

// getCurrentThreadId(): number
static napi_value NativeGetCurrentThreadId(napi_env env, napi_callback_info info) {
    napi_value result;
    napi_create_int64(env, (int64_t)pthread_self(), &result);
    return result;
}

EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports)
{
    napi_property_descriptor desc[] = {
        { "sleep", nullptr, NativeSleep, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getOSRunTime", nullptr, NativeGetOSRunTime, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getCurrentThreadId", nullptr, NativeGetCurrentThreadId, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}
EXTERN_C_END

static napi_module demoModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "base",
    .nm_priv = ((void*)0),
    .reserved = { 0 },
};

extern "C" __attribute__((constructor)) void RegisterBaseModule(void)
{
    napi_module_register(&demoModule);
}
