#include "napi_meter.h"
#include "hilog/log.h"
#undef LOG_DOMAIN
#undef LOG_TAG
#define LOG_DOMAIN 0x3200  // 全局domain宏，标识业务领域
#define LOG_TAG "MY_TAG"   // 全局tag宏，标识模块日志tag

static napi_value NapiTurnOnLED(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiTurnOnLED");
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 1) {
        napi_throw_error(env, nullptr, "NapiTurnOnLED Argument 1 arguments: index (number)");
        return nullptr;
    }

    // 解析 num (Uint8)
    int32_t num;
    if (napi_get_value_int32(env, args[0], &num) != napi_ok) {
        napi_throw_error(env, nullptr, "Argument 'num' must be an integer number");
        return nullptr;
    }

    bool result = false;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller && g_controller->IOpticalMeter) {
            result = g_controller->IOpticalMeter->TurnOnLED(static_cast<uint8_t>(num));
        } else {
            OH_LOG_WARN(LOG_APP, "Controller or IOpticalMeter is null, TurnOnRays ignored");
        }
    }

    napi_value jsResult;
    napi_get_boolean(env, result, &jsResult);
    return jsResult;
}

static napi_value NapiTurnOffLED(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiTurnOffLED");
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 1) {
        napi_throw_error(env, nullptr, "NapiTurnOffLED requires 1 argument: num (number)");
        return nullptr;
    }

    // 解析 num (Uint8)
    int32_t num;
    if (napi_get_value_int32(env, args[0], &num) != napi_ok) {
        napi_throw_error(env, nullptr, "Argument 'num' must be an integer number");
        return nullptr;
    }

    bool result = false;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller && g_controller->IOpticalMeter) {
            result = g_controller->IOpticalMeter->TurnOffLED(static_cast<uint8_t>(num));
        } else {
            OH_LOG_WARN(LOG_APP, "Controller or IOpticalMeter is null, TurnOffLED ignored");
        }
    }

    napi_value jsResult;
    napi_get_boolean(env, result, &jsResult);
    return jsResult;
}

static napi_value NapiGetPumpFactor(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiGetPumpFactor");

    float factor = 0.0f;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller && g_controller->IOpticalMeter) {
            factor = g_controller->IOpticalMeter->GetPumpFactor();
        } else {
            OH_LOG_WARN(LOG_APP, "Controller or IOpticalMeter is null, returning default pump factor 0.0");
        }
    }

    napi_value jsFactor;
    napi_create_double(env, static_cast<double>(factor), &jsFactor);
    return jsFactor;
}

static napi_value NapiSetPumpFactor(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiSetPumpFactor");

    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 1) {
        napi_throw_error(env, nullptr, "NapiSetPumpFactor requires 1 argument: factor (number)");
        return nullptr;
    }

    // 解析 factor (float)
    double factorDbl;
    if (napi_get_value_double(env, args[0], &factorDbl) != napi_ok) {
        napi_throw_error(env, nullptr, "Argument 'factor' must be a number");
        return nullptr;
    }
    float factor = static_cast<float>(factorDbl);

    bool result = false;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller && g_controller->IOpticalMeter) {
            result = g_controller->IOpticalMeter->SetPumpFactor(factor);
        } else {
            OH_LOG_WARN(LOG_APP, "Controller or IOpticalMeter is null, SetPumpFactor ignored");
        }
    }

    napi_value jsResult;
    napi_get_boolean(env, result, &jsResult);
    return jsResult;
}

static napi_value NapiGetMeterPoints(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiGetMeterPoints");

    MeterPoints points;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller != nullptr && g_controller->IOpticalMeter != nullptr) {
            points = g_controller->IOpticalMeter->GetMeterPoints();
        }
    }

    // 在堆上创建副本（必须！）
    MeterPoints* heapPoints = new MeterPoints(points); // 拷贝构造到堆

    // 创建一个空的 JS 对象用于绑定
    napi_value jsMeterPoints;
    napi_status status = napi_create_object(env, &jsMeterPoints);
    if (status != napi_ok) {
        delete heapPoints;
        return nullptr;
    }

    // 将 C++ 对象绑定到 JS 对象
    status = napi_wrap(
        env,
        jsMeterPoints,
        heapPoints,
        [](napi_env env, void* native, void* hint) {
            delete static_cast<MeterPoints*>(native); // 析构堆对象
        },
        nullptr,  // finalize_hint
        nullptr   // ref
    );

    if (status != napi_ok) {
        delete heapPoints; // 绑定失败，手动释放
        return nullptr;
    }

    return jsMeterPoints;
}

