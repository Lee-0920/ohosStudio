import { pumpCalibration } from '../model/AutoPumpCalFunc';
import { Task } from '../model/TaskModel';

/**
 * 对外暴露所有Task，方便改动和调用
 */
export class AutoPumpCalibrationTask {
  static pumpCalibration: Task = new Task('pumpCalibration', pumpCalibration);
}
