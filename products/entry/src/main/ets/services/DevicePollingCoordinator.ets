import { hilog } from '@kit.PerformanceAnalysisKit';
import {
  DeviceTopic,
  DeviceTopicInterest,
  DeviceTopicInterestLevel
} from '../models/deviceStateTypes';
import { PhotoTekCodeDescription, PhotoTekTimeValue } from './protocol/PhotoTekTypes';
import { DeviceConnectionSupervisor } from './DeviceConnectionSupervisor';
import { DeviceEventBus } from './DeviceEventBus';
import { DeviceStateStore } from './DeviceStateStore';
import { MonitorService } from './MonitorService';

const SOURCE_COORDINATOR = 'device_polling_coordinator';
const RUNTIME_INTERVAL_MS = 5000;
const RUNTIME_ACTIVE_INTERVAL_MS = 1000;
const ALARM_INTERVAL_MS = 3000;
const ALARM_ACTIVE_INTERVAL_MS = 1000;
const TEMPERATURE_INTERVAL_MS = 5000;
const TEMPERATURE_ACTIVE_INTERVAL_MS = 1000;
const SIGNAL_ACTIVE_INTERVAL_MS = 1000;
const MEASUREMENT_INTERVAL_MS = 10000;
const MEASUREMENT_ACTIVE_INTERVAL_MS = 5000;
const MAX_BACKOFF_FACTOR = 5;

export class DevicePollingCoordinator {
  private static started: boolean = false;
  private static foreground: boolean = true;
  private static timers: Map<DeviceTopic, number> = new Map();
  private static inFlight: Map<DeviceTopic, boolean> = new Map();
  private static failureCounts: Map<DeviceTopic, number> = new Map();
  private static interests: DeviceTopicInterest[] = [];

  static start(): void {
    if (DevicePollingCoordinator.started) {
      return;
    }
    DevicePollingCoordinator.started = true;
    console.info('DevicePollingCoordinator started');
    DevicePollingCoordinator.rescheduleAll();
    void DevicePollingCoordinator.requestRefresh('connection');
  }

  static stop(): void {
    DevicePollingCoordinator.started = false;
    DevicePollingCoordinator.clearAllTimers();
    DevicePollingCoordinator.inFlight.clear();
    DevicePollingCoordinator.failureCounts.clear();
    DevicePollingCoordinator.interests = [];
  }

  static setForeground(active: boolean): void {
    if (DevicePollingCoordinator.foreground === active) {
      return;
    }
    DevicePollingCoordinator.foreground = active;
    DevicePollingCoordinator.rescheduleAll();
  }

  static registerTopicInterest(
    topic: DeviceTopic,
    owner: string,
    level: DeviceTopicInterestLevel = 'normal'
  ): () => void {
    DevicePollingCoordinator.removeTopicInterest(topic, owner);
    const interest: DeviceTopicInterest = {
      topic: topic,
      owner: owner,
      level: level
    };
    DevicePollingCoordinator.interests.push(interest);
    console.info('registerTopicInterest topic=%{public}s owner=%{public}s subscribers=%{public}d interests=%{public}d',
      topic, owner, DeviceEventBus.getSubscriberCount(topic), DevicePollingCoordinator.interests.length);
    DevicePollingCoordinator.rescheduleTopic(topic);
    if (DevicePollingCoordinator.started) {
      void DevicePollingCoordinator.requestRefresh(topic);
    }
    return (): void => {
      DevicePollingCoordinator.removeTopicInterest(topic, owner);
    };
  }

  static removeTopicInterest(topic: DeviceTopic, owner: string): void {
    DevicePollingCoordinator.interests = DevicePollingCoordinator.interests.filter(
      (interest: DeviceTopicInterest) => !(interest.topic === topic && interest.owner === owner)
    );
    DevicePollingCoordinator.rescheduleTopic(topic);
  }

