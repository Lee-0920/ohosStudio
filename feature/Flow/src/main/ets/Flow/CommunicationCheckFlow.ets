import { hilog } from "@kit.PerformanceAnalysisKit";
import { Flow } from './Flow';
import { PT65DriveController } from "pt65drivecontrollerplugin";

export enum CommunicationCheckType {
  DCCommunicationCheck,
}

export class CommunicationCheckFlow extends Flow {
  name: string = "";
  result: string = "";

  constructor(name: string, flowName: string = "CommunicationCheckFlow") {
    super(flowName);
    this.name = name;
    this.result = "";
  }

  GetRuntime(): number {
    return 0;
  }

  OnStart(): void {
    hilog.info(122, 'CommunicationCheckFlow', 'OnStart');

    // 设置运行状态
    // let runStatus = Helper.Status.SetStatus(setting.runStatus.communication);
    // StatusManager.Instance().SetStatus(runStatus);

    // 设置运行动作
    // if (this.name == "DCCommunicationCheck") {
    //   let runAction = Helper.Status.SetAction(setting.runAction.DCCommunication);
    //   StatusManager.Instance().SetAction(runAction);
    // }

    // 更新流程消息
    // let flowManager = FlowManager.Instance();
    // flowManager.UpdateFlowMessage(this.name, "测试中");

    // ModbusInterface.commTestResult = setting.modbusCoder.detectResultID.detecting;
  }

  OnProcess(): void {
    hilog.info(122, 'CommunicationCheckFlow', 'OnProcess Start');

    try {
      if (this.name == "DCCommunicationCheck") {
        const DC = new PT65DriveController();
        // DC.IsConnected();
      }

      this.result = "通过";
      // ModbusInterface.commTestResult = setting.modbusCoder.detectResultID.passed;
    } catch (err) {
      if (err instanceof Error) {
        if (err.message.includes("ExpectEventTimeoutException") ||
            err.message.includes("CommandTimeoutException")) {
          // ExceptionHandler.MakeAlarm(err);
        }
        hilog.warn(122, 'CommunicationCheckFlow', 'OnProcess()=>%{public}s', err.message);
      } else {
        hilog.warn(122, 'CommunicationCheckFlow', 'OnProcess()=>未知异常');
      }

      this.result = "未通过";
      // ModbusInterface.commTestResult = setting.modbusCoder.detectResultID.fail;
    }

    hilog.info(122, 'CommunicationCheckFlow', 'OnProcess End, result: %{public}s', this.result);
  }

  OnStop(): void {
    hilog.info(122, 'CommunicationCheckFlow', 'OnStop');
  }
}
