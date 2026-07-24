// 执行方法类，所有方法定义在此
import { thread, DateTimeUtil } from 'base';
import { hilog } from "@kit.PerformanceAnalysisKit";
import { CollectSampleFlow } from '../../../Flow/CollectSampleFlow';

@Concurrent
export async function collectSample(): Promise<number> {
  const startTime = DateTimeUtil.getTimestamp();
  const flow = new CollectSampleFlow('');
  flow.OnStart();
  flow.OnProcess();
  flow.OnStop();
  hilog.info(122, 'CollectSampleFlow', '操作时间 = %{public}d', DateTimeUtil.getTimestamp() - startTime);
  return 1;
}