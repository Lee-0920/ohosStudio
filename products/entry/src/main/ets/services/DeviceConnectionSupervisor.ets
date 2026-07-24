import { hilog } from '@kit.PerformanceAnalysisKit';
import {
  ConnectionSnapshotInput,
  DeviceBusinessConnectionState,
  DeviceTopic
} from '../models/deviceStateTypes';
import { MonitorService } from './MonitorService';

const DOMAIN = 0x0003;
const TAG = 'DeviceConnectionSupervisor';
const CONNECTION_FAILURE_THRESHOLD = 3;
const RECONNECT_PROBE_INTERVAL_MS = 5000;
const ACTIVE_RECONNECT_PROBE_INTERVAL_MS = 2000;
const ONLINE_HEARTBEAT_INTERVAL_MS = 10000;
const DEGRADED_HEARTBEAT_INTERVAL_MS = 3000;
const MAX_RECONNECT_BACKOFF_MS = 30000;

/**
 * 设备业务连接监督器。
 *
 * TCP 和 UART 都以 PhotoTek/Modbus 协议探测成功作为业务在线标准：
 * TCP 需要 socket 可用且 0x04 读取系统状态输入寄存器 16 成功；
 * UART 需要串口打开且同一个 0x04 探测请求成功。
 */
export class DeviceConnectionSupervisor {
  private static businessState: DeviceBusinessConnectionState = 'disconnected';
  private static failureCount: number = 0;
  private static lastProbeAt: number = 0;
  private static lastSuccessAt: number = 0;
  private static lastFailureAt: number = 0;
  private static lastFailureReason: string = '';
  private static autoReconnectEnabled: boolean = true;

  static getBusinessState(): DeviceBusinessConnectionState {
    return DeviceConnectionSupervisor.businessState;
  }

  static canRunBusinessRequests(): boolean {
    return DeviceConnectionSupervisor.businessState === 'online' ||
      DeviceConnectionSupervisor.businessState === 'degraded';
  }

  static isAutoReconnectEnabled(): boolean {
    return DeviceConnectionSupervisor.autoReconnectEnabled;
  }

  static enableAutoReconnect(): void {
    DeviceConnectionSupervisor.autoReconnectEnabled = true;
    if (DeviceConnectionSupervisor.businessState === 'manualDisconnected') {
      DeviceConnectionSupervisor.businessState = 'disconnected';
    }
  }

  static markManualDisconnected(): void {
    DeviceConnectionSupervisor.autoReconnectEnabled = false;
    DeviceConnectionSupervisor.failureCount = 0;
    DeviceConnectionSupervisor.lastFailureReason = '';
    DeviceConnectionSupervisor.businessState = 'manualDisconnected';
  }

  static markConfigChanged(): void {
    DeviceConnectionSupervisor.autoReconnectEnabled = true;
    DeviceConnectionSupervisor.failureCount = 0;
    DeviceConnectionSupervisor.lastFailureReason = '';
    DeviceConnectionSupervisor.businessState = 'disconnected';
  }

  static async probe(reason: string): Promise<ConnectionSnapshotInput> {
    DeviceConnectionSupervisor.lastProbeAt = Date.now();
    if (!DeviceConnectionSupervisor.autoReconnectEnabled && !MonitorService.isConnectedToMcu()) {
      DeviceConnectionSupervisor.businessState = 'manualDisconnected';
      return DeviceConnectionSupervisor.createSnapshotInput('自动重连已关闭');
    }

    DeviceConnectionSupervisor.businessState = 'probing';
    const connected = await MonitorService.probeConnection();
    if (connected) {
      DeviceConnectionSupervisor.recordTransportSuccess(reason);
      return DeviceConnectionSupervisor.createSnapshotInput('');
    }

    DeviceConnectionSupervisor.recordTransportFailure(reason, '协议探测失败');
    return DeviceConnectionSupervisor.createSnapshotInput(DeviceConnectionSupervisor.lastFailureReason);
  }

  static recordTransportSuccess(source: string): void {
    DeviceConnectionSupervisor.failureCount = 0;
    DeviceConnectionSupervisor.lastSuccessAt = Date.now();
    DeviceConnectionSupervisor.lastFailureReason = '';
    DeviceConnectionSupervisor.autoReconnectEnabled = true;
    DeviceConnectionSupervisor.businessState = 'online';
    hilog.info(DOMAIN, TAG, 'Transport success from %{public}s', source);
  }

