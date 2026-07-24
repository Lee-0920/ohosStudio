import { cleanOperation } from '../model/CleanFunc';
import { Task } from '../model/TaskModel';

/**
 * 对外暴露所有Task，方便改动和调用
 */
export class CleanTask {
  static cleanOperation: Task = new Task('cleanOperation', cleanOperation);
}
