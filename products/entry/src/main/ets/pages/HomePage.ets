import { hilog } from '@kit.PerformanceAnalysisKit';
import { UiUtil } from 'base';
import { DataActionButton } from '../components/DataActionButton';
import { StatusChip } from '../components/StatusChip';
import { MeasureType } from 'flow';

import {
  ConnectionSnapshot,
  DeviceEvent,
  MeasurementDisplaySnapshot,
  RuntimeSnapshot
} from '../models/deviceStateTypes';
import { DeviceEventBus } from '../services/DeviceEventBus';
import { DevicePollingCoordinator } from '../services/DevicePollingCoordinator';
import { DeviceStateStore } from '../services/DeviceStateStore';
import { MonitorService } from '../services/MonitorService';
import { ResultManager, MeasureRecord } from 'dataservice';
import { dncp } from 'communication';

const DOMAIN = 0x0001;
const TAG = 'HomePage';

@Component
export struct HomePage {
  @Prop viewportWidth: number = 1024;
  @Prop viewportHeight: number = 768;
  @Prop scaleFactor: number = 1.92;
  @Prop isActivate: boolean = true;
  @Prop canOperateInstrument: boolean = true;
  // Home page owns measurement UI state and talks to MonitorService directly.
  @State private currentIndicator: string = '-';
  // 显示设备复合结果时间，来源为输入寄存器 238；没有有效结果快照时保留占位值。
  @State private sampleTime: string = 'xxxx-xx-xx xx:xx:xx';
  @State private mainValue: string = '-';
  @State private mainUnit: string = '-';
  @State private measurementResultType: string = '-';
  @State private isMeasuring: boolean = false;
  @State private isMcuConnected: boolean = false;
  @State private runningSeconds: number = 0;
  @State private systemStatusText: string = '空闲中';
  @State private currentActionText: string = '空闲中';
  @State private currentActionSeconds: number = 0;
  @State private connectionStatusLabel: string = '未连接';
  @State private showCalibrationDialog: boolean = false;
  @State private isCalibrationSubmitting: boolean = false;
  @State private calibrationDialogMessage: string = '';
  @State private isStoppingCurrentOperation: boolean = false;
  @State private operationMessage: string = '';
  // 1-second timer id for runtime refresh.
  private timeInterval: number = -1;
  // Concurrency guard for polling request.
  private isPollingMeasurement: boolean = false;
  // 系统行为
  private currentActionKey: string = '';
  private currentActionStartedAt: number = 0;
  private isPollingRuntimeInfo: boolean = false;
  private wasActivate: boolean = true;
  private unsubscribeConnection: (() => void) | null = null;
  private unsubscribeRuntime: (() => void) | null = null;
  private unsubscribeMeasurement: (() => void) | null = null;
  private releaseConnectionInterest: (() => void) | null = null;
  private releaseRuntimeInterest: (() => void) | null = null;
  private releaseMeasurementInterest: (() => void) | null = null;

  private async refreshRuntimeInfo(): Promise<void> {
    if (this.isPollingRuntimeInfo) {
      return;
    }

    this.isPollingRuntimeInfo = true;
    try {
      await DevicePollingCoordinator.requestRefresh('runtime');
      this.applyRuntimeSnapshot(DeviceStateStore.getRuntimeSnapshot());
    } finally {
      this.isPollingRuntimeInfo = false;
    }
  }

  private applyDisconnectedRuntimeState(): void {
    this.isMcuConnected = false;
    this.connectionStatusLabel = '未连接';
    this.measurementResultType = '-';
    this.systemStatusText = '未连接';
    if (this.currentActionText !== '未连接') {
      this.currentActionText = '未连接';
      this.currentActionKey = '';
      this.currentActionStartedAt = 0;
      this.currentActionSeconds = 0;
    }
  }

  private syncMeasurementParameter(): void {
    const name = MonitorService.getCurrentMeasurementParamName();
    const paramInfo = MonitorService.getCurrentMeasurementParameterInfo();
    this.currentIndicator = name.length > 0 ? name : '-';
    this.mainUnit = paramInfo.unit.length > 0 ? paramInfo.unit : 'mg/L';
  }

