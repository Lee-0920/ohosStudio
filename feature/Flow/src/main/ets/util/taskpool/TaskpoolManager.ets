import taskpool from '@ohos.taskpool';
import { Task } from './model/TaskModel';
import { ThreadWorkerGlobalScope } from '@kit.ArkTS';
import { createEmptyMeasureResult, MeasureResult, Measurer } from '../../Flow/Measurer';
import { MeasureFlow, MeasureType, MeasureConfig } from '../../Flow/MeasureFlow'
import { PipeOperationParams, MaintainOperationParams, HardwareOperationParams } from "../../Setting/Setting";
import { Operator } from '../../Flow/Operator';
import { CleanType } from '../../../../../Index';


// ✅ 1. 定义统一的任务队列节点，将 Task 与 Payload 原子绑定
interface TaskQueueItem {
  task: Task;
  payload?: PipeOperationParams | MaintainOperationParams | MeasureConfig | CleanType | HardwareOperationParams;
}

/**
 * 流程总控制器，初始化，添加/停止/执行任务
 */
@ObservedV2
export class TaskpoolManager {
  private static manager: TaskpoolManager | undefined = undefined;
  private currentTask: taskpool.Task | undefined = undefined;
  @Trace private startRunTime: Date | undefined = undefined;
  private endRunTime: Date | undefined = undefined;
  private currentRunTime: Date | undefined = undefined;
  // private endRunTime: Date | undefined = undefined;
  private taskQueue: TaskQueueItem[] = [];
  private isStopping: Boolean = false;
  private enableResultHandle: boolean = false;
  private measureResult: MeasureResult | undefined = undefined;
  private measureFlow: MeasureFlow | undefined = undefined;
  private measureFlowName: String = '';
  private currentMeasureConfig: MeasureConfig | undefined= undefined;

  static getInstance(): TaskpoolManager {
    if (!TaskpoolManager.manager) {
      TaskpoolManager.manager = new TaskpoolManager();
    }
    return TaskpoolManager.manager;
  }

  init() {
    console.info(`TLQQ, taskpool初始化`);
    this.isStopping = false;
    this.taskQueue = [];
    this.currentTask = undefined;
    this.startRunTime = undefined;
    this.endRunTime = undefined;
    this.currentRunTime = undefined;
    this.currentMeasureConfig = undefined;
    this.measureFlow = undefined;
    this.enableResultHandle = false;
  }

  addTask(task: Task, payload?: PipeOperationParams | MaintainOperationParams | MeasureConfig | CleanType | HardwareOperationParams) {
    console.info(`TLQQ, taskpool添加任务: ${task.getTaskName()}`);
    if (payload !== undefined) {
      // 有参任务：序列化并绑定参数
      this.taskQueue.push({ task, payload });
    }else{
      this.taskQueue.push({task});
    }
  }

  stopTask() {
    console.info('TLQQ, StopTask');
    this.isStopping = true;
    this.enableResultHandle = false;
    this.taskQueue = [];
    taskpool.cancel(this.currentTask);
    Operator.getInstance().Stop();
  }

  enableMeasureFlow(arg: MaintainOperationParams){
    const measureType = arg.params as MeasureType;
    switch (arg.params){
      case MeasureType.Sample:
        this.measureFlowName = 'MeasureSample';
        break;
      case MeasureType.Blank:
        this.measureFlowName = 'MeasureBlank';
        break;
      case MeasureType.Standard:
        this.measureFlowName = 'MeasureStandard';
        break;
      case MeasureType.ZeroCheck:
        this.measureFlowName = 'MeasureZeroCheck';
        break;
      case MeasureType.RangeCheck:
        this.measureFlowName = 'MeasureRangeCheck';
        break;
    }
    this.enableResultHandle = true;
    this.measureResult = createEmptyMeasureResult();
    this.measureFlow = new MeasureFlow(this.measureFlowName.toString(), measureType);
    this.measureFlow.measureType = measureType;
    //调用MeasureFlow初始化，方便流程中调用Measure内部参数
    this.measureFlow.OnStart();
    this.measureFlow.OnProcess();
    // 提取可序列化配置
    this.currentMeasureConfig = this.measureFlow.exportConfig();
  }

  mergeMeasureResult(target: MeasureResult, source: Partial<MeasureResult>): void {
    if (source.initReferenceAD !== undefined) target.initReferenceAD = source.initReferenceAD;
    if (source.initMeasureAD !== undefined) target.initMeasureAD = source.initMeasureAD;
    if (source.finalReferenceAD !== undefined) target.finalReferenceAD = source.finalReferenceAD;
    if (source.finalMeasureAD !== undefined) target.finalMeasureAD = source.finalMeasureAD;
     if (source.darkReferenceAD !== undefined) target.darkReferenceAD = source.darkReferenceAD;
     if (source.darkMeasureAD !== undefined) target.darkMeasureAD = source.darkMeasureAD;
    if (source.initThermostatTemp !== undefined) target.initThermostatTemp = source.initThermostatTemp;
    if (source.initEnvironmentTemp !== undefined) target.initEnvironmentTemp = source.initEnvironmentTemp;
    if (source.finalThermostatTemp !== undefined) target.finalThermostatTemp = source.finalThermostatTemp;
    if (source.finalEnvironmentTemp !== undefined) target.finalEnvironmentTemp = source.finalEnvironmentTemp;
  }

  async runTask(workerPort: ThreadWorkerGlobalScope) {
    console.info(`TLQQ, taskpool开始执行任务`);
    this.startRunTime = new Date(); // 总任务开始时间
    for (let index = 0; index < this.taskQueue.length; index++) {
      const item  = this.taskQueue[index];
      console.info(`TLQQ, task: ${item.task.getTaskName()} is execute`);
      if (item.payload !== undefined)
      {
        item.task.setTaskParam(item.payload);
      }
      if (this.currentMeasureConfig !== undefined)
      {
        item.task.setTaskParam(this.currentMeasureConfig);
      }
      let currentTask = item.task.getTask();
      this.currentTask = currentTask;
      this.currentRunTime = new Date();
      await taskpool.execute(currentTask).then((data: object) => {
        // ✅ 核心：将任务返回的部分字段合并到总结果中
        // Object.assign 只覆盖 data 中存在的键，{} 空对象无任何影响
        if (data && typeof data === 'object' && this.measureResult) {
          this.mergeMeasureResult(this.measureResult, data as Partial<MeasureResult>);
        }
        // console.info(`TLQQ, task: ${task.getTaskName()} return result: ${JSON.stringify(data)}`);
        // console.info(`TLQQ, task: ${task.getTaskName()} return result no json: ${data}`);
        console.info(`TLQQ, task: ${item.task.getTaskName()} execute end, 向UI线程发送消息`);
        workerPort.postMessage({
          status: 'success',
          result: data
        });
      }).catch((err: object) => {
        console.info(`TLQQ, task: ${item.task.getTaskName()} return err: ${JSON.stringify(err)}`);
      })
    }

    if(this.measureFlow && this.enableResultHandle && !this.isStopping && this.measureResult)
    {
      this.measureFlow.ResultHandle(this.measureResult);
      if (this.measureFlow.lastMeasureRecord) {
        workerPort.postMessage({
          status: 'complete',
          type: 'measureComplete',
          data: this.measureFlow.lastMeasureRecord
        });
        console.info("post measureComplete");
      }
    }
    this.endRunTime = new Date(); // 总任务结束时间
  }
}