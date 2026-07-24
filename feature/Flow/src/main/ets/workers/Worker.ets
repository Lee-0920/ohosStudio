import { ErrorEvent, MessageEvents, ThreadWorkerGlobalScope, worker } from '@kit.ArkTS';
import { ProcessManager } from '../util/taskpool/task/ProcessManager';
import { MaintainOperationParams, PipeOperationParams, HardwareOperationParams } from "../Setting/Setting";



const workerPort: ThreadWorkerGlobalScope = worker.workerPort;
let timer: number | undefined = undefined;
let running: boolean = true;

// 1. 定义 Worker 维护操作消息的完整结构接口
interface MaintenanceOperatorMessage {
  type: string;
  timeStamp: number;
  data: MaintainOperationParams;
}

// 1. 定义 Worker 管道操作消息的完整结构接口
interface PipeOperatorMessage {
  type: string;
  timeStamp: number;
  data: PipeOperationParams;
}

// 1. 定义 Worker 硬件测试消息的完整结构接口
interface HardwareOperatorMessage {
  type: string;
  timeStamp: number;
  data: HardwareOperationParams;
}

/**
 * Defines the event handler to be called when the worker thread receives a message sent by the host thread.
 * The event handler is executed in the worker thread.
 *
 * @param event message data
 */
