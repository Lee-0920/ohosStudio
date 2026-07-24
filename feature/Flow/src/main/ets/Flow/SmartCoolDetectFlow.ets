import { hilog } from "@kit.PerformanceAnalysisKit";
import { Flow } from './Flow';
import { DateTimeUtil } from 'base';
import { BaseController } from 'controllerplugin';
import { PT65DriveController } from "pt65drivecontrollerplugin";

export enum SmartCoolDetectType {
  Cool,
  Heat,
}

export class SmartCoolDetectFlow extends Flow {
  detectTime: number = DateTimeUtil.getTimestamp();

  constructor(name: string) {
    super(name);
    this.detectTime = DateTimeUtil.getTimestamp();
  }

  GetRuntime(): number {
    return 0;
  }

  OnStart(): void {
    hilog.info(122, 'SmartCoolDetectFlow', 'OnStart');

    // 初始化下位机
    const controller = new BaseController();
    const deviceStatus = controller.GetIDeviceStatus();
    if (deviceStatus) {
      // deviceStatus.Initialize();
    }

    // 检测消解室是否为安全温度
    // op:CheckDigestSafety()

    // 更新状态
    // let runStatus = Helper.Status.SetStatus(setting.runStatus.smartDetect);
    // StatusManager.Instance().SetStatus(runStatus);

    // 更新动作
    // let runAction = Helper.Status.SetAction(setting.runAction.smartCoolDetect);
    // StatusManager.Instance().SetAction(runAction);

    this.isUserStop = false;
  }

  OnProcess(): void {
    hilog.info(122, 'SmartCoolDetectFlow', 'OnProcess Start');

    // 更新流程消息
    // let flowManager = FlowManager.Instance();
    // flowManager.UpdateFlowMessage(this.name, "诊断中...");

    // ModbusInterface.detectResult = setting.modbusCoder.detectResultID.detecting;

    let status = false;

    // 诊断流程
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
      //     op:StartThermostat(ThermostatMode.Refrigerate, thermostatTemp, 1, setting.temperature.smartHeatDetectTime * 2);
      //     op:StopThermostat();
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
          hilog.warn(122, 'SmartCoolDetectFlow', 'OnProcess() => %{public}s', err.message);
        }
      }
    }

    // 获取恒温器状态
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

    hilog.info(122, 'SmartCoolDetectFlow', 'OnProcess End, result: %{public}s', this.result);
  }

  OnStop(): void {
    hilog.info(122, 'SmartCoolDetectFlow', 'OnStop');

    // 初始化下位机
    const controller = new BaseController();
    const deviceStatus = controller.GetIDeviceStatus();
    if (deviceStatus) {
      // deviceStatus.Initialize();
    }

    // 检测消解室是否为安全温度
    // op:CheckDigestSafety()

    hilog.info(122, 'SmartCoolDetectFlow', '智能冷却模块诊断结束');
    hilog.info(122, 'SmartCoolDetectFlow', '诊断时间 = %{public}ds', DateTimeUtil.getTimestamp() - this.detectTime);
  }
}
