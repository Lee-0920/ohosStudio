import { hilog } from "@kit.PerformanceAnalysisKit";
import { Flow } from './Flow';
import { DateTimeUtil } from 'base';
import { BaseController } from 'controllerplugin';
import { liquidTypes } from '../Setting/LiquidType';
import { Operator, WasteType } from '../Flow/Operator';
import { setting } from '../Setting/Setting';
import { config } from '../Config/Config';
import { ThermostatMode } from 'communication'; //导入模块
import { ActionItem } from '../Setting/RunAction';
import { StatusItem } from '../Setting/RunStatus';
import { emitter } from '@kit.BasicServicesKit';
import { WorkerMeasureStatusEvent } from './Measurer';
import { MeasureType } from './MeasureFlow';

/** Modbus 系统状态码：与 feature/modbus 的 SystemStatus 对齐 */
const CLEAN_QUANT_TUBE_STATUS = 6;
const CLEAN_DIGESTION_STATUS = 5;
const DEEP_CLEAN_STATUS = 22;           // 深度清洗
const CLEAN_ALL_PIPES_STATUS = 7;
const ONE_KEY_RENEW_STATUS = 9;         // 一键填充试剂复用一键运行
const MULTI_VALVE_AUTO_CLEAN_STATUS = 5; // 多联阀自动清洗复用清洗消解室

/**
 * 当前状态信息（显式接口，避免 ArkTS 对象字面量作为类型声明报错）。
 */
