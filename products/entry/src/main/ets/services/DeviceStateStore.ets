import {
  AlarmSnapshot,
  ConnectionSnapshot,
  ConnectionSnapshotInput,
  DeviceEvent,
  DeviceSnapshot,
  MeasurementDisplaySnapshot,
  RuntimeSnapshot,
  SignalSnapshot,
  TemperatureSnapshot
} from '../models/deviceStateTypes';
import {
  PhotoTekCodeDescription,
  PhotoTekMeasurementParameterInfo,
  PhotoTekTemperatureValue,
  PhotoTekTimeValue
} from './protocol/PhotoTekTypes';
import { DeviceEventBus } from './DeviceEventBus';

const SOURCE_DEFAULT = 'device_state_store';
const SOURCE_DISCONNECTED = 'device_disconnected';

export class DeviceStateStore {
  private static connectionSnapshot: ConnectionSnapshot = DeviceStateStore.createDefaultConnectionSnapshot();
  private static runtimeSnapshot: RuntimeSnapshot = DeviceStateStore.createDefaultRuntimeSnapshot();
  private static alarmSnapshot: AlarmSnapshot = DeviceStateStore.createDefaultAlarmSnapshot();
  private static temperatureSnapshot: TemperatureSnapshot = DeviceStateStore.createDefaultTemperatureSnapshot();
  private static signalSnapshot: SignalSnapshot = DeviceStateStore.createDefaultSignalSnapshot();
  private static measurementSnapshot: MeasurementDisplaySnapshot = DeviceStateStore.createDefaultMeasurementSnapshot();

  static getConnectionSnapshot(): ConnectionSnapshot {
    return DeviceStateStore.connectionSnapshot;
  }

  static getRuntimeSnapshot(): RuntimeSnapshot {
    return DeviceStateStore.runtimeSnapshot;
  }

  static getAlarmSnapshot(): AlarmSnapshot {
    return DeviceStateStore.alarmSnapshot;
  }

  static getTemperatureSnapshot(): TemperatureSnapshot {
    return DeviceStateStore.temperatureSnapshot;
  }

  static getSignalSnapshot(): SignalSnapshot {
    return DeviceStateStore.signalSnapshot;
  }

  static getMeasurementDisplaySnapshot(): MeasurementDisplaySnapshot {
    return DeviceStateStore.measurementSnapshot;
  }

  static updateConnection(input: ConnectionSnapshotInput, source: string = SOURCE_DEFAULT): ConnectionSnapshot {
    const now = Date.now();
    const snapshot: ConnectionSnapshot = {
      topic: 'connection',
      updatedAt: now,
      source: source,
      valid: true,
      errorMessage: input.errorMessage,
      state: input.state,
      businessState: input.businessState,
      connected: input.connected,
      mode: input.mode,
      failureCount: input.failureCount,
      lastProbeAt: input.lastProbeAt,
      lastSuccessAt: input.lastSuccessAt,
      lastFailureAt: input.lastFailureAt,
      autoReconnectEnabled: input.autoReconnectEnabled,
      statusLabel: input.statusLabel
    };
    const previous = DeviceStateStore.connectionSnapshot;
    DeviceStateStore.connectionSnapshot = snapshot;
    DeviceStateStore.publishIfChanged(previous, snapshot, DeviceStateStore.changedConnectionKeys(previous, snapshot));
    return snapshot;
  }

