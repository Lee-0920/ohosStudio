import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { UiUtil } from 'base';
import {
  AlarmSnapshot,
  DeviceEvent,
  RuntimeSnapshot
} from '../models/deviceStateTypes';
import { setting } from 'flow';
import { DeviceEventBus } from '../services/DeviceEventBus';
import { DevicePollingCoordinator } from '../services/DevicePollingCoordinator';
import { DeviceStateStore } from '../services/DeviceStateStore';
import { PT63EventService } from '../services/PT63EventService';
import {
  AlarmDisplaySettings,
  UserSettingsListener,
  UserSettingsService
} from '../services/UserSettingsService';
import {
  EventPack
} from 'communication';

const FOOTER_DOMAIN = 0x0003;
const FOOTER_TAG = 'FooterBar';

@Component
export struct FooterBar {
  // Current timestamp shown at footer right.
  @State currentTime: string = '';
  @Prop viewportWidth: number = 1024;
  @Prop viewportHeight: number = 768;
  @Prop scaleFactor: number = 1.92;

  @State private reactTemperatureText: string = '-';
  @State private alarmText: string = '当前无报警';
  @State private firstTimerLabel: string = '空闲';
  @State private secondTimerLabel: string = '空闲';
  private alarmSettings: AlarmDisplaySettings = UserSettingsService.getDefaultAlarmDisplaySettings();
  private userSettingsListener: UserSettingsListener | null = null;
  private unsubscribeAlarm: (() => void) | null = null;
  private releaseAlarmInterest: (() => void) | null = null;
  private unsubscribeRuntime: (() => void) | null = null;
  private releaseRuntimeInterest: (() => void) | null = null;
  private unsubscribePt63: (() => void) | null = null;
  private timer: number = -1;
  @State private firstTimerTargetSeconds: number = 0;
  @State private secondTimerTargetSeconds: number = 0;
  @State private firstTimerElapsedMs: number = 0;
  @State private secondTimerElapsedMs: number = 0;
  @State private currentSystemStatusCode: number | null = null;
  @State private currentActionCode: number | null = null;
  private lastRuntimeSource: string = '';
  private FirstTextTimerController = new TextTimerController();
  private SecondTextTimerController = new TextTimerController();

  private getHostContext(): common.Context | null {
    const context = this.getUIContext().getHostContext();
    if (!context) {
      return null;
    }
    return context as common.Context;
  }

  private async loadAlarmSettings(): Promise<void> {
    const context = this.getHostContext();
    if (!context) {
      this.alarmSettings = UserSettingsService.getCachedAlarmDisplaySettings();
      return;
    }
    this.alarmSettings = await UserSettingsService.loadAlarmDisplaySettings(context);
  }

  private async loadAlarmSettingsAndRefresh(): Promise<void> {
    await this.loadAlarmSettings();
    this.applyAlarmSnapshot(DeviceStateStore.getAlarmSnapshot());
  }

  private shouldDisplayAlarm(code: number): boolean {
    if (code >= 11 && code <= 18) {
      return this.alarmSettings.reagentReminderEnabled;
    }
    if (code === 29 || code === 41) {
      return this.alarmSettings.sampleExceededAlarmEnabled;
    }
    if (code === 47) {
      return this.alarmSettings.leakDetectEnabled;
    }
    return true;
  }

  private applyAlarmSnapshot(snapshot: AlarmSnapshot): void {
    if (!snapshot.valid || !snapshot.active || snapshot.alarmCode === null) {
      this.alarmText = '当前无报警';
      return;
    }

    this.alarmText = this.shouldDisplayAlarm(snapshot.alarmCode) ? snapshot.alarmLabel : '当前无报警';
  }

