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
        CommunicationPlugin/Dscp/DscpPacket.cpp
        CommunicationPlugin/Dscp/DscpStatus.cpp
        CommunicationPlugin/eCek/Common/MessageDigest.c
        CommunicationPlugin/eCek/Common/SafeHeap.c
        CommunicationPlugin/eCek/Container/Queue.c
        CommunicationPlugin/eCek/DNCP/App/DscpController.c
        CommunicationPlugin/eCek/DNCP/App/DscpDevice.c
        CommunicationPlugin/eCek/DNCP/Base/Frame.c
        CommunicationPlugin/eCek/DNCP/Lai/LaiRS485Master.cpp
        CommunicationPlugin/eCek/DNCP/Lai/LaiSerial.cpp
        CommunicationPlugin/eCek/DNCP/Lai/LaiTcpClient.cpp
        CommunicationPlugin/eCek/DNCP/Lai/LaiTcpServer.cpp
        CommunicationPlugin/eCek/DNCP/Lai/Lai.c
        CommunicationPlugin/eCek/DNCP/Ll/Dslp.c
        CommunicationPlugin/eCek/DNCP/Ll/Ll.c
        CommunicationPlugin/eCek/DNCP/Ll/Llci.c
        CommunicationPlugin/eCek/DNCP/Net/Net.c
        CommunicationPlugin/eCek/DNCP/Net/NetPack.c
        CommunicationPlugin/eCek/DNCP/Net/Trp.c
        CommunicationPlugin/eCek/DNCP/Net/TrpTail.c
        CommunicationPlugin/eCek/DNCP/Port/OS/DscpScheduler.cpp
        CommunicationPlugin/eCek/Common/Port/Cpp11/System.cpp
        CommunicationPlugin/eCek/Tracer/Trace.c
        CommunicationPlugin/Stack/DncpMcStack.cpp
        CommunicationPlugin/Stack/DncpStack.cpp
        CommunicationPlugin/App/AsyncCall.cpp
        CommunicationPlugin/App/AsyncScheduler.cpp
        CommunicationPlugin/App/AsyncTask.cpp
        CommunicationPlugin/App/CallingQueue.cpp
        CommunicationPlugin/App/EventHandler.cpp
        CommunicationPlugin/App/SyncCaller.cpp
        CommunicationPlugin/App/CommunicationLibrary.cpp
        CommunicationPlugin/App/CommunicationException.cpp
        CommunicationPlugin/App/CommunicationProxy.cpp
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