  static updateRuntime(
    systemStatus: PhotoTekCodeDescription | null,
    currentAction: PhotoTekCodeDescription | null,
    source: string = SOURCE_DEFAULT
  ): RuntimeSnapshot {
    const now = Date.now();
    const previous = DeviceStateStore.runtimeSnapshot;
    const actionCode = DeviceStateStore.codeToNumber(currentAction);
    const statusCode = DeviceStateStore.codeToNumber(systemStatus);
    let actionStartedAt = previous.actionStartedAt;
    if (!currentAction || actionCode !== previous.currentActionCode || actionStartedAt <= 0) {
      actionStartedAt = currentAction ? now : 0;
    }
    const snapshot: RuntimeSnapshot = {
      topic: 'runtime',
      updatedAt: now,
      source: source,
      valid: systemStatus !== null && currentAction !== null,
      errorMessage: systemStatus !== null && currentAction !== null ? '' : '读取运行状态失败',
      systemStatus: systemStatus,
      systemStatusCode: statusCode,
      systemStatusLabel: systemStatus ? systemStatus.label : '-',
      currentAction: currentAction,
      currentActionCode: actionCode,
      currentActionLabel: currentAction ? currentAction.label : '-',
      actionStartedAt: actionStartedAt,
      actionDurationSeconds: actionStartedAt > 0 ? Math.max(0, Math.floor((now - actionStartedAt) / 1000)) : 0
    };
    DeviceStateStore.runtimeSnapshot = snapshot;
    DeviceStateStore.publishIfChanged(previous, snapshot, DeviceStateStore.changedRuntimeKeys(previous, snapshot));
    return snapshot;
  }

  static updateRuntimeInvalid(errorMessage: string, source: string = SOURCE_DEFAULT): RuntimeSnapshot {
    const now = Date.now();
    const previous = DeviceStateStore.runtimeSnapshot;
    const snapshot: RuntimeSnapshot = {
      topic: 'runtime',
      updatedAt: now,
      source: source,
      valid: false,
      errorMessage: errorMessage,
      systemStatus: null,
      systemStatusCode: null,
      systemStatusLabel: '-',
      currentAction: null,
      currentActionCode: null,
      currentActionLabel: '-',
      actionStartedAt: 0,
      actionDurationSeconds: 0
    };
    DeviceStateStore.runtimeSnapshot = snapshot;
    DeviceStateStore.publishIfChanged(previous, snapshot, DeviceStateStore.changedRuntimeKeys(previous, snapshot));
    return snapshot;
  }

  static updateAlarm(
    alarm: PhotoTekCodeDescription | null,
    alarmTime: PhotoTekTimeValue | null,
    source: string = SOURCE_DEFAULT
  ): AlarmSnapshot {
    const now = Date.now();
    const previous = DeviceStateStore.alarmSnapshot;
    const alarmCode = DeviceStateStore.codeToNumber(alarm);
    const alarmTimestamp = DeviceStateStore.timeValueToTimestamp(alarmTime, now);
    const active = alarmCode !== null && alarmCode !== 0;
    const snapshot: AlarmSnapshot = {
      topic: 'alarm',
      updatedAt: now,
      source: source,
      valid: alarm !== null,
      errorMessage: alarm !== null ? '' : '读取报警失败',
      alarm: alarm,
      alarmCode: alarmCode,
      alarmLabel: alarm ? alarm.label : '当前无报警',
      alarmTime: alarmTime,
      alarmTimestamp: alarmTimestamp,
      active: active,
      newAlarm: active && (alarmCode !== previous.alarmCode || alarmTimestamp !== previous.alarmTimestamp)
    };
    DeviceStateStore.alarmSnapshot = snapshot;
    DeviceStateStore.publishIfChanged(previous, snapshot, DeviceStateStore.changedAlarmKeys(previous, snapshot));
    return snapshot;
  }

  static updateAlarmInvalid(errorMessage: string, source: string = SOURCE_DEFAULT): AlarmSnapshot {
    const now = Date.now();
    const previous = DeviceStateStore.alarmSnapshot;
    const snapshot: AlarmSnapshot = {
      topic: 'alarm',
      updatedAt: now,
      source: source,
      valid: false,
      errorMessage: errorMessage,
      alarm: null,
      alarmCode: null,
      alarmLabel: '当前无报警',
      alarmTime: null,
      alarmTimestamp: now,
      active: false,
      newAlarm: false
    };
    DeviceStateStore.alarmSnapshot = snapshot;
    DeviceStateStore.publishIfChanged(previous, snapshot, DeviceStateStore.changedAlarmKeys(previous, snapshot));
    return snapshot;
  }

