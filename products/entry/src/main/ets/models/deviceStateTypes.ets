import {
  PhotoTekCodeDescription,
  PhotoTekMeasurementParameterInfo,
  PhotoTekTemperatureValue,
  PhotoTekTimeValue
} from '../services/protocol/PhotoTekTypes';

export type DeviceTopic =
  'connection' |
  'runtime' |
  'alarm' |
  'temperature' |
  'signal' |
  'measurement';

export type DeviceCommunicationMode = 'tcp' | 'uart';
export type DeviceConnectionStatus = 'disconnected' | 'online';
export type DeviceBusinessConnectionState =
  'disconnected' |
  'probing' |
  'online' |
  'degraded' |
  'manualDisconnected';
export type DeviceTopicInterestLevel = 'normal' | 'high';

export interface DeviceSnapshotBase {
  topic: DeviceTopic;
  updatedAt: number;
  source: string;
  valid: boolean;
  errorMessage: string;
}

export interface ConnectionSnapshot extends DeviceSnapshotBase {
  topic: 'connection';
  state: DeviceConnectionStatus;
  businessState: DeviceBusinessConnectionState;
  connected: boolean;
  mode: DeviceCommunicationMode;
  failureCount: number;
  lastProbeAt: number;
  lastSuccessAt: number;
  lastFailureAt: number;
  autoReconnectEnabled: boolean;
  statusLabel: string;
}

export interface ConnectionSnapshotInput {
  state: DeviceConnectionStatus;
  businessState: DeviceBusinessConnectionState;
  connected: boolean;
  mode: DeviceCommunicationMode;
  failureCount: number;
  lastProbeAt: number;
  lastSuccessAt: number;
  lastFailureAt: number;
  autoReconnectEnabled: boolean;
  statusLabel: string;
  errorMessage: string;
}

export interface RuntimeSnapshot extends DeviceSnapshotBase {
  topic: 'runtime';
  systemStatus: PhotoTekCodeDescription | null;
  systemStatusCode: number | null;
  systemStatusLabel: string;
  currentAction: PhotoTekCodeDescription | null;
  currentActionCode: number | null;
  currentActionLabel: string;
  actionStartedAt: number;
  actionDurationSeconds: number;
}

export interface AlarmSnapshot extends DeviceSnapshotBase {
  topic: 'alarm';
  alarm: PhotoTekCodeDescription | null;
  alarmCode: number | null;
  alarmLabel: string;
  alarmTime: PhotoTekTimeValue | null;
  alarmTimestamp: number;
  active: boolean;
  newAlarm: boolean;
}

export interface TemperatureSnapshot extends DeviceSnapshotBase {
  topic: 'temperature';
  temperatures: PhotoTekTemperatureValue | null;
  digestionTemperature: number | null;
  ambientTemperature: number | null;
  unit: string;
}

export interface SignalSnapshot extends DeviceSnapshotBase {
  topic: 'signal';
  waterSampleAbsorbance: number | null;
}

export interface MeasurementDisplaySnapshot extends DeviceSnapshotBase {
  topic: 'measurement';
  parameter: PhotoTekMeasurementParameterInfo;
  value: number | null;
  unit: string;
  resultType: PhotoTekCodeDescription | null;
  resultTypeLabel: string;
  sampleTime: number;
  measuring: boolean;
  runningSeconds: number;
}

export type DeviceSnapshot =
  ConnectionSnapshot |
  RuntimeSnapshot |
  AlarmSnapshot |
  TemperatureSnapshot |
  SignalSnapshot |
  MeasurementDisplaySnapshot;

export interface DeviceEvent {
  topic: DeviceTopic;
  previous: DeviceSnapshot;
  current: DeviceSnapshot;
  changedKeys: string[];
  emittedAt: number;
}

export type DeviceEventListener = (event: DeviceEvent) => void;

export interface DeviceTopicInterest {
  topic: DeviceTopic;
  owner: string;
  level: DeviceTopicInterestLevel;
}
