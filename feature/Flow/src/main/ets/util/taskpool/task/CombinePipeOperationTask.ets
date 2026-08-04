import { combinePipeOperation } from '../model/CombinePipeFunc';
import { Task } from '../model/TaskModel';

/**
 * 对外暴露所有Task，方便改动和调用
 */
export class CombinePipeOperationTask {
  static combinePipeOperation: Task = new Task('combinePipeOperation', combinePipeOperation);
}
