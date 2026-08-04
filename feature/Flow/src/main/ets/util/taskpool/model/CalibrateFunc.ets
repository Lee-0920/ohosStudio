// 执行方法类，所有方法定义在此
import { thread, DateTimeUtil } from 'base';
import { hilog } from "@kit.PerformanceAnalysisKit";
import { CalibrateFlow, CalibrateType } from '../../../Flow/CalibrateFlow';
import { TaskResultWrapper } from '../TaskpoolManager';

@Concurrent
export async function calibrate(type: CalibrateType): Promise<TaskResultWrapper> {
  const startTime = DateTimeUtil.getTimestamp();
  const flow = new CalibrateFlow('', type);
  flow.OnStart();
  flow.OnProcess();
  flow.OnStop();
  hilog.info(122, 'CalibrateFlow', '操作时间 = %{public}d', DateTimeUtil.getTimestamp() - startTime);
  return {
    type: 'calibrate',
    data: flow.lastCalibrateRecord
  };
}