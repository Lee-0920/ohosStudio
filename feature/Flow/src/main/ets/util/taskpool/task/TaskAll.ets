import { Operator } from '../../../Flow/Operator';
import { executeX, executeY, executeZ, executeA,
  drainBeforeMeasure, cleanBeforeMeasure, rinse, addSample, addReagent1, addReagent2, digest,
  digestCooling, readMeasureAD, proformaResult, afterMeasureCooling, drainAfterMeasure, cleanAfterMeasure,
  readInitialAD, finalResult,drainAfterMeasureBlank} from '../model/TaskFunc';
import { Task } from '../model/TaskModel';
import { ParamA, TestData } from '../model/TaskParam';

/**
 * 对外暴露所有Task，方便改动和调用
 */
export class TaskAll {
  static drainBeforeMeasure: Task = new Task('drainBeforeMeasure', drainBeforeMeasure);
  static cleanBeforeMeasure: Task = new Task('cleanBeforeMeasure', cleanBeforeMeasure);
  static rinse: Task = new Task('rinse', rinse);
  static addSample: Task = new Task('addSample', addSample);
  static addReagent1: Task = new Task('addReagent1', addReagent1);
  static addReagent2: Task = new Task('addReagent2', addReagent2);
  static digest: Task = new Task('digest', digest);
  static digestCooling: Task = new Task('digestCooling', digestCooling);
  static readMeasureAD: Task = new Task('readMeasureAD', readMeasureAD);
  static proformaResult: Task = new Task('proformaResult', proformaResult);
  static afterMeasureCooling: Task = new Task('afterMeasureCooling', afterMeasureCooling);
  static drainAfterMeasure: Task = new Task('drainAfterMeasure', drainAfterMeasure);
  static cleanAfterMeasure: Task = new Task('cleanAfterMeasure', cleanAfterMeasure);
  static readInitialAD: Task = new Task('readInitialAD', readInitialAD);
  static finalResult: Task = new Task('finalResult', finalResult);
  static drainAfterMeasureBlank: Task = new Task('drainAfterMeasureBlank', drainAfterMeasureBlank);
}
