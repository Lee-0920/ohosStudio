// 执行方法类，所有方法定义在此

import { taskpool } from '@kit.ArkTS';
import { Operator, WasteType } from '../../../Flow/Operator';
import { liquidTypes, getLiquidType } from '../../../Setting/LiquidType';
import { thread, DateTimeUtil } from 'base';
import { hilog } from "@kit.PerformanceAnalysisKit";
import { PipeOperationParams } from "../../../Setting/Setting";
import { MeterMode, RollDirection } from 'communication';

@Concurrent
export async function pipeOperation(params: PipeOperationParams): Promise<number> {
  const startTime = DateTimeUtil.getTimestamp();
  console.info(`TLQQ `, params.liquidName, params.dir, params.mode, params.volume);
  const source = getLiquidType(params.liquidName);

  console.log(source?.name);
  const op = Operator.getInstance();
  if (source != undefined)
  {
    if(params.dir == RollDirection.Suck)
    {
      if(params.mode == '精确定量'){
        console.debug('精确定量');
        op.Pump(source, params.volume , 0.2);
        // op.Meter(MeterMode.Accurate, source, params.volume, RollDirection.Suck);
      }else if (params.mode == '智能定量'){
        console.debug('光学定量');
        op.Pump(source, params.volume , 0.2);
        // op.Meter(MeterMode.Smart, source, params.volume, RollDirection.Suck);
      }else{
        console.debug('泵计步');
        op.Pump(source, params.volume , 0.2);
      }
    }
    else
    {
      op.Drain(source, params.volume , 0.2);
    }
  }
  hilog.info(122, 'PipeOperationFunc', '管道操作时间 = %{public}d', DateTimeUtil.getTimestamp() - startTime);
  return 1;
}