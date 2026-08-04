import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0003;
const TAG = 'MaintenanceRuntimeDisplayService';

/**
 * 维护面板触发的运行时显示信息。
 * 不经过 DeviceStateStore/applyRuntimeSnapshot，由 MaintenancePanel 直接下发，
 * 供 FooterBar 订阅并显示在底部状态栏第一个计时区域。
 */
export interface MaintenanceRuntimeDisplayInfo {
  /** 状态码，对应 RunStatus.ets 中的编码 */
  statusCode: number;
  /** 状态文本，如“测量水样” */
  statusLabel: string;
  /** 该状态预计总时长（秒），用于进度条 */
  statusTotalSeconds: number;
  /** 开始时间戳（ms） */
  startedAt: number;
  /** 该维护项的完整动作步骤序列，为空或缺省则按 RunAction.ets 通用序列推算 */
  actionSteps?: MaintenanceRuntimeActionStep[];
}

export type MaintenanceRuntimeDisplayListener = (info: MaintenanceRuntimeDisplayInfo | null) => void;

/**
 * 维护运行时单个动作步骤。
 */
export interface MaintenanceRuntimeActionStep {
  actionLabel: string;
  actionTotalSeconds: number;
}

/**
 * MaintenancePanel 调用 start() 前传入的原始信息（不含 startedAt）。
 */
export interface MaintenanceRuntimeInfoInput {
  statusCode: number;
  statusLabel: string;
  statusTotalSeconds: number;
  actionSteps?: MaintenanceRuntimeActionStep[];
}

/**
 * 维护运行时显示服务。
 *
 * 职责：
 * 1. 在运维页面维护面板点击“执行”时，由 MaintenancePanel 调用 start() 发布当前状态。
 * 2. 维护操作结束或停止时，由 MaintenancePanel 调用 clear() 清除显示。
 * 3. FooterBar 通过 addListener() 订阅，把状态显示到底部状态栏（状态文本 + 已执行时间 + 进度条）。
 */
export class MaintenanceRuntimeDisplayService {
  private static currentInfo: MaintenanceRuntimeDisplayInfo | null = null;
  private static listeners: MaintenanceRuntimeDisplayListener[] = [];

  /**
   * 订阅维护运行时显示变化。
   * 如果当前已有正在显示的维护信息，会立即回调一次。
   * 返回取消订阅函数。
   */
  static addListener(listener: MaintenanceRuntimeDisplayListener): () => void {
    if (MaintenanceRuntimeDisplayService.listeners.indexOf(listener) < 0) {
      MaintenanceRuntimeDisplayService.listeners.push(listener);
    }
    if (MaintenanceRuntimeDisplayService.currentInfo !== null) {
      try {
        listener(MaintenanceRuntimeDisplayService.currentInfo);
      } catch (err) {
        hilog.error(DOMAIN, TAG, 'initial listener invoke failed: %{public}s', JSON.stringify(err));
      }
    }
    return (): void => {
      MaintenanceRuntimeDisplayService.listeners = MaintenanceRuntimeDisplayService.listeners.filter(
        (item: MaintenanceRuntimeDisplayListener) => item !== listener
      );
    };
  }

  /**
   * 开始显示某个维护状态。
   */
  static start(
    statusCode: number,
    statusLabel: string,
    statusTotalSeconds: number,
    actionSteps?: MaintenanceRuntimeActionStep[]
  ): void {
    const info: MaintenanceRuntimeDisplayInfo = {
      statusCode,
      statusLabel,
      statusTotalSeconds,
      startedAt: Date.now(),
      actionSteps
    };
    MaintenanceRuntimeDisplayService.currentInfo = info;
    hilog.info(DOMAIN, TAG, 'start statusCode=%{public}d label=%{public}s total=%{public}d steps=%{public}d listeners=%{public}d',
      info.statusCode, info.statusLabel, info.statusTotalSeconds, actionSteps?.length ?? 0,
      MaintenanceRuntimeDisplayService.listeners.length);
    MaintenanceRuntimeDisplayService.notify(info);
  }

  /**
   * 清除维护状态显示，底部状态栏恢复空闲。
   */
  static clear(): void {
    if (MaintenanceRuntimeDisplayService.currentInfo === null) {
      return;
    }
    MaintenanceRuntimeDisplayService.currentInfo = null;
    hilog.info(DOMAIN, TAG, 'clear');
    MaintenanceRuntimeDisplayService.notify(null);
  }

  /**
   * 获取当前维护显示信息，没有则返回 null。
   */
  static getCurrentInfo(): MaintenanceRuntimeDisplayInfo | null {
    return MaintenanceRuntimeDisplayService.currentInfo;
  }

  private static notify(info: MaintenanceRuntimeDisplayInfo | null): void {
    const listeners = MaintenanceRuntimeDisplayService.listeners.slice();
    listeners.forEach((listener: MaintenanceRuntimeDisplayListener) => {
      try {
        listener(info);
      } catch (err) {
        hilog.error(DOMAIN, TAG, 'listener failed: %{public}s', JSON.stringify(err));
      }
    });
  }
}