  static recordTransportFailure(source: DeviceTopic | string, reason: string): void {
    DeviceConnectionSupervisor.failureCount++;
    DeviceConnectionSupervisor.lastFailureAt = Date.now();
    DeviceConnectionSupervisor.lastFailureReason = reason;
    DeviceConnectionSupervisor.autoReconnectEnabled = true;

    if (DeviceConnectionSupervisor.failureCount >= CONNECTION_FAILURE_THRESHOLD ||
      !MonitorService.isConnectedToMcu()) {
      DeviceConnectionSupervisor.businessState = 'disconnected';
    } else {
      DeviceConnectionSupervisor.businessState = 'degraded';
    }

    hilog.warn(
      DOMAIN,
      TAG,
      'Transport failure from %{public}s count=%{public}d state=%{public}s reason=%{public}s',
      source,
      DeviceConnectionSupervisor.failureCount,
      DeviceConnectionSupervisor.businessState,
      reason
    );
  }

  static syncFromMonitorService(source: string): void {
    if (MonitorService.isConnectedToMcu()) {
      DeviceConnectionSupervisor.recordTransportSuccess(source);
      return;
    }
    if (DeviceConnectionSupervisor.businessState === 'online' ||
      DeviceConnectionSupervisor.businessState === 'degraded' ||
      DeviceConnectionSupervisor.businessState === 'probing') {
      DeviceConnectionSupervisor.businessState = 'disconnected';
    }
  }

  static nextConnectionIntervalMs(hasHighInterest: boolean): number {
    if (DeviceConnectionSupervisor.businessState === 'online') {
      return hasHighInterest ? ACTIVE_RECONNECT_PROBE_INTERVAL_MS : ONLINE_HEARTBEAT_INTERVAL_MS;
    }
    if (DeviceConnectionSupervisor.businessState === 'degraded') {
      return hasHighInterest ? ACTIVE_RECONNECT_PROBE_INTERVAL_MS : DEGRADED_HEARTBEAT_INTERVAL_MS;
    }
    if (!DeviceConnectionSupervisor.autoReconnectEnabled) {
      return MAX_RECONNECT_BACKOFF_MS;
    }

    const base = hasHighInterest ? ACTIVE_RECONNECT_PROBE_INTERVAL_MS : RECONNECT_PROBE_INTERVAL_MS;
    const backoffFactor = Math.max(1, DeviceConnectionSupervisor.failureCount + 1);
    return Math.min(MAX_RECONNECT_BACKOFF_MS, base * backoffFactor);
  }

  static createSnapshotInput(errorMessage: string = ''): ConnectionSnapshotInput {
    const monitorConnected = MonitorService.isConnectedToMcu();
    if (!monitorConnected &&
      (DeviceConnectionSupervisor.businessState === 'online' ||
        DeviceConnectionSupervisor.businessState === 'degraded' ||
        DeviceConnectionSupervisor.businessState === 'probing')) {
      DeviceConnectionSupervisor.businessState = 'disconnected';
    }
    const onlineLike = DeviceConnectionSupervisor.businessState === 'online' ||
      DeviceConnectionSupervisor.businessState === 'degraded';
    const connected = monitorConnected && onlineLike;
    const snapshot: ConnectionSnapshotInput = {
      state: connected ? 'online' : 'disconnected',
      businessState: DeviceConnectionSupervisor.businessState,
      connected: connected,
      mode: MonitorService.getCommunicationMode(),
      failureCount: DeviceConnectionSupervisor.failureCount,
      lastProbeAt: DeviceConnectionSupervisor.lastProbeAt,
      lastSuccessAt: DeviceConnectionSupervisor.lastSuccessAt,
      lastFailureAt: DeviceConnectionSupervisor.lastFailureAt,
      autoReconnectEnabled: DeviceConnectionSupervisor.autoReconnectEnabled,
      statusLabel: DeviceConnectionSupervisor.statusLabel(),
      errorMessage: errorMessage
    };
    return snapshot;
  }

  private static statusLabel(): string {
    if (DeviceConnectionSupervisor.businessState === 'online') {
      return '已连接';
    }
    if (DeviceConnectionSupervisor.businessState === 'probing') {
      return '连接中';
    }
    if (DeviceConnectionSupervisor.businessState === 'degraded') {
      return '连接不稳定';
    }
    if (DeviceConnectionSupervisor.businessState === 'manualDisconnected') {
      return '已断开';
    }
    return '未连接';
  }
}
