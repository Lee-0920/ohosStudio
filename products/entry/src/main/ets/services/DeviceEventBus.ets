import { hilog } from '@kit.PerformanceAnalysisKit';
import {
  DeviceEvent,
  DeviceEventListener,
  DeviceTopic
} from '../models/deviceStateTypes';

const DOMAIN = 0x0003;
const TAG = 'DeviceEventBus';

export class DeviceEventBus {
  private static connectionListeners: DeviceEventListener[] = [];
  private static runtimeListeners: DeviceEventListener[] = [];
  private static alarmListeners: DeviceEventListener[] = [];
  private static temperatureListeners: DeviceEventListener[] = [];
  private static signalListeners: DeviceEventListener[] = [];
  private static measurementListeners: DeviceEventListener[] = [];

  static subscribe(topic: DeviceTopic, listener: DeviceEventListener): () => void {
    const listeners = DeviceEventBus.listenersForTopic(topic);
    if (listeners.indexOf(listener) < 0) {
      listeners.push(listener);
    }
    return (): void => {
      DeviceEventBus.unsubscribe(topic, listener);
    };
  }

  static unsubscribe(topic: DeviceTopic, listener: DeviceEventListener): void {
    if (topic === 'connection') {
      DeviceEventBus.connectionListeners = DeviceEventBus.connectionListeners.filter(
        (item: DeviceEventListener) => item !== listener
      );
      return;
    }
    if (topic === 'runtime') {
      DeviceEventBus.runtimeListeners = DeviceEventBus.runtimeListeners.filter(
        (item: DeviceEventListener) => item !== listener
      );
      return;
    }
    if (topic === 'alarm') {
      DeviceEventBus.alarmListeners = DeviceEventBus.alarmListeners.filter(
        (item: DeviceEventListener) => item !== listener
      );
      return;
    }
    if (topic === 'temperature') {
      DeviceEventBus.temperatureListeners = DeviceEventBus.temperatureListeners.filter(
        (item: DeviceEventListener) => item !== listener
      );
      return;
    }
    if (topic === 'signal') {
      DeviceEventBus.signalListeners = DeviceEventBus.signalListeners.filter(
        (item: DeviceEventListener) => item !== listener
      );
      return;
    }
    DeviceEventBus.measurementListeners = DeviceEventBus.measurementListeners.filter(
      (item: DeviceEventListener) => item !== listener
    );
  }

  static publish(event: DeviceEvent): void {
    const listeners = DeviceEventBus.listenersForTopic(event.topic).slice();
    listeners.forEach((listener: DeviceEventListener) => {
      try {
        listener(event);
      } catch (err) {
        hilog.error(DOMAIN, TAG, 'Device event listener failed. topic=%{public}s error=%{public}s',
          event.topic, JSON.stringify(err));
      }
    });
  }

  static getSubscriberCount(topic: DeviceTopic): number {
    return DeviceEventBus.listenersForTopic(topic).length;
  }

  private static listenersForTopic(topic: DeviceTopic): DeviceEventListener[] {
    if (topic === 'connection') {
      return DeviceEventBus.connectionListeners;
    }
    if (topic === 'runtime') {
      return DeviceEventBus.runtimeListeners;
    }
    if (topic === 'alarm') {
      return DeviceEventBus.alarmListeners;
    }
    if (topic === 'temperature') {
      return DeviceEventBus.temperatureListeners;
    }
    if (topic === 'signal') {
      return DeviceEventBus.signalListeners;
    }
    return DeviceEventBus.measurementListeners;
  }
}
