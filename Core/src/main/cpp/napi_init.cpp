#include "napi/native_api.h"
#include "hilog/log.h"

#undef LOG_DOMAIN
#undef LOG_TAG

#define LOG_DOMAIN 101  // 自定义业务领域标识
#define LOG_TAG "Core" // 自定义模块标签

static napi_value Add(napi_env env, napi_callback_info info)
{
    size_t argc = 2;
    napi_value args[2] = {nullptr};

    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    napi_valuetype valuetype0;
    napi_typeof(env, args[0], &valuetype0);

    napi_valuetype valuetype1;
    napi_typeof(env, args[1], &valuetype1);

    double value0;
    napi_get_value_double(env, args[0], &value0);

    double value1;
    napi_get_value_double(env, args[1], &value1);

    napi_value sum;
    napi_create_double(env, value0 * value1, &sum);

    return sum;

}


static napi_value RunFlow(napi_env env, napi_callback_info info)
{
    napi_value result;
    napi_status status;
    
    // 1. 加载 ArkTS 模块
    // 路径格式："模块路径/文件名" (相对于 src/main/ets)
    // 假设文件在 ./src/main/ets/components/FlowList.ets
    const char* modulePath = "components/FlowList"; 
    
    OH_LOG_INFO(LOG_APP, "components/FlowList");
    
    status = napi_load_module(env, modulePath, &result);
    if (status != napi_ok) {
        // 处理加载失败的情况
        return nullptr;
    }
    OH_LOG_INFO(LOG_APP, "RunAllFlow");
    // 2. 获取模块中导出的 myFunction 函数
    napi_value myFunction;
    status = napi_get_named_property(env, result, "RunAllFlow", &myFunction);
    if (status != napi_ok) {
        return nullptr;
    }
    OH_LOG_INFO(LOG_APP, "call RunAllFlow");
    // 3. 调用 myFunction 函数
    napi_value callResult;
    status = napi_call_function(env, result, myFunction, 0, nullptr, &callResult);
    if (status != napi_ok) {
        return nullptr;
    }
    OH_LOG_INFO(LOG_APP, "call RunAllFlow End");
    // 返回调用结果
    return callResult;
}

EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports)
{
    napi_property_descriptor desc[] = {
        { "add", nullptr, Add, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "runFlow", nullptr, RunFlow, nullptr, nullptr, nullptr, napi_default, nullptr}
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
    .nm_modname = "core",
    .nm_priv = ((void*)0),
    .reserved = { 0 },
};

extern "C" __attribute__((constructor)) void RegisterCoreModule(void)
{
    napi_module_register(&demoModule);
}
