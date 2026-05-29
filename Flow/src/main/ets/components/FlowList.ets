import { hilog } from '@kit.PerformanceAnalysisKit';
import { Flow } from './Flow';


export class FlowList {
  static list: Flow[] = [];

  static AddFlow(flow: Flow): void {
    FlowList.list.push(flow);
  }

  static ClearList(): void {
    FlowList.list = [];
    // 可选：globalThis.collectgarbage && globalThis.collectgarbage('collect');
  }

  static StopAllFlow(): void {

    for (const flow of FlowList.list) {
      flow.Stop();
    }
  }

  static RemoveFlow(flowname: string): void {

    FlowList.list = FlowList.list.filter((flow) => {
      if (flow.name !== flowname) {
        return true;
      }
      if (flow.isStarted) {
        flow.Stop();
        return true;
      }
      return false;
    });
  }

  static RunAllFlow(): void {

    hilog.info(121,'flow', 'flow begin');

    try {
      for (const flow of FlowList.list) {
        if (!flow) {
          continue;
        }

        const name = flow.name;
        if (name === 'collectSample' || name === 'DCCommunicationCheck') {
          const runResult = flow.Run();
          const flowName = runResult[0];
          const result = runResult[1];
          hilog.info(121,'flow', `运行流:${flowName}结果: ${result}`);
        } else {
          const runResult = flow.Run();
          const flowName = runResult[0];
          const result = runResult[1];
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

    FlowList.ClearList();
    hilog.info(121,'flow', 'flow end');
  }
}