import { hilog } from "@kit.PerformanceAnalysisKit";
import { PT65DriveController } from "pt65drivecontrollerplugin";
import { liquidTypes, LiquidType } from '../Setting/LiquidType';
import { setting } from '../Setting/Setting';
import { PeristalticPump } from './PeristalticPump';
import { thread } from 'base';
import { config } from '../Config/Config';
import { dncp, pump, valve, temp, meter, optical } from 'communication'; //导入模块
import type { Meter, Valve, Pump, Temp, Optical } from 'communication'; // 或分别从各文件 import type
import {
  type MotionParam, type PumpResult,            //泵接口结构体导入
  PumpStatus, RollDirection, PumpOperateResult, //泵接口枚举体导入
  type Temperature, type ThermostatParam, type TempCalibrateFactor, type ThermostatResult, //温度接口结构体导入
  ThermostatMode, ThermostatOperateResult,                                                 //温度枚举体导入
  ValveMap,   //阀类导入
  MeterPoints,            //定量类导入
  type MeterPoint,        //定量结构体导入
  MeterMode, MeterResult, //定量枚举体导入
  type OpticalAD, type AcquiredResult, type LedParam, type RefADParam, //光学结构体导入
  AcquiredOperateResult, StaticADControlResult, AdjustResult,          //光学枚举体导入
} from 'communication'; //导入类型->结构体，枚举(结构体前必须加type，枚举体不需要加type)

import { ReagentRemainManager } from '../Common/ReagentRemainManager';
import { collections } from "@kit.ArkTS";

/**
 * 废液排放类型
 */
export enum WasteType {
  WasteReagent = 1,
  WasteWater = 2,
}

/**
 * 驱动器操作业务类
 * 对液路器、温控器、信号采集器业务操作的功能进行封装
 */
@Sendable
export class Operator {
  private static _instance: Operator | undefined;
  IOpticalMeter: Meter;
  ISolenoidValve: Valve;
  IPeristalticPump: Pump;
  ITemperatureControl: Temp;
  IOpticalAcquire: Optical;
  isMetering: boolean = false;
  isThermostat: boolean = false;
  isAcquiring: boolean = false;
  SPEED: number = 0.2;
  PRECISE: number = 0.000001;
  isStop: boolean = false;
  pumps: collections.Array<PeristalticPump> = new collections.Array();

  constructor() {
    // const DC = new PT65DriveController();
    this.IOpticalMeter = meter;
    this.ISolenoidValve = valve;
    this.IPeristalticPump = pump;
    this.ITemperatureControl = temp;
    this.IOpticalAcquire = optical;
    //
    // dncp.createPlugin();
    // dncp.addSlaveNode(1);
    // dncp.initDncpStack("/dev/ttyS0",false,"");

    // 初始化蠕动泵列表
    // for (let i = 0; i < pumpCount; i++) {
    //   this.pumps.push(new PeristalticPump(i, this.IPeristalticPump));
    // }
  }

  static getInstance(): Operator {
    if (!Operator._instance) {
      Operator._instance = new Operator();
      // 真正的初始化逻辑放在这里，且只在需要时执行
      Operator._instance.init();
    }
    return Operator._instance;
  }

  private init() {
    // 实际的初始化工作
    // dncp.createPlugin();
    // dncp.addSlaveNode(1);
    // dncp.initDncpStack("/dev/ttyS0",false,"");
  }

  /**
   * 调试打印
   */
  private debugPrintf(format: string, ...args: (string | number | boolean)[]): void {
    hilog.debug(122, 'Operator', format, args);
  }

  /**
   * 停止所有驱动控制器操作
   */
  Stop(): void {
    this.IOpticalMeter.stopMeter();
    this.isStop = true;

    if (this.isMetering) {
      this.IOpticalMeter.stopMeter();
      this.isMetering = false;
    }

    for (const pump of this.pumps) {
      if (pump.isRunning) {
        pump.Stop();
      }
    }

    if (this.isThermostat) {
      this.ITemperatureControl.stopThermostat();
      this.isThermostat = false;
    }

    if (this.isAcquiring) {
      this.IOpticalAcquire.stopAcquirer();
      this.isAcquiring = false;
    }
  }

  /**
   * 泵抽取液体操作
   * @param source 管道类型
   * @param volume 溶液体积
   * @param speed 泵速，0为默认速度
   * @param isWait 是否等待
   */
  Pump(source: LiquidType, volume: number, speed: number = 0, isWait: boolean = true): boolean {
    let ret = false;
    const timeout = Math.floor(volume * setting.liquid.meterLimit.pumpTimeoutFactor);

    this.debugPrintf("{Pump} source = %{public}s, volume = %{public}d, speed = %{public}d", source.name, volume, speed);

    try {
      const map = new ValveMap(source.valve);

      const result = this.IPeristalticPump.startPump(source.pump, RollDirection.Suck, volume, speed);
      // if (!result) {
      //   return false;
      // }

      if (isWait) {
        thread.sleep(1500);
      }

      const valveResult = this.ISolenoidValve.setValveMap(map);
      if (!valveResult) {
        this.IPeristalticPump.stopPump(source.pump);
        return false;
      }

      const pumpResult = this.IPeristalticPump.expectPumpResult(timeout);
      map.setData(0);
      this.ISolenoidValve.setValveMap(map);

      if (pumpResult.result == PumpOperateResult.Finished) {
        ret = true;
      }

      ret = true;
    } catch (err) {
      // 异常处理
      if (err instanceof Error) {
        hilog.warn(122, 'Operator', 'Pump error: %{public}s', err.message);
      }
      throw new Error(err);
    }

    ReagentRemainManager.getInstance().ReduceReagent(source, volume);
    return ret;
  }

  /**
   * 排液操作
   * @param dest 管道类型
   * @param volume 溶液体积
   * @param speed 泵速，0为默认速度
   */
  Drain(dest: LiquidType, volume: number, speed: number = 0): boolean {
    let ret = false;
    const timeout = Math.floor(volume * setting.liquid.meterLimit.pumpTimeoutFactor);

    this.debugPrintf("{Drain} dest = %{public}s, volume = %{public}d, speed = %{public}d", dest.name, volume, speed);

    try {
      // console.info(`TLQQ, before new`); // 现在应该能看到 ETS 构造函数里的日志了
      const map = new ValveMap(dest.valve);
      // console.info(`TLQQ, after new`); // 现在应该能看到 ETS 构造函数里的日志了

      const valveResult = this.ISolenoidValve.setValveMap(map);
      if (!valveResult) {
        return false;
      }
      // console.info(`TLQQ, after setValveMap`); // 现在应该能看到 ETS 构造函数里的日志了
      // thread.sleep(3000);

      const Result = this.IPeristalticPump.startPump(dest.pump, RollDirection.Drain, volume, speed);
      // console.info(`TLQQ, after startPump`); // 现在应该能看到 ETS 构造函数里的日志了
      // if (!Result) {
      //   return false;
      // }
      // thread.sleep(5000);
      // console.info(`TLQQ, expectPumpResult start `); // 现在应该能看到 ETS 构造函数里的日志了
      // let pumpResult: PumpResult = pump.expectPumpResult(3000);
      const pumpResult = this.IPeristalticPump.expectPumpResult(timeout);
      // console.info(`TLQQ, expectPumpResult end`); // 现在应该能看到 ETS 构造函数里的日志了
      thread.sleep(500);
      map.setData(0);
      this.ISolenoidValve.setValveMap(map);

      if (pumpResult.result == PumpOperateResult.Finished) {
        // console.info(`TLQQ, expectPumpResult Finished`);
        ret = true;
      }

      ret = true;
    } catch (err) {
      if (err instanceof Error) {
        hilog.warn(122, 'Operator', 'Drain error: %{public}s', err.message);
      }
      throw new Error(err);
    }

    ReagentRemainManager.getInstance().RecoverReagent(dest, volume);
    return ret;
  }