  static async requestRefresh(topic: DeviceTopic): Promise<void> {
    // if (DevicePollingCoordinator.inFlight.get(topic)) {
    //   return;
    // }
    // if (!DevicePollingCoordinator.shouldPollTopic(topic, true)) {
    //   return;
    // }
    //
    // DevicePollingCoordinator.inFlight.set(topic, true);
    // try {
    //   if (topic === 'connection') {
    //     await DevicePollingCoordinator.pollConnection();
    //   } else if (topic === 'runtime') {
    //     await DevicePollingCoordinator.pollRuntime();
    //   } else if (topic === 'alarm') {
    //     await DevicePollingCoordinator.pollAlarm();
    //   } else if (topic === 'temperature') {
    //     await DevicePollingCoordinator.pollTemperature();
    //   } else if (topic === 'signal') {
    //     await DevicePollingCoordinator.pollSignal();
    //   } else {
    //     await DevicePollingCoordinator.pollMeasurement();
    //   }
    //   DevicePollingCoordinator.recordSuccess(topic);
    // } catch (err) {
    //   DevicePollingCoordinator.recordFailure(topic, JSON.stringify(err));
    // } finally {
    //   DevicePollingCoordinator.inFlight.set(topic, false);
    //   DevicePollingCoordinator.rescheduleAfterRefresh(topic);
    // }
  }

  static notifyConnectionSnapshotChanged(previousConnected: boolean, currentConnected: boolean): void {
    if (!previousConnected && currentConnected) {
      DevicePollingCoordinator.handleConnectionRecovered();
      return;
    }
    if (previousConnected !== currentConnected) {
      DevicePollingCoordinator.rescheduleAll();
    }
  }

  private static async pollConnection(): Promise<void> {
    const previousConnected = DeviceStateStore.getConnectionSnapshot().connected;
    const snapshot = await DeviceConnectionSupervisor.probe('connection-topic');
    if (!snapshot.connected) {
      DeviceStateStore.resetRealtimeState('设备未连接');
    }
    DeviceStateStore.updateConnection(snapshot, SOURCE_COORDINATOR);
    DevicePollingCoordinator.notifyConnectionSnapshotChanged(previousConnected, snapshot.connected);
  }

  private static async pollRuntime(): Promise<void> {
    const connected = MonitorService.isConnectedToMcu();
    console.info('pollRuntime invoked connected=%{public}s', String(connected));
    if (!connected) {
      DeviceStateStore.updateRuntimeInvalid('设备未连接', SOURCE_COORDINATOR);
      return;
    }
    const status = await MonitorService.readSystemStatus();
    const action = await MonitorService.readCurrentAction();
    console.info('pollRuntime status=%{public}s action=%{public}s',
      status ? `${status.code}(${status.label})` : 'null',
      action ? `${action.code}(${action.label})` : 'null'
    );
    if (!status || !action) {
      DeviceStateStore.updateRuntimeInvalid('读取运行状态失败', SOURCE_COORDINATOR);
      throw new Error('runtime read returned null');
    }
    DeviceStateStore.updateRuntime(status, action, SOURCE_COORDINATOR);
  }

  private static async pollAlarm(): Promise<void> {
    if (!MonitorService.isConnectedToMcu()) {
      DeviceStateStore.updateAlarmInvalid('设备未连接', SOURCE_COORDINATOR);
      return;
    }
    const alarm = await MonitorService.readAlarmCode();
    if (!alarm) {
      DeviceStateStore.updateAlarmInvalid('读取报警失败', SOURCE_COORDINATOR);
      throw new Error('alarm read returned null');
    }
    const alarmCode = DevicePollingCoordinator.codeToNumber(alarm);
    let alarmTime: PhotoTekTimeValue | null = null;
    if (alarmCode !== null && alarmCode !== 0) {
      alarmTime = await MonitorService.readAlarmTime();
    }
    DeviceStateStore.updateAlarm(alarm, alarmTime, SOURCE_COORDINATOR);
  }