  private formatMeasurementResultType(code: number | string, label: string): string {
    const resultTypeCode = UiUtil.codeToNumber(code);
    if (resultTypeCode === 0 || resultTypeCode === 1 || resultTypeCode === 2 ||
      resultTypeCode === 7 || resultTypeCode === 10) {
      return label;
    }
    return '-';
  }

  // Refresh register 236 and its result type without allowing overlapping requests.
  private async refreshMeasurementDisplay(): Promise<void> {
    if (this.isPollingMeasurement || !MonitorService.isConnectedToMcu()) {
      return;
    }
    this.isPollingMeasurement = true;
    try {
      await DevicePollingCoordinator.requestRefresh('measurement');
      this.applyMeasurementSnapshot(DeviceStateStore.getMeasurementDisplaySnapshot());
    } finally {
      this.isPollingMeasurement = false;
    }
  }

  // Stop the current instrument task only when system status or current action is not idle.
  private async handleStopCurrentOperation(): Promise<void> {
    if (!this.canOperateInstrument || this.isStoppingCurrentOperation) {
      return;
    }

    if (!MonitorService.isConnectedToMcu()) {
      this.applyDisconnectedRuntimeState();
      this.operationMessage = '设备未连接，无法停止当前任务';
      return;
    }

    this.isStoppingCurrentOperation = true;
    this.operationMessage = '';
    try {
      const status = await MonitorService.readSystemStatus();
      const action = await MonitorService.readCurrentAction();
      this.isMcuConnected = MonitorService.isConnectedToMcu();

      if (!this.isMcuConnected) {
        this.applyDisconnectedRuntimeState();
        this.operationMessage = '设备连接已断开';
        return;
      }
      if (!status || !action) {
        this.operationMessage = '读取仪器运行状态失败';
        return;
      }

      this.systemStatusText = status.label;
      this.currentActionText = action.label;
      const statusCode = UiUtil.codeToNumber(status.code);
      const actionCode = UiUtil.codeToNumber(action.code);
      if (statusCode === null || actionCode === null) {
        this.operationMessage = '仪器运行状态无法识别';
        return;
      }
      if (statusCode === 0 && actionCode === 0) {
        this.operationMessage = '仪器当前处于空闲状态';
        return;
      }

      const taskName = actionCode !== 0 ? action.label : status.label;
      this.operationMessage = `正在停止：${taskName}`;
      const stopped = await MonitorService.stopCurrentOperation();
      if (!stopped) {
        this.operationMessage = `停止失败：${taskName}`;
        return;
      }

      this.operationMessage = `停止命令已下发：${taskName}`;
      this.currentActionStartedAt = Date.now();
      this.currentActionSeconds = 0;
      await this.refreshRuntimeInfo();
    } finally {
      this.isStoppingCurrentOperation = false;
    }
  }

  private openCalibrationDialog(): void {
    if (this.isCalibrationSubmitting || !this.canOperateInstrument) {
      return;
    }
    this.operationMessage = '';
    this.calibrationDialogMessage = '';
    this.showCalibrationDialog = true;
  }

  private closeCalibrationDialog(): void {
    if (this.isCalibrationSubmitting) {
      return;
    }
    this.showCalibrationDialog = false;
    this.calibrationDialogMessage = '';
  }

  private async syncAfterControlCommand(): Promise<void> {
    await DevicePollingCoordinator.requestRefresh('connection');
    this.applyConnectionSnapshot(DeviceStateStore.getConnectionSnapshot());
    if (!this.isMcuConnected) {
      this.applyDisconnectedRuntimeState();
      return;
    }

    await DevicePollingCoordinator.requestRefresh('measurement');
    await DevicePollingCoordinator.requestRefresh('runtime');
    this.applyMeasurementSnapshot(DeviceStateStore.getMeasurementDisplaySnapshot());
    this.applyRuntimeSnapshot(DeviceStateStore.getRuntimeSnapshot());
  }

