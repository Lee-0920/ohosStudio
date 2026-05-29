/**
 * @file
 * @brief 驱动控制器。
 * @details
 * @version 1.0.0
 * @author kim@erchashu.com
 * @date 2016/5/13
 */

//#include <QTime>
//#include <QThread>
//#include <QDebug>
//#include <QCoreApplication>
//#include "Log.h"
#include "PT63DriveController.h"
#include "API/Code/OpticalMeterInterface.h"
#include "API/Code/TemperatureControlInterface.h"
#include "API/Code/PeristalticPumpInterface.h"
#include "API/Code/OpticalAcquireInterface.h"
#include "App/EventHandler.h"
#include "App/CommunicationException.h"
#include "hilog/log.h"
#undef LOG_DOMAIN
#undef LOG_TAG
#define LOG_DOMAIN 0x3200  // 全局domain宏，标识业务领域
#define LOG_TAG "MY_TAG"   // 全局tag宏，标识模块日志tag


using namespace std;
using namespace Communication;
using namespace Communication::Dscp;

using namespace std;
using namespace Communication;
using namespace Communication::Dscp;

napi_threadsafe_function Controller::PT63DriveController::g_tsfn = nullptr;

namespace Controller
{
/**
 * @brief 驱动控制器构造。
 */
PT63DriveController::PT63DriveController(DscpAddress addr)
    : BaseController(addr),
    IPeristalticPump(new PeristalticPumpInterface(addr)),
    ISolenoidValve(new SolenoidValveInterface(addr)),
    IOpticalMeter(new OpticalMeterInterface(addr)),
    ITemperatureControl(new TemperatureControlInterface(addr)),
    IOpticalAcquire(new OpticalAcquireInterface(addr)),
    IExtTemperatureControl(new ExtTemperatureControlInterface(addr)),
    IExtOpticalAcquire(new ExtOpticalAcquireInterface(addr)),
    m_isEnable(false),
    m_isBoxFanRunning(false),
    m_insideEnvironmentTemp(0),
    m_environmentTemp(0),
    m_weepingDetectEnable(false)
{
    memset(m_thermostatTempArray, 0, sizeof(m_thermostatTempArray));

//    m_boxfanTimer = new QTimer();
//    connect(this, SIGNAL(BoxFanTriggerSignal(float)), this, SLOT(StartBoxFanSlot(float)));
//    connect(m_boxfanTimer, SIGNAL(timeout()), this, SLOT(CheckBoxFanTimeoutSlot()));
}

PT63DriveController::~PT63DriveController()
{
    if (IPeristalticPump)
        delete IPeristalticPump;
    if (ISolenoidValve)
        delete ISolenoidValve;
    if (IOpticalMeter)
        delete IOpticalMeter;
    if (ITemperatureControl)
        delete ITemperatureControl;
    if (IOpticalAcquire)
        delete IOpticalAcquire;
    if (IExtTemperatureControl)
        delete IExtTemperatureControl;
    if (IExtOpticalAcquire)
        delete IExtOpticalAcquire;
}

/**
 * @brief 初始化 LiquidController 环境。
 */
bool PT63DriveController::Init()
{
    IOpticalMeter->RegisterOpticalADNotice(this);
    ITemperatureControl->RegisterTemperatureNotice(this);
    IOpticalAcquire->RegisterAcquireADNotice(this);
    IOpticalAcquire->RegisterAcquireCheckLeaking(this);
    OH_LOG_ERROR(LOG_APP, "PT63DriveController::Init");
    return true;
}

bool PT63DriveController::Uninit()
{
    return true;
}

void PT63DriveController::Register(ISignalNotifiable *handle)
{
    m_notifise.push_back(handle);
}

PeristalticPumpInterface *PT63DriveController::GetIPeristalticPump()
{
    return IPeristalticPump;
}

SolenoidValveInterface *PT63DriveController::GetISolenoidValve()
{
    return ISolenoidValve;
}

OpticalMeterInterface *PT63DriveController::GetIOpticalMeter()
{
    return IOpticalMeter;
}

TemperatureControlInterface *PT63DriveController::GetITemperatureControl()
{
    return ITemperatureControl;
}

OpticalAcquireInterface *PT63DriveController::GetIOpticalAcquire()
{
    return IOpticalAcquire;
}

ExtTemperatureControlInterface *PT63DriveController::GetIExtTemperatureControl()
{
    return IExtTemperatureControl;
}

ExtOpticalAcquireInterface *PT63DriveController::GetIExtOpticalAcquire()
{
    return IExtOpticalAcquire;
}

float PT63DriveController::GetDigestTemperature() const
{
    return m_temperature.thermostatTemp;
}

float PT63DriveController::GetEnvironmentTemperature() const
{
    return m_temperature.environmentTemp;
}

float PT63DriveController::GetReportThermostatTemp(int index) const
{
    float temp = 0;

    if(index >= 0 && index < 2)
    {
        temp = m_thermostatTempArray[index];
    }

    return temp;
}

float PT63DriveController::GetReportEnvironmentTemp() const
{
    return m_environmentTemp;
}

Temperature PT63DriveController::GetCurrentTemperature()
{
    Temperature temp = {0, 0};

    try
    {
        temp = this->ITemperatureControl->GetTemperature();
    }
    catch (CommandTimeoutException e)  // 命令应答超时异常。
    {
        if(this->GetConnectStatus())
        {
            memcpy(&temp, &m_temperature, sizeof(Temperature));
        }
        else
        {
            throw CommandTimeoutException(e.m_addr, e.m_code);
        }
    }
    catch (std::exception e)
    {
        if(this->GetConnectStatus())
        {
            memcpy(&temp, &m_temperature, sizeof(Temperature));
        }
        else
        {
            throw std::exception();
        }
    }

    return temp;
}

void PT63DriveController::OnReceive(DscpEventPtr event)
{
    OH_LOG_ERROR(LOG_APP, "PT63DriveController OnReceive");
    // 检查 TSFN 是否已创建
    if (g_tsfn == nullptr) {
        OH_LOG_WARN(LOG_APP, "TSFN is null, callback not registered or already released.");
        return;
    }

    // 根据 event->type (假设有一个类型字段) 创建对应的 payload
    EventPayload* payload = nullptr;
    
     switch (event->code)
    {
        case DSCP_EVENT_OMI_OPTICAL_AD_NOTICE:      //光学定量信号AD上报
        {
            Uint8 num = *(event->data);
            Uint32 adValue[num];

            for(Uint8 i = 0; i < num; i++)
            {
                adValue[i] = *((Uint32*)(event->data+1 + i*4));
                m_MeterAD[i] = adValue[i];
            }
            payload = new EventPayload(MeterAD{
                    .point1 = m_MeterAD[0],
                    .point2 = m_MeterAD[1],
                    });
        }
            break;

        case DSCP_EVENT_TCI_TEMPERATURE_NOTICE:     //温度上报事件
        {
            m_temperature.thermostatTemp = *((float*)event->data);
            m_temperature.environmentTemp = *((float*)(event->data+4));

            m_thermostatTempArray[0] = *((float*)(event->data));
            m_environmentTemp = *((float*)(event->data+4));
            if(event->len >= 12)
            {
                m_thermostatTempArray[1] = *((float*)(event->data+8));
            }
            payload = new EventPayload(Temperature{
                        .thermostatTemp =  m_temperature.thermostatTemp,
                        .environmentTemp = m_temperature.environmentTemp,
                        });

        }
            break;

        case DSCP_EVENT_OAI_SIGNAL_AD_NOTICE:   // 光学测量信号AD定时上报事件
        {
            m_MeasureAD[0] = *((Uint32*)(event->data));
            m_MeasureAD[1] = *((Uint32*)(event->data + 4));
            OH_LOG_ERROR(LOG_APP, "DSCP_EVENT_OAI_SIGNAL_AD_NOTICE [%{public}d][%{public}d]", m_MeasureAD[0], m_MeasureAD[1]);
            payload = new EventPayload(OpticalAD{
                        .reference =  m_MeasureAD[0],
                        .measure = m_MeasureAD[1],
                        });
        }
            break;

        case DSCP_EVENT_DSI_CHECK_LEAKING_NOTICE:   // 漏液检测AD定时上报事件
        {
    //        if (m_weepingDetectEnable)
    //        {
                Uint16 checkLeakingValve = *((Uint16*)(event->data));
                payload = new EventPayload(Uint32 {(Uint32)checkLeakingValve});
    //        }
        }
            break;

        default:
            break;
    }
    OH_LOG_INFO(LOG_APP, "About to call threadsafe function, g_tsfn: %{public}p", g_tsfn);
    OH_LOG_INFO(LOG_APP, "Payload address: %{public}p", &payload);

    // 2. 调用线程安全函数
    //    这会将 eventData 和 CallJS 函数的执行请求放入队列
    //    N-API 会确保 CallJS 在正确的 JS 线程中被调用
    napi_status status = napi_call_threadsafe_function(g_tsfn,  payload, napi_tsfn_blocking);
    if (status != napi_ok) {
        OH_LOG_ERROR(LOG_APP, "Failed to call threadsafe function");
        // 如果调用失败，需要手动清理 eventData，因为 CallJS 不会被调用
        delete payload;
    }
    OH_LOG_INFO(LOG_APP, "After calling threadsafe function, status: %{public}d", status);
}

void PT63DriveController::StopSignalUpload()
{
//    if (this->GetConnectStatus())
//    {
//        //重置光学定量AD上传周期
//        try
//        {
//
//            this->IOpticalMeter->SetOpticalADNotifyPeriod(0);
//        }
//        catch(CommandTimeoutException e)
//        {
//            logger->warn("DriveController::ResetHandler() => %s", e.What().c_str());
//        }
//        catch(ExpectEventTimeoutException e)
//        {
//            logger->warn("DriveController::ResetHandler() => %s", e.What().c_str());
//        }
//        catch (std::exception e)
//        {
//            logger->warn("DriveController::ResetHandler() => %s", e.what());
//        }
//
//        //重置温度上传周期
//        try
//        {
//            this->ITemperatureControl->SetTemperatureNotifyPeriod(0);
//        }
//        catch(CommandTimeoutException e)
//        {
//            logger->warn("DriveController::ResetHandler() => %s", e.What().c_str());
//        }
//        catch(ExpectEventTimeoutException e)
//        {
//            logger->warn("DriveController::ResetHandler() => %s", e.What().c_str());
//        }
//        catch (std::exception e)
//        {
//            logger->warn("DriveController::ResetHandler() => %s", e.what());
//        }
//
//        //重置信号AD上传周期
//        try
//        {
//            this->IOpticalAcquire->SetAcquireADNotifyPeriod(0);
//        }
//        catch(CommandTimeoutException e)
//        {
//            logger->warn("DriveController::ResetHandler() => %s", e.What().c_str());
//        }
//        catch(ExpectEventTimeoutException e)
//        {
//            logger->warn("DriveController::ResetHandler() => %s", e.What().c_str());
//        }
//        catch (std::exception e)
//        {
//            logger->warn("DriveController::ResetHandler() => %s", e.what());
//        }
//    }
}

Uint32 PT63DriveController::GetMeterAD(int index) const
{
    if((0<=index)&&(index<2))
    {
        return m_MeterAD[index];
    }
    else
    {
        return 0;
    }
}

Uint32 PT63DriveController::GetMeasureAD(int index) const
{
    if((0<=index)&&(index<2))
    {
        return m_MeasureAD[index];
    }
    else
    {
        return 0;
    }
}

void PT63DriveController::SetBoxFanEnable(int index, int mode, float temp)
{
//    m_isEnable = enable;
//    if(enable)
//    {
//        m_isBoxFanRunning = false;
//    }
       ITemperatureControl->BoxFanSetMode(index, mode, temp);
}

//void PT63DriveController::BoxFanControlSlot(float temp)
//{
//    if (m_isEnable && m_insideEnvironmentTemp > 0.1)
//   {
//        if (temp - m_insideEnvironmentTemp > 0.1)
//        {
//           ITemperatureControl->BoxFanSetOutput(1); //打开箱风扇
//        }
//        else if (m_insideEnvironmentTemp - temp > 2)
//        {
//            ITemperatureControl->BoxFanSetOutput(0); //关机箱风扇
//        }
//    }
//}

//
//void PT63DriveController::StartBoxFanSlot(float time)
//{
//    m_boxfanTimer->start(time);
//    ITemperatureControl->BoxFanSetOutput(1); //关机箱风扇
//    logger->debug("开机箱风扇");
//}
//
//void PT63DriveController::CheckBoxFanTimeoutSlot(void)
//{
//    m_boxfanTimer->stop();
//    if (this->GetConnectStatus())
//    {
//        //重置光学定量AD上传周期
//        try
//        {
//            ITemperatureControl->BoxFanSetOutput(0); //关机箱风扇
//            logger->debug("关机箱风扇");
//        }
//        catch(CommandTimeoutException e)
//        {
//            logger->warn("PT63DriveController::BoxFanSetOutput() => %s", e.What().c_str());
//        }
//        catch(ExpectEventTimeoutException e)
//        {
//            logger->warn("PT63DriveController::BoxFanSetOutput() => %s", e.What().c_str());
//        }
//        catch (std::exception e)
//        {
//            logger->warn("PT63DriveController::BoxFanSetOutput() => %s", e.what());
//        }
//    }
//
//}

void PT63DriveController::StartSignalUpload()
{
    if (this->GetConnectStatus())
    {
//        //重置光学定量AD上传周期
//        try
//        {
//
//            this->IOpticalMeter->SetOpticalADNotifyPeriod(1);
//        }
//        catch(CommandTimeoutException e)
//        {
//            logger->warn("PT63DriveController::ResetHandler() => %s", e.What().c_str());
//        }
//        catch(ExpectEventTimeoutException e)
//        {
//            logger->warn("PT63DriveController::ResetHandler() => %s", e.What().c_str());
//        }
//        catch (std::exception e)
//        {
//            logger->warn("PT63DriveController::ResetHandler() => %s", e.what());
//        }
//
//        //重置温度上传周期
//        try
//        {
//            this->ITemperatureControl->SetTemperatureNotifyPeriod(1);
//        }
//        catch(CommandTimeoutException e)
//        {
//            logger->warn("PT63DriveController::ResetHandler() => %s", e.What().c_str());
//        }
//        catch(ExpectEventTimeoutException e)
//        {
//            logger->warn("PT63DriveController::ResetHandler() => %s", e.What().c_str());
//        }
//        catch (std::exception e)
//        {
//            logger->warn("PT63DriveController::ResetHandler() => %s", e.what());
//        }
//
//        //重置电极AD上传周期
//        try
//        {
//            this->IOpticalAcquire->SetAcquireADNotifyPeriod(1);
//        }
//        catch(CommandTimeoutException e)
//        {
//            logger->warn("DriveController::ResetHandler() => %s", e.What().c_str());
//        }
//        catch(ExpectEventTimeoutException e)
//        {
//            logger->warn("DriveController::ResetHandler() => %s", e.What().c_str());
//        }
//        catch (std::exception e)
//        {
//            logger->warn("DriveController::ResetHandler() => %s", e.what());
//        }
    }
}


void PT63DriveController::ClearThermostatRemainEvent()
{
//    logger->debug("{ClearThermostatRemainEvent}");
    try
    {
        DscpAddress addr = ITemperatureControl->GetAddress();
        for (int i = 0; i < 10; i++)
        {
            EventHandler::Instance()->Expect(addr,DSCP_EVENT_TCI_THERMOSTAT_RESULT, 200);
        }
    }
    catch(CommandTimeoutException e)
    {
    }
    catch(ExpectEventTimeoutException e)
    {
    }
    catch (std::exception e)
    {

    }
}

void PT63DriveController::ClearPumpRemainEvent()
{
//    logger->debug("{ClearPumpRemainEvent}");
    try
    {
        DscpAddress addr = IPeristalticPump->GetAddress();
        for (int i = 0; i < 10; i++)
        {
            EventHandler::Instance()->Expect(addr,DSCP_EVENT_PPI_PUMP_RESULT, 200);
        }
    }
    catch(CommandTimeoutException e)
    {
    }
    catch(ExpectEventTimeoutException e)
    {
    }
    catch (std::exception e)
    {

    }
//    float ontime = (m_environmentTemp - 10) * 8;
//    if(ontime>1)
//    {
////        m_boxfanTimer->start(ontime*1000);
//        emit BoxFanTriggerSignal(ontime*1000);
//        logger->debug("打开机箱风扇 %d 秒", (int)ontime);
//    }
}

void PT63DriveController::ClearAllRemainEvent()
{
//    logger->debug("{ClearAllRemainEvent}");
    EventHandler::Instance()->EmptyEvents();    //清空事件池
}


}