  private static async pollTemperature(): Promise<void> {
    if (!MonitorService.isConnectedToMcu()) {
      DeviceStateStore.updateTemperatureInvalid('设备未连接', SOURCE_COORDINATOR);
      return;
    }
    const temperatures = await MonitorService.readCurrentTemperatures();
    if (!temperatures) {
      DeviceStateStore.updateTemperatureInvalid('读取温度失败', SOURCE_COORDINATOR);
      throw new Error('temperature read returned null');
    }
    DeviceStateStore.updateTemperature(temperatures, SOURCE_COORDINATOR);
  }

  private static async pollSignal(): Promise<void> {
    if (!MonitorService.isConnectedToMcu()) {
      DeviceStateStore.updateSignalInvalid('设备未连接', SOURCE_COORDINATOR);
      return;
    }
    const absorbance = await MonitorService.readWaterSampleAbsorbance();
    if (absorbance === null) {
      DeviceStateStore.updateSignalInvalid('读取信号失败', SOURCE_COORDINATOR);
      throw new Error('signal read returned null');
    }
    DeviceStateStore.updateSignal(absorbance, SOURCE_COORDINATOR);
  }

  private static async pollMeasurement(): Promise<void> {
    if (!MonitorService.isConnectedToMcu()) {
      DeviceStateStore.updateMeasurementInvalid(
        MonitorService.getCurrentMeasurementParameterInfo(),
        false,
        0,
        '设备未连接',
        SOURCE_COORDINATOR
      );
      return;
    }

    await MonitorService.refreshMeasurementParameter();
    const parameter = MonitorService.getCurrentMeasurementParameterInfo();
    const value = await MonitorService.readCompositeMeasurementResult();
    const resultType = await MonitorService.readMeasurementResultType();
    const resultTime = await MonitorService.readCompositeResultTime();
    const measuring = MonitorService.isMeasurementRunning();
    const runningSeconds = MonitorService.getMeasurementRunningSeconds();
    if (value === null) {
      DeviceStateStore.updateMeasurementInvalid(
        parameter,
        measuring,
        runningSeconds,
        '读取测量显示失败',
        SOURCE_COORDINATOR
      );
      throw new Error('measurement display read returned null');
    }
    DeviceStateStore.updateMeasurementDisplay(
      parameter,
      value,
      resultType,
      DevicePollingCoordinator.timeValueToTimestamp(resultTime, Date.now()),
      measuring,
      runningSeconds,
      SOURCE_COORDINATOR
    );
  }

  private static shouldPollTopic(topic: DeviceTopic, allowForced: boolean): boolean {
    if (!DevicePollingCoordinator.started && !allowForced) {
      return false;
    }
    if (topic === 'connection') {
      return DevicePollingCoordinator.foreground;
    }
    if (!DevicePollingCoordinator.foreground) {
      return false;
    }
    if (!DeviceConnectionSupervisor.canRunBusinessRequests()) {
      DeviceConnectionSupervisor.syncFromMonitorService('shouldPollTopic');
    }
    if (!DeviceConnectionSupervisor.canRunBusinessRequests()) {
      return false;
    }
    if (allowForced) {
      return true;
    }
    if (topic === 'runtime') {
      const hasDemand = DevicePollingCoordinator.hasDemand(topic);
      const isActive = DevicePollingCoordinator.isRuntimeActive();
      const result = hasDemand || isActive;
      console.info('shouldPollTopic runtime demand=%{public}s active=%{public}s canRun=%{public}s result=%{public}s',
        String(hasDemand), String(isActive), String(DeviceConnectionSupervisor.canRunBusinessRequests()),
        String(result));
      return result;
    }
    if (topic === 'measurement') {
      return DevicePollingCoordinator.hasDemand(topic) || MonitorService.isMeasurementRunning();
    }
    return DevicePollingCoordinator.hasDemand(topic);
  }

