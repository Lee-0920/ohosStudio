import { ErrorEvent, MessageEvents, worker } from '@kit.ArkTS';
import { ParameterItem } from '../Config/BaseEnum';
import { MeasurementScheduleConfig } from '../Config/ScheduleMeasurementConfig';
import { CalculateModel } from '../util/taskpool/model/CalculateModel';
import { MeasureData } from '../DataManager/DataBase';
import { ResultManager, MeasureRecord } from 'dataservice';

export class WorkerManager {
  private static workerManager: WorkerManager | undefined = undefined;
  private worker: worker.ThreadWorker | undefined = undefined;
  private listeners: Map<string, (event: MessageEvents) => void> = new Map();

  // todo: 是否加全局锁，防止多次触发任务，还是允许多种不同任务并行

  private constructor() {
    this.worker = new worker.ThreadWorker('Flow/ets/workers/Worker.ets')
    this.worker.onmessage = (event: MessageEvents) => {
      this.handleInternalMessage(event);
      this.listeners.forEach((value, key) => {
        console.info(`TLQQ, desc: ${key} receive callback`);
        value(event);
      });
    }
  }
  static getInstance(): WorkerManager {
    if (!WorkerManager.workerManager) {
      WorkerManager.workerManager = new WorkerManager();
    }
    return WorkerManager.workerManager;
  }

  /**
   * 接收worker线程发送的数据
   * @param desc 处理方法的描述/什么地方会使用到, example: 用于刷新xx界面xx参数
   * @param func 处理worker线程返回数据的方法
   */
  onmessage(desc: string, func: (event: MessageEvents) => void) {
    if (!this.worker) {
      console.error(`TLQQ, worker未正常初始化`);
      return;
    }
    if (!this.listeners.has(desc)) {
      this.listeners.set(desc, func);
    }
  }

  /**
   * 去掉回调
   * @param desc 需要去掉的回调描述
   */
  offmessage(desc: string) {
    if (this.listeners.has(desc)) {
      console.info(`TLQQ, 已去掉 ${desc} 的回调`);
      this.listeners.delete(desc);
    }
  }

  private handleInternalMessage(event: MessageEvents): void {
    if (event.data?.type === 'measureComplete' && event.data?.data) {
      console.info("recv measureComplete");
      void this.saveMeasureRecord(event.data.data as MeasureData);
    }
  }

  private async saveMeasureRecord(record: MeasureData): Promise<void> {
    try {
      const resultManager = ResultManager.getInstance();
      if (!resultManager.isReady()) {
        console.warn('WorkerManager: ResultManager 尚未初始化，无法保存测量记录');
        return;
      }
      const measureRecord = new MeasureRecord();
      measureRecord.dateTime = record.dateTime;
      measureRecord.initReferenceAD = record.initReferenceAD;
      measureRecord.initMeasureAD = record.initMeasureAD;
      measureRecord.finalReferenceAD = record.finalReferenceAD;
      measureRecord.finalMeasureAD = record.finalMeasureAD;
      measureRecord.initThermostatTemp = record.initThermostatTemp;
      measureRecord.initEnvironmentTemp = record.initEnvironmentTemp;
      measureRecord.finalThermostatTemp = record.finalThermostatTemp;
      measureRecord.finalEnvironmentTemp = record.finalEnvironmentTemp;
      measureRecord.consistency = record.consistency;
      measureRecord.absorbance = record.absorbance;
      measureRecord.mode = record.mode;
      measureRecord.resultType = record.resultType;
      measureRecord.versionString = '1, 0, 0, 2';
      const id = await resultManager.addMeasureRecord('test', measureRecord, false);
      if (id > 0) {
        console.info(`WorkerManager: 添加测量记录成功: ${id}`);
      } else {
        console.error('WorkerManager: 添加测量记录失败');
      }
    } catch (err) {
      console.error(`WorkerManager: 添加测量记录异常: ${err}`);
    }
  }

  onmessageerror(event: MessageEvents) {

  }

  onerror(event: ErrorEvent) {

  }

  /**
   * 向worker线程发送数据
   * @param event 需要发送的数据
   */
  postMessage(event: MessageEvents) {
    if (this.worker) {
      this.worker.postMessage(event);
    }
  }

  /**
   * 定时流程
   */
  calculateProcess() {
    let calculateModel = new CalculateModel();
    for (let index = 0; index < MeasurementScheduleConfig.type.length; index++) {
      const type = MeasurementScheduleConfig.type[index];
      console.info(`TLQQ, type.name: ${type.name}`);
      calculateModel.setName(type.name);
      for (let index1 = 0; index1 < type.params.length; index1++) {
        const param = type.params[index1];
        console.info(`TLQQ, param.value: ${param.value}`);
        console.info(`TLQQ, param.unit: ${param.unit}`);
        if (param.paramName === ParameterItem.INTERVALPERIOD && typeof param.value === 'number') {
          calculateModel.setIntervalPeriod(param.value);
        } else if (param.paramName === ParameterItem.TIMEPOINTSET && typeof param.value === 'string') {
          calculateModel.setTimePointSet(param.value);
        } else if (param.paramName === ParameterItem.INTERVALTIME && typeof param.value === 'number') {
          calculateModel.setIntervalTime(param.value);
        }
      }
    }
    if (this.worker) {
      this.worker.postMessage({
        type: 'calculateProcess',
        data: {

        },
        timestamp: 12
      });
    }

  }
}