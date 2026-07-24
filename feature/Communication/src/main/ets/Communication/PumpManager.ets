import communication from 'libcommunication.so';
import type { MotionParam, PumpResult } from 'libcommunication.so';
import { PumpStatus, RollDirection, PumpOperateResult } from 'libcommunication.so';

@Sendable
export class Pump {
  getTotalPumps(): number {
    return communication.pump_getTotalPumps();
  }

  getPumpFactor(index: number): number {
    return communication.pump_getPumpFactor(index);
  }

  setPumpFactor(index: number, factor: number): boolean {
    return communication.pump_setPumpFactor(index, factor);
  }

  getPumpStatus(index: number): PumpStatus {
    return communication.pump_getPumpStatus(index);
  }

  getMotionParam(index: number): MotionParam {
    return communication.pump_getMotionParam(index);
  }

  setMotionParam(index: number, param: MotionParam): boolean {
    return communication.pump_setMotionParam(index, param);
  }

  startPump(index: number, dir: RollDirection, volume: number, seep: number): boolean {
    return communication.pump_startPump(index, dir, volume, seep);
  }

  stopPump(index: number): boolean {
    return communication.pump_stopPump(index);
  }

  getPumpVolume(index: number): number {
    return communication.pump_getPumpVolume(index);
  }

  expectPumpResult(timeout: number): PumpResult {
    return communication.pump_expectPumpResult(timeout);
  }
}

export type { MotionParam, PumpResult };
export { PumpStatus, RollDirection, PumpOperateResult };

export default new Pump();