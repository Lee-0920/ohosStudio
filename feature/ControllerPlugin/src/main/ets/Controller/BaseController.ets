
import { DeviceStatusInterface } from './API/DeviceInfoInterface';
import { hilog } from '@kit.PerformanceAnalysisKit';

export class BaseController {

  deviceStatusInterface : DeviceStatusInterface = new DeviceStatusInterface();

  constructor(){
    hilog.info(90,'BaseController', 'BaseController.constructor()')
  }

  GetIDeviceStatus(): DeviceStatusInterface{
    hilog.info(90,'BaseController', 'BaseController.GetIDeviceStatus()')
    return this.deviceStatusInterface;
  }

  GetConnectStatus(): boolean {
    hilog.info(90,'BaseController', 'BaseController.GetConnectStatus()')
    return true;
  }


}