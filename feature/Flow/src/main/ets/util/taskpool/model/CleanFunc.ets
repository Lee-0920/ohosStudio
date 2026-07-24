// 执行方法类，所有方法定义在此
import { thread, DateTimeUtil } from 'base';
import { hilog } from "@kit.PerformanceAnalysisKit";
import { CleanType } from '../../../../../../Index';
import { CleanFlow } from '../../../Flow/CleanFlow';

@Concurrent
export async function cleanOperation(params: CleanType): Promise<number> {
  const startTime = DateTimeUtil.getTimestamp();
  const cleanFlow = new CleanFlow('', params);
  cleanFlow.OnStart();
  cleanFlow.OnProcess();
  cleanFlow.OnStop();
  hilog.info(122, 'CleanOperation', '清洗操作时间 = %{public}d', DateTimeUtil.getTimestamp() - startTime);
  return 1;
}