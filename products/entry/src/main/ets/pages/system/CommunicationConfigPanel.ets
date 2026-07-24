// products/entry/src/main/ets/pages/system/CommunicationConfigPanel.ets

import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import {
  ConnectionSnapshot, DeviceEvent
} from '../../models/deviceStateTypes';
import {
  CommunicationConfig,
  CommunicationConfigApplyResult,
  UartParity
} from '../../models/communicationConfigTypes';
import { CommunicationConfigService } from '../../services/CommunicationConfigService';
import { DeviceConnectionSupervisor } from '../../services/DeviceConnectionSupervisor';
import { DeviceEventBus } from '../../services/DeviceEventBus';
import { DevicePollingCoordinator } from '../../services/DevicePollingCoordinator';
import { DeviceStateStore } from '../../services/DeviceStateStore';
import { CommunicationMode, MonitorService } from '../../services/MonitorService';
import { SystemActionButton } from './SystemControls';
import { getGlobalModbusServer, TcpConfig, SerialConfig } from 'modbus';
import { UiUtil } from 'base';

const DOMAIN = 0x0004;
const TAG = 'CommunicationConfigPanel';

@Component
export struct CommunicationConfigPanel {
  @Prop viewportWidth: number = 1024;
  @Prop viewportHeight: number = 768;
  @Prop scaleFactor: number = 1.92;
  @State private communicationMode: CommunicationMode = 'uart';
  @State private tcpIp: string = '192.168.0.110';
  @State private tcpPort: string = '5020';
  @State private uartPath: string = '/dev/ttyS7';
  @State private uartBaudRate: string = '9600';
  @State private uartDataBits: string = '8';
  @State private uartStopBits: string = '1';
  @State private uartParity: string = 'N';
  @State private uartDriverMode: string = 'RS232';
  @State private statusText: string = '';
  @State private isActionRunning: boolean = false;
  @State private connectionConnected: boolean = false;
  @State private connectionStatusLabel: string = '未连接';
  onSystemAction: () => void = () => {
  };
  private unsubscribeConnection: (() => void) | null = null;
  private releaseConnectionInterest: (() => void) | null = null;
  private readonly communicationModeOptions: SelectOption[] = [
    { value: 'tcp' },
    { value: 'uart' }
  ];
  private readonly baudRateOptions: SelectOption[] = [
    { value: '1800' },
    { value: '2400' },
    { value: '4800' },
    { value: '9600' },
    { value: '19200' },
    { value: '38400' },
    { value: '57600' },
    { value: '115200' },
    { value: '230400' },
    { value: '460800' },
    { value: '500000' },
    { value: '576000' },
    { value: '921600' },
    { value: '1000000' },
    { value: '1152000' },
    { value: '1500000' },
    { value: '2000000' },
    { value: '2500000' },
    { value: '3000000' },
    { value: '3500000' },
    { value: '4000000' }
  ];
  private readonly dataBitsOptions: SelectOption[] = [
    { value: '7' },
    { value: '8' }
  ];
  private readonly stopBitsOptions: SelectOption[] = [
    { value: '1' },
    { value: '2' }
  ];
  private readonly parityOptions: SelectOption[] = [
    { value: 'N' },
    { value: 'E' },
    { value: 'O' }
  ];
  private readonly driverModeOptions: SelectOption[] = [
    { value: 'RS232' },
    { value: 'RS485' }
  ];

  aboutToAppear(): void {
    this.releaseConnectionSubscription();
    this.applyConnectionSnapshot(DeviceStateStore.getConnectionSnapshot());
    this.unsubscribeConnection = DeviceEventBus.subscribe('connection', (event: DeviceEvent) => {
      this.applyConnectionSnapshot(event.current as ConnectionSnapshot);
    });
    this.releaseConnectionInterest = DevicePollingCoordinator.registerTopicInterest(
      'connection',
      'CommunicationConfigPanel'
    );
    this.statusText = '正在载入业务通信配置';
    void this.loadPersistedConfig();
    // 同步 ModbusServer 状态
    this.syncModbusConnectionState();
  }

  aboutToDisappear(): void {
    this.releaseConnectionSubscription();
  }

  private parseDecimal(value: string): number | null {
    const parsed = Number(value.trim());
    return Number.isNaN(parsed) ? null : parsed;
  }

  private getHostContext(): common.Context | null {
    const context = this.getUIContext().getHostContext();
    if (!context) {
      return null;
    }
    return context as common.Context;
  }

