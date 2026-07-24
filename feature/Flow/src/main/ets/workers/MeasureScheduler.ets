import { ErrorEvent, MessageEvents, ThreadWorkerGlobalScope, worker } from '@kit.ArkTS';
import hilog from '@ohos.hilog';
import { DateTimeUtil } from 'base';
import { emitter } from '@kit.BasicServicesKit';
import { FlowTask } from '../FlowManager/FlowTask';
import { FlowType } from '../Flow/FlowInterface';

import { measureScheduler, UpdateSchedulerConfig, InitDataBase} from './SchedulerItem';

const workerPort: ThreadWorkerGlobalScope = worker.workerPort;

/**
 * 排期类型枚举
 */
export enum ScheduleType {
  Sample = 0,           // 测量水样
  ZeroCheck = 1,        // 零点核查
  RangeCheck = 2,       // 量程核查
  Standard = 3,         // 测量程校准液
  Blank = 4,            // 测零点校准液
  ExtAddStandard = 5,   // 测加标样
  ExtParallel = 6,      // 测平行样
  Calibrate = 7,        // 校准
}

/**
 * 调度任务接口
 */
interface SchedulerTask {
  name: string;         // 任务名称
  text: string;         // 任务显示名称
  priority: number;     // 优先级（数值越小优先级越高）
  interval: number;     // 周期（小时）
  lastTime: number;     // 上次执行时间
  nextTime: number;     // 下次执行时间
  isRetry: boolean;     // 是否掉电重测
  isTimedMeasure: boolean; // 是否整点测量模式
  calculateNextTime: (startTime: number, runTime: number) => [isValid: boolean, nextTime: number];
  createFlow: (UIContext: Context) => void;
}

interface CurrFlow {
  name: string;
  startTime: number;
  runTime: number;
  endTime: number;
}

// 1. 定义数据结构接口
interface EvenDataStatus {
  name: string;
  time: number;
  isRunning: boolean;
}

interface StatusData {
  data: EvenDataStatus;
}

class MeasureScheduler {
  private static instance: MeasureScheduler;

  private taskQueue: SchedulerTask[] = [];
  private m_readyTask: SchedulerTask | null = null;
  private m_currFlow: CurrFlow = {
    name: "",
    startTime: 0,
    runTime: 0,
    endTime: 0,
  };
  private m_isFlowRunning = false;
  private m_isEnabled = true;
  private m_timeoutFailedReTry = 0;
  private m_loadFailedReTry = 0;

  private m_timerId: number | null = null;
  private m_checkSchedulerTimerId: number | null = null;

  public UIContext: Context | null =  null;

  private constructor() {
    // 延迟启动调度器，确保配置已初始化
    setTimeout(() => {
      this.startScheduler();
    }, 1000); // 延迟1秒启动，确保 EntryAbility 中的初始化已完成
  }

  static getInstance(): MeasureScheduler {
    if (!MeasureScheduler.instance) {
      MeasureScheduler.instance = new MeasureScheduler();
    }
    return MeasureScheduler.instance;
  }

  async Update(): Promise<void> {
    if (this.m_isEnabled) {
      await this.UpdateSlot();
    }
  }

  Enabled(status: boolean): void {
    if (status) {
      let needUpdate = false;
      if (!this.m_isEnabled) {
        needUpdate = true;
      }
      this.m_isEnabled = true;

      if (needUpdate) {
        this.EnabledTimerSlot(true);
        this.Update().catch((e: Error) => console.error("Update failed: " + e));
      }
    } else {
      this.EnabledTimerSlot(false);
      this.m_isEnabled = false;
    }
  }

  private EnabledTimerSlot(status: boolean): void {
    if (status) {
      if (!this.m_checkSchedulerTimerId) {
        this.startCheckSchedulerTimer();
      }
    } else {
      if (this.m_checkSchedulerTimerId) {
        clearInterval(this.m_checkSchedulerTimerId);
        this.m_checkSchedulerTimerId = null;
      }
      if (this.m_timerId) {
        clearTimeout(this.m_timerId);
        this.m_timerId = null;
      }
    }
  }

