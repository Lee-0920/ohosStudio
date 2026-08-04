import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { emitter, Callback } from '@kit.BasicServicesKit';
import { UiUtil } from 'base';
import {
  AlarmSnapshot,
  DeviceEvent,
  RuntimeSnapshot
} from '../models/deviceStateTypes';
import { setting } from 'flow';
import { preferences } from '@kit.ArkData';
import { ExternalInterfaceConfig } from 'flow/src/main/ets/Config/ScheduleMeasurementConfig';
import { SetConfig, Type, Param } from 'flow/src/main/ets/Config/BaseInterface';
import { TypeItem, ParameterItem, INSTRUMENTSTATUS } from 'flow/src/main/ets/Config/BaseEnum';
import { DeviceEventBus } from '../services/DeviceEventBus';
import { DevicePollingCoordinator } from '../services/DevicePollingCoordinator';
import { DeviceStateStore } from '../services/DeviceStateStore';
import {
  MaintenanceRuntimeDisplayInfo,
  MaintenanceRuntimeDisplayService
} from '../services/MaintenanceRuntimeDisplayService';
import { PT63EventService } from '../services/PT63EventService';
import {
  AlarmDisplaySettings,
  UserSettingsListener,
  UserSettingsService
} from '../services/UserSettingsService';
import {
  EventPack
} from 'communication';
import { MonitorService } from '../services/MonitorService';

const FOOTER_DOMAIN = 0x0003;
const FOOTER_TAG = 'FooterBar';

/**
 * Worker 线程通过 emitter 发送的测量进度事件。
 */
interface WorkerMeasureStatusEvent {
  type: 'measureProgress';
  phase: 'start' | 'action' | 'end';
  statusLabel: string;
  statusTotalSeconds: number;
  actionLabel: string;
  actionTotalSeconds: number;
  measureType: number;
  timestamp: number;
  /** 可选：直接指定的系统状态码，覆盖 measureType 的默认映射 */
  systemStatusCode?: number;
}

/**
 * FooterBar 内部使用的 Worker 运行时显示信息。
 */
interface WorkerRuntimeDisplayInfo {
  statusLabel: string;
  statusTotalSeconds: number;
  actionLabel: string;
  actionTotalSeconds: number;
}

@Component
export struct FooterBar {
  // Current timestamp shown at footer right.
  @State currentTime: string = '';
  @Prop viewportWidth: number = 1024;
  @Prop viewportHeight: number = 768;
  @Prop scaleFactor: number = 1.92;

  @State private reactTemperatureText: string = '-';
  @State private alarmText: string = '当前无报警';
  @State private instrumentStatusText: string = '运行';
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

  // 从 Worker 线程接收的运行时显示状态（不经过 DeviceStateStore / MaintenancePanel）
  @State private workerDisplayInfo: WorkerRuntimeDisplayInfo | null = null;
  @State private workerDisplayElapsedMs: number = 0;
  @State private workerActionElapsedMs: number = 0;
  @State private workerCurrentActionStepIndex: number = -1;
  private workerDisplayInterval: number = -1;
  private emitterCallback: Callback<emitter.EventData> | null = null;
  /**
   * Worker 测量结束后进入空闲锁定状态：忽略 DeviceStateStore 的下发，
   * 防止“点击停止”后底部栏被延迟的旧状态快照重新覆盖成“测量水样 00:01:00”。
   * 新的 Worker 或维护面板事件到来时会自动解除锁定。
   */
  private workerEndedIdleLock: boolean = false;

  @State private firstTimerTargetSeconds: number = 0;
  @State private secondTimerTargetSeconds: number = 0;
  @State private firstTimerElapsedMs: number = 0;
  @State private secondTimerElapsedMs: number = 0;
  @State private currentSystemStatusCode: number | null = null;
  @State private currentActionCode: number | null = null;
  private lastRuntimeSource: string = '';
  private FirstTextTimerController = new TextTimerController();
  private SecondTextTimerController = new TextTimerController();

  // DeviceStateStore 驱动第一个进度条时使用的的手动计时器（替代 TextTimer 倒计时，避免 count 不更新）
  private defaultDisplayInterval: number = -1;