  private async loadPersistedConfig(): Promise<void> {
    const context = this.getHostContext();
    if (!context) {
      this.statusText = '无法获取应用上下文，通信配置载入失败';
      return;
    }
    const result = await CommunicationConfigService.initialize(context);
    this.applyConfigToState(result.config);
    this.updateStatusText(result.fallbackToDefaults ? '持久化配置无效，已载入默认配置' :
      (result.fromPersistence ? '已载入持久化业务通信配置' : '已载入默认业务通信配置'));
  }

  private applyConfigToState(config: CommunicationConfig): void {
    this.communicationMode = config.mode;
    this.tcpIp = config.tcpIp;
    this.tcpPort = `${config.tcpPort}`;
    this.uartPath = config.uartPath;
    this.uartBaudRate = `${config.uartBaudRate}`;
    this.uartDataBits = `${config.uartDataBits}`;
    this.uartStopBits = `${config.uartStopBits}`;
    this.uartParity = config.uartParity;
    this.uartDriverMode = config.uartIsRs485 ? 'RS485' : 'RS232';
  }

  private updateStatusText(prefix: string): void {
    this.syncConnectionState();
    const mode = MonitorService.getCommunicationMode();
    const connected = this.connectionStatusLabel.length > 0 ? this.connectionStatusLabel :
      (this.connectionConnected ? '已连接' : '未连接');
    this.statusText = `${prefix}。当前通道=${mode === 'tcp' ? 'TCP' : 'UART'}，状态=${connected}`;
  }

  private syncConnectionState(): void {
    const snapshot = DeviceConnectionSupervisor.createSnapshotInput('');
    this.connectionConnected = snapshot.connected;
    this.connectionStatusLabel = snapshot.statusLabel;
  }

  private applyConnectionSnapshot(snapshot: ConnectionSnapshot): void {
    this.connectionConnected = snapshot.connected;
    this.connectionStatusLabel = snapshot.statusLabel;
  }

  private releaseConnectionSubscription(): void {
    if (this.unsubscribeConnection) {
      this.unsubscribeConnection();
      this.unsubscribeConnection = null;
    }
    if (this.releaseConnectionInterest) {
      this.releaseConnectionInterest();
      this.releaseConnectionInterest = null;
    }
  }

  private createConfigFromState(): CommunicationConfig | null {
    const port = this.parseDecimal(this.tcpPort);
    const baud = this.parseDecimal(this.uartBaudRate);
    const dataBits = this.parseDecimal(this.uartDataBits);
    const stopBits = this.parseDecimal(this.uartStopBits);
    if (port === null || baud === null || dataBits === null || stopBits === null) {
      return null;
    }
    const parity: UartParity = this.uartParity === 'E' ? 'E' : this.uartParity === 'O' ? 'O' : 'N';
    const config: CommunicationConfig = {
      mode: this.communicationMode,
      tcpIp: this.tcpIp,
      tcpPort: port,
      uartPath: this.uartPath,
      uartBaudRate: baud,
      uartDataBits: dataBits,
      uartStopBits: stopBits,
      uartParity: parity,
      uartIsRs485: this.uartDriverMode === 'RS485'
    };
    return CommunicationConfigService.normalizeConfig(config);
  }

  // ==================== 同步配置到 ModbusServer ====================

