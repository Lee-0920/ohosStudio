#include "napi_temp.h"
#include "hilog/log.h"
#undef LOG_DOMAIN
#undef LOG_TAG
#define LOG_DOMAIN 0x3200  // 全局domain宏，标识业务领域
#define LOG_TAG "MY_TAG"   // 全局tag宏，标识模块日志tag

bool JsObjectToTemperature(napi_env env, napi_value jsObj, Temperature& out) {
    // 解析 thermostatTemp
    napi_value jsThermostat;
    if (napi_get_named_property(env, jsObj, "thermostatTemp", &jsThermostat) != napi_ok) {
        OH_LOG_ERROR(LOG_APP, "Missing required property: thermostatTemp");
        return false;
    }
    double val;
    if (napi_get_value_double(env, jsThermostat, &val) != napi_ok) {
        OH_LOG_ERROR(LOG_APP, "thermostatTemp must be a number");
        return false;
    }
    out.thermostatTemp = static_cast<float>(val);

    // 解析 environmentTemp
    napi_value jsEnvironment;
    if (napi_get_named_property(env, jsObj, "environmentTemp", &jsEnvironment) != napi_ok) {
        OH_LOG_ERROR(LOG_APP, "Missing required property: environmentTemp");
        return false;
    }
    if (napi_get_value_double(env, jsEnvironment, &val) != napi_ok) {
        OH_LOG_ERROR(LOG_APP, "environmentTemp must be a number");
        return false;
    }
    out.environmentTemp = static_cast<float>(val);

    return true;
}

napi_value TemperatureToJsObject(napi_env env, const Temperature& temp) {
    napi_value obj;
    napi_create_object(env, &obj);

    napi_value jsThermostat, jsEnvironment;

    // 将 float 转为 double 创建 JS number
    napi_create_double(env, static_cast<double>(temp.thermostatTemp), &jsThermostat);
    napi_create_double(env, static_cast<double>(temp.environmentTemp), &jsEnvironment);

    // 设置属性
    napi_set_named_property(env, obj, "thermostatTemp", jsThermostat);
    napi_set_named_property(env, obj, "environmentTemp", jsEnvironment);

    return obj;
}

napi_value ThermostatParamToJsObject(napi_env env, const ThermostatParam& param) {
    napi_value obj;
    napi_create_object(env, &obj);

    napi_value jsProportion, jsIntegration, jsDifferential;

    // 将 float 转为 double 创建 JS number（JS 中所有数字都是 double）
    napi_create_double(env, static_cast<double>(param.proportion), &jsProportion);
    napi_create_double(env, static_cast<double>(param.integration), &jsIntegration);
    napi_create_double(env, static_cast<double>(param.differential), &jsDifferential);

    // 设置属性（属性名与结构体成员一致）
    napi_set_named_property(env, obj, "proportion", jsProportion);
    napi_set_named_property(env, obj, "integration", jsIntegration);
    napi_set_named_property(env, obj, "differential", jsDifferential);

    return obj;
}

bool JsObjectToThermostatParam(napi_env env, napi_value jsObj, ThermostatParam& out) {
    // 解析 proportion
    napi_value jsProp;
    if (napi_get_named_property(env, jsObj, "proportion", &jsProp) != napi_ok) {
        OH_LOG_ERROR(LOG_APP, "Missing required property: proportion");
        return false;
    }
    double val;
    if (napi_get_value_double(env, jsProp, &val) != napi_ok) {
        OH_LOG_ERROR(LOG_APP, "proportion must be a number");
        return false;
    }
    out.proportion = static_cast<float>(val);

    // 解析 integration
    napi_value jsInteg;
    if (napi_get_named_property(env, jsObj, "integration", &jsInteg) != napi_ok) {
        OH_LOG_ERROR(LOG_APP, "Missing required property: integration");
        return false;
    }
    if (napi_get_value_double(env, jsInteg, &val) != napi_ok) {
        OH_LOG_ERROR(LOG_APP, "integration must be a number");
        return false;
    }
    out.integration = static_cast<float>(val);

    // 解析 differential
    napi_value jsDiff;
    if (napi_get_named_property(env, jsObj, "differential", &jsDiff) != napi_ok) {
        OH_LOG_ERROR(LOG_APP, "Missing required property: differential");
        return false;
    }
    if (napi_get_value_double(env, jsDiff, &val) != napi_ok) {
        OH_LOG_ERROR(LOG_APP, "differential must be a number");
        return false;
    }
    out.differential = static_cast<float>(val);

    return true;
}