static napi_value NapiSetMeterPoints(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiSetMeterPoints");

    size_t argc = 1;
    napi_value args[1];
    napi_value thisArg = nullptr;

    // 获取参数
    napi_status status = napi_get_cb_info(env, info, &argc, args, &thisArg, nullptr);
    if (status != napi_ok || argc < 1) {
        napi_throw_error(env, nullptr, "Expected 1 argument: MeterPoints object");
        return nullptr;
    }

    // 从 JS 对象中解包出 MeterPoints*
    MeterPoints* inputPoints = nullptr;
    status = napi_unwrap(env, args[0], reinterpret_cast<void**>(&inputPoints));
    if (status != napi_ok || inputPoints == nullptr) {
        napi_throw_error(env, nullptr, "Invalid MeterPoints object (not wrapped or null)");
        return nullptr;
    }

    bool result = false;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller != nullptr && g_controller->IOpticalMeter != nullptr) {
            result = g_controller->IOpticalMeter->SetMeterPoints(*inputPoints); // 传值拷贝
        }
    }

    // 返回布尔结果
    napi_value jsResult;
    napi_get_boolean(env, result, &jsResult);
    return jsResult;
}

static napi_value NapiGetMeterStatus(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiGetMeterStatus");

    uint16_t status = 0; // 默认值
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller != nullptr && g_controller->IOpticalMeter != nullptr) {
            status = g_controller->IOpticalMeter->GetMeterStatus();
        } else {
            OH_LOG_WARN(LOG_APP, "Controller or IMeterPoints is null, returning 0");
        }
    }

    // 转换为 JS number（JS 无 uint16，用 number 表示）
    napi_value jsStatus;
    napi_status nstatus = napi_create_uint32(env, static_cast<uint32_t>(status), &jsStatus);
    if (nstatus != napi_ok) {
        napi_throw_error(env, nullptr, "Failed to create JS number for meter status");
        return nullptr;
    }

    return jsStatus;
}

static napi_value NapiStartMeter(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiStartMeter");

    size_t argc = 4;
    napi_value args[4];
    napi_status status = napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    if (status != napi_ok || argc < 4) {
        napi_throw_error(env, nullptr, "Expected 4 arguments: dir (number), mode (number), volume (number), limitVolume (number)");
        return nullptr;
    }

    // 1. 解析 RollDirection (uint32)
    uint32_t dirValue = 0;
    if (napi_get_value_uint32(env, args[0], &dirValue) != napi_ok) {
        napi_throw_error(env, nullptr, "Argument 1 (dir) must be a non-negative integer");
        return nullptr;
    }

    // 2. 解析 MeterMode (uint32)
    uint32_t modeValue = 0;
    if (napi_get_value_uint32(env, args[1], &modeValue) != napi_ok) {
        napi_throw_error(env, nullptr, "Argument 2 (mode) must be a non-negative integer");
        return nullptr;
    }

    // 3. 解析 volume (float)
    double volDouble = 0.0;
    if (napi_get_value_double(env, args[2], &volDouble) != napi_ok) {
        napi_throw_error(env, nullptr, "Argument 3 (volume) must be a number");
        return nullptr;
    }

    // 4. 解析 limitVolume (float)
    double limitVolDouble = 0.0;
    if (napi_get_value_double(env, args[3], &limitVolDouble) != napi_ok) {
        napi_throw_error(env, nullptr, "Argument 4 (limitVolume) must be a number");
        return nullptr;
    }

    // 转换为 C++ 类型
    RollDirection dir = static_cast<RollDirection>(dirValue);
    MeterMode mode = static_cast<MeterMode>(modeValue);
    float volume = static_cast<float>(volDouble);
    float limitVolume = static_cast<float>(limitVolDouble);

    bool result = false;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller != nullptr && g_controller->IOpticalMeter != nullptr) {
            result = g_controller->IOpticalMeter->StartMeter(dir, mode, volume, limitVolume);
        } else {
            OH_LOG_WARN(LOG_APP, "g_controller or IOpticalMeter is null");
        }
    }

    // 返回布尔值
    napi_value jsResult;
    napi_get_boolean(env, result, &jsResult);
    return jsResult;
}

