// lhipstudio/modbus/src/main/ets/types/napi_init.cpp

#include <cstdio>
#include <fcntl.h>
#include <unistd.h>
#include <termios.h>
#include <string.h>
#include <vector>
#include <cerrno>
#include <poll.h>
#include "napi/native_api.h"

#undef LOG_TAG
#define LOG_TAG "SerialPort"

static int uart_fd = -1;
static bool is_uart_opened = false;

// Serial port configuration structure
struct SerialConfig {
    int baudRate;
    int dataBits;
    int stopBits;
    int parity;
};

// Current serial port configuration
static SerialConfig currentConfig = {
    .baudRate = 9600,
    .dataBits = 8,
    .stopBits = 1,
    .parity = 0
};

// Baud rate conversion
static speed_t getBaudRate(int baudRate) {
    switch (baudRate) {
        case 4800: return B4800;
        case 9600: return B9600;
        case 19200: return B19200;
        case 38400: return B38400;
        case 57600: return B57600;
        case 115200: return B115200;
        default: return B9600;
    }
}

// Configure serial port parameters
static bool configureUart(int fd, const SerialConfig& config) {
    struct termios options;
    if (tcgetattr(fd, &options) != 0) {
        return false;
    }

    // Set to raw mode
    cfmakeraw(&options);
    
    // Set baud rate
    speed_t baudRate = getBaudRate(config.baudRate);
    cfsetispeed(&options, baudRate);
    cfsetospeed(&options, baudRate);
    
    // Set data bits
    options.c_cflag &= ~CSIZE;
    switch (config.dataBits) {
        case 5: options.c_cflag |= CS5; break;
        case 6: options.c_cflag |= CS6; break;
        case 7: options.c_cflag |= CS7; break;
        case 8: options.c_cflag |= CS8; break;
        default: options.c_cflag |= CS8; break;
    }
    
    // Set stop bits
    if (config.stopBits == 2) {
        options.c_cflag |= CSTOPB;
    } else {
        options.c_cflag &= ~CSTOPB;
    }
    
    // Set parity
    if (config.parity == 1) {  // Odd parity
        options.c_cflag |= PARENB;
        options.c_cflag |= PARODD;
    } else if (config.parity == 2) {  // Even parity
        options.c_cflag |= PARENB;
        options.c_cflag &= ~PARODD;
    } else {  // No parity
        options.c_cflag &= ~PARENB;
    }
    
    // Enable receiver, ignore modem control lines
    options.c_cflag |= (CLOCAL | CREAD);
    
    // Set input mode: no special character processing, no parity checking
    options.c_iflag = 0;
    
    // Set output mode: raw output
    options.c_oflag = 0;
    
    // Set control characters
    options.c_cc[VTIME] = 10;  // Read timeout 1 second (10 * 100ms)
    options.c_cc[VMIN] = 0;    // Non-blocking read
    
    // Flush input and output buffers
    tcflush(fd, TCIOFLUSH);
    
    // Apply settings
    if (tcsetattr(fd, TCSANOW, &options) != 0) {
        return false;
    }
    return true;
}

// Open serial port (supports specifying path)
static napi_value OpenUart(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    char devicePath[128] = "/dev/ttyS0";  // Default path
    
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    // If parameter is provided, use the specified device path
    if (argc >= 1) {
        size_t pathLen = 0;
        napi_get_value_string_utf8(env, args[0], devicePath, sizeof(devicePath) - 1, &pathLen);
    }
    
    // If already open, close first
    if (uart_fd >= 0) {
        close(uart_fd);
        uart_fd = -1;
    }
    
    // Open serial port
    uart_fd = open(devicePath, O_RDWR | O_NOCTTY | O_NDELAY);
    if (uart_fd < 0) {
        napi_value result;
        napi_get_boolean(env, false, &result);
        return result;
    }
    
    // Set to non-blocking mode
    fcntl(uart_fd, F_SETFL, O_NONBLOCK);
    
    // Configure serial port parameters
    if (!configureUart(uart_fd, currentConfig)) {
        close(uart_fd);
        uart_fd = -1;
        napi_value result;
        napi_get_boolean(env, false, &result);
        return result;
    }
    
    is_uart_opened = true;
    
    napi_value result;
    napi_get_boolean(env, true, &result);
    return result;
}