bool JsObjectToTempCalibrateFactor(napi_env env, napi_value jsObj, TempCalibrateFactor& out) {
    // 1. 获取 negativeInput
    napi_value jsNegativeInput;
    if (napi_get_named_property(env, jsObj, "negativeInput", &jsNegativeInput) != napi_ok) {
        OH_LOG_ERROR(LOG_APP, "Missing required property: negativeInput");
        return false;
    }
    double val;
    if (napi_get_value_double(env, jsNegativeInput, &val) != napi_ok) {
        OH_LOG_ERROR(LOG_APP, "negativeInput must be a number");
        return false;
    }
    out.negativeInput = static_cast<float>(val);

    // 2. 获取 referenceVoltage
    napi_value jsReferenceVoltage;
    if (napi_get_named_property(env, jsObj, "referenceVoltage", &jsReferenceVoltage) != napi_ok) {
        OH_LOG_ERROR(LOG_APP, "Missing required property: referenceVoltage");
        return false;
    }
    if (napi_get_value_double(env, jsReferenceVoltage, &val) != napi_ok) {
        OH_LOG_ERROR(LOG_APP, "referenceVoltage must be a number");
        return false;
    }
    out.referenceVoltage = static_cast<float>(val);

    // 3. 获取 calibrationVoltage
    napi_value jsCalibrationVoltage;
    if (napi_get_named_property(env, jsObj, "calibrationVoltage", &jsCalibrationVoltage) != napi_ok) {
        OH_LOG_ERROR(LOG_APP, "Missing required property: calibrationVoltage");
        return false;
    }
    if (napi_get_value_double(env, jsCalibrationVoltage, &val) != napi_ok) {
        OH_LOG_ERROR(LOG_APP, "calibrationVoltage must be a number");
        return false;
    }
    out.calibrationVoltage = static_cast<float>(val);

    return true;
}

napi_value TempCalibrateFactorToJsObject(napi_env env, const TempCalibrateFactor& factor) {
    napi_value obj;
    napi_create_object(env, &obj);

    napi_value jsNegativeInput, jsReferenceVoltage, jsCalibrationVoltage;

    // 创建 JS number 值（double 精度）
    napi_create_double(env, static_cast<double>(factor.negativeInput), &jsNegativeInput);
    napi_create_double(env, static_cast<double>(factor.referenceVoltage), &jsReferenceVoltage);
    napi_create_double(env, static_cast<double>(factor.calibrationVoltage), &jsCalibrationVoltage);

    // 设置属性
    napi_set_named_property(env, obj, "negativeInput", jsNegativeInput);
    napi_set_named_property(env, obj, "referenceVoltage", jsReferenceVoltage);
    napi_set_named_property(env, obj, "calibrationVoltage", jsCalibrationVoltage);

    return obj;
}

static napi_value NapiGetCalibrateFactor(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiGetCalibrateFactor");

    // 1. 调用底层获取数据（线程安全）
    TempCalibrateFactor factor{0.0f, 0.0f, 0.0f}; // 默认初始化
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller != nullptr && g_controller->ITemperatureControl != nullptr) {
            factor = g_controller->ITemperatureControl->GetCalibrateFactor();
        } else {
            OH_LOG_WARN(LOG_APP, "Controller or ITemperature is null, returning default factor");
        }
    }

    // 5. 转换为 JS 对象并返回
    napi_value jsObj = TempCalibrateFactorToJsObject(env, factor);
    return jsObj;
}

static napi_value NapiSetCalibrateFactor(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiSetCalibrateFactor");

    // 1. 获取参数（预期2个：index, calibrateFactor）
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    // 2. 参数数量校验
    if (argc < 1) {
        napi_throw_error(env, nullptr, "NapiSetCalibrateFactor requires 1 arguments: (calibrateFactor)");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }

    // 4. 解析 JS 对象为 TempCalibrateFactor
    TempCalibrateFactor factor;
    if (!JsObjectToTempCalibrateFactor(env, args[0], factor)) {
        napi_throw_error(env, nullptr,
            "Invalid calibrateFactor object: must have 'negativeInput', 'referenceVoltage', and 'calibrationVoltage' as numbers");
        return nullptr;
    }

    // 5. 打印日志（注意：float 需转为 double 供 %{public}f 使用）
    OH_LOG_INFO(LOG_APP,
        "NapiSetCalibrateFactor index=%{public}d, negativeInput=%{public}f, referenceVoltage=%{public}f, calibrationVoltage=%{public}f",
        index,
        static_cast<double>(factor.negativeInput),
        static_cast<double>(factor.referenceVoltage),
        static_cast<double>(factor.calibrationVoltage)
    );

    // 6. 调用底层业务逻辑（加锁）
    bool result = false;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller != nullptr && g_controller->ITemperatureControl != nullptr) {
            result = g_controller->ITemperatureControl->SetCalibrateFactor(factor);
        } else {
            OH_LOG_WARN(LOG_APP, "Controller or ITemperature is null, ignoring SetCalibrateFactor call");
        }
    }

    napi_value jsResult;
    napi_get_boolean(env, result, &jsResult);
    return jsResult;
}

