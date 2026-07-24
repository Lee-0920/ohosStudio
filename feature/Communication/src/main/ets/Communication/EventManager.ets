import communication from 'libcommunication.so';
import type { EventPack } from 'libcommunication.so';

export class Event {
  setOnPT63EventCallback(callback: (event: EventPack) => void): void {
    communication.event_setOnPT63EventCallback(callback);
  }
}

export type { EventPack };

export default new Event();