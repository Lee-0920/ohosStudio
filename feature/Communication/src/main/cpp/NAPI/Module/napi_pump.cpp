#include "napi_pump.h"
#include "hilog/log.h"
#undef LOG_DOMAIN
#undef LOG_TAG
#define LOG_DOMAIN 0x3200  // 全局domain宏，标识业务领域
#define LOG_TAG "MY_TAG"   // 全局tag宏，标识模块日志tag

bool JsObjectToMotionParam(napi_env env, napi_value jsObj, MotionParam& out) {
    // 获取 acceleration
    napi_value jsAccel;
    if (napi_get_named_property(env, jsObj, "acceleration", &jsAccel) != napi_ok) {
        return false;
    }
    double accel;
    if (napi_get_value_double(env, jsAccel, &accel) != napi_ok) {
        return false;
    }

    // 获取 speed
    napi_value jsSpeed;
    if (napi_get_named_property(env, jsObj, "speed", &jsSpeed) != napi_ok) {
        return false;
    }
    double speed;
    if (napi_get_value_double(env, jsSpeed, &speed) != napi_ok) {
        return false;
    }

    out.acceleration = static_cast<float>(accel);
    out.speed = static_cast<float>(speed);
    return true;
}

napi_value MotionParamToJsObject(napi_env env, const MotionParam& param) {
    napi_value obj;
    napi_create_object(env, &obj);

    napi_value jsAccel, jsSpeed;
    napi_create_double(env, param.acceleration, &jsAccel);
    napi_create_double(env, param.speed, &jsSpeed);

    napi_set_named_property(env, obj, "acceleration", jsAccel);
    napi_set_named_property(env, obj, "speed", jsSpeed);

    return obj;
}

static napi_value NapiGetTotalPumps(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiGetTotalPumps");

    int32_t index = 0;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller != nullptr && g_controller->IPeristalticPump != nullptr) {
            index = g_controller->IPeristalticPump->GetTotalPumps();
        }
    }
    napi_value result;
    napi_status status = napi_create_int32(env, index, &result);
    if (status != napi_ok) {
        // 错误处理（可选）
        return nullptr;
    }
    return result; // 直接返回对象，无需 undefined
}

static napi_value NapiGetPumpFactor(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiGetPumpFactor");
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    // 2. 参数数量校验
    if (argc < 1) {
        napi_throw_error(env, nullptr, "NapiGetPumpFactor requires 1 arguments: (index)");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }

    // 3. 解析 index (int32)
    int32_t index;
    if (napi_get_value_int32(env, args[0], &index) != napi_ok) {
        napi_throw_error(env, nullptr, "Argument 0 (index) must be an integer");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    double factor = 0;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller != nullptr && g_controller->IPeristalticPump != nullptr) {
            factor = g_controller->IPeristalticPump->GetPumpFactor(index);
        }
    }

    napi_value result;
    napi_status status = napi_create_double(env, factor, &result);
    if (status != napi_ok) {
        // 错误处理（可选）
        return nullptr;
    }
    return result; // 直接返回对象，无需 undefined
}

static napi_value NapiSetPumpFactor(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 2) {
        napi_throw_error(env, nullptr, "NapiSetPumpFactor Argument 2 arguments: index (number), factor (number)");
        return nullptr;
    }

    // 解析 index (int)
    int32_t index;
    napi_get_value_int32(env, args[0], &index);

    // 解析 factor (float)
    double factorDouble; // JS Number 是 double，需转换
    napi_get_value_double(env, args[1], &factorDouble);
    float factor = static_cast<float>(factorDouble);

    bool result = false; // 默认状态值
    std::lock_guard<std::mutex> lock(g_mutex);
    if (g_controller != nullptr && g_controller->IPeristalticPump != nullptr) {
        result = g_controller->IPeristalticPump->SetPumpFactor(index, factor);
    }

    // 5. 返回布尔值
    napi_value jsResult;
    napi_get_boolean(env, result, &jsResult);
    return jsResult;
}

