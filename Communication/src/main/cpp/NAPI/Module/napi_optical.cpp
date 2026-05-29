#include "napi_optical.h"
#include "hilog/log.h"
#undef LOG_DOMAIN
#undef LOG_TAG
#define LOG_DOMAIN 0x3200  // 全局domain宏，标识业务领域
#define LOG_TAG "MY_TAG"   // 全局tag宏，标识模块日志tag

napi_value LedParamToJsObject(napi_env env, const LedParam& ledParam) {
    napi_value obj;
    napi_create_object(env, &obj);

    napi_value jsProportion, jsIntegration, jsDifferential;

    // 将 float 转为 double 创建 JS number
    napi_create_double(env, static_cast<double>(ledParam.proportion), &jsProportion);
    napi_create_double(env, static_cast<double>(ledParam.integration), &jsIntegration);
    napi_create_double(env, static_cast<double>(ledParam.differential), &jsDifferential);

    // 设置属性
    napi_set_named_property(env, obj, "proportion", jsProportion);
    napi_set_named_property(env, obj, "integration", jsIntegration);
    napi_set_named_property(env, obj, "differential", jsDifferential);

    return obj;
}

bool JsObjectToLedParam(napi_env env, napi_value jsObj, LedParam& out) {
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

napi_value RefADParamToJsObject(napi_env env, const RefADParam& param) {
    napi_value obj;
    napi_create_object(env, &obj);

    napi_value jsTarget, jsTolorance, jsTimeout;

    // Uint32 可直接用 napi_create_uint32
    napi_create_uint32(env, param.target, &jsTarget);
    napi_create_uint32(env, param.tolorance, &jsTolorance);
    napi_create_uint32(env, param.timeout, &jsTimeout);

    napi_set_named_property(env, obj, "target", jsTarget);
    napi_set_named_property(env, obj, "tolorance", jsTolorance);  // 按结构体原名
    napi_set_named_property(env, obj, "timeout", jsTimeout);

    return obj;
}

bool JsObjectToRefADParam(napi_env env, napi_value jsObj, RefADParam& out) {
    // 解析 target
    napi_value jsTarget;
    if (napi_get_named_property(env, jsObj, "target", &jsTarget) != napi_ok) {
        OH_LOG_ERROR(LOG_APP, "Missing required property: target");
        return false;
    }
    uint32_t val;
    if (napi_get_value_uint32(env, jsTarget, &val) != napi_ok) {
        OH_LOG_ERROR(LOG_APP, "target must be a non-negative integer (Uint32)");
        return false;
    }
    out.target = val;

    // 解析 tolorance
    napi_value jsTolorance;
    if (napi_get_named_property(env, jsObj, "tolorance", &jsTolorance) != napi_ok) {
        OH_LOG_ERROR(LOG_APP, "Missing required property: tolorance");
        return false;
    }
    if (napi_get_value_uint32(env, jsTolorance, &val) != napi_ok) {
        OH_LOG_ERROR(LOG_APP, "tolorance must be a non-negative integer (Uint32)");
        return false;
    }
    out.tolorance = val;

    // 解析 timeout
    napi_value jsTimeout;
    if (napi_get_named_property(env, jsObj, "timeout", &jsTimeout) != napi_ok) {
        OH_LOG_ERROR(LOG_APP, "Missing required property: timeout");
        return false;
    }
    if (napi_get_value_uint32(env, jsTimeout, &val) != napi_ok) {
        OH_LOG_ERROR(LOG_APP, "timeout must be a non-negative integer (Uint32)");
        return false;
    }
    out.timeout = val;

    return true;
}

napi_value AcquiredResultToJsObject(napi_env env, const AcquiredResult& res) {
    napi_value obj;
    napi_create_object(env, &obj);

    // 构建 ad 子对象
    napi_value jsAdObj;
    napi_create_object(env, &jsAdObj);

    napi_value jsRef, jsMeas;
    napi_create_uint32(env, res.ad.reference, &jsRef);
    napi_create_uint32(env, res.ad.measure, &jsMeas);

    napi_set_named_property(env, jsAdObj, "reference", jsRef);
    napi_set_named_property(env, jsAdObj, "measure", jsMeas);

    // 设置顶层属性
    napi_set_named_property(env, obj, "ad", jsAdObj);

    napi_value jsResult;
    napi_create_int32(env, res.result, &jsResult);
    napi_set_named_property(env, obj, "result", jsResult);

    return obj;
}

bool JsObjectToAcquiredResult(napi_env env, napi_value jsObj, AcquiredResult& out) {
    // 解析 ad 子对象
    napi_value jsAdObj;
    if (napi_get_named_property(env, jsObj, "ad", &jsAdObj) != napi_ok) {
        OH_LOG_ERROR(LOG_APP, "Missing required property: ad");
        return false;
    }

    // 解析 ad.reference
    napi_value jsRef;
    if (napi_get_named_property(env, jsAdObj, "reference", &jsRef) != napi_ok) {
        OH_LOG_ERROR(LOG_APP, "Missing required property: ad.reference");
        return false;
    }
    uint32_t uval;
    if (napi_get_value_uint32(env, jsRef, &uval) != napi_ok) {
        OH_LOG_ERROR(LOG_APP, "ad.reference must be a non-negative integer (Uint32)");
        return false;
    }
    out.ad.reference = uval;

    // 解析 ad.measure
    napi_value jsMeas;
    if (napi_get_named_property(env, jsAdObj, "measure", &jsMeas) != napi_ok) {
        OH_LOG_ERROR(LOG_APP, "Missing required property: ad.measure");
        return false;
    }
    if (napi_get_value_uint32(env, jsMeas, &uval) != napi_ok) {
        OH_LOG_ERROR(LOG_APP, "ad.measure must be a non-negative integer (Uint32)");
        return false;
    }
    out.ad.measure = uval;

    // 解析 result
    napi_value jsResult;
    if (napi_get_named_property(env, jsObj, "result", &jsResult) != napi_ok) {
        OH_LOG_ERROR(LOG_APP, "Missing required property: result");
        return false;
    }
    int32_t ival;
    if (napi_get_value_int32(env, jsResult, &ival) != napi_ok) {
        OH_LOG_ERROR(LOG_APP, "result must be an integer");
        return false;
    }
    out.result = static_cast<int>(ival);

    return true;
}

static napi_value NapiTurnOnLED(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiTurnOnLED (no-arg version)");

    // 不需要任何参数
    size_t argc = 0;
    napi_get_cb_info(env, info, &argc, nullptr, nullptr, nullptr);

    bool result = false;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller && g_controller->IOpticalAcquire) {
            result = g_controller->IOpticalAcquire->TurnOnLED();
        } else {
            OH_LOG_WARN(LOG_APP, "Controller or IOpticalAcquire is null, TurnOnLED ignored");
        }
    }

    napi_value jsResult;
    napi_get_boolean(env, result, &jsResult);
    return jsResult;
}

