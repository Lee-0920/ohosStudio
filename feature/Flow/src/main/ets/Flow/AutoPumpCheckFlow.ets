import { hilog } from "@kit.PerformanceAnalysisKit";
import { Flow } from './Flow';
import { BaseController } from 'controllerplugin';
import { PT65DriveController } from "pt65drivecontrollerplugin";
import { DateTimeUtil } from 'base';
import { liquidTypes , LiquidType} from '../Setting/LiquidType';
import { Operator, WasteType } from '../Flow/Operator';
import { setting } from '../Setting/Setting';
import { config } from '../Config/Config';
import { ThermostatMode, MeterMode, RollDirection } from 'communication'; //导入模块
import { emitter } from '@kit.BasicServicesKit';
import { ActionItem } from '../Setting/RunAction';
import { WorkerMeasureStatusEvent } from './Measurer';
import { MeasureType } from './MeasureFlow';

/** Modbus 系统状态码：定量泵校准 */
const QUANT_PUMP_CAL_STATUS = 11;

export enum AutoPumpCheckType {
  AutoPumpCheck = 0,
}

export class AutoPumpCheckFlow extends Flow {
  private SPEED: number = 0.2;

  constructor(name: string) {
    super(name);
  }

  GetRuntime(): number {
    return 0;
  }

  OnStart(): void {
    hilog.info(122, 'AutoPumpCheckFlow', 'OnStart');

    // 初始化下位机
    const controller = new BaseController();
    const deviceStatus = controller.GetIDeviceStatus();
    if (deviceStatus) {
      // deviceStatus.Initialize(); // 需根据实际接口实现
    }

    // 检测消解室是否为安全温度
    // op.CheckDigestSafety()

    // 设置运行状态
    // let runStatus = Helper.Status.SetStatus(setting.runStatus.autoPumpCheck);
    // StatusManager.Instance().SetStatus(runStatus);
  }

  OnProcess(): void {
    hilog.info(122, 'AutoPumpCheckFlow', 'OnProcess Start');

    this.isUserStop = false;
    this.isFinish = false;
    let dateTime = DateTimeUtil.getTimestamp(); //Date.now();

    this.emitAutoPumpCheckProgress('start', setting.runAction.pumpCheck.drainMeterPipe);

    try {
      const source = liquidTypes.blank;  // 需要根据实际定义
      const op = Operator.getInstance();

      // 获取泵系数并设置速度
      const factor = op.IOpticalMeter.getPumpFactor();
      op.IOpticalMeter.setMeteSpeed(setting.liquid.meterSpeed * factor);
      hilog.info(122, 'AutoPumpCheckFlow', "Set Meter Speed " + (setting.liquid.meterSpeed * factor));

      // 排走定量管液体
      this.emitAutoPumpCheckProgress('action', setting.runAction.pumpCheck.drainMeterPipe);
      op.DrainToWaste(setting.liquid.meterPipeVolume);
      if (this.IsCancelled()) {
        throw new Error("UserStopException");
      }

      // 精确定量最小定量点的液体
      this.emitAutoPumpCheckProgress('action', setting.runAction.pumpCheck.meterToMinMeterPoint);
      this.MeterToMinMeterPoint(source);
      if (this.IsCancelled()) {
        throw new Error("UserStopException");
      }

      // 设置速度
      op.IOpticalMeter.setMeteSpeed(30 * factor);
      hilog.info(122, 'AutoPumpCheckFlow', "Set Meter Speed " + (30 * factor));

      // 直接定量最大定量点的液体
      this.emitAutoPumpCheckProgress('action', setting.runAction.pumpCheck.meterToMaxMeterPoint);
      this.MeterToMaxMeterPoint(source);
      if (this.IsCancelled()) {
        throw new Error("UserStopException");
      }

      op.IOpticalMeter.setMeteSpeed(setting.liquid.meterSpeed * factor);
      hilog.info(122, 'AutoPumpCheckFlow', "Set Meter Speed " + (setting.liquid.meterSpeed * factor));

      // 计算新的泵系数
      const meterPoinNum = config.hardware.meterPoint.num;
      const step = op.IPeristalticPump.getPumpFactor(0) / factor;
      const setFactor = (config.hardware.meterPoint.point[1].realVolume -
                         config.hardware.meterPoint.point[0].setVolume) / step;

      this.emitAutoPumpCheckProgress('action', setting.runAction.pumpCheck.drainMeterPipe);
      op.DrainToWaste(setting.liquid.meterPipeVolume);
      if (this.IsCancelled()) {
        throw new Error("UserStopException");
      }

      // hilog.info(122, 'AutoPumpCheckFlow', "Set Meter Speed " , setFactor);
      // op.IOpticalMeter.setPumpFactor(setFactor);
      // this.result = setFactor.toFixed(8);

      // 保存配置到数据库 TODO
      hilog.info(122, 'AutoPumpCheckFlow', "### ");

      this.isFinish = true;
    } catch (err) {
      hilog.info(122, 'AutoPumpCheckFlow', "Catch Err ");
      if (err instanceof Error) {
        // 检查异常类型
        if (err.message.includes("PumpStoppedException") ||
            err.message.includes("MeterStoppedException") ||
            err.message.includes("UserStopException")) {
          this.isUserStop = true;
        }
        throw err;
      }
    } finally {
      // 无论正常结束、用户停止还是异常，都发送 end 事件，让底部进度条和 Modbus 回到空闲
      this.emitAutoPumpCheckProgress('end');
    }

    hilog.info(122, 'AutoPumpCheckFlow', 'OnProcess End, duration: %{public}dms', DateTimeUtil.getTimestamp());
  }