  private async UpdateSlot(): Promise<void> {
    // 检查运行权限（这里简化处理）
    if (this.m_timerId) {
      clearTimeout(this.m_timerId);
      this.m_timerId = null;
    }
    await this.updateConfig();
    this.UpdateItemList();
    this.UpdateQueue();
    this.UpdateReadyItem();
  }

  async updateConfig(): Promise<void> {
    try {
      await UpdateSchedulerConfig();
      console.log("配置更新完成");
    } catch (error) {
      console.error("更新失败：" + error);
    }
  }

  UpdateItemList(): void {
    if (this.taskQueue.length > 0) {
      this.taskQueue = [];
    }
    for (const schedulerItem of measureScheduler) {
      const isOpenResult = schedulerItem.isOpen();
      const isOpen = isOpenResult[0];
      const isTimedMeasure = isOpenResult[1] ?? false;

      if (isOpen) {
        const result = schedulerItem.getNextTime();
        const valid = result[0];
        if (valid) {
          let task: SchedulerTask = {
            name: schedulerItem.name,
            text: schedulerItem.text,
            priority: schedulerItem.getPriority(),
            interval: schedulerItem.getInterval(),
            lastTime: schedulerItem.getLastTime(),
            nextTime: result[1],
            isRetry: schedulerItem.isRetry(),
            isTimedMeasure: isTimedMeasure,
            calculateNextTime:schedulerItem.calculateNextTime,
            createFlow:schedulerItem.createFlow,
          };
          this.taskQueue.push(task);
          console.info("task: "+task.name+" => taskQueue[].nextTime: " + task.nextTime);
        }
      }
    }
  }

  UpdateQueue(): void {

    if (this.taskQueue.length > 0) {
      this.taskQueue.sort((a: SchedulerTask, b: SchedulerTask): number => {
        return a.nextTime - b.nextTime; //升序排列
      });

      if (this.RetryAnalysis()) {
        return;
      }

      if (this.m_isFlowRunning && this.m_currFlow.name !== "") {
        if (this.m_currFlow.runTime > 0) {
          this.NextTimeAnalysis(this.m_currFlow);
          this.PriorityAnalysis(this.m_currFlow.endTime);
        } else {
          this.taskQueue = [];
        }
      } else {
        this.PriorityAnalysis(DateTimeUtil.getTimestamp());
      }
    }
  }

  private RetryAnalysis(): boolean {
    if (this.taskQueue.length === 0 || this.m_isFlowRunning) {
      return false;
    }

    let foundRetryItem: SchedulerTask | null = null;
    for (const task of this.taskQueue) {
      if (task.isRetry) {
        foundRetryItem = task;
        break;
      }
    }

    if (foundRetryItem) {
      this.taskQueue = [foundRetryItem];
      return true;
    }

    return false;
  }

  private NextTimeAnalysis(currFlow: CurrFlow): void {
    if (this.taskQueue.length === 0) {
      return;
    }

    for (let i = 0; i < this.taskQueue.length; i++) {
      const task = this.taskQueue[i];
      if (task.isTimedMeasure) {
        const result = task.calculateNextTime(currFlow.startTime, currFlow.runTime);
        const valid = result[0];
        if (!valid) {
          this.taskQueue.splice(i, 1);
          i--;
        }
        break;
      }
    }

    for (let i = 0; i < this.taskQueue.length; i++) {
      const task = this.taskQueue[i];
      if (task.name === currFlow.name && !task.isTimedMeasure) {
        const result = task.calculateNextTime(currFlow.startTime, currFlow.runTime);
        const valid = result[0];
        if (!valid) {
          this.taskQueue.splice(i, 1);
          i--;
        }
        break;
      }
    }

    this.taskQueue.sort((a: SchedulerTask, b: SchedulerTask): number => {
      return a.nextTime - b.nextTime;
    });
  }

  private PriorityAnalysis(refTime: number): void {
    if (this.taskQueue.length === 0) {
      return;
    }

    this.taskQueue.sort((a: SchedulerTask, b: SchedulerTask): number => {
      return a.nextTime - b.nextTime;
    });

    const firstItem = this.taskQueue[0];

    if (refTime > firstItem.nextTime) {
      this.taskQueue.sort((a: SchedulerTask, b: SchedulerTask): number => {
        return a.priority - b.priority; //升序排列，数字越小优先级越高
      });

      this.taskQueue = this.taskQueue.filter((task: SchedulerTask) => {
        return task.nextTime <= refTime;
      });

      if (this.taskQueue.length > 0) {
        this.taskQueue[0].nextTime = refTime;
      }
    }
  }

