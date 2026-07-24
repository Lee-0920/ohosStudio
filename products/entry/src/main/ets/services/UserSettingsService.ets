import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0003;
const TAG = 'UserSettingsService';

const PREFERENCES_NAME = 'waterquality_user_settings';
const SETTING_KEY_PREFIX = 'setting_';

const KEY_REAGENT_REMINDER = 'system-reagent-reminder';
const KEY_LEAK_DETECT = 'system-leak-detect';
const KEY_SAMPLE_EXCEEDED_ALARM = 'external-alarm-enabled';

const SWITCH_ON_TEXT = '开';
const SWITCH_OFF_TEXT = '关';

export interface UserSettingValue {
  key: string;
  value: string;
}

export interface AlarmDisplaySettings {
  reagentReminderEnabled: boolean;
  leakDetectEnabled: boolean;
  sampleExceededAlarmEnabled: boolean;
}

export type UserSettingsListener = () => void;

export class UserSettingsService {
  private static alarmDisplaySettings: AlarmDisplaySettings = UserSettingsService.getDefaultAlarmDisplaySettings();
  private static listeners: UserSettingsListener[] = [];

  static getDefaultAlarmDisplaySettings(): AlarmDisplaySettings {
    return {
      reagentReminderEnabled: false,
      leakDetectEnabled: false,
      sampleExceededAlarmEnabled: false
    };
  }

  static getCachedAlarmDisplaySettings(): AlarmDisplaySettings {
    return UserSettingsService.copyAlarmDisplaySettings(UserSettingsService.alarmDisplaySettings);
  }

  static async loadSettingValues(
    context: common.Context,
    defaults: UserSettingValue[]
  ): Promise<UserSettingValue[]> {
    try {
      const store = preferences.getPreferencesSync(context, { name: PREFERENCES_NAME });
      const values: UserSettingValue[] = [];
      defaults.forEach((item: UserSettingValue) => {
        values.push({
          key: item.key,
          value: UserSettingsService.readString(store, UserSettingsService.toStorageKey(item.key), item.value)
        });
      });
      return values;
    } catch (err) {
      hilog.warn(DOMAIN, TAG, '读取用户设置失败: %{public}s', JSON.stringify(err));
      return UserSettingsService.copySettingValues(defaults);
    }
  }

  static async saveSettingValues(context: common.Context, values: UserSettingValue[]): Promise<boolean> {
    try {
      const store = preferences.getPreferencesSync(context, { name: PREFERENCES_NAME });
      values.forEach((item: UserSettingValue) => {
        store.putSync(UserSettingsService.toStorageKey(item.key), item.value);
      });
      await store.flush();
      return true;
    } catch (err) {
      hilog.error(DOMAIN, TAG, '保存用户设置失败: %{public}s', JSON.stringify(err));
      return false;
    }
  }

  static async loadAlarmDisplaySettings(context: common.Context): Promise<AlarmDisplaySettings> {
    try {
      const store = preferences.getPreferencesSync(context, { name: PREFERENCES_NAME });
      const settings: AlarmDisplaySettings = {
        reagentReminderEnabled: UserSettingsService.readSwitch(
          store,
          UserSettingsService.toStorageKey(KEY_REAGENT_REMINDER),
          false
        ),
        leakDetectEnabled: UserSettingsService.readSwitch(
          store,
          UserSettingsService.toStorageKey(KEY_LEAK_DETECT),
          false
        ),
        sampleExceededAlarmEnabled: UserSettingsService.readSwitch(
          store,
          UserSettingsService.toStorageKey(KEY_SAMPLE_EXCEEDED_ALARM),
          false
        )
      };
      UserSettingsService.alarmDisplaySettings = UserSettingsService.copyAlarmDisplaySettings(settings);
      return settings;
    } catch (err) {
      hilog.warn(DOMAIN, TAG, '读取报警显示设置失败: %{public}s', JSON.stringify(err));
      const defaults = UserSettingsService.getDefaultAlarmDisplaySettings();
      UserSettingsService.alarmDisplaySettings = UserSettingsService.copyAlarmDisplaySettings(defaults);
      return defaults;
    }
  }