  private handleStartCalibration(): void {
    this.openCalibrationDialog();
  }

  // Forward current-range calibration command to communication service.
  private async handleCalibrateCurrentRange(): Promise<void> {
    if (this.isCalibrationSubmitting || !this.canOperateInstrument) {
      return;
    }

    this.isCalibrationSubmitting = true;
    this.calibrationDialogMessage = '';

    try {
      hilog.info(DOMAIN, TAG, 'Start current range calibration');
      const started = await MonitorService.startCalibration();
      if (!started) {
        hilog.error(DOMAIN, TAG, 'Start current range calibration failed');
        this.calibrationDialogMessage = '校准当前量程曲线启动失败';
        await this.syncAfterControlCommand();
        return;
      }

      await this.syncAfterControlCommand();
      this.showCalibrationDialog = false;
    } finally {
      this.isCalibrationSubmitting = false;
    }
  }

  private async handleReagentUpdateAndCalibrateAllRanges(): Promise<void> {
    if (this.isCalibrationSubmitting || !this.canOperateInstrument) {
      return;
    }
    this.isMcuConnected = MonitorService.isConnectedToMcu();

    this.isCalibrationSubmitting = true;
    this.calibrationDialogMessage = '';

    try {
      // 疑问点：当前协议只在“当前动作”输入寄存器里定义了 code=46 的“一键更新试剂”，
      // 测量控制保持寄存器暂未定义对应可写控制码，所以这里只发送读命令并忽略响应，再继续校准流程。
      hilog.info(DOMAIN, TAG, 'Read reagent update action before calibration');
      await MonitorService.readCurrentAction();

      const started = await MonitorService.startCalibration();
      this.isMcuConnected = MonitorService.isConnectedToMcu();
      if (!started) {
        hilog.error(DOMAIN, TAG, 'Start reagent update calibration failed');
        this.calibrationDialogMessage = '试剂更新并校准所有量程曲线启动失败';
        await this.syncAfterControlCommand();
        return;
      }

      await this.syncAfterControlCommand();
      this.showCalibrationDialog = false;
    } finally {
      this.isCalibrationSubmitting = false;
    }
  }

  // Forward standard sample check command to communication service.
  private async handleStartSpanCheck(): Promise<void> {
    if (!this.canOperateInstrument) {
      return;
    }
    this.operationMessage = '';
    hilog.info(DOMAIN, TAG, 'Start span check');
    const started = await MonitorService.startSpanCheck();
    this.isMcuConnected = MonitorService.isConnectedToMcu();

    if (!started) {
      hilog.error(DOMAIN, TAG, 'Start span check failed');
      return;
    }

    if (this.isMcuConnected) {
      await this.refreshMeasurementDisplay();
      await this.refreshRuntimeInfo();
    }
  }

  private updateCurrentActionSecondsFromTimer(): void {
    if (this.currentActionStartedAt <= 0 || this.currentActionText === '未连接') {
      this.currentActionSeconds = 0;
      return;
    }
    this.currentActionSeconds = Math.max(0, Math.floor((Date.now() - this.currentActionStartedAt) / 1000));
  }

  // Per-second UI refresh:
  // sampleTime 不在这里刷新，它只随 measurement 快照中的复合结果时间更新。
  // 这里仅更新当前动作持续时间，保证空闲/运行计时每秒稳定变化。
  private updateCurrentTime(): void {
    if (this.isActivate && !this.wasActivate) {
      void DevicePollingCoordinator.requestRefresh('connection');
      void DevicePollingCoordinator.requestRefresh('runtime');
      void DevicePollingCoordinator.requestRefresh('measurement');
    }
    this.wasActivate = this.isActivate;

    if (this.isMeasuring) {
      this.runningSeconds = MonitorService.getMeasurementRunningSeconds();
    } else {
      this.runningSeconds = 0;
    }

    this.updateCurrentActionSecondsFromTimer();
    this.applyRuntimeSnapshot(DeviceStateStore.getRuntimeSnapshot());
    this.applyMeasurementSnapshot(DeviceStateStore.getMeasurementDisplaySnapshot());
  }

