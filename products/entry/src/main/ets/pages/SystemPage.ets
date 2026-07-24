import { common } from '@kit.AbilityKit';
import { GradientSideTabBar } from '../components/GradientSideTabBar';
import { OPERATION_LOG_TYPE_SYSTEM } from '../models/dataRecordTypes';
import { WqSystemInfoItem, WqSystemTableRow } from '../models/monitorTypes';
import { NetworkRuntimeInfo, NetworkSettingsConfig } from '../models/systemSettingsTypes';
import { OperationLogService } from '../services/OperationLogService';
import { MonitorService } from '../services/MonitorService';
import { SystemInfoSessionListener, SystemInfoSessionStore } from '../services/SystemInfoSessionStore';
import { SettingsManager, InstrumentInfoConfig, ManufactureType, DateStruct } from 'dataservice';
import { DateTimeParts, SystemSettingsService } from '../services/SystemSettingsService';
import { BoardInfoPanel } from './system/BoardInfoPanel';
import { CommunicationConfigPanel } from './system/CommunicationConfigPanel';
import { UartDebugPanel } from './system/UartDebugPanel';
import { InstrumentInfoPanel } from './system/InstrumentInfoPanel';
import { NetworkSettingsPanel } from './system/NetworkSettingsPanel';
import { SystemSettingsPanel } from './system/SystemSettingsPanel';
import { SystemTimePanel } from './system/SystemTimePanel';
import { DebugPanel } from './system/DebugPanel';
import { UiUtil } from 'base';

interface NetworkConfigSnapshot {
  mode: string;
  ip: string;
  netMask: string;
  gateway: string;
  dns1: string;
  dns2: string;
}

interface NetworkRuntimeSnapshot {
  ip: string;
  netMask: string;
  gateway: string;
  dns1: string;
  dns2: string;
}

@Component
export struct SystemPage {
  @Prop viewportWidth: number = 1024;
  @Prop viewportHeight: number = 768;
  @Prop scaleFactor: number = 1.92;

  @State private systemInfoList: WqSystemInfoItem[] = [];
  @State private boardInfoRows: WqSystemTableRow[] = SystemInfoSessionStore.getBoardInfoRows();
  @State private selectedSystemTab: string = '仪器信息';
  @State private networkMode: string = 'dhcp';
  @State private staticIp: string = '';
  @State private staticMask: string = '';
  @State private staticGateway: string = '';
  @State private staticDns1: string = '';
  @State private staticDns2: string = '';
  @State private dhcpIp: string = '-';
  @State private dhcpMask: string = '-';
  @State private dhcpGateway: string = '-';
  @State private dhcpDns1: string = '-';
  @State private dhcpDns2: string = '-';
  @State private systemDate: string = '';
  @State private systemTime: string = '';
  @State private currentSystemTimeText: string = '-';
  @State private instrumentTimeText: string = '-';
  @State private timeActionMessage: string = '';
  @State private isTimeActionRunning: boolean = false;
  @State private actionVersion: number = 0;

  private readonly systemTabs: string[] = ['仪器信息', '板卡信息', '网络设置', '系统时间', '系统设置'
    // , '通信设置', 'Uart调试面板', '功能调试面板'
  ];
  private systemInfoSessionListener: SystemInfoSessionListener | null = null;

  aboutToAppear(): void {
    this.syncSystemInfoRows();
    void this.loadInstrumentInfoFromSettings();
    void this.syncNetworkSettings();
    void this.refreshTimePage(true);
    if (this.systemInfoSessionListener) {
      SystemInfoSessionStore.removeListener(this.systemInfoSessionListener);
    }
    const listener: SystemInfoSessionListener = () => {
      this.syncSystemInfoRows();
    };
    this.systemInfoSessionListener = listener;
    SystemInfoSessionStore.addListener(listener);
    void this.refreshBoardInfoIfChanged();
  }

  aboutToDisappear(): void {
    if (this.systemInfoSessionListener) {
      SystemInfoSessionStore.removeListener(this.systemInfoSessionListener);
      this.systemInfoSessionListener = null;
    }
  }

