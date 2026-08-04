import { TaskpoolManager, UserCancelledError } from '../TaskpoolManager';
import { CleanTask } from './CleanTask';
import { AutoPumpCalibrationTask } from './AutoPumpCalibrationTask';
import { AutoADAdjustTask } from './AutoADAdjustTask';
import { PipeOperationTask } from './PipeOperationTask';
import { CombinePipeOperationTask } from './CombinePipeOperationTask';
import { HardwareTestTask } from './HardwareTestTask';
import { CollectSampleTask } from './CollectSampleTask';
import { MeasureTask } from './MeasureTask';
import { CalibrateTask } from './CalibrateTask';
import { ThreadWorkerGlobalScope } from '@kit.ArkTS';
import { MaintainOperationParams, PipeOperationParams, HardwareOperationParams, CombinePipeOperationParams } from "../../../Setting/Setting";
import { CleanType, MeasureType, CalibrateType } from '../../../../../../Index';

/**
 * 对外暴露所有流程，不同流程自行添加任务
 */
export class ProcessManager {
  private static instance: ProcessManager;
  private static processes: Function[] = [];

  static getInstance(): ProcessManager {
    if (!ProcessManager.instance) {
      ProcessManager.instance = new ProcessManager();
    }
    return ProcessManager.instance;
  }

  initProcesses(processes: Function[]) {
    ProcessManager.processes = processes;
  }

  static cleanProcess = async (workerPort: ThreadWorkerGlobalScope, params: MaintainOperationParams) => {
    const cleanType = params.params as CleanType;
    TaskpoolManager.getInstance().init();
    TaskpoolManager.getInstance().addTask(CleanTask.cleanOperation, cleanType);
    await TaskpoolManager.getInstance().runTask(workerPort);
  }

  static pipeOperationProcess = async (workerPort: ThreadWorkerGlobalScope, params: PipeOperationParams) => {
    TaskpoolManager.getInstance().init();
    TaskpoolManager.getInstance().addTask(PipeOperationTask.pipeOperation, params);
    await TaskpoolManager.getInstance().runTask(workerPort);
  }

  static combinePipeOperationProcess = async (workerPort: ThreadWorkerGlobalScope, params: CombinePipeOperationParams) => {
    TaskpoolManager.getInstance().init();
    TaskpoolManager.getInstance().addTask(CombinePipeOperationTask.combinePipeOperation, params);
    await TaskpoolManager.getInstance().runTask(workerPort);
  }

  static hardwareTestProcess = async (workerPort: ThreadWorkerGlobalScope, params: HardwareOperationParams) => {
    TaskpoolManager.getInstance().init();
    TaskpoolManager.getInstance().addTask(HardwareTestTask.hardwareOperation, params);
    await TaskpoolManager.getInstance().runTask(workerPort);
  }

  static autoPumpCalibrationTask = async (workerPort: ThreadWorkerGlobalScope) => {
    TaskpoolManager.getInstance().init();
    TaskpoolManager.getInstance().addTask(AutoPumpCalibrationTask.pumpCalibration);
    await TaskpoolManager.getInstance().runTask(workerPort);
  }

  static autoADAdjustTask = async (workerPort: ThreadWorkerGlobalScope, params: HardwareOperationParams) => {
    TaskpoolManager.getInstance().init();
    TaskpoolManager.getInstance().addTask(AutoADAdjustTask.adAdjust, params);
    await TaskpoolManager.getInstance().runTask(workerPort);
  }

  static collectSampleTask = async (workerPort: ThreadWorkerGlobalScope) => {
    TaskpoolManager.getInstance().init();
    TaskpoolManager.getInstance().addTask(CollectSampleTask.collectSample);
    await TaskpoolManager.getInstance().runTask(workerPort);
  }

  static measureProcess = async (workerPort: ThreadWorkerGlobalScope, params: MaintainOperationParams) => {
    const measureType = params.params as MeasureType;
    const TOTAL_RUNS = params.runTimes;
    for (let i = 0; i < TOTAL_RUNS; i++) {
      console.info(`========== 开始第 ${i + 1}/${TOTAL_RUNS} 次流程 ==========`);
      try {
        TaskpoolManager.getInstance().init();
        TaskpoolManager.getInstance().addTask(MeasureTask.measure, measureType);
        await TaskpoolManager.getInstance().runTask(workerPort);

        console.info(`========== 第 ${i + 1}/${TOTAL_RUNS} 次流程完成 ==========`);
      }
      catch (error) {
        console.info(`第 ${i + 1} 次流程异常: %{public}s`, JSON.stringify(error));
        if (error instanceof UserCancelledError) {
          console.info(`========== 用户主动停止，已执行 ${i}/${TOTAL_RUNS} 次 ==========`);
          break;
        }
      }
    }
    console.info(`========== 全部 ${TOTAL_RUNS} 次流程执行结束 ==========`);
  }

  static calibrateProcess = async (workerPort: ThreadWorkerGlobalScope, params: MaintainOperationParams) => {
    const calibrateType = params.params as CalibrateType;
    TaskpoolManager.getInstance().init();
    TaskpoolManager.getInstance().addTask(CalibrateTask.calibrate, calibrateType);
    await TaskpoolManager.getInstance().runTask(workerPort);
  }

  static stopProcess = async (workerPort: ThreadWorkerGlobalScope) => {
    // TaskpoolManager.getInstance().init();
    TaskpoolManager.getInstance().stopTask();
  }

  async runProcess() {
    for (let index = 0; index < ProcessManager.processes.length; index++) {
      const process = ProcessManager.processes[index];
      await process();
    }
  }

}