  private applyConnectionSnapshot(snapshot: ConnectionSnapshot): void {
    this.isMcuConnected = snapshot.connected;
    this.connectionStatusLabel = snapshot.statusLabel.length > 0 ? snapshot.statusLabel :
      (snapshot.connected ? '已连接' : '未连接');
    if (!snapshot.connected) {
      this.measurementResultType = '-';
      this.systemStatusText = '未连接';
      if (this.currentActionText !== '未连接') {
        this.currentActionText = '未连接';
        this.currentActionKey = '';
        this.currentActionStartedAt = 0;
        this.currentActionSeconds = 0;
      }
    }
  }

  private applyRuntimeSnapshot(snapshot: RuntimeSnapshot): void {
    const connection = DeviceStateStore.getConnectionSnapshot();
    this.isMcuConnected = connection.connected;
    this.connectionStatusLabel = connection.statusLabel.length > 0 ? connection.statusLabel :
      (connection.connected ? '已连接' : '未连接');
    if (!connection.connected) {
      this.measurementResultType = '-';
      this.systemStatusText = '未连接';
      if (this.currentActionText !== '未连接') {
        this.currentActionText = '未连接';
        this.currentActionKey = '';
        this.currentActionStartedAt = 0;
        this.currentActionSeconds = 0;
      }
      return;
    }

    if (!snapshot.valid) {
      return;
    }

    this.systemStatusText = snapshot.systemStatusLabel;
    const nextKey = snapshot.currentActionCode === null ? '' : `${snapshot.currentActionCode}`;
    if (nextKey !== this.currentActionKey || this.currentActionStartedAt <= 0) {
      this.currentActionKey = nextKey;
      this.currentActionStartedAt = snapshot.actionStartedAt > 0 ? snapshot.actionStartedAt : Date.now();
    }
    this.currentActionText = snapshot.currentActionLabel;
    this.updateCurrentActionSecondsFromTimer();
  }

  private applyMeasurementSnapshot(snapshot: MeasurementDisplaySnapshot): void {
    this.currentIndicator = snapshot.parameter.name.length > 0 ? snapshot.parameter.name : '-';
    this.mainUnit = snapshot.unit.length > 0 ? snapshot.unit : 'mg/L';
    this.isMeasuring = snapshot.measuring;
    this.runningSeconds = snapshot.runningSeconds;
    if (snapshot.value !== null) {
      this.mainValue = snapshot.value.toFixed(3);
      this.sampleTime = UiUtil.formatDateTime(new Date(snapshot.sampleTime));
    }
    // sampleTime 当前显示复合结果时间；若后续要展示其他设备时间，应在 measurement 快照内统一切换来源。
    this.measurementResultType = snapshot.resultType ?
      this.formatMeasurementResultType(snapshot.resultType.code, snapshot.resultType.label) : '-';
  }

  private runtimeBadgeText(): string {
    return this.systemStatusText.length > 0 ? this.systemStatusText : (this.isMeasuring ? '运行' : '空闲')
  }

  private measurementStatusText(): string {
    return this.currentActionText.length > 0 ?
      `${this.currentActionText}  ${UiUtil.formatDuration(this.currentActionSeconds)}` :
      (this.isMeasuring ? '运行' : '空闲')
  }

