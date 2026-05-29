#include "napi_valve.h"
#include "hilog/log.h"
#undef LOG_DOMAIN
#undef LOG_TAG
#define LOG_DOMAIN 0x3200  // 全局domain宏，标识业务领域
#define LOG_TAG "MY_TAG"   // 全局tag宏，标识模块日志tag

static napi_value NapiGetTotalValves(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiGetTotalValves");

    int32_t num;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller != nullptr && g_controller->ISolenoidValve != nullptr) {
            num = g_controller->ISolenoidValve->GetTotalValves();
        }
    }
    napi_value result;
    napi_status status = napi_create_int32(env, num, &result);
    if (status != napi_ok) {
        // 错误处理（可选）
        return nullptr;
    }
    return result; // 直接返回对象，无需 undefined
   
}

static napi_value NapiGetValveMap(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiGetValveMap");

    ValveMap map;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller != nullptr && g_controller->ISolenoidValve != nullptr) {
            map = g_controller->ISolenoidValve->GetValveMap();
        }
    }
    
    // 2. 在堆上创建副本（必须！）
    ValveMap* heapMap = new ValveMap(map); // 拷贝到堆

    // 3. 创建一个空的 JS 对象（用于绑定）
    napi_value jsValveMap;
    napi_create_object(env, &jsValveMap);

    // 4. 将 C++ 对象绑定到 JS 对象
    napi_status status = napi_wrap(
        env,
        jsValveMap,
        heapMap,
        [](napi_env env, void* native, void* hint) {
            delete static_cast<ValveMap*>(native); // 析构
        },
        nullptr, // finalize_hint
        nullptr  // ref
    );

    if (status != napi_ok) {
        delete heapMap; // 失败时手动清理
        return nullptr;
    }

    // 5. 返回 JS 对象
    return jsValveMap;
}

static napi_value NapiSetValveMap(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiSetValveMap");

    // 1. 获取 JS 参数（期望传入一个 ValveMap 对象）
    size_t argc = 1;
    napi_value args[1];
    napi_status status = napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    if (status != napi_ok || argc < 1) {
        OH_LOG_ERROR(LOG_APP, "Invalid arguments: expected one ValveMap object");
        return nullptr;
    }

    // 3. 解包出 C++ ValveMap 指针
    ValveMap* vm = nullptr;
    status = napi_unwrap(env, args[0], reinterpret_cast<void**>(&vm));
    if (status != napi_ok || vm == nullptr) {
        OH_LOG_ERROR(LOG_APP, "Failed to unwrap ValveMap object");
        return nullptr;
    }

    bool result = false;
    // 4. 调用业务逻辑（加锁）
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller != nullptr && g_controller->ISolenoidValve != nullptr) {
            result = g_controller->ISolenoidValve->SetValveMap(*vm); // 传入副本或引用（根据 SetValveMap 签名）
        } else {
            OH_LOG_WARN(LOG_APP, "Controller or ISolenoidValve is null");
        }
    }

    // 5. 返回 result（boolean 函数）
    napi_value jsResult;
    napi_get_boolean(env, result, &jsResult);
    return jsResult;
}

static napi_value NapiCtrlSpinValve(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiCtrlSpinValve");

    // 1. 获取 JS 参数（期望传入一个 ValveMap 对象）
    size_t argc = 1;
    napi_value args[1];
    napi_status status = napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    if (status != napi_ok || argc < 1) {
        OH_LOG_ERROR(LOG_APP, "Invalid arguments: expected one ValveMap object");
        return nullptr;
    }

    // 3. 解包出 C++ ValveMap 指针
    ValveMap* vm = nullptr;
    status = napi_unwrap(env, args[0], reinterpret_cast<void**>(&vm));
    if (status != napi_ok || vm == nullptr) {
        OH_LOG_ERROR(LOG_APP, "Failed to unwrap ValveMap object");
        return nullptr;
    }

     bool result = false;
    // 4. 调用业务逻辑（加锁）
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller != nullptr && g_controller->ISolenoidValve != nullptr) {
            result = g_controller->ISolenoidValve->CtrlSpinValve(*vm); // 传入副本或引用（根据 SetValveMap 签名）
        } else {
            OH_LOG_WARN(LOG_APP, "Controller or ISolenoidValve is null");
        }
    }

    // 4. 返回 JS boolean
    napi_value jsResult;
    napi_get_boolean(env, result, &jsResult);
    return jsResult;
}

