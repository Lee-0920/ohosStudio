import { PhotoTekDevice } from './PhotoTekDevice';
import { WaterQualityDevice } from './WaterQualityDevice';

export class DeviceContext {
  private static currentDevice: WaterQualityDevice = new PhotoTekDevice();

  static getDevice(): WaterQualityDevice {
    return DeviceContext.currentDevice;
  }

  static setDevice(device: WaterQualityDevice): void {
    DeviceContext.currentDevice = device;
  }
}
