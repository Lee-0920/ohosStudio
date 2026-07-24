// lhipstudio/Common/alarm/src/main/ets/model/AlarmRecord.ets

import { AlarmCode, getAlarmDescription, getAlarmType, AlarmType } from './AlarmCode';

// 告警状态
export enum AlarmStatus {
  ACTIVE = '未消除',     // 当前活跃告警
  ACKNOWLEDGED = '已确认', // 已确认但未消除
  CLEARED = '已消除'      // 已消除
}

// 告警记录
export class AlarmRecord {
  id: string;                          // 唯一标识
  alarmCode: AlarmCode;                // 告警码
  description: string;                 // 告警描述
  alarmType: AlarmType;                // 告警类型
  status: AlarmStatus;                 // 告警状态
  triggeredAt: number;                 // 触发时间（时间戳）
  acknowledgedAt: number;              // 确认时间（时间戳，0表示未确认）
  clearedAt: number;                   // 消除时间（时间戳，0表示未消除）
  acknowledgedBy: string;              // 确认人
  clearedBy: string;                   // 消除人
  extraInfo: string;                   // 额外信息

  constructor(alarmCode: AlarmCode, extraInfo: string = '') {
    this.id = `${alarmCode}_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
    this.alarmCode = alarmCode;
    this.description = getAlarmDescription(alarmCode);
    this.alarmType = getAlarmType(alarmCode);
    this.status = AlarmStatus.ACTIVE;
    this.triggeredAt = Date.now();
    this.acknowledgedAt = 0;
    this.clearedAt = 0;
    this.acknowledgedBy = '';
    this.clearedBy = '';
    this.extraInfo = extraInfo;
  }

  // 确认告警
  acknowledge(userId: string): void {
    if (this.status === AlarmStatus.ACTIVE) {
      this.status = AlarmStatus.ACKNOWLEDGED;
      this.acknowledgedAt = Date.now();
      this.acknowledgedBy = userId;
    }
  }

  // 消除告警
  clear(userId: string): void {
    if (this.status !== AlarmStatus.CLEARED) {
      this.status = AlarmStatus.CLEARED;
      this.clearedAt = Date.now();
      this.clearedBy = userId;
    }
  }

  // 判断是否为活跃告警
  isActive(): boolean {
    return this.status === AlarmStatus.ACTIVE || this.status === AlarmStatus.ACKNOWLEDGED;
  }

  // 获取持续时间（毫秒）
  getDuration(): number {
    const endTime = this.clearedAt > 0 ? this.clearedAt : Date.now();
    return endTime - this.triggeredAt;
  }

  // 格式化持续时间
  getDurationFormatted(): string {
    const ms = this.getDuration();
    const seconds = Math.floor(ms / 1000);
    const minutes = Math.floor(seconds / 60);
    const hours = Math.floor(minutes / 60);
    const days = Math.floor(hours / 24);

    if (days > 0) {
      return `${days}天${hours % 24}小时`;
    } else if (hours > 0) {
      return `${hours}小时${minutes % 60}分`;
    } else if (minutes > 0) {
      return `${minutes}分${seconds % 60}秒`;
    } else {
      return `${seconds}秒`;
    }
  }

  // 格式化时间戳
  static formatTimestamp(ts: number): string {
    if (ts === 0) return '-';
    const date = new Date(ts);
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hour = String(date.getHours()).padStart(2, '0');
    const minute = String(date.getMinutes()).padStart(2, '0');
    const second = String(date.getSeconds()).padStart(2, '0');
    return `${year}-${month}-${day} ${hour}:${minute}:${second}`;
  }

  // 序列化
  serialize(): string {
    return JSON.stringify({
      id: this.id,
      alarmCode: this.alarmCode,
      description: this.description,
      alarmType: this.alarmType,
      status: this.status,
      triggeredAt: this.triggeredAt,
      acknowledgedAt: this.acknowledgedAt,
      clearedAt: this.clearedAt,
      acknowledgedBy: this.acknowledgedBy,
      clearedBy: this.clearedBy,
      extraInfo: this.extraInfo
    });
  }

  // 反序列化
  static deserialize(data: string): AlarmRecord {
    interface AlarmRecordData {
      id: string;
      alarmCode: AlarmCode;
      description: string;
      alarmType: AlarmType;
      status: AlarmStatus;
      triggeredAt: number;
      acknowledgedAt: number;
      clearedAt: number;
      acknowledgedBy: string;
      clearedBy: string;
      extraInfo: string;
    }
    const obj: AlarmRecordData = JSON.parse(data) as AlarmRecordData;
    const record = new AlarmRecord(obj.alarmCode, obj.extraInfo);
    record.id = obj.id;
    record.description = obj.description;
    record.alarmType = obj.alarmType;
    record.status = obj.status;
    record.triggeredAt = obj.triggeredAt;
    record.acknowledgedAt = obj.acknowledgedAt;
    record.clearedAt = obj.clearedAt;
    record.acknowledgedBy = obj.acknowledgedBy;
    record.clearedBy = obj.clearedBy;
    return record;
  }
}