  /**
   * 将通信配置同步到 ModbusServer
   */
  private syncConfigToModbusServer(config: CommunicationConfig): void {
    const server = getGlobalModbusServer();
    if (!server) {
      hilog.warn(DOMAIN, TAG, 'ModbusServer not available');
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
        if (success) {
          this.syncModbusConnectionState();
        }
      }).catch((err: Error) => {
        hilog.error(DOMAIN, TAG, 'TCP server restart error: %{public}s', err.message);
      });
    } else {
      // 应用串口配置
      const success = server.applySerialConfig();
      hilog.info(DOMAIN, TAG, 'Serial config applied: %{public}s', success ? 'success' : 'failed');
      this.syncModbusConnectionState();
    }

    hilog.info(DOMAIN, TAG, 'Config synced to ModbusServer: mode=%{public}s', config.mode);
  }

  // ==================== 同步 ModbusServer 连接状态 ====================

  /**
   * 同步 ModbusServer 的 UART/TCP 连接状态到页面状态
   */
  private syncModbusConnectionState(): void {
    const server = getGlobalModbusServer();
    if (!server) {
      this.connectionConnected = false;
      this.connectionStatusLabel = '服务未启动';
      return;
    }

    // 检查 TCP 服务器状态
    const tcpRunning = server.getTcpServerRunning();
    if (this.communicationMode === 'tcp') {
      const count = server.getTCPConnectionCount();
      if (tcpRunning) {
        this.connectionConnected = count > 0;
        this.connectionStatusLabel = this.connectionConnected ? `已连接(${count})` : '监听中';
      } else {
        this.connectionConnected = false;
        this.connectionStatusLabel = '未启动';
      }
    } else {
      // UART 模式
      this.connectionConnected = server.isSerialOpened();
      this.connectionStatusLabel = this.connectionConnected ? '已连接' : '未连接';
    }
  }

  // ==================== 保存和应用配置 ====================

  private async saveAndApplyConfig(): Promise<boolean> {
    const context = this.getHostContext();
    if (!context) {
      this.statusText = '无法获取应用上下文，通信配置未保存';
      return false;
    }
    const config = this.createConfigFromState();
    if (!config || !CommunicationConfigService.isValidConfig(config)) {
      this.statusText = '通信配置参数无效，请检查 TCP 和 UART 参数';
      return false;
    }

    const previousConnected = DeviceStateStore.getConnectionSnapshot().connected;
    const result: CommunicationConfigApplyResult =
      await CommunicationConfigService.saveAndApply(context, config);
    if (!result.success) {
      this.statusText = result.errorMessage.length > 0 ? result.errorMessage : '通信配置保存失败';
      return false;
    }

    // 同步配置到 ModbusServer
    this.syncConfigToModbusServer(config);

    this.applyConfigToState(result.config);
    if (result.changed) {
      DeviceConnectionSupervisor.markConfigChanged();
      DeviceStateStore.resetRealtimeState('通信配置已变更');
      const snapshot = DeviceConnectionSupervisor.createSnapshotInput('通信配置已变更');
      DeviceStateStore.updateConnection(snapshot, 'communication_config_panel');
      DevicePollingCoordinator.notifyConnectionSnapshotChanged(previousConnected, snapshot.connected);
    }

    const modeText = result.config.mode === 'tcp' ?
      `TCP ${result.config.tcpIp}:${result.config.tcpPort}` :
      `UART ${result.config.uartPath} ${result.config.uartBaudRate} ` +
        `${result.config.uartDataBits}${result.config.uartParity}${result.config.uartStopBits} ` +
        `${result.config.uartIsRs485 ? 'RS485' : 'RS232'}`;
    const prefix = !result.changed ? `配置已保存（无变化）：${modeText}` :
      (result.disconnectedPreviousConnection ?
        `配置已保存并应用，原连接已断开：${modeText}` :
        `配置已保存并应用：${modeText}`);
    this.updateStatusText(prefix);
    this.onSystemAction();
    return true;
  }

  // ==================== 按钮事件 ====================

  private async handleApplyConfig(): Promise<void> {
    if (this.isActionRunning) {
      return;
    }
    this.isActionRunning = true;
    try {
      await this.saveAndApplyConfig();
    } finally {
      this.isActionRunning = false;
    }
  }

  private async connectCurrentMode(): Promise<void> {
    if (this.isActionRunning) {
      return;
    }
    this.isActionRunning = true;
    try {
      if (!(await this.saveAndApplyConfig())) {
        return;
      }

      this.statusText = '通信配置已保存，正在连接业务通信通道';
      DeviceConnectionSupervisor.enableAutoReconnect();
      const previousConnected = DeviceStateStore.getConnectionSnapshot().connected;
      const ok = await MonitorService.connect();
      if (ok) {
        DeviceConnectionSupervisor.recordTransportSuccess('manual-connect');
      } else {
        DeviceConnectionSupervisor.recordTransportFailure('manual-connect', '手动连接失败');
      }
      const snapshot = DeviceConnectionSupervisor.createSnapshotInput(ok ? '' : '手动连接失败');
      DeviceStateStore.updateConnection(snapshot, 'communication_config_panel');
      DevicePollingCoordinator.notifyConnectionSnapshotChanged(previousConnected, snapshot.connected);

      this.syncModbusConnectionState();
      this.updateStatusText(ok ? '连接成功' : '连接失败');
      this.onSystemAction();
    } finally {
      this.isActionRunning = false;
    }
  }

  private disconnectCurrentMode(): void {
    const previousConnected = DeviceStateStore.getConnectionSnapshot().connected;
    MonitorService.disconnect();
    DeviceConnectionSupervisor.markManualDisconnected();
    DeviceStateStore.resetRealtimeState('用户主动断开');
    const snapshot = DeviceConnectionSupervisor.createSnapshotInput('用户主动断开');
    DeviceStateStore.updateConnection(snapshot, 'communication_config_panel');
    DevicePollingCoordinator.notifyConnectionSnapshotChanged(previousConnected, snapshot.connected);

    this.syncModbusConnectionState();
    this.updateStatusText('已断开业务通信通道');
    this.onSystemAction();
  }

  private refreshStatus(): void {
    this.syncModbusConnectionState();
    this.updateStatusText('已刷新状态');
  }

  // ==================== UI 构建 ====================

  @Builder
  private sectionTitle(title: string) {
    Text(title)
      .fontSize(UiUtil.vh(1.9, 12, 16, this.viewportHeight, this.scaleFactor))
      .fontWeight(FontWeight.Bold)
      .fontColor('#222222')
      .height(UiUtil.vh(3.2, 24, 34, this.viewportHeight, this.scaleFactor))
  }

  @Builder
  private labelText(label: string, widthValue?: number) {
    Text(label)
      .fontSize(UiUtil.vh(1.65, 11, 15, this.viewportHeight, this.scaleFactor))
      .fontColor('#333333')
      .width(widthValue !== undefined ? widthValue : UiUtil.vw(7.0, 56, 84, this.viewportWidth, this.scaleFactor))
      .maxLines(1)
  }

  @Builder
  private inputCell(textValue: string, widthValue: number, onValueChange: (value: string) => void) {
    TextInput({ text: textValue })
      .height(UiUtil.vh(3.6, 28, 38, this.viewportHeight, this.scaleFactor))
      .width(widthValue)
      .fontSize(UiUtil.vh(1.65, 11, 15, this.viewportHeight, this.scaleFactor))
      .backgroundColor('#FFFFFF')
      .border({ width: UiUtil.vh(0.1, 1, 1, this.viewportHeight, this.scaleFactor), color: '#D8DDE3' })
      .borderRadius(UiUtil.vh(0.45, 3, 5, this.viewportHeight, this.scaleFactor))
      .onChange((value: string) => {
        onValueChange(value);
      })
  }

  @Builder
  private selectCell(options: SelectOption[], value: string, widthValue: number,
    onValueChange: (value: string) => void) {
    Select(options)
      .value(value)
      .height(UiUtil.vh(3.6, 28, 38, this.viewportHeight, this.scaleFactor))
      .width(widthValue)
      .onSelect((_index: number, selectedValue?: string) => {
        onValueChange(selectedValue ? selectedValue : value);
      })
  }

  @Builder
  private actionButton(label: string, onAction: () => void, widthValue?: number) {
    SystemActionButton({
      label: label,
      buttonWidth: widthValue !== undefined ? widthValue :
        UiUtil.vw(9.6, 78, 112, this.viewportWidth, this.scaleFactor),
      buttonHeight: UiUtil.vh(4.2, 32, 46, this.viewportHeight, this.scaleFactor),
      fontSizeValue: UiUtil.vh(1.65, 11, 15, this.viewportHeight, this.scaleFactor),
      borderRadiusValue: UiUtil.vh(0.65, 4, 8, this.viewportHeight, this.scaleFactor),
      onAction: () => {
        onAction();
      }
    })
  }

  build() {
    Column() {
      Scroll() {
        Column() {
          this.sectionTitle('业务通信通道');

          Row() {
            this.labelText('当前通道');
            this.selectCell(this.communicationModeOptions, this.communicationMode,
              UiUtil.vw(9.0, 74, 104, this.viewportWidth, this.scaleFactor), (value: string) => {
                this.communicationMode = value === 'uart' ? 'uart' : 'tcp';
                // 切换模式时更新状态
                this.syncModbusConnectionState();
              });

            this.labelText('连接状态', UiUtil.vw(7.0, 56, 84, this.viewportWidth, this.scaleFactor));
            Text(this.connectionStatusLabel)
              .fontSize(UiUtil.vh(1.65, 11, 15, this.viewportHeight, this.scaleFactor))
              .fontColor(this.connectionConnected ? '#1B7F4C' : '#B04632')
          }
          .width('100%')
          .height(UiUtil.vh(4.4, 34, 46, this.viewportHeight, this.scaleFactor))
          .alignItems(VerticalAlign.Center)

          this.sectionTitle('TCP 参数');
          Row() {
            this.labelText('IP 地址');
            this.inputCell(this.tcpIp, UiUtil.vw(17.0, 136, 198, this.viewportWidth, this.scaleFactor),
              (value: string) => {
                this.tcpIp = value;
              });

            this.labelText('端口', UiUtil.vw(5.6, 44, 64, this.viewportWidth, this.scaleFactor));
            this.inputCell(this.tcpPort, UiUtil.vw(7.0, 58, 82, this.viewportWidth, this.scaleFactor),
              (value: string) => {
                this.tcpPort = value;
              });
          }
          .width('100%')
          .height(UiUtil.vh(4.4, 34, 46, this.viewportHeight, this.scaleFactor))
          .alignItems(VerticalAlign.Center)

          this.sectionTitle('UART 参数');
          Row() {
            this.labelText('设备路径');
            this.inputCell(this.uartPath, UiUtil.vw(20.0, 160, 238, this.viewportWidth, this.scaleFactor),
              (value: string) => {
                this.uartPath = value;
              });

            this.labelText('波特率', UiUtil.vw(5.8, 46, 68, this.viewportWidth, this.scaleFactor));
            this.selectCell(this.baudRateOptions, this.uartBaudRate,
              UiUtil.vw(11.0, 90, 126, this.viewportWidth, this.scaleFactor), (value: string) => {
                this.uartBaudRate = value;
              });
          }
          .width('100%')
          .height(UiUtil.vh(4.4, 34, 46, this.viewportHeight, this.scaleFactor))
          .alignItems(VerticalAlign.Center)

          Row() {
            this.labelText('驱动模式');
            this.selectCell(this.driverModeOptions, this.uartDriverMode,
              UiUtil.vw(9.0, 74, 104, this.viewportWidth, this.scaleFactor), (value: string) => {
                this.uartDriverMode = value;
              });

            this.labelText('数据位', UiUtil.vw(5.6, 44, 64, this.viewportWidth, this.scaleFactor));
            this.selectCell(this.dataBitsOptions, this.uartDataBits,
              UiUtil.vw(6.2, 50, 72, this.viewportWidth, this.scaleFactor), (value: string) => {
                this.uartDataBits = value;
              });

            this.labelText('停止位', UiUtil.vw(5.6, 44, 64, this.viewportWidth, this.scaleFactor));
            this.selectCell(this.stopBitsOptions, this.uartStopBits,
              UiUtil.vw(6.2, 50, 72, this.viewportWidth, this.scaleFactor), (value: string) => {
                this.uartStopBits = value;
              });

            this.labelText('校验位', UiUtil.vw(5.6, 44, 64, this.viewportWidth, this.scaleFactor));
            this.selectCell(this.parityOptions, this.uartParity,
              UiUtil.vw(6.2, 50, 72, this.viewportWidth, this.scaleFactor), (value: string) => {
                this.uartParity = value;
              });
          }
          .width('100%')
          .height(UiUtil.vh(4.4, 34, 46, this.viewportHeight, this.scaleFactor))
          .alignItems(VerticalAlign.Center)

          Row({ space: UiUtil.vw(0.8, 6, 10, this.viewportWidth, this.scaleFactor) }) {
            this.actionButton('应用配置', () => {
              void this.handleApplyConfig();
            });
            this.actionButton(this.isActionRunning ? '连接中' : '连接', () => {
              void this.connectCurrentMode();
            });
            this.actionButton('断开', () => this.disconnectCurrentMode());
            this.actionButton('查询状态', () => this.refreshStatus(),
              UiUtil.vw(10.0, 82, 118, this.viewportWidth, this.scaleFactor));
          }
          .width('100%')
          .height(UiUtil.vh(5.2, 38, 54, this.viewportHeight, this.scaleFactor))
          .alignItems(VerticalAlign.Center)
          .margin({ top: UiUtil.vh(0.8, 4, 10, this.viewportHeight, this.scaleFactor) })

          Text(this.statusText)
            .fontSize(UiUtil.vh(1.65, 11, 15, this.viewportHeight, this.scaleFactor))
            .fontColor('#333333')
            .width('100%')
            .margin({ top: UiUtil.vh(1.0, 6, 12, this.viewportHeight, this.scaleFactor) })
        }
        .width('100%')
        .padding({
          left: UiUtil.vw(1.4, 10, 18, this.viewportWidth, this.scaleFactor),
          right: UiUtil.vw(1.4, 10, 18, this.viewportWidth, this.scaleFactor),
          top: UiUtil.vh(1.0, 6, 12, this.viewportHeight, this.scaleFactor),
          bottom: UiUtil.vh(1.2, 8, 14, this.viewportHeight, this.scaleFactor)
        })
      }
      .layoutWeight(1)
      .width('100%')
    }
    .layoutWeight(1)
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}