  // 维护面板直接下发的运行时显示（不经过 DeviceStateStore/applyRuntimeSnapshot）
  @State private maintenanceDisplayInfo: MaintenanceRuntimeDisplayInfo | null = null;
  @State private maintenanceDisplayElapsedMs: number = 0;
  @State private maintenanceCurrentActionStepIndex: number = -1;
  private maintenanceDisplayInterval: number = -1;
  private unsubscribeMaintenanceDisplay: (() => void) | null = null;
  private unsubscribeWorkerDisplay: (() => void) | null = null;

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
    return this.currentSystemStatusCode !== null || this.maintenanceDisplayInfo !== null || this.workerDisplayInfo !== null;
  }

  /**
   * 订阅 Worker 线程通过 emitter 发送的测量进度事件。
   * 事件由 Measurer.ets 在 worker 线程执行测量流程时发出，跨线程到达主线程。
   */
  private subscribeWorkerMeasureStatus(): () => void {
    const callback: Callback<emitter.EventData> = (eventData: emitter.EventData) => {
      const data = eventData.data as WorkerMeasureStatusEvent;
      if (!data || data.type !== 'measureProgress') {
        return;
      }
      hilog.info(
        FOOTER_DOMAIN,
        FOOTER_TAG,
        'recv MeasureStatus phase=%{public}s status=%{public}s action=%{public}s',
        data.phase,
        data.statusLabel,
        data.actionLabel
      );
      this.applyWorkerMeasureStatus(data);
    };
    this.emitterCallback = callback;
    emitter.on('MeasureStatus', callback);
    return (): void => {
      emitter.off('MeasureStatus', callback);
      this.emitterCallback = null;
    };
  }

  /**
   * 处理 Worker 线程下发的测量进度事件，更新底部两个进度条。
   * 该逻辑独立于 DeviceStateStore 和 MaintenancePanel。
   */
  private applyWorkerMeasureStatus(data: WorkerMeasureStatusEvent): void {
    hilog.info(
      FOOTER_DOMAIN,
      FOOTER_TAG,
      'applyWorkerMeasureStatus phase=%{public}s status=%{public}s action=%{public}s',
      data.phase,
      data.statusLabel,
      data.actionLabel
    );

    if (data.phase === 'end') {
      this.clearWorkerDisplay();
      this.refreshDeviceStateSnapshot();
      this.workerEndedIdleLock = true;
      this.applyMaintenanceRuntimeInfo(null);
      hilog.info(FOOTER_DOMAIN, FOOTER_TAG, 'worker ended, idle lock enabled');
      return;
    }

    // Worker 事件到达时，清除 MaintenancePanel 驱动的旧显示，避免冲突
    if (this.maintenanceDisplayInfo !== null) {
      this.clearMaintenanceDisplayInterval();
      this.maintenanceDisplayInfo = null;
      this.maintenanceDisplayElapsedMs = 0;
      this.maintenanceCurrentActionStepIndex = -1;
    }
    this.clearDefaultDisplayInterval();

    // 新的 Worker 测量开始/动作事件，解除之前的空闲锁定
    if (this.workerEndedIdleLock) {
      this.workerEndedIdleLock = false;
      hilog.info(FOOTER_DOMAIN, FOOTER_TAG, 'new worker progress arrived, idle lock disabled');
    }

    const isNewStatus = this.workerDisplayInfo === null ||
      this.workerDisplayInfo.statusLabel !== data.statusLabel;
    const isNewAction = this.workerDisplayInfo === null ||
      this.workerDisplayInfo.actionLabel !== data.actionLabel;

    if (isNewStatus) {
      this.workerDisplayElapsedMs = 0;
    }
    if (isNewAction) {
      this.workerActionElapsedMs = 0;
      this.workerCurrentActionStepIndex = -1;
    }

    this.workerDisplayInfo = {
      statusLabel: data.statusLabel,
      statusTotalSeconds: data.statusTotalSeconds,
      actionLabel: data.actionLabel,
      actionTotalSeconds: data.actionTotalSeconds
    };

    this.firstTimerLabel = data.statusLabel;
    this.firstTimerTargetSeconds = data.statusTotalSeconds;
    this.firstTimerElapsedMs = this.workerDisplayElapsedMs;

    this.secondTimerLabel = data.actionLabel;
    this.secondTimerTargetSeconds = data.actionTotalSeconds;
    this.secondTimerElapsedMs = this.workerActionElapsedMs;

    // 避免每次事件都重启计时器，防止时间走得偏慢
    if (this.workerDisplayInterval === -1) {
      this.startWorkerDisplayInterval();
    }
  }

  private startWorkerDisplayInterval(): void {
    this.clearWorkerDisplayInterval();
    this.workerDisplayInterval = setInterval(() => {
      this.workerDisplayElapsedMs += 100;
      this.workerActionElapsedMs += 100;
      this.firstTimerElapsedMs = this.workerDisplayElapsedMs;
      this.secondTimerElapsedMs = this.workerActionElapsedMs;
      // 不主动停止：测量实际时长可能超过预估值，等待 'end' 事件再恢复空闲
    }, 100);
  }

  private clearWorkerDisplayInterval(): void {
    if (this.workerDisplayInterval !== -1) {
      clearInterval(this.workerDisplayInterval);
      this.workerDisplayInterval = -1;
    }
  }

  /**
   * 清除 Worker 驱动的显示，恢复空闲状态。
   */
  private clearWorkerDisplay(): void {
    this.clearWorkerDisplayInterval();
    this.clearDefaultDisplayInterval();
    this.workerDisplayInfo = null;
    this.workerDisplayElapsedMs = 0;
    this.workerActionElapsedMs = 0;
    this.workerCurrentActionStepIndex = -1;
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
  }

  /**
   * 刷新DeviceStateStore状态,组合维护时读取状态判断单个流程是否执行结束
   */
  private refreshDeviceStateSnapshot(): void {
    const snapshot = DeviceStateStore.getRuntimeSnapshot();
    snapshot.valid = true;
    snapshot.systemStatus = { code: 0, label: '空闲'};
    snapshot.currentAction = { code: 0, label: '空闲'};
    snapshot.systemStatusCode = 0;
    snapshot.currentActionCode = 0;
    DeviceStateStore.updateRuntime(snapshot.systemStatus, snapshot.currentAction, 'FooterBar');
    MonitorService.resetMeasurementRunning();
  }

  private clearDefaultDisplayInterval(): void {
    if (this.defaultDisplayInterval !== -1) {
      clearInterval(this.defaultDisplayInterval);
      this.defaultDisplayInterval = -1;
    }
  }

  private startDefaultDisplayInterval(): void {
    this.clearDefaultDisplayInterval();
    this.defaultDisplayInterval = setInterval(() => {
      this.firstTimerElapsedMs += 100;
      if (this.firstTimerTargetSeconds > 0 && this.firstTimerElapsedMs >= this.firstTimerTargetSeconds * 1000) {
        this.clearDefaultDisplayInterval();
      }
    }, 100);
  }

  /**
   * 处理维护面板直接下发的运行时显示信息。
   * 与 DeviceStateStore/applyRuntimeSnapshot 完全独立。
   */
  private applyMaintenanceRuntimeInfo(info: MaintenanceRuntimeDisplayInfo | null): void {
    hilog.info(FOOTER_DOMAIN, FOOTER_TAG, 'applyMaintenanceRuntimeInfo info=%{public}s idleLock=%{public}s',
      info === null ? 'null' : JSON.stringify(info),
      String(this.workerEndedIdleLock));

    // Worker 测量结束后的空闲锁定期间，忽略 MaintenanceRuntimeDisplayService 下发的非空显示，
    // 避免底部栏在停止后被延迟的维护面板快照重新覆盖。
    if (info !== null && this.workerEndedIdleLock) {
      hilog.info(FOOTER_DOMAIN, FOOTER_TAG, 'ignore maintenance info due to worker idle lock');
      return;
    }

    this.clearMaintenanceDisplayInterval();
    this.maintenanceDisplayInfo = info;
    this.maintenanceDisplayElapsedMs = 0;
    this.maintenanceCurrentActionStepIndex = -1;
    if (info !== null) {
      this.clearDefaultDisplayInterval();
      // 新的维护面板事件到来，解除 Worker 结束后的空闲锁定
      if (this.workerEndedIdleLock) {
        this.workerEndedIdleLock = false;
        hilog.info(FOOTER_DOMAIN, FOOTER_TAG, 'maintenance info arrived, idle lock disabled');
      }
      this.maintenanceDisplayInterval = setInterval(() => {
        this.maintenanceDisplayElapsedMs += 100;
        hilog.info(FOOTER_DOMAIN, FOOTER_TAG, 'maintenanceDisplayInterval elapsed=%{public}d', this.maintenanceDisplayElapsedMs);
        this.syncSecondTimerToMaintenanceAction(info, this.maintenanceDisplayElapsedMs);
        if (info.statusTotalSeconds > 0 && this.maintenanceDisplayElapsedMs >= info.statusTotalSeconds * 1000) {
          this.clearMaintenanceDisplayInterval();
        }
      }, 100);
      this.syncSecondTimerToMaintenanceAction(info, 0);
    } else {
      this.clearSecondTimerToIdle();
      this.clearDefaultDisplayInterval();
      // 维护显示清除后，同步把 DeviceStateStore 驱动的状态也恢复空闲，避免显示旧状态
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
    }
  }

  /**
   * 根据维护状态累计时间，推算当前应显示的动作，并同步到第二个进度条。
   * 优先使用 MaintenancePanel 下发的 actionSteps；未下发时按状态码通用序列回退。
   * 数据来自 RunAction.ets，不经过 DeviceStateStore。
   */
  private syncSecondTimerToMaintenanceAction(info: MaintenanceRuntimeDisplayInfo, elapsedMs: number): void {
    const elapsedSeconds = Math.floor(elapsedMs / 1000);

    if (info.actionSteps && info.actionSteps.length > 0) {
      let accumulatedSeconds = 0;
      for (let i = 0; i < info.actionSteps.length; i++) {
        const step = info.actionSteps[i];
        if (elapsedSeconds < accumulatedSeconds + step.actionTotalSeconds) {
          const elapsedInStepMs = elapsedMs - accumulatedSeconds * 1000;
          if (i !== this.maintenanceCurrentActionStepIndex) {
            this.maintenanceCurrentActionStepIndex = i;
            this.currentActionCode = null;
            this.secondTimerTargetSeconds = step.actionTotalSeconds;
            this.secondTimerElapsedMs = elapsedInStepMs;
            this.secondTimerLabel = step.actionLabel;
            hilog.info(
              FOOTER_DOMAIN,
              FOOTER_TAG,
              'maintenance action switched index=%{public}d label=%{public}s target=%{public}d',
              i,
              this.secondTimerLabel,
              this.secondTimerTargetSeconds
            );
          } else {
            this.secondTimerElapsedMs = elapsedInStepMs;
          }
          return;
        }
        accumulatedSeconds += step.actionTotalSeconds;
      }
      this.clearSecondTimerToIdle();
      return;
    }

    // 未提供 actionSteps 时，使用原状态码通用序列回退
    if (!this.isAutoScheduledStatus(info.statusCode)) {
      this.clearSecondTimerToIdle();
      return;
    }
    const actionCode = this.getActionCodeByStatusTime(info.statusCode, elapsedSeconds);
    if (actionCode === null) {
      this.clearSecondTimerToIdle();
      return;
    }
    if (actionCode !== this.currentActionCode) {
      const newTarget = this.getRunActionTimeSeconds(actionCode);
      this.currentActionCode = actionCode;
      this.maintenanceCurrentActionStepIndex = -1;
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
        'maintenance action switched status=%{public}d action=%{public}d label=%{public}s target=%{public}d',
        info.statusCode,
        actionCode,
        this.secondTimerLabel,
        newTarget
      );
    }
  }

  private clearMaintenanceDisplayInterval(): void {
    if (this.maintenanceDisplayInterval !== -1) {
      clearInterval(this.maintenanceDisplayInterval);
      this.maintenanceDisplayInterval = -1;
    }
  }

  private formatElapsedTime(ms: number): string {
    const totalSeconds = Math.floor(ms / 1000);
    const hours = Math.floor(totalSeconds / 3600).toString().padStart(2, '0');
    const minutes = Math.floor((totalSeconds % 3600) / 60).toString().padStart(2, '0');
    const seconds = (totalSeconds % 60).toString().padStart(2, '0');
    return `${hours}:${minutes}:${seconds}`;
  }

  /**
   * 格式化剩余时间。若已用时间超过总时长则显示 00:00:00。
   */
  private formatRemainingTime(totalSeconds: number, elapsedMs: number): string {
    const remainingMs = Math.max(0, totalSeconds * 1000 - elapsedMs);
    return this.formatElapsedTime(remainingMs);
  }

  /**
   * 从设置页“外联接口 → 仪器状态”的持久化配置中读取当前状态。
   * SettingPage 将配置保存在 preferences 'myStore' 的 'config2' 键中。
   */
  private loadInstrumentStatusFromSettings(): void {
    const context = this.getHostContext();
    if (!context) {
      return;
    }

    try {
      const dataPreferences = preferences.getPreferencesSync(context, { name: 'myStore' });
      const savedConfig = dataPreferences.getSync('config2', '') as string;
      if (!savedConfig) {
        this.updateInstrumentStatusFromConfig(ExternalInterfaceConfig);
        return;
      }
      const config: SetConfig = JSON.parse(savedConfig) as SetConfig;
      this.updateInstrumentStatusFromConfig(config);
    } catch (err) {
      hilog.error(FOOTER_DOMAIN, FOOTER_TAG, 'load instrument status failed: %{public}s', JSON.stringify(err));
    }
  }

  private updateInstrumentStatusFromConfig(config: SetConfig): void {
    const instrumentStatusType = config.type.find((t: Type) => t.name === TypeItem.INSTRUMENTSTATUS);
    if (!instrumentStatusType) {
      return;
    }
    const statusParam = instrumentStatusType.params.find((p: Param) => p.paramName === ParameterItem.STATUS);
    if (!statusParam || !Array.isArray(statusParam.value)) {
      return;
    }
    const options = statusParam.value as SelectOption[];
    const selectedIndex = statusParam.select ?? 0;
    const selectedOption = options[selectedIndex];
    if (selectedOption && typeof selectedOption.value === 'string') {
      this.instrumentStatusText = selectedOption.value;
    }
  }

  private getInstrumentStatusColor(): string {
    switch (this.instrumentStatusText) {
      case INSTRUMENTSTATUS.RUN:
        return 'green';
      case INSTRUMENTSTATUS.OFFLINE:
        return '#9E9E9E';
      case INSTRUMENTSTATUS.MAINTENANCE:
        return '#FF9800';
      case INSTRUMENTSTATUS.MALFUNCTION:
        return '#E53935';
      case INSTRUMENTSTATUS.CALIBRATION:
        return '#ff400396';
      case INSTRUMENTSTATUS.DEBUGGING:
        return '#9C27B0';
      default:
        return 'green';
    }
  }

  private clearSecondTimerToIdle(): void {
    if (this.currentActionCode === null && this.maintenanceCurrentActionStepIndex === -1 && this.secondTimerLabel === '空闲') {
      return;
    }
    this.currentActionCode = null;
    this.maintenanceCurrentActionStepIndex = -1;
    this.secondTimerTargetSeconds = 0;
    this.secondTimerElapsedMs = 0;
    this.secondTimerLabel = '空闲';
    this.SecondTextTimerController.pause();
    this.SecondTextTimerController.reset();
  }

  private applyRuntimeSnapshot(snapshot: RuntimeSnapshot): void {
    this.lastRuntimeSource = snapshot.source ?? '';

    const statusAvailable = snapshot.systemStatusCode !== null;
    const actionAvailable = snapshot.currentActionCode !== null;

    hilog.info(
      FOOTER_DOMAIN,
      FOOTER_TAG,
      'applyRuntimeSnapshot valid=%{public}s statusCode=%{public}s actionCode=%{public}s label=%{public}s/%{public}s source=%{public}s idleLock=%{public}s',
      String(snapshot.valid),
      statusAvailable ? snapshot.systemStatusCode!.toString() : 'null',
      actionAvailable ? snapshot.currentActionCode!.toString() : 'null',
      snapshot.systemStatusLabel,
      snapshot.currentActionLabel,
      this.lastRuntimeSource,
      String(this.workerEndedIdleLock)
    );

    // Worker 测量结束后进入空闲锁定，忽略 DeviceStateStore 的下发，
    // 避免“点击停止”后底部栏被延迟的旧状态快照重新覆盖。
    if (this.workerEndedIdleLock) {
      hilog.info(FOOTER_DOMAIN, FOOTER_TAG, 'ignore runtime snapshot due to worker idle lock');
      return;
    }

    // 只要有状态码就显示状态，只要有动作码就显示动作；DeviceStateStore 的 valid 要求两者同时存在，
    // 但 FooterBar 这里允许只显示其中一项，避免某一项缺失时整个底部栏都变成“空闲”。
    if (!statusAvailable && !actionAvailable) {
      this.clearDefaultDisplayInterval();
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
        this.clearDefaultDisplayInterval();
        if (newFirstTarget > 0) {
          this.startDefaultDisplayInterval();
        }
      }
    } else {
      this.currentSystemStatusCode = null;
      this.firstTimerTargetSeconds = 0;
      this.firstTimerElapsedMs = 0;
      this.firstTimerLabel = '空闲';
      this.FirstTextTimerController.pause();
      this.FirstTextTimerController.reset();
      this.clearDefaultDisplayInterval();
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
    if (this.maintenanceDisplayInfo === null) {
      this.applyRuntimeSnapshot(DeviceStateStore.getRuntimeSnapshot());
    }
    void this.loadAlarmSettingsAndRefresh();
    this.loadInstrumentStatusFromSettings();

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
      // 维护面板或 Worker 线程直接驱动期间，DeviceStateStore 的 runtime 事件不刷新底部状态栏
      if (this.maintenanceDisplayInfo !== null || this.workerDisplayInfo !== null) {
        return;
      }
      this.applyRuntimeSnapshot(event.current as RuntimeSnapshot);
    });
    this.releaseRuntimeInterest = DevicePollingCoordinator.registerTopicInterest('runtime', 'FooterBar');
    hilog.info(FOOTER_DOMAIN, FOOTER_TAG, 'FooterBar registered runtime interest');

    // 订阅维护面板直接下发的运行时显示
    this.unsubscribeMaintenanceDisplay = MaintenanceRuntimeDisplayService.addListener(
      (info: MaintenanceRuntimeDisplayInfo | null) => {
        // Worker 线程正在驱动时，忽略维护面板下发的旧显示信息
        if (this.workerDisplayInfo !== null) {
          return;
        }
        this.applyMaintenanceRuntimeInfo(info);
      }
    );

    // 订阅 Worker 线程通过 emitter 发送的测量进度事件
    this.unsubscribeWorkerDisplay = this.subscribeWorkerMeasureStatus();

    // 开启定时器，每秒更新一次
    this.timer = setInterval(() => {
      this.updateTime();
    }, 1000);
  }

  updateTime() {
    this.currentTime = UiUtil.formatDateTime(new Date());
    this.loadInstrumentStatusFromSettings();
  }

  aboutToDisappear(): void {
    this.releaseSubscriptions();
    this.clearMaintenanceDisplayInterval();
    this.clearWorkerDisplay();
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
    if (this.unsubscribeMaintenanceDisplay) {
      this.unsubscribeMaintenanceDisplay();
      this.unsubscribeMaintenanceDisplay = null;
    }
    if (this.unsubscribeWorkerDisplay) {
      this.unsubscribeWorkerDisplay();
      this.unsubscribeWorkerDisplay = null;
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
        Row() {
          // 当前状态进度条
          Stack({ alignContent: Alignment.Center }) {
            // 背景框
            Column()
              .width('100%')
              .height('100%')
              .backgroundColor('#44000000')
              .borderRadius(UiUtil.vh(1, 4, 8, this.viewportHeight, this.scaleFactor))

            if (this.workerDisplayInfo !== null) {
              // Worker 线程直接下发的状态显示
              Progress({
                value: this.workerDisplayInfo.statusTotalSeconds > 0
                  ? Math.min(100, (this.workerDisplayElapsedMs / (this.workerDisplayInfo.statusTotalSeconds * 1000)) * 100)
                  : 0,
                total: 100,
                type: ProgressType.Linear
              })
                .width('100%')
                .height('100%')
                .backgroundColor('#00000000')
                .color('#3300D4C8')
                .borderRadius(UiUtil.vh(1, 4, 8, this.viewportHeight, this.scaleFactor))

              Row() {
                Text(this.workerDisplayInfo.statusLabel)
                  .fontSize(UiUtil.vh(1.5, 12, 18, this.viewportHeight, this.scaleFactor))
                  .fontColor('white')
                  .fontWeight(FontWeight.Bold)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .layoutWeight(1)
                  .textShadow({ radius: 2, color: '#000000', offsetX: 1, offsetY: 1 })

                Text(this.formatRemainingTime(this.workerDisplayInfo.statusTotalSeconds, this.workerDisplayElapsedMs))
                  .fontColor('white')
                  .fontSize(UiUtil.vh(1.5, 12, 18, this.viewportHeight, this.scaleFactor))
              }
              .width('100%')
              .height('100%')
              .padding({ left: 12, right: 12 })
              .justifyContent(FlexAlign.SpaceBetween)
            } else if (this.maintenanceDisplayInfo !== null) {
              // 维护面板直接下发的状态显示（不经过 applyRuntimeSnapshot）
              Progress({
                value: this.maintenanceDisplayInfo.statusTotalSeconds > 0
                  ? Math.min(100, (this.maintenanceDisplayElapsedMs / (this.maintenanceDisplayInfo.statusTotalSeconds * 1000)) * 100)
                  : 0,
                total: 100,
                type: ProgressType.Linear
              })
                .width('100%')
                .height('100%')
                .backgroundColor('#00000000')
                .color('#3300D4C8')
                .borderRadius(UiUtil.vh(1, 4, 8, this.viewportHeight, this.scaleFactor))

              Row() {
                Text(this.maintenanceDisplayInfo.statusLabel)
                  .fontSize(UiUtil.vh(1.5, 12, 18, this.viewportHeight, this.scaleFactor))
                  .fontColor('white')
                  .fontWeight(FontWeight.Bold)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .layoutWeight(1)
                  .textShadow({ radius: 2, color: '#000000', offsetX: 1, offsetY: 1 })

                Text(this.formatRemainingTime(this.maintenanceDisplayInfo.statusTotalSeconds, this.maintenanceDisplayElapsedMs))
                  .fontColor('white')
                  .fontSize(UiUtil.vh(1.5, 12, 18, this.viewportHeight, this.scaleFactor))
              }
              .width('100%')
              .height('100%')
              .padding({ left: 12, right: 12 })
              .justifyContent(FlexAlign.SpaceBetween)
            } else {
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

                Text(this.formatRemainingTime(this.firstTimerTargetSeconds, this.firstTimerElapsedMs))
                  .fontColor('white')
                  .fontSize(UiUtil.vh(1.5, 12, 18, this.viewportHeight, this.scaleFactor))
              }
              .height('100%')
              .padding({ left: 12, right: 12 })
              .justifyContent(FlexAlign.SpaceBetween)
            }
          }
          .height(UiUtil.vh(2.0, 16, 24, this.viewportHeight, this.scaleFactor))
          .width(200)
          .margin({ right: 20 })

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

              if (this.workerDisplayInfo !== null || this.maintenanceDisplayInfo !== null) {
                // Worker 线程或维护面板直接驱动时使用手动计时，避免 TextTimer 不更新
                Text(this.formatElapsedTime(this.secondTimerElapsedMs))
                  .fontColor('white')
                  .fontSize(UiUtil.vh(1.5, 12, 18, this.viewportHeight, this.scaleFactor))
              } else {
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
            }
            .height('100%')
            .padding({ left: 12, right: 12 })
            .justifyContent(FlexAlign.SpaceBetween)
          }
          .height(UiUtil.vh(2.0, 16, 24, this.viewportHeight, this.scaleFactor))
          .width(200)
        }
        .margin({ left: 40, right: 40 })

        Row() {
          Image(this.isSystemRunning() ? $r('app.media.cloudConnected') : $r('app.media.cloudDisconnected'))
            .width(40)
            .height(40)
          Row() {
            Text(this.instrumentStatusText)
              .fontSize(UiUtil.vh(1.8, 12, 20, this.viewportHeight, this.scaleFactor))
              .fontWeight(FontWeight.Bold)
              .fontColor(this.getInstrumentStatusColor())
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }
        .margin({ right: 20 })

        // Time display area.
        Text(this.currentTime)
          .fontSize(UiUtil.vh(1.8, 12, 20, this.viewportHeight, this.scaleFactor))
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .margin({ right: UiUtil.vw(2.0, 10, 30, this.viewportWidth, this.scaleFactor) })

        // if (this.alarmText.length > 0) {
        //   Text('报警：' + this.alarmText)
        //     .fontSize(UiUtil.vh(1.8, 12, 20, this.viewportHeight, this.scaleFactor))
        //     .fontWeight(FontWeight.Bold)
        //     .fontColor('#FFD966')
        //     // .maxWidth(UiUtil.vw(22.0, 140, 320))
        //     .maxLines(1)
        //     .textOverflow({ overflow: TextOverflow.Ellipsis })
        //     .margin({ right: UiUtil.vw(1.4, 8, 20, this.viewportWidth, this.scaleFactor) })
        // }
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