static napi_value NapiGetTemperature(napi_env env, napi_callback_info info) {
    Temperature temp{0.0f, 0.0f};
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller && g_controller->ITemperatureControl) {
            temp = g_controller->ITemperatureControl->GetTemperature();
        }
    }
    return TemperatureToJsObject(env, temp);
}

static napi_value NapiGetThermostatParam(napi_env env, napi_callback_info info) {
    ThermostatParam param{0.0f, 0.0f, 0.0f};
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller && g_controller->ITemperatureControl) {
            param = g_controller->ITemperatureControl->GetThermostatParam();
        }
    }
    return ThermostatParamToJsObject(env, param);
}

static napi_value NapiSetThermostatParam(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 1) {
        napi_throw_error(env, nullptr, "Expected 1 argument: thermostatParam object");
        return nullptr;
    }

    ThermostatParam param;
    if (!JsObjectToThermostatParam(env, args[0], param)) {
        napi_throw_error(env, nullptr,
            "Invalid thermostatParam: must have 'proportion', 'integration', and 'differential' as numbers");
        return nullptr;
    }
    bool result = false;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller && g_controller->ITemperatureControl) {
            result = g_controller->ITemperatureControl->SetThermostatParam(param);
        }
    }

    // 8. 返回布尔值
    napi_value jsResult;
    napi_get_boolean(env, result, &jsResult);
    return jsResult;
}

static napi_value NapiGetThermostatStatus(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiGetThermostatStatus");

    uint16_t status = 0; // 默认状态值

    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller && g_controller->ITemperatureControl) {
            status = g_controller->ITemperatureControl->GetThermostatStatus();
        } else {
            OH_LOG_WARN(LOG_APP, "Controller or ITemperatureControl is null, returning default status 0");
        }
    }

    // 将 uint16_t 转为 JS number
    napi_value jsStatus;
    napi_create_uint32(env, static_cast<uint32_t>(status), &jsStatus);
    return jsStatus;
}

static napi_value NapiStartThermostat(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiStartThermostat");

    // 1. 获取参数（预期4个）
    size_t argc = 4;
    napi_value args[4];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    // 2. 参数数量校验
    if (argc < 4) {
        napi_throw_error(env, nullptr, "StartThermostat requires 4 arguments: (mode, targetTemp, toleranceTemp, timeout)");
        return nullptr;
    }

    // 3. 解析 mode (int32 -> ThermostatMode)
    int32_t modeInt;
    if (napi_get_value_int32(env, args[0], &modeInt) != napi_ok) {
        napi_throw_error(env, nullptr, "Argument 0 (mode) must be an integer");
        return nullptr;
    }
    ThermostatMode mode = static_cast<ThermostatMode>(modeInt);

    // 4. 解析 targetTemp (float)
    double targetTempDbl;
    if (napi_get_value_double(env, args[1], &targetTempDbl) != napi_ok) {
        napi_throw_error(env, nullptr, "Argument 1 (targetTemp) must be a number");
        return nullptr;
    }
    float targetTemp = static_cast<float>(targetTempDbl);

    // 5. 解析 toleranceTemp (float)
    double toleranceTempDbl;
    if (napi_get_value_double(env, args[2], &toleranceTempDbl) != napi_ok) {
        napi_throw_error(env, nullptr, "Argument 2 (toleranceTemp) must be a number");
        return nullptr;
    }
    float toleranceTemp = static_cast<float>(toleranceTempDbl);

    // 6. 解析 timeout (float)
    double timeoutDbl;
    if (napi_get_value_double(env, args[3], &timeoutDbl) != napi_ok) {
        napi_throw_error(env, nullptr, "Argument 3 (timeout) must be a number");
        return nullptr;
    }
    float timeout = static_cast<float>(timeoutDbl);

    // 7. 调用底层逻辑（加锁）
    bool result = false;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller && g_controller->ITemperatureControl) {
            result = g_controller->ITemperatureControl->StartThermostat(
                mode, targetTemp, toleranceTemp, timeout
            );
        } else {
            OH_LOG_WARN(LOG_APP, "Controller or ITemperatureControl is null, StartThermostat ignored");
        }
    }

    // 8. 返回布尔值
    napi_value jsResult;
    napi_get_boolean(env, result, &jsResult);
    return jsResult;
}

