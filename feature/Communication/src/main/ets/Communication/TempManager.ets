import communication from 'libcommunication.so';
import type { TempCalibrateFactor, Temperature, ThermostatParam, ThermostatResult } from 'libcommunication.so';
import { ThermostatOperateResult, ThermostatMode } from 'libcommunication.so';

@Sendable
export class Temp {
  getCalibrateFactor(): TempCalibrateFactor { return communication.temp_getCalibrateFactor(); }
  setCalibrateFactor(factor: TempCalibrateFactor): boolean { return communication.temp_setCalibrateFactor(factor); }

  getTemperature(): Temperature { return communication.temp_getTemperature(); }

  getThermostatParam(): ThermostatParam { return communication.temp_getThermostatParam(); }
  setThermostatParam(param: ThermostatParam): boolean { return communication.temp_setThermostatParam(param); }
  getCurrentThermostatParam(): ThermostatParam { return communication.temp_getCurrentThermostatParam(); }
  setCurrentThermostatParam(param: ThermostatParam): boolean { return communication.temp_setCurrentThermostatParam(param); }

  getThermostatStatus(): number { return communication.temp_getThermostatStatus(); }
  startThermostat(mode: number, targetTemp: number, toleranceTemp: number, timeout: number): boolean {
    return communication.temp_startThermostat(mode, targetTemp, toleranceTemp, timeout);
  }
  stopThermostat(): boolean { return communication.temp_stopThermostat(); }
  expectThermostat(timeout: number): ThermostatResult { return communication.temp_expectThermostat(timeout); }

  setTemperatureNotifyPeriod(period: number): boolean { return communication.temp_setTemperatureNotifyPeriod(period); }

  boxFanSetOutput(level: number): boolean { return communication.temp_boxFanSetOutput(level); }
  digestionFanSetOutput(level: number): boolean { return communication.temp_digestionFanSetOutput(level); }
  boxFanSetMode(index: number, mode: number, temp: number): boolean {
    return communication.temp_boxFanSetMode(index, mode, temp);
  }

  getHeaterMaxDutyCycle(): number { return communication.temp_getHeaterMaxDutyCycle(); }
  setHeaterMaxDutyCycle(level: number): boolean { return communication.temp_setHeaterMaxDutyCycle(level); }

  turnOnRays(): boolean { return communication.temp_turnOnRays(); }
  turnOffRays(): boolean { return communication.temp_turnOffRays(); }
}

//转导出给消费方（注意用 export type）
export type { TempCalibrateFactor, Temperature, ThermostatParam, ThermostatResult };
export { ThermostatOperateResult, ThermostatMode };

export default new Temp();