  /**
   * 向主线程发送定量泵自动校准进度事件。
   */
  private emitAutoPumpCheckProgress(phase: 'start' | 'action' | 'end', action?: ActionItem): void {
    const statusInfo = setting.runStatus.autoPumpCheck;
    const payload: WorkerMeasureStatusEvent = {
      type: 'measureProgress',
      phase: phase,
      statusLabel: statusInfo.text,
      statusTotalSeconds: statusInfo.GetTime?.() ?? 0,
      actionLabel: action?.text ?? '空闲',
      actionTotalSeconds: action?.GetTime?.() ?? 0,
      measureType: MeasureType.Sample, // 非测量流程占位，实际以 systemStatusCode 为准
      timestamp: DateTimeUtil.getTimestamp(),
      systemStatusCode: QUANT_PUMP_CAL_STATUS
    };
    const eventData: emitter.EventData = {
      data: payload
    };
    emitter.emit("MeasureStatus", eventData);
    hilog.info(
      100,
      'AutoPumpCheckFlow',
      'emit progress phase=%{public}s status=%{public}s action=%{public}s actionTime=%{public}d',
      phase,
      statusInfo.text,
      action?.text ?? '空闲',
      action?.GetTime?.() ?? 0
    );
  }

  OnStop(): void {
    hilog.info(122, 'AutoPumpCheckFlow', 'OnStop');

    // 初始化下位机 TODO

    // 保存试剂余量表
    // ReagentRemainManager.SaveRemainStatus();

    if (!this.isFinish) {
      if (this.isUserStop) {
        this.result = "用户终止";
        hilog.info(122, 'AutoPumpCheckFlow', '用户终止');
      } else {
        this.result = "故障终止";
        hilog.warn(122, 'AutoPumpCheckFlow', '故障终止');
      }
    } else {
      this.result = "定量泵自动校准结束";
      hilog.info(122, 'AutoPumpCheckFlow', '定量泵自动校准结束');
      
      // 更新Widget
      // UpdateWidgetManager.Instance().Update(UpdateEvent.AutoPumpCheck, "AutoPumpCheckFlow");
    }
  }