static napi_value NapiStopThermostat(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiStopThermostat");

    bool result = false;

    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller && g_controller->ITemperatureControl) {
            result = g_controller->ITemperatureControl->StopThermostat();
        } else {
            OH_LOG_WARN(LOG_APP, "Controller or ITemperatureControl is null, StopThermostat ignored");
        }
    }

    napi_value jsResult;
    napi_get_boolean(env, result, &jsResult);
    return jsResult;
}

static napi_value NapiSetTemperatureNotifyPeriod(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiSetTemperatureNotifyPeriod");

    // 1. 获取参数（预期1个）
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    // 2. 参数数量校验
    if (argc < 1) {
        napi_throw_error(env, nullptr, "SetTemperatureNotifyPeriod requires 1 argument: period (number)");
        return nullptr;
    }

    // 3. 解析 period (number -> float)
    double periodDbl;
    if (napi_get_value_double(env, args[0], &periodDbl) != napi_ok) {
        napi_throw_error(env, nullptr, "Argument 'period' must be a number");
        return nullptr;
    }
    float period = static_cast<float>(periodDbl);

    // 4. 调用底层逻辑（加锁）
    bool result = false;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller && g_controller->ITemperatureControl) {
            result = g_controller->ITemperatureControl->SetTemperatureNotifyPeriod(period);
        } else {
            OH_LOG_WARN(LOG_APP, "Controller or ITemperatureControl is null, SetTemperatureNotifyPeriod ignored");
        }
    }

    // 5. 返回布尔值
    napi_value jsResult;
    napi_get_boolean(env, result, &jsResult);
    return jsResult;
}

static napi_value NapiExpectThermostat(napi_env env, napi_callback_info info) {
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

    ThermostatResult result = {0, 0, 0}; // 默认错误
    try
    {
//        std::lock_guard<std::mutex> lock(g_mutex);//等待事件过程中解锁,允许停止指令下发,否则停止指令无效
        if (g_controller != nullptr && g_controller->IPeristalticPump != nullptr) {
            result = g_controller->ITemperatureControl->ExpectThermostat(static_cast<long>(timeout));
        }
         // 创建 JS 对象：{ index: ..., result: ... }
        napi_value jsObj;
        napi_create_object(env, &jsObj);
        
        // 设置 result (int → int32)
        napi_value jsResult;
        napi_create_int32(env, result.result, &jsResult);
        napi_set_named_property(env, jsObj, "result", jsResult);
        
        // 设置 temp (float → int32)
        napi_value jsTemp;
        napi_create_double(env, result.temp, &jsTemp);
        napi_set_named_property(env, jsObj, "temp", jsTemp);
    
        // 设置 index (uint8_t → uint32)
        napi_value jsIndex;
        napi_create_uint32(env, static_cast<uint32_t>(result.index), &jsIndex);
        napi_set_named_property(env, jsObj, "index", jsIndex);
    
        return jsObj;
    } catch (Communication::ExpectEventTimeoutException e) {

        char hexBuf[5]; // 4位十六进制 + '\0'
        snprintf(hexBuf, sizeof(hexBuf), "%04X", static_cast<unsigned int>(e.m_code));

        std::string msg = "Expect timeout: addr=" + e.m_addr.ToString() 
                    + ", code=0x" + hexBuf;
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

static napi_value NapiBoxFanSetOutput(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiBoxFanSetOutput");

    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 1) {
        napi_throw_error(env, nullptr, "BoxFanSetOutput requires 1 argument: level (number)");
        return nullptr;
    }

    double levelDbl;
    if (napi_get_value_double(env, args[0], &levelDbl) != napi_ok) {
        napi_throw_error(env, nullptr, "Argument 'level' must be a number");
        return nullptr;
    }
    float level = static_cast<float>(levelDbl);

    bool result = false;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller && g_controller->ITemperatureControl) { // 假设风扇控制接口为 IFanControl
            result = g_controller->ITemperatureControl->BoxFanSetOutput(level);
        } else {
            OH_LOG_WARN(LOG_APP, "Controller or IFanControl is null, BoxFanSetOutput ignored");
        }
    }

    napi_value jsResult;
    napi_get_boolean(env, result, &jsResult);
    return jsResult;
}

