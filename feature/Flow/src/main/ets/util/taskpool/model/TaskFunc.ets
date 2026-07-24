// 执行方法类，所有方法定义在此

import { ParamA, TestData } from './TaskParam';
import { taskpool } from '@kit.ArkTS';
import { Operator, WasteType } from '../../../Flow/Operator';
import { liquidTypes } from '../../../Setting/LiquidType';
import { config, status } from '../../../Config/Config'
import { setting, RangeConfig } from '../../../Setting/Setting';
import { ActionItem } from '../../../Setting/RunAction';
import { MeasureType, MeasureConfig } from '../../../Flow/MeasureFlow';
import { thread, DateTimeUtil } from 'base';
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

import { hilog } from "@kit.PerformanceAnalysisKit";

import { Measurer } from '../../../Flow/Measurer'
import { MeasureResult } from '../../../Flow/Measurer'

@Concurrent
export async function executeX(paramA: ParamA): Promise<number> {
  return paramA.getA() + paramA.getB();
}

@Concurrent
export async function executeY(testClass: TestData): Promise<TestData> {
  testClass.setName('newName');
  return testClass;
}

@Concurrent
export async function executeZ(): Promise<number> {
  taskpool.Task.sendData(100);
  return 1;
}

@Concurrent
export async function executeA(): Promise<number> {
  return 1;
}

@Concurrent
export async function drainBeforeMeasure(): Promise<number> {
  const startTime = DateTimeUtil.getTimestamp();
  const op = Operator.getInstance();
  op.DrainToWaste(setting.liquid.meterPipeVolume, WasteType.WasteWater);
  op.AirToDigestionRoom();
  hilog.info(122, 'Measurer', '测量前排液时间 = %{public}d', DateTimeUtil.getTimestamp() - startTime);
  return 1;
}

@Concurrent
export async function cleanBeforeMeasure(): Promise<number> {
  const startTime = DateTimeUtil.getTimestamp();
  const op = Operator.getInstance();

  // if (this.measureType === MeasureType.Blank) {
  //   const cleanAftMeaBlankVol = 1;
  //   // op.CleanMeterPipe(liquidTypes.blank, 1.2, 1.2, WasteType.WasteWater, 300);
  //   for (let i = 1; i <= 1; i++) {
  //     // op.PumpToDigestionRoom(liquidTypes.blank, cleanAftMeaBlankVol, 2.2, WasteType.WasteWater);
  //     // op.Pump(liquidTypes.digestionRoom, 2.2, 0.2, false);
  //     // op.DrainToWaste(2.2, WasteType.WasteWater);
  //   }
  //   // op.SecludeLiquid(liquidTypes.blank);
  //   // op.DrainFromDigestionRoomCheck(nil, WasteType.WasteWater, 2);
  // }

  // if (!status.measureStatus.digestionRoomIsBlank)
  {
    let cleanTimes = 1;
    let cleanAftMeaBlankVol = setting.liquid.cleanVolume.cleanAftMeaBlankVol;
    if (config.measureParam.wasteWaterEnvironment) {
      cleanAftMeaBlankVol = setting.liquid.cleanVolume.cleanAftMeaBlankVol;
    }
    if (config.measureParam.tapWaterEnvironment) {
      cleanAftMeaBlankVol = setting.liquid.cleanVolume.cleanAftMeaBlankVol;
      cleanTimes = 2;
    }

    for (let i = 1; i <= cleanTimes; i++) {
      if (cleanAftMeaBlankVol > 0) {
        op.PumpToDigestionRoom(liquidTypes.blank, cleanAftMeaBlankVol, 0);
        op.DrainToWaste(0);
        op.SecludeLiquid(liquidTypes.blank);
        op.DrainFromDigestionRoomCheck(3, WasteType.WasteWater, 2);
      }
    }
  }

  if (config.measureParam.cleanBefMeaBlankVol > 0 && status.measureStatus.digestionRoomIsBlank) {
    // op.PumpToDigestionRoom(liquidTypes.blank, config.measureParam.cleanBefMeaBlankVol, 2, WasteType.WasteWater);
    // op.DrainToWaste(0, WasteType.WasteWater);
    // op.SecludeLiquid(liquidTypes.blank);
    // op.DrainFromDigestionRoom(WasteType.WasteWater, false, 2);
  }

  // if (this.TimeCheck() && status.measureStatus.digestionRoomIsBlank) {
  //   hilog.info(122, 'Measurer', '二次清洗');
  //   status.measureStatus.lastMeasureEndTime = DateTimeUtil.getTimestamp();
  //   // ConfigLists.SaveMeasureStatus();
  //   // op.PumpToDigestionRoom(liquidTypes.blank, 6, 2, WasteType.WasteWater);
  //   // op.DrainToWaste(0, WasteType.WasteWater);
  //   // op.SecludeLiquid(liquidTypes.blank);
  //   // op.DrainFromDigestionRoom(WasteType.WasteWater, false, 2);
  // }

  status.measureStatus.digestionRoomIsBlank = true;
  // ConfigLists.SaveMeasureStatus();

  hilog.info(122, 'Measurer', '测量前清洗时间 = %{public}d', DateTimeUtil.getTimestamp() - startTime);
  return 1;
}

