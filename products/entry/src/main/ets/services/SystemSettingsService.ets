import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { systemTime } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import {
  NetworkMode,
  NetworkRuntimeInfo,
  NetworkSettingsConfig,
  NetworkSettingsLoadResult
} from '../models/systemSettingsTypes';

const DOMAIN = 0x0003;
const TAG = 'SystemSettingsService';

const PREFERENCES_NAME = 'waterquality_system_settings';
const KEY_IFACE = 'network_iface';
const KEY_MODE = 'network_mode';
const KEY_IP = 'network_ip';
const KEY_NET_MASK = 'network_net_mask';
const KEY_GATEWAY = 'network_gateway';
const KEY_DNS1 = 'network_dns1';
const KEY_DNS2 = 'network_dns2';

const DEFAULT_IFACE = 'eth1';
const ETHERNET_MODULE_NAME = 'net.ethernet';
const STATIC_MODE = 0;
const DHCP_MODE = 1;
const LAN_STATIC_MODE = 2;
const LAN_DHCP_MODE = 3;

interface EthernetIfaceConfig {
  mode: number;
  ipAddr: string;
  routeAddr?: string;
  maskAddr?: string;
  gateAddr?: string;
  dnsAddr0?: string;
  dnsAddr1?: string;
  dns0Addr?: string;
  dns1Addr?: string;
  route?: string;
  netMask?: string;
  gateway?: string;
  dnsServers?: string;
  domain?: string;
}

interface EthernetSystemApi {
  getIfaceConfig: (iface: string) => Promise<EthernetIfaceConfig>;
  setIfaceConfig: (iface: string, config: EthernetIfaceConfig) => Promise<void>;
}

export interface DateTimeParts {
  year: number;
  month: number;
  day: number;
  hour: number;
  minute: number;
  second: number;
}

const DEFAULT_NETWORK_CONFIG: NetworkSettingsConfig = {
  iface: DEFAULT_IFACE,
  mode: 'dhcp',
  ip: '',
  netMask: '',
  gateway: '',
  dns1: '',
  dns2: ''
};

export class SystemSettingsService {
  static getDefaultNetworkConfig(): NetworkSettingsConfig {
    return SystemSettingsService.copyNetworkConfig(DEFAULT_NETWORK_CONFIG);
  }

  static async loadNetworkConfig(context: common.Context): Promise<NetworkSettingsLoadResult> {
    try {
      const store = preferences.getPreferencesSync(context, { name: PREFERENCES_NAME });
      if (store.hasSync(KEY_MODE)) {
        return {
          config: {
            iface: SystemSettingsService.readString(store, KEY_IFACE, DEFAULT_IFACE),
            mode: SystemSettingsService.readNetworkMode(store, KEY_MODE, DEFAULT_NETWORK_CONFIG.mode),
            ip: SystemSettingsService.readString(store, KEY_IP, ''),
            netMask: SystemSettingsService.readString(store, KEY_NET_MASK, ''),
            gateway: SystemSettingsService.readString(store, KEY_GATEWAY, ''),
            dns1: SystemSettingsService.readString(store, KEY_DNS1, ''),
            dns2: SystemSettingsService.readString(store, KEY_DNS2, '')
          },
          fromPersistence: true
        };
      }
    } catch (err) {
      hilog.warn(DOMAIN, TAG, '读取网络配置持久化失败: %{public}s', JSON.stringify(err));
    }

    const systemConfig = await SystemSettingsService.readSystemNetworkConfig(DEFAULT_IFACE);
    if (systemConfig) {
      return {
        config: systemConfig,
        fromPersistence: false
      };
    }

    return {
      config: SystemSettingsService.getDefaultNetworkConfig(),
      fromPersistence: false
    };
  }