static napi_value NapiStopMeter(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiStopMeter");

    bool result = false;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller != nullptr && g_controller->IOpticalMeter != nullptr) {
            result = g_controller->IOpticalMeter->StopMeter();
        } else {
            OH_LOG_WARN(LOG_APP, "g_controller or IOpticalMeter is null, cannot stop meter");
        }
    }

    napi_value jsResult;
    napi_status status = napi_get_boolean(env, result, &jsResult);
    if (status != napi_ok) {
        napi_throw_error(env, nullptr, "Failed to create boolean return value");
        return nullptr;
    }

    return jsResult;
}

static napi_value NapiIsAutoCloseValve(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiIsAutoCloseValve");

    size_t argc = 1;
    napi_value args[1];
    napi_status status = napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    if (status != napi_ok || argc < 1) {
        napi_throw_error(env, nullptr, "Expected 1 argument: isCloseValve (boolean)");
        return nullptr;
    }

    // 解析布尔参数
    bool isCloseValve = false;
    status = napi_get_value_bool(env, args[0], &isCloseValve);
    if (status != napi_ok) {
        napi_throw_error(env, nullptr, "Argument must be a boolean");
        return nullptr;
    }

    bool result = false;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller != nullptr && g_controller->IOpticalMeter != nullptr) {
            result = g_controller->IOpticalMeter->IsAutoCloseValve(isCloseValve);
        } else {
            OH_LOG_WARN(LOG_APP, "g_controller or IOpticalMeter is null");
        }
    }

    napi_value jsResult;
    napi_get_boolean(env, result, &jsResult);
    return jsResult;
}

static napi_value NapiSetOpticalADNotifyPeriod(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiSetOpticalADNotifyPeriod");

    size_t argc = 1;
    napi_value args[1];
    napi_status status = napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    if (status != napi_ok || argc < 1) {
        napi_throw_error(env, nullptr, "Expected 1 argument: period (number)");
        return nullptr;
    }

    // 解析 period 参数（JS number → float）
    double periodDouble = 0.0;
    if (napi_get_value_double(env, args[0], &periodDouble) != napi_ok) {
        napi_throw_error(env, nullptr, "Argument 'period' must be a number");
        return nullptr;
    }

    float period = static_cast<float>(periodDouble);

    // 可选：增加合理性校验（例如 period > 0）
    if (period <= 0.0f) {
        OH_LOG_WARN(LOG_APP, "Invalid notify period: %f, must be > 0", period);
        // 根据需求决定是否允许 <=0（如 0 表示关闭通知）
        // 此处不强制拦截，交由底层处理
    }

    bool result = false;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller != nullptr && g_controller->IOpticalMeter != nullptr) {
            result = g_controller->IOpticalMeter->SetOpticalADNotifyPeriod(period);
        } else {
            OH_LOG_WARN(LOG_APP, "g_controller or IOpticalMeter is null");
        }
    }

    napi_value jsResult;
    napi_get_boolean(env, result, &jsResult);
    return jsResult;
}

