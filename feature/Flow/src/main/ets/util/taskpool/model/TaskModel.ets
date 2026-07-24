import taskpool from '@ohos.taskpool';
import { Operator } from '../../../Flow/Operator';
import { ParamA, TestData } from './TaskParam';
import { Config } from '../../../Config/Config'
import { PipeOperationParams, MaintainOperationParams, HardwareOperationParams } from "../../../Setting/Setting";
import { MeasureConfig } from '../../../Flow/MeasureFlow'
import { CleanType } from '../../../../../../Index';

type TaskParam = ParamA | TestData | Operator | Config | PipeOperationParams | MaintainOperationParams | MeasureConfig | CleanType | HardwareOperationParams;

/**
 * 任务类，用来定义线程执行内容
 * @param name: 任务名称
 * @param func: 执行方法
 * @param param: 任务参数
 * @param callback: 任务回调
 */
export class Task {
  private name: string = '';
  private param?: TaskParam;
  private func: Function = () => {};
  private callback?: Function;
  private task: taskpool.Task | undefined = undefined;

  constructor(name: string, func: Function, param?: TaskParam, callback?: Function) {
    this.name = name;
    this.func = func;
    this.param = param;
    this.callback = callback;
  }

  setTaskParam(param?: TaskParam): void {
    if (param != undefined){
      this.param = param;
    }
  }

  // Task任务只能跑一次，所以每次都重新new出来
  getTask(): taskpool.Task {
    this.task = undefined;
    if (this.param === undefined) {
      this.task = new taskpool.Task(this.name, this.func);
    } else {
      this.task = new taskpool.Task(this.name, this.func, this.param);
    }
    if (this.callback) {
      this.task.onReceiveData(this.callback);
    }
    return this.task;
  }

  getTaskName() {
    return this.name;
  }
}