  private syncSystemInfoRows(): void {
    this.boardInfoRows = SystemInfoSessionStore.getBoardInfoRows();
  }

  private async loadInstrumentInfoFromSettings(): Promise<void> {
    const config = await SettingsManager.getInstance().getInstrumentInfo();
    this.systemInfoList = this.buildInstrumentInfoRows(config);
  }

  private buildInstrumentInfoRows(config: InstrumentInfoConfig | null): WqSystemInfoItem[] {
    if (!config) {
      return [];
    }

    const manufactureTypeText = (type: number): string => {
      switch (type) {
        case ManufactureType.Oem:
          return 'OEM';
        case ManufactureType.Diy:
          return 'DIY';
        case ManufactureType.Ls:
        default:
          return '朗石';
      }
    };

    return [
      { label: '显示型号', value: this.formatInstrumentInfoValue(config.showModel) },
      { label: '显示名称', value: this.formatInstrumentInfoValue(config.showName) },
      { label: '仪器型号', value: this.formatInstrumentInfoValue(config.model) },
      { label: '仪器类型', value: this.formatInstrumentInfoValue(config.type) },
      { label: '序列号', value: this.formatInstrumentInfoValue(config.sn) },
      { label: '生产厂商', value: this.formatInstrumentInfoValue(config.manufacturer) },
      { label: '厂商编号', value: this.formatInstrumentInfoValue(config.MfrN) },
      { label: 'UUID', value: this.formatInstrumentInfoValue(config.uuid) },
      { label: '生产日期', value: this.formatDateStruct(config.manuDate) },
      { label: '授权有效期', value: UiUtil.formatDateTimestamp(config.expirationDate) },
      { label: '永久授权', value: config.permanent ? '是' : '否' },
      { label: '厂商类型', value: manufactureTypeText(config.manufactureType) }
    ];
  }

  private formatInstrumentInfoValue(value: string | null | undefined): string {
    const text = value ? value.trim() : '';
    return text.length > 0 ? text : '-';
  }

  private formatDateStruct(date: DateStruct | null | undefined): string {
    if (!date) {
      return '-';
    }
    const month = String(date.month).padStart(2, '0');
    const day = String(date.day).padStart(2, '0');
    return `${date.year}-${month}-${day}`;
  }

  private async syncNetworkSettings(): Promise<void> {
    const context = this.getHostContext();
    if (!context) {
      return;
    }

    const result = await SystemSettingsService.loadNetworkConfig(context);
    const configSnapshot: NetworkConfigSnapshot = {
      mode: result.config.mode,
      ip: result.config.ip,
      netMask: result.config.netMask,
      gateway: result.config.gateway,
      dns1: result.config.dns1,
      dns2: result.config.dns2
    };
    const currentConfigSnapshot: NetworkConfigSnapshot = {
      mode: this.networkMode,
      ip: this.staticIp,
      netMask: this.staticMask,
      gateway: this.staticGateway,
      dns1: this.staticDns1,
      dns2: this.staticDns2
    };
    if (JSON.stringify(configSnapshot) !== JSON.stringify(currentConfigSnapshot)) {
      this.applyNetworkConfigToState(result.config);
    }
    await this.syncRuntimeNetworkInfo(result.config.iface);
  }

  private async syncRuntimeNetworkInfo(iface: string): Promise<void> {
    const runtimeInfo = await SystemSettingsService.readRuntimeNetworkInfo(iface);
    const runtimeSnapshot = this.buildRuntimeSnapshot(runtimeInfo);
    const currentRuntimeSnapshot: NetworkRuntimeSnapshot = {
      ip: this.dhcpIp,
      netMask: this.dhcpMask,
      gateway: this.dhcpGateway,
      dns1: this.dhcpDns1,
      dns2: this.dhcpDns2
    };
    if (JSON.stringify(runtimeSnapshot) !== JSON.stringify(currentRuntimeSnapshot)) {
      this.applyRuntimeNetworkInfoToState(runtimeInfo);
    }
  }

