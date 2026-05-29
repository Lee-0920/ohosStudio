#include "napi_event.h"
#include "hilog/log.h"
#undef LOG_DOMAIN
#undef LOG_TAG
#define LOG_DOMAIN 0x3200  // 全局domain宏，标识业务领域
#define LOG_TAG "MY_TAG"   // 全局tag宏，标识模块日志tag

using namespace Communication;
// 初始化静态成员
//napi_threadsafe_function Controller::PT63DriveController::g_tsfn = nullptr;

// Finalizer 函数：当 TSFN 被完全释放时调用
void TsfnFinalizer(napi_env env, void* finalize_data, void* finalize_hint) {
    // 在这里可以执行任何需要在 TSFN 生命周期结束时进行的清理工作
    // 例如，通知底层驱动停止发送事件等
    OH_LOG_INFO(LOG_APP, "TsfnFinalizer called, TSFN is being cleaned up.");
}


// 新的 CallJS 函数，能处理 variant
static void CallJS(napi_env env, napi_value js_callback, void* context, void* data) {
    OH_LOG_INFO(LOG_APP, "CallJS ");

    // 关键：检查 data 是否为 nullptr
    if (data == nullptr) {
        OH_LOG_ERROR(LOG_APP, "CallJS received null data!");
        return;
    }
    auto* payload = static_cast<Controller::EventPayload*>(data);

    // 关键：检查 payload 指针是否有效（基本检查）
    OH_LOG_INFO(LOG_APP, "CallJS: payload address = %{public}p", payload);

    // 1. 创建 JS 对象
    napi_value jsEventObj;
    napi_create_object(env, &jsEventObj);
    
//    size_t index = payload->index();
//    OH_LOG_INFO(LOG_APP, "CallJS: variant index = %{public}zu", index);
//    // 根据索引手动处理，而不是使用 std::visit
//    if (index == 0) {
//        // Temperature
//        const auto& tempData = std::get<Temperature>(*payload);
//        OH_LOG_INFO(LOG_APP, "Manual get: Temperature - thermostat=%{public}f, environment=%{public}f", 
//                   tempData.thermostatTemp, tempData.environmentTemp);
//    } else if (index == 1) {
//        // OpticalAD  
//        const auto& opticalData = std::get<OpticalAD>(*payload);
//        OH_LOG_INFO(LOG_APP, "Manual get: OpticalAD - ref=%{public}u, measure=%{public}u",
//                   opticalData.reference, opticalData.measure);
//    } else if (index == 2) {
//        // MeterAD
//        const auto& meterData = std::get<MeterAD>(*payload);
//        OH_LOG_INFO(LOG_APP, "Manual get: MeterAD - p1=%{public}u, p2=%{public}u",
//                   meterData.point1, meterData.point2);
//    } 
//        else if (index == 3) {
//        // uint16_t
//        const auto& leakingData = std::get<Uint16>(*payload);
//        OH_LOG_INFO(LOG_APP, "Manual get: Leaking - value=%{public}hu",
//                   leakingData);
//    }

    // 2. 使用 std::visit 来安全地访问 variant 中的实际类型
    std::visit([env, &jsEventObj](const auto& concreteData) {
        using T = std::decay_t<decltype(concreteData)>;

        if constexpr (std::is_same_v<T, Temperature>) {
            OH_LOG_INFO(LOG_APP, "CallJS -> Temperature");
            // 处理温度数据
            napi_value jsType; napi_create_string_utf8(env, "TEMPERATURE", NAPI_AUTO_LENGTH, &jsType);
            napi_set_named_property(env, jsEventObj, "type", jsType);

            napi_value jsThermostatTemp; napi_create_double(env, concreteData.thermostatTemp, &jsThermostatTemp);
            napi_set_named_property(env, jsEventObj, "thermostatTemp", jsThermostatTemp);

            napi_value jsEnvironmentTemp; napi_create_double(env, concreteData.environmentTemp, &jsEnvironmentTemp);
            napi_set_named_property(env, jsEventObj, "environmentTemp", jsEnvironmentTemp);

        } else if constexpr (std::is_same_v<T, OpticalAD>) {
            OH_LOG_INFO(LOG_APP, "CallJS -> OpticalAD");
            // 处理光学数据
            napi_value jsType; napi_create_string_utf8(env, "OPTICAL", NAPI_AUTO_LENGTH, &jsType);
            napi_set_named_property(env, jsEventObj, "type", jsType);

            napi_value jsReferenceAd; napi_create_uint32(env, concreteData.reference, &jsReferenceAd);
            napi_set_named_property(env, jsEventObj, "reference", jsReferenceAd);

            napi_value jsMeasureAd; napi_create_uint32(env, concreteData.measure, &jsMeasureAd);
            napi_set_named_property(env, jsEventObj, "measure", jsMeasureAd);
         } else if constexpr (std::is_same_v<T, MeterAD>) {
            OH_LOG_INFO(LOG_APP, "CallJS -> OpticalAD");
            // 处理光学数据
            napi_value jsType; napi_create_string_utf8(env, "METER", NAPI_AUTO_LENGTH, &jsType);
            napi_set_named_property(env, jsEventObj, "type", jsType);

            napi_value jsReferenceAd; napi_create_uint32(env, concreteData.point1, &jsReferenceAd);
            napi_set_named_property(env, jsEventObj, "point1", jsReferenceAd);

            napi_value jsMeasureAd; napi_create_uint32(env, concreteData.point2, &jsMeasureAd);
            napi_set_named_property(env, jsEventObj, "point2", jsMeasureAd);
        } else if constexpr (std::is_same_v<T, Uint32>) {
            OH_LOG_INFO(LOG_APP, "CallJS -> Leacking");
            // 处理泵数据
            napi_value jsType; napi_create_string_utf8(env, "LEACKING", NAPI_AUTO_LENGTH, &jsType);
            napi_set_named_property(env, jsEventObj, "type", jsType);

            napi_value jsLeakingId; napi_create_int32(env, concreteData, &jsLeakingId);
            napi_set_named_property(env, jsEventObj, "value", jsLeakingId);
        }
        // ... 为其他类型添加 else if ...

    }, *payload);

    // 3. 调用 JS 回调
    napi_value global;
    napi_get_global(env, &global);
    napi_call_function(env, global, js_callback, 1, &jsEventObj, nullptr);

    // 4. 清理内存
    delete payload;
}