static napi_value NapiGetPumpStatus(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 1) {
        napi_throw_error(env, nullptr, "Expected 1 argument: index (number)");
        return nullptr;
    }

    int32_t index;
    napi_get_value_int32(env, args[0], &index);

    // 调用实际逻辑
    PumpStatus status = PumpStatus::Idle;
    std::lock_guard<std::mutex> lock(g_mutex);
    if (g_controller != nullptr && g_controller->IPeristalticPump != nullptr) {
        status = g_controller->IPeristalticPump->GetPumpStatus(index);
    }

    // 将枚举转为整数并返回给 JS/TS
    napi_value result;
    napi_create_int32(env, static_cast<int32_t>(status), &result);
    return result;
}

static napi_value NapiGetMotionParam(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiGetMotionParam");
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    // 2. 参数数量校验
    if (argc < 1) {
        napi_throw_error(env, nullptr, "NapiGetMotionParam requires 1 arguments: (index)");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }

    // 3. 解析 index (int32)
    int32_t index;
    if (napi_get_value_int32(env, args[0], &index) != napi_ok) {
        napi_throw_error(env, nullptr, "Argument 0 (index) must be an integer");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    MotionParam currentParam{0.0f, 0.0f};
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller != nullptr && g_controller->IPeristalticPump != nullptr) {
            currentParam = g_controller->IPeristalticPump->GetMotionParam(index);
        }
    }

    // 转换为 JS 对象
    napi_value jsObj = MotionParamToJsObject(env, currentParam);
    return jsObj; // 直接返回对象，无需 undefined
}

static napi_value NapiSetMotionParam(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiSetMotionParam");

    // 1. 获取参数数量和参数数组
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    // 2. 参数数量校验
    if (argc < 2) {
        napi_throw_error(env, nullptr, "NapiSetMotionParam requires 2 arguments: (index, motionParam)");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }

    // 3. 解析 index (int32)
    int32_t index;
    if (napi_get_value_int32(env, args[0], &index) != napi_ok) {
        napi_throw_error(env, nullptr, "Argument 0 (index) must be an integer");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }

    MotionParam param;
    if (!JsObjectToMotionParam(env, args[1], param)) {
        napi_throw_error(env, nullptr, "Invalid motionParam object: must have 'acceleration' and 'speed' as numbers");
        return nullptr;
    }

    OH_LOG_INFO(LOG_APP, "NapiSetMotionParam %{public}d-%{public}f-%{public}f",index, param.acceleration, param.speed);

    // 7. 调用实际业务逻辑
    bool result = 0; // 默认状态值
    std::lock_guard<std::mutex> lock(g_mutex);
    if (g_controller != nullptr && g_controller->IPeristalticPump != nullptr) {
        result = g_controller->IPeristalticPump->SetMotionParam(index, param);
    } else {
        OH_LOG_WARN(LOG_APP, "Pump controller or IPeristalticPump is null, ignoring StartPump call");
    }

    // 5. 返回布尔值
    napi_value jsResult;
    napi_get_boolean(env, result, &jsResult);
    return jsResult;
}

