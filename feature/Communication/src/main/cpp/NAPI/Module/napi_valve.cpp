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

    // 1. 从硬件/控制器获取 C++ ValveMap（栈上副本）
    ValveMap map;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller != nullptr && g_controller->ISolenoidValve != nullptr) {
            map = g_controller->ISolenoidValve->GetValveMap();
        } else {
            OH_LOG_WARN(LOG_APP, "Controller or ISolenoidValve is null, returning default ValveMap");
        }
    }

    // 2. ❌ 删除 new ValveMap / napi_wrap / 析构lambda
    // ✅ 改为：创建纯 JS 对象并逐属性赋值
    napi_value jsValveMap;
    napi_create_object(env, &jsValveMap);

    // 辅助 lambda：将 int32 值写入 JS 对象属性
    auto setInt32Prop = [&](const char* name, int32_t value) {
        napi_value jsVal;
        napi_create_int32(env, value, &jsVal);
        napi_set_named_property(env, jsValveMap, name, jsVal);
    };

    // ⚠️ 根据 ValveMap 实际 Getter 调整此处
    setInt32Prop("data",   map.GetData());
    setInt32Prop("cmd",    static_cast<int32_t>(map.GetCmd()));
    setInt32Prop("param1", static_cast<int32_t>(map.GetParam1()));
    setInt32Prop("param2", static_cast<int32_t>(map.GetParam2()));
    setInt32Prop("index",  static_cast<int32_t>(map.GetIndex()));

    OH_LOG_INFO(LOG_APP, "NapiGetValveMap returned: data=%{public}d cmd=%{public}d",
                map.GetData(), map.GetCmd());

    // 3. 返回纯数据 JS 对象（无 wrap、无 C++ 指针、可被 @Sendable 接收）
    return jsValveMap;
}

static napi_value NapiSetValveMap(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiSetValveMap");

    // 1. 获取 JS 参数（@Sendable ValveMap 纯数据对象）
    size_t argc = 1;
    napi_value args[1];
    napi_status status = napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    if (status != napi_ok || argc < 1) {
        OH_LOG_ERROR(LOG_APP, "Invalid arguments: expected one ValveMap object");
        return nullptr;
    }

    // 2. ❌ 删除 napi_unwrap（@Sendable 对象没有 wrap 指针）
    // ✅ 改为：从 JS 对象属性中提取字段，构造栈上 C++ ValveMap
    int32_t data = 0, cmd = 0, param1 = 0, param2 = 0, index = 0;

    auto readInt32Prop = [&](const char* propName, int32_t& out) {
        napi_value prop;
        if (napi_get_named_property(env, args[0], propName, &prop) == napi_ok) {
            napi_get_value_int32(env, prop, &out);
        }
    };

    readInt32Prop("data",   data);
    readInt32Prop("cmd",    cmd);
    readInt32Prop("param1", param1);
    readInt32Prop("param2", param2);
    readInt32Prop("index",  index);

    // ⚠️ 根据 ValveMap 的实际构造函数/Setter 调整此处
    // 方式A：如果有全参构造函数
    ValveMap vm(data);
    vm.SetSpinValveCmd(cmd, param1, param2);
    // 如果 index 也需要设置，调用对应 setter

    // 方式B：如果只有默认构造 + setter
    // ValveMap vm;
    // vm.SetData(data);
    // vm.SetSpinValveCmd(cmd, param1, param2);

    OH_LOG_INFO(LOG_APP, "Parsed ValveMap: data=%{public}d cmd=%{public}d p1=%{public}d p2=%{public}d idx=%{public}d",
                data, cmd, param1, param2, index);

    // 3. 调用业务逻辑（加锁），传入栈上对象的引用/副本
    bool result = false;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller != nullptr && g_controller->ISolenoidValve != nullptr) {
            result = g_controller->ISolenoidValve->SetValveMap(vm);
        } else {
            OH_LOG_WARN(LOG_APP, "Controller or ISolenoidValve is null");
        }
    }

    // 4. 返回 boolean
    napi_value jsResult;
    napi_get_boolean(env, result, &jsResult);
    return jsResult;
}

static napi_value NapiCtrlSpinValve(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiCtrlSpinValve");

    // 1. 获取 JS 参数（@Sendable ValveMap 纯数据对象）
    size_t argc = 1;
    napi_value args[1];
    napi_status status = napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    if (status != napi_ok || argc < 1) {
        OH_LOG_ERROR(LOG_APP, "Invalid arguments: expected one ValveMap object");
        return nullptr;
    }

    // 2. ❌ 删除 napi_unwrap
    // ✅ 改为：从 JS 对象属性中提取字段，构造栈上 C++ ValveMap
    int32_t data = 0, cmd = 0, param1 = 0, param2 = 0, index = 0;

    auto readInt32Prop = [&](const char* propName, int32_t& out) {
        napi_value prop;
        if (napi_get_named_property(env, args[0], propName, &prop) == napi_ok) {
            napi_get_value_int32(env, prop, &out);
        }
    };

    readInt32Prop("data",   data);
    readInt32Prop("cmd",    cmd);
    readInt32Prop("param1", param1);
    readInt32Prop("param2", param2);
    readInt32Prop("index",  index);

    // ⚠️ 根据 ValveMap 实际构造方式调整
    ValveMap vm(data);
    vm.SetSpinValveCmd(cmd, param1, param2);
    // 如需设置 index: vm.SetIndex(index);

    OH_LOG_INFO(LOG_APP, "CtrlSpinValve parsed: data=%{public}d cmd=%{public}d p1=%{public}d p2=%{public}d idx=%{public}d",
                data, cmd, param1, param2, index);

    // 3. 调用业务逻辑（加锁），传入栈上对象
    bool result = false;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller != nullptr && g_controller->ISolenoidValve != nullptr) {
            result = g_controller->ISolenoidValve->CtrlSpinValve(vm);
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
    // 2. 定义方法描述符 NapiGetTotalPumps
    napi_property_descriptor descriptors[] = {
        {"valve_getTotalValves", nullptr, NapiGetTotalValves, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"valve_getValveMap", nullptr, NapiGetValveMap, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"valve_setValveMap", nullptr, NapiSetValveMap, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"valve_ctrlSpinValve", nullptr, NapiCtrlSpinValve, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"valve_setValve16", nullptr, NapiSetValve16, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"valve_setCheckLeakingPeriod", nullptr, NapiSetCheckLeakingPeriod, nullptr, nullptr, nullptr, napi_default, nullptr},
    };

    // 3. 将方法绑定到 valveObj
    napi_define_properties(
        env,
        exports,
        sizeof(descriptors) / sizeof(descriptors[0]),
        descriptors
    );
}