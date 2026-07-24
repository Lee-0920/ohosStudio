export type SettingFieldSource = 'local' | 'deviceWritable' | 'deviceReadOnly';

const DEVICE_WRITABLE_MEASUREMENT_FIELDS: string[] = [
  'measure-current-range',
  'measure-digestion-temp',
  'measure-digestion-time',
  'measure-reaction-temp',
  'measure-reaction-time'
];

const DEVICE_READ_ONLY_MEASUREMENT_FIELDS: string[] = [
  // 量程一/二/三的设备写入映射尚未确认，当前保留为本地可编辑字段，不归入设备只读字段。
  'measure-slope',
  'measure-intercept',
  'measure-calibration-time',
  'measure-zero-liquid',
  'measure-range-liquid',
  'measure-check-limit'
];

export class SettingConfigPolicy {
  static createRowRenderKey(rowId: string, value: string, control: string): string {
    return `${rowId}:${value}:${control}`;
  }

  static createScheduleRenderKey(version: number): string {
    return `measurement-schedule:${version}`;
  }

  static getMeasurementFieldSource(rowId: string): SettingFieldSource {
    if (DEVICE_WRITABLE_MEASUREMENT_FIELDS.indexOf(rowId) >= 0) {
      return 'deviceWritable';
    }
    if (DEVICE_READ_ONLY_MEASUREMENT_FIELDS.indexOf(rowId) >= 0) {
      return 'deviceReadOnly';
    }
    return 'local';
  }

  static shouldLoadPersistedMeasurementValue(rowId: string): boolean {
    return SettingConfigPolicy.getMeasurementFieldSource(rowId) === 'local';
  }

  static shouldResetMeasurementValue(rowId: string): boolean {
    return SettingConfigPolicy.getMeasurementFieldSource(rowId) !== 'deviceReadOnly';
  }

  static resolveCheckDeviationValue(
    _allowedDeviation: number | null,
    deviation: number | null
  ): number | null {
    // 设置页“核查偏差限值”按项目约定展示寄存器 314 的实际核查偏差，不使用 312 的允许偏差。
    return deviation;
  }

  static resolveCurrentRangeName(
    currentRange: number,
    rangeOneUpperLimit: number | null,
    rangeTwoUpperLimit: number | null,
    rangeThreeUpperLimit: number | null
  ): string {
    const names: string[] = ['量程一', '量程二', '量程三'];
    const upperLimits: (number | null)[] = [
      rangeOneUpperLimit,
      rangeTwoUpperLimit,
      rangeThreeUpperLimit
    ];
    for (let i = 0; i < upperLimits.length; i++) {
      const upperLimit = upperLimits[i];
      if (upperLimit !== null && Math.abs(upperLimit - currentRange) < 0.001) {
        return names[i];
      }
    }
    return '';
  }
}