  static updateTemperature(
    temperatures: PhotoTekTemperatureValue | null,
    source: string = SOURCE_DEFAULT
  ): TemperatureSnapshot {
    const now = Date.now();
    const previous = DeviceStateStore.temperatureSnapshot;
    const snapshot: TemperatureSnapshot = {
      topic: 'temperature',
      updatedAt: now,
      source: source,
      valid: temperatures !== null,
      errorMessage: temperatures !== null ? '' : '读取温度失败',
      temperatures: temperatures,
      digestionTemperature: temperatures ? temperatures.digestionTemperature : null,
      ambientTemperature: temperatures ? temperatures.ambientTemperature : null,
      unit: temperatures && temperatures.unit.length > 0 ? temperatures.unit : '℃'
    };
    DeviceStateStore.temperatureSnapshot = snapshot;
    DeviceStateStore.publishIfChanged(previous, snapshot, DeviceStateStore.changedTemperatureKeys(previous, snapshot));
    return snapshot;
  }

  static updateTemperatureInvalid(errorMessage: string, source: string = SOURCE_DEFAULT): TemperatureSnapshot {
    const now = Date.now();
    const previous = DeviceStateStore.temperatureSnapshot;
    const snapshot: TemperatureSnapshot = {
      topic: 'temperature',
      updatedAt: now,
      source: source,
      valid: false,
      errorMessage: errorMessage,
      temperatures: null,
      digestionTemperature: null,
      ambientTemperature: null,
      unit: '℃'
    };
    DeviceStateStore.temperatureSnapshot = snapshot;
    DeviceStateStore.publishIfChanged(previous, snapshot, DeviceStateStore.changedTemperatureKeys(previous, snapshot));
    return snapshot;
  }

  static updateSignal(waterSampleAbsorbance: number | null, source: string = SOURCE_DEFAULT): SignalSnapshot {
    const now = Date.now();
    const previous = DeviceStateStore.signalSnapshot;
    const snapshot: SignalSnapshot = {
      topic: 'signal',
      updatedAt: now,
      source: source,
      valid: waterSampleAbsorbance !== null,
      errorMessage: waterSampleAbsorbance !== null ? '' : '读取信号失败',
      waterSampleAbsorbance: waterSampleAbsorbance
    };
    DeviceStateStore.signalSnapshot = snapshot;
    DeviceStateStore.publishIfChanged(previous, snapshot, DeviceStateStore.changedSignalKeys(previous, snapshot));
    return snapshot;
  }

  static updateSignalInvalid(errorMessage: string, source: string = SOURCE_DEFAULT): SignalSnapshot {
    return DeviceStateStore.updateSignalWithValidity(null, false, errorMessage, source);
  }

  static updateMeasurementDisplay(
    parameter: PhotoTekMeasurementParameterInfo,
    value: number | null,
    resultType: PhotoTekCodeDescription | null,
    resultTime: number,
    measuring: boolean,
    runningSeconds: number,
    source: string = SOURCE_DEFAULT
  ): MeasurementDisplaySnapshot {
    const now = Date.now();
    const previous = DeviceStateStore.measurementSnapshot;
    const snapshot: MeasurementDisplaySnapshot = {
      topic: 'measurement',
      updatedAt: now,
      source: source,
      valid: value !== null,
      errorMessage: value !== null ? '' : '读取测量显示失败',
      parameter: parameter,
      value: value,
      unit: parameter.unit.length > 0 ? parameter.unit : 'mg/L',
      resultType: resultType,
      resultTypeLabel: resultType ? resultType.label : '-',
      sampleTime: resultTime > 0 ? resultTime : now,
      measuring: measuring,
      runningSeconds: runningSeconds
    };
    DeviceStateStore.measurementSnapshot = snapshot;
    DeviceStateStore.publishIfChanged(previous, snapshot, DeviceStateStore.changedMeasurementKeys(previous, snapshot));
    return snapshot;
  }

