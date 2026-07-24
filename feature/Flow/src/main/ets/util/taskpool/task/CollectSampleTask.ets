import { collectSample } from '../model/CollectSampleFunc';
import { Task } from '../model/TaskModel';

/**
 * 对外暴露所有Task，方便改动和调用
 */
export class CollectSampleTask {
  static collectSample: Task = new Task('collectSample', collectSample);
}