  private getRunStatusTimeSeconds(statusCode: number | null): number {
    console.info('getRunStatusTimeSeconds');
    if (statusCode === null) {
      return 0;
    }
    switch (statusCode) {
      case 1:
        return setting.runStatus.measureSample.GetTime?.() ?? 0;
      case 2:
        return setting.runStatus.measureStandard.GetTime?.() ?? 0;
      case 3:
        return setting.runStatus.measureBlank.GetTime?.() ?? 0;
      case 4:
        return setting.runStatus.calibrate.GetTime?.() ?? 0;
      case 5:
        return setting.runStatus.cleanDigestionRoom.GetTime?.() ?? 0;
      case 6:
        return setting.runStatus.cleanMeterPipe.GetTime?.() ?? 0;
      case 7:
        return setting.runStatus.cleanAll.GetTime?.() ?? 0;
      case 8:
        return setting.runStatus.collectSample.GetTime?.() ?? 0;
      case 9:
        return setting.runStatus.oneKeyMaintain.GetTime?.() ?? 0;
      case 10:
        return setting.runStatus.digesterCooling.GetTime?.() ?? 0;
      case 11:
        return setting.runStatus.autoPumpCheck.GetTime?.() ?? 0;
      case 22:
        return setting.runStatus.cleanDeeply.GetTime?.() ?? 0;
      case 29:
        return setting.runStatus.onlyCalibrateBlank.GetTime?.() ?? 0;
      case 30:
        return setting.runStatus.onlyCalibrateStandard.GetTime?.() ?? 0;
      case 33:
        return setting.runStatus.measureQualityHandle.GetTime?.() ?? 0;
      case 41:
        return setting.runStatus.measureCheckStandard.GetTime?.() ?? 0;
      case 44:
        return setting.runStatus.meterADAdjust.GetTime?.() ?? 0;
      case 45:
        return setting.runStatus.measureADAdjust.GetTime?.() ?? 0;
      case 46:
        return setting.runStatus.oneKeyRenew.GetTime?.() ?? 0;
      default:
        return 0;
    }
  }

  private getRunActionTimeSeconds(actionCode: number | null): number {
    if (actionCode === null) {
      return 0;
    }
    switch (actionCode) {
      case 1:
        return setting.runAction.measure.cleanBeforeMeasure.GetTime?.() ?? 0;
      case 2:
        return setting.runAction.measure.readInitialAD.GetTime?.() ?? 0;
      case 3:
        return setting.runAction.measure.rinse.GetTime?.() ?? 0;
      case 4:
        return setting.runAction.measure.addSample.GetTime?.() ?? 0;
      case 5:
        return setting.runAction.measure.addReagent1.GetTime?.() ?? 0;
      case 6:
        return setting.runAction.measure.addReagent2.GetTime?.() ?? 0;
      case 11:
        return setting.runAction.cleanMeterPipe.GetTime?.() ?? 0;
      case 12:
        return setting.runAction.measure.preheating.GetTime?.() ?? 0;
      case 13:
        return setting.runAction.measure.digest.GetTime?.() ?? 0;
      case 14:
        return setting.runAction.measure.digestCooling.GetTime?.() ?? 0;
      case 15:
        return setting.runAction.measure.readMeasureAD.GetTime?.() ?? 0;
      case 17:
        return setting.runAction.digestSafetyCheck.GetTime?.() ?? 0;
      case 18:
        return setting.runAction.collectSample.collect.GetTime?.() ?? 0;
      case 19:
        return setting.runAction.collectSample.silent.GetTime?.() ?? 0;
      case 20:
        return setting.runAction.measure.drainBeforeMeasure.GetTime?.() ?? 0;
      case 21:
        return setting.runAction.measure.drainAfterMeasure.GetTime?.() ?? 0;
      case 22:
        return setting.runAction.measure.cleanAfterMeasure.GetTime?.() ?? 0;
      default:
        return 0;
    }
  }

