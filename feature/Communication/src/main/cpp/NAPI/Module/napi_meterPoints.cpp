#include "napi_meterPoints.h"
#include "hilog/log.h"
#undef LOG_DOMAIN
#undef LOG_TAG
#define LOG_DOMAIN 0x3200  // 全局domain宏，标识业务领域
#define LOG_TAG "MY_TAG"   // 全局tag宏，标识模块日志tag
#include "napi/native_api.h"
#include "/PT63DriveControllerPlugin/API/MeterPoints.h" // 你的 ValveMap 头文件

using namespace Controller::API;

// 析构回调：当 JS 对象被 GC 时释放 C++ 对象
static void MeterPointsDestructor(napi_env env, void* nativeObject, void* finalize_hint) {
    delete static_cast<MeterPoints*>(nativeObject);
}

// JS 构造函数
static napi_value MeterPointsConstructor(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "MeterPointsConstructor");
    napi_status status;
    size_t argc = 1;
    napi_value args[1];
    napi_value thisArg;

    status = napi_get_cb_info(env, info, &argc, args, &thisArg, nullptr);
    if (status != napi_ok) return nullptr;

    int32_t initData = 0;
    if (argc >= 1) {
        napi_get_value_int32(env, args[0], &initData);
    }

    // 创建 C++ 对象
    MeterPoints* vm = new MeterPoints(initData);

    // 将 C++ 对象绑定到 JS 对象（thisArg）
    status = napi_wrap(env, thisArg, vm, MeterPointsDestructor, nullptr, nullptr);
    if (status != napi_ok) {
        delete vm;
        return nullptr;
    }
    OH_LOG_INFO(LOG_APP, "MeterPointDestructor End %{public}d", initData);

    return thisArg;
}

// GetNum()
static napi_value GetNum(napi_env env, napi_callback_info info) {
    napi_value thisArg;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisArg, nullptr);

    MeterPoints* meterPoints = nullptr;
    napi_unwrap(env, thisArg, reinterpret_cast<void**>(&meterPoints));

    int num = meterPoints->GetNum();
    napi_value result;
    napi_create_int32(env, num, &result);
    
    return nullptr;
}

// SetNum(num)
static napi_value SetNum(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_value thisArg;
    napi_get_cb_info(env, info, &argc, args, &thisArg, nullptr);

    if (argc != 1) {
        napi_throw_error(env, nullptr, "SetNum requires exactly 1 argument");
        return nullptr;
    }

    uint32_t num;
    napi_get_value_uint32(env, args[0], &num);

    MeterPoints* meterPoints = nullptr;
    napi_unwrap(env, thisArg, reinterpret_cast<void**>(&meterPoints));
    meterPoints->SetNum(num);

    return nullptr; // void
}

// SetPoint(index, { setVolume, realVolume })
static napi_value SetPoint(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "MeterPoints SetPoint");
    size_t argc = 2;
    napi_value args[2];
    napi_value thisArg;
    napi_get_cb_info(env, info, &argc, args, &thisArg, nullptr);

    if (argc != 2) {
        napi_throw_error(env, nullptr, "SetPoint requires 2 arguments: index and point object");
        return nullptr;
    }

    uint32_t index;
    napi_get_value_uint32(env, args[0], &index);

    napi_value setVolKey, realVolKey;
    napi_create_string_utf8(env, "setVolume", NAPI_AUTO_LENGTH, &setVolKey);
    napi_create_string_utf8(env, "realVolume", NAPI_AUTO_LENGTH, &realVolKey);

    napi_value setVolVal, realVolVal;
    napi_get_named_property(env, args[1], "setVolume", &setVolVal);
    napi_get_named_property(env, args[1], "realVolume", &realVolVal);

    double setVol, realVol;
    napi_get_value_double(env, setVolVal, &setVol);
    napi_get_value_double(env, realVolVal, &realVol);

    MeterPoint point;
    point.setVolume = static_cast<float>(setVol);
    point.realVolume = static_cast<float>(realVol);

    MeterPoints* meterPoints = nullptr;
    napi_unwrap(env, thisArg, reinterpret_cast<void**>(&meterPoints));
    meterPoints->SetPoint(index, point);

    return nullptr;
}

// GetPoint(index) -> { setVolume, realVolume }
static napi_value GetPoint(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_value thisArg;
    napi_get_cb_info(env, info, &argc, args, &thisArg, nullptr);

    if (argc != 1) {
        napi_throw_error(env, nullptr, "GetPoint requires 1 argument: index");
        return nullptr;
    }

    uint32_t index;
    napi_get_value_uint32(env, args[0], &index);

    MeterPoints* meterPoints = nullptr;
    napi_unwrap(env, thisArg, reinterpret_cast<void**>(&meterPoints));

    MeterPoint point = meterPoints->GetPoint(index);

    napi_value result;
    napi_create_object(env, &result);

    napi_value setVol, realVol;
    napi_create_double(env, point.setVolume, &setVol);
    napi_create_double(env, point.realVolume, &realVol);

    napi_set_named_property(env, result, "setVolume", setVol);
    napi_set_named_property(env, result, "realVolume", realVol);

    return result;
}

void RegisterMeterPointsModule(napi_env env, napi_value exports) {
    // 2. 定义方法描述符 NapiGetTotalPumps
    napi_property_descriptor descriptors[] = {
        {"meterPoint_getNum", nullptr, GetNum, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"meterPoint_setNum", nullptr, SetNum, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"meterPoint_setPoint", nullptr, SetPoint, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"meterPoint_getPoint", nullptr, GetPoint, nullptr, nullptr, nullptr, napi_default, nullptr},
    };

    napi_define_class(env, "MeterPoints", NAPI_AUTO_LENGTH,
                      MeterPointsConstructor, nullptr,
                      sizeof(descriptors) / sizeof(descriptors[0]), descriptors,
                      &exports);
}