  static updateMeasurementInvalid(
    parameter: PhotoTekMeasurementParameterInfo,
    measuring: boolean,
    runningSeconds: number,
    errorMessage: string,
    source: string = SOURCE_DEFAULT
  ): MeasurementDisplaySnapshot {
    const now = Date.now();
    const previous = DeviceStateStore.measurementSnapshot;
    const snapshot: MeasurementDisplaySnapshot = {
      topic: 'measurement',
      updatedAt: now,
      source: source,
      valid: false,
      errorMessage: errorMessage,
      parameter: parameter,
      value: null,
      unit: parameter.unit.length > 0 ? parameter.unit : 'mg/L',
      resultType: null,
      resultTypeLabel: '-',
      sampleTime: now,
      measuring: measuring,
      runningSeconds: runningSeconds
    };
    DeviceStateStore.measurementSnapshot = snapshot;
    DeviceStateStore.publishIfChanged(previous, snapshot, DeviceStateStore.changedMeasurementKeys(previous, snapshot));
    return snapshot;
  }

  static resetRealtimeState(reason: string = '设备未连接'): void {
    DeviceStateStore.updateRuntimeInvalid(reason, SOURCE_DISCONNECTED);
    DeviceStateStore.updateAlarmInvalid(reason, SOURCE_DISCONNECTED);
    DeviceStateStore.updateTemperatureInvalid(reason, SOURCE_DISCONNECTED);
    DeviceStateStore.updateSignalInvalid(reason, SOURCE_DISCONNECTED);
    DeviceStateStore.updateMeasurementInvalid(
      DeviceStateStore.measurementSnapshot.parameter,
      false,
      0,
      reason,
      SOURCE_DISCONNECTED
    );
  }

  private static updateSignalWithValidity(
    waterSampleAbsorbance: number | null,
    valid: boolean,
    errorMessage: string,
    source: string
  ): SignalSnapshot {
    const now = Date.now();
    const previous = DeviceStateStore.signalSnapshot;
    const snapshot: SignalSnapshot = {
      topic: 'signal',
      updatedAt: now,
      source: source,
      valid: valid,
      errorMessage: errorMessage,
      waterSampleAbsorbance: waterSampleAbsorbance
    };
    DeviceStateStore.signalSnapshot = snapshot;
    DeviceStateStore.publishIfChanged(previous, snapshot, DeviceStateStore.changedSignalKeys(previous, snapshot));
    return snapshot;
  }

  private static publishIfChanged(previous: DeviceSnapshot, current: DeviceSnapshot, changedKeys: string[]): void {
    if (changedKeys.length === 0) {
      return;
    }
    const event: DeviceEvent = {
      topic: current.topic,
      previous: previous,
      current: current,
      changedKeys: changedKeys,
      emittedAt: Date.now()
    };
    DeviceEventBus.publish(event);
  }

  private static createDefaultConnectionSnapshot(): ConnectionSnapshot {
    const now = Date.now();
    const snapshot: ConnectionSnapshot = {
      topic: 'connection',
      updatedAt: now,
      source: SOURCE_DEFAULT,
      valid: true,
      errorMessage: '',
      state: 'disconnected',
      businessState: 'disconnected',
      connected: false,
      mode: 'uart',
      failureCount: 0,
      lastProbeAt: 0,
      lastSuccessAt: 0,
      lastFailureAt: 0,
      autoReconnectEnabled: true,
      statusLabel: '未连接'
    };
    return snapshot;
  }

  private static createDefaultRuntimeSnapshot(): RuntimeSnapshot {
    const now = Date.now();
    const snapshot: RuntimeSnapshot = {
      topic: 'runtime',
      updatedAt: now,
      source: SOURCE_DEFAULT,
      valid: false,
      errorMessage: '尚未读取运行状态',
      systemStatus: null,
      systemStatusCode: null,
      systemStatusLabel: '-',
      currentAction: null,
      currentActionCode: null,
      currentActionLabel: '-',
      actionStartedAt: 0,
      actionDurationSeconds: 0
    };
    return snapshot;
  }