  private getRunStatusLabel(statusCode: number | null): string {
    if (statusCode === null) {
      return '空闲';
    }
    switch (statusCode) {
      case 1:
        return setting.runStatus.measureSample.text;
      case 2:
        return setting.runStatus.measureStandard.text;
      case 3:
        return setting.runStatus.measureBlank.text;
      case 4:
        return setting.runStatus.calibrate.text;
      case 5:
        return setting.runStatus.cleanDigestionRoom.text;
      case 6:
        return setting.runStatus.cleanMeterPipe.text;
      case 7:
        return setting.runStatus.cleanAll.text;
      case 8:
        return setting.runStatus.collectSample.text;
      case 9:
        return setting.runStatus.oneKeyMaintain.text;
      case 10:
        return setting.runStatus.digesterCooling.text;
      case 11:
        return setting.runStatus.autoPumpCheck.text;
      case 22:
        return setting.runStatus.cleanDeeply.text;
      case 29:
        return setting.runStatus.onlyCalibrateBlank.text;
      case 30:
        return setting.runStatus.onlyCalibrateStandard.text;
      case 33:
        return setting.runStatus.measureQualityHandle.text;
      case 41:
        return setting.runStatus.measureCheckStandard.text;
      case 44:
        return setting.runStatus.meterADAdjust.text;
      case 45:
        return setting.runStatus.measureADAdjust.text;
      case 46:
        return setting.runStatus.oneKeyRenew.text;
      default:
        return '空闲';
    }
  }

  private getRunActionLabel(actionCode: number | null): string {
    if (actionCode === null) {
      return '空闲';
    }
    switch (actionCode) {
      case 1:
        return setting.runAction.measure.cleanBeforeMeasure.text;
      case 2:
        return setting.runAction.measure.readInitialAD.text;
      case 3:
        return setting.runAction.measure.rinse.text;
      case 4:
        return setting.runAction.measure.addSample.text;
      case 5:
        return setting.runAction.measure.addReagent1.text;
      case 6:
        return setting.runAction.measure.addReagent2.text;
      case 11:
        return setting.runAction.cleanMeterPipe.text;
      case 12:
        return setting.runAction.measure.preheating.text;
      case 13:
        return setting.runAction.measure.digest.text;
      case 14:
        return setting.runAction.measure.digestCooling.text;
      case 15:
        return setting.runAction.measure.readMeasureAD.text;
      case 17:
        return setting.runAction.digestSafetyCheck.text;
      case 18:
        return setting.runAction.collectSample.collect.text;
      case 19:
        return setting.runAction.collectSample.silent.text;
      case 20:
        return setting.runAction.measure.drainBeforeMeasure.text;
      case 21:
        return setting.runAction.measure.drainAfterMeasure.text;
      case 22:
        return setting.runAction.measure.cleanAfterMeasure.text;
      default:
        return '空闲';
    }
  }

  /**
   * 根据运行状态判断系统是否正在运行。
   * 该状态由 DeviceEventBus 的 runtime 事件提供，与 RunStatus.ets 中的状态定义对应。
   */
  private isSystemRunning(): boolean {
    return this.currentSystemStatusCode !== null;
  }