  private connectionStatusText(): string {
    return `通讯  ${this.connectionStatusLabel}`;
  }
  private parseMeasureTypesToString(type: MeasureType): string {
    const MeasureTypeLabel: Map<MeasureType, string> = new Map([
      [MeasureType.Blank, '零点校准液'],
      [MeasureType.Sample, '水样'],
      [MeasureType.Standard, '量程校准液'],
      [MeasureType.Check, '标样(跨度)核查液'],
      [MeasureType.AddStandard, '加标样'],
      [MeasureType.Parallel, '平行样'],
      [MeasureType.ZeroCheck, '零点核查液'],
      [MeasureType.RangeCheck, '标样(跨度)核查液'],
      [MeasureType.ExtAddStandard, '外部加标'],
      [MeasureType.ExtParallel, '外部平行'],
      [MeasureType.QualityHandle, '质控'],
    ]);

    // ✅ 使用方式
    const label: string = MeasureTypeLabel.get(type) ?? '未知类型';
    return label;
  }

  private async getValue(): Promise<void> {
    const result = await ResultManager.getInstance().getLatestMeasureRecord();
    if (result) {
      this.measurementResultType = this.parseMeasureTypesToString(result.resultType);
      this.mainValue = result.consistency.toFixed(3).toString();
      this.sampleTime = UiUtil.formatDateTimestamp(result.dateTime);
      // console.info(`TLQQ, homepage ${result.resultType} ${this.mainValue} ${this.sampleTime} ${result.dateTime} `);
    }
  }

  // Register listeners and start 1-second timer when home page appears.
  aboutToAppear(): void {
    //初始化DNCP 保证全局只初始化一次
    dncp.createPlugin();
    dncp.addSlaveNode(1);
    dncp.initDncpStack("/dev/ttyS0",false, '',
      (pollingAddr: number, status: boolean) => {
        console.info(`[DNCP] Device ${pollingAddr} status: ${status}`);
      });
    console.log('通信模块初始化完成');

    this.releaseDeviceSubscriptions();
    MonitorService.setMeasurementParamListener((_, name: string) => {
      this.currentIndicator = name;
      const unit = MonitorService.getCurrentMeasurementParameterInfo().unit;
      this.mainUnit = unit.length > 0 ? unit : this.mainUnit;
    });

    MonitorService.setMeasurementStateListener((isMeasuring: boolean) => {
      this.isMeasuring = isMeasuring;
      this.runningSeconds = MonitorService.getMeasurementRunningSeconds();
      void DevicePollingCoordinator.requestRefresh('measurement');
    });
    this.isMeasuring = MonitorService.isMeasurementRunning();
    this.runningSeconds = MonitorService.getMeasurementRunningSeconds();
    this.unsubscribeConnection = DeviceEventBus.subscribe('connection', (event: DeviceEvent) => {
      this.applyConnectionSnapshot(event.current as ConnectionSnapshot);
    });
    this.unsubscribeRuntime = DeviceEventBus.subscribe('runtime', (event: DeviceEvent) => {
      this.applyRuntimeSnapshot(event.current as RuntimeSnapshot);
    });
    this.unsubscribeMeasurement = DeviceEventBus.subscribe('measurement', (event: DeviceEvent) => {
      this.applyMeasurementSnapshot(event.current as MeasurementDisplaySnapshot);
    });
    this.releaseConnectionInterest = DevicePollingCoordinator.registerTopicInterest('connection', 'HomePage');
    this.releaseRuntimeInterest = DevicePollingCoordinator.registerTopicInterest('runtime', 'HomePage');
    this.releaseMeasurementInterest = DevicePollingCoordinator.registerTopicInterest('measurement', 'HomePage');
    this.applyConnectionSnapshot(DeviceStateStore.getConnectionSnapshot());
    this.applyRuntimeSnapshot(DeviceStateStore.getRuntimeSnapshot());
    this.applyMeasurementSnapshot(DeviceStateStore.getMeasurementDisplaySnapshot());

    if (this.isMcuConnected) {
      this.syncMeasurementParameter();
      void DevicePollingCoordinator.requestRefresh('measurement');
      void DevicePollingCoordinator.requestRefresh('runtime');
    } else {
      this.applyDisconnectedRuntimeState();
    }

    this.updateCurrentTime();
    this.timeInterval = setInterval(() => {
      this.updateCurrentTime();
      this.getValue();
    }, 1000);
  }