  private buildRuntimeSnapshot(info: NetworkRuntimeInfo | null): NetworkRuntimeSnapshot {
    if (!info) {
      return { ip: '-', netMask: '-', gateway: '-', dns1: '-', dns2: '-' };
    }
    return {
      ip: this.displayNetworkValue(info.ip),
      netMask: this.displayNetworkValue(info.netMask),
      gateway: this.displayNetworkValue(info.gateway),
      dns1: this.displayNetworkValue(info.dns1),
      dns2: this.displayNetworkValue(info.dns2)
    };
  }

  private applyNetworkConfigToState(config: NetworkSettingsConfig): void {
    this.networkMode = config.mode;
    this.staticIp = config.ip;
    this.staticMask = config.netMask;
    this.staticGateway = config.gateway;
    this.staticDns1 = config.dns1;
    this.staticDns2 = config.dns2;
  }

  private applyRuntimeNetworkInfoToState(runtimeInfo: NetworkRuntimeInfo | null): void {
    if (!runtimeInfo) {
      this.dhcpIp = '-';
      this.dhcpMask = '-';
      this.dhcpGateway = '-';
      this.dhcpDns1 = '-';
      this.dhcpDns2 = '-';
      return;
    }
    this.dhcpIp = this.displayNetworkValue(runtimeInfo.ip);
    this.dhcpMask = this.displayNetworkValue(runtimeInfo.netMask);
    this.dhcpGateway = this.displayNetworkValue(runtimeInfo.gateway);
    this.dhcpDns1 = this.displayNetworkValue(runtimeInfo.dns1);
    this.dhcpDns2 = this.displayNetworkValue(runtimeInfo.dns2);
  }

  private displayNetworkValue(value: string): string {
    const text = value.trim();
    return text.length > 0 ? text : '-';
  }

  private syncCurrentSystemTime(updateEditor: boolean = false): void {
    const now = new Date();
    const dateText = SystemSettingsService.formatDate(now);
    const timeText = SystemSettingsService.formatTime(now);
    this.currentSystemTimeText = `${dateText} ${timeText}`;
    if (updateEditor) {
      this.systemDate = dateText;
      this.systemTime = timeText;
    }
  }

  private async refreshTimePage(updateEditor: boolean = false): Promise<void> {
    this.syncCurrentSystemTime(updateEditor);
    if (!MonitorService.isConnectedToMcu()) {
      this.instrumentTimeText = '设备未连接';
      return;
    }

    const instrumentTime = await MonitorService.readSystemTime();
    this.instrumentTimeText = instrumentTime ? instrumentTime.text : '读取失败';
  }

  private async handleSyncSystemTimeToInstrument(): Promise<void> {
    if (this.isTimeActionRunning) {
      return;
    }

    this.isTimeActionRunning = true;
    this.timeActionMessage = '正在同步系统时间到仪器';
    const now = new Date();
    const dateText = SystemSettingsService.formatDate(now);
    const timeText = SystemSettingsService.formatTime(now);
    const success = await OperationLogService.runWithLog({
      logType: OPERATION_LOG_TYPE_SYSTEM,
      action: '同步仪器时间',
      content: `同步系统时间到仪器 ${dateText} ${timeText}`,
      source: 'system_page'
    }, async (): Promise<boolean> => {
      if (!MonitorService.isConnectedToMcu()) {
        this.timeActionMessage = '设备未连接，无法同步仪器时间';
        return false;
      }
      const written = await MonitorService.writeSystemTime(
        now.getFullYear(),
        now.getMonth() + 1,
        now.getDate(),
        now.getHours(),
        now.getMinutes(),
        now.getSeconds()
      );
      this.timeActionMessage = written ? '系统时间已同步到仪器' : '仪器时间写入失败';
      return written;
    });
    await this.refreshTimePage(false);
    if (success) {
      this.systemDate = dateText;
      this.systemTime = timeText;
    }
    this.isTimeActionRunning = false;
    this.runSystemAction();
  }