static napi_value NapiExpectMeterResult(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 1) {
        napi_throw_error(env, nullptr, "Expected 1 argument: timeout (number)");
        return nullptr;
    }

    int32_t timeout; // JS number → int64_t（支持 long 范围）
    napi_status status = napi_get_value_int32(env, args[0], &timeout);
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

    MeterResult result = MeterResult::Failed; // 默认错误
    try
    {
//        std::lock_guard<std::mutex> lock(g_mutex); //等待事件过程中解锁,允许停止指令下发,否则停止指令无效
        if (g_controller != nullptr && g_controller->IOpticalMeter != nullptr) {
            result = g_controller->IOpticalMeter->ExpectMeterResult(static_cast<int>(timeout));
        }
        // 创建 JS 对象：{ index: ..., result: ... }
        napi_value jsObj;
        napi_create_object(env, &jsObj);
    
        // 设置 result (int → int32)
        napi_value jsResult;
        napi_create_int32(env, static_cast<int32_t>(result), &jsResult);
        napi_set_named_property(env, jsObj, "result", jsResult);
    
        return jsObj;
    } catch (Communication::ExpectEventTimeoutException e) {

        char hexBuf[5]; // 4位十六进制 + '\0'
        snprintf(hexBuf, sizeof(hexBuf), "%04X", static_cast<unsigned int>(e.m_code));

        std::string msg = "Expect timeout: addr=" + e.m_addr.ToString() 
                    + ", code=0x" + hexBuf;
        OH_LOG_INFO(LOG_APP, "NapiExpectMeterResult %{public}s", msg.c_str());
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

static napi_value NapiSetMeteSpeed(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiSetMeteSpeed");

    size_t argc = 1;
    napi_value args[1];
    napi_status status = napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    if (status != napi_ok || argc < 1) {
        napi_throw_error(env, nullptr, "Expected 1 argument: speed (number)");
        return nullptr;
    }

    // 解析 speed 参数（JS number → float）
    double speedDouble = 0.0;
    if (napi_get_value_double(env, args[0], &speedDouble) != napi_ok) {
        napi_throw_error(env, nullptr, "Argument 'speed' must be a number");
        return nullptr;
    }

    float speed = static_cast<float>(speedDouble);

    // 可选：增加合理性校验（例如 speed >= 0）
    if (speed < 0.0f) {
        OH_LOG_WARN(LOG_APP, "Invalid meter speed: %f, should be non-negative", speed);
        // 是否拒绝？此处交由底层处理，仅记录警告
    }

    bool result = false;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller != nullptr && g_controller->IOpticalMeter != nullptr) {
            result = g_controller->IOpticalMeter->SetMeteSpeed(speed);
        } else {
            OH_LOG_WARN(LOG_APP, "g_controller or IOpticalMeter is null");
        }
    }

    napi_value jsResult;
    napi_get_boolean(env, result, &jsResult);
    return jsResult;
}

static napi_value NapiGetMeteSpeed(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiGetMeteSpeed");

    float speed = 0.0f; // 默认值
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller != nullptr && g_controller->IOpticalMeter != nullptr) {
            speed = g_controller->IOpticalMeter->GetMeteSpeed();
        } else {
            OH_LOG_WARN(LOG_APP, "g_controller or IOpticalMeter is null, returning default speed 0.0");
        }
    }

    napi_value jsResult;
    napi_status status = napi_create_double(env, static_cast<double>(speed), &jsResult);
    if (status != napi_ok) {
        napi_throw_error(env, nullptr, "Failed to create return number");
        return nullptr;
    }

    return jsResult;
}

static napi_value NapiSetMeterFinishValveMap(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiSetMeterFinishValveMap");

    size_t argc = 1;
    napi_value args[1];
    napi_status status = napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    if (status != napi_ok || argc < 1) {
        napi_throw_error(env, nullptr, "Expected 1 argument: map (non-negative integer)");
        return nullptr;
    }

    // 尝试解析为整数（JS number → uint32_t）
    int64_t mapInt64 = 0;
    if (napi_get_value_int64(env, args[0], &mapInt64) != napi_ok) {
        // 如果不是整数，尝试从 double 转换（如 1.0）
        double mapDouble = 0.0;
        if (napi_get_value_double(env, args[0], &mapDouble) != napi_ok ||
            mapDouble < 0.0 || mapDouble > static_cast<double>(UINT32_MAX) ||
            mapDouble != std::floor(mapDouble)) {
            napi_throw_error(env, nullptr, "Argument 'map' must be a non-negative integer within [0, 2^32-1]");
            return nullptr;
        }
        mapInt64 = static_cast<int64_t>(mapDouble);
    }

    // 检查范围 [0, UINT32_MAX]
    if (mapInt64 < 0 || mapInt64 > static_cast<int64_t>(UINT32_MAX)) {
        napi_throw_error(env, nullptr, "Argument 'map' out of Uint32 range");
        return nullptr;
    }

    uint32_t map = static_cast<uint32_t>(mapInt64);

    bool result = false;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller != nullptr && g_controller->IOpticalMeter != nullptr) {
            result = g_controller->IOpticalMeter->SetMeterFinishValveMap(map);
        } else {
            OH_LOG_WARN(LOG_APP, "g_controller or IOpticalMeter is null");
        }
    }

    napi_value jsResult;
    napi_get_boolean(env, result, &jsResult);
    return jsResult;
}

