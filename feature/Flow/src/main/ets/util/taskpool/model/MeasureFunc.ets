// 执行方法类，所有方法定义在此
import { thread, DateTimeUtil } from 'base';
import { hilog } from "@kit.PerformanceAnalysisKit";
import { MeasureFlow, MeasureType } from '../../../Flow/MeasureFlow';
import { TaskResultWrapper } from '../TaskpoolManager';

@Concurrent
export async function measure(type: MeasureType): Promise<TaskResultWrapper> {
  const startTime = DateTimeUtil.getTimestamp();
  const flow = new MeasureFlow('', type);
  flow.OnStart();
  flow.OnProcess();
  flow.OnStop();
  hilog.info(122, 'MeasureFlow', '操作时间 = %{public}d', DateTimeUtil.getTimestamp() - startTime);
  return {
    type: 'measure',
    data: flow.lastMeasureRecord
  };
}