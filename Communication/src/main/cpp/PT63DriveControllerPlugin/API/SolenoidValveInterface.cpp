/**

 * @file
 * @brief 电磁阀控制接口。
 * @details
 * @version 1.0.0
 * @author kim@erchashu.com
 * @date 2015/3/7
 */

#include "Code/SolenoidValveInterface.h"
#include "Code/OpticalAcquireInterface.h"
#include "Dscp/DscpStatus.h"
#include "App/SyncCaller.h"
#include "App/EventHandler.h"
#include "SolenoidValveInterface.h"
#include "hilog/log.h"
#undef LOG_DOMAIN
#undef LOG_TAG
#define LOG_DOMAIN 0x3200  // 全局domain宏，标识业务领域
#define LOG_TAG "MY_TAG"   // 全局tag宏，标识模块日志tag
using namespace std;
using namespace Communication;
using namespace Communication::Dscp;
using namespace System;

namespace Controller
{
namespace API
{

/**
 * @brief 电磁阀控制接口构造。
 * @param[in] addr 设备地址。
 */
SolenoidValveInterface::SolenoidValveInterface(DscpAddress addr)
    : DeviceInterface(addr)
{

}

/**
 * @brief 查询系统支持的总电磁阀数目。
 * @return 总电磁阀数目， Uint16。
 */
int SolenoidValveInterface::GetTotalValves()
{
    int totalValves = 0;

    DscpCmdPtr cmd(new DscpCommand(m_addr, DSCP_CMD_SVI_GET_TOTAL_VALVES));
    SyncCaller  syncCaller(m_retries);
    DscpRespPtr resp = syncCaller.Send(cmd);
    if (resp)
    {
        totalValves = *((Uint16*)resp->data);
    }

    return totalValves;
}

/**
 * @brief 查询当前开启的阀门映射图。
 * @return 通道映射图，Uint32，每位表示一个通道的开关状态，1为打开，0为闭合，低位开始。
 */
ValveMap SolenoidValveInterface::GetValveMap()
{
    ValveMap map(0);

    DscpCmdPtr cmd(new DscpCommand(m_addr, DSCP_CMD_SVI_GET_VALVE_MAP));
    SyncCaller syncCaller(m_retries);
    DscpRespPtr resp = syncCaller.Send(cmd);
    if (resp)
    {
        map.SetData(*((Uint32*)resp->data));
    }

    return map;
}

/**
 * @brief 设置要开启的阀门映射图。
 * @param map Uint32，通道映射图，每位表示一个通道的开关状态，1为打开，0为闭合，低位开始。
* @return 返回状态，操作是否成功。
 */
bool SolenoidValveInterface::SetValveMap(ValveMap map)
{
    Uint16 status = DscpStatus::Error;
    Uint32 mapVal = map.GetData();
    OH_LOG_INFO(LOG_APP, "SetValveMap %{public}d", mapVal);
    DscpCmdPtr cmd(new DscpCommand(m_addr, DSCP_CMD_SVI_SET_VALVE_MAP, &mapVal, sizeof(mapVal)));
    SyncCaller syncCaller(m_retries);
    status = syncCaller.SendWithStatus(cmd);
    return (status == DscpStatus::OK);
}
bool SolenoidValveInterface::SetValve16(Uint8 isOpen)
{
    Uint16 status = DscpStatus::Error;
    Uint8 mapVal = isOpen;

    DscpCmdPtr cmd(new DscpCommand(m_addr, DSCP_CMD_SVI_SET_VALVE16, &mapVal, sizeof(mapVal)));
    SyncCaller syncCaller(m_retries);
    status = syncCaller.SendWithStatus(cmd);
    return (status == DscpStatus::OK);
}

/**
 * @brief 设置要开启的阀门映射图。
 * @param map Uint32，通道映射图，每位表示一个通道的开关状态，1为打开，0为闭合，低位开始。
* @return 返回状态，操作是否成功。
 */
bool SolenoidValveInterface::CtrlSpinValve(ValveMap map)
{
    Uint16 status = DscpStatus::Error;
    Uint8 cmdData[3] = {0};
    cmdData[0] = map.GetCmd();
    cmdData[1] = map.GetParam1();
    cmdData[2] = map.GetParam2();
    OH_LOG_INFO(LOG_APP, "CtrlSpinValve [%{public}d][%{public}d][%{public}d]", cmdData[0], cmdData[1], cmdData[2]);
    DscpCmdPtr cmd(new DscpCommand(m_addr, DSCP_CMD_SVI_CTL_SPINVALVE, cmdData, sizeof(cmdData)));
    SyncCaller syncCaller(m_retries);
    status = syncCaller.SendWithStatus(cmd);
    return (status == DscpStatus::OK);
}

/**
 * @brief 设置漏液检测信号上报周期
 * @param Period Float 单位秒。
 * @return 状态回应，Uint16，支持的状态有：
 *  - @ref DSCP_OK  操作成功；
 *  - @ref DSCP_ERROR 操作失败；
 */
bool SolenoidValveInterface::SetCheckLeakingPeriod(float period)
{
    Uint16 status = DscpStatus::Error;

    DscpCmdPtr cmd(new DscpCommand(m_addr, DSCP_CMD_OAI_SET_CHECK_LEAKING_PERIOD, &period, sizeof(period)));
    SyncCaller syncCaller(m_retries);
    status = syncCaller.SendWithStatus(cmd);
    return (status == DscpStatus::OK);
}
}
}