  private timeOutCallBak = (): void => {
    this.TimeoutSlot();
  }

  UpdateReadyItem(): void {
    this.m_readyTask = null;
    const currTime = DateTimeUtil.getTimestamp();
    let times = 0;

    if (this.taskQueue.length > 0) {
      this.m_readyTask = this.taskQueue[0];
      if (this.m_readyTask.name !== "" && this.m_readyTask.nextTime > -1) {
        times = this.m_readyTask.nextTime - currTime;
        if (times <= 0 || this.m_readyTask.isRetry) {
          times = 5;
        } else {
          times = (times + 1) * 1000;
        }

        if (this.m_timerId) {
          clearTimeout(this.m_timerId);
        }
        this.m_timerId = setTimeout(this.timeOutCallBak, times);
        console.info("UpdateReadyItem.time: %d", times);
      }
    }

    this.UpdateExpectInfo(this.m_readyTask?.nextTime ?? -1, this.m_readyTask?.text ?? "");
  }

  private UpdateExpectInfo(nextTime: number, text: string): void {
    let schedulerStr = "";
    if (nextTime > -1 && text !== "") {
      const date = new Date(nextTime * 1000);
      const strTime = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')} ${String(date.getHours()).padStart(2, '0')}:${String(date.getMinutes()).padStart(2, '0')}:${String(date.getSeconds()).padStart(2, '0')}`;
      schedulerStr = `将于 ${strTime} ${text}`;

      console.info(schedulerStr);
    }
    let eventData: emitter.EventData = {
      data: {
        content: schedulerStr,
      }
    };

    emitter.emit("SchedulerInfo", eventData);
  }

  private TimeoutSlot(): void {
    let isFailed = false;
    if (!this.m_isFlowRunning) {
      try {
        if (this.m_readyTask) {
          if(this.UIContext) {
            this.m_readyTask.createFlow(this.UIContext);
          } else {
            console.error("MeasureScheduler::TimeoutSlot() => UIContext is null");
          }

        }
      } catch (e) {
        console.error("MeasureScheduler::TimeoutSlot() => " + JSON.stringify(e));
        isFailed = true;
      }
    }

    if (isFailed) {
      if (this.m_timeoutFailedReTry < 3) {
        this.m_timeoutFailedReTry++;
        console.warn("********** Reset MeasureScheduler **********");
        this.Update().catch((e: Error) => console.error("Update failed: " + e));
      }
    } else {
      this.m_timeoutFailedReTry = 0;
    }
  }

  private checkAndSchedule = (): void => {
    if (!this.m_isFlowRunning && this.taskQueue.length > 0 && !this.m_timerId) {
      if (this.m_loadFailedReTry < 3) {
        this.m_loadFailedReTry++;
        console.warn("********** ReLoad MeasureScheduler **********");
        this.Update().catch((e: Error) => console.error("Update failed: " + e));
      }
    } else {
      this.m_loadFailedReTry = 0;
    }
  }

  private startScheduler(): void {
    this.startCheckSchedulerTimer();

    let callback: Callback<emitter.EventData> = (eventData: emitter.EventData) => {
      let str = JSON.stringify(eventData);
      let statusData:StatusData = JSON.parse(str) as StatusData;
      this.m_isFlowRunning = statusData.data.isRunning;
      if (this.m_isFlowRunning) {
        this.m_currFlow.name = statusData.data.name;
        this.m_currFlow.startTime = DateTimeUtil.getTimestamp();
        this.m_currFlow.runTime = statusData.data.time;
        this.m_currFlow.endTime = this.m_currFlow.startTime + statusData.data.time;
        this.Update().catch((e: Error) => console.error("Update failed: " + e));

      } else {
        this.m_currFlow.name = "";
        this.m_currFlow.startTime = 0;
        this.m_currFlow.runTime = 0;
        this.m_currFlow.endTime = 0;
      }

      console.info(`eventData: ${JSON.stringify(eventData)}`);
    };
    emitter.on("FlowStatus", callback);
  }

