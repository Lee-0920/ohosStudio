import { calibrate } from '../model/CalibrateFunc';
import { Task } from '../model/TaskModel';

/**
 * 对外暴露所有Task，方便改动和调用
 */
export class CalibrateTask {
  static calibrate: Task = new Task('calibrate', calibrate);
}
