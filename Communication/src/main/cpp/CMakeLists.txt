# the minimum version of CMake.
cmake_minimum_required(VERSION 3.5.0)
project(myNpmLib LANGUAGES C CXX)

set(CMAKE_C_STANDARD 99)      # 启用 C99 标准
set(CMAKE_CXX_STANDARD 17)
set(NATIVERENDER_ROOT_PATH ${CMAKE_CURRENT_SOURCE_DIR})

if(DEFINED PACKAGE_FIND_FILE)
    include(${PACKAGE_FIND_FILE})
endif()

include_directories(${NATIVERENDER_ROOT_PATH})

add_library(communication SHARED
        Dscp/DscpPacket.cpp
        Dscp/DscpStatus.cpp
        eCek/Common/MessageDigest.c
        eCek/Common/SafeHeap.c
        eCek/Container/Queue.c
        eCek/DNCP/App/DscpController.c
        eCek/DNCP/App/DscpDevice.c
        eCek/DNCP/Base/Frame.c
        eCek/DNCP/Lai/LaiRS485Master.cpp
        eCek/DNCP/Lai/LaiSerial.cpp
        eCek/DNCP/Lai/LaiTcpClient.cpp
        eCek/DNCP/Lai/LaiTcpServer.cpp
        eCek/DNCP/Lai/Lai.c
        eCek/DNCP/Ll/Dslp.c
        eCek/DNCP/Ll/Ll.c
        eCek/DNCP/Ll/Llci.c
        eCek/DNCP/Net/Net.c
        eCek/DNCP/Net/NetPack.c
        eCek/DNCP/Net/Trp.c
        eCek/DNCP/Net/TrpTail.c
        eCek/DNCP/Port/OS/DscpScheduler.cpp
        eCek/Common/Port/Cpp11/System.cpp
        eCek/Tracer/Trace.c
        Stack/DncpMcStack.cpp
        Stack/DncpStack.cpp
        App/AsyncCall.cpp
        App/AsyncScheduler.cpp
        App/AsyncTask.cpp
        App/CallingQueue.cpp
        App/EventHandler.cpp
        App/SyncCaller.cpp
        App/CommunicationLibrary.cpp
        App/CommunicationException.cpp
        App/CommunicationProxy.cpp
        ControllerPlugin/API/DeviceInfoInterface.cpp
        ControllerPlugin/API/DeviceStatusInterface.cpp
        ControllerPlugin/API/DeviceUpdateInterface.cpp
        ControllerPlugin/API/DscpSystemInterface.cpp
        ControllerPlugin/API/DeviceInterface.cpp
        ControllerPlugin/API/Version.cpp
        ControllerPlugin/API/UpdatableInfo.cpp
        ControllerPlugin/API/ManufDate.cpp
        ControllerPlugin/ControllerPlugin.cpp
        ControllerPlugin/BaseController.cpp
        ControllerPlugin/API/InstrumentInfoInterface.cpp
        PT63DriveControllerplugin/PT63DriveControllerplugin.cpp
        PT63DriveControllerplugin/PT63DriveController.cpp
        PT63DriveControllerplugin/API/PeristalticPumpInterface.cpp
        PT63DriveControllerplugin/API/TemperatureControlInterface.cpp
        PT63DriveControllerplugin/API/SolenoidValveInterface.cpp
        PT63DriveControllerplugin/API/ValveMap.cpp
        PT63DriveControllerplugin/API/MeterPoints.cpp
        PT63DriveControllerplugin/API/OpticalMeterInterface.cpp
        PT63DriveControllerplugin/API/OpticalAcquireInterface.cpp
        PT63DriveControllerplugin/API/ExtOpticalAcquireInterface.cpp
        PT63DriveControllerplugin/API/ExtTemperatureControlInterface.cpp
        NAPI/ControllerManager.h
        NAPI/Module/napi_dncp.cpp
        NAPI/Module/napi_dncp.h
        NAPI/Module/napi_pump.cpp
        NAPI/Module/napi_pump.h
        NAPI/napi_communicationlibrary.cpp
        NAPI/Module/napi_valve.h
        NAPI/Module/napi_valve.cpp
        NAPI/Module/napi_valveMap.h
        NAPI/Module/napi_valveMap.cpp
        NAPI/Module/napi_temp.h
        NAPI/Module/napi_temp.cpp
        NAPI/Module/napi_meter.h
        NAPI/Module/napi_meter.cpp
        NAPI/Module/napi_meterPoints.h
        NAPI/Module/napi_meterPoints.cpp
        NAPI/Module/napi_optical.h
        NAPI/Module/napi_optical.cpp
        NAPI/Module/napi_event.h
        NAPI/Module/napi_event.cpp)
target_link_libraries(communication PUBLIC libace_napi.z.so c++ libhilog_ndk.z.so)