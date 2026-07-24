// modbus/src/main/ets/utils/EventBus.ets

import { CommLogEntry } from '../model/Types';
import { hilog } from '@kit.PerformanceAnalysisKit';

type LogCallback = (log: CommLogEntry) => void;

class EventBus {
  private static instance: EventBus;
  private logCallbacks: LogCallback[] = [];

  static getInstance(): EventBus {
    if (!EventBus.instance) {
      EventBus.instance = new EventBus();
    }
    return EventBus.instance;
  }

  // 注册日志回调
  onLog(callback: LogCallback): void {
    this.logCallbacks.push(callback);
  }

  // 取消注册
  offLog(callback: LogCallback): void {
    const index = this.logCallbacks.indexOf(callback);
    if (index > -1) {
      this.logCallbacks.splice(index, 1);
    }
  }

  // 发送日志
  emitLog(log: CommLogEntry): void {
    this.logCallbacks.forEach(callback => {
      try {
        callback(log);
      } catch (error) {
        hilog.error(0x0000, 'EventBus', 'emitLog error: %{public}s', JSON.stringify(error));
      }
    });
  }
}

export default EventBus;