  static async saveNetworkConfig(context: common.Context, config: NetworkSettingsConfig): Promise<boolean> {
    const normalizedConfig = SystemSettingsService.normalizeNetworkConfig(config);
    if (!SystemSettingsService.isValidNetworkConfig(normalizedConfig)) {
      hilog.error(DOMAIN, TAG, '保存网络配置失败: 参数无效');
      return false;
    }

    const applied = await SystemSettingsService.applyNetworkConfig(normalizedConfig);
    if (!applied) {
      return false;
    }

    try {
      const store = preferences.getPreferencesSync(context, { name: PREFERENCES_NAME });
      store.putSync(KEY_IFACE, normalizedConfig.iface);
      store.putSync(KEY_MODE, normalizedConfig.mode);
      store.putSync(KEY_IP, normalizedConfig.ip);
      store.putSync(KEY_NET_MASK, normalizedConfig.netMask);
      store.putSync(KEY_GATEWAY, normalizedConfig.gateway);
      store.putSync(KEY_DNS1, normalizedConfig.dns1);
      store.putSync(KEY_DNS2, normalizedConfig.dns2);
      await store.flush();
      hilog.info(DOMAIN, TAG, '网络配置已保存: iface=%{public}s mode=%{public}s', normalizedConfig.iface,
        normalizedConfig.mode);
      return true;
    } catch (err) {
      hilog.error(DOMAIN, TAG, '网络配置持久化失败: %{public}s', JSON.stringify(err));
      return false;
    }
  }

  static async readRuntimeNetworkInfo(iface: string): Promise<NetworkRuntimeInfo | null> {
    const config = await SystemSettingsService.readSystemNetworkConfig(iface);
    if (!config) {
      return null;
    }
    return {
      ip: config.ip,
      netMask: config.netMask,
      gateway: config.gateway,
      dns1: config.dns1,
      dns2: config.dns2
    };
  }

  static async setSystemDateTime(dateText: string, timeText: string): Promise<boolean> {
    const timestamp = SystemSettingsService.parseDateTime(dateText, timeText);
    if (timestamp < 0) {
      hilog.error(DOMAIN, TAG, '设置系统时间失败: 日期时间格式无效');
      return false;
    }

    try {
      await systemTime.setTime(timestamp);
      hilog.info(DOMAIN, TAG, '系统时间已设置: %{public}s %{public}s', dateText, timeText);
      return true;
    } catch (err) {
      hilog.error(DOMAIN, TAG, '设置系统时间失败: %{public}s', JSON.stringify(err));
      return false;
    }
  }

  static formatDate(date: Date): string {
    return `${SystemSettingsService.padNumber(date.getFullYear(), 4)}-${SystemSettingsService.padNumber(date.getMonth() + 1, 2)}-${SystemSettingsService.padNumber(date.getDate(), 2)}`;
  }

  static formatTime(date: Date): string {
    return `${SystemSettingsService.padNumber(date.getHours(), 2)}:${SystemSettingsService.padNumber(date.getMinutes(), 2)}:${SystemSettingsService.padNumber(date.getSeconds(), 2)}`;
  }

  static parseDateTimeParts(dateText: string, timeText: string): DateTimeParts | null {
    const parts = SystemSettingsService.readDateTimeParts(dateText, timeText);
    if (!parts) {
      return null;
    }

    const date = new Date(parts.year, parts.month - 1, parts.day, parts.hour, parts.minute, parts.second, 0);
    if (date.getFullYear() !== parts.year || date.getMonth() !== parts.month - 1 ||
      date.getDate() !== parts.day || date.getHours() !== parts.hour ||
      date.getMinutes() !== parts.minute || date.getSeconds() !== parts.second) {
      return null;
    }
    return parts;
  }

  private static async applyNetworkConfig(config: NetworkSettingsConfig): Promise<boolean> {
    try {
      const ifaceConfig = SystemSettingsService.toEthernetIfaceConfig(config);
      const api = SystemSettingsService.getEthernetApi();
      await api.setIfaceConfig(config.iface, ifaceConfig);
      hilog.info(DOMAIN, TAG, '以太网配置已下发: iface=%{public}s mode=%{public}s', config.iface, config.mode);
      return true;
    } catch (err) {
      hilog.error(DOMAIN, TAG, '设置网络配置失败: %{public}s', JSON.stringify(err));
      return false;
    }
  }

