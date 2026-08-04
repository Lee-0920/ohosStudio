import { hilog } from "@kit.PerformanceAnalysisKit";
import { Flow } from './Flow';
import { DateTimeUtil } from 'base';
import { BaseController } from 'controllerplugin';
import { PT65DriveController } from "pt65drivecontrollerplugin";
import { liquidTypes, LiquidType } from '../Setting/LiquidType';
import { Operator, WasteType } from './Operator';
import { setting } from '../Setting/Setting';
import { config } from '../Config/Config';
import { ActionItem } from '../Setting/RunAction';
import { MeterMode, RollDirection } from 'communication';
import { emitter } from '@kit.BasicServicesKit';
import { WorkerMeasureStatusEvent } from './Measurer';
import { MeasureType } from './MeasureFlow';

/** Modbus 系统状态码：管路操作 */
const PIPE_OPERATION_STATUS = 12;

export enum LiquidOperateType {
  SuckFromSample,
  SuckFromStandard,
  SuckFromBlank,
  SuckFromRangeCheck,
  SuckFromReagent1,
  SuckFromReagent2,
  SuckFromReagent3,
  SuckFromDigestionRoom,
  DrainToWaste,
  DrainToDigestionRoom,
  DrainToSample,
  DrainToStandard,
  DrainToBlank,
  DrainToRangeCheck,
  DrainToReagent1,
  DrainToReagent2,
  DrainToReagent3,
}


export class LiquidOperateFlow extends Flow {
  source: LiquidType = liquidTypes.none;
  dest: LiquidType = liquidTypes.none;
  mode: number = 0;
  sVolume: number = 0;
  dVolume: number = 0;
  action: string = '';
  dateTime: number = DateTimeUtil.getTimestamp();

  constructor(name: string, source?: LiquidType, dest?: LiquidType, mode: number = 0, sVol: number = 0, dVol: number = 0, action: string = '') {
    super(name);
    this.source = source ?? liquidTypes.none;
    this.dest = dest ?? liquidTypes.none;
    this.mode = mode;
    this.sVolume = sVol;
    this.dVolume = dVol;
    this.action = action;
  }

  GetRuntime(): number {
    return 0;
  }

  OnStart(): void {
    hilog.info(122, 'LiquidOperateFlow', 'OnStart');

    // 初始化下位机
    const controller = new BaseController();
    const deviceStatus = controller.GetIDeviceStatus();
    if (deviceStatus) {
      // deviceStatus.Initialize();
    }

    // 检测消解室是否为安全温度
    // op.CheckDigestSafety()
  }