  // Release listeners and timer when home page disappears.
  aboutToDisappear(): void {
    MonitorService.setMeasurementParamListener(null);
    MonitorService.setMeasurementStateListener(null);
    this.releaseDeviceSubscriptions();
    if (this.timeInterval !== -1) {
      clearInterval(this.timeInterval);
      this.timeInterval = -1;
    }
  }

  private releaseDeviceSubscriptions(): void {
    if (this.unsubscribeConnection) {
      this.unsubscribeConnection();
      this.unsubscribeConnection = null;
    }
    if (this.unsubscribeRuntime) {
      this.unsubscribeRuntime();
      this.unsubscribeRuntime = null;
    }
    if (this.unsubscribeMeasurement) {
      this.unsubscribeMeasurement();
      this.unsubscribeMeasurement = null;
    }
    if (this.releaseConnectionInterest) {
      this.releaseConnectionInterest();
      this.releaseConnectionInterest = null;
    }
    if (this.releaseRuntimeInterest) {
      this.releaseRuntimeInterest();
      this.releaseRuntimeInterest = null;
    }
    if (this.releaseMeasurementInterest) {
      this.releaseMeasurementInterest();
      this.releaseMeasurementInterest = null;
    }
  }

  @Builder
  private calibrationDialogOverlay() {
    Stack({ alignContent: Alignment.Center }) {
      Column() {
        Row() {
          Text('一键校准')
            .fontSize(UiUtil.vh(2.2, 16, 24, this.viewportHeight, this.scaleFactor))
            .fontWeight(FontWeight.Bold)
            .fontColor('#1F2937')

          Blank()

          Text('×')
            .width(UiUtil.vh(3.6, 28, 36, this.viewportHeight, this.scaleFactor))
            .height(UiUtil.vh(3.6, 28, 36, this.viewportHeight, this.scaleFactor))
            .fontSize(UiUtil.vh(2.6, 18, 26, this.viewportHeight, this.scaleFactor))
            .fontColor('#334155')
            .fontWeight(FontWeight.Medium)
            .textAlign(TextAlign.Center)
            .borderRadius(UiUtil.vh(0.6, 4, 8, this.viewportHeight, this.scaleFactor))
            .backgroundColor('#EEF2F7')
            .opacity(this.isCalibrationSubmitting ? 0.45 : 1)
            .onClick(() => {
              this.closeCalibrationDialog();
            })
        }
        .width('100%')
        .height(UiUtil.vh(5.6, 42, 56, this.viewportHeight, this.scaleFactor))
        .alignItems(VerticalAlign.Center)
        .margin({ bottom: UiUtil.vh(1.2, 8, 14, this.viewportHeight, this.scaleFactor) })

        DataActionButton({
          label: '校准当前量程曲线',
          buttonWidth: UiUtil.vw(36.0, 292, 456, this.viewportWidth, this.scaleFactor),
          buttonHeight: UiUtil.vh(6.8, 50, 68, this.viewportHeight, this.scaleFactor),
          fontSizeValue: UiUtil.vh(1.9, 13, 18, this.viewportHeight, this.scaleFactor),
          borderRadiusValue: UiUtil.vh(0.8, 6, 8, this.viewportHeight, this.scaleFactor),
          onAction: () => {
            void this.handleCalibrateCurrentRange();
          }
        })
          .opacity(this.isCalibrationSubmitting ? 0.65 : 1)

        DataActionButton({
          label: '试剂更新并校准所有量程曲线',
          buttonWidth: UiUtil.vw(36.0, 292, 456, this.viewportWidth, this.scaleFactor),
          buttonHeight: UiUtil.vh(6.8, 50, 68, this.viewportHeight, this.scaleFactor),
          fontSizeValue: UiUtil.vh(1.75, 12, 16, this.viewportHeight, this.scaleFactor),
          borderRadiusValue: UiUtil.vh(0.8, 6, 8, this.viewportHeight, this.scaleFactor),
          marginTop: UiUtil.vh(1.2, 8, 14, this.viewportHeight, this.scaleFactor),
          onAction: () => {
            void this.handleReagentUpdateAndCalibrateAllRanges();
          }
        })
          .opacity(this.isCalibrationSubmitting ? 0.65 : 1)

        if (this.calibrationDialogMessage.length > 0) {
          Text(this.calibrationDialogMessage)
            .width('100%')
            .fontSize(UiUtil.vh(1.55, 11, 15, this.viewportHeight, this.scaleFactor))
            .fontColor('#B45309')
            .textAlign(TextAlign.Center)
            .margin({ top: UiUtil.vh(1.3, 8, 14, this.viewportHeight, this.scaleFactor) })
        }
      }
      .width(UiUtil.vw(42.0, 340, 520, this.viewportWidth, this.scaleFactor))
      .padding({
        left: UiUtil.vw(2.0, 18, 28, this.viewportWidth, this.scaleFactor),
        right: UiUtil.vw(2.0, 18, 28, this.viewportWidth, this.scaleFactor),
        top: UiUtil.vh(1.8, 14, 22, this.viewportHeight, this.scaleFactor),
        bottom: UiUtil.vh(2.2, 16, 26, this.viewportHeight, this.scaleFactor)
      })
      .borderRadius(UiUtil.vh(0.9, 6, 8, this.viewportHeight, this.scaleFactor))
      .border({ width: UiUtil.vh(0.1, 1, 1.6, this.viewportHeight, this.scaleFactor), color: '#D7DEE8' })
      .backgroundColor('#FFFFFF')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#99000000')
    .zIndex(20)
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column() {
        // Middle instrument background and core measurement display.
        Stack() {
          Image($r('app.media.middle'))
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Fill)

          Text(this.measurementResultType)
            .fontSize(UiUtil.vh(1.8, 12, 20, this.viewportHeight, this.scaleFactor))
            .fontColor('#00FF00')
            .fontWeight(FontWeight.Medium)
            .position({
              x: UiUtil.vw(4.0, 32, 48, this.viewportWidth, this.scaleFactor),
              y: UiUtil.vh(2.0, 32, 52, this.viewportHeight, this.scaleFactor)
            })

          Column() {
            // Current monitored indicator.
            Text('监测指标 : ' + this.currentIndicator)
              .fontSize(UiUtil.vh(2.5, 16, 30, this.viewportHeight, this.scaleFactor))
              .fontColor('#00FF00')
              .fontWeight(FontWeight.Medium)
              .margin({ top: UiUtil.vh(2.8, 20, 30, this.viewportHeight, this.scaleFactor) })

            // Latest sample time.
            Text(this.sampleTime)
              .fontSize(UiUtil.vh(2.0, 13, 23, this.viewportHeight, this.scaleFactor))
              .fontColor('#00FF00')
              .margin({ top: UiUtil.vh(0.9, 6, 12, this.viewportHeight, this.scaleFactor) })

            // Main measurement value (largest text).
            // 样例值
            Text(this.mainValue)
              .fontSize(UiUtil.vh(8.0, 46, 92, this.viewportHeight, this.scaleFactor))
              .fontWeight(FontWeight.Bold)
              .fontColor('#00FF00')
              .margin({ top: UiUtil.vh(0.8, 6, 12, this.viewportHeight, this.scaleFactor) })

            // Unit for measurement value.
            // 值的单位
            Text(this.mainUnit)
              .fontSize(UiUtil.vh(2.9, 18, 34, this.viewportHeight, this.scaleFactor))
              .fontColor('#00FF00')
              .fontWeight(FontWeight.Medium)
              .margin({
                top: -UiUtil.vh(0.3, 2, 5, this.viewportHeight, this.scaleFactor),
                bottom: UiUtil.vh(0.8, 6, 12, this.viewportHeight, this.scaleFactor)
              })
          }
          .width('100%')
          .height('100%')
          .alignItems(HorizontalAlign.Center)
          .padding({ bottom: UiUtil.vh(1.8, 12, 24, this.viewportHeight, this.scaleFactor) })
        }
        .width('96%')
        .height(UiUtil.vh(44.5, 192, 300, this.viewportHeight, this.scaleFactor))
        .margin({ bottom: UiUtil.vh(0.5, 5, 8, this.viewportHeight, this.scaleFactor) })

        // Operation button row for measurement/calibration/check actions.
        Row() {
          Stack() {
            Image($r('app.media.not_select'))
              .width('100%')
              .height('100%')
              .objectFit(ImageFit.Fill)
            Text('停止测量')
              .fontSize(UiUtil.vh(2.0, 14, 22, this.viewportHeight, this.scaleFactor))
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
          }
          .width('30%')
          .height(UiUtil.vh(9.0, 56, 92, this.viewportHeight, this.scaleFactor))
          .opacity(this.canOperateInstrument ? 1 : 0.45)
          .enabled(this.canOperateInstrument)
          .onClick(() => {
            void this.handleStopCurrentOperation();
          })

          Stack() {
            Image($r('app.media.not_select'))
              .width('100%')
              .height('100%')
              .objectFit(ImageFit.Fill)
            Text('一键校准')
              .fontSize(UiUtil.vh(2.0, 14, 22, this.viewportHeight, this.scaleFactor))
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
          }
          .width('30%')
          .height(UiUtil.vh(9.0, 56, 92, this.viewportHeight, this.scaleFactor))
          .opacity(this.canOperateInstrument ? 1 : 0.45)
          .enabled(this.canOperateInstrument)
          .onClick(() => {
            // Trigger one-click calibration command.
            this.handleStartCalibration();
          })

          Stack() {
            Image($r('app.media.not_select'))
              .width('100%')
              .height('100%')
              .objectFit(ImageFit.Fill)
            Text('标样核查')
              .fontSize(UiUtil.vh(2.0, 14, 22, this.viewportHeight, this.scaleFactor))
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
          }
          .width('30%')
          .height(UiUtil.vh(9.0, 56, 92, this.viewportHeight, this.scaleFactor))
          .opacity(this.canOperateInstrument ? 1 : 0.45)
          .enabled(this.canOperateInstrument)
          .onClick(() => {
            // Trigger standard sample checking command.
            void this.handleStartSpanCheck();
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceEvenly)
        .margin({
          top: UiUtil.vh(-3.0, -20, -5, this.viewportHeight, this.scaleFactor),
          bottom: UiUtil.vh(0.6, 4, 8, this.viewportHeight, this.scaleFactor)
        })

        if (this.operationMessage.length > 0) {
          Text(this.operationMessage)
            .width('94%')
            .height(UiUtil.vh(3.2, 24, 34, this.viewportHeight, this.scaleFactor))
            .fontSize(UiUtil.vh(1.45, 11, 15, this.viewportHeight, this.scaleFactor))
            .fontColor(this.operationMessage.indexOf('失败') >= 0 || this.operationMessage.indexOf('未连接') >= 0 ||
              this.operationMessage.indexOf('断开') >= 0 || this.operationMessage.indexOf('无法') >= 0 ? '#E53935' :
              '#0B9F9A')
            .textAlign(TextAlign.Center)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ bottom: UiUtil.vh(0.6, 4, 8, this.viewportHeight, this.scaleFactor) })
        }
      }
      .width('100%')
      .constraintSize({ minHeight: '100%' })
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Start)
      .padding({
        top: UiUtil.vh(0.8, 5, 10, this.viewportHeight, this.scaleFactor),
        left: UiUtil.vw(0.9, 8, 16, this.viewportWidth, this.scaleFactor),
        right: UiUtil.vw(0.9, 8, 16, this.viewportWidth, this.scaleFactor),
        bottom: UiUtil.vh(1.0, 6, 14, this.viewportHeight, this.scaleFactor)
      })
      .backgroundColor('#FFFFFF')

      if (this.showCalibrationDialog) {
        this.calibrationDialogOverlay();
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}
