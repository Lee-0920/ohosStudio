# lhipstudio/modbus/src/main/ets/types/CMakeLists.txt

cmake_minimum_required(VERSION 3.5.0)
project(Serial)

set(NATIVERENDER_ROOT_PATH ${CMAKE_CURRENT_SOURCE_DIR})

if(DEFINED PACKAGE_FIND_FILE)
    include(${PACKAGE_FIND_FILE})
endif()

include_directories(${NATIVERENDER_ROOT_PATH}
                    ${NATIVERENDER_ROOT_PATH}/include)

add_library(entry SHARED napi_init.cpp)

# 链接库
target_link_libraries(entry PUBLIC
    libace_napi.z.so
    libhilog_ndk.z.so
)

# 输出到正确目录
set(OUTPUT_PATH ${CMAKE_CURRENT_SOURCE_DIR}/../../../libs/${OHOS_ARCH})
file(MAKE_DIRECTORY ${OUTPUT_PATH})
add_custom_command(TARGET entry POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy
        $<TARGET_FILE:entry>
        ${OUTPUT_PATH}/$<TARGET_FILE_NAME:entry>
)