export interface CleanStatusInfo {
  label: string;
  totalSeconds: number;
}

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
    this.emitCleanProgress('start');

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
      this.isFinish = true;
    } catch (err) {
      if (err instanceof Error) {
        // 检查异常类型
        if (err.message.includes("PumpStoppedException") ||
            err.message.includes("MeterStoppedException") ||
            err.message.includes("ThermostatStoppedException") ||
            err.message.includes("UserStopException") ||
            err.message.includes("用户终止")) {
          this.isUserStop = true;
        }
        throw err;
      }
    } finally {
      // 正常结束、用户停止或异常都要发送 end，确保底部进度条和 Modbus 回到空闲
      hilog.info(122, 'CleanFlow', 'OnProcess End');
      this.emitCleanProgress('end');
    }
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

    this.emitCleanProgress('action', setting.runAction.drainToWaste);
    // 从定量管排液到废液桶
    op.DrainToWaste(setting.liquid.meterPipeVolume);
    if (this.IsCancelled()) {
      throw new Error("UserStopException");
    }

    this.emitCleanProgress('action', setting.runAction.cleanDigestionRoom);
    // 排消解器溶液到废液桶
    op.DrainFromDigestionRoom();
    if (this.IsCancelled()) {
      throw new Error("UserStopException");
    }

    // 加浓硫酸到消解室
    op.SlowMeterToDigestionRoom(liquidTypes.reagent2, 2);
    if (this.IsCancelled()) {
      throw new Error("UserStopException");
    }
    op.DrainToWaste(0);
    op.Drain(liquidTypes.reagent2, setting.liquid.liquidSecludeVolume*2, setting.liquid.liquidSecludeSpeed);
    if (this.IsCancelled()) {
      throw new Error("UserStopException");
    }

    // 消解与冷却逻辑
    if (op.ITemperatureControl.getTemperature().thermostatTemp < setting.temperature.cleanDigestTemp) {
      // 加热
      op.StartThermostat(ThermostatMode.Auto, 100, setting.temperature.toleranceTemp, setting.temperature.digestTempTimeout);
      if (!this.Wait(600)) {
        throw new Error("UserStopException");
      }
      op.StopThermostat();

      // 冷却
      op.StartThermostat(ThermostatMode.Refrigerate, 70, 0, setting.temperature.digestTempTimeout);
      op.StopThermostat();
    }
    if (this.IsCancelled()) {
      throw new Error("UserStopException");
    }

    // 排消解器溶液到废液桶
    op.CleanPipeFromDigestionRoom(liquidTypes.digestionRoom, 4);
    if (this.IsCancelled()) {
      throw new Error("UserStopException");
    }

    // 清洗消解室
    op.SimpleCleanDigestionRoom(liquidTypes.blank, setting.clean.cleanVolume);
    if (this.IsCancelled()) {
      throw new Error("UserStopException");
    }
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

    this.emitCleanProgress('action', setting.runAction.cleanDigestionRoom);

    // 清洗消解室
    op.CleanDigestionRoom(liquidTypes.blank, setting.clean.cleanVolume);
    if (this.IsCancelled()) {
      throw new Error("UserStopException");
    }

    this.isFinish = true;
    hilog.info(122, 'CleanFlow', 'CleanDigestionRoom End');
  }

  /**
   * 清洗定量管流程
   */
  private CleanMeterPipe(): void {
    hilog.info(122, 'CleanFlow', 'CleanMeterPipe Start');
    const op = Operator.getInstance();

    this.emitCleanProgress('action', setting.runAction.cleanMeterPipe);

    op.DrainToWaste(2);
    if (this.IsCancelled()) {
      throw new Error("UserStopException");
    }
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

    this.emitCleanProgress('action', setting.runAction.cleanAll.cleanDigestionRoom);
    // 清洗消解室(包含排空定量管和消解室)
    op.CleanDigestionRoom(liquidTypes.blank, setting.clean.cleanVolume);
    if (this.IsCancelled()) {
      throw new Error("UserStopException");
    }

    this.emitCleanProgress('action', setting.runAction.cleanAll.drainSamplePipe);
    // 排空水样管
    op.Drain(liquidTypes.sample, setting.liquid.samplePipeVolume + config.measureParam.extendSamplePipeVolume, 0.5);
    if (this.IsCancelled()) {
      throw new Error("UserStopException");
    }

    this.emitCleanProgress('action', setting.runAction.cleanAll.drainStandardPipe);
    // 排空量程校准液管
    op.Drain(liquidTypes.standard, setting.liquid.standardPipeVolume, 0.5);
    if (this.IsCancelled()) {
      throw new Error("UserStopException");
    }

    // 如果开启扩展功能，排空零点核查液管和标样核查液管
    // if (config.system.targetMap.EXTEND.enable == true) {
    //   op.Drain(liquidTypes.zeroCheck, setting.liquid.zeroCheckPipeVolume, 0);
    //   op.Drain(liquidTypes.rangeCheck, setting.liquid.rangeCheckPipeVolume, 0);
    // }

    this.emitCleanProgress('action', setting.runAction.cleanAll.drainReagent1Pipe);
    // 排空试剂一管和试剂二管
    op.Drain(liquidTypes.reagent1, setting.liquid.reagent1PipeVolume, 0.5);
    if (this.IsCancelled()) {
      throw new Error("UserStopException");
    }

    this.emitCleanProgress('action', setting.runAction.cleanAll.drainReagent2Pipe);
    op.Drain(liquidTypes.reagent2, setting.liquid.reagent2PipeVolume, 0.5);
    if (this.IsCancelled()) {
      throw new Error("UserStopException");
    }

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

    this.emitCleanProgress('action', setting.runAction.oneKeyMaintain.clearWaste);
    // 清空残留液
    op.DrainToWaste(setting.liquid.meterPipeVolume);
    op.DrainFromDigestionRoom();

    this.emitCleanProgress('action', setting.runAction.oneKeyMaintain.clearReagent1Pipe);
    // 清空试剂一管
    op.ClearReagentPipe(liquidTypes.reagent1, setting.liquid.pipeRenewVolume);

    this.emitCleanProgress('action', setting.runAction.oneKeyMaintain.clearReagent2Pipe);
    // 清空试剂二管
    op.ClearReagentPipe(liquidTypes.reagent2, setting.liquid.pipeRenewVolume);

    this.emitCleanProgress('action', setting.runAction.oneKeyMaintain.clearBlankPipe);
    // 清空零点校准液管
    op.ClearReagentPipe(liquidTypes.blank, setting.liquid.pipeRenewVolume);

    this.emitCleanProgress('action', setting.runAction.cleanDigestionRoom);
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

  /**
   * 根据当前测量类型获取对应的状态文本和总时长。
   */
  private getCurrentStatusInfo(): CleanStatusInfo {
    switch (this.cleanType) {
      case CleanType.cleanMeterPipe:
        return {
          label: setting.runStatus.cleanMeterPipe.text,
          totalSeconds: setting.runStatus.cleanMeterPipe.GetTime?.() ?? 0
        };
      case CleanType.cleanDigestionRoom:
        return {
          label: setting.runStatus.cleanDigestionRoom.text,
          totalSeconds: setting.runStatus.cleanDigestionRoom.GetTime?.() ?? 0
        };
      case CleanType.cleanDeeply:
        return {
          label: setting.runStatus.cleanDeeply.text,
          totalSeconds: setting.runStatus.cleanDeeply.GetTime?.() ?? 0
        };
      case CleanType.cleanAll:
        return {
          label: setting.runStatus.cleanAll.text,
          totalSeconds: setting.runStatus.cleanAll.GetTime?.() ?? 0
        };
      case CleanType.oneKeyRenew:
        return {
          label: setting.runStatus.oneKeyRenew.text,
          totalSeconds: setting.runStatus.oneKeyRenew.GetTime?.() ?? 0
        };
      default:
        return { label: '空闲', totalSeconds: 0 };
    }
  }

  /**
   * 向主线程发送测量进度事件。
   * 事件通过 emitter 进程级事件总线发送，包含当前状态和当前动作的完整信息。
   */
  private emitCleanProgress(phase: 'start' | 'action' | 'end', action?: ActionItem): void {
    const statusInfo = this.getCurrentStatusInfo();
    const payload: WorkerMeasureStatusEvent = {
      type: 'measureProgress',
      phase: phase,
      statusLabel: statusInfo.label,
      statusTotalSeconds: statusInfo.totalSeconds,
      actionLabel: action?.text ?? '空闲',
      actionTotalSeconds: action?.GetTime?.() ?? 0,
      measureType: MeasureType.Sample, // 非测量流程占位，实际以 systemStatusCode 为准
      timestamp: DateTimeUtil.getTimestamp(),
      systemStatusCode: this.mapCleanTypeToSystemStatus(this.cleanType)
    };
    const eventData: emitter.EventData = {
      data: payload
    };
    emitter.emit("MeasureStatus", eventData);
    hilog.info(
      100,
      'Measurer',
      'emit measure progress phase=%{public}s status=%{public}s action=%{public}s actionTime=%{public}d',
      phase,
      statusInfo.label,
      action?.text ?? '空闲',
      action?.GetTime?.() ?? 0
    );
  }

  /**
   * 将清洗类型映射为 Modbus 系统状态码。
   */
  private mapCleanTypeToSystemStatus(cleanType: CleanType): number {
    switch (cleanType) {
      case CleanType.cleanMeterPipe:
        return CLEAN_QUANT_TUBE_STATUS;
      case CleanType.cleanDigestionRoom:
        return CLEAN_DIGESTION_STATUS;
      case CleanType.cleanDeeply:
        return DEEP_CLEAN_STATUS;
      case CleanType.cleanAll:
        return CLEAN_ALL_PIPES_STATUS;
      case CleanType.oneKeyRenew:
        return ONE_KEY_RENEW_STATUS;
      case CleanType.multiValveAutoClean:
        return MULTI_VALVE_AUTO_CLEAN_STATUS;
      default:
        return 0;
    }
  }
}