  /**
   * 排液操作,排液前后不关阀
   */
  DrainNotCloseValve(dest: LiquidType, volume: number, speed: number = 0): boolean {
    let ret = false;
    const timeout = Math.floor(volume * setting.liquid.meterLimit.pumpTimeoutFactor);

    this.debugPrintf("{Drain} dest = %{public}s, volume = %{public}d, speed = %{public}d", dest.name, volume, speed);

    try {
      const map = new ValveMap(dest.valve);

      const Result = this.IPeristalticPump.startPump(dest.pump, RollDirection.Drain, volume, speed);
      if (!Result) {
        return false;
      }

      const pumpResult = this.IPeristalticPump.expectPumpResult(timeout);
      map.setData(0);

      if (pumpResult.result == PumpOperateResult.Finished) {
        ret = true;
      }

      ret = true;
    } catch (err) {
      if (err instanceof Error) {
        hilog.warn(122, 'Operator', 'DrainNotCloseValve error: %{public}s', err.message);
      }
      throw new Error(err);
    }

    ReagentRemainManager.getInstance().RecoverReagent(dest, volume);
    return ret;
  }

  /**
   * 设置定量过冲程度
   * @param mode 定量模式
   * @param value 过冲程度
   */
  SetMeterOverValue(mode: MeterMode, value: number): void {
    switch (mode) {
      case MeterMode.Accurate:
        this.IOpticalMeter.setMeterEndPointOverCount(value);
        this.debugPrintf("{MeterOverValue} mode = Accurate, value = %{public}d", value);
        break;
      case MeterMode.Ropiness:
        this.IOpticalMeter.setRopinessMeterOverValue(value);
        this.debugPrintf("{MeterOverValue} mode = Ropiness, value = %{public}d", value);
        break;
      case MeterMode.Layered:
        // this.IOpticalMeter.setLayeredMeterOverValue(value);
        this.debugPrintf("{MeterOverValue} mode = Layered, value = %{public}d", value);
        break;
    }
  }

  /**
   * 定量液体操作
   * @param mode 定量模式
   * @param source 管道类型
   * @param volume 溶液体积
   * @param dir 方向
   */
  Meter(mode: MeterMode, source: LiquidType, volume: number, dir: RollDirection): boolean {
    let ret = false;

    let limitVolume = 0;
    let timeout = 0;

    if (source === liquidTypes.sample) {
      limitVolume = setting.liquid.meterLimit.sampleLimitVolume + volume;
    } else if (source === liquidTypes.blank) {
      limitVolume = setting.liquid.meterLimit.blankLimitVolume + volume;
    } else if (source === liquidTypes.digestionRoom) {
      limitVolume = setting.liquid.meterLimit.digestionRoomLimitVolume + volume;
    } else {
      limitVolume = setting.liquid.meterLimit.reagentLimitVolume + volume;
    }

    if (mode === MeterMode.Accurate || mode === MeterMode.Ropiness || mode === MeterMode.Layered) {
      limitVolume = limitVolume * 3;
    }

    if (mode === MeterMode.Accurate || mode === MeterMode.Ropiness || 
        mode === MeterMode.Layered || source === liquidTypes.reagent2) {
      timeout = Math.floor(limitVolume * setting.liquid.meterLimit.meterTimeoutFactor * 3);
    } else {
      timeout = Math.floor(limitVolume * setting.liquid.meterLimit.meterTimeoutFactor);
    }

    const modeStr = ['Accurate', 'Direct', 'Smart', 'Ropiness', 'Layered'][mode];
    this.debugPrintf("{Meter} source = %{public}s, volume = %{public}d, mode = %{public}s, dir = %{public}d", 
                     source.name, volume, modeStr, dir);

    this.isMetering = true;

    try {
      const map = new ValveMap(source.valve);

      const meterResult = this.IOpticalMeter.startMeter(dir, mode, volume, limitVolume);
      if (!meterResult) {
        this.isMetering = false;
        return false;
      }

      if (source === liquidTypes.reagent2 || source === liquidTypes.reagent1) {
        thread.sleep(2300);
      } else {
        thread.sleep(1500);
      }

      const valveResult = this.ISolenoidValve.setValveMap(map); 
      if (!valveResult) {
        this.IOpticalMeter.stopMeter();
        this.isMetering = false;
        return false;
      }

      const expectResult = this.IOpticalMeter.expectMeterResult(timeout);
      this.isMetering = false;

      if (expectResult === MeterResult.Finished) {
        ret = true;
      }

      this.isMetering = false;
      ret = true;
    } catch (err) {
      this.isMetering = false;
      if (err instanceof Error) {
        hilog.warn(122, 'Operator', 'Meter error: %{public}s', err.message);
      }
      throw new Error(err);
    }

    ReagentRemainManager.getInstance().ReduceReagent(source, volume);
    return ret;
  }

  /**
   * 停止定量操作
   */
  StopMeter(): void {
    this.IOpticalMeter.stopMeter();
    const result = this.IOpticalMeter.expectMeterResult(3000);
  }

  /**
   * 定量结束自动关闭阀开关
   * @param isCloseValve 是否自动关闭
   */
  AutoCloseValve(isCloseValve: boolean): boolean {
    return this.IOpticalMeter.isAutoCloseValve(isCloseValve);
  }

  /**
   * 消解器冒泡
   * @param time 冒泡时间
   */
  AirToDigestionRoom(time?: number): void {
    if (time === undefined) {
      time = setting.liquid.pumpAirVolume / setting.liquid.pumpAirSpeed;
    }

    const factor = this.IPeristalticPump.getPumpFactor(0);
    const drainSpeed = setting.liquid.prefabricateDrainSpeed * factor;

    this.Drain(liquidTypes.none, 0.3, drainSpeed);
    this.Drain(liquidTypes.digestionRoom, time * setting.liquid.pumpAirSpeed, setting.liquid.pumpAirStepSpeed * factor);
  }

  /**
   * 管道隔离
   * @param source 管道类型
   * @param vol 体积
   */
  SecludeLiquid(source: LiquidType, vol?: number): void {
    if (source === liquidTypes.digestionRoom) {
      this.Drain(source, setting.liquid.liquidSecludeVolume * 10, setting.liquid.liquidSecludeSpeed);
    } else {
      if (vol !== undefined && vol !== 0) {
        this.Drain(source, vol, setting.liquid.liquidSecludeSpeed);
      } else {
        this.Drain(source, setting.liquid.liquidSecludeVolume, setting.liquid.liquidSecludeSpeed);
      }
    }
  }