// Close serial port
static napi_value CloseUart(napi_env env, napi_callback_info info) {
    if (uart_fd >= 0) {
        close(uart_fd);
        uart_fd = -1;
    }
    is_uart_opened = false;
    return nullptr;
}

// Write data to serial port (single write call + tcdrain to wait for transmission complete)
static ssize_t writeAll(int fd, const uint8_t* data, size_t count) {
    ssize_t n = write(fd, data, count);
    if (n > 0) {
        // Wait for all data to be sent
        tcdrain(fd);
    }
    return n;
}

// Write to serial port (supports binary data)
static napi_value WriteUart(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    if (uart_fd < 0) {
        napi_value result;
        napi_get_boolean(env, false, &result);
        return result;
    }
    
    // Check parameter type
    napi_valuetype type;
    napi_typeof(env, args[0], &type);
    
    ssize_t written = 0;
    size_t requested = 0;
    
    if (type == napi_string) {
        // String type
        char data[1024] = {0};
        size_t len = 0;
        napi_get_value_string_utf8(env, args[0], data, sizeof(data) - 1, &len);
        requested = len;
        written = writeAll(uart_fd, reinterpret_cast<uint8_t*>(data), len);
    } else if (type == napi_object) {
        // Check if ArrayBuffer or Uint8Array
        bool isArrayBuffer = false;
        napi_is_arraybuffer(env, args[0], &isArrayBuffer);
        
        if (isArrayBuffer) {
            void* data = nullptr;
            size_t dataLen = 0;
            napi_get_arraybuffer_info(env, args[0], &data, &dataLen);
            if (data != nullptr && dataLen > 0) {
                requested = dataLen;
                written = writeAll(uart_fd, static_cast<uint8_t*>(data), dataLen);
            }
        } else {
            // Try to handle as Uint8Array
            napi_value buffer;
            napi_get_named_property(env, args[0], "buffer", &buffer);
            void* data = nullptr;
            size_t dataLen = 0;
            napi_get_arraybuffer_info(env, buffer, &data, &dataLen);
            
            if (data != nullptr && dataLen > 0) {
                napi_value offsetVal;
                napi_get_named_property(env, args[0], "byteOffset", &offsetVal);
                uint32_t offset = 0;
                napi_get_value_uint32(env, offsetVal, &offset);
                
                napi_value lengthVal;
                napi_get_named_property(env, args[0], "byteLength", &lengthVal);
                uint32_t length = 0;
                napi_get_value_uint32(env, lengthVal, &length);
                
                if (offset + length <= dataLen) {
                    requested = length;
                    written = writeAll(uart_fd, static_cast<uint8_t*>(data) + offset, length);
                }
            }
        }
    }
    napi_value result;
    napi_get_boolean(env, written > 0, &result);
    return result;
}

// Read serial port (returns ArrayBuffer)
static napi_value ReadUartBinary(napi_env env, napi_callback_info info) {
    if (uart_fd < 0) {
        napi_value result;
        napi_create_arraybuffer(env, 0, nullptr, &result);
        return result;
    }
    
    // Read data
    uint8_t buffer[2048] = {0};
    ssize_t n = read(uart_fd, buffer, sizeof(buffer));
    // Print read data (hexadecimal)
    if (n > 0) {
        char hexBuf[4096] = {0};
        int offset = 0;
        for (int i = 0; i < n && offset < (int)sizeof(hexBuf) - 3; i++) {
            offset += sprintf(hexBuf + offset, "%02X ", buffer[i]);
        }
    }
    
    // Create ArrayBuffer to return
    napi_value result;
    void* data = nullptr;
    napi_create_arraybuffer(env, n > 0 ? n : 0, &data, &result);
    
    if (n > 0 && data != nullptr) {
        memcpy(data, buffer, n);
    }
    
    return result;
}