static napi_value NapiSetAcquireADNotifyPeriod(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiSetAcquireADNotifyPeriod");

    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 1) {
        napi_throw_error(env, nullptr, "NapiSetAcquireADNotifyPeriod requires 1 argument: period (number)");
        return nullptr;
    }

    // 解析 period (float)
    double periodDouble;
    if (napi_get_value_double(env, args[0], &periodDouble) != napi_ok) {
        napi_throw_error(env, nullptr, "Argument 'period' must be a number");
        return nullptr;
    }

    bool result = false;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller && g_controller->IOpticalAcquire) {
            result = g_controller->IOpticalAcquire->SetAcquireADNotifyPeriod(static_cast<float>(periodDouble));
        } else {
            OH_LOG_WARN(LOG_APP, "Controller or IOpticalAcquire is null, SetAcquireADNotifyPeriod ignored");
        }
    }

    napi_value jsResult;
    napi_get_boolean(env, result, &jsResult);
    return jsResult;
}

static napi_value NapiStartAcquirer(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiStartAcquirer");

    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 1) {
        napi_throw_error(env, nullptr, "StartAcquirer requires 1 argument: acquireTime (number)");
        return nullptr;
    }

    double timeSec;
    if (napi_get_value_double(env, args[0], &timeSec) != napi_ok) {
        napi_throw_error(env, nullptr, "acquireTime must be a number");
        return nullptr;
    }

    bool result = false;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller && g_controller->IOpticalAcquire) {
            result = g_controller->IOpticalAcquire->StartAcquirer(static_cast<float>(timeSec));
        } else {
            OH_LOG_WARN(LOG_APP, "Controller or IOpticalAcquire is null, StartAcquirer ignored");
        }
    }

    napi_value jsResult;
    napi_get_boolean(env, result, &jsResult);
    return jsResult;
}

