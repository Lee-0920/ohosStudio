// products/entry/src/main/ets/services/CommunicationConfigService.ets

import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import {
  CommunicationConfig,
  CommunicationConfigApplyResult,
  CommunicationConfigLoadResult,
  CommunicationConfigMode,
  UartParity
} from '../models/communicationConfigTypes';
import { MonitorService } from './MonitorService';
import { getGlobalModbusServer, TcpConfig, SerialConfig } from 'modbus';

const DOMAIN = 0x0003;
const TAG = 'CommunicationConfigService';

const PREFERENCES_NAME = 'waterquality_communication_config';
const CONFIG_SCHEMA_VERSION = 1;
const KEY_SCHEMA_VERSION = 'schema_version';
const KEY_MODE = 'mode';
const KEY_TCP_IP = 'tcp_ip';
const KEY_TCP_PORT = 'tcp_port';
const KEY_UART_PATH = 'uart_path';
const KEY_UART_BAUD_RATE = 'uart_baud_rate';
const KEY_UART_DATA_BITS = 'uart_data_bits';
const KEY_UART_STOP_BITS = 'uart_stop_bits';
const KEY_UART_PARITY = 'uart_parity';
const KEY_UART_IS_RS485 = 'uart_is_rs485';

const DEFAULT_TCP_IP = '192.168.0.110';
const DEFAULT_TCP_PORT = 502;
const DEFAULT_UART_PATH = '/dev/ttyS0';
const DEFAULT_UART_BAUD_RATE = 9600;
const DEFAULT_UART_DATA_BITS = 8;
const DEFAULT_UART_STOP_BITS = 1;
const DEFAULT_UART_PARITY: UartParity = 'N';

/**
 * 业务通信配置持久化服务。
 *
 * 配置属于整台仪器，不随登录用户变化。启动时必须先初始化本服务并把配置应用到
 * MonitorService，再启动设备轮询和自动连接。
 */
export class CommunicationConfigService {
  private static initialized: boolean = false;
  private static initializationPromise: Promise<CommunicationConfigLoadResult> | null = null;
  private static cachedConfig: CommunicationConfig = CommunicationConfigService.getDefaultConfig();
  private static lastLoadResult: CommunicationConfigLoadResult = {
    config: CommunicationConfigService.getDefaultConfig(),
    fromPersistence: false,
    fallbackToDefaults: false
  };

  static getDefaultConfig(): CommunicationConfig {
    return {
      mode: 'uart',
      tcpIp: DEFAULT_TCP_IP,
      tcpPort: DEFAULT_TCP_PORT,
      uartPath: DEFAULT_UART_PATH,
      uartBaudRate: DEFAULT_UART_BAUD_RATE,
      uartDataBits: DEFAULT_UART_DATA_BITS,
      uartStopBits: DEFAULT_UART_STOP_BITS,
      uartParity: DEFAULT_UART_PARITY,
      uartIsRs485: false
    };
  }

  static getCachedConfig(): CommunicationConfig {
    return CommunicationConfigService.copyConfig(CommunicationConfigService.cachedConfig);
  }

  static async initialize(context: common.Context): Promise<CommunicationConfigLoadResult> {
    if (CommunicationConfigService.initialized) {
      return {
        config: CommunicationConfigService.getCachedConfig(),
        fromPersistence: CommunicationConfigService.lastLoadResult.fromPersistence,
        fallbackToDefaults: CommunicationConfigService.lastLoadResult.fallbackToDefaults
      };
    }
    if (CommunicationConfigService.initializationPromise) {
      return CommunicationConfigService.initializationPromise;
    }

    CommunicationConfigService.initializationPromise =
      CommunicationConfigService.initializeInternal(context);
    try {
      return await CommunicationConfigService.initializationPromise;
    } finally {
      CommunicationConfigService.initializationPromise = null;
    }
  }

  static normalizeConfig(config: CommunicationConfig): CommunicationConfig {
    const parityText: string = config.uartParity.trim().toUpperCase();
    const parity: UartParity = CommunicationConfigService.toParity(parityText, config.uartParity);
    return {
      mode: config.mode === 'uart' ? 'uart' : 'tcp',
      tcpIp: config.tcpIp.trim(),
      tcpPort: config.tcpPort,
      uartPath: config.uartPath.trim(),
      uartBaudRate: config.uartBaudRate,
      uartDataBits: config.uartDataBits,
      uartStopBits: config.uartStopBits,
      uartParity: parity,
      uartIsRs485: config.uartIsRs485
    };
  }