static napi_value NapiDigestionFanSetOutput(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiDigestionFanSetOutput");

    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 1) {
        napi_throw_error(env, nullptr, "DigestionFanSetOutput requires 1 argument: level (number)");
        return nullptr;
    }

    double levelDbl;
    if (napi_get_value_double(env, args[0], &levelDbl) != napi_ok) {
        napi_throw_error(env, nullptr, "Argument 'level' must be a number");
        return nullptr;
    }
    float level = static_cast<float>(levelDbl);

    bool result = false;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller && g_controller->ITemperatureControl) {
            result = g_controller->ITemperatureControl->DigestionFanSetOutput(level);
        } else {
            OH_LOG_WARN(LOG_APP, "Controller or IFanControl is null, DigestionFanSetOutput ignored");
        }
    }

    napi_value jsResult;
    napi_get_boolean(env, result, &jsResult);
    return jsResult;
}

static napi_value NapiGetHeaterMaxDutyCycle(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiGetHeaterMaxDutyCycle");

    float maxDutyCycle = 0.0f;

    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller && g_controller->ITemperatureControl) { // 假设加热控制接口为 IHeaterControl
            maxDutyCycle = g_controller->ITemperatureControl->GetHeaterMaxDutyCycle();
        } else {
            OH_LOG_WARN(LOG_APP, "Controller or IHeaterControl is null, returning default 0.0f");
        }
    }

    napi_value jsResult;
    napi_create_double(env, static_cast<double>(maxDutyCycle), &jsResult);
    return jsResult;
}

static napi_value NapiSetHeaterMaxDutyCycle(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiSetHeaterMaxDutyCycle");

    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 1) {
        napi_throw_error(env, nullptr, "SetHeaterMaxDutyCycle requires 1 argument: maxDutyCycle (number)");
        return nullptr;
    }

    double maxDutyCycleDbl;
    if (napi_get_value_double(env, args[0], &maxDutyCycleDbl) != napi_ok) {
        napi_throw_error(env, nullptr, "Argument 'maxDutyCycle' must be a number");
        return nullptr;
    }
    float maxDutyCycle = static_cast<float>(maxDutyCycleDbl);

    bool result = false;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller && g_controller->ITemperatureControl) {
            result = g_controller->ITemperatureControl->SetHeaterMaxDutyCycle(maxDutyCycle);
        } else {
            OH_LOG_WARN(LOG_APP, "Controller or IHeaterControl is null, SetHeaterMaxDutyCycle ignored");
        }
    }

    napi_value jsResult;
    napi_get_boolean(env, result, &jsResult);
    return jsResult;
}

static napi_value NapiGetCurrentThermostatParam(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiGetCurrentThermostatParam");

    ThermostatParam param{0.0f, 0.0f, 0.0f};

    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller && g_controller->ITemperatureControl) {
            param = g_controller->ITemperatureControl->GetCurrentThermostatParam();
        } else {
            OH_LOG_WARN(LOG_APP, "Controller or ITemperatureControl is null, returning default ThermostatParam");
        }
    }

    return ThermostatParamToJsObject(env, param);
}

static napi_value NapiSetCurrentThermostatParam(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiSetCurrentThermostatParam");

    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 1) {
        napi_throw_error(env, nullptr, "Expected 1 argument: thermostatParam object");
        return nullptr;
    }

    ThermostatParam param;
    if (!JsObjectToThermostatParam(env, args[0], param)) {
        napi_throw_error(env, nullptr,
            "Invalid thermostatParam: must have 'proportion', 'integration', and 'differential' as numbers");
        return nullptr;
    }

    bool result = false;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller && g_controller->ITemperatureControl) {
            result = g_controller->ITemperatureControl->SetCurrentThermostatParam(param);
        } else {
            OH_LOG_WARN(LOG_APP, "Controller or ITemperatureControl is null, SetCurrentThermostatParam ignored");
        }
    }

    napi_value jsResult;
    napi_get_boolean(env, result, &jsResult);
    return jsResult;
}