@Concurrent
export async function rinse(): Promise<number> {
  const startTime = DateTimeUtil.getTimestamp();
  const op = Operator.getInstance();
  // const RinseVolume = this.GetRinseVol();

  const RinseVolume = 6;

  op.Pump(liquidTypes.sample, 2, 0.3, false);
  op.DrainToWaste(2, WasteType.WasteWater);
  op.CleanMeterPipe(liquidTypes.sample, config.measureParam.sampleRenewVolume, 2, WasteType.WasteWater, 200, false);

  // op.Pump(liquidTypes.digestionRoom, 1, 0.2, false);
  // op.DrainToWaste(1);

  hilog.info(122, 'Measurer', '润洗时间 = %{public}d', DateTimeUtil.getTimestamp() - startTime);
  return 1;
}

@Concurrent
export async function addSample(measureConfig: MeasureConfig): Promise<number> {
  const startTime = DateTimeUtil.getTimestamp();
  const op = Operator.getInstance();
  const cleanMeterPipevolume = 2.4;

  console.info(`Measure ${JSON.stringify(measureConfig.addParam)}`);

  if (measureConfig.addParam.sampleVolume && measureConfig.addParam.sampleVolume > 0) {
    console.info("measure sample");
    op.MeterToDigestionRoom(liquidTypes.sample, measureConfig.addParam.sampleVolume, 1, WasteType.WasteWater);
    op.DrainLiquid(liquidTypes.sample, setting.liquid.samplePipeVolume + config.measureParam.extendSamplePipeVolume, WasteType.WasteWater);
    let CleanPipeTimes = 1;
    if (config.measureParam.wasteWaterEnvironment || config.measureParam.tapWaterEnvironment) {
      CleanPipeTimes = 2;
    }
    for (let i = 1; i <= CleanPipeTimes; i++) {
      op.Pump(liquidTypes.none, 0.5, 0.2, false);
      op.CleanMeterPipe(liquidTypes.blank, 2.4, 2.4, WasteType.WasteWater, setting.liquid.drainSpeed, false);
    }

    // const factor = dc.GetIPeristalticPump().GetPumpFactor(0);
    // const drainSpeed = 500 * factor;
    // op.SetMeterOverValue(MeterMode.Smart, 0);
    // op.ForcingCleanPipe(liquidTypes.sample, 2, 0.5, 0.7, drainSpeed);
    // op.SecludeLiquid(liquidTypes.blank);
    // op.SecludeLiquid(liquidTypes.sample, 0.2);

    if (config.measureParam.cleanSampleVol > 0) {
      // op.DrainToWaste(0, WasteType.WasteReagent);
      // op.MeterToSample(liquidTypes.blank, config.measureParam.cleanSampleVol, WasteType.WasteReagent);
      // op.SecludeLiquid(liquidTypes.blank);
      // op.DrainLiquid(liquidTypes.sample, setting.liquid.samplePipeVolume + config.measureParam.extendSamplePipeVolume, WasteType.WasteReagent);
    }
  }

  if (measureConfig.addParam.standardVolume && measureConfig.addParam.standardVolume > 0) {
    console.info("measure standard");
    // op.MeterToDigestionRoom(liquidTypes.standard, measureConfig.addParam.standardVolume, 1, WasteType.WasteWater);
    // op.DrainToWaste(0, WasteType.WasteWater);
    // op.SecludeLiquid(liquidTypes.standard, 0.3);

    let CleanPipeTimes = 1;
    if (config.measureParam.wasteWaterEnvironment || config.measureParam.tapWaterEnvironment) {
      CleanPipeTimes = 2;
    }
    for (let i = 1; i <= CleanPipeTimes; i++) {
      // op.Pump(liquidTypes.none, 0.5, 0.2, false);
      // op.CleanMeterPipe(liquidTypes.blank, cleanMeterPipevolume, 2.4);
    }
    // op.Pump(liquidTypes.none, 0.5, 0.2, false);
    // op.CleanMeterPipe(liquidTypes.blank, 1, 1);
  }

  if (measureConfig.addParam.zeroCheckVolume && measureConfig.addParam.zeroCheckVolume > 0) {
    console.info("measure zerocheck");
    op.MeterToDigestionRoom(liquidTypes.zeroCheck, measureConfig.addParam.zeroCheckVolume, 1, WasteType.WasteWater);
    op.DrainToWaste(0, WasteType.WasteWater);
    op.SecludeLiquid(liquidTypes.zeroCheck, 0.3);

    let CleanPipeTimes = 1;
    if (config.measureParam.wasteWaterEnvironment || config.measureParam.tapWaterEnvironment) {
      CleanPipeTimes = 2;
    }
    for (let i = 1; i <= CleanPipeTimes; i++) {
      op.Pump(liquidTypes.none, 0.5, 0.2, false);
      op.CleanMeterPipe(liquidTypes.blank, cleanMeterPipevolume, 2.4);
    }
    // op.Pump(liquidTypes.none, 0.5, 0.2, false);
    // op.CleanMeterPipe(liquidTypes.blank, 1, 1);
  }

  if (measureConfig.addParam.rangeCheckVolume && measureConfig.addParam.rangeCheckVolume > 0) {
    console.info("measure rangecheck");
    op.MeterToDigestionRoom(liquidTypes.rangeCheck, measureConfig.addParam.rangeCheckVolume, 1, WasteType.WasteWater);
    op.DrainToWaste(0, WasteType.WasteWater);
    op.SecludeLiquid(liquidTypes.rangeCheck, 0.3);

    let CleanPipeTimes = 1;
    if (config.measureParam.wasteWaterEnvironment || config.measureParam.tapWaterEnvironment) {
      CleanPipeTimes = 2;
    }
    for (let i = 1; i <= CleanPipeTimes; i++) {
      op.Pump(liquidTypes.none, 0.5, 0.2, false);
      op.CleanMeterPipe(liquidTypes.blank, cleanMeterPipevolume, 2.4);
    }
    // op.Pump(liquidTypes.none, 0.5, 0.2, false);
    // op.CleanMeterPipe(liquidTypes.blank, 1, 1);
  }

  status.measureStatus.digestionRoomIsBlank = false;
  // ConfigLists.SaveMeasureStatus();

  if (measureConfig.addParam.blankVolume && measureConfig.addParam.blankVolume > 0) {
    console.info("measure blank");
    op.Pump(liquidTypes.none, 0.5, 0.2, false);
    op.Pump(liquidTypes.blank, 0.8, 0.2, false);
    op.DrainToWaste(0, WasteType.WasteWater);
    op.MeterToDigestionRoom(liquidTypes.blank, measureConfig.addParam.blankVolume, 1, WasteType.WasteWater);
    op.DrainToWaste(0, WasteType.WasteWater);
    op.SecludeLiquid(liquidTypes.blank, 0.3);
  }

  if (measureConfig.addParam.dilutionExtractVolume1 && measureConfig.addParam.dilutionExtractVolume1 > 0) {
    op.AirToDigestionRoom(10);
    op.MeterFromDigestionRoom(measureConfig.addParam.dilutionExtractVolume1, 1, WasteType.WasteWater);
    op.SecludeLiquid(liquidTypes.digestionRoom);
    op.Pump(liquidTypes.none, 0.5, 0.2, false);
    op.CleanMeterPipe(liquidTypes.blank, cleanMeterPipevolume, 2.4, WasteType.WasteWater);
  }

  if (measureConfig.addParam.dilutionAddBlankVolume1 && measureConfig.addParam.dilutionAddBlankVolume1 > 0) {
    op.Pump(liquidTypes.none, 0.5, 0.2, false);
    op.Pump(liquidTypes.blank, 0.8, 0.2, false);
    op.DrainToWaste(0, WasteType.WasteWater);
    op.MeterToDigestionRoom(liquidTypes.blank, measureConfig.addParam.dilutionAddBlankVolume1, 1, WasteType.WasteWater);
    op.DrainToWaste(0, WasteType.WasteWater);
    op.SecludeLiquid(liquidTypes.blank, 0.3);
  }

  if (measureConfig.addParam.dilutionExtractVolume2 && measureConfig.addParam.dilutionExtractVolume2 > 0) {
    op.AirToDigestionRoom(10);
    op.MeterFromDigestionRoom(measureConfig.addParam.dilutionExtractVolume2, 1, WasteType.WasteWater);
    op.SecludeLiquid(liquidTypes.digestionRoom);
    op.Pump(liquidTypes.none, 0.5, 0.2, false);
    op.CleanMeterPipe(liquidTypes.blank, cleanMeterPipevolume, 2.4, WasteType.WasteWater);
  }

  if (measureConfig.addParam.dilutionAddBlankVolume2 && measureConfig.addParam.dilutionAddBlankVolume2 > 0) {
    op.Pump(liquidTypes.none, 0.5, 0.2, false);
    op.Pump(liquidTypes.blank, 0.8, 0.2, false);
    op.DrainToWaste(0, WasteType.WasteWater);
    op.MeterToDigestionRoom(liquidTypes.blank, measureConfig.addParam.dilutionAddBlankVolume2, 1, WasteType.WasteWater);
    op.DrainToWaste(0, WasteType.WasteWater);
    op.SecludeLiquid(liquidTypes.blank, 0.3);
  }

  if (measureConfig.addParam.dilutionExtractVolume3 && measureConfig.addParam.dilutionExtractVolume3 > 0) {
    op.AirToDigestionRoom(10);
    op.MeterFromDigestionRoom(measureConfig.addParam.dilutionExtractVolume3, 1, WasteType.WasteWater);
    op.SecludeLiquid(liquidTypes.digestionRoom);
    op.Pump(liquidTypes.none, 0.5, 0.2, false);
    op.CleanMeterPipe(liquidTypes.blank, cleanMeterPipevolume, 2.4, WasteType.WasteWater);
  }

  if (measureConfig.addParam.dilutionAddBlankVolume3 && measureConfig.addParam.dilutionAddBlankVolume3 > 0) {
    op.Pump(liquidTypes.none, 0.5, 0.2, false);
    op.Pump(liquidTypes.blank, 0.8, 0.2, false);
    op.DrainToWaste(0, WasteType.WasteWater);
    op.MeterToDigestionRoom(liquidTypes.blank, measureConfig.addParam.dilutionAddBlankVolume3, 1, WasteType.WasteWater);
    op.DrainToWaste(0, WasteType.WasteWater);
    op.SecludeLiquid(liquidTypes.blank, 0.3);
  }

  if (measureConfig.measureType === MeasureType.AddStandard && measureConfig.currentRange === 1) {
    // op.MeterToDigestionRoom(liquidTypes.standard, setting.unitVolume, nil, WasteType.WasteWater);
    // op.DrainToWaste(0, WasteType.WasteWater);
    // op.SecludeLiquid(liquidTypes.standard);
  }

  hilog.info(122, 'Measurer', '加待测样时间 = %{public}d', DateTimeUtil.getTimestamp() - startTime);
  return 1;
}