  private static async readSystemNetworkConfig(iface: string): Promise<NetworkSettingsConfig | null> {
    try {
      const api = SystemSettingsService.getEthernetApi();
      const config: EthernetIfaceConfig = await api.getIfaceConfig(iface);
      return SystemSettingsService.fromEthernetIfaceConfig(iface, config);
    } catch (err) {
      hilog.warn(DOMAIN, TAG, '读取网络配置失败: %{public}s', JSON.stringify(err));
      return null;
    }
  }

  private static getEthernetApi(): EthernetSystemApi {
    const nativeModule: Object = loadNativeModule(ETHERNET_MODULE_NAME);
    return nativeModule as EthernetSystemApi;
  }

  private static toEthernetIfaceConfig(config: NetworkSettingsConfig): EthernetIfaceConfig {
    const isStaticMode = config.mode === 'static';
    return {
      mode: SystemSettingsService.getIpSetMode(config.mode),
      ipAddr: isStaticMode ? config.ip : '',
      routeAddr: isStaticMode ? config.gateway : '',
      maskAddr: isStaticMode ? config.netMask : '',
      gateAddr: isStaticMode ? config.gateway : '',
      dnsAddr0: isStaticMode ? config.dns1 : '',
      dnsAddr1: isStaticMode ? config.dns2 : ''
    };
  }

  private static fromEthernetIfaceConfig(
    iface: string,
    config: EthernetIfaceConfig
  ): NetworkSettingsConfig {
    const dnsServers = SystemSettingsService.splitDnsServers(SystemSettingsService.optionalText(config.dnsServers));
    const firstDns = SystemSettingsService.pickText(config.dnsAddr0, config.dns0Addr);
    const secondDns = SystemSettingsService.pickText(config.dnsAddr1, config.dns1Addr);
    return {
      iface: iface,
      mode: SystemSettingsService.getNetworkMode(config.mode),
      ip: SystemSettingsService.trimValue(config.ipAddr),
      netMask: SystemSettingsService.pickText(config.maskAddr, config.netMask),
      gateway: SystemSettingsService.pickText(config.gateAddr, config.gateway),
      dns1: firstDns.length > 0 ? firstDns : dnsServers[0],
      dns2: secondDns.length > 0 ? secondDns : dnsServers[1]
    };
  }

  private static getIpSetMode(mode: NetworkMode): number {
    return mode === 'static' ? STATIC_MODE : DHCP_MODE;
  }

  private static getNetworkMode(mode: number): NetworkMode {
    if (mode === DHCP_MODE || mode === LAN_DHCP_MODE) {
      return 'dhcp';
    }
    if (mode === STATIC_MODE || mode === LAN_STATIC_MODE) {
      return 'static';
    }
    return 'static';
  }

  private static normalizeNetworkConfig(config: NetworkSettingsConfig): NetworkSettingsConfig {
    const normalizedMode: NetworkMode = config.mode === 'static' ? 'static' : 'dhcp';
    const normalizedIface = SystemSettingsService.trimValue(config.iface);
    return {
      iface: normalizedIface.length > 0 ? normalizedIface : DEFAULT_IFACE,
      mode: normalizedMode,
      ip: SystemSettingsService.trimValue(config.ip),
      netMask: SystemSettingsService.trimValue(config.netMask),
      gateway: SystemSettingsService.trimValue(config.gateway),
      dns1: SystemSettingsService.trimValue(config.dns1),
      dns2: SystemSettingsService.trimValue(config.dns2)
    };
  }

  private static isValidNetworkConfig(config: NetworkSettingsConfig): boolean {
    if (config.iface.length <= 0) {
      return false;
    }
    if (config.mode === 'dhcp') {
      return true;
    }
    if (!SystemSettingsService.isValidIpv4(config.ip)) {
      return false;
    }
    if (!SystemSettingsService.isValidIpv4(config.netMask)) {
      return false;
    }
    if (!SystemSettingsService.isValidIpv4(config.gateway)) {
      return false;
    }
    if (config.dns1.length > 0 && !SystemSettingsService.isValidIpv4(config.dns1)) {
      return false;
    }
    if (config.dns2.length > 0 && !SystemSettingsService.isValidIpv4(config.dns2)) {
      return false;
    }
    return true;
  }

