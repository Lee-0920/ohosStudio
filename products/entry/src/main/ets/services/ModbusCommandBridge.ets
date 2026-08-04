import { emitter, Callback } from '@kit.BasicServicesKit';
import { MessageEvents } from '@kit.ArkTS';
import { MODBUS_CONTROL_COMMAND_EVENT, ModbusControlCommandEventData } from 'modbus';
import {
  WorkerManager,
  MaintenceType,
  MeasureType,
  CalibrateType,
  CleanType,
  MaintainOperationParams
} from 'flow';
import { OperationTaskService } from './OperationTaskService';
import { hilog } from '@kit.PerformanceAnalysisKit';

/**
 * Worker 命令负载，显式声明以避免 arkts-no-obj-literals-as-types。
 */
interface WorkerCommandPayload {
  type: string;
  data: MaintainOperationParams;
}

const DOMAIN = 0x0000;
const TAG = 'ModbusCommandBridge';

/**
 * 桥接 feature/modbus 与 products/entry 的 OperationTaskService。
 *
 * Modbus 服务端在收到地址 272（测量控制）/273（采水控制）的写请求后，会通过 emitter
 * 发送 MODBUS_CONTROL_COMMAND_EVENT 事件；本类订阅该事件并：
 * 1. 调用 OperationTaskService 执行对应运维命令（写 MCU 寄存器、等待完成等）；
 * 2. 同步向 WorkerManager 发送消息，驱动 Worker 线程执行本地流程，
 *    使底部状态栏的两个进度条能够显示当前状态、当前动作和执行时间。
 */
export class ModbusCommandBridge {
  private static instance: ModbusCommandBridge | null = null;
  private emitterCallback: Callback<emitter.EventData> | null = null;

  static getInstance(): ModbusCommandBridge {
    if (!ModbusCommandBridge.instance) {
      ModbusCommandBridge.instance = new ModbusCommandBridge();
    }
    return ModbusCommandBridge.instance;
  }

  /**
   * 开始订阅 Modbus 控制指令事件。应在 ModbusServer 启动后调用。
   */
  start(): void {
    if (this.emitterCallback) {
      hilog.warn(DOMAIN, TAG, 'already started');
      return;
    }

    const callback: Callback<emitter.EventData> = (eventData: emitter.EventData) => {
      const data = eventData.data as ModbusControlCommandEventData;
      if (!data || !data.commandId || data.commandId.length === 0) {
        return;
      }
      hilog.info(
        DOMAIN,
        TAG,
        'recv modbus command address=%{public}d value=%{public}d commandId=%{public}s',
        data.sourceAddress,
        data.value,
        data.commandId
      );

      // 先向 WorkerManager 发送本地执行消息，驱动底部进度条
      this.dispatchWorkerCommand(data.commandId);

      // 再调用 OperationTaskService 执行 MCU 侧命令
      if (data.commandId === 'stop') {
        void OperationTaskService.stopCurrentOperation();
      } else {
        void OperationTaskService.runMaintenanceCommand(data.commandId);
      }
    };

    this.emitterCallback = callback;
    emitter.on(MODBUS_CONTROL_COMMAND_EVENT, callback);
    hilog.info(DOMAIN, TAG, 'started');
  }

  /**
   * 根据 commandId 向 WorkerManager 发送对应类型的本地执行消息。
   */
  private dispatchWorkerCommand(commandId: string): void {
    const payload = this.buildWorkerPayload(commandId);
    if (!payload) {
      return;
    }

    hilog.info(DOMAIN, TAG, 'dispatch worker command type=%{public}s', payload.type);
    const message: MessageEvents = {
      type: payload.type,
      data: payload.data,
      timeStamp: Date.now()
    } as MessageEvents;
    WorkerManager.getInstance().postMessage(message);
  }

  /**
   * 构造 Worker 消息负载。返回 null 表示该命令不需要 Worker 线程执行。
   */
  private buildWorkerPayload(commandId: string): WorkerCommandPayload | null {
    switch (commandId) {
      case 'sample':
        return this.makePayload('startMeasure', MaintenceType.AutoMeasure, MeasureType.Sample);
      case 'calibration':
      case 'one-key-calibration':
        return this.makePayload('startCalibrate', MaintenceType.AutoCalibrate, CalibrateType.calibrate);
      case 'measure-range-calibration-solution':
        return this.makePayload('startMeasure', MaintenceType.AutoMeasure, MeasureType.RangeCheck);
      case 'measure-zero-calibration-solution':
        return this.makePayload('startMeasure', MaintenceType.AutoMeasure, MeasureType.ZeroCheck);
      case 'clean-quantitative-tube':
        return this.makePayload('startClean', MaintenceType.AutoClean, CleanType.cleanMeterPipe);
      case 'clean-digestion-chamber':
        return this.makePayload('startClean', MaintenceType.AutoClean, CleanType.cleanDigestionRoom);
      case 'deep-cleaning':
        return this.makePayload('startClean', MaintenceType.AutoClean, CleanType.cleanDeeply);
      case 'clean-all-pipelines':
        return this.makePayload('startClean', MaintenceType.AutoClean, CleanType.cleanAll);
      case 'collect-water-sample':
        return this.makePayload('startCollectSample', MaintenceType.AutoCollectSample, 0);
      case 'quantitative-pump-calibration':
        return this.makePayload('startPumpCalibrate', MaintenceType.AutoPumpCalibrate, 0);
      case 'span-check':
        return this.makePayload('startMeasure', MaintenceType.AutoMeasure, MeasureType.RangeCheck);
      case 'zero-check':
        return this.makePayload('startMeasure', MaintenceType.AutoMeasure, MeasureType.ZeroCheck);
      case 'zero-calibration':
        return this.makePayload('startCalibrate', MaintenceType.AutoCalibrate, CalibrateType.onlyCalibrateBlank);
      case 'range-calibration':
        return this.makePayload('startCalibrate', MaintenceType.AutoCalibrate, CalibrateType.onlyCalibrateStandard);
      case 'stop':
        return this.makePayload('stop', MaintenceType.AutoMeasure, 0);
      default:
        return null;
    }
  }

  /**
   * 构造 WorkerCommandPayload 的工厂函数，避免对象字面量展开（arkts-no-spread）。
   */
  private makePayload(type: string, maintenceTypes: MaintenceType, params: number): WorkerCommandPayload {
    const data: MaintainOperationParams = {
      maintenceTypes: maintenceTypes,
      params: params,
      runTimes: 1
    };
    return {
      type: type,
      data: data
    };
  }

  /**
   * 停止订阅事件。
   */
  stop(): void {
    if (this.emitterCallback) {
      emitter.off(MODBUS_CONTROL_COMMAND_EVENT, this.emitterCallback);
      this.emitterCallback = null;
      hilog.info(DOMAIN, TAG, 'stopped');
    }
  }
}
