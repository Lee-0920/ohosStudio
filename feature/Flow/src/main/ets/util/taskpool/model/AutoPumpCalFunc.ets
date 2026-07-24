// 执行方法类，所有方法定义在此
import { thread, DateTimeUtil } from 'base';
import { hilog } from "@kit.PerformanceAnalysisKit";
import { AutoPumpCheckFlow } from '../../../Flow/AutoPumpCheckFlow';

@Concurrent
export async function pumpCalibration(): Promise<number> {
  const startTime = DateTimeUtil.getTimestamp();
  const flow = new AutoPumpCheckFlow('');
  flow.OnStart();
  flow.OnProcess();
  flow.OnStop();
  hilog.info(122, 'CleanOperation', '清洗操作时间 = %{public}d', DateTimeUtil.getTimestamp() - startTime);
  return 1;
}