  /**
   * 排液到废液桶
   * @param volume 体积
   * @param wasteType 废液类型
   */
  DrainToWaste(volume: number, wasteType: WasteType = WasteType.WasteReagent): void {
    const actualVolume = volume === 0 ? setting.liquid.meterPipeVolume : volume;
    if (wasteType === WasteType.WasteWater) {
      this.Drain(liquidTypes.wasteWater, actualVolume, 0.2);
    } else {
      this.Drain(liquidTypes.waste, actualVolume, 0.2);
    }
  }

  /**
   * 快速定量抽取液体到消解室
   */
  PumpToDigestionRoom(source: LiquidType, vol: number, point?: number, wType?: WasteType): void {
    const wasteType = wType === WasteType.WasteWater ? WasteType.WasteWater : WasteType.WasteReagent;
    const factor = this.IPeristalticPump.getPumpFactor(0);
    const drainSpeed = setting.liquid.prefabricateDrainSpeed * factor;

    this.IOpticalMeter.setMeteSpeed(setting.liquid.drainSpeed * factor);
    this.debugPrintf("Set Meter Speed %{public}d", setting.liquid.drainSpeed * factor);

    this.SetMeterOverValue(MeterMode.Smart, 0);
    // hilog.warn(122, 'Operator', 'PumpToDigestionRoom vol: %{public}d', vol);

    try {
      const volTable = this.SmartMeterVolumeAnalyse(vol);
      for (const volume of volTable) {
        this.Meter(MeterMode.Smart, source, volume, RollDirection.Suck);
        this.Drain(liquidTypes.digestionRoom, volume + setting.liquid.digestionRoomPipeVolume, drainSpeed);
        // hilog.warn(122, 'Operator', 'PumpToDigestionRoom volume: %{public}d', volume);
      }
    } catch (err) {
      if (err instanceof Error) {
        hilog.warn(122, 'Operator', 'PumpToDigestionRoom error: %{public}s', err.message);
      }
      throw new Error(err);
    }
  }

  /**
   * 精确定量抽取液体到消解室
   */
  MeterToDigestionRoom(source: LiquidType, vol: number, point?: number, wType?: WasteType): void {
    const wasteType = wType === WasteType.WasteWater ? WasteType.WasteWater : WasteType.WasteReagent;
    const factor = this.IPeristalticPump.getPumpFactor(0);
    const drainSpeed = setting.liquid.prefabricateDrainSpeed * factor * 0.8;

    this.IOpticalMeter.setMeteSpeed(setting.liquid.meterSpeed * factor);
    this.debugPrintf("Set Meter Speed %{public}d", setting.liquid.meterSpeed * factor);

    if (source === liquidTypes.sample) {
      this.SetMeterOverValue(MeterMode.Accurate, setting.liquid.accurateMeterOverValue * 3);
    } else {
      this.SetMeterOverValue(MeterMode.Accurate, setting.liquid.accurateMeterOverValue);
    }

    try {
      const volTable = point ? this.AccurateMeterVolumeAnalyse(vol, point) : this.AutoMeterVolumeAnalyse(vol);
      for (const volume of volTable) {
        this.Pump(liquidTypes.none, 0.5, 0.2, false);
        this.Meter(MeterMode.Accurate, source, volume, RollDirection.Suck);
        this.Drain(liquidTypes.none, 0.3, 0.2);
        this.Drain(liquidTypes.digestionRoom, volume + setting.liquid.digestionRoomPipeVolume, drainSpeed);
      }
    } catch (err) {
      if (err instanceof Error) {
        hilog.warn(122, 'Operator', 'MeterToDigestionRoom error: %{public}s', err.message);
      }
      throw new Error(err);
    }
  }

  /**
   * 慢速定量抽取液体到消解室
   */
  SlowMeterToDigestionRoom(source: LiquidType, vol: number, point?: number, wType?: WasteType): void {
    const wasteType = wType === WasteType.WasteWater ? WasteType.WasteWater : WasteType.WasteReagent;
    const factor = this.IPeristalticPump.getPumpFactor(source.pump);

    try {
      const volTable = point ? this.AccurateMeterVolumeAnalyse(vol, point) : this.AutoMeterVolumeAnalyse(vol);
      for (const volume of volTable) {
        this.IOpticalMeter.setMeteSpeed(setting.liquid.slowMeterSpeed * factor);
        this.Meter(MeterMode.Ropiness, source, volume, RollDirection.Suck);
        this.Drain(liquidTypes.none, 0.3, 0.4);
        this.Drain(liquidTypes.digestionRoom, volume + setting.liquid.digestionRoomPipeVolume, 0.1);
      }
      this.IOpticalMeter.setMeteSpeed(setting.liquid.meterSpeed * factor);
    } catch (err) {
      if (err instanceof Error) {
        hilog.warn(122, 'Operator', 'SlowMeterToDigestionRoom error: %{public}s', err.message);
      }
      throw new Error(err);
    }
  }

  SlowMeterToDigestionRoomNotCloseValve(source: LiquidType, vol: number, point?: number, wType?: WasteType): void {
    const wasteType = wType === WasteType.WasteWater ? WasteType.WasteWater : WasteType.WasteReagent;
    const factor = this.IPeristalticPump.getPumpFactor(0);

    try {
      const volTable = point ? this.AccurateMeterVolumeAnalyse(vol, point) : this.AutoMeterVolumeAnalyse(vol);
      for (const volume of volTable) {
        this.IOpticalMeter.setMeteSpeed(setting.liquid.slowMeterSpeed * factor);
        this.Meter(MeterMode.Ropiness, source, volume, RollDirection.Suck);
        this.Drain(liquidTypes.none, 0.3, 0.4);
        this.DrainNotCloseValve(liquidTypes.digestionRoom, volume + setting.liquid.digestionRoomPipeVolume, 0.1);
      }
      this.IOpticalMeter.setMeteSpeed(setting.liquid.meterSpeed * factor);
    } catch (err) {
      if (err instanceof Error) {
        hilog.warn(122, 'Operator', 'SlowMeterToDigestionRoomNotCloseValve error: %{public}s', err.message);
      }
      throw new Error(err);
    }
  }

  IndirectMeterToDigestionRoom(source: LiquidType, vol: number, wType?: WasteType): void {
    const wasteType = wType === WasteType.WasteWater ? WasteType.WasteWater : WasteType.WasteReagent;
    const factor = this.IPeristalticPump.getPumpFactor(0);
    const drainSpeed = setting.liquid.prefabricateDrainSpeed * factor;

    try {
      const volTable = this.AutoMeterVolumeAnalyse(vol);
      for (const volume of volTable) {
        this.IOpticalMeter.setMeteSpeed(setting.liquid.meterSpeed * 0.3 * factor);
        this.debugPrintf("Set Meter Speed %{public}d", setting.liquid.meterSpeed * 0.3 * factor);

        this.SetMeterOverValue(MeterMode.Accurate, setting.liquid.accurateMeterOverValue);
        this.Meter(MeterMode.Accurate, source, volume, RollDirection.Suck);
        this.Drain(liquidTypes.none, 0.3, 0.2);
        this.Drain(liquidTypes.digestionRoom, volume + setting.liquid.digestionRoomPipeVolume, 0.2);
        this.IOpticalMeter.setMeteSpeed(setting.liquid.meterSpeed * factor);
        this.debugPrintf("Set Meter Speed %{public}d", setting.liquid.meterSpeed * factor);
      }
    } catch (err) {
      if (err instanceof Error) {
        hilog.warn(122, 'Operator', 'IndirectMeterToDigestionRoom error: %{public}s', err.message);
      }
      throw new Error(err);
    }
  }

