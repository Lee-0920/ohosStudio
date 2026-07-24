import { hardwareOperation } from '../model/HardwareTestFunc';
import { Task } from '../model/TaskModel';

/**
 * 对外暴露所有Task，方便改动和调用
 */
export class HardwareTestTask {
  static hardwareOperation: Task = new Task('hardwareOperation', hardwareOperation);
}