static napi_value NapiStopAcquirer(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiStopAcquirer");

    size_t argc = 0;
    napi_get_cb_info(env, info, &argc, nullptr, nullptr, nullptr);

    bool result = false;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller && g_controller->IOpticalAcquire) {
            result = g_controller->IOpticalAcquire->StopAcquirer();
        } else {
            OH_LOG_WARN(LOG_APP, "Controller or IOpticalAcquire is null, StopAcquirer ignored");
        }
    }

    napi_value jsResult;
    napi_get_boolean(env, result, &jsResult);
    return jsResult;
}

static napi_value NapiStartLEDController(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiStartLEDController");

    size_t argc = 0;
    napi_get_cb_info(env, info, &argc, nullptr, nullptr, nullptr);

    bool result = false;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller && g_controller->IOpticalAcquire) {
            result = g_controller->IOpticalAcquire->StartLEDController();
        } else {
            OH_LOG_WARN(LOG_APP, "Controller or IOpticalAcquire is null, StartLEDController ignored");
        }
    }

    napi_value jsResult;
    napi_get_boolean(env, result, &jsResult);
    return jsResult;
}

static napi_value NapiTurnOffLED(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiTurnOffLED");

    size_t argc = 0;
    napi_get_cb_info(env, info, &argc, nullptr, nullptr, nullptr);

    bool result = false;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller && g_controller->IOpticalAcquire) {
            result = g_controller->IOpticalAcquire->TurnOffLED();
        } else {
            OH_LOG_WARN(LOG_APP, "Controller or IOpticalAcquire is null, TurnOffLED ignored");
        }
    }

    napi_value jsResult;
    napi_get_boolean(env, result, &jsResult);
    return jsResult;
}

static napi_value NapiGetLEDControllerTarget(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiGetLEDControllerTarget");

    size_t argc = 0;
    napi_get_cb_info(env, info, &argc, nullptr, nullptr, nullptr);

    Uint32 target = 0;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller && g_controller->IOpticalAcquire) {
            target = g_controller->IOpticalAcquire->GetLEDControllerTartet();
        } else {
            OH_LOG_WARN(LOG_APP, "Controller or IOpticalAcquire is null, GetLEDControllerTarget returns 0");
        }
    }

    napi_value jsResult;
    napi_create_uint32(env, target, &jsResult);
    return jsResult;
}

static napi_value NapiSetLEDControllerTarget(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiSetLEDControllerTarget");

    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 1) {
        napi_throw_error(env, nullptr, "SetLEDControllerTarget requires 1 argument: target (number)");
        return nullptr;
    }

    uint32_t target;
    if (napi_get_value_uint32(env, args[0], &target) != napi_ok) {
        napi_throw_error(env, nullptr, "target must be a non-negative integer (Uint32)");
        return nullptr;
    }

    bool result = false;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller && g_controller->IOpticalAcquire) {
            result = g_controller->IOpticalAcquire->SetLEDControllerTarget(target);
        } else {
            OH_LOG_WARN(LOG_APP, "Controller or IOpticalAcquire is null, SetLEDControllerTarget ignored");
        }
    }

    napi_value jsResult;
    napi_get_boolean(env, result, &jsResult);
    return jsResult;
}