static napi_value NapiGetSingleOpticalAD(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiGetSingleOpticalAD");

    size_t argc = 1;
    napi_value args[1];
    napi_status status = napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    if (status != napi_ok || argc < 1) {
        napi_throw_error(env, nullptr, "Expected 1 argument: num (integer in [0, 255])");
        return nullptr;
    }

    // 解析 num 参数（支持 number 或 bigint，但通常用 number）
    int64_t numInt64 = 0;
    if (napi_get_value_int64(env, args[0], &numInt64) != napi_ok) {
        double numDouble = 0.0;
        if (napi_get_value_double(env, args[0], &numDouble) != napi_ok ||
            numDouble < 0.0 || numDouble > 255.0 || numDouble != std::floor(numDouble)) {
            napi_throw_error(env, nullptr, "Argument 'num' must be an integer in range [0, 255]");
            return nullptr;
        }
        numInt64 = static_cast<int64_t>(numDouble);
    }

    if (numInt64 < 0 || numInt64 > 255) {
        napi_throw_error(env, nullptr, "Argument 'num' out of Uint8 range [0, 255]");
        return nullptr;
    }

    uint8_t num = static_cast<uint8_t>(numInt64);
    uint32_t adValue = 0;

    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller != nullptr && g_controller->IOpticalMeter != nullptr) {
            adValue = g_controller->IOpticalMeter->GetSingleOpticalAD(num);
        } else {
            OH_LOG_WARN(LOG_APP, "g_controller or IOpticalMeter is null, returning 0");
        }
    }

    // uint32_t 可安全转为 double（JS number 精确表示到 2^53）
    napi_value jsResult;
    napi_status createStatus = napi_create_uint32(env, adValue, &jsResult);
    if (createStatus != napi_ok) {
        // 回退到 double（极少见）
        napi_create_double(env, static_cast<double>(adValue), &jsResult);
    }

    return jsResult;
}

static napi_value NapiSetRopinessMeterOverValue(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiSetRopinessMeterOverValue");

    size_t argc = 1;
    napi_value args[1];
    napi_status status = napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    if (status != napi_ok || argc < 1) {
        napi_throw_error(env, nullptr, "Expected 1 argument: value (integer in [0, 65535])");
        return nullptr;
    }

    // 解析 value 参数
    int64_t valInt64 = 0;
    if (napi_get_value_int64(env, args[0], &valInt64) != napi_ok) {
        double valDouble = 0.0;
        if (napi_get_value_double(env, args[0], &valDouble) != napi_ok ||
            valDouble < 0.0 || valDouble > 65535.0 || valDouble != std::floor(valDouble)) {
            napi_throw_error(env, nullptr, "Argument 'value' must be an integer in range [0, 65535]");
            return nullptr;
        }
        valInt64 = static_cast<int64_t>(valDouble);
    }

    if (valInt64 < 0 || valInt64 > 65535) {
        napi_throw_error(env, nullptr, "Argument 'value' out of Uint16 range [0, 65535]");
        return nullptr;
    }

    uint16_t value = static_cast<uint16_t>(valInt64);
    bool result = false;

    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller != nullptr && g_controller->IOpticalMeter != nullptr) {
            result = g_controller->IOpticalMeter->SetRopinessMeterOverValue(value);
        } else {
            OH_LOG_WARN(LOG_APP, "g_controller or IOpticalMeter is null");
        }
    }

    napi_value jsResult;
    napi_get_boolean(env, result, &jsResult);
    return jsResult;
}

static napi_value NapiGetRopinessMeterOverValue(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiGetRopinessMeterOverValue");

    uint16_t value = 0; // 默认值
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller != nullptr && g_controller->IOpticalMeter != nullptr) {
            value = g_controller->IOpticalMeter->GetRopinessMeterOverValue();
        } else {
            OH_LOG_WARN(LOG_APP, "g_controller or IOpticalMeter is null, returning default 0");
        }
    }

    napi_value jsResult;
    napi_status status = napi_create_uint32(env, static_cast<uint32_t>(value), &jsResult);
    if (status != napi_ok) {
        // 极端情况下回退到 double
        napi_create_double(env, static_cast<double>(value), &jsResult);
    }

    return jsResult;
}

