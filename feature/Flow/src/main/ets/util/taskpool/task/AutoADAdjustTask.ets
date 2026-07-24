import { adAdjust } from '../model/AutoADAdjustFunc';
import { Task } from '../model/TaskModel';

/**
 * 对外暴露所有Task，方便改动和调用
 */
export class AutoADAdjustTask {
  static adAdjust: Task = new Task('adAdjust', adAdjust);
}
