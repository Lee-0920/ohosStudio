import { dncp, event, EventPack } from 'communication';

export type PT63EventListener = (eventPack: EventPack) => void;

/**
 * PT63 事件统一分发服务。
 *
 * 由于底层 `event.setOnPT63EventCallback` 仅支持注册一个全局回调，
 * 多个页面/组件需要监听 PT63 事件时，通过本服务进行订阅和解耦。
 * 同时本服务按引用计数管理 `dncp.startSignalUpload()` / `dncp.stopSignalUpload()`，
 * 确保只要有组件需要事件就开启信号上报，全部释放后停止以节省资源。
 */
export class PT63EventService {
  private static instance: PT63EventService | null = null;
  private listeners: PT63EventListener[] = [];
  private interestCount: number = 0;
  private isCallbackRegistered: boolean = false;
  private latestEnvironmentTemp: number | null = null;
  private latestThermostatTemp: number | null = null;

  static getInstance(): PT63EventService {
    if (!PT63EventService.instance) {
      PT63EventService.instance = new PT63EventService();
    }
    return PT63EventService.instance;
  }

  private constructor() {}

  /**
   * 获取最近一次 TEMPERATURE 事件中的环境温度（即 SignalPage 中 eventPack.environmentTemp）。
   * 若尚未收到事件，返回 null。
   */
  getLatestEnvironmentTemp(): number | null {
    return this.latestEnvironmentTemp;
  }

  /**
   * 获取最近一次 TEMPERATURE 事件中的消解温度（即 SignalPage 中 eventPack.thermostatTemp）。
   * 若尚未收到事件，返回 null。
   */
  getLatestThermostatTemp(): number | null {
    return this.latestThermostatTemp;
  }

  /**
   * 订阅 PT63 事件。
   * @returns 取消订阅函数，调用后可释放引用并可能停止信号上报。
   */
  subscribe(listener: PT63EventListener): () => void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener);
    }
    this.registerInterest();
    return (): void => {
      this.unsubscribe(listener);
    };
  }

  private unsubscribe(listener: PT63EventListener): void {
    const index = this.listeners.indexOf(listener);
    if (index > -1) {
      this.listeners.splice(index, 1);
    }
    this.releaseInterest();
  }

  private registerInterest(): void {
    this.interestCount++;
    if (this.interestCount === 1) {
      this.startReceiving();
    }
  }

  private releaseInterest(): void {
    if (this.interestCount > 0) {
      this.interestCount--;
      if (this.interestCount === 0) {
        this.stopReceiving();
      }
    }
  }

  private startReceiving(): void {
    if (!this.isCallbackRegistered) {
      event.setOnPT63EventCallback((eventPack: EventPack) => {
        this.dispatch(eventPack);
      });
      this.isCallbackRegistered = true;
    }
    dncp.startSignalUpload();
  }

  private stopReceiving(): void {
    dncp.stopSignalUpload();
  }

  private dispatch(eventPack: EventPack): void {
    if (eventPack.type === 'TEMPERATURE') {
      this.latestEnvironmentTemp = eventPack.environmentTemp;
      this.latestThermostatTemp = eventPack.thermostatTemp;
    }

    const listeners = this.listeners.slice();
    listeners.forEach((listener: PT63EventListener) => {
      try {
        listener(eventPack);
      } catch (err) {
        console.error('PT63EventService listener error:', JSON.stringify(err));
      }
    });
  }
}