  private applyRuntimeSnapshot(snapshot: RuntimeSnapshot): void {
    this.lastRuntimeSource = snapshot.source ?? '';

    const statusAvailable = snapshot.systemStatusCode !== null;
    const actionAvailable = snapshot.currentActionCode !== null;

    hilog.info(
      FOOTER_DOMAIN,
      FOOTER_TAG,
      'applyRuntimeSnapshot valid=%{public}s statusCode=%{public}s actionCode=%{public}s label=%{public}s/%{public}s source=%{public}s',
      String(snapshot.valid),
      statusAvailable ? snapshot.systemStatusCode!.toString() : 'null',
      actionAvailable ? snapshot.currentActionCode!.toString() : 'null',
      snapshot.systemStatusLabel,
      snapshot.currentActionLabel,
      this.lastRuntimeSource
    );

    // 只要有状态码就显示状态，只要有动作码就显示动作；DeviceStateStore 的 valid 要求两者同时存在，
    // 但 FooterBar 这里允许只显示其中一项，避免某一项缺失时整个底部栏都变成“空闲”。
    if (!statusAvailable && !actionAvailable) {
      this.currentSystemStatusCode = null;
      this.currentActionCode = null;
      this.firstTimerTargetSeconds = 0;
      this.secondTimerTargetSeconds = 0;
      this.firstTimerElapsedMs = 0;
      this.secondTimerElapsedMs = 0;
      this.firstTimerLabel = '空闲';
      this.secondTimerLabel = '空闲';
      this.FirstTextTimerController.pause();
      this.SecondTextTimerController.pause();
      this.FirstTextTimerController.reset();
      this.SecondTextTimerController.reset();
      return;
    }

    const statusChanged = snapshot.systemStatusCode !== this.currentSystemStatusCode;
    const actionChanged = snapshot.currentActionCode !== this.currentActionCode;

    if (statusAvailable) {
      this.currentSystemStatusCode = snapshot.systemStatusCode;
      const newFirstTarget = this.getRunStatusTimeSeconds(snapshot.systemStatusCode);

      if (snapshot.systemStatusCode === 1) {
        hilog.info(
          FOOTER_DOMAIN,
          FOOTER_TAG,
          'measureSample time=%{public}d seconds',
          newFirstTarget
        );
      }

      if (statusChanged || this.firstTimerTargetSeconds !== newFirstTarget) {
        this.firstTimerTargetSeconds = newFirstTarget;
        this.firstTimerElapsedMs = 0;
        this.firstTimerLabel = this.getRunStatusLabel(snapshot.systemStatusCode);
        this.FirstTextTimerController.pause();
        this.FirstTextTimerController.reset();
        if (newFirstTarget > 0) {
          this.FirstTextTimerController.start();
        }
      }
    } else {
      this.currentSystemStatusCode = null;
      this.firstTimerTargetSeconds = 0;
      this.firstTimerElapsedMs = 0;
      this.firstTimerLabel = '空闲';
      this.FirstTextTimerController.pause();
      this.FirstTextTimerController.reset();
    }

    if (actionAvailable) {
      this.currentActionCode = snapshot.currentActionCode;
      const newSecondTarget = this.getRunActionTimeSeconds(snapshot.currentActionCode);

      if (actionChanged || this.secondTimerTargetSeconds !== newSecondTarget) {
        this.secondTimerTargetSeconds = newSecondTarget;
        this.secondTimerElapsedMs = 0;
        this.secondTimerLabel = this.getRunActionLabel(snapshot.currentActionCode);
        this.SecondTextTimerController.pause();
        this.SecondTextTimerController.reset();
        if (newSecondTarget > 0) {
          this.SecondTextTimerController.start();
        }
      }
    } else {
      this.currentActionCode = null;
      this.secondTimerTargetSeconds = 0;
      this.secondTimerElapsedMs = 0;
      this.secondTimerLabel = '空闲';
      this.SecondTextTimerController.pause();
      this.SecondTextTimerController.reset();
    }

    hilog.info(
      FOOTER_DOMAIN,
      FOOTER_TAG,
      'computed targets status=%{public}s action=%{public}s targets=%{public}d/%{public}d',
      String(statusChanged),
      String(actionChanged),
      this.firstTimerTargetSeconds,
      this.secondTimerTargetSeconds
    );
  }

  /**
   * 根据状态累计运行时间自动切换当前动作。
   * 当 DeviceStateStore 轮询不到动作码时，用 RunAction.ets 里定义的时长模拟动作序列。
   */
  private updateCurrentActionFromStatusTime(elapsedMs: number): void {
    if (this.currentSystemStatusCode === null) {
      return;
    }
    // 只有从维护面板直接下发的状态才用时间推算动作序列；
    // 如果 DeviceStateStore 轮询到了真实动作码，以真实数据为准。
    if (this.lastRuntimeSource !== 'maintenance_panel') {
      return;
    }
    if (!this.isAutoScheduledStatus(this.currentSystemStatusCode)) {
      return;
    }

    const elapsedSeconds = Math.floor(elapsedMs / 1000);
    const actionCode = this.getActionCodeByStatusTime(this.currentSystemStatusCode, elapsedSeconds);

    if (actionCode === null) {
      // 动作序列已结束，当前没有正在执行的动作
      if (this.currentActionCode !== null) {
        this.currentActionCode = null;
        this.secondTimerTargetSeconds = 0;
        this.secondTimerElapsedMs = 0;
        this.secondTimerLabel = '空闲';
        this.SecondTextTimerController.pause();
        this.SecondTextTimerController.reset();
      }
      return;
    }

    if (actionCode !== this.currentActionCode) {
      const newTarget = this.getRunActionTimeSeconds(actionCode);
      this.currentActionCode = actionCode;
      this.secondTimerTargetSeconds = newTarget;
      this.secondTimerElapsedMs = 0;
      this.secondTimerLabel = this.getRunActionLabel(actionCode);
      this.SecondTextTimerController.pause();
      this.SecondTextTimerController.reset();
      if (newTarget > 0) {
        this.SecondTextTimerController.start();
      }

      hilog.info(
        FOOTER_DOMAIN,
        FOOTER_TAG,
        'action switched by scheduler status=%{public}d action=%{public}d label=%{public}s target=%{public}d',
        this.currentSystemStatusCode,
        actionCode,
        this.secondTimerLabel,
        newTarget
      );
    }
  }