  private MeterToMinMeterPoint(source: LiquidType): void {
    const minMeterPointVolume = config.hardware.meterPoint.point[0].setVolume;
    const meterPoinNum = config.hardware.meterPoint.num;
    const maxMeterPointVolume = config.hardware.meterPoint.point[1].setVolume;

    // 重试次数配置
    const meterFailedReTry = setting.liquid.meterFailedReTry;
    const meterOverflowReTry = setting.liquid.meterOverflowReTry;
    const meterUnfinishedReTry = setting.liquid.meterUnfinishedReTry;
    const meterAirBubbleReTry = setting.liquid.meterAirBubbleReTry;
    const meterTimeoutReTry = setting.liquid.meterTimeoutReTry;

    let failedCnt = 0;
    let overflowCnt = 0;
    let unfinishedCnt = 0;
    let airBubbleCnt = 0;
    let timeoutCnt = 0;

    // 分析废液类型
    let wasteType = WasteType.WasteReagent;
    if (source == liquidTypes.blank) {
      wasteType = WasteType.WasteWater;
    }
    const op = Operator.getInstance();

    const factor = op.IPeristalticPump.getPumpFactor(0);
    const drainSpeed = setting.liquid.prefabricateDrainSpeed * factor;

    op.SetMeterOverValue(MeterMode.Accurate, setting.liquid.accurateMeterOverValue);

    // while (true)
    {
      // try
      {
        op.Meter(MeterMode.Accurate, source, minMeterPointVolume, RollDirection.Suck);
        failedCnt = 0;
        overflowCnt = 0;
        unfinishedCnt = 0;
        airBubbleCnt = 0;
        timeoutCnt = 0;
        // break;
      }
      // catch (err) {
      //   // 异常处理逻辑
      //   if (err instanceof ExpectEventTimeoutException) {
      //     timeoutCnt++;
      //     hilog.warn(122, 'AutoPumpCheckFlow', '%{public}s', err.message);
      //     if (timeoutCnt >= meterTimeoutReTry) {
      //       // op.DrainToWaste(minMeterPointVolume, wasteType);
      //       throw new Error("MeterExpectTimeoutException");
      //     }
      //   } else if (err instanceof MeterFailedException) {
      //     failedCnt++;
      //     hilog.warn(122, 'AutoPumpCheckFlow', '%{public}s', err.message);
      //     if (failedCnt >= meterFailedReTry) {
      //       // op.DrainToWaste(minMeterPointVolume, wasteType);
      //       throw err;
      //     }
      //   } else if (err instanceof MeterOverflowException) {
      //     overflowCnt++;
      //     hilog.warn(122, 'AutoPumpCheckFlow', '%{public}s', err.message);
      //     if (overflowCnt >= meterOverflowReTry) {
      //       // op.DrainToWaste(minMeterPointVolume, wasteType);
      //       throw err;
      //     }
      //   } else if (err instanceof MeterUnfinishedException) {
      //     unfinishedCnt++;
      //     hilog.warn(122, 'AutoPumpCheckFlow', '%{public}s', err.message);
      //     if (unfinishedCnt >= meterUnfinishedReTry) {
      //       // op.DrainToWaste(minMeterPointVolume, wasteType);
      //       throw err;
      //     }
      //   } else if (err instanceof MeterAirBubbleException) {
      //     airBubbleCnt++;
      //     hilog.warn(122, 'AutoPumpCheckFlow', '%{public}s', err.message);
      //     if (airBubbleCnt >= meterAirBubbleReTry) {
      //       // op.DrainToWaste(minMeterPointVolume, wasteType);
      //       throw err;
      //     }
      //   } else {
      //     throw err;
      //   }
      // }
    }
  }

  private MeterToMaxMeterPoint(source: LiquidType): void {
    const meterPoinNum = config.hardware.meterPoint.num;
    const maxMeterPointVolume = config.hardware.meterPoint.point[meterPoinNum - 1].setVolume;

    // 分析废液类型
    let wasteType = WasteType.WasteReagent;
    if (source == liquidTypes.blank) {
      wasteType = WasteType.WasteWater;
    }
    const op = Operator.getInstance();

    op.SetMeterOverValue(MeterMode.Direct, 0);

    // try
    {
      op.Meter(MeterMode.Direct, source, maxMeterPointVolume, RollDirection.Suck);
    }
    // catch (err) {
    //   // 异常处理
    //   // op.DrainToWaste(maxMeterPointVolume, wasteType);
    //   throw err;
    // }
  }
}
