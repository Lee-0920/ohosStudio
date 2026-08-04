// 执行方法类，所有方法定义在此
import { thread, DateTimeUtil } from 'base';
import { hilog } from "@kit.PerformanceAnalysisKit";
import { AutoPumpCheckFlow } from '../../../Flow/AutoPumpCheckFlow';

@Concurrent
export async function pumpCalibration(): Promise<number> {
  const startTime = DateTimeUtil.getTimestamp();
  const flow = new AutoPumpCheckFlow('');
  try {
    flow.OnStart();
    flow.OnProcess();
  } finally {
    // 即使 OnProcess 抛出异常（如用户停止），也要执行 OnStop 进行结果记录与清理
    flow.OnStop();
  }
  hilog.info(122, 'CleanOperation', '定量泵校准操作时间 = %{public}d', DateTimeUtil.getTimestamp() - startTime);
  return 1;
}