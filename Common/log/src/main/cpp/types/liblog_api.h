#ifndef LIBLOG_API_H
#define LIBLOG_API_H

#include "napi/native_api.h"

// 日志级别枚举（供 ArkTS 使用）
typedef enum {
    LOG_LEVEL_DEBUG = 0,
    LOG_LEVEL_INFO = 1,
    LOG_LEVEL_WARN = 2,
    LOG_LEVEL_ERROR = 3
} LogLevel;

// NAPI 函数声明
napi_value NAPI_LogInit(napi_env env, napi_callback_info info);
napi_value NAPI_LogDebug(napi_env env, napi_callback_info info);
napi_value NAPI_LogInfo(napi_env env, napi_callback_info info);
napi_value NAPI_LogWarn(napi_env env, napi_callback_info info);
napi_value NAPI_LogError(napi_env env, napi_callback_info info);
napi_value NAPI_LogGetDir(napi_env env, napi_callback_info info);
napi_value NAPI_LogFlush(napi_env env, napi_callback_info info);

#endif // LIBLOG_API_H