static napi_value NapiGetMeterEndPointOverCount(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiGetMeterEndPointOverCount");

    uint16_t count = 0;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller != nullptr && g_controller->IOpticalMeter != nullptr) {
            count = g_controller->IOpticalMeter->GetMeterEndPointOverCount();
        } else {
            OH_LOG_WARN(LOG_APP, "g_controller or IOpticalMeter is null, returning 0");
        }
    }

    napi_value jsResult;
    napi_status status = napi_create_uint32(env, static_cast<uint32_t>(count), &jsResult);
    if (status != napi_ok) {
        napi_create_double(env, static_cast<double>(count), &jsResult);
    }

    return jsResult;
}

static napi_value NapiSetMeterEndPointOverCount(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiSetMeterEndPointOverCount");

    size_t argc = 1;
    napi_value args[1];
    napi_status status = napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    if (status != napi_ok || argc < 1) {
        napi_throw_error(env, nullptr, "Expected 1 argument: cnt (integer in [0, 65535])");
        return nullptr;
    }

    // 解析 cnt 参数
    int64_t cntInt64 = 0;
    if (napi_get_value_int64(env, args[0], &cntInt64) != napi_ok) {
        double cntDouble = 0.0;
        if (napi_get_value_double(env, args[0], &cntDouble) != napi_ok ||
            cntDouble < 0.0 || cntDouble > 65535.0 || cntDouble != std::floor(cntDouble)) {
            napi_throw_error(env, nullptr, "Argument 'cnt' must be an integer in range [0, 65535]");
            return nullptr;
        }
        cntInt64 = static_cast<int64_t>(cntDouble);
    }

    if (cntInt64 < 0 || cntInt64 > 65535) {
        napi_throw_error(env, nullptr, "Argument 'cnt' out of Uint16 range [0, 65535]");
        return nullptr;
    }

    uint16_t cnt = static_cast<uint16_t>(cntInt64);
    bool result = false;

    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller != nullptr && g_controller->IOpticalMeter != nullptr) {
            result = g_controller->IOpticalMeter->SetMeterEndPointOverCount(cnt);
        } else {
            OH_LOG_WARN(LOG_APP, "g_controller or IOpticalMeter is null");
        }
    }

    napi_value jsResult;
    napi_get_boolean(env, result, &jsResult);
    return jsResult;
}

void RegisterMeterModule(napi_env env, napi_value exports) {
    // 2. 定义方法描述符 NapiGetTotalPumps
    napi_property_descriptor descriptors[] = {
        {"meter_turnOnLED", nullptr, NapiTurnOnLED, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"meter_turnOffLED", nullptr, NapiTurnOffLED, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"meter_getPumpFactor", nullptr, NapiGetPumpFactor, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"meter_setPumpFactor", nullptr, NapiSetPumpFactor, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"meter_getMeterPoints", nullptr, NapiGetMeterPoints, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"meter_setMeterPoints", nullptr, NapiSetMeterPoints, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"meter_getMeterStatus", nullptr, NapiGetMeterStatus, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"meter_startMeter", nullptr, NapiStartMeter, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"meter_stopMeter", nullptr, NapiStopMeter, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"meter_isAutoCloseValve", nullptr, NapiIsAutoCloseValve, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"meter_setOpticalADNotifyPeriod", nullptr, NapiSetOpticalADNotifyPeriod, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"meter_expectMeterResult", nullptr, NapiExpectMeterResult, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"meter_setMeteSpeed", nullptr, NapiSetMeteSpeed, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"meter_getMeteSpeed", nullptr, NapiGetMeteSpeed, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"meter_setMeterFinishValveMap", nullptr, NapiSetMeterFinishValveMap, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"meter_getSingleOpticalAD", nullptr, NapiGetSingleOpticalAD, nullptr, nullptr,(nullptr), napi_default,(nullptr)},
        {"meter_getMeterEndPointOverCount", nullptr, NapiGetMeterEndPointOverCount, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"meter_setMeterEndPointOverCount", nullptr, NapiSetMeterEndPointOverCount, nullptr, nullptr, nullptr, napi_default, nullptr},
    };
    // 3. 将方法绑定到 meterObj
    napi_define_properties(
        env,
        exports,
        sizeof(descriptors) / sizeof(descriptors[0]),
        descriptors
    );
}