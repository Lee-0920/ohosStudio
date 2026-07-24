import { hilog } from "@kit.PerformanceAnalysisKit";
import { Flow } from './Flow';
import { DateTimeUtil } from 'base';
import { BaseController } from 'controllerplugin';
import { liquidTypes } from '../Setting/LiquidType';
import { Operator, WasteType } from '../Flow/Operator';
import { setting } from '../Setting/Setting';
import { config } from '../Config/Config';
import { ThermostatMode } from 'communication'; //导入模块
/**
 * 清洗类型枚举
 */
export enum CleanType {
  cleanMeterPipe = 0,      // 清洗定量管
  cleanDigestionRoom = 1,  // 清洗消解室
  cleanDeeply = 2,         // 深度清洗
  cleanAll = 3,            // 清洗所有管路
  oneKeyRenew = 4,         // 一键填充试剂
  multiValveAutoClean = 5, // 多联阀自动清洗
}

export class CleanFlow extends Flow {
  cleanDateTime: number = DateTimeUtil.getTimestamp();
  cleanType: CleanType = CleanType.cleanMeterPipe;
  isUseStart: boolean = false;

  constructor(name: string, cleanType: CleanType) {
    super(name);
    this.cleanType = cleanType;
    this.isUseStart = false;
  }

  GetRuntime(): number {
    // TODO: 根据 cleanType 获取运行时间
    // 需要实现 setting.runStatus 相关接口
    return 30; // 默认返回30秒
  }

  OnStart(): void {
    hilog.info(122, 'CleanFlow', 'OnStart cleanType = %{public}d ', this.cleanType);

    // 组合流程需要重新加载时间
    this.cleanDateTime = DateTimeUtil.getTimestamp();

    // // 初始化下位机
    // const controller = new BaseController();
    // const deviceStatus = controller.GetIDeviceStatus();
    // if (deviceStatus) {
    //   // deviceStatus.Initialize();
    // }

    // 检测消解室是否为安全温度
    // op.CheckDigestSafety()

    // 继电器指示
    // Helper.Result.RelayOutOperate(setting.mode.relayOut.cleanInstruct, true)

    // 设置运行状态
    // let runStatus = Helper.Status.SetStatus(setting.runStatus.cleanDeeply);
    // 根据 cleanType 设置对应的运行状态
    // StatusManager.Instance().SetStatus(runStatus);
  }

  OnProcess(): void {
    hilog.info(122, 'CleanFlow', 'OnProcess Start CleanType = %{public}d ', this.cleanType);

    this.isUserStop = false;
    this.isFinish = false;

    try {
      switch (this.cleanType) {
        case CleanType.cleanMeterPipe:
          this.CleanMeterPipe();
          break;
        case CleanType.cleanDigestionRoom:
          this.CleanDigestionRoom();
          break;
        case CleanType.cleanDeeply:
          this.CleanDeeply();
          break;
        case CleanType.cleanAll:
          this.CleanAll();
          break;
        case CleanType.oneKeyRenew:
          this.OneKeyRenew();
          break;
        case CleanType.multiValveAutoClean:
          this.MultiValveAutoClean();
          break;
      }
    } catch (err) {
      if (err instanceof Error) {
        // 检查异常类型
        if (err.message.includes("PumpStoppedException") ||
            err.message.includes("MeterStoppedException") ||
            err.message.includes("ThermostatStoppedException") ||
            err.message.includes("UserStopException")) {
          this.isUserStop = true;
        }
        throw err;
      }
    }

    this.isFinish = true;
    hilog.info(122, 'CleanFlow', 'OnProcess End');
  }

