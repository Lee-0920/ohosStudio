import { hilog } from '@kit.PerformanceAnalysisKit'
import { Flow } from './Flow';
import { emitter } from '@kit.BasicServicesKit';
import { DateTimeUtil } from 'base';
import { PT65DriveController } from "pt65drivecontrollerplugin";
// import { Operator } from './Operator';
import { config } from '../Config/Config';
import { status } from '../Config/Config';
import { setting, RangeConfig } from '../Setting/Setting';
import { ActionItem } from '../Setting/RunAction';
import { MeasureType } from './MeasureFlow';
// import { SHARED_OPERATOR } from './Operator'



export interface MeasureResult {
  initReferenceAD: number;       // 空白参考AD值
  initMeasureAD: number;          // 空白测量AD值
  finalReferenceAD: number;      // 结果参考AD值
  finalMeasureAD: number;         // 结果测量AD值
  darkReferenceAD: number;       // 暗电流参考AD值
  darkMeasureAD: number;          // 暗电流测量AD值
  initThermostatTemp: number;     // 读空白值时的消解室温度
  initEnvironmentTemp: number;    // 读空白值时的环境温度
  finalThermostatTemp: number;    // 读反应值时的消解室温度
  finalEnvironmentTemp: number;   // 读反应值时的环境温度
}

// ✅ 提供一个带默认值的工厂函数（interface 无法 new）
export function createEmptyMeasureResult(): MeasureResult {
  return {
    initReferenceAD: 0,
    initMeasureAD: 0,
    finalReferenceAD: 0,
    finalMeasureAD: 0,
    darkReferenceAD: 0,
    darkMeasureAD: 0,
    initThermostatTemp: 0,
    initEnvironmentTemp: 0,
    finalThermostatTemp: 0,
    finalEnvironmentTemp: 0,
  };
}

// export interface AddParam {
//   sampleVolume?: number;
//   standardVolume?: number;
//   zeroCheckVolume?: number;
//   rangeCheckVolume?: number;
//   blankVolume?: number;
//   rinseEnable?: boolean;
//   rinseSampleVolume?: number;
//   rinseStandardVolume?: number;
//   rinseZeroCheckVolume?: number;
//   rinseRangeCheckVolume?: number;
//   rinseBlankVolume?: number;
//   dilutionExtractVolume1?: number;
//   dilutionAddBlankVolume1?: number;
//   dilutionExtractVolume2?: number;
//   dilutionAddBlankVolume2?: number;
//   dilutionExtractVolume3?: number;
//   dilutionAddBlankVolume3?: number;
//   afterReagent1AddBlankVolume?: number;
//   //diluteFactor: number;
// }
// export interface AddParam extends RangeConfig {
//
// }

export interface ProcedureStep {
  action: ActionItem | null;
  execute: () => void;
}

// const op = SHARED_OPERATOR;

export class Measurer {
  static instance: Measurer | null = null;
  flow: Flow | null = null;
  measureType: MeasureType = MeasureType.Sample;
  currentRange: number = 1;
  temperatureBeforeAddReagent2: number = 0;
  NowVolume: number = 0;
  Rangent1AirVolume: number = 0;
  addParam: RangeConfig = { };

  measureResult: MeasureResult = {
    initReferenceAD: 0,
    initMeasureAD: 0,
    finalReferenceAD: 0,
    finalMeasureAD: 0,
    darkReferenceAD: 0,
    darkMeasureAD: 0,
    initThermostatTemp: 0,
    initEnvironmentTemp: 0,
    finalThermostatTemp: 0,
    finalEnvironmentTemp: 0,
  };

  private steps: ProcedureStep[] = [];

  private constructor() {
    this.flow = null;
    this.InitSteps();
  }

  static getInstance(): Measurer {
    if (!Measurer.instance) {
      Measurer.instance = new Measurer();
    }
    return Measurer.instance;
  }