  private static rescheduleAll(): void {
    DevicePollingCoordinator.rescheduleTopic('connection');
    DevicePollingCoordinator.rescheduleTopic('runtime');
    DevicePollingCoordinator.rescheduleTopic('alarm');
    DevicePollingCoordinator.rescheduleTopic('temperature');
    DevicePollingCoordinator.rescheduleTopic('signal');
    DevicePollingCoordinator.rescheduleTopic('measurement');
  }

  private static rescheduleTopic(topic: DeviceTopic): void {
    DevicePollingCoordinator.clearTimer(topic);
    if (!DevicePollingCoordinator.started || !DevicePollingCoordinator.shouldPollTopic(topic, false)) {
      return;
    }
    const interval = DevicePollingCoordinator.intervalForTopic(topic) *
      DevicePollingCoordinator.backoffFactor(topic);
    const timer = setInterval(() => {
      void DevicePollingCoordinator.requestRefresh(topic);
    }, interval);
    DevicePollingCoordinator.timers.set(topic, timer);
  }

  private static rescheduleAfterRefresh(topic: DeviceTopic): void {
    if (topic === 'connection' || !DeviceConnectionSupervisor.canRunBusinessRequests()) {
      DevicePollingCoordinator.rescheduleAll();
      return;
    }
    DevicePollingCoordinator.rescheduleTopic(topic);
    DevicePollingCoordinator.rescheduleTopic('connection');
  }

  private static handleConnectionRecovered(): void {
    DevicePollingCoordinator.clearBusinessTopicBackoff();
    DevicePollingCoordinator.rescheduleAll();
    DevicePollingCoordinator.refreshDemandedBusinessTopics();
  }

  private static clearBusinessTopicBackoff(): void {
    DevicePollingCoordinator.failureCounts.set('runtime', 0);
    DevicePollingCoordinator.failureCounts.set('alarm', 0);
    DevicePollingCoordinator.failureCounts.set('temperature', 0);
    DevicePollingCoordinator.failureCounts.set('signal', 0);
    DevicePollingCoordinator.failureCounts.set('measurement', 0);
  }

  private static refreshDemandedBusinessTopics(): void {
    if (DevicePollingCoordinator.hasDemand('runtime') || DevicePollingCoordinator.isRuntimeActive()) {
      void DevicePollingCoordinator.requestRefresh('runtime');
    }
    if (DevicePollingCoordinator.hasDemand('alarm')) {
      void DevicePollingCoordinator.requestRefresh('alarm');
    }
    if (DevicePollingCoordinator.hasDemand('temperature')) {
      void DevicePollingCoordinator.requestRefresh('temperature');
    }
    if (DevicePollingCoordinator.hasDemand('signal')) {
      void DevicePollingCoordinator.requestRefresh('signal');
    }
    if (DevicePollingCoordinator.hasDemand('measurement') || MonitorService.isMeasurementRunning()) {
      void DevicePollingCoordinator.requestRefresh('measurement');
    }
  }

  private static clearTimer(topic: DeviceTopic): void {
    const timer = DevicePollingCoordinator.timers.get(topic);
    if (timer !== undefined) {
      clearInterval(timer);
      DevicePollingCoordinator.timers.delete(topic);
    }
  }

  private static clearAllTimers(): void {
    DevicePollingCoordinator.clearTimer('connection');
    DevicePollingCoordinator.clearTimer('runtime');
    DevicePollingCoordinator.clearTimer('alarm');
    DevicePollingCoordinator.clearTimer('temperature');
    DevicePollingCoordinator.clearTimer('signal');
    DevicePollingCoordinator.clearTimer('measurement');
  }

