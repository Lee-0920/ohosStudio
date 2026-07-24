// lhipstudio/modbus/src/main/ets/ability/ModbusAbility.ets

import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { ModbusServer } from '../model/ModbusServer';
import { CommLogEntry } from '../model/Types';
import EventBus from '../utils/EventBus';

// 使用全局对象存储 ModbusServer 实例
let globalModbusServer: ModbusServer | null = null;

// 导出获取全局 ModbusServer 的方法
export function getGlobalModbusServer(): ModbusServer | null {
  return globalModbusServer;
}

export function setGlobalModbusServer(server: ModbusServer | null): void {
  globalModbusServer = server;
}

export default class ModbusAbility extends UIAbility {
  private modbusServer: ModbusServer | null = null;
  private connectionInfoTimer: number = -1;
  private mainWindow: window.Window | null = null;
  private mainWindowStage: window.WindowStage | null = null;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, 'ModbusAbility', 'Ability onCreate');
    // this.startModbusServer();
  }

  async startModbusServer(): Promise<void> {
    this.modbusServer = new ModbusServer();

    setGlobalModbusServer(this.modbusServer);

    this.modbusServer.setLogCallback((log: CommLogEntry) => {
      this.sendLogToUI(log);
    });

    const tcpStarted = await this.modbusServer.initTCPServer(5020);
    if (tcpStarted) {
      hilog.info(0x0000, 'ModbusAbility', 'Modbus TCP server started on port 5020');
    } else {
      hilog.error(0x0000, 'ModbusAbility', 'Failed to start Modbus TCP server');
    }

    const serialPaths: string[] = ['/dev/ttyS0', '/dev/ttyS1', '/dev/ttyUSB0', '/dev/ttyAMA0'];
    let serialStarted: boolean = false;

    for (const path of serialPaths) {
      hilog.info(0x0000, 'ModbusAbility', 'Trying serial port: %{public}s', path);
      serialStarted = await this.modbusServer.initSerialPort(path);
      if (serialStarted) {
        hilog.info(0x0000, 'ModbusAbility', 'Modbus RTU server started on %{public}s', path);
        break;
      }
    }

    if (!serialStarted) {
      hilog.error(0x0000, 'ModbusAbility', 'Failed to start Modbus RTU server on any port');
    }

    this.startConnectionInfoUpdate();
  }

  private sendLogToUI(log: CommLogEntry): void {
    try {
      EventBus.getInstance().emitLog(log);
    } catch (error) {
      hilog.error(0x0000, 'ModbusAbility', 'Failed to emit log: %{public}s', JSON.stringify(error));
    }
  }

  private startConnectionInfoUpdate(): void {
    this.connectionInfoTimer = setInterval(() => {
      if (this.modbusServer) {
        const count: number = this.modbusServer.getTCPConnectionCount();
        const connections: string[] = this.modbusServer.getTCPConnections();
        hilog.info(0x0000, 'ModbusAbility', 'TCP Connections: %{public}d, %{public}s', count, connections.join(','));
      }
    }, 2000);
  }

  private async setScreenAlwaysOn(): Promise<void> {
    if (this.mainWindow) {
      try {
        await this.mainWindow.setWindowKeepScreenOn(true);
      } catch (error) {
        hilog.error(0x0000, 'ModbusAbility', 'Failed to set screen always on: %{public}s', JSON.stringify(error));
      }
    }
  }

  onDestroy(): void {
    hilog.info(0x0000, 'ModbusAbility', 'Ability onDestroy');

    if (this.connectionInfoTimer !== -1) {
      clearInterval(this.connectionInfoTimer);
      this.connectionInfoTimer = -1;
    }

    if (this.modbusServer) {
      this.modbusServer.shutdown();
    }

    setGlobalModbusServer(null);
  }

  async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {
    hilog.info(0x0000, 'ModbusAbility', 'Ability onWindowStageCreate');
    this.mainWindowStage = windowStage;

    this.mainWindow = await windowStage.getMainWindow();
    await this.setScreenAlwaysOn();

    // 不加载内容，作为后台服务运行
  }

  onWindowStageDestroy(): void {
    hilog.info(0x0000, 'ModbusAbility', 'Ability onWindowStageDestroy');
    this.mainWindow = null;
    this.mainWindowStage = null;
  }

  onForeground(): void {
    hilog.info(0x0000, 'ModbusAbility', 'Ability onForeground');
    this.setScreenAlwaysOn();
  }

  onBackground(): void {
    hilog.info(0x0000, 'ModbusAbility', 'Ability onBackground');
  }
}