static napi_value NapiStartLEDOnceAdjust(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiStartLEDOnceAdjust");

    size_t argc = 3;
    napi_value args[3];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 3) {
        napi_throw_error(env, nullptr, "StartLEDOnceAdjust requires 3 arguments: targetAD, tolorance, timeout (all numbers)");
        return nullptr;
    }

    uint32_t targetAD, tolorance, timeout;
    if (napi_get_value_uint32(env, args[0], &targetAD) != napi_ok ||
        napi_get_value_uint32(env, args[1], &tolorance) != napi_ok ||
        napi_get_value_uint32(env, args[2], &timeout) != napi_ok) {
        napi_throw_error(env, nullptr, "All arguments must be non-negative integers (Uint32)");
        return nullptr;
    }

    bool result = false;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller && g_controller->IOpticalAcquire) {
            result = g_controller->IOpticalAcquire->StartLEDOnceAdjust(targetAD, tolorance, timeout);
        } else {
            OH_LOG_WARN(LOG_APP, "Controller or IOpticalAcquire is null, StartLEDOnceAdjust ignored");
        }
    }

    napi_value jsResult;
    napi_get_boolean(env, result, &jsResult);
    return jsResult;
}

static napi_value NapiStopLEDOnceAdjust(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiStopLEDOnceAdjust");

    size_t argc = 0;
    napi_get_cb_info(env, info, &argc, nullptr, nullptr, nullptr);

    bool result = false;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller && g_controller->IOpticalAcquire) {
            result = g_controller->IOpticalAcquire->StopLEDOnceAdjust();
        } else {
            OH_LOG_WARN(LOG_APP, "Controller or IOpticalAcquire is null, StopLEDOnceAdjust ignored");
        }
    }

    napi_value jsResult;
    napi_get_boolean(env, result, &jsResult);
    return jsResult;
}

static napi_value NapiGetLEDControllerParam(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiGetLEDControllerParam");

    size_t argc = 0;
    napi_get_cb_info(env, info, &argc, nullptr, nullptr, nullptr);

    LedParam param{0.0f, 0.0f, 0.0f};
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller && g_controller->IOpticalAcquire) {
            param = g_controller->IOpticalAcquire->GetLEDControllerParam();
        } else {
            OH_LOG_WARN(LOG_APP, "Controller or IOpticalAcquire is null, returning default LedParam");
        }
    }

    return LedParamToJsObject(env, param);
}

static napi_value NapiSetLEDControllerParam(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiSetLEDControllerParam");

    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 1) {
        napi_throw_error(env, nullptr, "Expected 1 argument: ledParam object");
        return nullptr;
    }

    LedParam param;
    if (!JsObjectToLedParam(env, args[0], param)) {
        napi_throw_error(env, nullptr,
            "Invalid thermostatParam: must have 'proportion', 'integration', and 'differential' as numbers");
        return nullptr;
    }

    bool result = false;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller && g_controller->IOpticalAcquire) {
           result = g_controller->IOpticalAcquire->SetLEDControllerParam(param);
        }
    }

    // 8. 返回布尔值
    napi_value jsResult;
    napi_get_boolean(env, result, &jsResult);
    return jsResult;
}

static napi_value NapiStartStaticADControl(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiStartStaticADControl");

    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 2) {
        napi_throw_error(env, nullptr, "StartStaticADControl requires 2 arguments: index (number), targetAD (number)");
        return nullptr;
    }

    uint32_t index32, targetAD;
    if (napi_get_value_uint32(env, args[0], &index32) != napi_ok ||
        napi_get_value_uint32(env, args[1], &targetAD) != napi_ok) {
        napi_throw_error(env, nullptr, "Both arguments must be non-negative integers");
        return nullptr;
    }

    if (index32 > UINT8_MAX) {
        napi_throw_error(env, nullptr, "index must be in range [0, 255]");
        return nullptr;
    }
    Uint8 index = static_cast<Uint8>(index32);

    bool result = false;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller && g_controller->IOpticalAcquire) {
            result = g_controller->IOpticalAcquire->StartStaticADControl(index, targetAD);
        } else {
            OH_LOG_WARN(LOG_APP, "Controller or IOpticalAcquire is null, StartStaticADControl ignored");
        }
    }

    napi_value jsResult;
    napi_get_boolean(env, result, &jsResult);
    return jsResult;
}