  DrainToWasteNotCloseValve(vol: number, wType?: WasteType): void {
    if (vol === undefined || vol === 0) {
      vol = 1;
    }

    const factor = this.IPeristalticPump.getPumpFactor(0);
    const drainSpeed = setting.liquid.prefabricateDrainSpeed * factor;

    if (wType === WasteType.WasteWater) {
      this.DrainNotCloseValve(liquidTypes.wasteWater, vol, drainSpeed);
    } else {
      this.DrainNotCloseValve(liquidTypes.waste, vol, drainSpeed);
    }
  }

  DrainToWasteWater(vol: number): void {
    if (vol === undefined || vol === 0) {
      vol = 1;
    }

    const factor = this.IPeristalticPump.getPumpFactor(0);
    const drainSpeed = setting.liquid.prefabricateDrainSpeed * factor;

    this.Drain(liquidTypes.wasteWater, vol + setting.liquid.multipleValvePipeVolume + setting.liquid.wastePipeVolume, drainSpeed);
  }

  GetMinDrainDigestionTimes(tatolVol: number): number {
    const point = setting.liquid.digestionRoomMeterPoint;
    const pointVol = config.hardware.meterPoint.point[point].setVolume;
    const minTimes = Math.floor(0.5 * tatolVol / pointVol + this.PRECISE) + 1;
    this.debugPrintf("tatolVol = %{public}d, minTimes = %{public}d", tatolVol, minTimes);
    return minTimes;
  }

  DrainFromDigestionRoomCheck(minTimes: number, wType?: WasteType, oneCmax?: number): void {
    const point = setting.liquid.digestionRoomMeterPoint;
    const pointVol = config.hardware.meterPoint.point[point].setVolume;

    const wasteType = wType === WasteType.WasteWater ? WasteType.WasteWater : WasteType.WasteReagent;

    const factor = this.IPeristalticPump.getPumpFactor(0);
    this.IOpticalMeter.setMeteSpeed(setting.liquid.drainSpeed * factor);
    this.debugPrintf("Set Meter Speed %{public}d", setting.liquid.drainSpeed * factor);

    let meterTimes = 0;

    this.SetMeterOverValue(MeterMode.Smart, 0);

    let actualPointVol = pointVol;
    if (oneCmax !== undefined && oneCmax > 0.1) {
      actualPointVol = oneCmax;
    }

    while (true) {
      try {
        this.Meter(MeterMode.Smart, liquidTypes.digestionRoom, actualPointVol, RollDirection.Suck);
        this.DrainToWaste(actualPointVol, wasteType);
        meterTimes = meterTimes + 1;
      } catch (err) {
        if (err instanceof Error) {
          hilog.warn(122, 'Operator', 'DrainFromDigestionRoomCheck error: %{public}s', err.message);
        }
        break;
      }
    }

    if (config.system.drainDigestRoomCheck === true && minTimes !== undefined && minTimes > 0) {
      if (meterTimes < minTimes) {
        this.debugPrintf("消解器排液异常,次数不足");
      } else if (meterTimes > minTimes * 2) {
        this.debugPrintf("消解器排液异常,次数过多");
      } else {
        this.debugPrintf("消解器排液完成");
      }
    } else {
      this.debugPrintf("消解器排液完成");
    }
  }

  DrainFromDigestionRoomCheckWithPressure(minTimes: number, wType?: WasteType): void {
    const point = setting.liquid.digestionRoomMeterPoint;
    const pointVol = config.hardware.meterPoint.point[point].setVolume;

    const wasteType = wType === WasteType.WasteWater ? WasteType.WasteWater : WasteType.WasteReagent;

    const factor = this.IPeristalticPump.getPumpFactor(0);
    this.IOpticalMeter.setMeteSpeed(setting.liquid.drainSpeed * factor);
    this.debugPrintf("Set Meter Speed %{public}d", setting.liquid.drainSpeed * factor);

    const drainSpeed = setting.liquid.prefabricateDrainSpeed * factor;

    this.SetMeterOverValue(MeterMode.Smart, 0);

    while (true) {
      try {
        this.Meter(MeterMode.Smart, liquidTypes.digestionRoom, pointVol, RollDirection.Suck);
        this.Drain(liquidTypes.digestionRoom, pointVol + setting.liquid.digestionRoomPipeVolume, 0);
      } catch (err) {
        if (err instanceof Error) {
          hilog.warn(122, 'Operator', 'DrainFromDigestionRoomCheckWithPressure error: %{public}s', err.message);
        }
        break;
      }
    }
  }

  CleanPipeFromDigestionRoom(source: LiquidType, vol: number, point?: number, wType?: WasteType): void {
    const wasteType = wType === WasteType.WasteWater ? WasteType.WasteWater : WasteType.WasteReagent;
    const factor = this.IPeristalticPump.getPumpFactor(0);
    const drainSpeed = setting.liquid.prefabricateDrainSpeed * factor;

    this.IOpticalMeter.setMeteSpeed(setting.liquid.drainSpeed * factor);
    this.debugPrintf("Set Meter Speed %{public}d", setting.liquid.drainSpeed * factor);

    const volTable = point ? this.AccurateMeterVolumeAnalyse(vol, point) : this.AutoMeterVolumeAnalyse(vol);

    for (const volume of volTable) {
      this.Meter(MeterMode.Smart, source, volume, RollDirection.Suck);
      this.DrainToWaste(volume, wasteType);
    }

    this.SecludeLiquid(source, 0.2);
  }

  DrainFromDigestionRoom(wType?: WasteType): void {
    const wasteType = wType === WasteType.WasteWater ? WasteType.WasteWater : WasteType.WasteReagent;
    const factor = this.IPeristalticPump.getPumpFactor(0);
    this.IOpticalMeter.setMeteSpeed(setting.liquid.drainSpeed * factor);

    const point = setting.liquid.digestionRoomMeterPoint;
    const pointVol = config.hardware.meterPoint.point[point].setVolume;

    this.SetMeterOverValue(MeterMode.Smart, 0);

    try {
      this.Meter(MeterMode.Smart, liquidTypes.digestionRoom, pointVol, RollDirection.Suck);
      this.DrainToWaste(pointVol, wasteType);
    } catch (err) {
      if (err instanceof Error) {
        hilog.warn(122, 'Operator', 'DrainFromDigestionRoom error: %{public}s', err.message);
      }
    }
  }

  MeterToSample(vol: number, point?: number): void {
    const factor = this.IPeristalticPump.getPumpFactor(0);
    const drainSpeed = setting.liquid.prefabricateDrainSpeed * factor;

    this.IOpticalMeter.setMeteSpeed(setting.liquid.meterSpeed * factor);
    this.debugPrintf("Set Meter Speed %{public}d", setting.liquid.meterSpeed * factor);

    this.SetMeterOverValue(MeterMode.Accurate, setting.liquid.accurateMeterOverValue);

    const volTable = point ? this.AccurateMeterVolumeAnalyse(vol, point) : this.AutoMeterVolumeAnalyse(vol);

    for (const volume of volTable) {
      this.Meter(MeterMode.Accurate, liquidTypes.sample, volume, RollDirection.Suck);
      this.Drain(liquidTypes.none, 0.3, 0.2);
    }
  }

