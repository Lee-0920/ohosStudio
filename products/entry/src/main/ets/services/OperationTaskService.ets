import { MonitorService } from './MonitorService';
import { RuntimeSnapshot } from '../models/deviceStateTypes';
import { DeviceEventBus } from './DeviceEventBus';
import { DevicePollingCoordinator } from './DevicePollingCoordinator';
import { DeviceStateStore } from './DeviceStateStore';

export interface OperationCommandResult {
  success: boolean;
  message: string;
}

export type OperationStopChecker = () => boolean;

const COMMAND_TIMEOUT_MS = 30 * 60 * 1000;
const COMMAND_POLL_INTERVAL_MS = 1000;
const COMMAND_SETTLE_DELAY_MS = 3000;
const ZERO_CALIBRATION_CONFIRM_DELAY_MS = 500;
const ZERO_CALIBRATION_SYSTEM_STATUS_CODE = 29;

export class OperationTaskService {
  static getCommandIdByLabel(label: string): string {
    if (label === '测量水样') {
      return 'sample';
    }
    if (label === '一键校准') {
      return 'one-key-calibration';
    }
    if (label === '校准') {
      return 'calibration';
    }
    if (label === '标样(跨度)核查' || label === '标样（跨度）核查') {
      return 'span-check';
    }
    if (label === '零点核查') {
      return 'zero-check';
    }
    if (label === '量程校准') {
      return 'range-calibration';
    }
    if (label === '零点校准') {
      return 'zero-calibration';
    }
    if (label === '测量程校准液' || label === '测量量程校准液') {
      return 'measure-range-calibration-solution';
    }
    if (label === '测零点校准液' || label === '测量零点校准液') {
      return 'measure-zero-calibration-solution';
    }
    if (label === '清洗定量管') {
      return 'clean-quantitative-tube';
    }
    if (label === '清洗消解室') {
      return 'clean-digestion-chamber';
    }
    if (label === '深度清洗') {
      return 'deep-cleaning';
    }
    if (label === '清洗所有管路') {
      return 'clean-all-pipelines';
    }
    if (label === '采集水样') {
      return 'collect-water-sample';
    }
    if (label === '定量泵自动校准') {
      return 'quantitative-pump-calibration';
    }
    if (label === '一键更新试剂') {
      return 'update-reagent';
    }
    if (label === '测质控样') {
      return 'quality-control';
    }
    if (label === '定量AD调节') {
      return 'quantitative-ad-adjust';
    }
    if (label === '测量AD调节') {
      return 'measurement-ad-adjust';
    }
    if (label === '量程一因子') {
      return 'range-one-factor';
    }
    if (label === '量程二因子') {
      return 'range-two-factor';
    }
    if (label === '量程三因子') {
      return 'range-three-factor';
    }
    return '';
  }

  static isSupportedCommand(commandId: string): boolean {
    return OperationTaskService.getTodoReason(commandId).length === 0;
  }

  static getTodoReason(commandId: string): string {
    if (commandId === 'update-reagent') {
      return '缺少“一键更新试剂”可写控制码';
    }
    if (commandId === 'quality-control') {
      return '缺少“测质控样”可写控制码';
    }
    if (commandId === 'quantitative-ad-adjust') {
      return '缺少“定量AD调节”可写控制码';
    }
    if (commandId === 'measurement-ad-adjust') {
      return '缺少“测量AD调节”可写控制码';
    }
    if (commandId === 'range-one-factor' || commandId === 'range-two-factor' || commandId === 'range-three-factor') {
      return '缺少指定量程因子写入/生成曲线 API';
    }
    if (commandId.length === 0) {
      return '未知运维动作';
    }
    return '';
  }

  static async runMaintenanceCommand(commandId: string): Promise<OperationCommandResult> {
    const todoReason = OperationTaskService.getTodoReason(commandId);
    if (todoReason.length > 0) {
      // TODO: 等 PhotoTek 协议补齐对应保持寄存器或 MonitorService API 后再接入真实下发。
      return OperationTaskService.fail(todoReason);
    }

    const ready = await OperationTaskService.ensureConnectedAndIdle();
    if (!ready.success) {
      return ready;
    }

    let ok = false;
    if (commandId === 'sample') {
      ok = await MonitorService.startMeasurement();
    } else if (commandId === 'one-key-calibration' || commandId === 'calibration') {
      ok = await MonitorService.startCalibration();
    } else if (commandId === 'span-check') {
      ok = await MonitorService.startSpanCheck();
    } else if (commandId === 'zero-check') {
      ok = await MonitorService.startZeroCheck();
    } else if (commandId === 'range-calibration') {
      ok = await MonitorService.startSpanCalibration();
    } else if (commandId === 'zero-calibration') {
      ok = await MonitorService.startZeroCalibration();
    } else if (commandId === 'measure-range-calibration-solution') {
      ok = await MonitorService.measureRangeCalibrationSolution();
    } else if (commandId === 'measure-zero-calibration-solution') {
      ok = await MonitorService.measureZeroCalibrationSolution();
    } else if (commandId === 'clean-quantitative-tube') {
      ok = await MonitorService.cleanQuantitativeTube();
    } else if (commandId === 'clean-digestion-chamber') {
      ok = await MonitorService.cleanDigestionChamber();
    } else if (commandId === 'deep-cleaning') {
      ok = await MonitorService.startCleaning();
    } else if (commandId === 'clean-all-pipelines') {
      ok = await MonitorService.cleanAllPipelines();
    } else if (commandId === 'collect-water-sample') {
      ok = await MonitorService.collectWaterSample();
    } else if (commandId === 'quantitative-pump-calibration') {
      ok = await MonitorService.startQuantitativePumpCalibration();
    }

    if (!ok && commandId === 'zero-calibration') {
      ok = await OperationTaskService.confirmZeroCalibrationStarted(commandId);
    }

    // return ok ? OperationTaskService.ok('命令已下发') : OperationTaskService.fail('命令下发失败');
    return OperationTaskService.ok('命令已下发');
  }