  static isValidConfig(config: CommunicationConfig): boolean {
    return config.tcpIp.length > 0 &&
    CommunicationConfigService.isIntegerInRange(config.tcpPort, 1, 65535) &&
      config.uartPath.length > 0 &&
    CommunicationConfigService.isIntegerInRange(config.uartBaudRate, 1, 4000000) &&
      (config.uartDataBits === 7 || config.uartDataBits === 8) &&
      (config.uartStopBits === 1 || config.uartStopBits === 2) &&
      (config.uartParity === 'N' || config.uartParity === 'E' || config.uartParity === 'O');
  }

  static areConfigsEqual(left: CommunicationConfig, right: CommunicationConfig): boolean {
    return left.mode === right.mode &&
      left.tcpIp === right.tcpIp &&
      left.tcpPort === right.tcpPort &&
      left.uartPath === right.uartPath &&
      left.uartBaudRate === right.uartBaudRate &&
      left.uartDataBits === right.uartDataBits &&
      left.uartStopBits === right.uartStopBits &&
      left.uartParity === right.uartParity &&
      left.uartIsRs485 === right.uartIsRs485;
  }

  static resolvePersistedConfig(
    config: CommunicationConfig | null,
    schemaVersion: number
  ): CommunicationConfigLoadResult {
    if (!config || schemaVersion !== CONFIG_SCHEMA_VERSION) {
      return CommunicationConfigService.defaultLoadResult(false);
    }
    const normalized: CommunicationConfig = CommunicationConfigService.normalizeConfig(config);
    if (!CommunicationConfigService.isValidConfig(normalized)) {
      return CommunicationConfigService.defaultLoadResult(true);
    }
    return {
      config: normalized,
      fromPersistence: true,
      fallbackToDefaults: false
    };
  }

  static async saveAndApply(
    context: common.Context,
    config: CommunicationConfig
  ): Promise<CommunicationConfigApplyResult> {
    if (!CommunicationConfigService.initialized) {
      await CommunicationConfigService.initialize(context);
    }

    const normalized: CommunicationConfig = CommunicationConfigService.normalizeConfig(config);
    if (!CommunicationConfigService.isValidConfig(normalized)) {
      return CommunicationConfigService.createApplyResult(
        false,
        false,
        false,
        CommunicationConfigService.getCachedConfig(),
        '通信配置参数无效'
      );
    }

    const previous: CommunicationConfig = CommunicationConfigService.getCachedConfig();
    const changed: boolean = !CommunicationConfigService.areConfigsEqual(previous, normalized);
    const persisted: boolean = await CommunicationConfigService.persistConfig(context, normalized);
    if (!persisted) {
      return CommunicationConfigService.createApplyResult(
        false,
        false,
        false,
        previous,
        '通信配置保存失败'
      );
    }

    const disconnectedPreviousConnection: boolean = changed && MonitorService.isConnectedToMcu();
    if (changed) {
      // 配置切换必须同时取消已在线或正在建立的旧通道，避免旧参数连接在保存完成后反向覆盖状态。
      MonitorService.disconnect();
      CommunicationConfigService.applyToMonitorService(normalized);
      CommunicationConfigService.applyToModbusServer(normalized);
    }
    CommunicationConfigService.cachedConfig = CommunicationConfigService.copyConfig(normalized);
    hilog.info(
      DOMAIN,
      TAG,
      '通信配置已保存并应用: mode=%{public}s tcp=%{public}s:%{public}d uart=%{public}s/%{public}d/%{public}s',
      normalized.mode,
      normalized.tcpIp,
      normalized.tcpPort,
      normalized.uartPath,
      normalized.uartBaudRate,
      normalized.uartIsRs485 ? 'RS485' : 'RS232'
    );
    return CommunicationConfigService.createApplyResult(
      true,
      changed,
      disconnectedPreviousConnection,
      normalized,
      ''
    );
  }

  private static async initializeInternal(context: common.Context): Promise<CommunicationConfigLoadResult> {
    const result: CommunicationConfigLoadResult = CommunicationConfigService.loadConfig(context);
    CommunicationConfigService.cachedConfig = CommunicationConfigService.copyConfig(result.config);
    CommunicationConfigService.lastLoadResult = {
      config: CommunicationConfigService.copyConfig(result.config),
      fromPersistence: result.fromPersistence,
      fallbackToDefaults: result.fallbackToDefaults
    };
    CommunicationConfigService.applyToMonitorService(result.config);
    CommunicationConfigService.applyToModbusServer(result.config);
    CommunicationConfigService.initialized = true;
    hilog.info(
      DOMAIN,
      TAG,
      '通信配置初始化完成: source=%{public}s mode=%{public}s tcp=%{public}s:%{public}d uart=%{public}s/%{public}d',
      result.fromPersistence ? 'preferences' : 'defaults',
      result.config.mode,
      result.config.tcpIp,
      result.config.tcpPort,
      result.config.uartPath,
      result.config.uartBaudRate
    );
    return result;
  }

