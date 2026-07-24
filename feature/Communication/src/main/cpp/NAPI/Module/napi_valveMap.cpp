#include "napi_valveMap.h"
#include "hilog/log.h"
#undef LOG_DOMAIN
#undef LOG_TAG
#define LOG_DOMAIN 0x3200
#define LOG_TAG "MY_TAG"
#include "napi/native_api.h"
#include "/PT63DriveControllerPlugin/API/ValveMap.h"

using namespace Controller::API;

// ❌ 已删除 ValveMapDestructor
// ❌ 已删除 ValveMapConstructor

// ✅ 辅助宏：从 JS 对象读取 int32 属性
#define GET_INT32_PROP(env, obj, name, out) \
    do { \
        napi_value _prop; \
        napi_get_named_property(env, obj, name, &_prop); \
        napi_get_value_int32(env, _prop, &out); \
    } while(0)

// ✅ 辅助宏：向 JS 对象写入 int32 属性
#define SET_INT32_PROP(env, obj, name, val) \
    do { \
        napi_value _v; \
        napi_create_int32(env, val, &_v); \
        napi_set_named_property(env, obj, name, _v); \
    } while(0)

// nativeInitValveMap(map: ValveMap, initData: number): void
static napi_value NativeInitValveMap(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    int32_t initData = 0;
    napi_get_value_int32(env, args[1], &initData);

    // 用临时 C++ 对象计算初始状态，然后同步到 JS 对象
    ValveMap temp(initData);
    SET_INT32_PROP(env, args[0], "data", temp.GetData());
    SET_INT32_PROP(env, args[0], "cmd", temp.GetCmd());
    SET_INT32_PROP(env, args[0], "param1", temp.GetParam1());
    SET_INT32_PROP(env, args[0], "param2", temp.GetParam2());
    SET_INT32_PROP(env, args[0], "index", temp.GetIndex());

    OH_LOG_INFO(LOG_APP, "NativeInitValveMap initData=%{public}d", initData);
    return nullptr;
}

// nativeSetData(map: ValveMap, data: number): void
static napi_value NativeSetData(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    int32_t data = 0;
    napi_get_value_int32(env, args[1], &data);

    // 如果 SetData 需要触发硬件，在此调用底层 API
    // ValveMap::StaticSetData(data); 
    SET_INT32_PROP(env, args[0], "data", data);

    OH_LOG_INFO(LOG_APP, "NativeSetData data=%{public}d", data);
    return nullptr;
}

// nativeGetData(map: ValveMap): number
static napi_value NativeGetData(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    int32_t data = 0;
    GET_INT32_PROP(env, args[0], "data", data);

    napi_value result;
    napi_create_uint32(env, static_cast<uint32_t>(data), &result);
    return result;
}

// nativeSetOn(map: ValveMap, index: number): void
static napi_value NativeSetOn(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    int32_t index = 0;
    napi_get_value_int32(env, args[1], &index);

    // 触发硬件: ValveMap::StaticSetOn(index);
    return nullptr;
}

// nativeSetOff(map: ValveMap, index: number): void
static napi_value NativeSetOff(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    int32_t index = 0;
    napi_get_value_int32(env, args[1], &index);

    // 触发硬件: ValveMap::StaticSetOff(index);
    return nullptr;
}

// nativeIsOn(map: ValveMap, index: number): boolean
static napi_value NativeIsOn(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    int32_t index = 0;
    napi_get_value_int32(env, args[1], &index);

    // bool on = ValveMap::StaticIsOn(index);
    bool on = false; // TODO: 替换为实际硬件查询
    napi_value result;
    napi_get_boolean(env, on, &result);
    return result;
}

// nativeClear(map: ValveMap): void
static napi_value NativeClear(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    // ValveMap::StaticClear();
    SET_INT32_PROP(env, args[0], "data", 0);
    SET_INT32_PROP(env, args[0], "cmd", 0);
    SET_INT32_PROP(env, args[0], "param1", 0);
    SET_INT32_PROP(env, args[0], "param2", 0);
    return nullptr;
}

// nativeSetSpinValveCmd(map: ValveMap, cmd: number, p1: number, p2: number): void
static napi_value NativeSetSpinValveCmd(napi_env env, napi_callback_info info) {
    size_t argc = 4;
    napi_value args[4];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 4) {
        napi_throw_error(env, nullptr, "nativeSetSpinValveCmd requires 4 arguments");
        return nullptr;
    }

    int32_t cmd = 0, p1 = 0, p2 = 0;
    napi_get_value_int32(env, args[1], &cmd);
    napi_get_value_int32(env, args[2], &p1);
    napi_get_value_int32(env, args[3], &p2);

    // ValveMap::StaticSetSpinValveCmd(cmd, p1, p2);
    SET_INT32_PROP(env, args[0], "cmd", cmd);
    SET_INT32_PROP(env, args[0], "param1", p1);
    SET_INT32_PROP(env, args[0], "param2", p2);
    return nullptr;
}

// ✅ 注册为模块级函数，不再是类方法
void RegisterValveMapModule(napi_env env, napi_value exports) {
    napi_property_descriptor descriptors[] = {
        {"valveMap_initValveMap",   nullptr, NativeInitValveMap,   nullptr, nullptr, nullptr, napi_default, nullptr},
        {"valveMap_setData",        nullptr, NativeSetData,        nullptr, nullptr, nullptr, napi_default, nullptr},
        {"valveMap_getData",        nullptr, NativeGetData,        nullptr, nullptr, nullptr, napi_default, nullptr},
        {"valveMap_setOn",          nullptr, NativeSetOn,          nullptr, nullptr, nullptr, napi_default, nullptr},
        {"valveMap_setOff",         nullptr, NativeSetOff,         nullptr, nullptr, nullptr, napi_default, nullptr},
        {"valveMap_isOn",           nullptr, NativeIsOn,           nullptr, nullptr, nullptr, napi_default, nullptr},
        {"valveMap_clear",          nullptr, NativeClear,          nullptr, nullptr, nullptr, napi_default, nullptr},
        {"valveMap_setSpinValveCmd",nullptr, NativeSetSpinValveCmd,nullptr, nullptr, nullptr, napi_default, nullptr},
    };

    napi_define_properties(env, exports,
        sizeof(descriptors) / sizeof(descriptors[0]), descriptors);
}