  private isAutoScheduledStatus(statusCode: number): boolean {
    return [1, 2, 3, 4, 33, 41, 8].includes(statusCode);
  }

  private getActionCodeByStatusTime(statusCode: number, elapsedSeconds: number): number | null {
    if (statusCode === 8) {
      // 采集样品：先采集，后静置
      const collectDuration = this.getRunActionTimeSeconds(18);
      if (elapsedSeconds < collectDuration) {
        return 18;
      }
      const silentDuration = this.getRunActionTimeSeconds(19);
      if (elapsedSeconds < collectDuration + silentDuration) {
        return 19;
      }
      return null;
    }

    // 测量相关流程：使用完整测量动作序列
    const measureSequence: number[] = [20, 1, 3, 4, 5, 11, 12, 6, 13, 14, 15, 21, 22, 2];
    let accumulated = 0;
    for (const code of measureSequence) {
      const duration = this.getRunActionTimeSeconds(code);
      if (elapsedSeconds < accumulated + duration) {
        return code;
      }
      accumulated += duration;
    }
    return null;
  }

  private applyTemperatureEvent(eventPack: EventPack): void {
    if (eventPack.type !== 'TEMPERATURE') {
      return;
    }
    if (eventPack.environmentTemp === undefined || eventPack.environmentTemp === null) {
      this.reactTemperatureText = '-';
      return;
    }
    this.reactTemperatureText = eventPack.environmentTemp.toFixed(1);
  }

  aboutToAppear(): void {
    console.info('aboutToAppear');
    this.releaseSubscriptions();
    this.applyAlarmSnapshot(DeviceStateStore.getAlarmSnapshot());
    this.applyRuntimeSnapshot(DeviceStateStore.getRuntimeSnapshot());
    void this.loadAlarmSettingsAndRefresh();

    // 初始化温度显示：优先使用 PT63EventService 已缓存的最新环境温度
    const latestEnvironmentTemp = PT63EventService.getInstance().getLatestEnvironmentTemp();
    if (latestEnvironmentTemp !== null) {
      this.reactTemperatureText = latestEnvironmentTemp.toFixed(1);
    }

    this.unsubscribePt63 = PT63EventService.getInstance().subscribe((eventPack: EventPack) => {
      this.applyTemperatureEvent(eventPack);
    });

    const listener: UserSettingsListener = () => {
      this.alarmSettings = UserSettingsService.getCachedAlarmDisplaySettings();
      this.applyAlarmSnapshot(DeviceStateStore.getAlarmSnapshot());
    };
    this.userSettingsListener = listener;
    UserSettingsService.addListener(listener);

    this.unsubscribeAlarm = DeviceEventBus.subscribe('alarm', (event: DeviceEvent) => {
      this.applyAlarmSnapshot(event.current as AlarmSnapshot);
    });
    this.releaseAlarmInterest = DevicePollingCoordinator.registerTopicInterest('alarm', 'FooterBar');

    this.unsubscribeRuntime = DeviceEventBus.subscribe('runtime', (event: DeviceEvent) => {
      this.applyRuntimeSnapshot(event.current as RuntimeSnapshot);
    });
    this.releaseRuntimeInterest = DevicePollingCoordinator.registerTopicInterest('runtime', 'FooterBar');
    hilog.info(FOOTER_DOMAIN, FOOTER_TAG, 'FooterBar registered runtime interest');

    // 开启定时器，每秒更新一次
    this.timer = setInterval(() => {
      this.updateTime();
    }, 1000);
  }