workerPort.onmessage = async (event: MessageEvents) => {
  console.info(`TLQQ, worker线程接受到UI线程发送的消息: ${JSON.stringify(event)}, 启动测试流程`);
  // todo: 把消息类型封装成enum，减少维护
  switch (event.data.type) {
    case 'startMeasure':
      console.info(`Worker received maintenance message: ${JSON.stringify(event.data)}`);

      // 2. 显式断言为已知接口，消除 any/unknown
      const messageMt = event.data as MaintenanceOperatorMessage;
      const payloadMt: MaintainOperationParams = messageMt.data;

      // 2. 安全校验（防止 UI 传参结构异常导致 Worker 崩溃）
      if (!payloadMt) {
        console.error(`Worker: Invalid maintenance payload: ${JSON.stringify(payloadMt)}`);
        break;
      }

      // 3. 显式声明类型并解构所需参数
      const paramsMt = payloadMt as MaintainOperationParams;
      console.info(`TLQQ, 解析维护-测量操作参数: maintenceTypes=${paramsMt.maintenceTypes}, params=${paramsMt.params}, runTimes=${paramsMt.runTimes}`);
      await ProcessManager.testProcess(workerPort, paramsMt);
      break;
    case 'stop':
      await ProcessManager.stopProcess(workerPort);
      break;
    case 'startClean':
      console.info(`Worker received maintenance message: ${JSON.stringify(event.data)}`);

      // 2. 显式断言为已知接口，消除 any/unknown
      const messageCl = event.data as MaintenanceOperatorMessage;
      const payloadCl: MaintainOperationParams = messageCl.data;

      // 2. 安全校验（防止 UI 传参结构异常导致 Worker 崩溃）
      if (!payloadCl) {
        console.error(`Worker: Invalid maintenance payload: ${JSON.stringify(payloadCl)}`);
        break;
      }

      // 3. 显式声明类型并解构所需参数
      const paramsCl = payloadCl as MaintainOperationParams;
      console.info(`TLQQ, 解析维护-清洗操作参数: maintenceTypes=${paramsCl.maintenceTypes}, params=${paramsCl.params}, runTimes=${paramsCl.runTimes}`);
      await ProcessManager.cleanProcess(workerPort, paramsCl);
      break;
    case 'pipeOperator':
      console.info(`Worker received pipeOperator message: ${JSON.stringify(event.data)}`);

      // 2. 显式断言为已知接口，消除 any/unknown
      const message = event.data as PipeOperatorMessage;
      const payload: PipeOperationParams = message.data;

      // 2. 安全校验（防止 UI 传参结构异常导致 Worker 崩溃）
      if (!payload || typeof payload.liquidName !== 'string' || typeof payload.volume !== 'number') {
        console.error(`Worker: Invalid pipeOperator payload: ${JSON.stringify(payload)}`);
        break;
      }

      // 3. 显式声明类型并解构所需参数
      const params = payload as PipeOperationParams;
      console.info(`TLQQ, 解析管道操作参数: liquidType=${params.liquidName}, dir=${params.dir}, volume=${params.volume}, mode=${params.mode}`);
      await ProcessManager.pipeOperationProcess(workerPort, params);
      break;
    case 'hardwareOperation':
      console.info(`Worker received haraware message: ${JSON.stringify(event.data)}`);

      // 2. 显式断言为已知接口，消除 any/unknown
      const messageHw = event.data as HardwareOperatorMessage;
      const payloadHw: HardwareOperationParams = messageHw.data;

      // 2. 安全校验（防止 UI 传参结构异常导致 Worker 崩溃）
      if (!payloadHw) {
        console.error(`Worker: Invalid hardware payload: ${JSON.stringify(payloadHw)}`);
        break;
      }

      //硬件参数未经过二次封装,直接传入使用
      console.info(`TLQQ, 解析硬件测试操作参数: operationName=${payloadHw.operationName}, status=${payloadHw.status}`);
      await ProcessManager.hardwareTestProcess(workerPort, payloadHw);
      break;
    case 'startPumpCalibrate': //客户端触发测量控制指令执行
      console.info(`TLQQ, 启动定量泵自动校准`);
      await ProcessManager.autoPumpCalibrationTask(workerPort);
      break;
    case 'startADAdjust': //客户端触发测量控制指令执行
      console.info(`Worker received adadjust message: ${JSON.stringify(event.data)}`);

      // 2. 显式断言为已知接口，消除 any/unknown
      const messageAd = event.data as MaintenanceOperatorMessage;
      const payloadAd: MaintainOperationParams = messageAd.data;

      // 2. 安全校验（防止 UI 传参结构异常导致 Worker 崩溃）
      if (!payloadAd) {
        console.error(`Worker: Invalid adadjust payload: ${JSON.stringify(payloadAd)}`);
        break;
      }

      const newPayload : HardwareOperationParams = { operationName: 'None', status: payloadAd.params};

      console.info(`TLQQ, 解析AD调节操作参数: operationName=${newPayload.operationName}, status=${newPayload.status}`);
      await ProcessManager.autoADAdjustTask(workerPort, newPayload);
      break;
    case 'startCollectSample': //客户端触发测量控制指令执行
      console.info(`TLQQ, 采集水样`);
      await ProcessManager.collectSampleTask(workerPort);
      break;
    case 'measure_control': //客户端触发测量控制指令执行
      //await ProcessAll.testProcess(workerPort);
      break;
    case 'calculateProcess': // 定时任务调度
      calculateNext(event.data.data.times);
      break;
    case 'schedule': // 排期任务调度
      await ProcessManager.getInstance().runProcess();
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

/**
 * 计算下一次触发时间
 * @param times [0, 3, 1]不用排序
 */
function calculateNext(times: number[]) {
  if (!times) {
    console.log(`TLQQ, 未传递定时时间`);
    return;
  }

  if (!running) {
    console.log(`TLQQ, 调度已终止，不再安排下一次`);
    clearTimeout(timer);
    return;
  }

  const now = new Date(); // 获取当前时间
  const candidates: number[] = times.map(hour => {
    const t = new Date(
      now.getFullYear(),
      now.getMonth(),
      now.getDate(),
      hour,
      0,
      0,
      0
    );
    if (t.getTime() <= now.getTime()) {
      t.setDate(t.getDate() + 1);
    }
    return t.getTime();
  })
  const next = Math.min(...candidates);
  console.info(`TLQQ, 已启动定时，下一次运行时间 ${new Date(next)}`);
  timer = setTimeout(async () => {
    if (!running) return;  // 双重保险（防止刚好卡点）

    const label = new Date().toLocaleTimeString();
    console.info(`TLQQ, 定时任务触发`);
    workerPort.postMessage({ type: 'trigger', time: label }); // 告知定时任务触发

    // 需要触发的任务

    calculateNext(times);
  }, next - now.getTime())
}