static napi_value NapiStopStaticADControl(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiStopStaticADControl");

    size_t argc = 0;
    napi_get_cb_info(env, info, &argc, nullptr, nullptr, nullptr);

    bool result = false;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller && g_controller->IOpticalAcquire) {
            result = g_controller->IOpticalAcquire->StopStaticADControl();
        } else {
            OH_LOG_WARN(LOG_APP, "Controller or IOpticalAcquire is null, StopStaticADControl ignored");
        }
    }

    napi_value jsResult;
    napi_get_boolean(env, result, &jsResult);
    return jsResult;
}

static napi_value NapiGetStaticADControlParam(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiGetStaticADControlParam");

    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 1) {
        napi_throw_error(env, nullptr, "GetStaticADControlParam requires 1 argument: index (number)");
        return nullptr;
    }

    uint32_t index32;
    if (napi_get_value_uint32(env, args[0], &index32) != napi_ok) {
        napi_throw_error(env, nullptr, "index must be a non-negative integer");
        return nullptr;
    }

    if (index32 > UINT8_MAX) {
        napi_throw_error(env, nullptr, "index must be in range [0, 255]");
        return nullptr;
    }
    Uint8 index = static_cast<Uint8>(index32);

    Uint16 value = 0;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller && g_controller->IOpticalAcquire) {
            value = g_controller->IOpticalAcquire->GetStaticADControlParam(index);
        } else {
            OH_LOG_WARN(LOG_APP, "Controller or IOpticalAcquire is null, returning 0");
        }
    }

    napi_value jsResult;
    napi_create_uint32(env, value, &jsResult); // Uint16 fits in uint32
    return jsResult;
}

static napi_value NapiSetStaticADControlParam(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiSetStaticADControlParam");

    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 2) {
        napi_throw_error(env, nullptr, "SetStaticADControlParam requires 2 arguments: index (number), value (number)");
        return nullptr;
    }

    uint32_t index32, value32;
    if (napi_get_value_uint32(env, args[0], &index32) != napi_ok ||
        napi_get_value_uint32(env, args[1], &value32) != napi_ok) {
        napi_throw_error(env, nullptr, "Both arguments must be non-negative integers");
        return nullptr;
    }

    if (index32 > UINT8_MAX) {
        napi_throw_error(env, nullptr, "index must be in range [0, 255]");
        return nullptr;
    }
    if (value32 > UINT16_MAX) {
        napi_throw_error(env, nullptr, "value must be in range [0, 65535]");
        return nullptr;
    }

    Uint8 index = static_cast<Uint8>(index32);
    Uint16 value = static_cast<Uint16>(value32);

    bool result = false;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller && g_controller->IOpticalAcquire) {
            result = g_controller->IOpticalAcquire->SetStaticADControlParam(index, value);
        } else {
            OH_LOG_WARN(LOG_APP, "Controller or IOpticalAcquire is null, SetStaticADControlParam ignored");
        }
    }

    napi_value jsResult;
    napi_get_boolean(env, result, &jsResult);
    return jsResult;
}

static napi_value NapiIsStaticADControlValid(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiIsStaticADControlValid");

    size_t argc = 0;
    napi_get_cb_info(env, info, &argc, nullptr, nullptr, nullptr);

    bool result = false;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller && g_controller->IOpticalAcquire) {
            result = g_controller->IOpticalAcquire->IsStaticADControlValid();
        } else {
            OH_LOG_WARN(LOG_APP, "Controller or IOpticalAcquire is null, IsStaticADControlValid returns false");
        }
    }

    napi_value jsResult;
    napi_get_boolean(env, result, &jsResult);
    return jsResult;
}