@Concurrent
export async function addReagent1(): Promise<number> {
  const startTime = DateTimeUtil.getTimestamp();
  const op = Operator.getInstance();

  op.Pump(liquidTypes.none, 0.5, 0.2, false);
  op.IndirectMeterToDigestionRoom(liquidTypes.reagent1, 2);//setting.liquid.reagent1Volume 体积参数不匹配运行故障
  op.DrainToWaste(0);
  op.SecludeLiquid(liquidTypes.reagent1);

  op.AirToDigestionRoom();
  op.CleanMeterPipe(liquidTypes.blank, 1.5, 1.5, WasteType.WasteWater, 200);

  hilog.info(122, 'Measurer', '加试剂一时间 = %{public}d', DateTimeUtil.getTimestamp() - startTime);
  return 1;
}

@Concurrent
export async function addReagent2(): Promise<number> {
  const startTime = DateTimeUtil.getTimestamp();
  const op = Operator.getInstance();

  op.Pump(liquidTypes.none, 0.5, 0.2, false);
  op.IndirectMeterToDigestionRoom(liquidTypes.reagent2, setting.liquid.reagent2Volume);
  op.DrainToWaste(0);
  op.SecludeLiquid(liquidTypes.reagent2);

  op.AirToDigestionRoom();
  op.CleanMeterPipe(liquidTypes.blank, 1.5, 1.5, WasteType.WasteWater, 200);

  hilog.info(122, 'Measurer', '加试剂二时间 = %{public}d', DateTimeUtil.getTimestamp() - startTime);
  return 1;
}

