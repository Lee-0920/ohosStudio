#include "napi/native_api.h"
#include "Log.h"
#include <hilog/log.h>
#include <string>

#undef LOG_DOMAIN
#undef LOG_TAG
#define LOG_DOMAIN 0x3200
#define LOG_TAG "LogNAPI"

static std::string GetStringFromNAPI(napi_env env, napi_value value) {
    size_t strSize = 0;
    napi_get_value_string_utf8(env, value, nullptr, 0, &strSize);
    char* buffer = new char[strSize + 1];
    size_t written = 0;
    napi_get_value_string_utf8(env, value, buffer, strSize + 1, &written);
    std::string result(buffer, written);
    delete[] buffer;
    return result;
}

// ========== 基础日志函数 ==========

static napi_value NAPI_Init(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    if (argc >= 1) {
        std::string absolutePath = GetStringFromNAPI(env, args[0]);
        OH_LOG_INFO(LOG_APP, "argc >= 1");
        Logger::GetInstance()->Init(absolutePath);
    }
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

static napi_value NAPI_Debug(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    if (argc >= 1) {
        std::string msg = GetStringFromNAPI(env, args[0]);
        Logger::GetInstance()->Debug( msg);
    }
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

static napi_value NAPI_Info(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    if (argc >= 1) {
        std::string msg = GetStringFromNAPI(env, args[0]);
        Logger::GetInstance()->Info(msg);
    }
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

static napi_value NAPI_Warn(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    if (argc >= 1) {
        std::string msg = GetStringFromNAPI(env, args[0]);
        Logger::GetInstance()->Warn(msg);
    }
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

static napi_value NAPI_Error(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    if (argc >= 1) {
        std::string msg = GetStringFromNAPI(env, args[0]);
        Logger::GetInstance()->Error(msg);
    }
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

static napi_value NAPI_GetLogDir(napi_env env, napi_callback_info info) {
    std::string logDir = Logger::GetLogDir();
    napi_value result;
    napi_create_string_utf8(env, logDir.c_str(), logDir.length(), &result);
    return result;
}

static napi_value NAPI_Flush(napi_env env, napi_callback_info info) {
    Logger::GetInstance()->Flush();
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

// ========== 日志回读函数 ==========

static napi_value NAPI_ReadRecentLogs(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    std::string name;
    int lines = 100;
    if (argc >= 1) {
        name = GetStringFromNAPI(env, args[0]);
        napi_get_value_int32(env, args[0], &lines);
    }
    
    std::string content = Logger::GetInstance()->ReadRecentLogs(lines);
    napi_value result;
    napi_create_string_utf8(env, content.c_str(), content.length(), &result);
    return result;
}

static napi_value NAPI_ReadLogsFromFile(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    if (argc < 1) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    std::string fileName = GetStringFromNAPI(env, args[0]);
    int lines = 100;
    if (argc >= 2) {
        napi_get_value_int32(env, args[1], &lines);
    }
    
    std::string content = Logger::GetInstance()->ReadLogsFromFile(fileName, lines);
    napi_value result;
    napi_create_string_utf8(env, content.c_str(), content.length(), &result);
    return result;
}

static napi_value NAPI_ReadAllLogs(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    if (argc < 1) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    std::string fileName = GetStringFromNAPI(env, args[0]);
    std::string content = Logger::GetInstance()->ReadAllLogs(fileName);
    napi_value result;
    napi_create_string_utf8(env, content.c_str(), content.length(), &result);
    return result;
}

static napi_value NAPI_GetAllLogFilesInfo(napi_env env, napi_callback_info info) {
    std::vector<Logger::LogFileInfo> infos = Logger::GetInstance()->GetAllLogFilesInfo();
    
    napi_value result;
    napi_create_array(env, &result);
    
    int index = 0;
    for (const auto& info : infos) {
        napi_value item;
        napi_create_object(env, &item);
        
        napi_value fileName;
        napi_create_string_utf8(env, info.fileName.c_str(), info.fileName.length(), &fileName);
        napi_set_named_property(env, item, "fileName", fileName);
        
        napi_value fileSize;
        napi_create_int64(env, info.fileSize, &fileSize);
        napi_set_named_property(env, item, "fileSize", fileSize);
        
        napi_value lineCount;
        napi_create_int32(env, info.lineCount, &lineCount);
        napi_set_named_property(env, item, "lineCount", lineCount);
        
        napi_value lastModified;
        napi_create_string_utf8(env, info.lastModified.c_str(), info.lastModified.length(), &lastModified);
        napi_set_named_property(env, item, "lastModified", lastModified);
        
        napi_set_element(env, result, index++, item);
    }
    
    return result;
}

static napi_value NAPI_ClearLogFile(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    if (argc < 1) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    std::string fileName = GetStringFromNAPI(env, args[0]);
    bool success = Logger::GetInstance()->ClearLogFile(fileName);
    
    napi_value result;
    napi_get_boolean(env, success, &result);
    return result;
}

static napi_value NAPI_DeleteLogFile(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    if (argc < 1) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    std::string fileName = GetStringFromNAPI(env, args[0]);
    bool success = Logger::GetInstance()->DeleteLogFile(fileName);
    
    napi_value result;
    napi_get_boolean(env, success, &result);
    return result;
}

// ========== 模块注册 ==========

static napi_value ModuleInit(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        // 基础功能
        {"init", nullptr, NAPI_Init, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"debug", nullptr, NAPI_Debug, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"info", nullptr, NAPI_Info, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"warn", nullptr, NAPI_Warn, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"error", nullptr, NAPI_Error, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getLogDir", nullptr, NAPI_GetLogDir, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"flush", nullptr, NAPI_Flush, nullptr, nullptr, nullptr, napi_default, nullptr},
        // 日志回读功能
        {"readRecentLogs", nullptr, NAPI_ReadRecentLogs, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"readLogsFromFile", nullptr, NAPI_ReadLogsFromFile, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"readAllLogs", nullptr, NAPI_ReadAllLogs, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getAllLogFilesInfo", nullptr, NAPI_GetAllLogFilesInfo, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"clearLogFile", nullptr, NAPI_ClearLogFile, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"deleteLogFile", nullptr, NAPI_DeleteLogFile, nullptr, nullptr, nullptr, napi_default, nullptr},
    };
    napi_define_properties(env, exports, sizeof(desc)/sizeof(desc[0]), desc);
    return exports;
}

static napi_module logModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = ModuleInit,
    .nm_modname = "log",
    .nm_priv = nullptr,
    .reserved = {0},
};

extern "C" __attribute__((constructor)) void RegisterLogModule(void) {
    napi_module_register(&logModule);
}