static napi_value NapiGetLEDDefaultValue(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiGetLEDDefaultValue");

    size_t argc = 0;
    napi_get_cb_info(env, info, &argc, nullptr, nullptr, nullptr);

    float value = 0.0f;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller && g_controller->IOpticalAcquire) {
            value = g_controller->IOpticalAcquire->GetLEDDefaultValue();
        } else {
            OH_LOG_WARN(LOG_APP, "Controller or IOpticalAcquire is null, returning 0.0");
        }
    }

    napi_value jsResult;
    napi_create_double(env, static_cast<double>(value), &jsResult);
    return jsResult;
}

static napi_value NapiSetLEDDefaultValue(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiSetLEDDefaultValue");

    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 1) {
        napi_throw_error(env, nullptr, "SetLEDDefaultValue requires 1 argument: value (number)");
        return nullptr;
    }

    double dval;
    if (napi_get_value_double(env, args[0], &dval) != napi_ok) {
        napi_throw_error(env, nullptr, "value must be a number");
        return nullptr;
    }

    bool result = false;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller && g_controller->IOpticalAcquire) {
            result = g_controller->IOpticalAcquire->SetLEDDefaultValue(static_cast<float>(dval));
        } else {
            OH_LOG_WARN(LOG_APP, "Controller or IOpticalAcquire is null, SetLEDDefaultValue ignored");
        }
    }

    napi_value jsResult;
    napi_get_boolean(env, result, &jsResult);
    return jsResult;
}

static napi_value NapiSetStaticADGain(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiSetStaticADGain");

    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 1) {
        napi_throw_error(env, nullptr, "SetStaticADGain requires 1 argument: gain (number)");
        return nullptr;
    }

    int32_t gain;
    if (napi_get_value_int32(env, args[0], &gain) != napi_ok) {
        napi_throw_error(env, nullptr, "gain must be an integer");
        return nullptr;
    }

    bool result = false;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller && g_controller->IOpticalAcquire) {
            result = g_controller->IOpticalAcquire->SetStaticADGain(static_cast<int>(gain));
        } else {
            OH_LOG_WARN(LOG_APP, "Controller or IOpticalAcquire is null, SetStaticADGain ignored");
        }
    }

    napi_value jsResult;
    napi_get_boolean(env, result, &jsResult);
    return jsResult;
}

static napi_value NapiExpectADAcquirer(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiExpectADAcquirer");

    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 1) {
        napi_throw_error(env, nullptr, "ExpectADAcquirer requires 1 argument: timeout (number)");
        return nullptr;
    }

    int64_t timeout;
    if (napi_get_value_int64(env, args[0], &timeout) != napi_ok) {
        // 兼容部分平台不支持 int64，尝试 double 或 int32
        double dval;
        if (napi_get_value_double(env, args[0], &dval) == napi_ok) {
            timeout = static_cast<int64_t>(dval);
        } else {
            napi_throw_error(env, nullptr, "timeout must be a number (integer or float)");
            return nullptr;
        }
    }

    AcquiredResult result{};
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller && g_controller->IOpticalAcquire) {
            result = g_controller->IOpticalAcquire->ExpectADAcquirer(static_cast<long>(timeout));
        } else {
            OH_LOG_WARN(LOG_APP, "Controller or IOpticalAcquire is null, ExpectADAcquirer returns default AcquiredResult");
        }
    }

    // 直接调用已有的转换函数
    return AcquiredResultToJsObject(env, result);
}

static napi_value NapiExpectLEDOnceAdjust(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiExpectLEDOnceAdjust");

    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 1) {
        napi_throw_error(env, nullptr, "ExpectLEDOnceAdjust requires 1 argument: timeout (number)");
        return nullptr;
    }

    int64_t timeout;
    if (napi_get_value_int64(env, args[0], &timeout) != napi_ok) {
        double dval;
        if (napi_get_value_double(env, args[0], &dval) == napi_ok) {
            timeout = static_cast<int64_t>(dval);
        } else {
            napi_throw_error(env, nullptr, "timeout must be a number");
            return nullptr;
        }
    }

    AdjustResult result = AdjustResult::Failed; // 默认值
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller && g_controller->IOpticalAcquire) {
            result = g_controller->IOpticalAcquire->ExpectLEDOnceAdjust(static_cast<long>(timeout));
        } else {
            OH_LOG_WARN(LOG_APP, "Controller or IOpticalAcquire is null, ExpectLEDOnceAdjust returns Failed");
        }
    }

    // 将 enum class 转为整数返回给 JS
    napi_value jsResult;
    napi_create_int32(env, static_cast<int32_t>(result), &jsResult);
    return jsResult;
}