@Concurrent
export async function digest(): Promise<number> {
  const startTime = DateTimeUtil.getTimestamp();
  const op = Operator.getInstance();

  let temperature = op.ITemperatureControl.getTemperature();
  let thermostatTemp = temperature.thermostatTemp;
  hilog.info(122, 'Measurer', '加热消解前温度 = %{public}d ℃', thermostatTemp);

  // const tempIncrement = thermostatTemp - this.temperatureBeforeAddReagent2;
  // if (tempIncrement < config.measureParam.temperatureIncrement && !config.system.debugMode && config.measureParam.temperatureIncrement !== 0) {
  //   hilog.info(122, 'Measurer', '加热前温度增量过低异常');
  //   throw new Error("AddLiquidToDigestionException");
  // }

  // op.ImmerseMeterPipe(setting.liquidType.blank, 2);

  const temp = config.measureParam.digestTemperature - thermostatTemp;
  if (temp > 0.01) {
    try {
      // FlowManager.Instance().ClearAllRemainEvent();
      thermostatTemp = op.StartThermostat(ThermostatMode.Auto, config.measureParam.digestTemperature, setting.temperature.toleranceTemp, setting.temperature.digestTempTimeout);
    } catch (err) {
      console.error('Measurer', '加热消解异常: %{public}s', (err as Error).message);
      throw new Error(err);
    }
  }

  hilog.info(122, 'Measurer', '到达消解目标温度 = %{public}d℃', thermostatTemp);

  // if (!this.flow?.Wait(config.measureParam.digestTime)) {
  //   // FlowManager.Instance().ClearAllRemainEvent();
  //   // op.StopThermostat();
  //   throw new Error("用户终止");
  // }
  // thread.sleep(60 * 1000);

  op.StopThermostat();

  hilog.info(122, 'Measurer', '加热消解时间 = %{public}d', DateTimeUtil.getTimestamp() - startTime);
  return 1;
}