  MeterFromDigestionRoom(vol: number, point?: number, wType?: WasteType): void {
    const wasteType = wType === WasteType.WasteWater ? WasteType.WasteWater : WasteType.WasteReagent;
    const factor = this.IPeristalticPump.getPumpFactor(0);
    this.IOpticalMeter.setMeteSpeed(setting.liquid.drainSpeed * factor);

    const volTable = point ? this.AccurateMeterVolumeAnalyse(vol, point) : this.AutoMeterVolumeAnalyse(vol);

    for (const volume of volTable) {
      this.Meter(MeterMode.Smart, liquidTypes.digestionRoom, volume, RollDirection.Suck);
      this.DrainToWaste(volume, wasteType);
    }
  }

  PumpFromDigestionRoom(vol: number, point?: number, wType?: WasteType): void {
    const wasteType = wType === WasteType.WasteWater ? WasteType.WasteWater : WasteType.WasteReagent;
    const factor = this.IPeristalticPump.getPumpFactor(0);
    this.IOpticalMeter.setMeteSpeed(setting.liquid.meterSpeed * factor * 0.5);
    this.debugPrintf("Set Meter Speed %{public}d", setting.liquid.meterSpeed * factor * 0.5);

    const drainSpeed = setting.liquid.prefabricateDrainSpeed * factor;

    let volTable: number[] = [];
    if (point === undefined) {
      volTable = this.AutoMeterVolumeAnalyse(vol);
    } else {
      volTable = this.SmartMeterVolumeAnalyse(vol, point);
    }

    for (const volume of volTable) {
      this.Meter(MeterMode.Smart, liquidTypes.digestionRoom, volume, RollDirection.Suck);
      this.DrainToWaste(volume, wasteType);
    }
  }

  DrainLiquid(source: LiquidType, vol: number, wType?: WasteType): void {
    const wasteType = wType === WasteType.WasteWater ? WasteType.WasteWater : WasteType.WasteReagent;
    const factor = this.IPeristalticPump.getPumpFactor(0);
    const drainSpeed = setting.liquid.prefabricateDrainSpeed * factor;

    this.DrainToWaste(0, wasteType);
    this.Drain(source, vol, drainSpeed);
  }

  CleanDigestionRoom(source: LiquidType, vol: number, wType?: WasteType): void {
    this.isStop = false;

    const wasteType = wType === WasteType.WasteWater ? WasteType.WasteWater : WasteType.WasteReagent;
    this.DrainToWaste(setting.liquid.meterPipeVolume);
    this.DrainFromDigestionRoom(wasteType);
    this.PumpToDigestionRoom(source, vol);
    this.DrainToWaste(0, wasteType);

    try {
      this.StartThermostat(ThermostatMode.Auto, 70, setting.temperature.toleranceTemp, 720);
      this.debugPrintf("到达消解目标温度 = 70℃");

      for (let i = 1; i <= 600; i++) {
        thread.sleep(1000);

        if (this.isStop) {
          throw new Error("User stopped");
        }
      }

      this.StopThermostat();
    } catch (err) {
      if (err instanceof Error) {
        hilog.warn(122, 'Operator', 'CleanDigestionRoom error: %{public}s', err.message);
      }
    }

    this.AirToDigestionRoom();
    this.DrainFromDigestionRoom(wasteType);
  }

  SimpleCleanDigestionRoom(source: LiquidType, vol: number, wType?: WasteType): void {
    const wasteType = wType === WasteType.WasteWater ? WasteType.WasteWater : WasteType.WasteReagent;

    this.PumpToDigestionRoom(source, vol);
    this.DrainToWaste(0, wasteType);
    this.DrainFromDigestionRoom(wasteType);
  }

  CleanMeterPipe(source: LiquidType, vol: number, point?: number, wType?: WasteType, speed?: number, secluded?: boolean): void {
    const wasteType = wType === WasteType.WasteWater ? WasteType.WasteWater : WasteType.WasteReagent;

    let actualSpeed = speed !== undefined ? speed : setting.liquid.drainSpeed;

    const factor = this.IPeristalticPump.getPumpFactor(0);
    this.IOpticalMeter.setMeteSpeed(actualSpeed * factor);
    this.debugPrintf("Set Meter Speed %{public}d", actualSpeed * factor);

    const drainSpeed = setting.liquid.prefabricateDrainSpeed * factor;

    const pointNum = config.hardware.meterPoint.num - 1;
    let maxMP = config.hardware.meterPoint.point[pointNum].setVolume;
    if (point !== undefined && point > 0.01) {
      maxMP = point;
    }

    const volTable = this.SmartMeterVolumeAnalyse(vol, maxMP);

    this.SetMeterOverValue(MeterMode.Smart, 0);

    for (const volume of volTable) {
      try {
        this.Meter(MeterMode.Smart, source, volume, RollDirection.Suck);
        this.DrainToWaste(volume, wasteType);
      } catch (err) {
        if (err instanceof Error) {
          hilog.warn(122, 'Operator', 'CleanMeterPipe error: %{public}s', err.message);
        }
      }
    }

    if (secluded === undefined || secluded === true) {
      this.SecludeLiquid(source, 0.2);
    }
  }

  ImmerseMeterPipe(source: LiquidType, vol: number, point?: number, wType?: WasteType, speed?: number): void {
    const wasteType = wType === WasteType.WasteWater ? WasteType.WasteWater : WasteType.WasteReagent;

    let actualSpeed = speed !== undefined ? speed : setting.liquid.drainSpeed;

    const factor = this.IPeristalticPump.getPumpFactor(0);
    this.IOpticalMeter.setMeteSpeed(actualSpeed * factor);
    this.debugPrintf("Set Meter Speed %{public}d", actualSpeed * factor);

    const drainSpeed = setting.liquid.prefabricateDrainSpeed * factor;

    const pointNum = config.hardware.meterPoint.num - 1;
    let maxMP = config.hardware.meterPoint.point[pointNum].setVolume;
    if (point !== undefined && point > 0.01) {
      maxMP = point;
    }

    const volTable = this.SmartMeterVolumeAnalyse(vol, maxMP);

    this.SetMeterOverValue(MeterMode.Smart, 0);

    for (const volume of volTable) {
      try {
        this.Meter(MeterMode.Smart, source, volume, RollDirection.Suck);
        this.DrainToWaste(volume, wasteType);
      } catch (err) {
        if (err instanceof Error) {
          hilog.warn(122, 'Operator', 'ImmerseMeterPipe error: %{public}s', err.message);
        }
      }
    }

    this.SecludeLiquid(source, 0.2);
  }

  CleanMeterPipeToPoint(source: LiquidType, vol: number, point: number, wType?: WasteType): void {
    this.CleanMeterPipe(source, vol, point, wType, undefined, true);
  }

  CleanReagentPipe(source: LiquidType, vol: number, wType?: WasteType): void {
    const wasteType = wType === WasteType.WasteWater ? WasteType.WasteWater : WasteType.WasteReagent;
    const factor = this.IPeristalticPump.getPumpFactor(0);
    const drainSpeed = setting.liquid.prefabricateDrainSpeed * factor;

    this.IOpticalMeter.setMeteSpeed(setting.liquid.drainSpeed * factor);
    this.debugPrintf("Set Meter Speed %{public}d", setting.liquid.drainSpeed * factor);

    this.SetMeterOverValue(MeterMode.Smart, 0);

    try {
      const volTable = this.SmartMeterVolumeAnalyse(vol);
      for (const volume of volTable) {
        this.Meter(MeterMode.Smart, source, volume, RollDirection.Suck);
        this.DrainToWaste(volume, wasteType);
      }
    } catch (err) {
      if (err instanceof Error) {
        hilog.warn(122, 'Operator', 'CleanReagentPipe error: %{public}s', err.message);
      }
    }

    this.SecludeLiquid(source, 0.2);
  }