  OnStop(): void {
    hilog.info(122, 'CleanFlow', 'OnStop');

    // // 初始化下位机
    // const controller = new BaseController();
    // const deviceStatus = controller.GetIDeviceStatus();
    // if (deviceStatus) {
    //   // deviceStatus.Initialize();
    // }

    // 继电器指示
    // Helper.Result.RelayOutOperate(setting.mode.relayOut.cleanInstruct, false)

    if (this.cleanType == CleanType.cleanDeeply) {
      // status.measure.schedule.autoClean.dateTime = this.cleanDateTime;
      // ConfigLists.SaveMeasureStatus();
    }

    if (!this.isFinish) {
      if (this.isUserStop) {
        this.result = "用户终止";
        hilog.info(122, 'CleanFlow', '用户终止');
      } else {
        this.result = "故障终止";
        hilog.warn(122, 'CleanFlow', '故障终止');
      }
    } else {
      this.result = "清洗完成";
      hilog.info(122, 'CleanFlow', '清洗完成');
      hilog.info(122, 'CleanFlow', '清洗流程总时间 = %{public}ds', DateTimeUtil.getTimestamp() - this.cleanDateTime);
    }

    // 保存试剂余量表
    // ReagentRemainManager.SaveRemainStatus();

    // status.measure.isUseStart = false;
    // ConfigLists.SaveMeasureStatus();

    // 检测消解室是否为安全温度
    // op.CheckDigestSafety();
  }

  /**
   * 深度清洗流程
   */
  private CleanDeeply(): void {
    hilog.info(122, 'CleanFlow', 'CleanDeeply Start');
    const op = Operator.getInstance();

    // 从定量管排液到废液桶
    op.DrainToWaste(setting.liquid.meterPipeVolume);

    // 排消解器溶液到废液桶
    op.DrainFromDigestionRoom();

    // 加浓硫酸到消解室
    op.SlowMeterToDigestionRoom(liquidTypes.reagent2, 2);
    op.DrainToWaste(0);
    op.Drain(liquidTypes.reagent2, setting.liquid.liquidSecludeVolume*2, setting.liquid.liquidSecludeSpeed);

    // 消解与冷却逻辑
    if (op.ITemperatureControl.getTemperature().thermostatTemp < setting.temperature.cleanDigestTemp) {
      // 加热
      op.StartThermostat(ThermostatMode.Auto, 100, setting.temperature.toleranceTemp, setting.temperature.digestTempTimeout);
      if (!this.Wait(600)) {
        throw new Error("用户终止");
      }
      op.StopThermostat();

      // 冷却
      op.StartThermostat(ThermostatMode.Refrigerate, 70, 0, setting.temperature.digestTempTimeout);
      op.StopThermostat();
    }

    // 排消解器溶液到废液桶
    op.CleanPipeFromDigestionRoom(liquidTypes.digestionRoom, 4);

    // 清洗消解室
    op.SimpleCleanDigestionRoom(liquidTypes.blank, setting.clean.cleanVolume);
    op.SimpleCleanDigestionRoom(liquidTypes.blank, setting.clean.cleanVolume);

    this.isFinish = true;
    hilog.info(122, 'CleanFlow', 'CleanDeeply End');
  }

  /**
   * 清洗消解室流程
   */
  private CleanDigestionRoom(): void {
    hilog.info(122, 'CleanFlow', 'CleanDigestionRoom Start');
    const op = Operator.getInstance();

    // 清洗消解室
    op.CleanDigestionRoom(liquidTypes.blank, setting.clean.cleanVolume);

    this.isFinish = true;
    hilog.info(122, 'CleanFlow', 'CleanDigestionRoom End');
  }

  /**
   * 清洗定量管流程
   */
  private CleanMeterPipe(): void {
    hilog.info(122, 'CleanFlow', 'CleanMeterPipe Start');
    const op = Operator.getInstance();
    op.DrainToWaste(2);
    op.CleanMeterPipe(liquidTypes.blank, 4);

    this.isFinish = true;
    hilog.info(122, 'CleanFlow', 'CleanMeterPipe End');
  }