  private static createDefaultAlarmSnapshot(): AlarmSnapshot {
    const now = Date.now();
    const snapshot: AlarmSnapshot = {
      topic: 'alarm',
      updatedAt: now,
      source: SOURCE_DEFAULT,
      valid: false,
      errorMessage: '尚未读取报警',
      alarm: null,
      alarmCode: null,
      alarmLabel: '当前无报警',
      alarmTime: null,
      alarmTimestamp: now,
      active: false,
      newAlarm: false
    };
    return snapshot;
  }

  private static createDefaultTemperatureSnapshot(): TemperatureSnapshot {
    const now = Date.now();
    const snapshot: TemperatureSnapshot = {
      topic: 'temperature',
      updatedAt: now,
      source: SOURCE_DEFAULT,
      valid: false,
      errorMessage: '尚未读取温度',
      temperatures: null,
      digestionTemperature: null,
      ambientTemperature: null,
      unit: '℃'
    };
    return snapshot;
  }

  private static createDefaultSignalSnapshot(): SignalSnapshot {
    const now = Date.now();
    const snapshot: SignalSnapshot = {
      topic: 'signal',
      updatedAt: now,
      source: SOURCE_DEFAULT,
      valid: false,
      errorMessage: '尚未读取信号',
      waterSampleAbsorbance: null
    };
    return snapshot;
  }

  private static createDefaultMeasurementSnapshot(): MeasurementDisplaySnapshot {
    const now = Date.now();
    const parameter: PhotoTekMeasurementParameterInfo = {
      code: 1018,
      legacyCode: '011',
      name: 'TN',
      unit: 'mg/L'
    };
    const snapshot: MeasurementDisplaySnapshot = {
      topic: 'measurement',
      updatedAt: now,
      source: SOURCE_DEFAULT,
      valid: false,
      errorMessage: '尚未读取测量显示',
      parameter: parameter,
      value: null,
      unit: parameter.unit,
      resultType: null,
      resultTypeLabel: '-',
      sampleTime: now,
      measuring: false,
      runningSeconds: 0
    };
    return snapshot;
  }

  private static codeToNumber(value: PhotoTekCodeDescription | null): number | null {
    if (!value) {
      return null;
    }
    if (typeof value.code === 'number') {
      return value.code;
    }
    const parsed = Number(value.code);
    return Number.isNaN(parsed) ? null : parsed;
  }

  private static timeValueToTimestamp(value: PhotoTekTimeValue | null, fallback: number): number {
    if (!value) {
      return fallback;
    }
    return new Date(value.year, value.month - 1, value.day, value.hour, value.minute, value.second).getTime();
  }

  private static pushChanged(changedKeys: string[], key: string, changed: boolean): void {
    if (changed) {
      changedKeys.push(key);
    }
  }

  private static changedConnectionKeys(previous: ConnectionSnapshot, current: ConnectionSnapshot): string[] {
    const changedKeys: string[] = [];
    DeviceStateStore.pushChanged(changedKeys, 'state', previous.state !== current.state);
    DeviceStateStore.pushChanged(changedKeys, 'businessState', previous.businessState !== current.businessState);
    DeviceStateStore.pushChanged(changedKeys, 'connected', previous.connected !== current.connected);
    DeviceStateStore.pushChanged(changedKeys, 'mode', previous.mode !== current.mode);
    DeviceStateStore.pushChanged(changedKeys, 'failureCount', previous.failureCount !== current.failureCount);
    DeviceStateStore.pushChanged(changedKeys, 'lastProbeAt', previous.lastProbeAt !== current.lastProbeAt);
    DeviceStateStore.pushChanged(changedKeys, 'lastSuccessAt', previous.lastSuccessAt !== current.lastSuccessAt);
    DeviceStateStore.pushChanged(changedKeys, 'lastFailureAt', previous.lastFailureAt !== current.lastFailureAt);
    DeviceStateStore.pushChanged(changedKeys, 'autoReconnectEnabled',
      previous.autoReconnectEnabled !== current.autoReconnectEnabled);
    DeviceStateStore.pushChanged(changedKeys, 'statusLabel', previous.statusLabel !== current.statusLabel);
    DeviceStateStore.pushChanged(changedKeys, 'errorMessage', previous.errorMessage !== current.errorMessage);
    return changedKeys;
  }

