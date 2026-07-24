import { common } from '@kit.AbilityKit';
import {
  AlarmSnapshot,
  DeviceEvent
} from '../models/deviceStateTypes';
import { DeviceEventBus } from './DeviceEventBus';
import { DevicePollingCoordinator } from './DevicePollingCoordinator';
import { DeviceStateStore } from './DeviceStateStore';
import {
  ALARM_TYPE_CALIBRATION_EXCEPTION,
  ALARM_TYPE_COMMUNICATION_EXCEPTION,
  ALARM_TYPE_INSTRUMENT_FAULT,
  ALARM_TYPE_MAINTENANCE_TIP,
  ALARM_TYPE_MEASUREMENT_EXCEPTION,
  ALARM_TYPE_REAGENT_EXCEPTION,
  ALARM_TYPE_SYSTEM_EXCEPTION,
  ALARM_TYPE_UPGRADE_EXCEPTION,
  LOG_RESULT_INFO,
  OPERATION_LOG_TYPE_INSTRUMENT_FAULT,
  AlarmRecord,
  AlarmRecordInput,
  AlarmRecordQuery,
  DataPageQueryResult
} from '../models/dataRecordTypes';
import { DataRecordDao } from '../dao/DataRecordDao';
import { OperationLogService } from './OperationLogService';

const DEFAULT_POLL_INTERVAL_MS = 3000;
const STATUS_RECORDED = 'recorded';
const SOURCE_DEVICE = 'device';
const ALARM_RECORD_OWNER = 'AlarmRecordService';

export class AlarmRecordService {
  private static unsubscribeAlarm: (() => void) | null = null;
  private static releaseAlarmInterest: (() => void) | null = null;
  private static isCapturing: boolean = false;
  private static currentRuntimeKey: string = '';
  private static currentRuntimeStartedAt: number = 0;

  static init(context: common.Context): Promise<boolean> {
    return DataRecordDao.init(context);
  }

  static queryAlarmRecords(query: AlarmRecordQuery): Promise<DataPageQueryResult<AlarmRecord>> {
    return DataRecordDao.queryAlarmRecords(query);
  }

  static startPolling(intervalMs: number = DEFAULT_POLL_INTERVAL_MS): void {
    if (AlarmRecordService.unsubscribeAlarm) {
      return;
    }
    const ignoredInterval = intervalMs;
    if (ignoredInterval <= 0) {
      return;
    }

    AlarmRecordService.unsubscribeAlarm = DeviceEventBus.subscribe('alarm', (event: DeviceEvent) => {
      const snapshot = event.current as AlarmSnapshot;
      void AlarmRecordService.captureAlarmSnapshot(snapshot);
    });
    AlarmRecordService.releaseAlarmInterest = DevicePollingCoordinator.registerTopicInterest(
      'alarm',
      ALARM_RECORD_OWNER
    );
    void AlarmRecordService.captureCurrentAlarm();
  }

  static stopPolling(): void {
    if (AlarmRecordService.unsubscribeAlarm) {
      AlarmRecordService.unsubscribeAlarm();
      AlarmRecordService.unsubscribeAlarm = null;
    }
    if (AlarmRecordService.releaseAlarmInterest) {
      AlarmRecordService.releaseAlarmInterest();
      AlarmRecordService.releaseAlarmInterest = null;
    }
    AlarmRecordService.isCapturing = false;
  }

  static async captureCurrentAlarm(): Promise<void> {
    AlarmRecordService.ensureSubscribed();
    await DevicePollingCoordinator.requestRefresh('alarm');
    await AlarmRecordService.captureAlarmSnapshot(DeviceStateStore.getAlarmSnapshot());
  }

  private static ensureSubscribed(): void {
    if (AlarmRecordService.unsubscribeAlarm) {
      return;
    }
    AlarmRecordService.startPolling();
  }

  private static async captureAlarmSnapshot(snapshot: AlarmSnapshot): Promise<void> {
    if (AlarmRecordService.isCapturing) {
      return;
    }
    if (!snapshot.valid || !snapshot.active || snapshot.alarmCode === null || snapshot.alarmCode === 0) {
      AlarmRecordService.resetRuntimeAlarm();
      return;
    }

    AlarmRecordService.isCapturing = true;
    try {
      const code = snapshot.alarmCode;
      const capturedAt = snapshot.updatedAt;
      const alarmTimestamp = snapshot.alarmTimestamp;
      const uniqueKey = AlarmRecordService.buildUniqueKey(
        code,
        alarmTimestamp,
        snapshot.alarmTime !== null,
        capturedAt
      );
      if (uniqueKey === AlarmRecordService.currentRuntimeKey) {
        return;
      }
      AlarmRecordService.currentRuntimeKey = uniqueKey;

      const alarmType = AlarmRecordService.classifyAlarmCode(code);
      const label = snapshot.alarm ? snapshot.alarm.label : `未知报警(${code})`;
      const input: AlarmRecordInput = {
        alarmTime: alarmTimestamp,
        alarmCode: code,
        alarmType: alarmType,
        category: alarmType,
        content: label,
        source: SOURCE_DEVICE,
        status: STATUS_RECORDED,
        uniqueKey: uniqueKey
      };
      const inserted = await DataRecordDao.insertAlarmRecord(input);
      if (inserted) {
        await OperationLogService.record({
          logType: OPERATION_LOG_TYPE_INSTRUMENT_FAULT,
          action: '记录告警',
          content: `${alarmType}: ${label}`,
          source: 'alarm_record_service',
          detail: `alarmCode=${code}`
        }, LOG_RESULT_INFO);
      }
    } finally {
      AlarmRecordService.isCapturing = false;
    }
  }

  static classifyAlarmCode(code: number): string {
    if (code === 20 || code === 21 || code === 22 || code === 36 || code === 37) {
      return ALARM_TYPE_COMMUNICATION_EXCEPTION;
    }
    if (code === 23 || code === 24 || code === 25 || code === 38 || code === 39) {
      return ALARM_TYPE_UPGRADE_EXCEPTION;
    }
    if (code === 31 || code === 32 || code === 33 || code === 34 || code === 35 || code === 40 || code === 43) {
      return ALARM_TYPE_MAINTENANCE_TIP;
    }
    if ((code >= 4 && code <= 18) || code === 1 || code === 2) {
      return ALARM_TYPE_REAGENT_EXCEPTION;
    }
    if (code === 28 || code === 30 || code === 42) {
      return ALARM_TYPE_CALIBRATION_EXCEPTION;
    }
    if (code === 3 || code === 29 || code === 41 || code === 46) {
      return ALARM_TYPE_MEASUREMENT_EXCEPTION;
    }
    if (code === 19 || code === 26 || (code >= 80 && code <= 88)) {
      return ALARM_TYPE_SYSTEM_EXCEPTION;
    }
    return ALARM_TYPE_INSTRUMENT_FAULT;
  }

  private static buildUniqueKey(code: number, alarmTimestamp: number, hasDeviceTime: boolean, capturedAt: number): string {
    if (hasDeviceTime) {
      return `${alarmTimestamp}-${code}`;
    }
    if (AlarmRecordService.currentRuntimeStartedAt <= 0) {
      AlarmRecordService.currentRuntimeStartedAt = capturedAt;
    }
    return `${AlarmRecordService.currentRuntimeStartedAt}-${code}`;
  }

  private static resetRuntimeAlarm(): void {
    AlarmRecordService.currentRuntimeKey = '';
    AlarmRecordService.currentRuntimeStartedAt = 0;
  }
}