  /**
   * 清洗所有管路
   */
  private CleanAll(): void {
    hilog.info(122, 'CleanFlow', 'CleanAll Start');
    const op = Operator.getInstance();

    // 清洗消解室(包含排空定量管和消解室)
    op.CleanDigestionRoom(liquidTypes.blank, setting.clean.cleanVolume);

    // 排空水样管
    op.Drain(liquidTypes.sample, setting.liquid.samplePipeVolume + config.measureParam.extendSamplePipeVolume, 0);

    // 排空量程校准液管
    op.Drain(liquidTypes.standard, setting.liquid.standardPipeVolume, 0);

    // 如果开启扩展功能，排空零点核查液管和标样核查液管
    // if (config.system.targetMap.EXTEND.enable == true) {
    //   op.Drain(liquidTypes.zeroCheck, setting.liquid.zeroCheckPipeVolume, 0);
    //   op.Drain(liquidTypes.rangeCheck, setting.liquid.rangeCheckPipeVolume, 0);
    // }

    // 排空试剂一管和试剂二管
    op.Drain(liquidTypes.reagent1, setting.liquid.reagent1PipeVolume, 0);
    op.Drain(liquidTypes.reagent2, setting.liquid.reagent2PipeVolume, 0);

    // 清洗各管路...
    op.CleanReagentPipe(liquidTypes.blank, 3*setting.unitVolume);
    // ...

    this.isFinish = true;
    hilog.info(122, 'CleanFlow', 'CleanAll End');
  }

  /**
   * 一键管路更新
   */
  private OneKeyRenew(): void {
    hilog.info(122, 'CleanFlow', 'OneKeyRenew Start');
    const op = Operator.getInstance();

    // 清空残留液
    op.DrainToWaste(setting.liquid.meterPipeVolume);
    op.DrainFromDigestionRoom();

    // 清空试剂一管
    op.ClearReagentPipe(liquidTypes.reagent1, setting.liquid.pipeRenewVolume);

    // 清空试剂二管
    op.ClearReagentPipe(liquidTypes.reagent2, setting.liquid.pipeRenewVolume);

    // 清空零点校准液管
    op.ClearReagentPipe(liquidTypes.blank, setting.liquid.pipeRenewVolume);

    // 清洗消解室
    op.PumpToDigestionRoom(liquidTypes.blank, 1.5, 1.5, WasteType.WasteWater);
    op.Pump(liquidTypes.digestionRoom, 2.2, 0.2, false);
    op.DrainToWaste(2.2, WasteType.WasteWater);

    hilog.info(122, 'CleanFlow', 'OneKeyRenew End');
  }

  /**
   * 多联阀自动清洗
   */
  private MultiValveAutoClean(): void {
    hilog.info(122, 'CleanFlow', 'MultiValveAutoClean Start');

    const op = Operator.getInstance();

    // 定量零点校准液，加压反冲水样管
    // op.SetMeterOverValue(MeterMode.Smart, 0);
    // op.Meter(MeterMode.Smart, liquidTypes.blank, cleanMeterPipevolume, RollDirection.Suck);
    // op.DrainNotCloseValve(liquidTypes.sample, 1, drainSpeed);
    // op.Drain(liquidTypes.sample, 5, drainSpeed);

    // 定量零点校准液，加压反冲废液管
    // op.SetMeterOverValue(MeterMode.Smart, 0);
    // op.Meter(MeterMode.Smart, liquidTypes.blank, cleanMeterPipevolume, RollDirection.Suck);
    // op.DrainToWasteNotCloseValve(1, drainSpeed);
    // op.DrainToWaste(5);

    // 定量零点校准液，加压反冲废水管
    // op.SetMeterOverValue(MeterMode.Smart, 0);
    // op.Meter(MeterMode.Smart, liquidTypes.blank, cleanMeterPipevolume, RollDirection.Suck);
    // op.DrainToWasteNotCloseValve(1, drainSpeed);
    // op.DrainToWaste(5, WasteType.WasteWater);

    hilog.info(122, 'CleanFlow', 'MultiValveAutoClean End');
  }
}
