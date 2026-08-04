import taskpool from '@ohos.taskpool';
import { Task } from './model/TaskModel';
import { ThreadWorkerGlobalScope, worker, MessageEvents, ErrorEvent } from '@kit.ArkTS';
import { MeasureType, MeasureConfig } from '../../Flow/MeasureFlow'
import { PipeOperationParams, MaintainOperationParams, HardwareOperationParams, CombinePipeOperationParams } from "../../Setting/Setting";
import { CleanType, CalibrateType } from '../../../../../Index';
import { MeasureData, CaliData } from '../../DataManager/DataBase';


// ✅ 1. 定义统一的任务队列节点，将 Task 与 Payload 原子绑定
interface TaskQueueItem {
  task: Task;
  payload?: PipeOperationParams | MaintainOperationParams | MeasureConfig | CleanType | HardwareOperationParams | MeasureType | CalibrateType | CombinePipeOperationParams;
}

// 所有 @Concurrent 任务统一返回此结构
export interface TaskResultWrapper {
  type: 'measure' | 'calibrate' | 'other';
  data: MeasureData | CaliData | object | null;
}

// 用户主动取消的专用异常类
export class UserCancelledError extends Error {
  constructor() {
    super('User cancelled operation');
    this.name = 'UserCancelledError';
  }
}

interface TaskPoolCancelErrorData {
  error: string;
  result?: object;
}

interface BusinessErrorLike {
  name: string;
  code?: number;
  data?: TaskPoolCancelErrorData;
}
/*
* 停止事件接口
 */
export interface MessageStopEvent {
  type: string;
  info: string;
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
  private measureFlowName: String = '';
  private stopWorker: worker.ThreadWorker | null = null;

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
  }

  addTask(task: Task, payload?: PipeOperationParams | MaintainOperationParams | MeasureConfig |
        CleanType | HardwareOperationParams | MeasureType | CalibrateType | CombinePipeOperationParams) {
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
    this.taskQueue = [];
    taskpool.cancel(this.currentTask);
    this.triggerStop();
  }

  /**
   * 触发专属 Worker 执行硬件停止
   * postMessage 是即时投递，不经过任何队列
   */
  private triggerStop(): void {
    // 懒初始化：首次停止时才创建 Worker
    if (!this.stopWorker) {
      try {
        this.stopWorker = new worker.ThreadWorker('Flow/ets/workers/StopWorker.ets');

        // 监听停止结果（可选，用于日志或UI反馈）
        this.stopWorker.onmessage = (e: MessageEvents) => {
          const msg = e.data as MessageStopEvent;
          if (msg.type === 'HARDWARE_STOP_DONE') {
            console.info('TaskpoolManager', '停止成功');
          } else if (msg.type === 'HARDWARE_STOP_ERROR') {
            console.error('TaskpoolManager', '停止失败: %{public}s', msg.info);
          }
        };

        this.stopWorker.onerror = (e: ErrorEvent) => {
          console.error('TaskpoolManager', 'StopWorker异常: %{public}s', e.message);
        };
      } catch (err) {
        console.error('TaskpoolManager', '创建StopWorker失败: %{public}s',
          (err as Error).message);
        return;
      }
    }

    // 即时发送，不等待，不阻塞
    this.stopWorker.postMessage({ type: 'HARDWARE_STOP' });
    console.info('TaskpoolManager', '已向StopWorker发送停止指令');
  }

  /**
   * 应用退出时清理专属 Worker
   */
  destroy(): void {
    if (this.stopWorker) {
      this.stopWorker.terminate();
      this.stopWorker = null;
      console.info('TaskpoolManager', 'StopWorker已销毁');
    }
  }

  /**
   * 检测抛出事件为停止事件，向ProcessManager抛出错误，停止后续流程。
   */
  isTaskCancelledError(err: object): boolean {
    if (!err || typeof err !== 'object') {
      return false;
    }

    const error = err as BusinessErrorLike;

    return error.name === 'BusinessError'
      && error.data !== undefined
      && error.data !== null
      && error.data.error === 'taskpool:: task has been canceled';
  }

  /**
   * 结果处理：筛选需要存储到数据库的数据，抛出由数据库存储。
   */
  resultHandle(workerPort: ThreadWorkerGlobalScope, task: Task, data: object): void {
    const wrapper = data as TaskResultWrapper;

    // 防御性检查：确保 wrapper 结构合法
    if (!wrapper || typeof wrapper.type !== 'string') {
      console.warn(`TLQQ, task: ${task.getTaskName()} 返回了非法的结果包装`);
      workerPort.postMessage({ status: 'success', result: data });
      return;
    }

    switch (wrapper.type) {
      case 'measure': {
        const measureData = wrapper.data as MeasureData | null;
        if (measureData && !this.isStopping) {
          console.info(`TLQQ, 获取到有效 MeasureData, dateTime=${measureData.dateTime}`);
          workerPort.postMessage({
            status: 'complete',
            type: 'measureComplete',
            data: measureData
          });
        } else {
          console.warn(`TLQQ, task: ${task.getTaskName()} MeasureData 为空或已停止`);
        }
        break;
      }

      case 'calibrate': {
        const caliData = wrapper.data as CaliData | null;
        if (caliData && !this.isStopping) {
          console.info(`TLQQ, 获取到有效 CaliData, dateTime=${caliData.dateTime}`);
          workerPort.postMessage({
            status: 'complete',
            type: 'calibrateComplete',  // ← 注意：应与 measureComplete 区分
            data: caliData
          });
        } else {
          console.warn(`TLQQ, task: ${task.getTaskName()} CaliData 为空或已停止`);
        }
        break;
      }

      default: {
        console.info(`TLQQ, task: ${task.getTaskName()} 返回通用结果, type=${wrapper.type}`);
        break;
      }
    }
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
      let currentTask = item.task.getTask();
      this.currentTask = currentTask;
      this.currentRunTime = new Date();
      await taskpool.execute(currentTask).then((data: object) => {

        //结果处理：目前只处理测量数据&校准数据
        this.resultHandle(workerPort, item.task, data);

        // console.info(`TLQQ, task: ${task.getTaskName()} return result: ${JSON.stringify(data)}`);
        // console.info(`TLQQ, task: ${task.getTaskName()} return result no json: ${data}`);
        console.info(`TLQQ, task: ${item.task.getTaskName()} execute end, 向UI线程发送消息`);
        workerPort.postMessage({
          status: 'success',
          result: data
        });
      }).catch((err: object) => {
        console.info(`TLQQ, task: ${item.task.getTaskName()} return err: ${JSON.stringify(err)}`);
        if(this.isTaskCancelledError(err)){
          throw new UserCancelledError();
        }
      })
    }

    this.endRunTime = new Date(); // 总任务结束时间
  }
}