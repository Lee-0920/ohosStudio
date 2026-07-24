// 执行方法类，所有方法定义在此
import { thread, DateTimeUtil } from 'base';
import { hilog } from "@kit.PerformanceAnalysisKit";
import { ADAdjustFlow, ADAdjustType } from '../../../Flow/ADAdjustFlow';
import { HardwareOperationParams } from "../../../Setting/Setting";

@Concurrent
export async function adAdjust(params: HardwareOperationParams): Promise<number> {
  const startTime = DateTimeUtil.getTimestamp();
  console.info(`Worker adAdjust: ${JSON.stringify(params)}`);
  const adType = params.status as ADAdjustType;
  const flow = new ADAdjustFlow('', adType);
  flow.OnStart();
  flow.OnProcess();
  flow.OnStop();
  hilog.info(122, 'ADAdjust', '操作时间 = %{public}d', DateTimeUtil.getTimestamp() - startTime);
  return 1;
}