@Concurrent
export async function digestCooling(): Promise<number> {
  const startTime = DateTimeUtil.getTimestamp();
  const op = Operator.getInstance();

  let temperature = op.ITemperatureControl.getTemperature();
  let thermostatTemp = temperature.thermostatTemp;
  hilog.info(122, 'Measurer', '消解冷却前温度 = %{public}d℃', thermostatTemp);

  const digestAirPumpingTemp = config.measureParam.reactTemperature + 5;
  const difference = thermostatTemp - digestAirPumpingTemp;

  if (difference > 0.01) {
    try {
      // FlowManager.Instance().ClearAllRemainEvent();
      hilog.info(122, 'Measurer', '消解冷却');
      thermostatTemp = op.StartThermostat(ThermostatMode.Auto, digestAirPumpingTemp, 0.2, setting.temperature.digestToReactCoolingTimeout);
    } catch (err) {
      console.error('Measurer', '消解冷却异常: %{public}s', (err as Error).message);
      throw new Error(err);
    }
    // FlowManager.Instance().ClearAllRemainEvent();
    // thermostatTemp = op.StopThermostat();
    hilog.info(122, 'Measurer', '到达消解鼓气目标温度 = %{public}d℃', thermostatTemp);
  }

  if (config.measureParam.pidCtrl) {
    op.IOpticalAcquire.startLEDController();
    hilog.info(122, 'Measurer', '打开测量LED,带PID');
  } else {
    op.IOpticalAcquire.turnOnLED();
    hilog.info(122, 'Measurer', '打开测量LED,不带PID');
  }

  op.DrainToWaste(setting.liquid.meterPipeVolume, WasteType.WasteReagent);

  // if (!config.measureParam.highlyOxidized) {
  //   const factor = DC.GetIPeristalticPump().GetPumpFactor(0);
  //   op.Drain(setting.liquidType.digestionRoom, 6, 0.3);
  // }

  const digestCoolingTemp = config.measureParam.reactTemperature + setting.temperature.naturalCoolingTempValue;
  const temp = thermostatTemp - digestCoolingTemp;

  if (temp > 0.01) {
    try {
      // FlowManager.Instance().ClearAllRemainEvent();
      hilog.info(122, 'Measurer', '加热反应');
      thermostatTemp = op.StartThermostat(ThermostatMode.Natural, config.measureParam.reactTemperature, 0.1, setting.temperature.naturalCoolingTimeout);
    } catch (err) {
      console.error('Measurer', '消解自然冷却异常: %{public}s', (err as Error).message);
      throw new Error(err);
    }
    // FlowManager.Instance().ClearAllRemainEvent();
    thermostatTemp = op.StopThermostat();
    hilog.info(122, 'Measurer', '到达消解自然冷却温度 = %{public}d℃', thermostatTemp);
  }

  hilog.info(122, 'Measurer', '消解冷却时间 = %{public}d', DateTimeUtil.getTimestamp() - startTime);
  return 1;
}

