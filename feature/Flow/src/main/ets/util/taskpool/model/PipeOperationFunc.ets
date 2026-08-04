// 执行方法类，所有方法定义在此
import { liquidTypes, getLiquidType } from '../../../Setting/LiquidType';
import { thread, DateTimeUtil } from 'base';
import { hilog } from "@kit.PerformanceAnalysisKit";
import { PipeOperationParams } from "../../../Setting/Setting";
import { RollDirection } from 'communication';
import { LiquidOperateFlow } from '../../../Flow/LiquidOperateFlow';

@Concurrent
export async function pipeOperation(params: PipeOperationParams): Promise<number> {
  const startTime = DateTimeUtil.getTimestamp();
  console.info(`TLQQ `, params.name, params.liquidName, params.dir, params.mode, params.volume);
  const source = getLiquidType(params.liquidName);
  let suckType = liquidTypes.none;
  let destType = liquidTypes.none;
  let mode: number = 0;

  if(params.mode === '光学定量'){
    mode = 1;
  } else if (params.mode === '精确定量') {
    mode = 2;
  }

  console.log(source?.name);
  if (source != undefined)
  {
    if(params.dir == RollDirection.Suck)
    {
      suckType = source;
    }
    else
    {
      destType = source;
    }

    const flow = new LiquidOperateFlow(params.liquidName, suckType, destType, mode, params.volume, params.volume, params.name);
    flow.OnStart();
    flow.OnProcess();
    flow.OnStop();
  }
  hilog.info(122, 'PipeOperationFunc', '管道操作时间 = %{public}d', DateTimeUtil.getTimestamp() - startTime);
  return 1;
}