static napi_value NapiTurnOnRays(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiTurnOnRays");

    bool result = false;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller && g_controller->ITemperatureControl) {
            result = g_controller->ITemperatureControl->TurnOnRays();
        } else {
            OH_LOG_WARN(LOG_APP, "Controller or ILightControl is null, TurnOnRays ignored");
        }
    }

    napi_value jsResult;
    napi_get_boolean(env, result, &jsResult);
    return jsResult;
}

static napi_value NapiTurnOffRays(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiTurnOffRays");

    bool result = false;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller && g_controller->ITemperatureControl) {
            result = g_controller->ITemperatureControl->TurnOffRays();
        } else {
            OH_LOG_WARN(LOG_APP, "Controller or ILightControl is null, TurnOffRays ignored");
        }
    }

    napi_value jsResult;
    napi_get_boolean(env, result, &jsResult);
    return jsResult;
}

static napi_value NapiBoxFanSetMode(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiBoxFanSetMode");

    size_t argc = 3;
    napi_value args[3];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 3) {
        napi_throw_error(env, nullptr, "Expected 3 arguments: index (number), mode (number), temp (number)");
        return nullptr;
    }

    // 解析 index (Uint8)
    double indexDbl;
    if (napi_get_value_double(env, args[0], &indexDbl) != napi_ok) {
        napi_throw_error(env, nullptr, "Argument 'index' must be a number");
        return nullptr;
    }
    uint8_t index = static_cast<uint8_t>(indexDbl);

    // 解析 mode (Uint8)
    double modeDbl;
    if (napi_get_value_double(env, args[1], &modeDbl) != napi_ok) {
        napi_throw_error(env, nullptr, "Argument 'mode' must be a number");
        return nullptr;
    }
    uint8_t mode = static_cast<uint8_t>(modeDbl);

    // 解析 temp (float)
    double tempDbl;
    if (napi_get_value_double(env, args[2], &tempDbl) != napi_ok) {
        napi_throw_error(env, nullptr, "Argument 'temp' must be a number");
        return nullptr;
    }
    float temp = static_cast<float>(tempDbl);

    bool result = false;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller && g_controller->ITemperatureControl) {
            result = g_controller->ITemperatureControl->BoxFanSetMode(index, mode, temp);
        } else {
            OH_LOG_WARN(LOG_APP, "Controller or IFanControl is null, BoxFanSetMode ignored");
        }
    }

    napi_value jsResult;
    napi_get_boolean(env, result, &jsResult);
    return jsResult;
}

void RegisterTempModule(napi_env env, napi_value exports) {
    // 2. 定义方法描述符 
    napi_property_descriptor descriptors[] = {
        {"temp_getCalibrateFactor", nullptr, NapiGetCalibrateFactor, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"temp_setCalibrateFactor", nullptr, NapiSetCalibrateFactor, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"temp_getTemperature", nullptr, NapiGetTemperature, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"temp_getThermostatParam", nullptr, NapiGetThermostatParam, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"temp_setThermostatParam", nullptr, NapiSetThermostatParam, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"temp_getThermostatStatus", nullptr, NapiGetThermostatStatus, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"temp_startThermostat", nullptr, NapiStartThermostat, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"temp_stopThermostat", nullptr, NapiStopThermostat, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"temp_setTemperatureNotifyPeriod", nullptr, NapiSetTemperatureNotifyPeriod, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"temp_expectThermostat", nullptr, NapiExpectThermostat, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"temp_boxFanSetOutput", nullptr, NapiBoxFanSetOutput, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"temp_digestionFanSetOutput", nullptr, NapiDigestionFanSetOutput, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"temp_getHeaterMaxDutyCycle", nullptr, NapiGetHeaterMaxDutyCycle, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"temp_setHeaterMaxDutyCycle", nullptr, NapiSetHeaterMaxDutyCycle, nullptr, nullptr,(nullptr), napi_default,(nullptr)},
        {"temp_turnOnRays", nullptr, NapiTurnOnRays, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"temp_turnOffRays", nullptr, NapiTurnOffRays, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"temp_boxFanSetMode", nullptr, NapiBoxFanSetMode, nullptr, nullptr, nullptr, napi_default, nullptr},
    };

    // 3. 将方法绑定到 tempObj
    napi_define_properties(
        env,
        exports,
        sizeof(descriptors) / sizeof(descriptors[0]),
        descriptors
    );
}