  ClearReagentPipe(source: LiquidType, wType?: WasteType): void {
    const wasteType = wType === WasteType.WasteWater ? WasteType.WasteWater : WasteType.WasteReagent;
    const factor = this.IPeristalticPump.getPumpFactor(0);
    const drainSpeed = setting.liquid.prefabricateDrainSpeed * factor;

    this.DrainToWaste(0, wasteType);
    this.SecludeLiquid(source);
  }
  MeterVolumeAnalyse(vol: number): number[] {
    const pointNum = config.hardware.meterPoint.num - 1;
    const maxMP = config.hardware.meterPoint.point[pointNum].setVolume;
    const minMP = config.hardware.meterPoint.point[1].setVolume;

    const count = Math.floor(vol / maxMP);
    const residue = vol - count * maxMP;
    const lDV = residue - minMP;
    const sDV = residue - minMP * 0.001;

    const volTable: number[] = [];

    if (count === 0) {
      volTable.push(residue);
    } else if (count > 0) {
      if (-this.PRECISE <= residue && residue <= this.PRECISE) {
        for (let i = 0; i < count; i++) {
          volTable.push(maxMP);
        }
      } else if (-this.PRECISE <= lDV) {
        for (let i = 0; i < count; i++) {
          volTable.push(maxMP);
        }
        volTable.push(residue);
      } else {
        if (-this.PRECISE <= sDV) {
          let num = 0;
          for (let i = 0; i < count; i++) {
            num = num + 1;
            if ((maxMP * num + residue) / 2 - minMP >= this.PRECISE) {
              break;
            }
          }

          if ((count - num) === 0) {
            volTable.push(minMP);
            volTable.push(vol - minMP);
          } else {
            for (let i = 0; i < (count - num); i++) {
              volTable.push(maxMP);
            }
            volTable.push((maxMP * num + residue) / 2);
            volTable.push((maxMP * num + residue) / 2);
          }
        } else {
          for (let i = 0; i < count; i++) {
            volTable.push(maxMP);
          }
        }
      }
    }

    if (volTable.length === 0) {
      return volTable;
    }

    return volTable;
  }

  AutoMeterVolumeAnalyse(vol: number): number[] {
    const ret = false;
    const mpTable: number[] = [];
    const pointNum = config.hardware.meterPoint.num - 1;

    for (let i = 1; i <= pointNum; i++) {
      mpTable[i - 1] = config.hardware.meterPoint.point[1 + pointNum - i].setVolume;
    }

    const volTable: number[] = [];
    let leftVol = vol;
    let retFlag = false;

    for (let k = 0; k < pointNum; k++) {
      for (let i = k; i < pointNum; i++) {
        while (leftVol > mpTable[i] - this.PRECISE && leftVol > 0) {
          volTable.push(mpTable[i]);
          leftVol = leftVol - mpTable[i];
          if (Math.abs(leftVol) < this.PRECISE) {
            retFlag = true;
            break;
          }
        }
        if (retFlag) {
          break;
        }
      }
      if (retFlag) {
        break;
      } else {
        volTable.length = 0;
        leftVol = vol;
      }
    }

    if (!retFlag) {
      hilog.warn(122, 'Operator', 'AutoMeterVolumeAnalyse: 自动分解定量体积不是定量点体积的倍数');
    }

    return volTable;
  }

  AccurateMeterVolumeAnalyse(vol: number, point: number): number[] {
    const volTable: number[] = [];

    let MP: number;
    if (point >= 0 && point <= config.hardware.meterPoint.num - 1) {
      MP = config.hardware.meterPoint.point[point].setVolume;
    } else {
      hilog.warn(122, 'Operator', 'AccurateMeterVolumeAnalyse: 无效的定量点');
      return volTable;
    }
    hilog.warn(122, 'Operator', 'AccurateMeterVolumeAnalyse vol: %{public}d MP: %{public}d', vol, MP);
    if ((vol - MP > this.PRECISE) || (-this.PRECISE <= vol - MP && vol - MP <= this.PRECISE)) {
      const count = Math.floor(vol / MP);
      const residue = vol - count * MP;

      if (-this.PRECISE <= residue && residue <= this.PRECISE) {
        for (let i = 0; i < count; i++) {
          volTable.push(MP);
        }
      } else {
        hilog.warn(122, 'Operator', 'AccurateMeterVolumeAnalyse: 精确定量体积不是定量点体积的倍数');
      }
    } else {
      hilog.warn(122, 'Operator', 'AccurateMeterVolumeAnalyse: 精确定量体积小于定量点体积');
    }

    return volTable;
  }

  SmartMeterVolumeAnalyse(vol: number, onceMax?: number): number[] {
    let maxMP = onceMax !== undefined ? onceMax : config.hardware.meterPoint.point[config.hardware.meterPoint.num-1].setVolume;
    const minMP = config.hardware.meterPoint.point[0].setVolume;

    const count = Math.floor(vol / maxMP);
    const residue = vol - count * maxMP;
    const lDV = residue - minMP;
    const sDV = residue - minMP * 0.001;

    const volTable: number[] = [];

    if (count === 0) {
      volTable.push(residue);
    } else if (count > 0) {
      if (-this.PRECISE <= residue && residue <= this.PRECISE) {
        for (let i = 0; i < count; i++) {
          volTable.push(maxMP);
        }
      } else if (-this.PRECISE <= lDV) {
        for (let i = 0; i < count; i++) {
          volTable.push(maxMP);
        }
        volTable.push(residue);
      } else {
        if (-this.PRECISE <= sDV) {
          let num = 0;
          for (let i = 0; i < count; i++) {
            num = num + 1;
            if ((maxMP * num + residue) / 2 - minMP >= this.PRECISE) {
              break;
            }
          }

          if ((count - num) === 0) {
            volTable.push(minMP);
            volTable.push(vol - minMP);
          } else {
            for (let i = 0; i < (count - num); i++) {
              volTable.push(maxMP);
            }
            volTable.push((maxMP * num + residue) / 2);
            volTable.push((maxMP * num + residue) / 2);
          }
        } else {
          for (let i = 0; i < count; i++) {
            volTable.push(maxMP);
          }
        }
      }
    }

    if (volTable.length === 0) {
      hilog.warn(122, 'Operator', 'SmartMeterVolumeAnalyse: 体积分解异常');
      return volTable;
    }

    return volTable;
  }

  ForceMeterVolumeAnalyseByPoint(vol: number, point: number): number[] {
    const volTable: number[] = [];
    const unitVolume = config.hardware.meterPoint.point[point].setVolume;
    let leftVol = vol;

    if (vol > unitVolume - this.PRECISE && vol % unitVolume < this.PRECISE) {
      while (leftVol > unitVolume - this.PRECISE && leftVol > 0) {
        volTable.push(unitVolume);
        leftVol = leftVol - unitVolume;
        if (Math.abs(leftVol) < this.PRECISE) {
          break;
        }
      }
    }

    if (volTable.length === 0) {
      hilog.warn(122, 'Operator', 'ForceMeterVolumeAnalyseByPoint: 强制分解定量体积不是定量点体积的倍数');
    }

    return volTable;
  }

