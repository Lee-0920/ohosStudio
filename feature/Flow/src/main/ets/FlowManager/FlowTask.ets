import { taskpool, worker } from '@kit.ArkTS';
import { BusinessError, emitter } from '@kit.BasicServicesKit';
import {
  FlowList, FlowType,
  ADAdjustType, ADAdjustFlow,
  AutoPumpCheckType, AutoPumpCheckFlow,
  CalibrateType, CalibrateFlow,
  CleanType, CleanFlow,
  CollectSampleType, CollectSampleFlow,
  CombineOperateType, CombineOperateFlow,
  CommunicationCheckType, CommunicationCheckFlow,
  LiquidOperateType, LiquidOperateFlow,
  MeasureType, MeasureFlow,
  SmartCoolDetectType, SmartCoolDetectFlow,
  SmartHeatDetectType, SmartHeatDetectFlow,
  SmartMeasureDetectType, SmartMeasureDetectFlow,
  SmartMeterDetectType, SmartMeterDetectFlow,
  SmartValveDetectType, SmartValveDetectFlow,
} from '../Flow/FlowInterface';

import { DatabaseManager, MeasureData } from '../DataManager/DataBase';


@Concurrent
async function CreatFlowTask(name:string, type:FlowType, FlowNum:number, UIContext:Context): Promise<MeasureData | null> {
  // 初始化数据库 用于taskpool线程的流程参数，上下文为UIContext
  // 任务开始前先同步数据库
  await DatabaseManager.getInstance().initialize(UIContext);
  await DatabaseManager.getInstance().getAll();

  switch (type) {
    case FlowType.Measure: {
      let flow = new MeasureFlow(name, FlowNum);
      FlowList.GetInstance().AddFlow(flow);
      FlowList.GetInstance().RunAllFlow();
      break;
    }
    case FlowType.Calibrate: {
      let flow = new CalibrateFlow(name, FlowNum);
      FlowList.GetInstance().AddFlow(flow);
      FlowList.GetInstance().RunAllFlow();
      break;
    }
    case FlowType.Clean: {
      let flow = new CleanFlow(name,FlowNum);
      FlowList.GetInstance().AddFlow(flow);
      FlowList.GetInstance().RunAllFlow();
      break;
    }
    case FlowType.ADAdjust: {
      let flow = new ADAdjustFlow(name,FlowNum);
      FlowList.GetInstance().AddFlow(flow);
      FlowList.GetInstance().RunAllFlow();
      break;
    }
    case FlowType.AutoPumpCheck: {
      let flow = new AutoPumpCheckFlow(name);
      FlowList.GetInstance().AddFlow(flow);
      FlowList.GetInstance().RunAllFlow();
      break;
    }
    case FlowType.CollectSample: {
      let flow = new CollectSampleFlow(name);
      FlowList.GetInstance().AddFlow(flow);
      FlowList.GetInstance().RunAllFlow();
      break;
    }
    case FlowType.CombineOperate: {
      let flow = new CombineOperateFlow(name); //TODO 参数不完全 流程较短也可尝试使用异步
      FlowList.GetInstance().AddFlow(flow);
      FlowList.GetInstance().RunAllFlow();
      break;
    }
    case FlowType.CommunicationCheck: {
      let flow = new CommunicationCheckFlow(name);
      FlowList.GetInstance().AddFlow(flow);
      FlowList.GetInstance().RunAllFlow();
      break;
    }
    case FlowType.LiquidOperate: {
      let flow = new LiquidOperateFlow(name); //TODO 参数不完全 流程较短也可尝试使用异步
      FlowList.GetInstance().AddFlow(flow);
      FlowList.GetInstance().RunAllFlow();
      break;
    }
    case FlowType.SmartCoolDetect: {
      let flow = new SmartCoolDetectFlow(name);
      FlowList.GetInstance().AddFlow(flow);
      FlowList.GetInstance().RunAllFlow();
      break;
    }
    case FlowType.SmartHeatDetect: {
      let flow = new SmartHeatDetectFlow(name);
      FlowList.GetInstance().AddFlow(flow);
      FlowList.GetInstance().RunAllFlow();
      break;
    }
    case FlowType.SmartMeasureDetect: {
      let flow = new SmartMeasureDetectFlow(name);
      FlowList.GetInstance().AddFlow(flow);
      FlowList.GetInstance().RunAllFlow();
      break;
    }
    case FlowType.SmartMeterDetect:{
      let flow = new SmartMeterDetectFlow(name);
      FlowList.GetInstance().AddFlow(flow);
      FlowList.GetInstance().RunAllFlow();
      break;
    }
    case FlowType.SmartValveDetect:{
      let flow = new SmartValveDetectFlow(name); //TODO 参数不完全 流程较短也可尝试使用异步
      FlowList.GetInstance().AddFlow(flow);
      FlowList.GetInstance().RunAllFlow();
      break;
    }
  }
  return FlowList.GetInstance().lastMeasureRecord;
}


export class FlowTask{
  private static instance: FlowTask = new FlowTask();

  public static GetInstance(): FlowTask{
    return FlowTask.instance;
  }

  private FlowIn: taskpool.LongTask | null = null;

  runFlow(name:string, type:FlowType, FlowNum:number, UIContext:Context){

    this.FlowIn = new taskpool.LongTask(CreatFlowTask, name, type, FlowNum, UIContext);
    taskpool.execute(this.FlowIn).then((value: object) => {
      console.info('execute group success');
      const record = value as MeasureData | null;
      if (record) {
        worker.workerPort.postMessage({
          status: 'complete',
          type: 'measureComplete',
          data: record
        });
      }
    }).catch((e: BusinessError) => {
      console.error(`execute group error: ${e.message}`);
    })
  }

  stopFlow(){
    if (this.FlowIn) {
      try {
        taskpool.cancel(this.FlowIn);
      } catch (err) {
        console.error("Failed to cancel task:", err);
      } finally {
        this.FlowIn = null;
      }
    }
  }

}


