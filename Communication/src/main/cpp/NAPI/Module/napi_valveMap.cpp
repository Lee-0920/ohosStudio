#include "napi_valveMap.h"
#include "hilog/log.h"
#undef LOG_DOMAIN
#undef LOG_TAG
#define LOG_DOMAIN 0x3200  // 全局domain宏，标识业务领域
#define LOG_TAG "MY_TAG"   // 全局tag宏，标识模块日志tag
#include "napi/native_api.h"
#include "/PT63DriveControllerPlugin/API/ValveMap.h" // 你的 ValveMap 头文件

using namespace Controller::API;

// 析构回调：当 JS 对象被 GC 时释放 C++ 对象
static void ValveMapDestructor(napi_env env, void* nativeObject, void* finalize_hint) {
    delete static_cast<ValveMap*>(nativeObject);
}

// JS 构造函数
static napi_value ValveMapConstructor(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "ValveMapConstructor");
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
    ValveMap* vm = new ValveMap(initData);

    // 将 C++ 对象绑定到 JS 对象（thisArg）
    status = napi_wrap(env, thisArg, vm, ValveMapDestructor, nullptr, nullptr);
    if (status != napi_ok) {
        delete vm;
        return nullptr;
    }
    OH_LOG_INFO(LOG_APP, "ValveMapConstructor End %{public}d", initData);

    return thisArg;
}

// JS 方法：SetOn
static napi_value ValveMap_SetOn(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_value thisArg;
    napi_get_cb_info(env, info, &argc, args, &thisArg, nullptr);

    int32_t index;
    napi_get_value_int32(env, args[0], &index);

    ValveMap* vm;
    napi_unwrap(env, thisArg, reinterpret_cast<void**>(&vm));
    vm->SetOn(index);

    return nullptr; // void
}

// JS 方法：SetOff
static napi_value ValveMap_SetOff(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_value thisArg;
    napi_get_cb_info(env, info, &argc, args, &thisArg, nullptr);

    int32_t index;
    napi_get_value_int32(env, args[0], &index);

    ValveMap* vm;
    napi_unwrap(env, thisArg, reinterpret_cast<void**>(&vm));
    vm->SetOff(index);

    return nullptr; // void
}

// JS 方法：IsOn
static napi_value ValveMap_IsOn(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_value thisArg;
    napi_get_cb_info(env, info, &argc, args, &thisArg, nullptr);

    int32_t index;
    napi_get_value_int32(env, args[0], &index);

    ValveMap* vm;
    napi_unwrap(env, thisArg, reinterpret_cast<void**>(&vm));
    bool on = vm->IsOn(index);

    napi_value result;
    napi_get_boolean(env, on, &result);
    return result;
}

// JS 方法：Clear
static napi_value ValveMap_Clear(napi_env env, napi_callback_info info) {
    napi_value thisArg;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisArg, nullptr);

    ValveMap* vm;
    napi_unwrap(env, thisArg, reinterpret_cast<void**>(&vm));

    vm->clear();
    return nullptr;
}

// JS 方法：SetOff
static napi_value ValveMap_SetData(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "ValveMap_SetData");
    size_t argc = 1;
    napi_value args[1];
    napi_value thisArg;
    napi_get_cb_info(env, info, &argc, args, &thisArg, nullptr);

    int32_t index;
    napi_get_value_int32(env, args[0], &index);

    ValveMap* vm;
    napi_unwrap(env, thisArg, reinterpret_cast<void**>(&vm));
    vm->SetData(index);

    return nullptr; // void
}

// JS 方法：GetData
static napi_value ValveMap_GetData(napi_env env, napi_callback_info info) {
    napi_value thisArg;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisArg, nullptr);

    ValveMap* vm;
    napi_unwrap(env, thisArg, reinterpret_cast<void**>(&vm));

    napi_value result;
    napi_create_uint32(env, vm->GetData(), &result);
    return result;
}

// JS 方法：SetSpinValveCmd
static napi_value ValveMap_SetSpinValveCmd(napi_env env, napi_callback_info info) {
    size_t argc = 3;
    napi_value args[3];
    napi_value thisArg;
    napi_get_cb_info(env, info, &argc, args, &thisArg, nullptr);
    
    if (argc < 3) {
        napi_throw_error(env, nullptr, "SetSpinValveCmd 4 argument: cmd (number)param1 (number)param2 (number)");
        return nullptr;
    }

    int32_t cmd;
    napi_get_value_int32(env, args[0], &cmd);
    
    int32_t param1;
    napi_get_value_int32(env, args[1], &param1);
    
    int32_t param2;
    napi_get_value_int32(env, args[2], &param2);

    ValveMap* vm;
    napi_unwrap(env, thisArg, reinterpret_cast<void**>(&vm));
    vm->SetSpinValveCmd(cmd, param1, param2);

    return nullptr; // void
}

