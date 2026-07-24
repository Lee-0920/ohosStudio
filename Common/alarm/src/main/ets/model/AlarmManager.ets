// lhipstudio/Common/alarm/src/main/ets/model/AlarmManager.ets

import { AlarmCode, getAlarmDescription } from './AlarmCode';
import { AlarmRecord, AlarmStatus } from './AlarmRecord';

// 告警回调接口
export interface AlarmCallback {
  onAlarmTriggered: (record: AlarmRecord) => void;
  onAlarmCleared: (record: AlarmRecord) => void;
  onAlarmListChanged: (records: AlarmRecord[]) => void;
}

export class AlarmManager {
  private static instance: AlarmManager;
  private alarmRecords: AlarmRecord[] = [];
  private callbacks: AlarmCallback[] = [];
  private isInitialized: boolean = false;

  // 单例模式
  static getInstance(): AlarmManager {
    if (!AlarmManager.instance) {
      AlarmManager.instance = new AlarmManager();
    }
    return AlarmManager.instance;
  }

  // 初始化
  initialize(): void {
    if (this.isInitialized) return;
    this.alarmRecords = [];
    this.isInitialized = true;
    console.info('AlarmManager initialized');
  }

  // 注册回调
  registerCallback(callback: AlarmCallback): void {
    this.callbacks.push(callback);
  }

  // 注销回调
  unregisterCallback(callback: AlarmCallback): void {
    const index = this.callbacks.indexOf(callback);
    if (index >= 0) {
      this.callbacks.splice(index, 1);
    }
  }

  // 触发告警（供其他模块调用）
  triggerAlarm(alarmCode: AlarmCode, extraInfo: string = ''): AlarmRecord {
    if (alarmCode === AlarmCode.NO_ALARM) {
      console.warn('Cannot trigger alarm with code NO_ALARM');
      // Create a dummy record just to satisfy return type
      const dummy = new AlarmRecord(alarmCode, extraInfo);
      return dummy;
    }

    const record = new AlarmRecord(alarmCode, extraInfo);
    this.alarmRecords.push(record);

    console.info(`Alarm triggered: ${record.description} (code: ${alarmCode})`);

    for (const callback of this.callbacks) {
      callback.onAlarmTriggered(record);
      callback.onAlarmListChanged(this.alarmRecords);
    }

    return record;
  }

  // 消除告警
  clearAlarm(recordId: string, userId: string = ''): boolean {
    const record = this.alarmRecords.find(r => r.id === recordId);
    if (!record) {
      console.warn(`Alarm record not found: ${recordId}`);
      return false;
    }

    if (record.status === AlarmStatus.CLEARED) {
      console.warn(`Alarm already cleared: ${recordId}`);
      return false;
    }

    record.clear(userId);
    console.info(`Alarm cleared: ${record.description} (code: ${record.alarmCode})`);

    for (const callback of this.callbacks) {
      callback.onAlarmCleared(record);
      callback.onAlarmListChanged(this.alarmRecords);
    }

    return true;
  }

  // 确认告警
  acknowledgeAlarm(recordId: string, userId: string = ''): boolean {
    const record = this.alarmRecords.find(r => r.id === recordId);
    if (!record) {
      console.warn(`Alarm record not found: ${recordId}`);
      return false;
    }

    record.acknowledge(userId);
    console.info(`Alarm acknowledged: ${record.description} (code: ${record.alarmCode})`);

    for (const callback of this.callbacks) {
      callback.onAlarmListChanged(this.alarmRecords);
    }

    return true;
  }

  // 获取所有告警记录
  getAllRecords(): AlarmRecord[] {
    return [...this.alarmRecords];
  }

  // 获取活跃告警（未消除的）
  getActiveRecords(): AlarmRecord[] {
    return this.alarmRecords.filter(r => r.isActive());
  }

  // 获取已消除告警
  getClearedRecords(): AlarmRecord[] {
    return this.alarmRecords.filter(r => r.status === AlarmStatus.CLEARED);
  }

  // 根据告警码查询
  getRecordsByCode(alarmCode: AlarmCode): AlarmRecord[] {
    return this.alarmRecords.filter(r => r.alarmCode === alarmCode);
  }

  // 获取当前活跃告警数量
  getActiveAlarmCount(): number {
    return this.getActiveRecords().length;
  }

  // 获取当前最高优先级的活跃告警码（返回数值最大的，代表最新/最严重）
  getCurrentAlarmCode(): AlarmCode {
    const activeRecords = this.getActiveRecords();
    if (activeRecords.length === 0) {
      return AlarmCode.NO_ALARM;
    }
    // 返回最新的活跃告警
    const latest = activeRecords[activeRecords.length - 1];
    return latest.alarmCode;
  }

  // 获取当前活跃告警描述
  getCurrentAlarmDescription(): string {
    const code = this.getCurrentAlarmCode();
    if (code === AlarmCode.NO_ALARM) {
      return '无报警';
    }
    return getAlarmDescription(code);
  }

  // 检查是否有活跃告警
  hasActiveAlarm(): boolean {
    return this.getActiveAlarmCount() > 0;
  }

  // 批量消除指定类型的告警
  clearAlarmsByType(alarmCode: AlarmCode, userId: string = ''): number {
    const records = this.getRecordsByCode(alarmCode).filter(r => r.isActive());
    let count = 0;
    for (const record of records) {
      if (this.clearAlarm(record.id, userId)) {
        count++;
      }
    }
    return count;
  }

  // 清除所有已消除的历史记录（清理内存）
  purgeClearedRecords(): number {
    const beforeCount = this.alarmRecords.length;
    this.alarmRecords = this.alarmRecords.filter(r => r.isActive());
    const purgedCount = beforeCount - this.alarmRecords.length;
    if (purgedCount > 0) {
      console.info(`Purged ${purgedCount} cleared alarm records`);
      for (const callback of this.callbacks) {
        callback.onAlarmListChanged(this.alarmRecords);
      }
    }
    return purgedCount;
  }

  // 获取告警统计
  getAlarmStatistics(): Map<AlarmCode, number> {
    const stats = new Map<AlarmCode, number>();
    for (const record of this.alarmRecords) {
      const count = stats.get(record.alarmCode) ?? 0;
      stats.set(record.alarmCode, count + 1);
    }
    return stats;
  }

  // 序列化所有记录
  serializeAll(): string {
    const data: string[] = [];
    for (const record of this.alarmRecords) {
      data.push(record.serialize());
    }
    return JSON.stringify(data);
  }

  // 从序列化数据恢复
  deserializeAll(data: string): void {
    const records: string[] = JSON.parse(data) as string[];
    this.alarmRecords = [];
    for (const recordData of records) {
      this.alarmRecords.push(AlarmRecord.deserialize(recordData));
    }
    console.info(`Restored ${this.alarmRecords.length} alarm records`);
    for (const callback of this.callbacks) {
      callback.onAlarmListChanged(this.alarmRecords);
    }
  }
}
