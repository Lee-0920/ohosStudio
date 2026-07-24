import { TaskpoolManager } from '../TaskpoolManager';
import { TaskAll } from './TaskAll';
import { CleanTask } from './CleanTask';
import { AutoPumpCalibrationTask } from './AutoPumpCalibrationTask';
import { AutoADAdjustTask } from './AutoADAdjustTask';
import { PipeOperationTask } from './PipeOperationTask';
import { HardwareTestTask } from './HardwareTestTask';
import { CollectSampleTask } from './CollectSampleTask';
import { ThreadWorkerGlobalScope } from '@kit.ArkTS';
import { MaintainOperationParams, PipeOperationParams, HardwareOperationParams } from "../../../Setting/Setting";
import { CleanType } from '../../../../../../Index';

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

  static testProcess = async (workerPort: ThreadWorkerGlobalScope, params: MaintainOperationParams) => {
    const TOTAL_RUNS = params.runTimes;

    for (let i = 0; i < TOTAL_RUNS; i++) {
      console.info(`========== 开始第 ${i + 1}/${TOTAL_RUNS} 次流程 ==========`);

      try {
        TaskpoolManager.getInstance().init();
        TaskpoolManager.getInstance().enableMeasureFlow(params);
        TaskpoolManager.getInstance().addTask(TaskAll.drainBeforeMeasure);
        TaskpoolManager.getInstance().addTask(TaskAll.cleanBeforeMeasure);
        TaskpoolManager.getInstance().addTask(TaskAll.rinse);
        TaskpoolManager.getInstance().addTask(TaskAll.addSample);
        TaskpoolManager.getInstance().addTask(TaskAll.addReagent1);
        TaskpoolManager.getInstance().addTask(TaskAll.addReagent2);
        TaskpoolManager.getInstance().addTask(TaskAll.digest);
        TaskpoolManager.getInstance().addTask(TaskAll.digestCooling);
        TaskpoolManager.getInstance().addTask(TaskAll.readMeasureAD);
        TaskpoolManager.getInstance().addTask(TaskAll.proformaResult);
        TaskpoolManager.getInstance().addTask(TaskAll.afterMeasureCooling);
        TaskpoolManager.getInstance().addTask(TaskAll.drainAfterMeasure);
        TaskpoolManager.getInstance().addTask(TaskAll.cleanAfterMeasure);
        TaskpoolManager.getInstance().addTask(TaskAll.readInitialAD);
        TaskpoolManager.getInstance().addTask(TaskAll.finalResult);
        TaskpoolManager.getInstance().addTask(TaskAll.drainAfterMeasureBlank);
        await TaskpoolManager.getInstance().runTask(workerPort);

        console.info(`========== 第 ${i + 1}/${TOTAL_RUNS} 次流程完成 ==========`);
      }
      catch (error) {
        console.info(`第 ${i + 1} 次流程异常: %{public}s`, JSON.stringify(error));
        // 🔴 根据业务需求选择以下策略之一：
        // 策略A: 继续下一次 → 使用 continue（需确保设备已回到安全状态）
        // 策略B: 立即停止 → 使用 break
        // 策略C: 重试当前次 → 使用 i-- （需加重试上限防止死循环）
        // break;
      }
    }

    console.info(`========== 全部 ${TOTAL_RUNS} 次流程执行结束 ==========`);
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