  static async saveAlarmDisplaySettings(context: common.Context, settings: AlarmDisplaySettings): Promise<boolean> {
    try {
      const store = preferences.getPreferencesSync(context, { name: PREFERENCES_NAME });
      store.putSync(
        UserSettingsService.toStorageKey(KEY_REAGENT_REMINDER),
        settings.reagentReminderEnabled ? SWITCH_ON_TEXT : SWITCH_OFF_TEXT
      );
      store.putSync(
        UserSettingsService.toStorageKey(KEY_LEAK_DETECT),
        settings.leakDetectEnabled ? SWITCH_ON_TEXT : SWITCH_OFF_TEXT
      );
      store.putSync(
        UserSettingsService.toStorageKey(KEY_SAMPLE_EXCEEDED_ALARM),
        settings.sampleExceededAlarmEnabled ? SWITCH_ON_TEXT : SWITCH_OFF_TEXT
      );
      await store.flush();
      UserSettingsService.alarmDisplaySettings = UserSettingsService.copyAlarmDisplaySettings(settings);
      UserSettingsService.notifyListeners();
      return true;
    } catch (err) {
      hilog.error(DOMAIN, TAG, '保存报警显示设置失败: %{public}s', JSON.stringify(err));
      return false;
    }
  }

  static createAlarmDisplaySettings(
    reagentReminderText: string,
    leakDetectText: string,
    sampleExceededAlarmText: string
  ): AlarmDisplaySettings {
    return {
      reagentReminderEnabled: UserSettingsService.isSwitchOn(reagentReminderText),
      leakDetectEnabled: UserSettingsService.isSwitchOn(leakDetectText),
      sampleExceededAlarmEnabled: UserSettingsService.isSwitchOn(sampleExceededAlarmText)
    };
  }

  static addListener(listener: UserSettingsListener): void {
    if (UserSettingsService.listeners.indexOf(listener) >= 0) {
      return;
    }
    UserSettingsService.listeners.push(listener);
  }

  static removeListener(listener: UserSettingsListener): void {
    UserSettingsService.listeners = UserSettingsService.listeners.filter((item: UserSettingsListener) => {
      return item !== listener;
    });
  }

  private static notifyListeners(): void {
    UserSettingsService.listeners.forEach((listener: UserSettingsListener) => {
      listener();
    });
  }

  private static toStorageKey(key: string): string {
    return `${SETTING_KEY_PREFIX}${key}`;
  }

  private static readString(store: preferences.Preferences, key: string, defaultValue: string): string {
    const value = store.getSync(key, defaultValue);
    if (typeof value === 'string') {
      return value;
    }
    return defaultValue;
  }

  private static readSwitch(store: preferences.Preferences, key: string, defaultValue: boolean): boolean {
    const defaultText = defaultValue ? SWITCH_ON_TEXT : SWITCH_OFF_TEXT;
    return UserSettingsService.isSwitchOn(UserSettingsService.readString(store, key, defaultText));
  }

  private static isSwitchOn(value: string): boolean {
    return value.trim() === SWITCH_ON_TEXT;
  }

  private static copyAlarmDisplaySettings(settings: AlarmDisplaySettings): AlarmDisplaySettings {
    return {
      reagentReminderEnabled: settings.reagentReminderEnabled,
      leakDetectEnabled: settings.leakDetectEnabled,
      sampleExceededAlarmEnabled: settings.sampleExceededAlarmEnabled
    };
  }

  private static copySettingValues(values: UserSettingValue[]): UserSettingValue[] {
    const copied: UserSettingValue[] = [];
    values.forEach((item: UserSettingValue) => {
      copied.push({
        key: item.key,
        value: item.value
      });
    });
    return copied;
  }
}
