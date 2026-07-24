// database/preferences/PreferencesUtil.ets
import preferences from '@ohos.data.preferences';

/**
 * 偏好型数据库工具类
 * 提供基础的读写能力，不维护单例状态
 */
export class PreferencesUtil {
  private preferences: preferences.Preferences | null = null;
  private name: string;

  constructor(name: string) {
    this.name = name;
  }

  async init(context: Context): Promise<void> {
    this.preferences = await preferences.getPreferences(context, this.name);
  }

  private getPref(): preferences.Preferences {
    if (this.preferences === null) {
      throw new Error(`Preferences ${this.name} not initialized`);
    }
    return this.preferences;
  }

  async putString(key: string, value: string): Promise<void> {
    await this.getPref().put(key, value);
    await this.getPref().flush();
  }

  async getString(key: string, defaultValue: string = ''): Promise<string> {
    return (await this.getPref().get(key, defaultValue)) as string;
  }

  async putNumber(key: string, value: number): Promise<void> {
    await this.getPref().put(key, value);
    await this.getPref().flush();
  }

  async getNumber(key: string, defaultValue: number = 0): Promise<number> {
    return (await this.getPref().get(key, defaultValue)) as number;
  }

  async putBoolean(key: string, value: boolean): Promise<void> {
    await this.getPref().put(key, value);
    await this.getPref().flush();
  }

  async getBoolean(key: string, defaultValue: boolean = false): Promise<boolean> {
    return (await this.getPref().get(key, defaultValue)) as boolean;
  }

  async putObject<T>(key: string, value: T): Promise<void> {
    const jsonStr = JSON.stringify(value);
    await this.putString(key, jsonStr);
  }

  async getObject<T>(key: string, defaultValue: T): Promise<T> {
    const jsonStr = await this.getString(key);
    if (jsonStr === '') {
      return defaultValue;
    }
    try {
      return JSON.parse(jsonStr) as T;
    } catch {
      return defaultValue;
    }
  }

  async hasKey(key: string): Promise<boolean> {
    return await this.getPref().has(key);
  }

  async delete(key: string): Promise<void> {
    await this.getPref().delete(key);
    await this.getPref().flush();
  }

  async clear(): Promise<void> {
    await this.getPref().clear();
    await this.getPref().flush();
  }
}