  updateTime() {
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const day = String(now.getDate()).padStart(2, '0');
    const hours = String(now.getHours()).padStart(2, '0');
    const minutes = String(now.getMinutes()).padStart(2, '0');
    const seconds = String(now.getSeconds()).padStart(2, '0');

    this.currentTime = `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`;
  }

  aboutToDisappear(): void {
    this.releaseSubscriptions();
    if (this.userSettingsListener) {
      UserSettingsService.removeListener(this.userSettingsListener);
      this.userSettingsListener = null;
    }
    clearInterval(this.timer) // 清理计时器防止内存泄露
  }

  private releaseSubscriptions(): void {
    if (this.unsubscribeAlarm) {
      this.unsubscribeAlarm();
      this.unsubscribeAlarm = null;
    }
    if (this.releaseAlarmInterest) {
      this.releaseAlarmInterest();
      this.releaseAlarmInterest = null;
    }
    if (this.unsubscribeRuntime) {
      this.unsubscribeRuntime();
      this.unsubscribeRuntime = null;
    }
    if (this.releaseRuntimeInterest) {
      this.releaseRuntimeInterest();
      this.releaseRuntimeInterest = null;
    }
    if (this.unsubscribePt63) {
      this.unsubscribePt63();
      this.unsubscribePt63 = null;
    }
  }