// JS 可调用的注册函数：setOnPT63EventCallback(cb)
static napi_value SetOnPT63EventCallback(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "SetOnPT63EventCallback called");
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    napi_valuetype valuetype;
    napi_typeof(env, args[0], &valuetype);
    if (valuetype != napi_function) {
        // 抛出错误
        napi_throw_error(env, nullptr, "Callback must be a function");
        return nullptr;
    }
    
    // 创建 async resource name
    napi_value resource_name;
    napi_create_string_utf8(env, "PT63EventCallback", NAPI_AUTO_LENGTH, &resource_name);
    
    OH_LOG_INFO(LOG_APP, "SetOnPT63EventCallback ##1.");
    OH_LOG_INFO(LOG_APP, "Before napi_create_threadsafe_function, g_tsfn is: %{public}p", Controller::PT63DriveController::g_tsfn);
    // 创建线程安全函数 (ThreadSafeFunction)
    // 这个函数可以在任何线程上调用，并最终在 JS 线程执行传入的 args[0] (即 JS 回调)
     napi_status status = napi_create_threadsafe_function(
        env, args[0], nullptr, resource_name, 0, 1, nullptr, TsfnFinalizer, nullptr,
        CallJS, // <-- 使用新的 CallJS 函数
        &Controller::PT63DriveController::g_tsfn
    );
    // ... 错误处理 ...
    OH_LOG_INFO(LOG_APP, "After napi_create_threadsafe_function, status: %{public}d, g_tsfn is: %{public}p", 
                status, Controller::PT63DriveController::g_tsfn);
    if (status != napi_ok) {
        OH_LOG_ERROR(LOG_APP, "Failed to create threadsafe function");
        napi_throw_error(env, nullptr, "Failed to create threadsafe function");
        return nullptr;
    }

    return nullptr;
}

void RegisterEventModule(napi_env env, napi_value exports) {
    // 1. 创建 event 子对象
    napi_value eventObj;
    napi_create_object(env, &eventObj);

    // 2. 定义方法描述符 NapiGetTotalPumps
    napi_property_descriptor descriptors[] = {
        {"setOnPT63EventCallback", nullptr, SetOnPT63EventCallback, nullptr, nullptr, nullptr, napi_default, nullptr},
    };
    // 3. 将方法绑定到 eventObj
    napi_define_properties(
        env,
        eventObj,
        sizeof(descriptors) / sizeof(descriptors[0]),
        descriptors
    );

    // 4. 【关键】将 eventObj 挂到 parentObj 上，属性名为 "meter"
    napi_set_named_property(env, exports, "event", eventObj);
}