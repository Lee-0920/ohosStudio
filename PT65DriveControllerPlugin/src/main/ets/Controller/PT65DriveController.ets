
import { BaseController } from 'controllerplugin';

import { hilog } from '@kit.PerformanceAnalysisKit';

class SolenoidValveInterface{
  GetValveMap(){
    hilog.info(90,'Controller', 'SolenoidValveInterface.GetValveMap');
  }
  SetValveMap():boolean{
    hilog.info(90,'Controller', 'SolenoidValveInterface.SetValveMap');
    return true;
  }
}

class TemperatureControlInterface {
  StartThermostat() : boolean{
    hilog.info(90,'Controller', 'TemperatureControlInterface.StartThermostat');
    return true;
  }
  StopThermostat() : boolean {
    hilog.info(90,'Controller', 'TemperatureControlInterface.StopThermostat');
    return true;
  }
}

class PeristalticPumpInterface {

}

class OpticalMeterInterface {

}

class OpticalAcquireInterface {

}

export class PT65DriveController extends BaseController{
  solenoidValveInterface : SolenoidValveInterface = new SolenoidValveInterface();
  temperatureControlInterface : TemperatureControlInterface = new TemperatureControlInterface();
  peristalticPumpInterface : PeristalticPumpInterface = new PeristalticPumpInterface();
  opticalMeterInterface : OpticalMeterInterface = new OpticalMeterInterface();
  opticalAcquireInterface : OpticalAcquireInterface = new OpticalAcquireInterface();

  constructor() {
    super();
  }

  GetIPeristalticPump() : PeristalticPumpInterface {
    return this.peristalticPumpInterface;
  }
  GetISolenoidValve():SolenoidValveInterface {
    return this.solenoidValveInterface;
  }
  GetIOpticalMeter():OpticalMeterInterface {
    return this.opticalMeterInterface;
  }
  GetITemperatureControl(): TemperatureControlInterface {
    return this.temperatureControlInterface;
  }
  GetIOpticalAcquire() : OpticalAcquireInterface {
    return this.opticalAcquireInterface;
  }

}