static napi_value NapiExpectStaticADControlResult(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "NapiExpectStaticADControlResult");

    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 1) {
        napi_throw_error(env, nullptr, "ExpectStaticADControlResult requires 1 argument: timeout (number)");
        return nullptr;
    }

    int64_t timeout;
    if (napi_get_value_int64(env, args[0], &timeout) != napi_ok) {
        double dval;
        if (napi_get_value_double(env, args[0], &dval) == napi_ok) {
            timeout = static_cast<int64_t>(dval);
        } else {
            napi_throw_error(env, nullptr, "timeout must be a number");
            return nullptr;
        }
    }

    StaticADControlResult result = StaticADControlResult::Unfinished; // 默认值
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (g_controller && g_controller->IOpticalAcquire) {
            result = g_controller->IOpticalAcquire->ExpectStaticADControlResult(static_cast<long>(timeout));
        } else {
            OH_LOG_WARN(LOG_APP, "Controller or IOpticalAcquire is null, returning Unfinished");
        }
    }

    // enum class → int32 → JS number
    napi_value jsResult;
    napi_create_int32(env, static_cast<int32_t>(result), &jsResult);
    return jsResult;
}

void RegisterOpticalModule(napi_env env, napi_value exports) {
    // 1. 创建 pump 子对象
    napi_value opticalObj;
    napi_create_object(env, &opticalObj);

    // 2. 定义方法描述符 
    napi_property_descriptor descriptors[] = {
        {"turnOnLED", nullptr, NapiTurnOnLED, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setAcquireADNotifyPeriod", nullptr, NapiSetAcquireADNotifyPeriod, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"startAcquirer", nullptr, NapiStartAcquirer, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"stopAcquirer", nullptr, NapiStopAcquirer, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"startLEDController", nullptr, NapiStartLEDController, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"turnOffLED", nullptr, NapiTurnOffLED, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getLEDControllerTarget", nullptr, NapiGetLEDControllerTarget, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setLEDControllerTarget", nullptr, NapiSetLEDControllerTarget, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"startLEDOnceAdjust", nullptr, NapiStartLEDOnceAdjust, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"stopLEDOnceAdjust", nullptr, NapiStopLEDOnceAdjust, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getLEDControllerParam", nullptr, NapiGetLEDControllerParam, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setLEDControllerParam", nullptr, NapiSetLEDControllerParam, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"startStaticADControl", nullptr, NapiStartStaticADControl, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"stopStaticADControl", nullptr, NapiStopStaticADControl, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getStaticADControlParam", nullptr, NapiGetStaticADControlParam, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setStaticADControlParam", nullptr, NapiSetStaticADControlParam, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"isStaticADControlValid", nullptr, NapiIsStaticADControlValid, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getLEDDefaultValue", nullptr, NapiGetLEDDefaultValue, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setLEDDefaultValue", nullptr, NapiSetLEDDefaultValue, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setStaticADGain", nullptr, NapiSetStaticADGain, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"expectADAcquirer", nullptr, NapiExpectADAcquirer, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"expectLEDOnceAdjust", nullptr, NapiExpectLEDOnceAdjust, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"expectStaticADControlResult", nullptr, NapiExpectStaticADControlResult, nullptr, nullptr, nullptr, napi_default, nullptr},
    };

    // 3. 将方法绑定到 opticalObj
    napi_define_properties(
        env,
        opticalObj,
        sizeof(descriptors) / sizeof(descriptors[0]),
        descriptors
    );

    // 4. 【关键】将 opticalObj 挂到 parentObj 上，属性名为 "pump"
    napi_set_named_property(env, exports, "optical", opticalObj);
}