static napi_value NapiSetValve16(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiSetValve16");

    // 1. 获取 JS 参数（期望一个 boolean 或 number）
    size_t argc = 1;
    napi_value args[1];
    if (napi_get_cb_info(env, info, &argc, args, nullptr, nullptr) != napi_ok || argc < 1) {
        OH_LOG_ERROR(LOG_APP, "Missing argument: expected isOpen (boolean/number)");
        napi_throw_error(env, nullptr, "Expected one argument: isOpen");
        return nullptr;
    }

    // 2. 转换参数：支持 boolean 或 number（0/1）
    bool isOpenBool = false;
    if (napi_get_value_bool(env, args[0], &isOpenBool) != napi_ok) {
        // 如果不是 boolean，尝试转为 uint32 再转 bool
        uint32_t val = 0;
        if (napi_get_value_uint32(env, args[0], &val) != napi_ok) {
            OH_LOG_ERROR(LOG_APP, "Argument must be boolean or number");
            napi_throw_error(env, nullptr, "isOpen must be boolean or 0/1");
            return nullptr;
        }
        isOpenBool = (val != 0);
    }

    Uint8 isOpen = static_cast<Uint8>(isOpenBool);

    // 3. 调用业务逻辑（加锁）
    bool result = false;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller != nullptr && g_controller->ISolenoidValve != nullptr) {
            result = g_controller->ISolenoidValve->SetValve16(isOpen);
        } else {
            OH_LOG_WARN(LOG_APP, "Controller or ISolenoidValve is null");
            // 可选：视为失败
            result = false;
        }
    }

    // 4. 返回 JS boolean
    napi_value jsResult;
    napi_get_boolean(env, result, &jsResult);
    return jsResult;
}

static napi_value NapiSetCheckLeakingPeriod(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiSetCheckLeakingPeriod");

    // 1. 获取 JS 参数（期望一个 number）
    size_t argc = 1;
    napi_value args[1];
    if (napi_get_cb_info(env, info, &argc, args, nullptr, nullptr) != napi_ok || argc < 1) {
        OH_LOG_ERROR(LOG_APP, "Missing argument: expected period (number)");
        napi_throw_error(env, nullptr, "Expected one argument: period (number)");
        return nullptr;
    }

    // 2. 转换参数：从 JS number 到 C++ float
    double periodDouble = 0.0;
    if (napi_get_value_double(env, args[0], &periodDouble) != napi_ok) {
        OH_LOG_ERROR(LOG_APP, "Argument must be a number");
        napi_throw_error(env, nullptr, "period must be a number");
        return nullptr;
    }

    // 可选：校验范围（例如 period > 0）
    if (periodDouble <= 0.0) {
        OH_LOG_WARN(LOG_APP, "Invalid period value: %{public}f", periodDouble);
        // 根据业务决定是否允许 ≤0；此处视为非法
        napi_throw_error(env, nullptr, "period must be greater than 0");
        return nullptr;
    }

    float period = static_cast<float>(periodDouble);

    // 3. 调用底层业务逻辑（加锁保护）
    bool result = false;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller != nullptr && g_controller->ISolenoidValve != nullptr) {
            result = g_controller->ISolenoidValve->SetCheckLeakingPeriod(period);
        } else {
            OH_LOG_WARN(LOG_APP, "Controller or ISolenoidValve is null");
            result = false; // 或抛异常，根据需求
        }
    }

    // 4. 返回 JS boolean
    napi_value jsResult;
    napi_get_boolean(env, result, &jsResult);
    return jsResult;
}

void RegisterValveModule(napi_env env, napi_value exports) {
    // 1. 创建 pump 子对象
    napi_value valveObj;
    napi_create_object(env, &valveObj);

    // 2. 定义方法描述符 NapiGetTotalPumps
    napi_property_descriptor descriptors[] = {
        {"getTotalValves", nullptr, NapiGetTotalValves, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getValveMap", nullptr, NapiGetValveMap, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setValveMap", nullptr, NapiSetValveMap, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"ctrlSpinValve", nullptr, NapiCtrlSpinValve, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setValve16", nullptr, NapiSetValve16, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setCheckLeakingPeriod", nullptr, NapiSetCheckLeakingPeriod, nullptr, nullptr, nullptr, napi_default, nullptr},
    };

    // 3. 将方法绑定到 valveObj
    napi_define_properties(
        env,
        valveObj,
        sizeof(descriptors) / sizeof(descriptors[0]),
        descriptors
    );

    // 4. 【关键】将 valveObj 挂到 parentObj 上，属性名为 "pump"
    napi_set_named_property(env, exports, "valve", valveObj);
}