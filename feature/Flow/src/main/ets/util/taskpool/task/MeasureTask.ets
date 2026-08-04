import { measure } from '../model/MeasureFunc';
import { Task } from '../model/TaskModel';

/**
 * 对外暴露所有Task，方便改动和调用
 */
export class MeasureTask {
  static measure: Task = new Task('measure', measure);
}