  private static changedRuntimeKeys(previous: RuntimeSnapshot, current: RuntimeSnapshot): string[] {
    const changedKeys: string[] = [];
    DeviceStateStore.pushChanged(changedKeys, 'valid', previous.valid !== current.valid);
    DeviceStateStore.pushChanged(changedKeys, 'systemStatusCode', previous.systemStatusCode !== current.systemStatusCode);
    DeviceStateStore.pushChanged(changedKeys, 'currentActionCode', previous.currentActionCode !== current.currentActionCode);
    DeviceStateStore.pushChanged(changedKeys, 'actionDurationSeconds',
      previous.actionDurationSeconds !== current.actionDurationSeconds);
    return changedKeys;
  }

  private static changedAlarmKeys(previous: AlarmSnapshot, current: AlarmSnapshot): string[] {
    const changedKeys: string[] = [];
    DeviceStateStore.pushChanged(changedKeys, 'valid', previous.valid !== current.valid);
    DeviceStateStore.pushChanged(changedKeys, 'alarmCode', previous.alarmCode !== current.alarmCode);
    DeviceStateStore.pushChanged(changedKeys, 'alarmTimestamp', previous.alarmTimestamp !== current.alarmTimestamp);
    DeviceStateStore.pushChanged(changedKeys, 'active', previous.active !== current.active);
    return changedKeys;
  }

  private static changedTemperatureKeys(previous: TemperatureSnapshot, current: TemperatureSnapshot): string[] {
    const changedKeys: string[] = [];
    DeviceStateStore.pushChanged(changedKeys, 'valid', previous.valid !== current.valid);
    DeviceStateStore.pushChanged(changedKeys, 'digestionTemperature',
      previous.digestionTemperature !== current.digestionTemperature);
    DeviceStateStore.pushChanged(changedKeys, 'ambientTemperature',
      previous.ambientTemperature !== current.ambientTemperature);
    return changedKeys;
  }

  private static changedSignalKeys(previous: SignalSnapshot, current: SignalSnapshot): string[] {
    const changedKeys: string[] = [];
    DeviceStateStore.pushChanged(changedKeys, 'valid', previous.valid !== current.valid);
    DeviceStateStore.pushChanged(changedKeys, 'waterSampleAbsorbance',
      previous.waterSampleAbsorbance !== current.waterSampleAbsorbance);
    return changedKeys;
  }

  private static changedMeasurementKeys(
    previous: MeasurementDisplaySnapshot,
    current: MeasurementDisplaySnapshot
  ): string[] {
    const changedKeys: string[] = [];
    DeviceStateStore.pushChanged(changedKeys, 'valid', previous.valid !== current.valid);
    DeviceStateStore.pushChanged(changedKeys, 'parameter', previous.parameter.code !== current.parameter.code);
    DeviceStateStore.pushChanged(changedKeys, 'value', previous.value !== current.value);
    DeviceStateStore.pushChanged(changedKeys, 'resultTypeLabel', previous.resultTypeLabel !== current.resultTypeLabel);
    DeviceStateStore.pushChanged(changedKeys, 'measuring', previous.measuring !== current.measuring);
    DeviceStateStore.pushChanged(changedKeys, 'runningSeconds', previous.runningSeconds !== current.runningSeconds);
    return changedKeys;
  }
}
