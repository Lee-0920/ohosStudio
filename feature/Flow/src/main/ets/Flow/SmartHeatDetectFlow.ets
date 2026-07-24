import { hilog } from "@kit.PerformanceAnalysisKit";
import { Flow } from './Flow';
import { DateTimeUtil } from 'base';
import { BaseController } from 'controllerplugin';
import { PT65DriveController } from "pt65drivecontrollerplugin";

export enum SmartHeatDetectType {
  Cool,
  Heat,
}

export class SmartHeatDetectFlow extends Flow {
  detectTime: number = DateTimeUtil.getTimestamp();

  constructor(name: string) {
    super(name);
    this.detectTime = DateTimeUtil.getTimestamp();
  }

  GetRuntime(): number {
    return 0;
  }

  OnStart(): void {
    hilog.info(122, 'SmartHeatDetectFlow', 'OnStart');

    const controller = new BaseController();
    const deviceStatus = controller.GetIDeviceStatus();
    if (deviceStatus) {
      // deviceStatus.Initialize();
    }

    // op:CheckDigestSafety()

    // let runStatus = Helper.Status.SetStatus(setting.runStatus.smartDetect);
    // StatusManager.Instance().SetStatus(runStatus);
    // let runAction = Helper.Status.SetAction(setting.runAction.smartHeatDetect);
    // StatusManager.Instance().SetAction(runAction);

    this.isUserStop = false;
  }

  OnProcess(): void {
    hilog.info(122, 'SmartHeatDetectFlow', 'OnProcess Start');

    // let flowManager = FlowManager.Instance();
    // flowManager.UpdateFlowMessage(this.name, "诊断中...");
    // ModbusInterface.detectResult = setting.modbusCoder.detectResultID.detecting;

    let status = false;

    const detect = (): void => {
      // const DC = new PT65DriveController();
      // const thermostatTemp = DC.GetCurrentTemperature().GetThermostatTemp();
      // const targetTemp = thermostatTemp + setting.temperature.smartHeatDetectTemp;

      // if (80 - targetTemp > 0.01) {
      //   op:StartThermostat(ThermostatMode.Auto, targetTemp, 1, setting.temperature.smartHeatDetectTime);
      //   op:StopThermostat();

      //   if (!this.Wait(2)) {
      //     throw new Error("用户终止");
      //   }

      //   const temp = DC.GetCurrentTemperature().GetThermostatTemp() - targetTemp;
      //   if (temp > -1) {
      //     status = true;
      //   }
      // }
    };

    try {
      detect();
    } catch (err) {
      if (err instanceof Error) {
        if (err.message.includes("ExpectEventTimeoutException") ||
            err.message.includes("CommandTimeoutException")) {
          // ExceptionHandler.MakeAlarm(err);
        } else if (err.message.includes("ThermostatStoppedException") ||
                   err.message.includes("UserStopException")) {
          this.isUserStop = true;
        } else if (err.message.includes("ThermostatFailedException") ||
                   err.message.includes("ThermostatTimeoutException")) {
          // ExceptionHandler.MakeAlarm(err);
        } else {
          hilog.warn(122, 'SmartHeatDetectFlow', 'OnProcess() => %{public}s', err.message);
        }
      }
    }

    // const DC = new PT65DriveController();
    // if (DC.GetITemperatureControl().GetThermostatStatus() == 2) {
    //   op:StopThermostat();
    // }
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

    hilog.info(122, 'SmartHeatDetectFlow', 'OnProcess End, result: %{public}s', this.result);
  }

  OnStop(): void {
    hilog.info(122, 'SmartHeatDetectFlow', 'OnStop');

    const controller = new BaseController();
    const deviceStatus = controller.GetIDeviceStatus();
    if (deviceStatus) {
      // deviceStatus.Initialize();
    }

    // op:CheckDigestSafety()

    hilog.info(122, 'SmartHeatDetectFlow', '智能加热模块诊断结束');
    hilog.info(122, 'SmartHeatDetectFlow', '诊断时间 = %{public}ds', DateTimeUtil.getTimestamp() - this.detectTime);
  }
}
