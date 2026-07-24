import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0003;
const TAG = 'OperationRecordService';
const PREFERENCES_NAME = 'waterquality_operation_records';

export interface OperationRecordValue {
  id: string;
  value: string;
  value2: string;
  value3: string;
  value4: string;
}

export class OperationRecordService {
  static async loadValues(
    context: common.Context,
    group: string,
    defaults: OperationRecordValue[]
  ): Promise<OperationRecordValue[]> {
    try {
      const store = preferences.getPreferencesSync(context, { name: PREFERENCES_NAME });
      const values: OperationRecordValue[] = [];
      defaults.forEach((item: OperationRecordValue) => {
        values.push({
          id: item.id,
          value: OperationRecordService.readString(store, OperationRecordService.toStorageKey(group, item.id, 'value'), item.value),
          value2: OperationRecordService.readString(store, OperationRecordService.toStorageKey(group, item.id, 'value2'), item.value2),
          value3: OperationRecordService.readString(store, OperationRecordService.toStorageKey(group, item.id, 'value3'), item.value3),
          value4: OperationRecordService.readString(store, OperationRecordService.toStorageKey(group, item.id, 'value4'), item.value4)
        });
      });
      return values;
    } catch (err) {
      hilog.warn(DOMAIN, TAG, '读取运维本地记录失败: %{public}s', JSON.stringify(err));
      return OperationRecordService.copyValues(defaults);
    }
  }

  static async saveValues(
    context: common.Context,
    group: string,
    values: OperationRecordValue[]
  ): Promise<boolean> {
    try {
      const store = preferences.getPreferencesSync(context, { name: PREFERENCES_NAME });
      values.forEach((item: OperationRecordValue) => {
        store.putSync(OperationRecordService.toStorageKey(group, item.id, 'value'), item.value);
        store.putSync(OperationRecordService.toStorageKey(group, item.id, 'value2'), item.value2);
        store.putSync(OperationRecordService.toStorageKey(group, item.id, 'value3'), item.value3);
        store.putSync(OperationRecordService.toStorageKey(group, item.id, 'value4'), item.value4);
      });
      await store.flush();
      return true;
    } catch (err) {
      hilog.error(DOMAIN, TAG, '保存运维本地记录失败: %{public}s', JSON.stringify(err));
      return false;
    }
  }

  private static toStorageKey(group: string, id: string, field: string): string {
    return `${group}_${id}_${field}`;
  }

  private static readString(store: preferences.Preferences, key: string, defaultValue: string): string {
    const value = store.getSync(key, defaultValue);
    if (typeof value === 'string') {
      return value;
    }
    return defaultValue;
  }

  private static copyValues(values: OperationRecordValue[]): OperationRecordValue[] {
    const copied: OperationRecordValue[] = [];
    values.forEach((item: OperationRecordValue) => {
      copied.push({
        id: item.id,
        value: item.value,
        value2: item.value2,
        value3: item.value3,
        value4: item.value4
      });
    });
    return copied;
  }
}