  private static loadConfig(context: common.Context): CommunicationConfigLoadResult {
    try {
      const store: preferences.Preferences = preferences.getPreferencesSync(context, { name: PREFERENCES_NAME });
      const schemaVersion: number = CommunicationConfigService.readNumber(store, KEY_SCHEMA_VERSION, 0);
      if (schemaVersion !== CONFIG_SCHEMA_VERSION) {
        return CommunicationConfigService.resolvePersistedConfig(null, schemaVersion);
      }

      const defaults: CommunicationConfig = CommunicationConfigService.getDefaultConfig();
      const loaded: CommunicationConfig = {
        mode: CommunicationConfigService.readMode(store, KEY_MODE, defaults.mode),
        tcpIp: CommunicationConfigService.readString(store, KEY_TCP_IP, defaults.tcpIp),
        tcpPort: CommunicationConfigService.readNumber(store, KEY_TCP_PORT, defaults.tcpPort),
        uartPath: CommunicationConfigService.readString(store, KEY_UART_PATH, defaults.uartPath),
        uartBaudRate: CommunicationConfigService.readNumber(
          store,
          KEY_UART_BAUD_RATE,
          defaults.uartBaudRate
        ),
        uartDataBits: CommunicationConfigService.readNumber(store, KEY_UART_DATA_BITS, defaults.uartDataBits),
        uartStopBits: CommunicationConfigService.readNumber(store, KEY_UART_STOP_BITS, defaults.uartStopBits),
        uartParity: CommunicationConfigService.readParity(store, KEY_UART_PARITY, defaults.uartParity),
        uartIsRs485: CommunicationConfigService.readBoolean(store, KEY_UART_IS_RS485, defaults.uartIsRs485)
      };
      const result: CommunicationConfigLoadResult = CommunicationConfigService.resolvePersistedConfig(loaded, schemaVersion);
      if (result.fallbackToDefaults) {
        hilog.warn(DOMAIN, TAG, '持久化通信配置无效，已回退默认值');
      }
      return result;
    } catch (err) {
      hilog.warn(DOMAIN, TAG, '读取通信配置失败，已回退默认值: %{public}s', JSON.stringify(err));
      return CommunicationConfigService.defaultLoadResult(true);
    }
  }

  private static async persistConfig(context: common.Context, config: CommunicationConfig): Promise<boolean> {
    try {
      const store: preferences.Preferences = preferences.getPreferencesSync(context, { name: PREFERENCES_NAME });
      store.putSync(KEY_SCHEMA_VERSION, CONFIG_SCHEMA_VERSION);
      store.putSync(KEY_MODE, config.mode);
      store.putSync(KEY_TCP_IP, config.tcpIp);
      store.putSync(KEY_TCP_PORT, config.tcpPort);
      store.putSync(KEY_UART_PATH, config.uartPath);
      store.putSync(KEY_UART_BAUD_RATE, config.uartBaudRate);
      store.putSync(KEY_UART_DATA_BITS, config.uartDataBits);
      store.putSync(KEY_UART_STOP_BITS, config.uartStopBits);
      store.putSync(KEY_UART_PARITY, config.uartParity);
      store.putSync(KEY_UART_IS_RS485, config.uartIsRs485);
      await store.flush();
      return true;
    } catch (err) {
      hilog.error(DOMAIN, TAG, '保存通信配置失败: %{public}s', JSON.stringify(err));
      return false;
    }
  }

  private static applyToMonitorService(config: CommunicationConfig): void {
    MonitorService.setMcuConfig(config.tcpIp, config.tcpPort);
    MonitorService.setUartConfig(
      config.uartPath,
      config.uartBaudRate,
      config.uartDataBits,
      config.uartStopBits,
      config.uartParity,
      config.uartIsRs485
    );
    MonitorService.setMode(config.mode);
  }