@Concurrent
export async function readMeasureAD(): Promise<Partial<MeasureResult>> {
  const startTime = DateTimeUtil.getTimestamp();
  const op = Operator.getInstance();

  let temp = op.ITemperatureControl.getTemperature();
  hilog.info(122, 'Measurer', '读反应值前 消解温度 = %{public}d ℃，环境温度 = %{public}d ℃', temp.thermostatTemp, temp.environmentTemp);

  const finalAD = op.StartAcquirerADWithFiltration(setting.signal.readADTime);
  op.IOpticalAcquire.turnOffLED();
  hilog.info(122, 'Measurer', '关闭LED');

  temp = op.ITemperatureControl.getTemperature();
  hilog.info(122, 'Measurer', '读反应值后 消解温度 = %{public}d ℃，环境温度 = %{public}d ℃', temp.thermostatTemp, temp.environmentTemp);

  hilog.info(122, 'Measurer', '读反应值时间 = %{public}d', DateTimeUtil.getTimestamp() - startTime);
  // ✅ 只返回 final 相关的4个字段
  return {
    finalReferenceAD: finalAD.reference,
    finalMeasureAD: finalAD.measure,
    finalThermostatTemp: temp.thermostatTemp,
    finalEnvironmentTemp: temp.environmentTemp,
  };
}

@Concurrent
export async function proformaResult(): Promise<number> {
  //显示预估值 未实现
  // if (this.flow?.ProformaResultHandle) {
  //   this.flow.ProformaResultHandle(this.measureResult);
  // }
  return 1;
}