static napi_value ValveMap_GetCmd(napi_env env, napi_callback_info info) {
    napi_value thisArg;
    // 获取调用该方法的 JS 对象（this）
    napi_get_cb_info(env, info, nullptr, nullptr, &thisArg, nullptr);

    // 从 JS 对象中解包出 C++ ValveMap 指针
    ValveMap* vm;
    napi_unwrap(env, thisArg, reinterpret_cast<void**>(&vm));

    // 调用 C++ 方法获取 cmd 值（uint8_t）
    uint8_t cmd = vm->GetCmd();

    // 创建对应的 JS number 值（使用 uint32 容纳 uint8）
    napi_value result;
    napi_create_uint32(env, static_cast<uint32_t>(cmd), &result);

    return result;
}

static napi_value ValveMap_GetParam1(napi_env env, napi_callback_info info) {
    napi_value thisArg;
    // 获取调用该方法的 JS 对象（this）
    napi_get_cb_info(env, info, nullptr, nullptr, &thisArg, nullptr);

    // 从 JS 对象中解包出 C++ ValveMap 指针
    ValveMap* vm;
    napi_unwrap(env, thisArg, reinterpret_cast<void**>(&vm));

    // 调用 C++ 方法获取 cmd 值（uint8_t）
    uint8_t cmd = vm->GetParam1();

    // 创建对应的 JS number 值（使用 uint32 容纳 uint8）
    napi_value result;
    napi_create_uint32(env, static_cast<uint32_t>(cmd), &result);

    return result;
}

static napi_value ValveMap_GetParam2(napi_env env, napi_callback_info info) {
    napi_value thisArg;
    // 获取调用该方法的 JS 对象（this）
    napi_get_cb_info(env, info, nullptr, nullptr, &thisArg, nullptr);

    // 从 JS 对象中解包出 C++ ValveMap 指针
    ValveMap* vm;
    napi_unwrap(env, thisArg, reinterpret_cast<void**>(&vm));

    // 调用 C++ 方法获取 cmd 值（uint8_t）
    uint8_t cmd = vm->GetParam2();

    // 创建对应的 JS number 值（使用 uint32 容纳 uint8）
    napi_value result;
    napi_create_uint32(env, static_cast<uint32_t>(cmd), &result);

    return result;
}

static napi_value ValveMap_GetIndex(napi_env env, napi_callback_info info) {
    napi_value thisArg;
    // 获取调用该方法的 JS 对象（this）
    napi_get_cb_info(env, info, nullptr, nullptr, &thisArg, nullptr);

    // 从 JS 对象中解包出 C++ ValveMap 指针
    ValveMap* vm;
    napi_unwrap(env, thisArg, reinterpret_cast<void**>(&vm));

    // 调用 C++ 方法获取 cmd 值（uint8_t）
    uint32_t cmd = vm->GetIndex();

    // 创建对应的 JS number 值（使用 uint32 容纳 uint8）
    napi_value result;
    napi_create_uint32(env, static_cast<uint32_t>(cmd), &result);

    return result;
}


void RegisterValveMapModule(napi_env env, napi_value exports) {
    // 1. 创建 valveMap 子对象
    napi_value valveMapObj;

    // 2. 定义方法描述符 NapiGetTotalPumps
    napi_property_descriptor descriptors[] = {
        {"setOn", nullptr, ValveMap_SetOn, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setOff", nullptr, ValveMap_SetOff, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"isOn", nullptr, ValveMap_IsOn, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setData", nullptr, ValveMap_SetData, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getData", nullptr, ValveMap_GetData, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"clear", nullptr, ValveMap_Clear, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setSpinValveCmd", nullptr, ValveMap_SetSpinValveCmd, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getCmd", nullptr, ValveMap_GetCmd, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getParam1", nullptr, ValveMap_GetParam1, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getParam2", nullptr, ValveMap_GetParam2, nullptr, nullptr, nullptr, napi_default, nullptr},
    };

    napi_define_class(env, "ValveMap", NAPI_AUTO_LENGTH,
                      ValveMapConstructor, nullptr,
                      sizeof(descriptors) / sizeof(descriptors[0]), descriptors,
                      &valveMapObj);

    // 将构造函数挂载到 exports 上，例如 exports.ValveMap = ValveMap
    napi_set_named_property(env, exports, "ValveMap", valveMapObj);
}