  build() {
    // Bottom status bar: brand logo + current time + temperature.
    Stack() {
      Image($r('app.media.bottom'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Fill)

      Row() {
        // Brand area.
        Row() {
          Image($r('app.media.logo_openharmony'))
            .height(UiUtil.vh(3.6, 24, 42, this.viewportHeight, this.scaleFactor))
            .width(UiUtil.vw(20.0, 150, 280, this.viewportWidth, this.scaleFactor))
            .objectFit(ImageFit.Contain)
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Start)
        .padding({ left: UiUtil.vw(3.2, 12, 24, this.viewportWidth, this.scaleFactor) })

        Row({ space: 20 }) {
          // 当前状态进度条
          Stack({ alignContent: Alignment.Center }) {
            // 背景框
            Column()
              .width('100%')
              .height('100%')
              .backgroundColor('#44000000')
              .borderRadius(UiUtil.vh(1, 4, 8, this.viewportHeight, this.scaleFactor))

            // 随执行时间填满整个框的透明蓝色进度
            Progress({
              value: this.firstTimerTargetSeconds > 0
                ? Math.min(100, (this.firstTimerElapsedMs / (this.firstTimerTargetSeconds * 1000)) * 100)
                : 0,
              total: 100,
              type: ProgressType.Linear
            })
              .width('100%')
              .height('100%')
              .backgroundColor('#00000000')
              .color('#3300D4C8')
              .borderRadius(UiUtil.vh(1, 4, 8, this.viewportHeight, this.scaleFactor))

            // 文字和时间浮在进度上方
            Row() {
              Text(this.firstTimerLabel)
                .fontSize(UiUtil.vh(1.5, 12, 18, this.viewportHeight, this.scaleFactor))
                .fontColor('white')
                .fontWeight(FontWeight.Bold)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .layoutWeight(1)
                .textShadow({ radius: 2, color: '#000000', offsetX: 1, offsetY: 1 })

              TextTimer({
                isCountDown: false,
                count: 0,
                controller: this.FirstTextTimerController
              })
                .fontColor('white')
                .format('HH:mm:ss')
                .fontSize(UiUtil.vh(1.5, 12, 18, this.viewportHeight, this.scaleFactor))
                .onTimer((utc: number, elapsedTime: number) => {
                  this.firstTimerElapsedMs = elapsedTime;
                  this.updateCurrentActionFromStatusTime(elapsedTime);
                  if (this.firstTimerTargetSeconds > 0 && elapsedTime >= this.firstTimerTargetSeconds * 1000) {
                    this.FirstTextTimerController.pause();
                  }
                })
            }
            .width('100%')
            .height('100%')
            .padding({ left: 12, right: 12 })
            .justifyContent(FlexAlign.SpaceBetween)
          }
          .width(UiUtil.vw(20.0, 240, 360, this.viewportWidth, this.scaleFactor))
          .height(UiUtil.vh(2.0, 16, 24, this.viewportHeight, this.scaleFactor))

          // 当前动作进度条
          Stack({ alignContent: Alignment.Center }) {
            // 背景框
            Column()
              .width('100%')
              .height('100%')
              .backgroundColor('#44000000')
              .borderRadius(UiUtil.vh(1, 4, 8, this.viewportHeight, this.scaleFactor))

            // 随执行时间填满整个框的透明蓝色进度
            Progress({
              value: this.secondTimerTargetSeconds > 0
                ? Math.min(100, (this.secondTimerElapsedMs / (this.secondTimerTargetSeconds * 1000)) * 100)
                : 0,
              total: 100,
              type: ProgressType.Linear
            })
              .width('100%')
              .height('100%')
              .backgroundColor('#00000000')
              .color('#3300D4C8')
              .borderRadius(UiUtil.vh(1, 4, 8, this.viewportHeight, this.scaleFactor))

            // 文字和时间浮在进度上方
            Row() {
              Text(this.secondTimerLabel)
                .fontSize(UiUtil.vh(1.5, 12, 18, this.viewportHeight, this.scaleFactor))
                .fontColor('white')
                .fontWeight(FontWeight.Bold)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .layoutWeight(1)
                .textShadow({ radius: 2, color: '#000000', offsetX: 1, offsetY: 1 })

              TextTimer({
                isCountDown: false,
                count: 0,
                controller: this.SecondTextTimerController
              })
                .fontColor('white')
                .format('HH:mm:ss')
                .fontSize(UiUtil.vh(1.5, 12, 18, this.viewportHeight, this.scaleFactor))
                .onTimer((utc: number, elapsedTime: number) => {
                  this.secondTimerElapsedMs = elapsedTime;
                  if (this.secondTimerTargetSeconds > 0 && elapsedTime >= this.secondTimerTargetSeconds * 1000) {
                    this.SecondTextTimerController.pause();
                  }
                })
            }
            .width('100%')
            .height('100%')
            .padding({ left: 12, right: 12 })
            .justifyContent(FlexAlign.SpaceBetween)
          }
          .width(UiUtil.vw(20.0, 240, 360, this.viewportWidth, this.scaleFactor))
          .height(UiUtil.vh(2.0, 16, 24, this.viewportHeight, this.scaleFactor))
        }
        .margin({ left: 40, right: 40 })

        Row({ space: 20 }) {
          Image(this.isSystemRunning() ? $r('app.media.cloudConnected') : $r('app.media.cloudDisconnected'))
            .width(40)
            .height(40)
          Row() {
            Text('运行')
              .fontSize(UiUtil.vh(1.8, 12, 20, this.viewportHeight, this.scaleFactor))
              .fontWeight(FontWeight.Bold)
              .fontColor('green')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }
        .margin({ right: 40 })

/*
        // Time display area.
        Text(this.currentTime)
          .fontSize(UiUtil.vh(1.8, 12, 20, this.viewportHeight, this.scaleFactor))
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .margin({ right: UiUtil.vw(2.0, 10, 30, this.viewportWidth, this.scaleFactor) })

        if (this.alarmText.length > 0) {
          Text('报警：' + this.alarmText)
            .fontSize(UiUtil.vh(1.8, 12, 20, this.viewportHeight, this.scaleFactor))
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFD966')
            // .maxWidth(UiUtil.vw(22.0, 140, 320))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ right: UiUtil.vw(1.4, 8, 20, this.viewportWidth, this.scaleFactor) })
        }
*/
        // Temperature display area.
        Text(this.reactTemperatureText + '℃')
          .fontSize(UiUtil.vh(2.2, 14, 26, this.viewportHeight, this.scaleFactor))
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .margin({ right: UiUtil.vw(1.4, 8, 20, this.viewportWidth, this.scaleFactor) })
      }
      .height(UiUtil.vh(7.0, 36, 56, this.viewportHeight, this.scaleFactor))
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .height(UiUtil.vh(7.0, 36, 56, this.viewportHeight, this.scaleFactor))
    .width('100%')
  }
}
