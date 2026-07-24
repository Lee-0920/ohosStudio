import communication from 'libcommunication.so';
import type { OpticalAD, LedParam, RefADParam, AcquiredResult } from 'libcommunication.so';
import { AdjustResult, StaticADControlResult, AcquiredOperateResult } from 'libcommunication.so';

@Sendable
export class Optical {
  turnOnLED(): boolean { return communication.optical_turnOnLED(); }
  turnOffLED(): number { return communication.optical_turnOffLED(); }

  setAcquireADNotifyPeriod(period: number): boolean {
    return communication.optical_setAcquireADNotifyPeriod(period);
  }

  startAcquirer(time: number): boolean { return communication.optical_startAcquirer(time); }
  stopAcquirer(): number { return communication.optical_stopAcquirer(); }
  expectADAcquirer(timeout: number): AcquiredResult { return communication.optical_expectADAcquirer(timeout); }

  startLEDController(): number { return communication.optical_startLEDController(); }
  getLEDControllerTarget(): number { return communication.optical_getLEDControllerTarget(); }
  setLEDControllerTarget(value: number): boolean { return communication.optical_setLEDControllerTarget(value); }
  getLEDControllerParam(): LedParam { return communication.optical_getLEDControllerParam(); }
  setLEDControllerParam(param: LedParam): boolean { return communication.optical_setLEDControllerParam(param); }

  startLEDOnceAdjust(target: number, tolerance: number, timeout: number): boolean {
    return communication.optical_startLEDOnceAdjust(target, tolerance, timeout);
  }
  stopLEDOnceAdjust(): boolean { return communication.optical_stopLEDOnceAdjust(); }
  expectLEDOnceAdjust(timeout: number): AdjustResult { return communication.optical_expectLEDOnceAdjust(timeout); }

  startStaticADControl(index: number, target: number): void {
    communication.optical_startStaticADControl(index, target);
  }
  stopStaticADControl(): boolean { return communication.optical_stopStaticADControl(); }
  getStaticADControlParam(): number { return communication.optical_getStaticADControlParam(); }
  setStaticADControlParam(index: number, value: number): boolean {
    return communication.optical_setStaticADControlParam(index, value);
  }
  isStaticADControlValid(): boolean { return communication.optical_isStaticADControlValid(); }
  expectStaticADControlResult(timeout: number): StaticADControlResult {
    return communication.optical_expectStaticADControlResult(timeout);
  }

  getLEDDefaultValue(): number { return communication.optical_getLEDDefaultValue(); }
  setLEDDefaultValue(value: number): boolean { return communication.optical_setLEDDefaultValue(value); }

  setStaticADGain(gain: number): boolean { return communication.optical_setStaticADGain(gain); }
}

export type { OpticalAD, LedParam, RefADParam, AcquiredResult };
export { AdjustResult, StaticADControlResult, AcquiredOperateResult };

export default new Optical();