@Concurrent
export async function afterMeasureCooling(): Promise<number> {
  const startTime = DateTimeUtil.getTimestamp();
  const op = Operator.getInstance();

  let temperature = op.ITemperatureControl.getTemperature();
  let thermostatTemp = temperature.thermostatTemp;
  const preDrainCoolingTemp = setting.temperature.preheating;
  let temp = thermostatTemp - preDrainCoolingTemp;

  if (temp > 0.01) {
    try {
      // FlowManager.Instance().ClearAllRemainEvent();
      thermostatTemp = op.StartThermostat(ThermostatMode.Auto, preDrainCoolingTemp, 0.2, setting.temperature.digestToReactCoolingTimeout);
    } catch (err) {
      console.error('Measurer', '排液前冷却异常: %{public}s', (err as Error).message);
      throw new Error(err);
    }
    // FlowManager.Instance().ClearAllRemainEvent();
    thermostatTemp = op.StopThermostat();
  }

  temperature = op.ITemperatureControl.getTemperature();
  thermostatTemp = temperature.thermostatTemp;
  hilog.info(122, 'Measurer', '消解自然冷却前温度 = %{public}d℃', thermostatTemp);

  hilog.info(122, 'Measurer', '排液前冷却时间 = %{public}d', DateTimeUtil.getTimestamp() - startTime);
  return 1;
}

@Concurrent
export async function drainAfterMeasure(): Promise<number> {
  const startTime = DateTimeUtil.getTimestamp();
  const op = Operator.getInstance();

  op.AirToDigestionRoom();
  //setting.measure.range[1].sampleVolume 未实现
  const reactTotalVol = 1 + setting.liquid.reagent1Volume + setting.liquid.reagent2Volume;
  const minTimes = op.GetMinDrainDigestionTimes(reactTotalVol);
  op.PumpFromDigestionRoom(4, 0, WasteType.WasteReagent);
  op.Pump(liquidTypes.digestionRoom, 2.2, 0.2, false);
  op.DrainToWaste(2.5, WasteType.WasteReagent);

  hilog.info(122, 'Measurer', '测量后排液时间 = %{public}d', DateTimeUtil.getTimestamp() - startTime);
  return 1;
}

@Concurrent
export async function cleanAfterMeasure(): Promise<number> {
  const startTime = DateTimeUtil.getTimestamp();
  const op = Operator.getInstance();

  let cleanTimes = 1;
  let cleanAftMeaBlankVol = setting.liquid.cleanVolume.cleanAftMeaBlankVol;
  if (config.measureParam.wasteWaterEnvironment) {
    cleanAftMeaBlankVol = setting.liquid.cleanVolume.cleanAftMeaBlankVol;
  }
  if (config.measureParam.tapWaterEnvironment) {
    cleanAftMeaBlankVol = setting.liquid.cleanVolume.cleanAftMeaBlankVol;
    cleanTimes = 2;
  }

  op.PumpToDigestionRoom(liquidTypes.blank, 1, 0);
  op.DrainToWaste(0);
  op.SecludeLiquid(liquidTypes.blank);
  op.Pump(liquidTypes.digestionRoom, 2.2, 0.2, false);
  op.DrainToWaste(2.2, WasteType.WasteReagent);

  for (let i = 1; i <= cleanTimes; i++) {
    if (cleanAftMeaBlankVol > 0) {
      op.PumpToDigestionRoom(liquidTypes.blank, cleanAftMeaBlankVol, 0);
      op.DrainToWaste(0);
      op.SecludeLiquid(liquidTypes.blank);
      op.DrainFromDigestionRoomCheck(3, WasteType.WasteReagent, 2.4);
    }
  }

  status.measureStatus.digestionRoomIsBlank = true;
  // ConfigLists.SaveMeasureStatus();

  hilog.info(122, 'Measurer', '测量后清洗时间 = %{public}d', DateTimeUtil.getTimestamp() - startTime);
  return 1;
}