  OnProcess(): void {
    hilog.info(122, 'LiquidOperateFlow', 'OnProcess Start');

    this.isUserStop = false;
    this.isFinish = false;
    this.dateTime = DateTimeUtil.getTimestamp();
    const op = Operator.getInstance();

    try {
      // 设置运行状态
      // let runStatus = Helper.Status.SetStatus(setting.runStatus.liquidOperate);
      // StatusManager.Instance().SetStatus(runStatus);

      // 设置运行动作
      // let runAction = Helper.Status.SetAction(this.action);
      // StatusManager.Instance().SetAction(runAction);

      this.emitPipeOperationProgress('start', this.action);

      if (this.source != liquidTypes.none) {
        const factor = op.IPeristalticPump.getPumpFactor(0);

        if (this.source == liquidTypes.reagent2) {
          op.IOpticalMeter.setMeteSpeed(setting.liquid.slowMeterSpeed * factor);
        } else {
          op.IOpticalMeter.setMeteSpeed(setting.liquid.meterSpeed * factor);
        }

        switch (this.mode) {
          case 0:
            op.Pump(this.source, this.sVolume, 0.2);
            break;
          case 1:
            op.SetMeterOverValue(MeterMode.Smart, 0);
            op.Meter(MeterMode.Smart, this.source, this.sVolume, RollDirection.Suck);
            break;
          case 2:
            op.SetMeterOverValue(MeterMode.Accurate, setting.liquid.accurateMeterOverValue);
            // 根据定量点选择LED检测方向
            if (this.sVolume == config.hardware.meterPoint.point[1].setVolume) {
              op.IOpticalMeter.turnOnLED(1);
              this.Wait(1);
              const meterLed1AD = op.IOpticalMeter.getSingleOpticalAD(1);
              op.IOpticalMeter.turnOffLED(1);
              this.Wait(1);
              if (meterLed1AD > 1000) {
                op.Meter(MeterMode.Accurate, this.source, this.sVolume, RollDirection.Suck);
              } else {
                op.Meter(MeterMode.Accurate, this.source, this.sVolume, RollDirection.Drain);
              }
            } else {
              op.IOpticalMeter.turnOnLED(2);
              this.Wait(1);
              const meterLed2AD = op.IOpticalMeter.getSingleOpticalAD(2);
              op.IOpticalMeter.turnOffLED(2);
              this.Wait(1);
              if (meterLed2AD > 1000) {
                op.Meter(MeterMode.Accurate, this.source, this.sVolume, RollDirection.Suck);
              } else {
                op.Meter(MeterMode.Accurate, this.source, this.sVolume, RollDirection.Drain);
              }
            }
            break;
          default:
            op.Pump(this.source, this.sVolume, 0.2);
            break;
        }
      }

      if (this.dest != liquidTypes.none) {
        op.Drain(this.dest, this.dVolume, 0.2);
      }

    } catch (err) {
      if (err instanceof Error) {
        if (err.message.includes("PumpStoppedException") ||
            err.message.includes("MeterStoppedException")) {
          this.isUserStop = true;
          this.emitPipeOperationProgress('end');
        }
        throw err;
      }
    }

    this.isFinish = true;
    hilog.info(122, 'LiquidOperateFlow', 'OnProcess End');
    this.emitPipeOperationProgress('end');
  }

  OnStop(): void {
    hilog.info(122, 'LiquidOperateFlow', 'OnStop');

    // 初始化下位机
    const controller = new BaseController();
    const deviceStatus = controller.GetIDeviceStatus();
    if (deviceStatus) {
      // deviceStatus.Initialize();
    }

    // 保存试剂余量表
    // ReagentRemainManager.SaveRemainStatus();

    if (!this.isFinish) {
      if (this.isUserStop) {
        this.result = "用户终止";
        hilog.info(122, 'LiquidOperateFlow', '用户终止');
      } else {
        this.result = "故障终止";
        hilog.warn(122, 'LiquidOperateFlow', '故障终止');
      }
    } else {
      this.result = "管路操作结束";
      hilog.info(122, 'LiquidOperateFlow', '管路操作结束');
      hilog.info(122, 'LiquidOperateFlow', '管路操作流程总时间 = %{public}ds', DateTimeUtil.getTimestamp() - this.dateTime);
    }
  }

  /**
   * 向主线程发送测量进度事件。
   * 事件通过 emitter 进程级事件总线发送，包含当前状态和当前动作的完整信息。
   */
  private emitPipeOperationProgress(phase: 'start' | 'action' | 'end', action?: string): void {
    const statusInfo: string = setting.runStatus.liquidOperate.text;
    const payload: WorkerMeasureStatusEvent = {
      type: 'measureProgress',
      phase: phase,
      statusLabel: statusInfo,
      statusTotalSeconds: 0,
      actionLabel: action ?? '空闲',
      actionTotalSeconds: 0,
      measureType: MeasureType.Sample, // 非测量流程占位，实际以 systemStatusCode 为准
      timestamp: DateTimeUtil.getTimestamp(),
      systemStatusCode: PIPE_OPERATION_STATUS
    };
    const eventData: emitter.EventData = {
      data: payload
    };
    emitter.emit("MeasureStatus", eventData);
    hilog.info(
      100,
      'LiquidOperateFlow',
      'emit progress phase=%{public}s status=%{public}s action=%{public}s actionTime=%{public}d',
      phase,
      statusInfo,
      action ?? '空闲',
      0
    );
  }
}
