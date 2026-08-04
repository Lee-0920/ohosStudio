// 执行方法类，所有方法定义在此
import { getLiquidType } from '../../../Setting/LiquidType';
import { thread, DateTimeUtil } from 'base';
import { hilog } from "@kit.PerformanceAnalysisKit";
import { CombinePipeOperationParams } from "../../../Setting/Setting";
import { CombineOperateFlow } from '../../../Flow/CombineOperateFlow';

@Concurrent
export async function combinePipeOperation(params: CombinePipeOperationParams): Promise<number> {
  const startTime = DateTimeUtil.getTimestamp();
  console.info(`TLQQ `, params.name, params.source, params.dest, params.volume);
  const source = getLiquidType(params.source);
  const dest = getLiquidType(params.dest);
  let mode: number = 0;

  if (source != undefined)
  {
    const flow = new CombineOperateFlow(params.name, source, dest, mode, params.volume, params.volume, params.name);
    flow.OnStart();
    flow.OnProcess();
    flow.OnStop();
  }
  hilog.info(122, 'CombinePipeOperationFunc', '组合操作时间 = %{public}d', DateTimeUtil.getTimestamp() - startTime);
  return 1;
}