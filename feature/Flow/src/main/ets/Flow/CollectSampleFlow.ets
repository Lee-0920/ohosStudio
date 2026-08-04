import { hilog } from "@kit.PerformanceAnalysisKit";
import { Flow } from './Flow';
import { DateTimeUtil } from 'base';
import { emitter } from '@kit.BasicServicesKit';
import { setting } from '../Setting/Setting';
import { config } from '../Config/Config';
import { ActionItem } from '../Setting/RunAction';
import { StatusItem } from '../Setting/RunStatus';
import { WorkerMeasureStatusEvent } from './Measurer';
import { MeasureType } from './MeasureFlow';

/** Modbus 系统状态码：采集水样（采水控制） */
const COLLECT_WATER_STATUS = 8;


/**
 * 清洗类型枚举
 */
export enum CollectSampleType {
  CollectSample = 0,      // 清洗定量管
}

export class CollectSampleFlow extends Flow {
  detectTime: number = DateTimeUtil.getTimestamp();

  constructor(name: string) {
    super(name);
    this.detectTime = DateTimeUtil.getTimestamp();
  }

  GetRuntime(): number {
    // TODO: 根据配置获取运行时间
    return 30; // 默认返回30秒
  }

  OnStart(): void {
    hilog.info(122, 'CollectSampleFlow', 'OnStart');

    // 组合流程需要重新加载时间
    this.detectTime = DateTimeUtil.getTimestamp();

    // 设置运行状态
    // let runStatus = Helper.Status.SetStatus(setting.runStatus.collectSample);
    // StatusManager.Instance().SetStatus(runStatus);
  }

  OnProcess(): void {
    hilog.info(122, 'CollectSampleFlow', 'OnProcess Start');

    this.isUserStop = false;
    this.isFinish = false;

    try {
      // 设置运行动作状态 - 采集
      // let runAction = Helper.Status.SetAction(setting.runAction.collectSample.collect);
      // StatusManager.Instance().SetAction(runAction);
      this.emitCollectSampleProgress('start', setting.runAction.collectSample.collect);

      // 获取水样采集器实例
      // const waterCollector = WaterCollector.Instance();

      // 判断仪器类型
      // if (!config.info.instrument["type"].includes("PT63P")) {
      //   waterCollector.TurnOn();
      // }

      // 继电器指示
      // Helper.Result.RelayOutOperate(setting.mode.relayOut.collectInstruct, true);

      // 采集等待
      if (!this.Wait(config.interconnection.miningWaterTime)) {
        // // 用户停止处理
        // if (!config.info.instrument["type"].includes("PT63P")) {
        //   waterCollector.TurnOff();
        // }
        // Helper.Result.RelayOutOperate(setting.mode.relayOut.collectInstruct, false);
        throw new Error("用户终止");
      }

      // 设置运行动作状态 - 静默
      // runAction = Helper.Status.SetAction(setting.runAction.collectSample.silent);
      // StatusManager.Instance().SetAction(runAction);
      this.emitCollectSampleProgress('action', setting.runAction.collectSample.silent);

      // 关闭采集器
      // if (!config.info.instrument["type"].includes("PT63P")) {
      //   waterCollector.TurnOff();
      // }

      // 继电器指示关闭
      // Helper.Result.RelayOutOperate(setting.mode.relayOut.collectInstruct, false);

      // 静默等待
      if (!this.Wait(config.interconnection.silentTime)) {
        throw new Error("用户终止");
      }

    } catch (err) {
      if (err instanceof Error) {
        if (err.message.includes("用户终止")) {
          this.isUserStop = true;
          this.emitCollectSampleProgress('end');
        }
        throw err;
      }
    }

    this.isFinish = true;
    hilog.info(122, 'CollectSampleFlow', 'OnProcess End');
    this.emitCollectSampleProgress('end');
  }

  OnStop(): void {
    hilog.info(122, 'CollectSampleFlow', 'OnStop');

    if (!this.isFinish) {
      if (this.isUserStop) {
        this.result = "用户终止";
        hilog.info(122, 'CollectSampleFlow', '用户终止');
      } else {
        this.result = "故障终止";
        hilog.warn(122, 'CollectSampleFlow', '故障终止');
      }
    } else {
      this.result = "采集水样结束";
      hilog.info(122, 'CollectSampleFlow', '采集水样结束');
      hilog.info(122, 'CollectSampleFlow', '采集水样时间 = %{public}ds', DateTimeUtil.getTimestamp() - this.detectTime);
    }
  }

  /**
   * 向主线程发送测量进度事件。
   * 事件通过 emitter 进程级事件总线发送，包含当前状态和当前动作的完整信息。
   */
  private emitCollectSampleProgress(phase: 'start' | 'action' | 'end', action?: ActionItem): void {
    const statusInfo: StatusItem = setting.runStatus.collectSample;
    const payload: WorkerMeasureStatusEvent = {
      type: 'measureProgress',
      phase: phase,
      statusLabel: statusInfo.text,
      statusTotalSeconds: statusInfo.GetTime?.() ?? 0,
      actionLabel: action?.text ?? '空闲',
      actionTotalSeconds: action?.GetTime?.() ?? 0,
      measureType: MeasureType.Sample, // 非测量流程占位，实际以 systemStatusCode 为准
      timestamp: DateTimeUtil.getTimestamp(),
      systemStatusCode: COLLECT_WATER_STATUS
    };
    const eventData: emitter.EventData = {
      data: payload
    };
    emitter.emit("MeasureStatus", eventData);
    hilog.info(
      100,
      'CollectSampleFlow',
      'emit progress phase=%{public}s status=%{public}s action=%{public}s actionTime=%{public}d',
      phase,
      statusInfo.text,
      action?.text ?? '空闲',
      action?.GetTime?.() ?? 0
    );
  }
}
