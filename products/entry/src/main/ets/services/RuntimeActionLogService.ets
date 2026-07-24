import {
  LOG_RESULT_INFO,
  OPERATION_LOG_TYPE_RUNTIME
} from '../models/dataRecordTypes';
import {
  DeviceEvent,
  RuntimeSnapshot
} from '../models/deviceStateTypes';
import { DeviceEventBus } from './DeviceEventBus';
import { DevicePollingCoordinator } from './DevicePollingCoordinator';
import { DeviceStateStore } from './DeviceStateStore';
import { PhotoTekCodeDescription } from './protocol/PhotoTekTypes';
import { OperationLogService } from './OperationLogService';
import { MeasurementRecordService } from './MeasurementRecordService';
import { CalibrationCurveService } from './CalibrationCurveService';

const DEFAULT_POLL_INTERVAL_MS = 1000;
const SOURCE_RUNTIME_ACTION = 'runtime_action_service';
const RUNTIME_ACTION_OWNER = 'RuntimeActionLogService';

export class RuntimeActionLogService {
  private static unsubscribeRuntime: (() => void) | null = null;
  private static releaseRuntimeInterest: (() => void) | null = null;
  private static isCapturing: boolean = false;
  private static lastActionKey: string = '';
  private static lastActionCode: number | null = null;
  private static hasSeenCalibrationAction: boolean = false;
  private static hasRecordedRuntimeAction: boolean = false;

  static startPolling(intervalMs: number = DEFAULT_POLL_INTERVAL_MS): void {
    if (RuntimeActionLogService.unsubscribeRuntime) {
      return;
    }
    const ignoredInterval = intervalMs;
    if (ignoredInterval <= 0) {
      return;
    }

    RuntimeActionLogService.unsubscribeRuntime = DeviceEventBus.subscribe('runtime', (event: DeviceEvent) => {
      const snapshot = event.current as RuntimeSnapshot;
      void RuntimeActionLogService.captureRuntimeSnapshot(snapshot);
    });
    RuntimeActionLogService.releaseRuntimeInterest = DevicePollingCoordinator.registerTopicInterest(
      'runtime',
      RUNTIME_ACTION_OWNER,
      'high'
    );
    void RuntimeActionLogService.captureCurrentAction();
  }

  static stopPolling(): void {
    if (RuntimeActionLogService.unsubscribeRuntime) {
      RuntimeActionLogService.unsubscribeRuntime();
      RuntimeActionLogService.unsubscribeRuntime = null;
    }
    if (RuntimeActionLogService.releaseRuntimeInterest) {
      RuntimeActionLogService.releaseRuntimeInterest();
      RuntimeActionLogService.releaseRuntimeInterest = null;
    }
    RuntimeActionLogService.isCapturing = false;
    RuntimeActionLogService.resetActionState();
  }

  static async captureCurrentAction(): Promise<void> {
    RuntimeActionLogService.ensureSubscribed();
    await DevicePollingCoordinator.requestRefresh('runtime');
    await RuntimeActionLogService.captureRuntimeSnapshot(DeviceStateStore.getRuntimeSnapshot());
  }

  private static ensureSubscribed(): void {
    if (RuntimeActionLogService.unsubscribeRuntime) {
      return;
    }
    RuntimeActionLogService.startPolling();
  }

  private static async captureRuntimeSnapshot(snapshot: RuntimeSnapshot): Promise<void> {
    if (RuntimeActionLogService.isCapturing) {
      return;
    }
    if (!snapshot.valid || !snapshot.currentAction) {
      RuntimeActionLogService.resetActionState();
      return;
    }

    RuntimeActionLogService.isCapturing = true;
    try {
      await RuntimeActionLogService.recordChangedAction(snapshot.currentAction);
    } finally {
      RuntimeActionLogService.isCapturing = false;
    }
  }

  private static async recordChangedAction(action: PhotoTekCodeDescription): Promise<void> {
    const key = RuntimeActionLogService.actionKey(action);
    if (key === RuntimeActionLogService.lastActionKey) {
      return;
    }
    const previousCode = RuntimeActionLogService.lastActionCode;
    const shouldCaptureCalibrationCurve = RuntimeActionLogService.hasSeenCalibrationAction;
    const code = RuntimeActionLogService.actionCodeNumber(action);
    if (RuntimeActionLogService.isCalibrationAction(action)) {
      RuntimeActionLogService.hasSeenCalibrationAction = true;
    }
    RuntimeActionLogService.lastActionKey = key;
    RuntimeActionLogService.lastActionCode = code;

    if (code === 0 && previousCode !== null && previousCode !== 0) {
      await MeasurementRecordService.captureLatestMeasurementRecord();
      if (shouldCaptureCalibrationCurve) {
        await CalibrationCurveService.captureCurrentCalibrationCurve();
        RuntimeActionLogService.hasSeenCalibrationAction = false;
      }
    }

    if (code === 0 && previousCode === null) {
      RuntimeActionLogService.hasSeenCalibrationAction = false;
    }

    if (code === 0 && !RuntimeActionLogService.hasRecordedRuntimeAction) {
      return;
    }

    RuntimeActionLogService.hasRecordedRuntimeAction = true;
    await OperationLogService.record({
      logType: OPERATION_LOG_TYPE_RUNTIME,
      action: '当前动作变化',
      content: `当前动作：${action.label}`,
      source: SOURCE_RUNTIME_ACTION,
      detail: `actionCode=${action.code}`
    }, LOG_RESULT_INFO);
  }

  private static actionKey(action: PhotoTekCodeDescription): string {
    return `${action.code}-${action.label}`;
  }

  private static actionCodeNumber(action: PhotoTekCodeDescription): number | null {
    if (typeof action.code === 'number') {
      return action.code;
    }
    const parsed = Number(action.code);
    return Number.isNaN(parsed) ? null : parsed;
  }

  private static isCalibrationAction(action: PhotoTekCodeDescription): boolean {
    const code = RuntimeActionLogService.actionCodeNumber(action);
    return code === 20 || action.label === '校准';
  }

  private static resetActionState(): void {
    RuntimeActionLogService.lastActionKey = '';
    RuntimeActionLogService.lastActionCode = null;
    RuntimeActionLogService.hasSeenCalibrationAction = false;
    RuntimeActionLogService.hasRecordedRuntimeAction = false;
  }
}