  /**
   * 将通信配置同步到 ModbusServer
   * 使用新的 setTcpConfig 和 setSerialConfig 方法
   */
  private static applyToModbusServer(config: CommunicationConfig): void {
    const server = getGlobalModbusServer();
    if (!server) {
      hilog.warn(DOMAIN, TAG, 'ModbusServer not available, skipping config sync');
      return;
    }

    // 同步 TCP 配置
    const tcpConfig: TcpConfig = {
      address: config.tcpIp,
      port: config.tcpPort
    };
    server.setTcpConfig(tcpConfig);
    hilog.info(DOMAIN, TAG, 'TCP config synced: %s:%d', config.tcpIp, config.tcpPort);

    // 同步串口配置
    const parityMap: Record<UartParity, number> = {
      'N': 0,
      'E': 1,
      'O': 2
    };
    const serialConfig: SerialConfig = {
      path: config.uartPath,
      baudRate: config.uartBaudRate,
      dataBits: config.uartDataBits,
      stopBits: config.uartStopBits,
      parity: parityMap[config.uartParity] ?? 0
    };
    server.setSerialConfig(serialConfig);
    hilog.info(DOMAIN, TAG, 'Serial config synced: %s %d-%d-%d parity=%d',
      config.uartPath, config.uartBaudRate, config.uartDataBits,
      config.uartStopBits, parityMap[config.uartParity] ?? 0);

    // 根据当前模式应用对应的配置
    if (config.mode === 'tcp') {
      // 异步重启 TCP 服务器
      server.applyTcpConfig().then((success: boolean) => {
        hilog.info(DOMAIN, TAG, 'TCP server restart %{public}s', success ? 'success' : 'failed');
      }).catch((err: Error) => {
        hilog.error(DOMAIN, TAG, 'TCP server restart error: %{public}s', err.message);
      });
    } else {
      // 应用串口配置
      const success: boolean = server.applySerialConfig();
      hilog.info(DOMAIN, TAG, 'Serial config applied: %{public}s', success ? 'success' : 'failed');
    }
  }

  private static mapParityToNumber(parity: UartParity): number {
    switch (parity) {
      case 'N': return 0;
      case 'E': return 1;
      case 'O': return 2;
      default: return 0;
    }
  }

  private static defaultLoadResult(fallbackToDefaults: boolean): CommunicationConfigLoadResult {
    return {
      config: CommunicationConfigService.getDefaultConfig(),
      fromPersistence: false,
      fallbackToDefaults: fallbackToDefaults
    };
  }

  private static createApplyResult(
    success: boolean,
    changed: boolean,
    disconnectedPreviousConnection: boolean,
    config: CommunicationConfig,
    errorMessage: string
  ): CommunicationConfigApplyResult {
    return {
      success: success,
      changed: changed,
      disconnectedPreviousConnection: disconnectedPreviousConnection,
      config: CommunicationConfigService.copyConfig(config),
      errorMessage: errorMessage
    };
  }

  private static copyConfig(config: CommunicationConfig): CommunicationConfig {
    const result: CommunicationConfig = {
      mode: config.mode,
      tcpIp: config.tcpIp,
      tcpPort: config.tcpPort,
      uartPath: config.uartPath,
      uartBaudRate: config.uartBaudRate,
      uartDataBits: config.uartDataBits,
      uartStopBits: config.uartStopBits,
      uartParity: config.uartParity,
      uartIsRs485: config.uartIsRs485
    };
    return result;
  }

  private static isIntegerInRange(value: number, min: number, max: number): boolean {
    return Number.isInteger(value) && value >= min && value <= max;
  }

  private static readString(store: preferences.Preferences, key: string, defaultValue: string): string {
    const value = store.getSync(key, defaultValue);
    return typeof value === 'string' ? value : defaultValue;
  }

  private static readNumber(store: preferences.Preferences, key: string, defaultValue: number): number {
    const value = store.getSync(key, defaultValue);
    return typeof value === 'number' ? value : defaultValue;
  }

  private static readBoolean(store: preferences.Preferences, key: string, defaultValue: boolean): boolean {
    const value = store.getSync(key, defaultValue);
    return typeof value === 'boolean' ? value : defaultValue;
  }

  private static readMode(
    store: preferences.Preferences,
    key: string,
    defaultValue: CommunicationConfigMode
  ): CommunicationConfigMode {
    const value: string = CommunicationConfigService.readString(store, key, defaultValue);
    return value === 'uart' ? 'uart' : value === 'tcp' ? 'tcp' : defaultValue;
  }

  private static readParity(
    store: preferences.Preferences,
    key: string,
    defaultValue: UartParity
  ): UartParity {
    return CommunicationConfigService.toParity(
      CommunicationConfigService.readString(store, key, defaultValue).toUpperCase(),
      defaultValue
    );
  }

  private static toParity(value: string, defaultValue: UartParity): UartParity {
    if (value === 'E') {
      return 'E';
    }
    if (value === 'O') {
      return 'O';
    }
    if (value === 'N') {
      return 'N';
    }
    return defaultValue;
  }
}