  private async handleSaveNetworkSettings(): Promise<void> {
    await OperationLogService.runWithLog({
      logType: OPERATION_LOG_TYPE_SYSTEM,
      action: '保存网络设置',
      content: '保存网络设置',
      source: 'system_page'
    }, async (): Promise<boolean> => {
      const context = this.getHostContext();
      if (!context) {
        return false;
      }

      const config: NetworkSettingsConfig = {
        iface: SystemSettingsService.getDefaultNetworkConfig().iface,
        mode: this.networkMode === 'static' ? 'static' : 'dhcp',
        ip: this.staticIp,
        netMask: this.staticMask,
        gateway: this.staticGateway,
        dns1: this.staticDns1,
        dns2: this.staticDns2
      };
      const saved = await SystemSettingsService.saveNetworkConfig(context, config);
      if (saved) {
        await this.syncNetworkSettings();
      }
      return saved;
    });
    this.runSystemAction();
  }

  private async handleSetUnifiedTime(): Promise<void> {
    if (this.isTimeActionRunning) {
      return;
    }

    const parts: DateTimeParts | null = SystemSettingsService.parseDateTimeParts(this.systemDate, this.systemTime);
    if (!parts) {
      this.timeActionMessage = '日期或时间格式无效';
      return;
    }
    if (parts.year < 1970 || parts.year > 2225) {
      this.timeActionMessage = '仪器支持的年份范围为 1970 至 2225';
      return;
    }
    if (!MonitorService.isConnectedToMcu()) {
      this.instrumentTimeText = '设备未连接';
      this.timeActionMessage = '设备未连接，未修改系统和仪器时间';
      return;
    }

    this.isTimeActionRunning = true;
    this.timeActionMessage = '正在统一设置系统和仪器时间';
    await OperationLogService.runWithLog({
      logType: OPERATION_LOG_TYPE_SYSTEM,
      action: '统一设置时间',
      content: `统一设置系统和仪器时间 ${this.systemDate} ${this.systemTime}`,
      source: 'system_page'
    }, async (): Promise<boolean> => {
      const systemUpdated = await SystemSettingsService.setSystemDateTime(this.systemDate, this.systemTime);
      if (!systemUpdated) {
        this.timeActionMessage = '系统时间设置失败，仪器时间未修改';
        return false;
      }

      const instrumentUpdated = await MonitorService.writeSystemTime(
        parts.year,
        parts.month,
        parts.day,
        parts.hour,
        parts.minute,
        parts.second
      );
      if (!instrumentUpdated) {
        this.timeActionMessage = '系统时间已修改，但仪器时间写入失败';
        return false;
      }
      this.timeActionMessage = '系统和仪器时间设置成功';
      return true;
    });
    await this.refreshTimePage(false);
    this.isTimeActionRunning = false;
    this.runSystemAction();
  }

  private getHostContext(): common.Context | null {
    const context = this.getUIContext().getHostContext();
    if (!context) {
      return null;
    }
    return context as common.Context;
  }

  private runSystemAction(): void {
    this.actionVersion++;
  }

  private async refreshBoardInfoIfChanged(): Promise<void> {
    try {
      const newInfo = await MonitorService.readBoardInfo();
      if (!newInfo) {
        return;
      }
      const cached = SystemInfoSessionStore.getBoardInfo();
      if (!cached || JSON.stringify(newInfo) !== JSON.stringify(cached)) {
        SystemInfoSessionStore.updateBoardInfo(newInfo);
      }
    } catch (err) {
      // 读取失败静默忽略，保持旧数据
    }
  }