  private static intervalForTopic(topic: DeviceTopic): number {
    if (topic === 'connection') {
      return DeviceConnectionSupervisor.nextConnectionIntervalMs(DevicePollingCoordinator.hasHighInterest(topic));
    }
    if (topic === 'runtime') {
      return DevicePollingCoordinator.hasHighInterest(topic) || DevicePollingCoordinator.isRuntimeActive() ?
      RUNTIME_ACTIVE_INTERVAL_MS : RUNTIME_INTERVAL_MS;
    }
    if (topic === 'alarm') {
      return DevicePollingCoordinator.hasHighInterest(topic) ? ALARM_ACTIVE_INTERVAL_MS : ALARM_INTERVAL_MS;
    }
    if (topic === 'temperature') {
      return DevicePollingCoordinator.hasHighInterest(topic) ? TEMPERATURE_ACTIVE_INTERVAL_MS : TEMPERATURE_INTERVAL_MS;
    }
    if (topic === 'signal') {
      return SIGNAL_ACTIVE_INTERVAL_MS;
    }
    return DevicePollingCoordinator.hasHighInterest(topic) ? MEASUREMENT_ACTIVE_INTERVAL_MS : MEASUREMENT_INTERVAL_MS;
  }

  private static hasDemand(topic: DeviceTopic): boolean {
    return DeviceEventBus.getSubscriberCount(topic) > 0 || DevicePollingCoordinator.hasInterest(topic);
  }

  private static hasInterest(topic: DeviceTopic): boolean {
    for (let i = 0; i < DevicePollingCoordinator.interests.length; i++) {
      if (DevicePollingCoordinator.interests[i].topic === topic) {
        return true;
      }
    }
    return false;
  }

  private static hasHighInterest(topic: DeviceTopic): boolean {
    for (let i = 0; i < DevicePollingCoordinator.interests.length; i++) {
      const interest = DevicePollingCoordinator.interests[i];
      if (interest.topic === topic && interest.level === 'high') {
        return true;
      }
    }
    return false;
  }

  private static isRuntimeActive(): boolean {
    const runtime = DeviceStateStore.getRuntimeSnapshot();
    return runtime.valid && runtime.currentActionCode !== null && runtime.currentActionCode !== 0;
  }

  private static backoffFactor(topic: DeviceTopic): number {
    const failureCount = DevicePollingCoordinator.failureCounts.get(topic) || 0;
    if (failureCount <= 0) {
      return 1;
    }
    return Math.min(MAX_BACKOFF_FACTOR, failureCount + 1);
  }

  private static recordSuccess(topic: DeviceTopic): void {
    if ((DevicePollingCoordinator.failureCounts.get(topic) || 0) !== 0) {
      DevicePollingCoordinator.failureCounts.set(topic, 0);
    }
    if (topic !== 'connection') {
      DeviceConnectionSupervisor.recordTransportSuccess(topic);
      DeviceStateStore.updateConnection(
        DeviceConnectionSupervisor.createSnapshotInput(''),
        SOURCE_COORDINATOR
      );
    }
  }

  private static recordFailure(topic: DeviceTopic, reason: string): void {
    const failureCount = (DevicePollingCoordinator.failureCounts.get(topic) || 0) + 1;
    DevicePollingCoordinator.failureCounts.set(topic, failureCount);
    if (topic !== 'connection') {
      DeviceConnectionSupervisor.recordTransportFailure(topic, reason);
      const snapshot = DeviceConnectionSupervisor.createSnapshotInput(reason);
      if (!snapshot.connected) {
        DeviceStateStore.resetRealtimeState('设备未连接');
      }
      DeviceStateStore.updateConnection(
        snapshot,
        SOURCE_COORDINATOR
      );
    }
  }

  private static codeToNumber(value: PhotoTekCodeDescription): number | null {
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
    const date = new Date(value.year, value.month - 1, value.day, value.hour, value.minute, value.second, 0);
    const timestamp = date.getTime();
    return Number.isNaN(timestamp) || timestamp <= 0 ? fallback : timestamp;
  }
}
