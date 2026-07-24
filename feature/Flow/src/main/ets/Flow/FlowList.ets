import { hilog } from '@kit.PerformanceAnalysisKit';
import { Flow } from './Flow';
import { emitter } from '@kit.BasicServicesKit';
import { MeasureData } from '../DataManager/DataBase';
import { MeasureFlow } from './MeasureFlow';



export class FlowList {
  list: Flow[] = [];
  // 最近一次测量流程生成的记录，供 taskpool 返回给 worker 后再抛回主线程入库
  lastMeasureRecord: MeasureData | null = null;
  private static instance: FlowList = new FlowList();

  public static GetInstance(): FlowList{
    return FlowList.instance;
  }

  AddFlow(flow: Flow): void {
    hilog.info(121,'flow', `添加流程%{public}s`, flow.name);
    this.list.push(flow);
  }

  ClearList(): void {
    this.list = [];
    // 可选：globalThis.collectgarbage && globalThis.collectgarbage('collect');
  }

  GetFlowListSize(): number{
    let size = 0;
    for (let _ of this.list) {
      size++;
    }
    return size;
  }

  StopAllFlow(): void {

    for (const flow of this.list) {
      flow.Stop();
    }
    this.ClearList();
  }

  RemoveFlow(flowName: string): void {

    this.list = this.list.filter((flow) => {
      if (flow.name !== flowName) {
        return true;
      }
      if (flow.isStarted) {
        flow.Stop();
        return true;
      }
      return false;
    });
  }

  emitterStatus(flowName:string, RunTime:number, isRun:boolean){
    let eventData: emitter.EventData = {
      data: {
        name: flowName,
        time: RunTime,
        isRunning: isRun,
      }
    };
    emitter.emit("FlowStatus", eventData);
  }

  RunAllFlow(): void {

    hilog.info(121,'flow', 'flow begin');

    try {
      hilog.info(121,'flow', `流程数量%{public}d`, this.GetFlowListSize());
      for (const flow of this.list) {
        if (!flow) {
          hilog.info(121,'flow', `FlowList is null`);
          continue;
        }

        const name = flow.name;
        if (name === 'collectSample' || name === 'DCCommunicationCheck') {
          this.emitterStatus(flow.name, flow.GetRuntime(), true);
          const runResult = flow.Run();
          const flowName = runResult[0];
          const result = runResult[1];
          if (flow instanceof MeasureFlow && flow.lastMeasureRecord) {
            this.lastMeasureRecord = flow.lastMeasureRecord;
          }
          this.emitterStatus(flow.name, 0, false);

          hilog.info(121,'flow', `运行流:${flowName}结果: ${result}`);
        } else {
          //发送emitter信号通通知，流程开始运行
          this.emitterStatus(flow.name, flow.GetRuntime(), true);
          const runResult = flow.Run();
          const flowName = runResult[0];
          const result = runResult[1];
          if (flow instanceof MeasureFlow && flow.lastMeasureRecord) {
            this.lastMeasureRecord = flow.lastMeasureRecord;
          }
          //发送emitter信号通通知，流程结束
          this.emitterStatus(flow.name, 0, false);

          hilog.info(121,'flow', `运行流:${flowName}结果:${result}`);
        }
      }

    } catch (err) {
      if (err instanceof Error) {
        hilog.info(121,'flow', 'FlowList.RunAllFlow() => %{public}s', err.message);
      } else {
        hilog.info(121,'flow', 'FlowList.RunAllFlow() => %{public}s', err);
      }
    }

    this.ClearList();
    hilog.info(121,'flow', 'flow end');
  }
}