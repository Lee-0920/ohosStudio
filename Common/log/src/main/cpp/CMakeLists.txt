cmake_minimum_required(VERSION 3.16)
project(log)

set(NATIVERENDER_ROOT_PATH ${CMAKE_CURRENT_SOURCE_DIR})

add_library(log SHARED
    napi_init.cpp
    Log.cpp
)

target_link_libraries(log PUBLIC
    libhilog_ndk.z.so
    libace_napi.z.so
    libc++.a
)

set_target_properties(log PROPERTIES
    CXX_STANDARD 11
    CXX_STANDARD_REQUIRED ON
)

# 打印成功信息
message(STATUS "Log module CMakeLists configured successfully")