// Read serial port (returns Base64 encoded string - compatible with old interface)
static napi_value ReadUartBase64(napi_env env, napi_callback_info info) {
    if (uart_fd < 0) {
        napi_value result;
        napi_create_string_utf8(env, "", NAPI_AUTO_LENGTH, &result);
        return result;
    }
    
    // Read data
    uint8_t buffer[2048] = {0};
    ssize_t n = read(uart_fd, buffer, sizeof(buffer));
    if (n <= 0) {
        napi_value result;
        napi_create_string_utf8(env, "", NAPI_AUTO_LENGTH, &result);
        return result;
    }
    
    // Base64 encoding table
    static const char* base64_chars = 
        "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        "abcdefghijklmnopqrstuvwxyz"
        "0123456789+/";
    
    // Calculate Base64 length
    size_t outLen = ((n + 2) / 3) * 4;
    std::vector<char> base64(outLen + 1, 0);
    
    // Base64 encoding
    for (size_t i = 0, j = 0; i < n;) {
        uint32_t octet_a = i < n ? buffer[i++] : 0;
        uint32_t octet_b = i < n ? buffer[i++] : 0;
        uint32_t octet_c = i < n ? buffer[i++] : 0;
        
        uint32_t triple = (octet_a << 16) | (octet_b << 8) | octet_c;
        
        base64[j++] = base64_chars[(triple >> 18) & 0x3F];
        base64[j++] = base64_chars[(triple >> 12) & 0x3F];
        base64[j++] = base64_chars[(triple >> 6) & 0x3F];
        base64[j++] = base64_chars[triple & 0x3F];
    }
    
    // Handle padding
    size_t mod = n % 3;
    if (mod == 1) {
        base64[outLen - 2] = '=';
        base64[outLen - 1] = '=';
    } else if (mod == 2) {
        base64[outLen - 1] = '=';
    }
    
    napi_value result;
    napi_create_string_utf8(env, base64.data(), outLen, &result);
    return result;
}

// Set serial port parameters
static napi_value SetSerialConfig(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    if (argc < 1) {
        napi_value result;
        napi_get_boolean(env, false, &result);
        return result;
    }
    
    // Get configuration object
    napi_value baudRateVal, dataBitsVal, stopBitsVal, parityVal;
    napi_get_named_property(env, args[0], "baudRate", &baudRateVal);
    napi_get_named_property(env, args[0], "dataBits", &dataBitsVal);
    napi_get_named_property(env, args[0], "stopBits", &stopBitsVal);
    napi_get_named_property(env, args[0], "parity", &parityVal);
    
    napi_get_value_int32(env, baudRateVal, &currentConfig.baudRate);
    napi_get_value_int32(env, dataBitsVal, &currentConfig.dataBits);
    napi_get_value_int32(env, stopBitsVal, &currentConfig.stopBits);
    napi_get_value_int32(env, parityVal, &currentConfig.parity);
    
    // If serial port is already open, reconfigure
    if (uart_fd >= 0) {
        bool success = configureUart(uart_fd, currentConfig);
        napi_value result;
        napi_get_boolean(env, success, &result);
        return result;
    }
    
    napi_value result;
    napi_get_boolean(env, true, &result);
    return result;
}

// Clear serial port buffer
static napi_value FlushUart(napi_env env, napi_callback_info info) {
    if (uart_fd >= 0) {
        // Wait for all data to be sent, then clear receive buffer
        tcdrain(uart_fd);
        tcflush(uart_fd, TCIFLUSH);
        napi_value result;
        napi_get_boolean(env, true, &result);
        return result;
    }
    napi_value result;
    napi_get_boolean(env, false, &result);
    return result;
}

// Get serial port status
static napi_value GetUartStatus(napi_env env, napi_callback_info info) {
    napi_value result;
    napi_create_object(env, &result);
    
    napi_value opened;
    napi_get_boolean(env, uart_fd >= 0, &opened);
    napi_set_named_property(env, result, "isOpened", opened);
    
    napi_value fd;
    napi_create_int32(env, uart_fd, &fd);
    napi_set_named_property(env, result, "fd", fd);
    
    return result;
}

// Module initialization
static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        // Original interface (keep compatible)
        {"openUart", nullptr, OpenUart, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"writeUart", nullptr, WriteUart, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"readUart", nullptr, ReadUartBase64, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"closeUart", nullptr, CloseUart, nullptr, nullptr, nullptr, napi_default, nullptr},
        
        // New interface
        {"readUartBinary", nullptr, ReadUartBinary, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setSerialConfig", nullptr, SetSerialConfig, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"flushUart", nullptr, FlushUart, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getUartStatus", nullptr, GetUartStatus, nullptr, nullptr, nullptr, napi_default, nullptr}
    };
    
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}

// Register module
extern "C" __attribute__((constructor)) void RegisterUartModule(void) {
    napi_module module = {
        .nm_version = 1,
        .nm_flags = 0,
        .nm_filename = nullptr,
        .nm_register_func = Init,
        .nm_modname = "entry",
    };
    napi_module_register(&module);
}
