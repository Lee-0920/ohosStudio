/**
 * @file
 * @brief 驱动控制器。
 * @details
 * @version 1.0.0
 * @author kim@erchashu.com
 * @date 2016/5/13
 */


#if !defined(CONTROLLER_DRIVECONTROLNET_H_)
#define CONTROLLER_DRIVECONTROLNET_H_

#include <vector>
#include "ControllerPlugin/BaseController.h"
#include "API/PeristalticPumpInterface.h"
#include "API/SolenoidValveInterface.h"
#include "API/OpticalMeterInterface.h"
#include "API/TemperatureControlInterface.h"
#include "API/OpticalAcquireInterface.h"
#include "API/ExtTemperatureControlInterface.h"
#include "API/ExtOpticalAcquireInterface.h"
//#include "QTimer"
#include <napi/native_api.h>

using std::list;

namespace Controller
{

// 定义一个变体（Variant），它可以是上述任意一种类型
using EventPayload = std::variant<Temperature, OpticalAD, MeterAD, Uint32/*, ...*/>;
// 定义事件类型枚举，用于在 JS 层快速判断类型（可选，但非常有用）
enum class EventType : uint8_t {
    METER,
    TEMPERATURE,
    OPTICAL,
    LEAKING,
    // ...
};
/**
 * @brief 驱动控制器。
 * @details
 */
class PT63DriveController :public BaseController
{
public:
    PT63DriveController(DscpAddress addr);
    virtual ~PT63DriveController();
    bool Init();
    bool Uninit();

    PeristalticPumpInterface* GetIPeristalticPump();
    SolenoidValveInterface* GetISolenoidValve();
    OpticalMeterInterface* GetIOpticalMeter();
    TemperatureControlInterface*  GetITemperatureControl();
    OpticalAcquireInterface* GetIOpticalAcquire();
    ExtTemperatureControlInterface*  GetIExtTemperatureControl();
    ExtOpticalAcquireInterface* GetIExtOpticalAcquire();

    float GetDigestTemperature() const;
    float GetEnvironmentTemperature() const;
    Temperature GetCurrentTemperature();
	
	float GetReportThermostatTemp(int index) const;
    float GetReportEnvironmentTemp() const;

    void ClearAllRemainEvent();
    void ClearThermostatRemainEvent();
    void ClearPumpRemainEvent();

    // ---------------------------------------
    // IEventReceivable 接口
    void Register(ISignalNotifiable *handle);
    virtual void OnReceive(DscpEventPtr event);
    void StartSignalUpload();
    void StopSignalUpload();
    void SetBoxFanEnable(int index, int mode, float temp);
    Uint32 GetMeterAD(int index) const;
    Uint32 GetMeasureAD(int index) const;
public:
    // 设备接口集
    PeristalticPumpInterface * const IPeristalticPump;
    SolenoidValveInterface * const ISolenoidValve;
    OpticalMeterInterface * const IOpticalMeter;
    TemperatureControlInterface * const ITemperatureControl;
    OpticalAcquireInterface * const IOpticalAcquire;
    ExtTemperatureControlInterface * const IExtTemperatureControl;
    ExtOpticalAcquireInterface * const IExtOpticalAcquire;
    static napi_threadsafe_function g_tsfn;

//signals:
//    void  BoxFanTriggerSignal(float time);
//public slots:
////  void  BoxFanControlSlot(float temp);
//    void StartBoxFanSlot(float);
//    void CheckBoxFanTimeoutSlot(void);

private:
    list<ISignalNotifiable*> m_notifise;
    Temperature m_temperature;

    bool m_isEnable;
    bool m_isBoxFanRunning;
    float m_insideEnvironmentTemp;
    bool m_weepingDetectEnable;

    float m_environmentTemp;
    float m_thermostatTempArray[2];
    Uint32 m_MeterAD[2];
    Uint32 m_MeasureAD[2];
//    QTimer* m_boxfanTimer;
};

}

#endif  //CONTROLLER_DRIVECONTROLNET_H_