  private static isValidIpv4(value: string): boolean {
    const parts = value.split('.');
    if (parts.length !== 4) {
      return false;
    }
    for (let i = 0; i < parts.length; i++) {
      if (parts[i].length <= 0) {
        return false;
      }
      if (!SystemSettingsService.isNumberText(parts[i])) {
        return false;
      }
      const num = Number(parts[i]);
      if (num < 0 || num > 255) {
        return false;
      }
      if (parts[i] !== num.toString()) {
        return false;
      }
    }
    return true;
  }

  private static splitDnsServers(dnsServers: string): string[] {
    const dnsList = SystemSettingsService.trimValue(dnsServers).split(',');
    const result: string[] = ['', ''];
    let index = 0;
    for (let i = 0; i < dnsList.length && index < result.length; i++) {
      const dns = SystemSettingsService.trimValue(dnsList[i]);
      if (dns.length > 0) {
        result[index] = dns;
        index++;
      }
    }
    return result;
  }

  private static pickText(firstValue: string | undefined, secondValue: string | undefined): string {
    const firstText = SystemSettingsService.optionalText(firstValue);
    if (firstText.length > 0) {
      return firstText;
    }
    return SystemSettingsService.optionalText(secondValue);
  }

  private static optionalText(value: string | undefined): string {
    if (typeof value === 'string') {
      return SystemSettingsService.trimValue(value);
    }
    return '';
  }

  private static parseDateTime(dateText: string, timeText: string): number {
    const parts = SystemSettingsService.parseDateTimeParts(dateText, timeText);
    if (!parts) {
      return -1;
    }

    const date = new Date(parts.year, parts.month - 1, parts.day, parts.hour, parts.minute, parts.second, 0);
    return date.getTime();
  }

  private static readDateTimeParts(dateText: string, timeText: string): DateTimeParts | null {
    const dateParts = SystemSettingsService.trimValue(dateText).split('-');
    const timeParts = SystemSettingsService.trimValue(timeText).split(':');
    if (dateParts.length !== 3 || timeParts.length !== 3) {
      return null;
    }
    if (!SystemSettingsService.isNumberText(dateParts[0]) || !SystemSettingsService.isNumberText(dateParts[1]) ||
      !SystemSettingsService.isNumberText(dateParts[2]) || !SystemSettingsService.isNumberText(timeParts[0]) ||
      !SystemSettingsService.isNumberText(timeParts[1]) || !SystemSettingsService.isNumberText(timeParts[2])) {
      return null;
    }
    return {
      year: Number(dateParts[0]),
      month: Number(dateParts[1]),
      day: Number(dateParts[2]),
      hour: Number(timeParts[0]),
      minute: Number(timeParts[1]),
      second: Number(timeParts[2])
    };
  }

  private static isNumberText(value: string): boolean {
    if (value.length <= 0) {
      return false;
    }
    for (let i = 0; i < value.length; i++) {
      const code = value.charCodeAt(i);
      if (code < 48 || code > 57) {
        return false;
      }
    }
    return true;
  }

  private static readString(store: preferences.Preferences, key: string, defaultValue: string): string {
    const value = store.getSync(key, defaultValue);
    if (typeof value === 'string') {
      return value;
    }
    return defaultValue;
  }

  private static readNetworkMode(store: preferences.Preferences, key: string, defaultValue: NetworkMode): NetworkMode {
    const value = store.getSync(key, defaultValue);
    if (value === 'static') {
      return 'static';
    }
    return 'dhcp';
  }

  private static copyNetworkConfig(config: NetworkSettingsConfig): NetworkSettingsConfig {
    return {
      iface: config.iface,
      mode: config.mode,
      ip: config.ip,
      netMask: config.netMask,
      gateway: config.gateway,
      dns1: config.dns1,
      dns2: config.dns2
    };
  }

  private static trimValue(value: string): string {
    return value.trim();
  }

  private static padNumber(value: number, length: number): string {
    let text = value.toString();
    while (text.length < length) {
      text = `0${text}`;
    }
    return text;
  }
}
