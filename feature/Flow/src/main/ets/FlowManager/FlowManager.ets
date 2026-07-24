import { hilog } from '@kit.PerformanceAnalysisKit';
import { worker, MessageEvents } from '@kit.ArkTS';
import { MeasureType } from '../Flow/MeasureFlow';
import { CalibrateType } from '../Flow/CalibrateFlow';
import { FlowType } from '../Flow/FlowInterface';
import { MeasureData } from '../DataManager/DataBase';
import { ResultManager, MeasureRecord } from 'dataservice';

const DOMAIN = 0x0001;

enum FlowMessage {
  addFlow = 1,
  scheduler = 2,
  context = 3,
  runFlow = 4,
  stopFlow = 5,
}

interface WorkerFlowMessageData {
  flowName: string;
  flowType: FlowType;
  flowNum: number;
}

interface WorkerFlowMessage {
  type: FlowMessage;
  data?: WorkerFlowMessageData;
  context?: Context;
}


export class FlowManager {
  private static workerInstance: worker.ThreadWorker | null = null;

  private static ensureWorker(): worker.ThreadWorker {
    if (!FlowManager.workerInstance) {
      try {
        FlowManager.workerInstance = new worker.ThreadWorker('Flow/ets/workers/MeasureScheduler.ets');
        FlowManager.workerInstance.onmessage = (event: MessageEvents) => {
          FlowManager.handleWorkerMessage(event);
        }
      } catch (error) {
        hilog.error(DOMAIN, 'flowManager', 'Failed to create worker: %{public}s', String(error));
        throw new Error('Failed to create worker: ' + String(error));
      }
    }
    return FlowManager.workerInstance;
  }

  private static handleWorkerMessage(event: MessageEvents): void {
    if (event.data?.type === 'measureComplete' && event.data?.data) {
      void FlowManager.saveMeasureRecord(event.data.data as MeasureData);
    }
  }

  private static async saveMeasureRecord(record: MeasureData): Promise<void> {
    try {
      const resultManager = ResultManager.getInstance();
      if (!resultManager.isReady()) {
        console.warn('FlowManager: ResultManager 尚未初始化，无法保存测量记录');
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
        console.info(`FlowManager: 添加测量记录成功: ${id}`);
      } else {
        console.error('FlowManager: 添加测量记录失败');
      }
    } catch (err) {
      console.error(`FlowManager: 添加测量记录异常: ${err}`);
    }
  }

  static AddFlow(name: string, flowType: FlowType, flowNum:number ): void {
    try {
      const workerInstance = FlowManager.ensureWorker();
      workerInstance.postMessage({
        type: 'addFlow',
        data: { name, flowType, flowNum },
      });
    } catch (error) {
      hilog.error(DOMAIN, 'flowManager', 'AddFlow failed: %{public}s', String(error));
    }
  }

  static startFlow(name: string, type: FlowType, num:number): boolean {
    try {
      const workerInstance = FlowManager.ensureWorker();
      workerInstance.postMessage({
        type: 'startFlow',
        data: { flowName: name, flowType: type, flowNum: num }
      });
      return true;
    } catch (error) {
      hilog.error(DOMAIN, 'flowManager', 'startFlow failed: %{public}s', String(error));
      return false;
    }
  }

  static Scheduler(): boolean {
    try {
      const workerInstance = FlowManager.ensureWorker();
      workerInstance.postMessage({
        type: 'Scheduler',
      });
      return true;
    } catch (error) {
      hilog.error(DOMAIN, 'flowManager', 'startFlow failed: %{public}s', String(error));
      return false;
    }
  }

  static DBConfig(UIContext:Context): boolean {
    try {
      const workerInstance = FlowManager.ensureWorker();
      workerInstance.postMessage({
        type: 'context',
        context: UIContext,
      });
      return true;
    } catch (error) {
      hilog.error(DOMAIN, 'flowManager', 'startFlow failed: %{public}s', String(error));
      return false;
    }
  }

  static stopFlow(): boolean {
    try {
      const workerInstance = FlowManager.ensureWorker();
      workerInstance.postMessage({ type: 'stopFlow' });
      workerInstance.terminate();
      FlowManager.workerInstance = null;
      hilog.info(DOMAIN, 'flowManager', 'stopFlow message sent');
      return true;
    } catch (error) {
      hilog.error(DOMAIN, 'flowManager', 'stopFlow failed: %{public}s', String(error));
      return false;
    }
  }
}
