import communication from 'libcommunication.so';
import { ValveMap } from 'libcommunication.so';

@Sendable
export class Valve {
  getTotalValves(): number {
    return communication.valve_getTotalValves();
  }

  getValveMap(): ValveMap {
    return communication.valve_getValveMap();
  }

  setValveMap(map: ValveMap): boolean {
    return communication.valve_setValveMap(map);
  }

  ctrlSpinValve(map: ValveMap): boolean {
    return communication.valve_ctrlSpinValve(map);
  }

  setValve16(isOpen: boolean): boolean {
    return communication.valve_setValve16(isOpen);
  }

  setCheckLeakingPeriod(period: number): boolean {
    return communication.valve_setCheckLeakingPeriod(period);
  }
}

// export { ValveMap };

export default new Valve();