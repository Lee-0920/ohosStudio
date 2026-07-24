/**
 * @file
 * @brief DSCP 数据包
 * @details 
 * @version 1.0.0
 * @author kim@erchashu.com
 * @date 2015/3/7
 */

#ifndef COMMUNICATION_DSCP_DSCPPACKET_H
#define COMMUNICATION_DSCP_DSCPPACKET_H

#include <memory>
#include "DscpAddress.h"

using System::Byte;
using System::Uint16;
using System::String;

namespace Communication
{
namespace Dscp
{

/**
 * @brief DSCP 数据包
 */
class DscpPacket
{
public:
    DscpAddress addr;
    Uint16 code;
    Byte* data;
    Uint16 len;

public:
    DscpPacket()
    {
        this->code = 0;
        this->data = nullptr;
        this->len = 0;
    }

    DscpPacket(DscpAddress addr, Uint16 code)
    {
        this->addr = addr;
        this->code = code;
        this->data = nullptr;
        this->len = 0;
    }

    DscpPacket(DscpAddress addr, Uint16 code, const void* data, Uint16 len)
    {
        this->addr = addr;
        this->code = code;
        if (len > 0)
        {
            this->data = new Byte[len];
            memcpy(this->data, data, len);
            this->len = len;
        }
        else
        {
            this->data = nullptr;
            this->len = 0;
        }
    }

    DscpPacket(const DscpPacket& pack)
    {
        this->addr = pack.addr;
        this->code = pack.code;
        this->len = pack.len;
        this->data = nullptr;

        if (pack.len > 0)
        {
            this->data = new Byte[pack.len];
            memcpy(this->data, pack.data, pack.len);
        }
    }

    ~DscpPacket()
    {
        if (this->data)
        {
            delete[] this->data;
            this->data = nullptr;
            this->len = 0;
        }
    }

    virtual String ToString()
    {  
        std::string addrStr = this->addr.ToString();
        int size = snprintf(nullptr, 0, "{0x%x} A[%s] L(%d)", this->code, addrStr.c_str(), this->len);
        std::string result(size, '\0');
//        snprintf(result.data(), size + 1, "{0x%x} A[%s] L(%d)", this->code, addrStr.c_str(), this->len);
        // Step 2: 分配空间（+1 为 \0）
        result.resize(size + 1);
    
        // Step 3: 安全写入
        snprintf(&result[0], size + 1, "{0x%x} A[%s] L(%d)", 
                 this->code, addrStr.c_str(), this->len);
    
        // Step 4: 截断尾部 \0（std::string 不存储它）
        result.resize(size);
        return result;
    }
};

/**
 * @brief DSCP数据包引用对象。使用引用计数器自动管理数据包对象的内存。
 */
typedef std::shared_ptr<DscpPacket> DscpPackPtr;

/**
 * @brief DSCP 数据包类型。
 */
enum class DscpType
{
    Cmd,
    RespInfo,
    RespStatus,
    Event
};

/**
 * @brief DSCP 系统命令定义。
 */
class DscpSysCmd
{
public:
    // 回声测试。
    static const Uint16 ECHO;
    // 获取接口版本。
    static const Uint16 GET_IFVER;
};


}
}

#endif  //CONTROLNET_COMMUNICATION_DSCP_DSCPPACKET_H
