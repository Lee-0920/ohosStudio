// ValveMap.ets
import communication from 'libcommunication.so';

@Sendable
export class ValveMap {
  public data: number = 0;
  public cmd: number = 0;
  public param1: number = 0;
  public param2: number = 0;
  public index: number = 0;

  constructor(initData?: number) {
    // console.info(`TLQQ, constructor()`);
    if (initData !== undefined) {
      // console.info(`TLQQ, constructor() data: ${initData}`);
      communication.valveMap_initValveMap(this, initData);
    }
  }

  setData(val: number): void {
    communication.valveMap_setData(this, val);
  }

  getData(): number {
    return communication.valveMap_getData(this);
  }

  setOn(idx: number): void {
    communication.valveMap_setOn(this, idx);
  }

  setOff(idx: number): void {
    communication.valveMap_setOff(this, idx);
  }

  isOn(idx: number): boolean {
    return communication.valveMap_isOn(this, idx);
  }

  clear(): void {
    communication.valveMap_clear(this);
  }

  setSpinValveCmd(cmd: number, p1: number, p2: number): void {
    communication.valveMap_setSpinValveCmd(this, cmd, p1, p2);
  }

  getCmd(): number { return this.cmd; }
  getParam1(): number { return this.param1; }
  getParam2(): number { return this.param2; }
  getIndex(): number { return this.index; }
}