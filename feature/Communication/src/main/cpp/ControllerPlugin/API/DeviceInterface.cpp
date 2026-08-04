/**
 * @file
 * @brief 设备操作接口。
 * @details 
 * @version 1.0.0
 * @author kim@erchashu.com
 * @date 2015/3/7
 */

#include "CommunicationPlugin/App/SyncCaller.h"
#include "CommunicationPlugin/App/CommunicationException.h"
#include "CommunicationPlugin/Dscp/DscpStatus.h"
#include "CommunicationPlugin/eCek/DNCP/App/DscpSysDefine.h"
#include "UpdatableInfo.h"
#include "DeviceInterface.h"
#include "hilog/log.h"
#undef LOG_DOMAIN
#undef LOG_TAG
#define LOG_DOMAIN 0x3200  // 全局domain宏，标识业务领域
#define LOG_TAG "MY_TAG"   // 全局tag宏，标识模块日志tag

using namespace Communication;
using namespace Communication::Dscp;

namespace Controller
{
namespace API
{

/**
 * @brief 设备接口构造。
 *
 */
DeviceInterface::DeviceInterface()
    : m_addr(1, 1)
{
    m_timeout = 0;
    m_info = nullptr;
    m_retries = 3;
}

/**
 * @brief 设备接口构造。
 * @param[in] addr 设备地址。
 *
 */
DeviceInterface::DeviceInterface(DscpAddress addr)
{
    m_timeout = 0;
    m_addr = addr;
    m_info = nullptr;
    m_retries = 3;
}

/**
 * @brief 设备接口构造。
 * @param[in] addr 设备地址。
 * @param[in] retries 通信超时/错误重试次数。
 *
 */
DeviceInterface::DeviceInterface(DscpAddress addr,int retries)
{
    m_timeout = 0;
    m_addr = addr;
    m_info = nullptr;
    m_retries = retries;
}

/**
 * @brief 设备接口构造。
 * @param[in] addr 设备地址。
 * @param[in] info 可更新的信息对象，由客户代码管理内存。
 */
DeviceInterface::DeviceInterface(DscpAddress addr, UpdatableInfo* info)
{
    m_timeout = 0;
    m_addr = addr;
    m_info = info;
    m_retries = 3;
}

/**
 * @brief 设备接口析构。
 */
DeviceInterface::~DeviceInterface()
{
}

/**
 * @brief 获取设备地址。
 * @return 设备地址。
 */
DscpAddress DeviceInterface::GetAddress()
{
    OH_LOG_INFO(LOG_APP, "DeviceInterface::GetAddress");
    return m_addr;
}

/**
 * @brief 设置设备地址。
 * @param[in] addr 设备地址。
 */
void DeviceInterface::SetAddress(DscpAddress addr)
{
    m_addr = addr;
}

/**
 * @brief 获取同步调用的超时时间。
 * @return 超时时间。
 * @note 系统暂时未使用该参数。
 */
int DeviceInterface::GetTimeout()
{
    return m_timeout;
}

/**
 * @brief 设置同步调用的超时时间。
 * @param[in] ms 超时时间。
 * @note 系统暂时未使用该参数。
 */
void DeviceInterface::SetTimeout(int ms)
{
    m_timeout = ms;
}

/**
 * @brief 获取设备通信超时/错误重试次数。
 * @return 重试次数。
 */
int DeviceInterface::GetRetries()
{
    return m_retries;
}

/**
 * @brief 设置设备超时/错误重试次数。
 * @param[in] retries 重试次数。
 */
void DeviceInterface::SetRetries(int retries)
{
    m_retries = retries;
}

/**
 * @brief 设备更新的信息对象。
 * @param[in] info 可更新的信息对象，由客户代码管理内存。
 */
void DeviceInterface::SetUpdatableInfo(UpdatableInfo* info)
{
    (void)info;
}

DscpEventPtr DeviceInterface::Expect(int code, int timeout)
{
    DscpEventPtr event = nullptr;
    try
    {
        event = EventHandler::Instance()->Expect(m_addr,code,timeout);
    }
    catch(ExpectEventTimeoutException e)
    {
        OH_LOG_ERROR(LOG_APP, "重获事件 {addr = %{public}s, code = %{public}X}",
                e.m_addr.ToString().c_str(),
                e.m_code);
         try {
            Uint16 status = DscpStatus::Error;

            DscpCmdPtr cmd(new DscpCommand(m_addr, DSCP_SYSCMD_ACQUIRE_EVENT));
            SyncCaller syncCaller(m_retries);
            status = syncCaller.SendWithStatus(cmd);
    
            OH_LOG_ERROR(LOG_APP, "重获命令应答：%{public}d", status);
    
            if(status == DscpStatus::OK)
            {
                try {
                    event = EventHandler::Instance()->Expect(m_addr, code, 6000);
                } catch (ExpectEventTimeoutException e) {
                    OH_LOG_ERROR(LOG_APP, "重获事件 {addr = %{public}s, code = %{public}X}",
                            e.m_addr.ToString().c_str(),
                            e.m_code);
                    // 吞掉异常，返回 nullptr，绝不让异常逃逸出 DeviceInterface::Expect
                }
            }
            else
            {
                OH_LOG_ERROR(LOG_APP, "ExpectEventTimeoutException：重获命令应答无效");
                //因为catch的时候调用异常的拷贝函数，LUA与C++的交互栈已经没有异常类，需要重新定义异常然后抛出
                // 吞掉异常，返回 nullptr，绝不让异常逃逸出 DeviceInterface::Expect
                throw ExpectEventTimeoutException(e.m_addr, e.m_code);
            }
         } catch (ExpectEventTimeoutException e) {
            OH_LOG_ERROR(LOG_APP, "重获事件 {addr = %{public}s, code = %{public}X}",
                    e.m_addr.ToString().c_str(),
                    e.m_code);
            // 吞掉异常，返回 nullptr，绝不让异常逃逸出 DeviceInterface::Expect
            throw ExpectEventTimeoutException(e.m_addr, e.m_code);
        }
    }

    return event;
}

}
}