  private InitSteps(): void {
    this.steps = [
      {
        action: null,
        execute: () => {
        }
      },
      {
        action: setting.runAction.measure.drainBeforeMeasure,
        execute: () => {
          const startTime = DateTimeUtil.getTimestamp();

          // op.DrainToWaste(setting.liquid.meterPipeVolume);
          // op.AirToDigestionRoom();

          if (status.measureStatus.digestionRoomIsBlank) {
            // op.DrainFromDigestionRoom(WasteType.WasteWater, false, 2.4);
          } else {
            // op.DrainFromDigestionRoom(WasteType.WasteReagent, false, 2.4);
          }

          hilog.info(100, 'Measurer', '测量前排液时间 = %{public}d', DateTimeUtil.getTimestamp() - startTime);
        }
      },
      {
        action: setting.runAction.measure.cleanBeforeMeasure,
        execute: () => {
          const startTime = DateTimeUtil.getTimestamp();
          const DC = new PT65DriveController();

          if (this.measureType === MeasureType.Blank) {
            const cleanAftMeaBlankVol = 1;
            // op.CleanMeterPipe(setting.liquidType.blank, 1.2, 1.2, WasteType.WasteWater, 300);
            for (let i = 1; i <= 1; i++) {
              // op.PumpToDigestionRoom(setting.liquidType.blank, cleanAftMeaBlankVol, 2.2, WasteType.WasteWater);
              // op.Pump(setting.liquidType.digestionRoom, 2.2, 0.2, false);
              // op.DrainToWaste(2.2, WasteType.WasteWater);
            }
            // op.SecludeLiquid(setting.liquidType.blank);
            // op.DrainFromDigestionRoomCheck(nil, WasteType.WasteWater, 2);
          }

          if (!status.measureStatus.digestionRoomIsBlank) {
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
                // op.PumpToDigestionRoom(setting.liquidType.blank, cleanAftMeaBlankVol, 2);
                // op.DrainToWaste(0);
                // op.SecludeLiquid(setting.liquidType.blank);
                // op.DrainFromDigestionRoomCheck(nil, WasteType.WasteWater, 2);
              }
            }
          }

          if (config.measureParam.cleanBefMeaBlankVol > 0 && status.measureStatus.digestionRoomIsBlank) {
            // op.PumpToDigestionRoom(setting.liquidType.blank, config.measureParam.cleanBefMeaBlankVol, 2, WasteType.WasteWater);
            // op.DrainToWaste(0, WasteType.WasteWater);
            // op.SecludeLiquid(setting.liquidType.blank);
            // op.DrainFromDigestionRoom(WasteType.WasteWater, false, 2);
          }

          if (this.TimeCheck() && status.measureStatus.digestionRoomIsBlank) {
            hilog.info(100, 'Measurer', '二次清洗');
            status.measureStatus.lastMeasureEndTime = DateTimeUtil.getTimestamp();
            // ConfigLists.SaveMeasureStatus();
            // op.PumpToDigestionRoom(setting.liquidType.blank, 6, 2, WasteType.WasteWater);
            // op.DrainToWaste(0, WasteType.WasteWater);
            // op.SecludeLiquid(setting.liquidType.blank);
            // op.DrainFromDigestionRoom(WasteType.WasteWater, false, 2);
          }

          status.measureStatus.digestionRoomIsBlank = true;
          // ConfigLists.SaveMeasureStatus();

          hilog.info(100, 'Measurer', '测量前清洗时间 = %{public}d', DateTimeUtil.getTimestamp() - startTime);
        }
      },
      {
        action: setting.runAction.measure.rinse,
        execute: () => {
          const startTime = DateTimeUtil.getTimestamp();
          const RinseVolume = this.GetRinseVol();

          if (this.addParam.rinseEnable) {
            if (this.addParam.rinseSampleVolume && this.addParam.rinseSampleVolume > 0) {
              if (config.measureParam.sampleRenewVolume > 0) {
                // op.Pump(setting.liquidType.sample, 2, 0.3, false);
                // op.DrainToWaste(2, setting.liquidType.waste);
                // op.CleanMeterPipe(setting.liquidType.sample, config.measureParam.sampleRenewVolume, 2, setting.liquidType.waste, 200, false);
              }
              // op.CleanMeterPipe(setting.liquidType.sample, RinseVolume, 2.3, setting.liquidType.waste, 200, false);
            }

            if (this.addParam.rinseStandardVolume && this.addParam.rinseStandardVolume > 0) {
              // op.CleanMeterPipe(setting.liquidType.standard, RinseVolume + config.measureParam.sampleRenewVolume, 2.3, WasteType.WasteWater, 200, false);
            }

            if (this.addParam.rinseZeroCheckVolume && this.addParam.rinseZeroCheckVolume > 0) {
              // op.CleanMeterPipe(setting.liquidType.zeroCheck, RinseVolume + config.measureParam.sampleRenewVolume, 2.3, WasteType.WasteWater, 200, false);
            }

            if (this.addParam.rinseRangeCheckVolume && this.addParam.rinseRangeCheckVolume > 0) {
              // op.CleanMeterPipe(setting.liquidType.rangeCheck, RinseVolume + config.measureParam.sampleRenewVolume, 2.3, WasteType.WasteWater, 200, false);
            }

            if (this.addParam.rinseBlankVolume && this.addParam.rinseBlankVolume > 0) {
              // op.CleanMeterPipe(setting.liquidType.blank, RinseVolume + config.measureParam.sampleRenewVolume, 2.3, WasteType.WasteWater, 200, false);
            }
          }

          // op.Pump(setting.liquidType.digestionRoom, 1, 0.2, false);
          // op.DrainToWaste(1);

          hilog.info(100, 'Measurer', '润洗时间 = %{public}d', DateTimeUtil.getTimestamp() - startTime);
        }
      },
      {
        action: setting.runAction.measure.addSample,
        execute: () => {
          const startTime = DateTimeUtil.getTimestamp();
          const cleanMeterPipevolume = 2.4;

          if (this.addParam.sampleVolume && this.addParam.sampleVolume > 0) {
            // op.MeterToDigestionRoom(setting.liquidType.sample, this.addParam.sampleVolume, nil, setting.liquidType.waste);
            // op.DrainLiquid(setting.liquidType.sample, setting.liquid.samplePipeVolume + config.measureParam.extendSamplePipeVolume, setting.liquidType.waste);

            let CleanPipeTimes = 1;
            if (config.measureParam.wasteWaterEnvironment || config.measureParam.tapWaterEnvironment) {
              CleanPipeTimes = 2;
            }
            for (let i = 1; i <= CleanPipeTimes; i++) {
              // op.Pump(setting.liquidType.none, 0.5, 0.2, false);
              // op.CleanMeterPipe(setting.liquidType.blank, 2.4, 2.4, WasteType.WasteWater, setting.liquid.drainSpeed, false);
            }

            // const factor = dc.GetIPeristalticPump().GetPumpFactor(0);
            // const drainSpeed = 500 * factor;
            // op.SetMeterOverValue(MeterMode.Smart, 0);
            // op.ForcingCleanPipe(setting.liquidType.sample, 2, 0.5, 0.7, drainSpeed);
            // op.SecludeLiquid(setting.liquidType.blank);
            // op.SecludeLiquid(setting.liquidType.sample, 0.2);

            if (config.measureParam.cleanSampleVol > 0) {
              // op.DrainToWaste(0, WasteType.WasteReagent);
              // op.MeterToSample(setting.liquidType.blank, config.measureParam.cleanSampleVol, WasteType.WasteReagent);
              // op.SecludeLiquid(setting.liquidType.blank);
              // op.DrainLiquid(setting.liquidType.sample, setting.liquid.samplePipeVolume + config.measureParam.extendSamplePipeVolume, WasteType.WasteReagent);
            }
          }

          if (this.addParam.standardVolume && this.addParam.standardVolume > 0) {
            // op.MeterToDigestionRoom(setting.liquidType.standard, this.addParam.standardVolume, nil, setting.liquidType.waste);
            // op.DrainToWaste(0, setting.liquidType.waste);
            // op.SecludeLiquid(setting.liquidType.standard, 0.3);

            let CleanPipeTimes = 1;
            if (config.measureParam.wasteWaterEnvironment || config.measureParam.tapWaterEnvironment) {
              CleanPipeTimes = 2;
            }
            for (let i = 1; i <= CleanPipeTimes; i++) {
              // op.Pump(setting.liquidType.none, 0.5, 0.2, false);
              // op.CleanMeterPipe(setting.liquidType.blank, cleanMeterPipevolume, 2.4);
            }
            // op.Pump(setting.liquidType.none, 0.5, 0.2, false);
            // op.CleanMeterPipe(setting.liquidType.blank, 1, 1);
          }

          if (this.addParam.zeroCheckVolume && this.addParam.zeroCheckVolume > 0) {
            // op.MeterToDigestionRoom(setting.liquidType.zeroCheck, this.addParam.zeroCheckVolume, nil, setting.liquidType.waste);
            // op.DrainToWaste(0, setting.liquidType.waste);
            // op.SecludeLiquid(setting.liquidType.zeroCheck, 0.3);

            let CleanPipeTimes = 1;
            if (config.measureParam.wasteWaterEnvironment || config.measureParam.tapWaterEnvironment) {
              CleanPipeTimes = 2;
            }
            for (let i = 1; i <= CleanPipeTimes; i++) {
              // op.Pump(setting.liquidType.none, 0.5, 0.2, false);
              // op.CleanMeterPipe(setting.liquidType.blank, cleanMeterPipevolume, 2.4);
            }
            // op.Pump(setting.liquidType.none, 0.5, 0.2, false);
            // op.CleanMeterPipe(setting.liquidType.blank, 1, 1);
          }

          if (this.addParam.rangeCheckVolume && this.addParam.rangeCheckVolume > 0) {
            // op.MeterToDigestionRoom(setting.liquidType.rangeCheck, this.addParam.rangeCheckVolume, nil, setting.liquidType.waste);
            // op.DrainToWaste(0, setting.liquidType.waste);
            // op.SecludeLiquid(setting.liquidType.rangeCheck, 0.3);

            let CleanPipeTimes = 1;
            if (config.measureParam.wasteWaterEnvironment || config.measureParam.tapWaterEnvironment) {
              CleanPipeTimes = 2;
            }
            for (let i = 1; i <= CleanPipeTimes; i++) {
              // op.Pump(setting.liquidType.none, 0.5, 0.2, false);
              // op.CleanMeterPipe(setting.liquidType.blank, cleanMeterPipevolume, 2.4);
            }
            // op.Pump(setting.liquidType.none, 0.5, 0.2, false);
            // op.CleanMeterPipe(setting.liquidType.blank, 1, 1);
          }

          status.measureStatus.digestionRoomIsBlank = false;
          // ConfigLists.SaveMeasureStatus();

          if (this.addParam.blankVolume && this.addParam.blankVolume > 0) {
            // op.Pump(setting.liquidType.none, 0.5, 0.2, false);
            // op.Pump(setting.liquidType.blank, 0.8, 0.2, false);
            // op.DrainToWaste(0, setting.liquidType.wasteWater);
            // op.MeterToDigestionRoom(setting.liquidType.blank, this.addParam.blankVolume, nil, setting.liquidType.waste);
            // op.DrainToWaste(0, setting.liquidType.waste);
            // op.SecludeLiquid(setting.liquidType.blank, 0.3);
          }

          if (this.addParam.dilutionExtractVolume1 && this.addParam.dilutionExtractVolume1 > 0) {
            // op.AirToDigestionRoom(10);
            // op.MeterFromDigestionRoom(this.addParam.dilutionExtractVolume1, nil, setting.liquidType.waste);
            // op.SecludeLiquid(setting.liquidType.digestionRoom);
            // op.Pump(setting.liquidType.none, 0.5, 0.2, false);
            // op.CleanMeterPipe(setting.liquidType.blank, cleanMeterPipevolume, 2.4, WasteType.WasteWater);
          }

          if (this.addParam.dilutionAddBlankVolume1 && this.addParam.dilutionAddBlankVolume1 > 0) {
            // op.Pump(setting.liquidType.none, 0.5, 0.2, false);
            // op.Pump(setting.liquidType.blank, 0.8, 0.2, false);
            // op.DrainToWaste(0, setting.liquidType.wasteWater);
            // op.MeterToDigestionRoom(setting.liquidType.blank, this.addParam.dilutionAddBlankVolume1, nil, setting.liquidType.waste);
            // op.DrainToWaste(0, setting.liquidType.waste);
            // op.SecludeLiquid(setting.liquidType.blank, 0.3);
          }

          if (this.addParam.dilutionExtractVolume2 && this.addParam.dilutionExtractVolume2 > 0) {
            // op.AirToDigestionRoom(10);
            // op.MeterFromDigestionRoom(this.addParam.dilutionExtractVolume2, nil, setting.liquidType.waste);
            // op.SecludeLiquid(setting.liquidType.digestionRoom);
            // op.Pump(setting.liquidType.none, 0.5, 0.2, false);
            // op.CleanMeterPipe(setting.liquidType.blank, cleanMeterPipevolume, 2.4, WasteType.WasteWater);
          }

          if (this.addParam.dilutionAddBlankVolume2 && this.addParam.dilutionAddBlankVolume2 > 0) {
            // op.Pump(setting.liquidType.none, 0.5, 0.2, false);
            // op.Pump(setting.liquidType.blank, 0.8, 0.2, false);
            // op.DrainToWaste(0, setting.liquidType.wasteWater);
            // op.MeterToDigestionRoom(setting.liquidType.blank, this.addParam.dilutionAddBlankVolume2, nil, setting.liquidType.waste);
            // op.DrainToWaste(0, setting.liquidType.waste);
            // op.SecludeLiquid(setting.liquidType.blank, 0.3);
          }

          if (this.addParam.dilutionExtractVolume3 && this.addParam.dilutionExtractVolume3 > 0) {
            // op.AirToDigestionRoom(10);
            // op.MeterFromDigestionRoom(this.addParam.dilutionExtractVolume3, nil, setting.liquidType.waste);
            // op.SecludeLiquid(setting.liquidType.digestionRoom);
            // op.Pump(setting.liquidType.none, 0.5, 0.2, false);
            // op.CleanMeterPipe(setting.liquidType.blank, cleanMeterPipevolume, 2.4, WasteType.WasteWater);
          }

          if (this.addParam.dilutionAddBlankVolume3 && this.addParam.dilutionAddBlankVolume3 > 0) {
            // op.Pump(setting.liquidType.none, 0.5, 0.2, false);
            // op.Pump(setting.liquidType.blank, 0.8, 0.2, false);
            // op.DrainToWaste(0, setting.liquidType.wasteWater);
            // op.MeterToDigestionRoom(setting.liquidType.blank, this.addParam.dilutionAddBlankVolume3, nil, setting.liquidType.waste);
            // op.DrainToWaste(0, setting.liquidType.waste);
            // op.SecludeLiquid(setting.liquidType.blank, 0.3);
          }

          if (this.measureType === MeasureType.AddStandard && this.currentRange === 1) {
            // op.MeterToDigestionRoom(setting.liquidType.standard, setting.unitVolume, nil, setting.liquidType.waste);
            // op.DrainToWaste(0, setting.liquidType.waste);
            // op.SecludeLiquid(setting.liquidType.standard);
          }

          hilog.info(100, 'Measurer', '加待测样时间 = %{public}d', DateTimeUtil.getTimestamp() - startTime);
        }
      },
      {
        action: setting.runAction.measure.addReagent1,
        execute: () => {
          const startTime = DateTimeUtil.getTimestamp();

          // op.Pump(setting.liquidType.none, 0.5, 0.2, false);
          // op.IndirectMeterToDigestionRoom(setting.liquidType.reagent1, setting.liquid.reagent1Volume);
          // op.DrainToWaste(0);
          // op.SecludeLiquid(setting.liquidType.reagent1);

          if (this.addParam.afterReagent1AddBlankVolume && this.addParam.afterReagent1AddBlankVolume > 0) {
            // op.MeterToDigestionRoom(setting.liquidType.blank, this.addParam.afterReagent1AddBlankVolume, PointNum.First);
            // op.DrainToWaste(0);
            // op.SecludeLiquid(setting.liquidType.blank);
          }

          if (this.measureType === MeasureType.AddStandard && this.currentRange > 1) {
            // op.MeterToDigestionRoom(setting.liquidType.standard, setting.unitVolume, PointNum.First, setting.liquidType.waste);
            // op.DrainToWaste(0, setting.liquidType.waste);
            // op.SecludeLiquid(setting.liquidType.standard);
          }

          // op.AirToDigestionRoom();
          // op.CleanMeterPipe(setting.liquidType.blank, 1.5, 1.5, WasteType.WasteWater, 200);

          hilog.info(100, 'Measurer', '加试剂一时间 = %{public}d', DateTimeUtil.getTimestamp() - startTime);
        }
      },
      {
        action: setting.runAction.measure.addReagent2,
        execute: () => {
          const startTime = DateTimeUtil.getTimestamp();

          const DC = new PT65DriveController();
          //this.temperatureBeforeAddReagent2 = DC.GetCurrentTemperature().GetThermostatTemp();
          hilog.info(100, 'Measurer', '加试剂二前温度 = %{public}f ℃', this.temperatureBeforeAddReagent2);

          // op.Pump(setting.liquidType.none, 0.5, 0.2, false);
          // op.Pump(setting.liquidType.reagent2, 0.5, 0.3, false);
          // op.Drain(setting.liquidType.none, 0.5, 0.1);
          // op.DrainToWaste(1, WasteType.WasteReagent);
          // op.CleanMeterPipe(setting.liquidType.blank, 2.4, 2.4, WasteType.WasteWater, 200);

          if (config.measureParam.highlyOxidized) {
            // op.SlowMeterToDigestionRoomNotCloseValve(setting.liquidType.reagent2, 1, PointNum.First);
            // op.DrainToWaste(0);
            // op.CleanMeterPipe(setting.liquidType.blank, 2);
          }

          // op.Pump(setting.liquidType.none, 0.5, 0.2, false);
          // op.SlowMeterToDigestionRoom(setting.liquidType.reagent2, setting.liquid.reagent2Volume, PointNum.Second);
          // op.DrainToWaste(0);
          // op.Drain(setting.liquidType.reagent2, setting.liquid.liquidSecludeVolume * 3, setting.liquid.liquidSecludeSpeed);

          // const factor = DC.GetIPeristalticPump().GetPumpFactor(0);
          // op.Drain(setting.liquidType.none, 0.3, 0.2);
          // op.Drain(setting.liquidType.digestionRoom, 6, setting.liquid.pumpAirStepSpeed * factor * 0.5);

          hilog.info(100, 'Measurer', '加试剂二时间 = %{public}d', DateTimeUtil.getTimestamp() - startTime);
        }
      },
      {
        action: setting.runAction.measure.digest,
        execute: () => {
          const startTime = DateTimeUtil.getTimestamp();

          if (config.system.dryFireProtection) {
            const DC = new PT65DriveController();
            if (config.measureParam.pidCtrl) {
              // DC.GetIOpticalAcquire().StartLEDController();
              hilog.info(100, 'Measurer', '打开测量LED,带PID');
            } else {
              // DC.GetIOpticalAcquire().TurnOnLED();
              hilog.info(100, 'Measurer', '打开测量LED,不带PID');
            }

            if (this.flow && !this.flow.Wait(10)) {
              // DC.GetIOpticalAcquire().TurnOffLED();
              throw new Error("用户终止");
            }

            // op.dryFireDitect();
            // DC.GetIOpticalAcquire().TurnOffLED();
            hilog.info(100, 'Measurer', '关闭LED');
          }

          const DC = new PT65DriveController();
          let thermostatTemp = 2;//DC.GetCurrentTemperature().GetThermostatTemp();
          hilog.info(100, 'Measurer', '加热消解前温度 = %{public}f ℃', thermostatTemp);

          const tempIncrement = thermostatTemp - this.temperatureBeforeAddReagent2;
          if (tempIncrement < config.measureParam.temperatureIncrement && !config.system.debugMode && config.measureParam.temperatureIncrement !== 0) {
            hilog.info(100, 'Measurer', '加热前温度增量过低异常');
            throw new Error("AddLiquidToDigestionException");
          }

          // op.ImmerseMeterPipe(setting.liquidType.blank, 2);

          const temp = config.measureParam.digestTemperature - thermostatTemp;
          if (temp > 0.01) {
            try {
              // FlowManager.Instance().ClearAllRemainEvent();
              // thermostatTemp = op.StartThermostat(ThermostatMode.Auto, config.measureParam.digestTemperature, setting.temperature.toleranceTemp, setting.temperature.digestTempTimeout);
            } catch (err) {
              hilog.error(100, 'Measurer', '加热消解异常: %{public}s', (err as Error).message);
              throw new Error(err);
            }
          }

          hilog.info(100, 'Measurer', '到达消解目标温度 = %{public}f℃', thermostatTemp);

          if (!this.flow?.Wait(config.measureParam.digestTime)) {
            // FlowManager.Instance().ClearAllRemainEvent();
            // op.StopThermostat();
            throw new Error("用户终止");
          }

          hilog.info(100, 'Measurer', '加热消解时间 = %{public}d', DateTimeUtil.getTimestamp() - startTime);
        }
      },
      {
        action: setting.runAction.measure.digestCooling,
        execute: () => {
          const startTime = DateTimeUtil.getTimestamp();

          // const DC = new PT65DriveController();
          // const thermostatTemp = DC.GetCurrentTemperature().GetThermostatTemp();
          // hilog.info(100, 'Measurer', '消解冷却前温度 = %{public}f℃', thermostatTemp);

          // const digestAirPumpingTemp = config.measureParam.reactTemperature + 5;
          // const difference = thermostatTemp - digestAirPumpingTemp;

          // if (difference > 0.01) {
          //   try {
          //     // FlowManager.Instance().ClearAllRemainEvent();
          //     // thermostatTemp = op.StartThermostat(ThermostatMode.Auto, digestAirPumpingTemp, 0.2, setting.temperature.digestToReactCoolingTimeout);
          //   } catch (err) {
          //     hilog.error(100, 'Measurer', '消解冷却异常: %{public}s', (err as Error).message);
          //     throw err;
          //   }
          //   // FlowManager.Instance().ClearAllRemainEvent();
          //   // thermostatTemp = op.StopThermostat();
          //   hilog.info(100, 'Measurer', '到达消解鼓气目标温度 = %{public}f℃', thermostatTemp);
          // }

          // if (config.measureParam.pidCtrl) {
          //   DC.GetIOpticalAcquire().StartLEDController();
          //   hilog.info(100, 'Measurer', '打开测量LED,带PID');
          // } else {
          //   DC.GetIOpticalAcquire().TurnOnLED();
          //   hilog.info(100, 'Measurer', '打开测量LED,不带PID');
          // }

          // op.DrainToWaste(setting.liquid.meterPipeVolume, WasteType.WasteReagent);

          // if (!config.measureParam.highlyOxidized) {
          //   const factor = DC.GetIPeristalticPump().GetPumpFactor(0);
          //   op.Drain(setting.liquidType.digestionRoom, 6, 0.3);
          // }

          // const digestCoolingTemp = config.measureParam.reactTemperature + setting.temperature.naturalCoolingTempValue;
          // const temp = thermostatTemp - digestCoolingTemp;

          // if (temp > 0.01) {
          //   try {
          //     // FlowManager.Instance().ClearAllRemainEvent();
          //     // thermostatTemp = op.StartThermostat(ThermostatMode.Natural, config.measureParam.reactTemperature, 0.1, setting.temperature.naturalCoolingTimeout);
          //   } catch (err) {
          //     hilog.error(100, 'Measurer', '消解自然冷却异常: %{public}s', (err as Error).message);
          //     throw err;
          //   }
          //   // FlowManager.Instance().ClearAllRemainEvent();
          //   // thermostatTemp = op.StopThermostat();
          //   hilog.info(100, 'Measurer', '到达消解自然冷却温度 = %{public}f℃', thermostatTemp);
          // }

          hilog.info(100, 'Measurer', '消解冷却时间 = %{public}d', DateTimeUtil.getTimestamp() - startTime);
        }
      },
      {
        action: setting.runAction.measure.readMeasureAD,
        execute: () => {
          const startTime = DateTimeUtil.getTimestamp();

          const DC = new PT65DriveController();
          //const temp = DC.GetCurrentTemperature();
          //hilog.info(100, 'Measurer', '读反应值前 消解温度 = %{public}f ℃，环境温度 = %{public}f ℃', temp.GetThermostatTemp(), temp.GetEnvironmentTemp());

          // const finalAD = op.StartAcquirerADWithFiltration(setting.signal.readADTime);
          // DC.GetIOpticalAcquire().TurnOffLED();
          hilog.info(100, 'Measurer', '关闭LED');

          //hilog.info(100, 'Measurer', '读反应值后 消解温度 = %{public}f ℃，环境温度 = %{public}f ℃', DC.GetCurrentTemperature().GetThermostatTemp(), DC.GetCurrentTemperature().GetEnvironmentTemp());

          // this.measureResult.finalReferenceAD = finalAD.GetReference();
          // this.measureResult.finalMeasureAD = finalAD.GetMeasure();
          //this.measureResult.finalThermostatTemp = temp.GetThermostatTemp();
          //this.measureResult.finalEnvironmentTemp = temp.GetEnvironmentTemp();

          hilog.info(100, 'Measurer', '读反应值时间 = %{public}d', DateTimeUtil.getTimestamp() - startTime);
        }
      },
      {
        action: null,
        execute: () => {
          // if (this.flow?.ProformaResultHandle) {
          //   this.flow.ProformaResultHandle(this.measureResult);
          // }
        }
      },
      {
        action: setting.runAction.measure.digestCooling,
        execute: () => {
          const startTime = DateTimeUtil.getTimestamp();

          const DC = new PT65DriveController();
          let thermostatTemp = 50; //DC.GetCurrentTemperature().GetThermostatTemp();
          const preDrainCoolingTemp = setting.temperature.naturalCoolingTempValue;
          let temp = thermostatTemp - preDrainCoolingTemp;

          if (temp > 0.01) {
            try {
              // FlowManager.Instance().ClearAllRemainEvent();
              // thermostatTemp = op.StartThermostat(ThermostatMode.Auto, preDrainCoolingTemp, 0.2, setting.temperature.digestToReactCoolingTimeout);
            } catch (err) {
              hilog.error(100, 'Measurer', '排液前冷却异常: %{public}s', (err as Error).message);
              throw new Error(err);
            }
            // FlowManager.Instance().ClearAllRemainEvent();
            // thermostatTemp = op.StopThermostat();
          }

          //thermostatTemp = DC.GetCurrentTemperature().GetThermostatTemp();
          hilog.info(100, 'Measurer', '消解自然冷却前温度 = %{public}f℃', thermostatTemp);

          if (thermostatTemp > 50) {
            try {
              // FlowManager.Instance().ClearAllRemainEvent();
              // thermostatTemp = op.StartThermostat(ThermostatMode.Natural, config.measureParam.preDrainCoolingTemp, 0, setting.temperature.naturalCoolingTimeout);
            } catch (err) {
              hilog.error(100, 'Measurer', '排液前自然冷却异常: %{public}s', (err as Error).message);
              throw new Error(err);
            }
            // FlowManager.Instance().ClearAllRemainEvent();
            // thermostatTemp = op.StopThermostat();
          }

          hilog.info(100, 'Measurer', '排液前冷却时间 = %{public}d', DateTimeUtil.getTimestamp() - startTime);
        }
      },
      {
        action: null,
        execute: () => {
          if (this.flow) {
            if(this.flow.ProformaResultHandle){
              this.flow.ProformaResultHandle(this.measureResult);
            }
          }
        }
      },
      {
        action: setting.runAction.measure.drainAfterMeasure,
        execute: () => {
          const startTime = DateTimeUtil.getTimestamp();

          // op.AirToDigestionRoom();
          // const reactTotalVol = setting.measure.range[1].sampleVolume + setting.liquid.reagent1Volume + setting.liquid.reagent2Volume;
          // const minTimes = op.GetMinDrainDigestionTimes(reactTotalVol);
          // op.PumpFromDigestionRoom(4, nil, WasteType.WasteReagent);
          // op.Pump(setting.liquidType.digestionRoom, 2.2, 0.2, false);
          // op.DrainToWaste(2.5, WasteType.WasteReagent);

          hilog.info(100, 'Measurer', '测量后排液时间 = %{public}d', DateTimeUtil.getTimestamp() - startTime);
        }
      },
      {
        action: setting.runAction.measure.cleanAfterMeasure,
        execute: () => {
          const startTime = DateTimeUtil.getTimestamp();

          let cleanTimes = 1;
          let cleanAftMeaBlankVol = setting.liquid.cleanVolume.cleanAftMeaBlankVol;
          if (config.measureParam.wasteWaterEnvironment) {
            cleanAftMeaBlankVol = setting.liquid.cleanVolume.cleanAftMeaBlankVol;
          }
          if (config.measureParam.tapWaterEnvironment) {
            cleanAftMeaBlankVol = setting.liquid.cleanVolume.cleanAftMeaBlankVol;
            cleanTimes = 2;
          }

          // op.PumpToDigestionRoom(setting.liquidType.blank, 1, 1);
          // op.DrainToWaste(0);
          // op.SecludeLiquid(setting.liquidType.blank);
          // op.Pump(setting.liquidType.digestionRoom, 2.2, 0.2, false);
          // op.DrainToWaste(2.2, WasteType.WasteReagent);

          for (let i = 1; i <= cleanTimes; i++) {
            if (cleanAftMeaBlankVol > 0) {
              // op.PumpToDigestionRoom(setting.liquidType.blank, cleanAftMeaBlankVol, 2.3);
              // op.DrainToWaste(0);
              // op.SecludeLiquid(setting.liquidType.blank);
              // op.DrainFromDigestionRoomCheck(nil, WasteType.WasteReagent, 2.4);
            }
          }

          status.measureStatus.digestionRoomIsBlank = true;
          // ConfigLists.SaveMeasureStatus();

          hilog.info(100, 'Measurer', '测量后清洗时间 = %{public}d', DateTimeUtil.getTimestamp() - startTime);
        }
      },
      {
        action: setting.runAction.measure.readInitialAD,
        execute: () => {
          const startTime = DateTimeUtil.getTimestamp();

          let readInitADBlankVolume = setting.liquid.cleanVolume.readInitADBlankVolume;
          if (config.measureParam.wasteWaterEnvironment || config.measureParam.tapWaterEnvironment) {
            readInitADBlankVolume = setting.liquid.cleanVolume.readInitADBlankVolume;
          }

          // op.PumpToDigestionRoom(setting.liquidType.blank, readInitADBlankVolume, 2.4);
          // op.DrainToWaste(0, WasteType.WasteWater);
          // op.SecludeLiquid(setting.liquidType.blank);

          const DC = new PT65DriveController();
          const targetTemp = 60;

          if (config.measureParam.pidCtrl) {
            // DC.GetIOpticalAcquire().StartLEDController();
            hilog.info(100, 'Measurer', '打开测量LED,带PID');
          } else {
            // DC.GetIOpticalAcquire().TurnOnLED();
            hilog.info(100, 'Measurer', '打开测量LED,不带PID');
          }

          const thermostatTemp = 50; //DC.GetCurrentTemperature().GetThermostatTemp();
          hilog.info(100, 'Measurer', '读空白值加热前温度 = %{public}f℃', thermostatTemp);

          try {
            // FlowManager.Instance().ClearAllRemainEvent();
            // op.StartThermostat(ThermostatMode.Auto, targetTemp, 5, setting.temperature.reactTempTimeout);
          } catch (err) {
            hilog.error(100, 'Measurer', '读空白值加热异常: %{public}s', (err as Error).message);
            throw new Error(err);
          }

          // FlowManager.Instance().ClearAllRemainEvent();
          // op.StopThermostat();
          // op.AirToDigestionRoom();

          if (!this.flow?.Wait(config.measureParam.readInitRilentTime)) {
            // FlowManager.Instance().ClearAllRemainEvent();
            // op.StopThermostat();
            throw new Error("用户终止");
          }

          //const temp = DC.GetCurrentTemperature();
          //hilog.info(100, 'Measurer', '读空白值 静置后消解室温度 = %{public}f 环境温度 = %{public}f', temp.GetThermostatTemp(), temp.GetEnvironmentTemp());

          // const initAD = op.StartAcquirerADWithFiltration(setting.signal.readADTime);
          // DC.GetIOpticalAcquire().TurnOffLED();
          hilog.info(100, 'Measurer', '关闭LED');

          if (!this.flow?.Wait(1)) {
            throw new Error("用户终止");
          }

          // const darkAD = op.StartAcquirerAD(setting.signal.readDarkADTime);

          // this.measureResult.initReferenceAD = initAD.GetReference() - darkAD.GetReference();
          // this.measureResult.initMeasureAD = initAD.GetMeasure() - darkAD.GetMeasure();
          // this.measureResult.finalReferenceAD = this.measureResult.finalReferenceAD - darkAD.GetReference();
          // this.measureResult.finalMeasureAD = this.measureResult.finalMeasureAD - darkAD.GetMeasure();
          this.measureResult.initThermostatTemp = 0;//temp.GetThermostatTemp();
          this.measureResult.initEnvironmentTemp = 0;//temp.GetEnvironmentTemp();

          hilog.info(100, 'Measurer', '读空白值时间 = %{public}d', DateTimeUtil.getTimestamp() - startTime);
        }
      },
      {
        action: null,
        execute: () => {
          status.measureStatus.lastMeasureEndTime = DateTimeUtil.getTimestamp();
          if (this.flow) {
            if(this.flow.ResultHandle){
              this.flow.ResultHandle(this.measureResult);
            }
          }
        }
      },
      {
        action: setting.runAction.measure.drainAfterMeasure,
        execute: () => {
          const startTime = DateTimeUtil.getTimestamp();

          if (!config.measureParam.wasteWaterEnvironment) {
            // const reactTotalVol = setting.liquid.cleanVolume.Common.readInitADBlankVolume;
            // const minTimes = op.GetMinDrainDigestionTimes(reactTotalVol);
            // op.DrainFromDigestionRoomCheck(minTimes, WasteType.WasteWater, 2.4);
          }

          hilog.info(100, 'Measurer', '测量后排液时间 = %{public}d', DateTimeUtil.getTimestamp() - startTime);
        }
      },
    ];
  }

  Reset(): void {
    this.flow = null;
    this.measureType = MeasureType.Sample;
    this.currentRange = 1;
    this.NowVolume = 0;
    this.addParam = {};

  }

  GetMeasureResult(): MeasureResult {
    const result: MeasureResult =  this.measureResult ;
    return result;
  }

  GetZeroMeasureResult(): MeasureResult {
    return {
      initReferenceAD: 0,
      initMeasureAD: 0,
      finalReferenceAD: 0,
      finalMeasureAD: 0,
      darkReferenceAD: 0,
      darkMeasureAD: 0,
      initThermostatTemp: 0,
      initEnvironmentTemp: 0,
      finalThermostatTemp: 0,
      finalEnvironmentTemp: 0,
    };
  }

  TimeCheck(): boolean {
    const currentTime = DateTimeUtil.getTimestamp();
    const measurerIntervalMaxTime = 36 * 60 * 60;
    const lastTime = status.measureStatus.lastMeasureEndTime;

    if (lastTime === 0) {
      hilog.info(100, 'Measurer', '出厂首次流程测量');
      return true;
    }

    const expireTime = lastTime + measurerIntervalMaxTime;
    if (expireTime - currentTime < 0) {
      hilog.info(100, 'Measurer', '距离上次测量已超36小时');
      return true;
    }
    return false;
  }

  GetRinseVol(): number {
    let rinseVol = 0;

    if (this.TimeCheck()) {
      rinseVol = 7;
    } else {
      if (this.addParam.rinseSampleVolume && this.addParam.rinseSampleVolume > 0) {
        rinseVol = this.addParam.rinseSampleVolume;
      } else if (this.addParam.rinseStandardVolume && this.addParam.rinseStandardVolume > 0) {
        rinseVol = this.addParam.rinseStandardVolume;
      } else if (this.addParam.rinseZeroCheckVolume && this.addParam.rinseZeroCheckVolume > 0) {
        rinseVol = this.addParam.rinseZeroCheckVolume;
      } else if (this.addParam.rinseRangeCheckVolume && this.addParam.rinseRangeCheckVolume > 0) {
        rinseVol = this.addParam.rinseRangeCheckVolume;
      } else if (this.addParam.rinseBlankVolume && this.addParam.rinseBlankVolume > 0) {
        rinseVol = this.addParam.rinseBlankVolume;
      }
    }

    return rinseVol;
  }

  SkipFlow(): void {
    status.measureStatus.lastMeasureEndTime = DateTimeUtil.getTimestamp();
    // if (this.flow?.ResultHandle) {
    //   this.flow.ResultHandle(this.measureResult);
    // }
  }

  Measure(): MeasureResult {
    if (setting.common.skipFlow) {
      this.SkipFlow();
      return this.measureResult;
    }

    if (this.steps.length !== 0) {
      hilog.info(100, 'Measurer', '--------------Execute configuration procedure--------------');
      for (const step of this.steps) {
        if (step.action) {
          hilog.info(100, 'Measurer', 'action: %{public}s', step.action.text);
        }
        const executeStartTime = DateTimeUtil.getTimestamp();
        step.execute();
        if (step.action) {
          this.CheckExecuteTime(step.action.text, DateTimeUtil.getTimestamp() - executeStartTime, false);
        }
      }
    } else {
      hilog.info(100, 'Measurer', '--------------Execute default procedure--------------');
      for (const step of this.steps) {
        if (step.action) {
          hilog.info(100, 'Measurer', 'action: %{public}s', step.action.text);
        }
        const executeStartTime = DateTimeUtil.getTimestamp();
        step.execute();
        if (step.action && step.action.GetTime) {
          this.CheckExecuteTime(step.action.text, DateTimeUtil.getTimestamp() - executeStartTime, false);
          this.emitterAction(step.action.text, step.action.GetTime());
        }
      }
    }
    this.emitterAction("空闲", 0);

    return this.measureResult;
  }

  emitterAction(step: string, runTime: number): void {
    const eventData: emitter.EventData = {
      data: {
        action: step,
        time: runTime
      }
    };
    emitter.emit("MeasureStatus", eventData);
  }

  CheckExecuteTime(name: string, time: number, isWarn: boolean, checkParam?: number, isError: number = 0): boolean {
    if (!name || time === undefined) {
      return false;
    }

    let notMatchFlow = true;

    for (const item of status.measureStatus.measurerSaveTime) {
      if (item.name === name) {
        notMatchFlow = false;

        if (isWarn !== undefined) {
          //item.isWarn = isWarn;
        }

        if (item.time2 === -1 && isError === 0) {
          item.time2 = time;
          hilog.info(100, 'Measurer', '流程：%{public}s 存储第二次时间 %{public}d', name, time);
          break;
        } else if (item.time3 === -1 && isError === 0) {
          item.time3 = time;
          hilog.info(100, 'Measurer', '流程：%{public}s 存储第三次时间 %{public}d', name, time);

          let time1 = item.time1;
          let time2 = item.time2;
          let time3 = item.time3;
          //todo
          // if (time1 > time2) {
          //   [time1, time2] = [time2, time1];
          // }
          // if (time2 > time3) {
          //   [time2, time3] = [time3, time2];
          //   if (time1 > time2) {
          //     [time1, time2] = [time2, time1];
          //   }
          // }

          if (Math.abs(time1 - time3) > time2 / 2) {
            hilog.info(100, 'Measurer', '前三次测量出现异常时间，需要清除异常时间 排序后时间为：%{public}d %{public}d %{public}d', time1, time2, time3);
            if (Math.abs(time2 - time1) > Math.abs(time2 - time3)) {
              hilog.info(100, 'Measurer', '异常时间为 %{public}d', time1);
              item.time1 = time2;
              item.time2 = time3;
            } else {
              hilog.info(100, 'Measurer', '异常时间为 %{public}d', time3);
              item.time1 = time2;
              item.time2 = time1;
            }
            hilog.info(100, 'Measurer', '下个流程将重新记录第三次时间');
            item.time3 = -1;
          }
          break;
        }

        const totalTime = (item.time1 + item.time2 + item.time3) / 3;

        if ((checkParam === undefined || item.checkParam === checkParam) &&
            Math.abs(totalTime - time) > totalTime * 0.5) {
          if (isWarn) {
            hilog.info(100, 'Measurer', '流程时间异常，流程：%{public}s 本次测量时间：%{public}ds 正常测量时间：%{public}ds', name, time, totalTime);
          } else {
            hilog.info(100, 'Measurer', '流程时间变动过大，流程：%{public}s 本次测量时间：%{public}ds 正常测量时间：%{public}ds', name, time, totalTime);
          }
        } else if (checkParam !== undefined && item.checkParam !== checkParam) {
          hilog.info(100, 'Measurer', '流程：%{public}s 关键参数修改，统计时间清空', name);
          item.time1 = time;
          item.time2 = -1;
          item.time3 = -1;
          item.checkParam = checkParam;
        } else {
          item.time1 = item.time2;
          item.time2 = item.time3;
          item.time3 = time;
        }

        // ConfigLists.SaveMeasureStatus();
        break;
      }
    }

    if (notMatchFlow) {
      let isSave = false;
      for (const item of status.measureStatus.measurerSaveTime) {
        if (item.name === "" && isError === 0) {
          item.name = name;
          item.time1 = time;
          hilog.info(100, 'Measurer', '流程：%{public}s 存储第一次时间 %{public}d', name, time);
          if (isWarn !== undefined) {
            //item.isWarn = isWarn;
          }
          if (checkParam !== undefined) {
            item.checkParam = checkParam;
          }
          isSave = true;
          // ConfigLists.SaveMeasureStatus();
          break;
        }
      }

      if (!isSave) {
        hilog.info(100, 'Measurer', '只能检查10个流程');
      }
    }

    return true;
  }

  PrintAllCheckExecuteTime(): void {
    hilog.info(100, 'Measurer', '');
    for (const item of status.measureStatus.measurerSaveTime) {
      if (item.name !== "") {
        const average = (item.time1 + item.time2 + item.time3) / 3;
        hilog.info(100, 'Measurer', 'Flow:%{public}s  time1= %{public}ds  time2= %{public}ds  time3= %{public}ds  average= %{public}d',
          item.name, item.time1, item.time2, item.time3, average);
        hilog.info(100, 'Measurer', '');
      }
    }
  }

  SaveExecuteTime(name: string, time: number): void {
    for (const item of status.measureStatus.measurerSaveTime) {
      if (item.name === name) {
        item.time1 = item.time2;
        item.time2 = item.time3;
        item.time3 = time;
        // ConfigLists.SaveMeasureStatus();
        break;
      }
    }
  }

  GetExecuteTime(name: string): number {
    for (const item of status.measureStatus.measurerSaveTime) {
      if (item.name === name) {
        if (item.time1 !== 0 && item.time2 !== 0 && item.time3 !== 0) {
          return Math.round((item.time1 + item.time2 + item.time3) / 3);
        }
        return 0;
      }
    }
    return 0;
  }
}