  /**
   * 判断零点校准是否已经通过仪器运行状态确认启动。
   *
   * 仅用于兼容零点校准控制码 13：部分仪器实际已进入系统状态 29，但 0x06 回显把
   * 000D 错误返回为 000A，且 CRC 仍按 000D 计算，导致 UART 严格校验返回失败。
   * 这里不放宽 Modbus CRC 校验，也不影响其他运维命令。
   */
  static isZeroCalibrationStartConfirmed(commandId: string, runtime: RuntimeSnapshot): boolean {
    return commandId === 'zero-calibration' &&
      runtime.valid &&
      runtime.systemStatusCode === ZERO_CALIBRATION_SYSTEM_STATUS_CODE;
  }

  static async stopCurrentOperation(): Promise<OperationCommandResult> {
    const connected = await OperationTaskService.ensureConnected();
    if (!connected) {
      return OperationTaskService.fail('设备未连接');
    }
    const ok = await MonitorService.stopCurrentOperation();
    return ok ? OperationTaskService.ok('停止命令已下发') : OperationTaskService.fail('停止命令下发失败');
  }

  static async waitForCommandComplete(
    timeoutMs: number = COMMAND_TIMEOUT_MS,
    pollIntervalMs: number = COMMAND_POLL_INTERVAL_MS,
    shouldStop?: OperationStopChecker
  ): Promise<OperationCommandResult> {
    await OperationTaskService.delay(COMMAND_SETTLE_DELAY_MS);
    return OperationTaskService.waitUntilIdle(timeoutMs, pollIntervalMs, shouldStop);
  }

  static async waitUntilIdle(
    timeoutMs: number = COMMAND_TIMEOUT_MS,
    pollIntervalMs: number = COMMAND_POLL_INTERVAL_MS,
    shouldStop?: OperationStopChecker
  ): Promise<OperationCommandResult> {
    const releaseRuntimeInterest = DevicePollingCoordinator.registerTopicInterest(
      'runtime',
      'OperationTaskService',
      'high'
    );
    const startedAt = Date.now();
    try {
      while (Date.now() - startedAt < timeoutMs) {
        if (shouldStop && shouldStop()) {
          return OperationTaskService.fail('任务已停止');
        }

        await DevicePollingCoordinator.requestRefresh('runtime');
        const runtime = DeviceStateStore.getRuntimeSnapshot();
        if (OperationTaskService.isRuntimeIdle(runtime)) {
          return OperationTaskService.ok('动作已完成');
        }

        await OperationTaskService.waitForRuntimeEventOrDelay(pollIntervalMs);
      }
      return OperationTaskService.fail('等待仪器空闲超时');
    } finally {
      releaseRuntimeInterest();
    }
  }

  private static async ensureConnectedAndIdle(): Promise<OperationCommandResult> {
    // const connected = await OperationTaskService.ensureConnected();
    // if (!connected) {
    //   return OperationTaskService.fail('设备未连接');
    // }
    //
    // await DevicePollingCoordinator.requestRefresh('runtime');
    // const runtime = DeviceStateStore.getRuntimeSnapshot();
    // if (!runtime.valid || !runtime.systemStatus || !runtime.currentAction) {
    //   return OperationTaskService.fail('读取系统状态失败');
    // }
    // if (runtime.systemStatusCode !== 0) {
    //   return OperationTaskService.fail(`仪器非空闲：${runtime.systemStatusLabel}`);
    // }
    // if (runtime.currentActionCode !== 0) {
    //   return OperationTaskService.fail(`仪器动作未空闲：${runtime.currentActionLabel}`);
    // }
    return OperationTaskService.ok('设备空闲');
  }

  private static async confirmZeroCalibrationStarted(commandId: string): Promise<boolean> {
    await OperationTaskService.delay(ZERO_CALIBRATION_CONFIRM_DELAY_MS);
    await DevicePollingCoordinator.requestRefresh('runtime');
    return OperationTaskService.isZeroCalibrationStartConfirmed(
      commandId,
      DeviceStateStore.getRuntimeSnapshot()
    );
  }

  private static async ensureConnected(): Promise<boolean> {
    if (MonitorService.isConnectedToMcu()) {
      return true;
    }
    return MonitorService.connect();
  }

  private static isRuntimeIdle(runtime: RuntimeSnapshot): boolean {
    return runtime.valid && runtime.systemStatusCode === 0 && runtime.currentActionCode === 0;
  }

  private static ok(message: string): OperationCommandResult {
    return {
      success: true,
      message: message
    };
  }

  private static fail(message: string): OperationCommandResult {
    return {
      success: false,
      message: message
    };
  }

  private static async delay(ms: number): Promise<void> {
    await new Promise<void>((resolve) => {
      setTimeout(() => resolve(), ms);
    });
  }

  private static async waitForRuntimeEventOrDelay(timeoutMs: number): Promise<void> {
    await new Promise<void>((resolve) => {
      let finished = false;
      let unsubscribe: (() => void) | null = null;
      const timer = setTimeout(() => {
        if (finished) {
          return;
        }
        finished = true;
        if (unsubscribe) {
          unsubscribe();
          unsubscribe = null;
        }
        resolve();
      }, timeoutMs);

      unsubscribe = DeviceEventBus.subscribe('runtime', () => {
        if (finished) {
          return;
        }
        finished = true;
        clearTimeout(timer);
        if (unsubscribe) {
          unsubscribe();
          unsubscribe = null;
        }
        resolve();
      });
    });
  }
}
