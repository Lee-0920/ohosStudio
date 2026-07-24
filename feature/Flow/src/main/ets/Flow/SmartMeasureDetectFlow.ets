import { hilog } from "@kit.PerformanceAnalysisKit";
import { Flow } from './Flow';
import { DateTimeUtil } from 'base';
import { BaseController } from 'controllerplugin';
import { PT65DriveController } from "pt65drivecontrollerplugin";

export enum SmartMeasureDetectType {
  Measure,
}

export class SmartMeasureDetectFlow extends Flow {
  detectTime: number = DateTimeUtil.getTimestamp();

  constructor(name: string) {
    super(name);
    this.detectTime = DateTimeUtil.getTimestamp();
  }

  GetRuntime(): number {
    return 0;
  }

  OnStart(): void {
    hilog.info(122, 'SmartMeasureDetectFlow', 'OnStart');

    const controller = new BaseController();
    const deviceStatus = controller.GetIDeviceStatus();
    if (deviceStatus) {
      // deviceStatus.Initialize();
    }

    // op:CheckDigestSafety()

    // let runStatus = Helper.Status.SetStatus(setting.runStatus.smartDetect);
    // StatusManager.Instance().SetStatus(runStatus);
    // let runAction = Helper.Status.SetAction(setting.runAction.smartMeasureDetect);
    // StatusManager.Instance().SetAction(runAction);

    this.isUserStop = false;
  }

  OnProcess(): void {
    hilog.info(122, 'SmartMeasureDetectFlow', 'OnProcess Start');

    // let flowManager = FlowManager.Instance();
    // flowManager.UpdateFlowMessage(this.name, "诊断中...");
    // ModbusInterface.detectResult = setting.modbusCoder.detectResultID.detecting;

    let status = false;

    const detect = (): void => {
      // op:DrainToWaste(setting.liquid.meterPipeVolume);
      // op:DrainFromDigestionRoom();

      // const AD0 = op.StartAcquirerAD(setting.signal.readADTime);

      // const DC = new PT65DriveController();
      // DC.GetIOpticalAcquire().TurnOnLED();
      // if (!this.Wait(2)) {
      //   throw new Error("用户终止");
      // }

      // const AD1 = op.StartAcquirerAD(setting.signal.readADTime);
      // DC.GetIOpticalAcquire().TurnOffLED();

      // if ((AD1.GetMeasure() - AD0.GetMeasure()) > 20000) {
      //   status = true;
      // }
    };

    try {
      detect();
    } catch (err) {
      if (err instanceof Error) {
        if (err.message.includes("ExpectEventTimeoutException") ||
            err.message.includes("CommandTimeoutException")) {
          // ExceptionHandler.MakeAlarm(err);
        } else if (err.message.includes("PumpStoppedException") ||
                   err.message.includes("UserStopException") ||
                   err.message.includes("MeterStoppedException") ||
                   err.message.includes("AcquirerADStoppedException")) {
          this.isUserStop = true;
        } else if (err.message.includes("AcquirerADFailedException") ||
                   err.message.includes("PumpFailedException") ||
                   err.message.includes("MeterFailedException")) {
          // ExceptionHandler.MakeAlarm(err);
        } else {
          hilog.warn(122, 'SmartMeasureDetectFlow', 'OnProcess() => %{public}s', err.message);
        }
      }
    }
    status = true;  //todo 删除
    if (this.isUserStop) {
      this.result = "停止";
      // ModbusInterface.detectResult = setting.modbusCoder.detectResultID.stop;
    } else {
      if (status == true) {
        this.result = "通过";
        // ModbusInterface.detectResult = setting.modbusCoder.detectResultID.passed;
      } else {
        this.result = "未通过";
        // ModbusInterface.detectResult = setting.modbusCoder.detectResultID.fail;
      }
    }

    hilog.info(122, 'SmartMeasureDetectFlow', 'OnProcess End, result: %{public}s', this.result);
  }

  OnStop(): void {
    hilog.info(122, 'SmartMeasureDetectFlow', 'OnStop');

    const controller = new BaseController();
    const deviceStatus = controller.GetIDeviceStatus();
    if (deviceStatus) {
      // deviceStatus.Initialize();
    }

    hilog.info(122, 'SmartMeasureDetectFlow', '智能测量模块诊断结束');
    hilog.info(122, 'SmartMeasureDetectFlow', '诊断时间 = %{public}ds', DateTimeUtil.getTimestamp() - this.detectTime);
  }
}