  @Builder
  private systemContent() {
    if (this.selectedSystemTab === this.systemTabs[0]) {
      InstrumentInfoPanel({
        systemInfoList: this.systemInfoList,
        viewportWidth: this.viewportWidth,
        viewportHeight: this.viewportHeight,
        scaleFactor: this.scaleFactor
      });
    } else if (this.selectedSystemTab === this.systemTabs[1]) {
      BoardInfoPanel({
        boardRows: this.boardInfoRows,
        viewportWidth: this.viewportWidth,
        viewportHeight: this.viewportHeight,
        scaleFactor: this.scaleFactor
      });
    } else if (this.selectedSystemTab === this.systemTabs[2]) {
      NetworkSettingsPanel({
        networkMode: this.networkMode,
        staticIp: this.staticIp,
        staticMask: this.staticMask,
        staticGateway: this.staticGateway,
        staticDns1: this.staticDns1,
        staticDns2: this.staticDns2,
        dhcpIp: this.dhcpIp,
        dhcpMask: this.dhcpMask,
        dhcpGateway: this.dhcpGateway,
        dhcpDns1: this.dhcpDns1,
        dhcpDns2: this.dhcpDns2,
        viewportWidth: this.viewportWidth,
        viewportHeight: this.viewportHeight,
        scaleFactor: this.scaleFactor,
        onSystemAction: () => {
          void this.handleSaveNetworkSettings();
        }
      });
    } else if (this.selectedSystemTab === this.systemTabs[3]) {
      SystemTimePanel({
        systemDate: this.systemDate,
        systemTime: this.systemTime,
        currentSystemTimeText: this.currentSystemTimeText,
        instrumentTimeText: this.instrumentTimeText,
        actionMessage: this.timeActionMessage,
        isActionRunning: this.isTimeActionRunning,
        viewportWidth: this.viewportWidth,
        viewportHeight: this.viewportHeight,
        scaleFactor: this.scaleFactor,
        onSyncInstrumentTime: () => {
          void this.handleSyncSystemTimeToInstrument();
        },
        onSetUnifiedTime: () => {
          void this.handleSetUnifiedTime();
        }
      });
    } else if (this.selectedSystemTab === this.systemTabs[4]) {
      SystemSettingsPanel({
        viewportWidth: this.viewportWidth,
        viewportHeight: this.viewportHeight,
        scaleFactor: this.scaleFactor,
        onSystemAction: () => {
          this.runSystemAction();
        }
      });
    }
    /*
    else if (this.selectedSystemTab === this.systemTabs[5]) {
      CommunicationConfigPanel({
        viewportWidth: this.viewportWidth,
        viewportHeight: this.viewportHeight,
        scaleFactor: this.scaleFactor,
        onSystemAction: () => {
          this.runSystemAction();
        }
      });
    }
    */
    // else if (this.selectedSystemTab === this.systemTabs[6]) {
    //   UartDebugPanel({
    //     viewportWidth: this.viewportWidth,
    //     viewportHeight: this.viewportHeight,
    //     scaleFactor: this.scaleFactor,
    //     onSystemAction: () => {
    //       this.runSystemAction();
    //     }
    //   });
    // } else if (this.selectedSystemTab === this.systemTabs[7]) {
    //   DebugPanel({
    //     viewportWidth: this.viewportWidth,
    //     viewportHeight: this.viewportHeight,
    //     scaleFactor: this.scaleFactor,
    //     onSystemAction: () => {
    //       this.runSystemAction();
    //     }
    //   });
    // }
    else {
      InstrumentInfoPanel({
        systemInfoList: this.systemInfoList,
        viewportWidth: this.viewportWidth,
        viewportHeight: this.viewportHeight,
        scaleFactor: this.scaleFactor
      });
    }
  }

  build() {
    Row() {
      GradientSideTabBar({
        tabs: this.systemTabs,
        selectedTab: this.selectedSystemTab,
        viewportWidth: this.viewportWidth,
        viewportHeight: this.viewportHeight,
        scaleFactor: this.scaleFactor,
        onTabChange: (tab: string) => {
          this.selectedSystemTab = tab;
          if (tab === this.systemTabs[0]) {
            void this.loadInstrumentInfoFromSettings();
          } else if (tab === this.systemTabs[1]) {
            void this.refreshBoardInfoIfChanged();
          } else if (tab === this.systemTabs[2]) {
            void this.syncNetworkSettings();
          } else if (tab === this.systemTabs[3]) {
            this.timeActionMessage = '';
            void this.refreshTimePage(true);
          }
        }
      })

      this.systemContent();
    }
    .width('100%')
    .height('100%')
    .constraintSize({ minHeight: '100%' })
    .alignItems(VerticalAlign.Top)
    .backgroundColor('#F7F7F7')
  }
}
