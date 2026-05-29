//
// Created on 2026/5/26.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#ifndef LHIPSTUDIO_CONTROLLERMANAGER_H
#define LHIPSTUDIO_CONTROLLERMANAGER_H

#include <mutex>
#include <map>
#include <memory>
#include <iostream>
#include <memory>
#include "PT63DriveControllerPlugin/PT63DriveControllerPlugin.h"
#include "PT63DriveControllerPlugin/PT63DriveController.h"
class PT63DriveController; // 前向声明或包含完整定义

// 👇 声明：g_controller 在别处定义
extern std::unique_ptr<Controller::PT63DriveController> g_controller;
// 👇 声明：g_mutex 在别处定义
extern std::mutex g_mutex;

#endif //LHIPSTUDIO_CONTROLLERMANAGER_H
