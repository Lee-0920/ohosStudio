import { pipeOperation } from '../model/PipeOperationFunc';
import { Task } from '../model/TaskModel';

/**
 * 对外暴露所有Task，方便改动和调用
 */
export class PipeOperationTask {
  static pipeOperation: Task = new Task('pumpFromBlank', pipeOperation);
}
