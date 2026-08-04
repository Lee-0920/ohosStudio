import communication from 'libcommunication.so';
import type { MeterPoint } from 'libcommunication.so';
import { MeterMode, MeterResult, MeterPoints, RollDirection } from 'libcommunication.so';

@Sendable
export class Meter {
  turnOnLED(num: number): boolean {
    return communication.meter_turnOnLED(num);
  }

  turnOffLED(num: number): boolean {
    return communication.meter_turnOffLED(num);
  }

  getPumpFactor(): number {
    return communication.meter_getPumpFactor();
  }

  setPumpFactor(factor: number): boolean {
    return communication.meter_setPumpFactor(factor);
  }

  getMeterPoints(): MeterPoints {
    return communication.meter_getMeterPoints();
  }

  setMeterPoints(param: MeterPoints): boolean {
    return communication.meter_setMeterPoints(param);
  }

  getMeterStatus(): number {
    return communication.meter_getMeterStatus();
  }

  startMeter(dir: RollDirection, mode: MeterMode, vol: number, litVol: number): boolean {
    return communication.meter_startMeter(dir, mode, vol, litVol);
  }

  stopMeter(): boolean {
    return communication.meter_stopMeter();
  }

  isAutoCloseValve(status: boolean): boolean {
    return communication.meter_isAutoCloseValve(status);
  }

  setOpticalADNotifyPeriod(period: number): void {
    communication.meter_setOpticalADNotifyPeriod(period);
  }

  expectMeterResult(timeout: number): MeterResult {
    return communication.meter_expectMeterResult(timeout);
  }

  setMeteSpeed(speed: number): boolean {
    return communication.meter_setMeteSpeed(speed);
  }

  getMeteSpeed(): number {
    return communication.meter_getMeteSpeed();
  }

  setMeterFinishValveMap(map: number): boolean {
    return communication.meter_setMeterFinishValveMap(map);
  }

  getSingleOpticalAD(num: number): number {
    return communication.meter_getSingleOpticalAD(num);
  }

  setRopinessMeterOverValue(cnt: number): boolean {
    return communication.meter_setRopinessMeterOverValue(cnt);
  }

  getRopinessMeterOverValue(): number {
    return communication.meter_getRopinessMeterOverValue();
  }

  getMeterEndPointOverCount(): number {
    return communication.meter_getMeterEndPointOverCount();
  }

  setMeterEndPointOverCount(cnt: number): boolean {
    return communication.meter_setMeterEndPointOverCount(cnt);
  }
}

export type { MeterPoint };
export { MeterMode, MeterResult, MeterPoints };

export default new Meter();