  StartThermostat(mode: ThermostatMode, targetTemp: number, tolerance: number, timeout: number): number {
    let temp = 0;

    this.ITemperatureControl.startThermostat(mode, targetTemp, tolerance, timeout);

    this.debugPrintf("{StartThermostat} mode = %{public}d, targetTemp = %{public}d, tolerance = %{public}d, timeout = %{public}d",
      mode, targetTemp, tolerance, timeout);
    this.isThermostat = true;

    const result = this.ITemperatureControl.expectThermostat(timeout * 1000 + 1000);

    this.debugPrintf("{thermostatResult} result = %{public}d, temp = %{public}d", result.result, result.temp);

    if (result.result === ThermostatOperateResult.Failed) {
      this.isThermostat = false;
    } else if (result.result === ThermostatOperateResult.Stopped) {
      this.isThermostat = false;
    } else if (result.result === ThermostatOperateResult.Timeout) {
      this.isThermostat = false;
    } else if (result.result === ThermostatOperateResult.Reached) {
      this.isThermostat = false;
    }
    temp = result.temp;

    return temp;
  }

  StopThermostat(): number {
    let temp = 0;

    const ret = this.ITemperatureControl.stopThermostat();

    if (ret) {
      this.debugPrintf("{StopThermostat}");
      const result = this.ITemperatureControl.expectThermostat(5000);
      temp = result.temp;
      this.debugPrintf("{thermostatResult} result = %{public}d, temp = %{public}d", result.result, result.temp);

      if (result.result === ThermostatOperateResult.Stopped) {
        this.isThermostat = false;
      }
    }

    return temp;
  }

  CheckDigestSafety(): void {
    const safeTemp = setting.temperature.digestSafetyTemp;

    const thermostatTemp = this.ITemperatureControl.getTemperature();
    this.debugPrintf("安全冷却前温度 = %{public}d ℃", thermostatTemp.thermostatTemp);

    const tempDiff = thermostatTemp.thermostatTemp - safeTemp;

    if (tempDiff > 0.01) {
      this.StartThermostat(ThermostatMode.Refrigerate, safeTemp, 1, setting.temperature.digestToReactCoolingTimeout);
      this.debugPrintf("到达安全冷却目标温度 = %{public}d ℃", thermostatTemp.thermostatTemp);
    }
  }

  StartAcquirerAD(acquireTime: number): OpticalAD {
    let AD: OpticalAD = {reference:0, measure:0};
    let temp: OpticalAD = {reference:0, measure:0};

    const timeout = acquireTime * 1000 + 1000;
    this.isAcquiring = true;
    const startResult = this.IOpticalAcquire.startAcquirer(acquireTime);
    if (startResult) {
      try {
        const result = this.IOpticalAcquire.expectADAcquirer(timeout);
        if (result.result === AcquiredOperateResult.Failed) {
          this.isAcquiring = false;
          throw new Error("AcquirerADFailedException");
        } else if (result.result === AcquiredOperateResult.Stopped) {
          this.isAcquiring = false;
          throw new Error("AcquirerADStoppedException");
        } else if (result.result === AcquiredOperateResult.Finished) {
          temp = result.ad;
        }

        this.isAcquiring = false;

        AD = temp;
      } catch (err) {
        this.isAcquiring = false;
        if (err instanceof Error) {
          hilog.warn(122, 'Operator', 'StartAcquirerAD error: %{public}s', err.message);
        }
        throw new Error(err);
      }
    }
    return AD;
  }

  StartAcquirerADWithFiltration(acquireTime: number): OpticalAD {
    const readAdTime = 1;
    const referenceAD: number[] = [];
    const measureAD: number[] = [];
    let temp = 0;
    let referenceADSumData = 0;
    let measureADSumData = 0;
    const filterNum = Math.floor(acquireTime / 5);

    const retAD: OpticalAD = {reference: 0, measure: 0};

    for (let i = 1; i <= acquireTime; i += readAdTime) {
      const ad = this.StartAcquirerAD(readAdTime);
      referenceAD[i - 1] = ad.reference;
      measureAD[i - 1] = ad.measure;
    }

    for (let i = 1; i <= acquireTime; i++) {
      this.debugPrintf("referenceAD[%{public}d] = %{public}d measureAD[%{public}d] = %{public}d",
        i, referenceAD[i - 1], i, measureAD[i - 1]);
    }

    for (let i = 1; i < acquireTime; i++) {
      for (let j = acquireTime; j > i; j--) {
        if (referenceAD[j - 1] < referenceAD[j - 2]) {
          temp = referenceAD[j - 2];
          referenceAD[j - 2] = referenceAD[j - 1];
          referenceAD[j - 1] = temp;
        }
        if (measureAD[j - 1] < measureAD[j - 2]) {
          temp = measureAD[j - 2];
          measureAD[j - 2] = measureAD[j - 1];
          measureAD[j - 1] = temp;
        }
      }
    }

    for (let i = filterNum; i < acquireTime - filterNum; i++) {
      referenceADSumData = referenceADSumData + referenceAD[i - 1];
      measureADSumData = measureADSumData + measureAD[i - 1];
    }

    const ret1 = Math.floor(referenceADSumData / (acquireTime - filterNum * 2));
    const ret2 = Math.floor(measureADSumData / (acquireTime - filterNum * 2));

    retAD.reference = ret1;
    retAD.measure = ret2;

    return retAD;
  }

  dryFireDitect(): number {
    const dest = liquidTypes.digestionRoom;
    const volume = 1000000;
    const speed = setting.liquid.pumpAirSpeed * 1.5;
    const map = new ValveMap(dest.valve);
    const readADCount = 50;
    const absorbance: number[] = [];

    let rsd = 0;


    this.debugPrintf("{Drain} dest = %{public}s, volume = %{public}d, speed = %{public}d", dest.name, volume, speed);

    try {
      const valveResult = this.ISolenoidValve.setValveMap(map);
      if (!valveResult) {
        return 0;
      }

      const Result = this.IPeristalticPump.startPump(dest.pump, RollDirection.Drain, volume, speed);
      if (!Result) {
        return 0;
      }

      thread.sleep(5000);

      for (let i = 1; i <= readADCount; i++) {
        const ad = this.StartAcquirerAD(setting.signal.dryFireReadADTime);
        const initReference = ad.reference;
        const initMeasure = ad.measure;
        absorbance[i - 1] = initMeasure - initReference;
        this.debugPrintf("第%{public}d次读取吸光度 = %{public}d", i, absorbance[i - 1]);
      }

      map.setData(0);
      this.ISolenoidValve.setValveMap(map);

    } catch (err) {
      if (err instanceof Error) {
        hilog.warn(122, 'Operator', 'dryFireDitect error: %{public}s', err.message);
      }
    }

    return rsd;
  }