static napi_value NapiStartPump(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiStartPump");

    // 1. 获取参数数量和参数数组
    size_t argc = 4;
    napi_value args[4];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    // 2. 参数数量校验
    if (argc < 4) {
        napi_throw_error(env, nullptr, "NapiStartPump requires 4 arguments: (index, dir, volume, seep)");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }

    // 3. 解析 index (int32)
    int32_t index;
    if (napi_get_value_int32(env, args[0], &index) != napi_ok) {
        napi_throw_error(env, nullptr, "Argument 0 (index) must be an integer");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }

    // 4. 解析 dir (int32, 对应 RollDirection)
    int32_t dirInt;
    if (napi_get_value_int32(env, args[1], &dirInt) != napi_ok) {
        napi_throw_error(env, nullptr, "Argument 1 (dir) must be an integer (RollDirection enum value)");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }

    // 可选：校验枚举范围（推荐）
    if (dirInt < 0 || dirInt > 2) {
        napi_throw_error(env, nullptr, "Invalid RollDirection value. Expected 0 (Suck), 1 (Drain), or 2 (Empty)");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    RollDirection dir = static_cast<RollDirection>(dirInt);

    // 5. 解析 volume (double -> float)
    double volumeDouble;
    if (napi_get_value_double(env, args[2], &volumeDouble) != napi_ok) {
        napi_throw_error(env, nullptr, "Argument 2 (volume) must be a number");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    float volume = static_cast<float>(volumeDouble);

    // 6. 解析 seep (double -> float)
    double seepDouble;
    if (napi_get_value_double(env, args[3], &seepDouble) != napi_ok) {
        napi_throw_error(env, nullptr, "Argument 3 (seep) must be a number");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    float seep = static_cast<float>(seepDouble);

    OH_LOG_INFO(LOG_APP, "NapiStartPump %{public}d-%{public}d-%{public}f-%{public}f",index, dir, volume, seep);

    // 7. 调用实际业务逻辑
    bool result = false; // 默认状态值
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller != nullptr && g_controller->IPeristalticPump != nullptr) {
            result = g_controller->IPeristalticPump->StartPump(index, dir, volume, seep);
        } else {
            OH_LOG_WARN(LOG_APP, "Pump controller or IPeristalticPump is null, ignoring StartPump call");
        }
    }
    
    // 5. 返回布尔值
    napi_value jsResult;
    napi_get_boolean(env, result, &jsResult);
    return jsResult;
}

static napi_value NapiStopPump(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiStopPump");
    // 1. 获取参数数量和参数数组
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    // 2. 参数数量校验
    if (argc < 1) {
        napi_throw_error(env, nullptr, "NapiStopPump requires 1 arguments: (index)");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    // 3. 解析 index (int32)
    int32_t index;
    if (napi_get_value_int32(env, args[0], &index) != napi_ok) {
        napi_throw_error(env, nullptr, "Argument 0 (index) must be an integer");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    bool result = false; // 默认状态值
    std::lock_guard<std::mutex> lock(g_mutex);
    if (g_controller != nullptr)
    {
        result = g_controller->IPeristalticPump->StopPump(index); // 安全调用
    }
    napi_value jsResult;
    napi_get_boolean(env, result, &jsResult);
    return jsResult;
}

static napi_value NapiGetPumpVolume(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 1) {
        napi_throw_error(env, nullptr, "Expected 1 argument: index (number)");
        return nullptr;
    }

    int32_t index;
    napi_status status = napi_get_value_int32(env, args[0], &index);
    if (status != napi_ok) {
        napi_throw_error(env, nullptr, "Failed to parse index as integer");
        return nullptr;
    }

    float volume = 0.0f; // 默认值

    {
        // 加锁并调用业务逻辑
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller != nullptr && g_controller->IPeristalticPump != nullptr) {
            volume = g_controller->IPeristalticPump->GetPumpVolume(static_cast<int>(index));
        }
        // 如果控制器未初始化，返回 0.0f（或可抛异常，按需选择）
    }

    // 将 float 转为 JS number（使用 double 精度）
    napi_value result;
    napi_create_double(env, static_cast<double>(volume), &result);
    return result;
}

static napi_value NapiExpectPumpResult(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiExpectPumpResult");
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 1) {
        napi_throw_error(env, nullptr, "Expected 1 argument: timeout (number)");
        return nullptr;
    }

    int64_t timeout; // JS number → int64_t（支持 long 范围）
    napi_status status = napi_get_value_int64(env, args[0], &timeout);
    if (status != napi_ok) {
        // 兜底：尝试从 double 转（兼容传入非整数）
        double dval;
        if (napi_get_value_double(env, args[0], &dval) == napi_ok) {
            timeout = static_cast<int64_t>(dval);
        } else {
            napi_throw_error(env, nullptr, "Timeout must be a number");
            return nullptr;
        }
    }

    PumpResult result = {0, 2}; // 默认错误

    try 
    {
//        std::lock_guard<std::mutex> lock(g_mutex); //等待事件过程中解锁,允许停止指令下发,否则停止指令无效
        if (g_controller != nullptr && g_controller->IPeristalticPump != nullptr) {
            result = g_controller->IPeristalticPump->ExpectPumpResult(static_cast<long>(timeout));
        }
        // 创建 JS 对象：{ index: ..., result: ... }
        napi_value jsObj;
        napi_create_object(env, &jsObj);
    
        // 设置 index (uint8_t → uint32)
        napi_value jsIndex;
        napi_create_uint32(env, static_cast<uint32_t>(result.index), &jsIndex);
        napi_set_named_property(env, jsObj, "index", jsIndex);
    
        // 设置 result (int → int32)
        napi_value jsResult;
        napi_create_int32(env, result.result, &jsResult);
        napi_set_named_property(env, jsObj, "result", jsResult);
    
        return jsObj;
    } catch (Communication::ExpectEventTimeoutException e) {

        char hexBuf[5]; // 4位十六进制 + '\0'
        snprintf(hexBuf, sizeof(hexBuf), "%04X", static_cast<unsigned int>(e.m_code));

        std::string msg = "Expect timeout: addr=" + e.m_addr.ToString() 
                    + ", code=0x" + hexBuf;
        OH_LOG_INFO(LOG_APP, "NapiExpectPumpResult %{public}s", msg.c_str());
        // 1. 创建 JS Error 的消息字符串
        napi_value jsMsg;
        napi_create_string_utf8(env, msg.c_str(), msg.length(), &jsMsg);
        
        // 2. 创建 JS Error 对象（第二个参数传 nullptr，稍后手动挂载标准 code）
        napi_value jsError;
        napi_create_error(env, nullptr, jsMsg, &jsError);
        
        // 3. 新增：挂载标准 Node-API 语义化错误码（供 JS 层 err.code 匹配）
        napi_value jsCodeStr;
        napi_create_string_utf8(env, "EXPECT_TIMEOUT", NAPI_AUTO_LENGTH, &jsCodeStr);
        napi_set_named_property(env, jsError, "code", jsCodeStr);
        
        // 4. 保留原有的自定义业务数字错误码
        napi_value jsErrorCode;
        napi_create_int32(env, e.m_code, &jsErrorCode);
        napi_set_named_property(env, jsError, "errorCode", jsErrorCode);
        
        // 5. 抛出异常并返回 nullptr
        napi_throw(env, jsError);
        return nullptr;
    } catch (const std::exception& e) {
        // 标准库异常
        napi_throw_error(env, "NATIVE_STD_ERROR", e.what());
        return nullptr;

    } catch (...) {
        // 未知异常兜底
        napi_throw_error(env, "NATIVE_UNKNOWN_ERROR", 
            "Unknown native exception in Expect");
        return nullptr;
    }
    
}

void RegisterPumpModule(napi_env env, napi_value exports) {
    // 2. 定义方法描述符 NapiGetTotalPumps
    napi_property_descriptor descriptors[] = {
        {"pump_getTotalPumps", nullptr, NapiGetTotalPumps, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"pump_getPumpFactor", nullptr, NapiGetPumpFactor, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"pump_setPumpFactor", nullptr, NapiSetPumpFactor, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"pump_getPumpStatus", nullptr, NapiGetPumpStatus, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"pump_getMotionParam", nullptr, NapiGetMotionParam, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"pump_setMotionParam", nullptr, NapiSetMotionParam, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"pump_startPump", nullptr, NapiStartPump, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"pump_stopPump", nullptr, NapiStopPump, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"pump_getPumpVolume", nullptr, NapiGetPumpVolume, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"pump_expectPumpResult", nullptr, NapiExpectPumpResult, nullptr, nullptr,(nullptr), napi_default,(nullptr)},
    };

    // 3. 将方法绑定到 pumpObj
    napi_define_properties(
        env,
        exports,
        sizeof(descriptors) / sizeof(descriptors[0]),
        descriptors
    );
}