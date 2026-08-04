import { worker, MessageEvents, ErrorEvent } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Operator } from '../Flow/Operator';
import { MessageStopEvent } from '../util/taskpool/TaskpoolManager';

const TAG = 'HardwareStopWorker';
const DOMAIN = 122;

// Worker 入口：监听来自主线程/管理Worker的消息
worker.workerPort.onmessage = (e: MessageEvents) => {
  const msg = e.data as MessageStopEvent;

  if (msg.type === 'HARDWARE_STOP') {
    hilog.info(DOMAIN, TAG, '收到硬件停止指令，开始执行...');
    try {
      // 在这里同步阻塞是完全安全的
      // 该 Worker 不做任何其他事，不会触发5秒看门狗
      Operator.getInstance().Stop();

      hilog.info(DOMAIN, TAG, '硬件停止完成');
      worker.workerPort.postMessage({ type: 'HARDWARE_STOP_DONE' });
    } catch (err) {
      const errMsg = (err as Error)?.message ?? 'Unknown error';
      hilog.error(DOMAIN, TAG, '硬件停止失败: %{public}s', errMsg);
      worker.workerPort.postMessage({
        type: 'HARDWARE_STOP_ERROR',
        error: errMsg
      });
    }
  }
};

// Worker 错误兜底
worker.workerPort.onerror = (e: ErrorEvent) => {
  hilog.error(DOMAIN, TAG, 'Worker异常: %{public}s', e.message);
};