  AutoStaticADControl(index: number, target: number): boolean {
    const timeout = 120 * 1000;

    // const ret =
    this.IOpticalAcquire.startStaticADControl(index,target);

    // if ret === true then
    //   this.isStaticADControl = true
      this.debugPrintf("Auto static AD control started index = %{public}d target = %{public}d", index, target);

      const result = this.IOpticalAcquire.expectStaticADControlResult(timeout);

      if (result === StaticADControlResult.Unfinished){
        this.debugPrintf("Auto static AD control Unfinished ");
        return false;
      } else if (result === StaticADControlResult.Finished){
        this.debugPrintf("Auto static AD control Finished ");
        return true;
      }
      else {
        this.debugPrintf("Auto static AD control Unknow %{public}%d ", result);
      }
    // end
    return false;
  }

  StopStaticADControl(): boolean {
    return this.IOpticalAcquire.stopStaticADControl();
  }

  SaveCalibrationTimeStr(timeStr: string): void {
    hilog.info(122, 'Operator', 'SaveCalibrationTimeStr: %{public}s', timeStr);
  }

  CalculateAbsorbance(refAD: number, meaAD: number): number {
    const absorbance = refAD - meaAD;
    return absorbance;
  }

  SaveUserCurve(curveData: number[]): boolean {
    hilog.info(122, 'Operator', 'SaveUserCurve');
    return true;
  }

  GetCurveParam(): number[] {
    hilog.info(122, 'Operator', 'GetCurveParam');
    return [];
  }

  CheckSCAgreement(): number {
    hilog.info(122, 'Operator', 'CheckSCAgreement');
    return 0;
  }

  // ValveCheck(checkNum?: number): boolean {
  //   let isRepeated = false;
  //
  //   for (const [key, value] of Object.entries(config.system.valveSetting)) {
  //     if ((liquidTypes as Record<string, LiquidType>)[key] !== undefined) {
  //       const liquidType = (liquidTypes as Record<string, LiquidType>)[key];
  //       if (liquidType.valve !== undefined) {
  //         if (typeof value === 'number') {
  //           const valveName = 'valve' + value;
  //           if (liquidType.valve !== (setting.liquidType.map as Record<string, number>)[valveName]) {
  //             this.debugPrintf("%{public}s 阀配置更改为 valve%{public}d", key, value);
  //           }
  //         } else if (Array.isArray(value)) {
  //           let valveSum = 0;
  //           for (const num of value as number[]) {
  //             const valveName = 'valve' + num;
  //             valveSum = valveSum + (setting.liquid.map as Record<string, number>)[valveName];
  //           }
  //           if (liquidType.valve !== valveSum) {
  //             this.debugPrintf("%{public}s 阀配置更改为 %{public}s", key, JSON.stringify(value));
  //           }
  //         }
  //
  //         if (checkNum !== undefined) {
  //           if (typeof value === 'number' && checkNum === value) {
  //             isRepeated = true;
  //           } else if (Array.isArray(value) && (value as number[]).includes(checkNum)) {
  //             isRepeated = true;
  //           }
  //         }
  //       }
  //     }
  //   }
  //
  //   return isRepeated;
  // }

  DrainWithPressure(dest: LiquidType, times: number, pressureVol: number, forcingVol: number, pipeVol: number, speed: number): boolean {
    let ret = false;
    const timeout = Math.floor((pressureVol + forcingVol) * setting.liquid.meterLimit.pumpTimeoutFactor);
    const map = new ValveMap(dest.valve);
    const closeMap = new ValveMap(0);

    this.isStop = false;

    this.debugPrintf("{加压排液}：%{public}s, 不开阀排液体积(加压) = %{public}d, 开阀排液体积 = %{public}d, 速度 = %{public}d",
      dest.name, pressureVol, forcingVol + pipeVol, speed);

    const closeValveTime = Math.floor(1000 * (pressureVol / speed));
    const openValveTime = Math.floor(1000 * (forcingVol / speed));

    try {
      const Result = this.IPeristalticPump.startPump(dest.pump, RollDirection.Drain, (times * (pressureVol + forcingVol) + pipeVol), speed);
      if (!Result) {
        return false;
      }

      for (let i = 1; i <= times; i++) {
        this.ISolenoidValve.setValveMap(closeMap);

        if (closeValveTime > 0) {
          thread.sleep(closeValveTime);
        }

        if (this.isStop) {
          throw new Error("User stopped");
        }

        this.ISolenoidValve.setValveMap(map);

        if (openValveTime > 0 && times > i) {
          thread.sleep(openValveTime);
        }

        if (this.isStop) {
          throw new Error("User stopped");
        }
      }

      const pumpResult = this.IPeristalticPump.expectPumpResult(timeout);
      map.setData(0);
      this.ISolenoidValve.setValveMap(map);

      if (pumpResult.result === PumpOperateResult.Finished) {
        ret = true;
      }
    } catch (err) {
      if (err instanceof Error) {
        hilog.warn(122, 'Operator', 'DrainWithPressure error: %{public}s', err.message);
      }
    }

    ReagentRemainManager.getInstance().RecoverReagent(dest, (pressureVol + forcingVol));
    return ret;
  }

  ForcingCleanPipe(source: LiquidType, blankVol: number, pressureVol: number, forcingVol: number, forcingSpeed: number): void {
    const wasteType = WasteType.WasteWater;

    try {
      this.Meter(MeterMode.Smart, liquidTypes.blank, blankVol, RollDirection.Suck);
      this.Drain(source, forcingVol, forcingSpeed);
      this.DrainToWaste(0);
    } catch (err) {
      if (err instanceof Error) {
        hilog.warn(122, 'Operator', 'ForcingCleanPipe error: %{public}s', err.message);
      }
    }
  }

  ValveReSet(valveTable: number[]): void {
    if (config.system.valveSetting.sample !== valveTable[0]) {
      config.system.valveSetting.sample = valveTable[0];
    }
    if (config.system.valveSetting.standard !== valveTable[1]) {
      config.system.valveSetting.standard = valveTable[1];
    }
    if (config.system.valveSetting.blank !== valveTable[2]) {
      config.system.valveSetting.blank = valveTable[2];
    }
    if (config.system.valveSetting.digestionRoom[0] !== valveTable[3]) {
      config.system.valveSetting.digestionRoom[0] = valveTable[3];
    }
    if (config.system.valveSetting.digestionRoom[1] !== valveTable[4]) {
      config.system.valveSetting.digestionRoom[1] = valveTable[4];
    }
    if (config.system.valveSetting.wasteWater !== valveTable[5]) {
      config.system.valveSetting.wasteWater = valveTable[5];
    }
    if (config.system.valveSetting.waste !== valveTable[6]) {
      config.system.valveSetting.waste = valveTable[6];
    }
    if (config.system.valveSetting.reagent1 !== valveTable[7]) {
      config.system.valveSetting.reagent1 = valveTable[7];
    }
    if (config.system.valveSetting.reagent2 !== valveTable[8]) {
      config.system.valveSetting.reagent2 = valveTable[8];
    }
    if (config.system.valveSetting.zeroCheck !== valveTable[9]) {
      config.system.valveSetting.zeroCheck = valveTable[9];
    }
    if (config.system.valveSetting.rangeCheck !== valveTable[10]) {
      config.system.valveSetting.rangeCheck = valveTable[10];
    }
  }

}

// ✅ 模块级常量：整个模块只创建一次
// TaskPool 序列化时会识别为同一份数据，不会重复构造
// export const SHARED_OPERATOR: Operator = new Operator();