@Concurrent
export async function readInitialAD(): Promise<Partial<MeasureResult>> {
  const startTime = DateTimeUtil.getTimestamp();
  const op = Operator.getInstance();

  let readInitADBlankVolume = setting.liquid.cleanVolume.readInitADBlankVolume;
  if (config.measureParam.wasteWaterEnvironment || config.measureParam.tapWaterEnvironment) {
    readInitADBlankVolume = setting.liquid.cleanVolume.readInitADBlankVolume;
  }

  op.PumpToDigestionRoom(liquidTypes.blank, readInitADBlankVolume, 0);
  op.DrainToWaste(0, WasteType.WasteWater);
  op.SecludeLiquid(liquidTypes.blank);

  const targetTemp = 60;

  if (config.measureParam.pidCtrl) {
    op.IOpticalAcquire.startLEDController();
    hilog.info(122, 'Measurer', '打开测量LED,带PID');
  } else {
    op.IOpticalAcquire.turnOnLED();
    hilog.info(122, 'Measurer', '打开测量LED,不带PID');
  }

  let temperature = op.ITemperatureControl.getTemperature();
  const thermostatTemp = temperature.thermostatTemp;
  hilog.info(122, 'Measurer', '读空白值加热前温度 = %{public}d℃', thermostatTemp);

  // try {
  //   // FlowManager.Instance().ClearAllRemainEvent();
  //   op.StartThermostat(ThermostatMode.Auto, targetTemp, 5, setting.temperature.reactTempTimeout);
  // } catch (err) {
  //   console.error('Measurer', '读空白值加热异常: %{public}s', (err as Error).message);
  //   throw new Error(err);
  // }

  // FlowManager.Instance().ClearAllRemainEvent();
  op.StopThermostat();
  op.AirToDigestionRoom();

  // if (!this.flow?.Wait(config.measureParam.readInitRilentTime)) {
  //   // FlowManager.Instance().ClearAllRemainEvent();
  //   // op.StopThermostat();
  //   throw new Error("用户终止");
  // }

  const temp = op.ITemperatureControl.getTemperature();
  hilog.info(122, 'Measurer', '读空白值 静置后消解室温度 = %{public}d 环境温度 = %{public}d', temp.thermostatTemp, temp.environmentTemp);

  const initAD = op.StartAcquirerADWithFiltration(setting.signal.readADTime);
  op.IOpticalAcquire.turnOffLED();
  hilog.info(122, 'Measurer', '关闭LED');

  // if (!this.flow?.Wait(1)) {
  //   throw new Error("用户终止");
  // }

  thread.sleep(1000);

  const darkAD = op.StartAcquirerAD(setting.signal.readDarkADTime);

  hilog.info(122, 'Measurer', '读空白值时间 = %{public}d', DateTimeUtil.getTimestamp() - startTime);
  return {
    initReferenceAD: initAD.reference,
    initMeasureAD: initAD.measure,
    darkReferenceAD: darkAD.reference,
    darkMeasureAD: darkAD.measure,
    initThermostatTemp: temp.thermostatTemp,
    initEnvironmentTemp: temp.environmentTemp,
  };
}

@Concurrent
export async function finalResult(): Promise<number> {
  status.measureStatus.lastMeasureEndTime = DateTimeUtil.getTimestamp();
  // if (this.flow) {
  //   if(this.flow.ResultHandle){
  //     this.flow.ResultHandle(this.measureResult);
  //   }
  // }
  return 1;
}

@Concurrent
export async function drainAfterMeasureBlank(): Promise<number> {
  const startTime = DateTimeUtil.getTimestamp();
  const op = Operator.getInstance();

  // if (!config.measureParam.wasteWaterEnvironment)
  {
    const reactTotalVol = setting.liquid.cleanVolume.readInitADBlankVolume;
    const minTimes = op.GetMinDrainDigestionTimes(reactTotalVol);
    op.DrainFromDigestionRoomCheck(minTimes, WasteType.WasteWater, 2.4);
  }

  hilog.info(122, 'Measurer', '测量后排液时间 = %{public}d', DateTimeUtil.getTimestamp() - startTime);
  return 1;
}