//
// Created on 2026/5/27.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#ifndef LHIPSTUDIO_NAPI_VALVE_H
#define LHIPSTUDIO_NAPI_VALVE_H
#include "../ControllerManager.h"
#include <napi/native_api.h>

void RegisterValveModule(napi_env env, napi_value exports);
#endif //LHIPSTUDIO_NAPI_VALVE_H
