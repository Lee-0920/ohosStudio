// products/entry/src/main/ets/entryability/EntryAbility.ets

import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { ErrorEvent, MessageEvents, ThreadWorkerGlobalScope, worker } from '@kit.ArkTS';
import { ResultManager, SettingsManager, MeasureStatusManager } from 'dataservice';
import { ModbusServer, CommLogEntry, EventBus, getGlobalModbusServer, setGlobalModbusServer, TcpConfig, SerialConfig } from 'modbus';
import { Logger } from 'logger';
import { AlarmManager, AlarmInfo, AlarmType } from 'alarm';
import { CommunicationConfigService } from '../services/CommunicationConfigService';
import { CommunicationConfig } from '../models/communicationConfigTypes';
import { UserSettingsService } from '../services/UserSettingsService';
import { ModbusCommandBridge } from '../services/ModbusCommandBridge';
import { ModbusRuntimeSyncService } from '../services/ModbusRuntimeSyncService';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {

  //private workInstance:worker.ThreadWorker = new worker.ThreadWorker('Flow/ets/workers/MeasureScheduler.ets');
  private modbusServer: ModbusServer | null = null;
  private connectionInfoTimer: number = -1;
  private mainWindow: window.Window | null = null;
  private mainWindowStage: window.WindowStage | null = null;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }

    try {
      let path = this.context.filesDir + '/logger/';
      Logger.init(path);
      hilog.info(0x0000, '应用启动', '日志文件路径：%{public}s', path);
    } catch (error) {
      hilog.info(0x0000, '应用启动', '应用启动失败');
    }

    try {
      const alarmDir = this.context.filesDir + '/alarm/';
      AlarmManager.getInstance().init(alarmDir);
      hilog.info(0x0000, '应用启动', '告警文件路径：%{public}s', alarmDir);

      const alarm : AlarmInfo = {
        name: '试剂一抽取失败',
        type: AlarmType.REAGENT,
        level: 'Warning',
        cause: '试剂瓶液位过低'
      };
      AlarmManager.getInstance().addAlarm(alarm);
    } catch (error) {
      const err = error as Error;
      hilog.error(0x0000, '应用启动', '告警管理器初始化失败: %{public}s, stack: %{public}s',
        err.message ?? JSON.stringify(error), err.stack ?? '');
    }
    // 启动Modbus服务器
    this.startModbusServer();
  }

  async startModbusServer(): Promise<void> {
    this.modbusServer = new ModbusServer();

    // 设置全局变量，供页面访问
    setGlobalModbusServer(this.modbusServer);

    // 启动 Modbus 控制指令桥接，把地址 272/273 的写请求转发给 OperationTaskService
    ModbusCommandBridge.getInstance().start();

    // 启动 Modbus 运行状态同步，把系统状态/当前动作写入 DataStore 的地址 16/17
    ModbusRuntimeSyncService.getInstance().start();

    // 设置日志回调
    this.modbusServer.setLogCallback((log: CommLogEntry) => {
      this.sendLogToUI(log);
    });

    // 启动TCP服务器（使用默认配置）
    const tcpStarted = await this.modbusServer.initTCPServer(5020);
    if (tcpStarted) {
      hilog.info(DOMAIN, 'EntryAbility', 'Modbus TCP server started on port 5020');
    } else {
      hilog.error(DOMAIN, 'EntryAbility', 'Failed to start Modbus TCP server');
    }

    // 尝试多个可能的串口设备（使用默认配置）
    const serialPaths: string[] = ['/dev/ttyS0', '/dev/ttyS1', '/dev/ttyUSB0', '/dev/ttyAMA0'];
    let serialStarted: boolean = false;

    for (const path of serialPaths) {
      hilog.info(DOMAIN, 'EntryAbility', 'Trying serial port: %{public}s', path);
      serialStarted = await this.modbusServer.initSerialPort(path);
      if (serialStarted) {
        hilog.info(DOMAIN, 'EntryAbility', 'Modbus RTU server started on %{public}s', path);
        break;
      }
    }

    if (!serialStarted) {
      hilog.error(DOMAIN, 'EntryAbility', 'Failed to start Modbus RTU server on any port');
    }

    // 启动连接信息更新
    this.startConnectionInfoUpdate();
  }

  // 发送日志到UI
  private sendLogToUI(log: CommLogEntry): void {
    try {
      EventBus.getInstance().emitLog(log);
      hilog.info(DOMAIN, 'testTag', 'Log emitted: %{public}s', log.description);
    } catch (error) {
      hilog.error(DOMAIN, 'testTag', 'Failed to emit log: %{public}s', JSON.stringify(error));
    }
  }

  // 更新连接信息（仅监控，不修改数据）
  private startConnectionInfoUpdate(): void {
    this.connectionInfoTimer = setInterval(() => {
      if (this.modbusServer) {
        const count: number = this.modbusServer.getTCPConnectionCount();
        const connections: string[] = this.modbusServer.getTCPConnections();
        hilog.info(DOMAIN, 'EntryAbility', 'TCP Connections: %{public}d, %{public}s', count, connections.join(','));

        // 可以通过事件总线发送连接状态更新
        if (this.mainWindowStage) {
          // 连接状态变化可以通过日志回调通知UI
          if (count > 0) {
            const log: CommLogEntry = {
              id: Date.now(),
              timestamp: new Date().toLocaleTimeString(),
              direction: 'RECEIVE',
              protocol: 'TCP',
              data: 'STATUS',
              description: `当前TCP连接数: ${count}`
            };
            this.sendLogToUI(log);
          }
        }
      }
    }, 2000);
  }

  // 设置屏幕常亮
  private async setScreenAlwaysOn(): Promise<void> {
    if (this.mainWindow) {
      try {
        await this.mainWindow.setWindowKeepScreenOn(true);
        hilog.info(DOMAIN, 'testTag', 'Screen always on mode enabled');
      } catch (error) {
        hilog.error(DOMAIN, 'testTag', 'Failed to set screen always on: %{public}s', JSON.stringify(error));
      }
    }
  }

  private enableFullscreen(windowStage: window.WindowStage): void {
    windowStage.getMainWindow((err, win) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to get main window. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      this.mainWindow = win;
      void (async () => {
        try {
          // Use Promise overload to avoid deprecated callback API.
          await win.setWindowLayoutFullScreen(true);
        } catch (setErr) {
          hilog.error(DOMAIN, 'testTag', 'Failed to set fullscreen. Cause: %{public}s', JSON.stringify(setErr));
          return;
        }

        try {
          // Hide status/navigation bars in fullscreen mode.
          await win.setWindowSystemBarEnable([]);
        } catch (barErr) {
          hilog.error(DOMAIN, 'testTag', 'Failed to hide system bars. Cause: %{public}s', JSON.stringify(barErr));
          return;
        }

        hilog.info(DOMAIN, 'testTag', 'Fullscreen enabled and system bars hidden');
      })();
    });
  }

  async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {
    hilog.info(DOMAIN, 'testTag', 'Ability onWindowStageCreate');
    this.mainWindowStage = windowStage;

    this.mainWindow = await windowStage.getMainWindow();
    // 屏幕常亮
    await this.setScreenAlwaysOn();
    // 沉浸式全屏
    this.enableFullscreen(windowStage);

    try {
      // 1. 初始化 SettingsManager（管理 instrument_config 数据库）
      const settingsManager = SettingsManager.getInstance();
      await settingsManager.init(this.context);
      hilog.info(DOMAIN, 'testTag', 'SettingsManager initialized');

      // 2. 初始化 MeasureStatusManager（管理 measure_status_config 数据库）
      const measureStatusManager = MeasureStatusManager.getInstance();
      await measureStatusManager.init(this.context);
      hilog.info(DOMAIN, 'testTag', 'MeasureStatusManager initialized');

      // 3. 初始化 ResultManager（关系型数据库）
      const resultManager = ResultManager.getInstance();
      await resultManager.init(this.context, {
        decimalNum: 3,
        settingUseNum: 3
      });
      hilog.info(DOMAIN, 'testTag', 'ResultManager initialized');

      // 4. 初始化 CommunicationConfigService 并同步配置到 ModbusServer
      const configResult = await CommunicationConfigService.initialize(this.context);
      this.applyConfigToModbusServer(configResult.config);
      hilog.info(DOMAIN, 'testTag', 'CommunicationConfigService initialized, mode=%{public}s', configResult.config.mode);

      // 5. 恢复持久化的 Modbus 协议表
      try {
        const persistedProtocol = await UserSettingsService.loadSettingValues(this.context, [
          { key: 'system-modbus-table', value: 'LS4.0' }
        ]);
        const tableName = persistedProtocol.find(item => item.key === 'system-modbus-table')?.value ?? 'LS4.0';
        getGlobalModbusServer()?.setProtocolTable(tableName);
        hilog.info(DOMAIN, 'EntryAbility', 'Restored modbus protocol table: %{public}s', tableName);
      } catch (err) {
        hilog.warn(DOMAIN, 'EntryAbility', 'Failed to restore modbus protocol table: %{public}s', JSON.stringify(err));
      }

      // 所有初始化完成后再加载页面
      windowStage.loadContent('pages/Index3', (err) => {
        if (err && err.code) {
          hilog.error(DOMAIN, 'testTag', 'Failed to load content: %{public}s', JSON.stringify(err));
          return;
        }
        hilog.info(DOMAIN, 'testTag', 'Succeeded in loading content.');

        // 将ModbusServer实例传递给页面
        this.passModbusServerToPage();
      });

      // 启动 Worker
      // this.workInstance.postMessage({type:'context', context: this.context});
      // 监听 Worker 消息
      // this.workInstance.onmessage = () => {
      //   hilog.info(DOMAIN, 'testTag', '%{public}s', '排期');
      // };

    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to initialize databases: %{public}s', JSON.stringify(err));
      // 即使失败也加载页面，但页面会显示错误
      windowStage.loadContent('pages/Index', (err) => {
        if (err && err.code) {
          hilog.error(DOMAIN, 'testTag', 'Failed to load content: %{public}s', JSON.stringify(err));
        }
        // 将ModbusServer实例传递给页面
        this.passModbusServerToPage();
      });
    }
  }

  // 将ModbusServer实例传递给页面
  private passModbusServerToPage(): void {
    // 通过全局变量传递，页面可以通过 getGlobalModbusServer() 访问
    const server: ModbusServer | null = getGlobalModbusServer();
    if (server) {
      hilog.info(DOMAIN, 'testTag', 'ModbusServer instance available for pages');
    }
  }

  /**
   * 将 CommunicationConfig 同步到 ModbusServer
   * 使用新的 setTcpConfig 和 setSerialConfig 方法
   */
  private applyConfigToModbusServer(config: CommunicationConfig): void {
    const server = getGlobalModbusServer();
    if (!server) {
      hilog.warn(DOMAIN, 'testTag', 'ModbusServer not available, skipping config sync');
      return;
    }

    // 同步 TCP 配置
    const tcpConfig: TcpConfig = {
      address: config.tcpIp,
      port: config.tcpPort
    };
    server.setTcpConfig(tcpConfig);
    hilog.info(DOMAIN, 'testTag', 'TCP config synced: %s:%d', config.tcpIp, config.tcpPort);

    // 同步串口配置
    const parityMap: Record<string, number> = {
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
    hilog.info(DOMAIN, 'testTag', 'Serial config synced: %s %d-%d-%d',
      config.uartPath, config.uartBaudRate, config.uartDataBits, config.uartStopBits);

    // 根据当前模式应用对应的配置
    if (config.mode === 'tcp') {
      // 异步重启 TCP 服务器
      server.applyTcpConfig().then((success: boolean) => {
        hilog.info(DOMAIN, 'testTag', 'TCP server restart %{public}s', success ? 'success' : 'failed');
      }).catch((err: Error) => {
        hilog.error(DOMAIN, 'testTag', 'TCP server restart error: %{public}s', err.message);
      });
    } else {
      // 应用串口配置
      const success: boolean = server.applySerialConfig();
      hilog.info(DOMAIN, 'testTag', 'Serial config applied: %{public}s', success ? 'success' : 'failed');
    }
  }

  async onDestroy() {
    hilog.info(DOMAIN, 'testTag', 'Ability onDestroy');

    // 清理连接信息定时器
    if (this.connectionInfoTimer !== -1) {
      clearInterval(this.connectionInfoTimer);
      this.connectionInfoTimer = -1;
    }

    // 关闭Modbus服务器
    if (this.modbusServer) {
      this.modbusServer.shutdown();
    }

    // 清除全局变量
    setGlobalModbusServer(null);

    // 停止 Modbus 控制指令桥接
    ModbusCommandBridge.getInstance().stop();

    // 停止 Modbus 运行状态同步
    ModbusRuntimeSyncService.getInstance().stop();

    try {
      const resultManager = ResultManager.getInstance();
      const rdbManager = resultManager.getRdbManager();
      await rdbManager.forceCheckpoint();
      console.info('Checkpoint completed on app destroy');
    } catch (err) {
      console.error(`Checkpoint failed: ${err}`);
    }
    // this.workInstance.terminate(); //销毁worker
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
    this.mainWindow = null;
    this.mainWindowStage = null;
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
    this.setScreenAlwaysOn();
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}