  private startCheckSchedulerTimer(): void {
    this.m_checkSchedulerTimerId = setInterval(this.checkAndSchedule, 3000);
  }

  initDataBase(){
    if (this.UIContext != null) {
      InitDataBase(this.UIContext).then(()=>{
        console.info("MeasureScheduler::InitDataBase() => success");
      }).catch((error: Error) => {
        console.error("MeasureScheduler::InitDataBase() => " + JSON.stringify(error));
      })
    } else {
      console.info('MeasureScheduler::InitDataBase() UIContext is null');
    }
  }
}

// 实例化并监听消息
const scheduler = MeasureScheduler.getInstance();
const flowTask = FlowTask.GetInstance();

interface WorkerFlowMessageData {
  flowName: string;
  flowType: FlowType;
  flowNum: number;
}

enum FlowMessage {
  addFlow = 1,
  scheduler = 2,
  context = 3,
  runFlow = 4,
  stopFlow = 5,
  stopScheduler = 6,
}

interface WorkerFlowMessage {
  type: FlowMessage;
  data?: WorkerFlowMessageData;
  context?: Context;
}
/**
 * Defines the event handler to be called when the worker thread receives a message sent by the host thread.
 * The event handler is executed in the worker thread.
 *
 * @param event message data
 */
workerPort.onmessage = (event: MessageEvents) => {
  const message = event.data as WorkerFlowMessage;
  if (!message || !message.type) {
    return;
  }
  hilog.info(1, 'MeasureScheduler', 'worker received message %{public}s', message.type);
  switch (message.type) {
    // case 'startFlow': {
    //   const data = message.data;
    //   if (!data || !data.name) {
    //     return;
    //   }
    //
    //   let flow: MeasureFlow | CalibrateFlow;
    //   if (data.kind === 'calibrate') {
    //     flow = new CalibrateFlow(data.name, data.caliType ?? CalibrateType.calibrate);
    //   } else {
    //     flow = new MeasureFlow(data.name, data.meaType ?? MeasureType.Sample);
    //   }
    //
    //   FlowList.GetInstance().AddFlow(flow);
    //   FlowList.GetInstance().RunAllFlow();
    //   break;
    // }
    case FlowMessage.stopFlow: {
      console.info('workerPort.onmessage: stopFlow');
      flowTask.stopFlow();
      break;
    }
    case FlowMessage.scheduler: {
      console.info('workerPort.onmessage: Scheduler');
      scheduler.Update().catch((e: Error) => console.error("Update failed: " + e));
      break;
    }
    // case 'addFlow': {
    //   const data = message.data;
    //   if (!data || !data.name) {
    //     return;
    //   }
    //   const flow = new MeasureFlow(data.name, data.meaType ?? MeasureType.Sample);
    //   FlowList.GetInstance().AddFlow(flow);
    //   break;
    // }
    case FlowMessage.runFlow: {
      console.info('workerPort.onmessage: runFlow');
      const data = message.data;
      if (scheduler.UIContext) {
        if(data?.flowType && data?.flowName && data?.flowNum ) {
          flowTask.runFlow(data.flowName, data.flowType, data.flowNum, scheduler.UIContext);
        }
      }
      break;
    }
    case FlowMessage.context: {
      let context = message.context as Context;
      scheduler.UIContext = context;
      scheduler.initDataBase();
      console.info('workerPort.onmessage: UIContext: ' + context.processName )
      break;
    }
    case FlowMessage.addFlow: {
      console.info('workerPort.onmessage: addFlow');
      break;
    }
    case FlowMessage.stopScheduler: {
      console.info('workerPort.onmessage: stopScheduler');
      break;
    }
    default:
      break;
  }
};

/**
 * Defines the event handler to be called when the worker receives a message that cannot be deserialized.
 * The event handler is executed in the worker thread.
 *
 * @param event message data
 */
workerPort.onmessageerror = (event: MessageEvents) => {
};

/**
 * Defines the event handler to be called when an exception occurs during worker execution.
 * The event handler is executed in the worker thread.
 *
 * @param event error message
 */
workerPort.onerror = (event: ErrorEvent) => {
};