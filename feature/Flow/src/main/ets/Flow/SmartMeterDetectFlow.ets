import { hilog } from "@kit.PerformanceAnalysisKit";
import { Flow } from './Flow';
import { DateTimeUtil } from 'base';
import { BaseController } from 'controllerplugin';
import { liquidTypes } from '../Setting/LiquidType';

export enum SmartMeterDetectType {
  meter,
}

export class SmartMeterDetectFlow extends Flow {
  detectTime: number = DateTimeUtil.getTimestamp();

  constructor(name: string) {
    super(name);
    this.detectTime = DateTimeUtil.getTimestamp();
  }

  GetRuntime(): number {
    return 0;
  }

  OnStart(): void {
    hilog.info(122, 'SmartMeterDetectFlow', 'OnStart');

    const controller = new BaseController();
    const deviceStatus = controller.GetIDeviceStatus();
    if (deviceStatus) {
      // deviceStatus.Initialize();
    }

    // let runStatus = Helper.Status.SetStatus(setting.runStatus.smartDetect);
    // StatusManager.Instance().SetStatus(runStatus);
    // let runAction = Helper.Status.SetAction(setting.runAction.smartMeterDetect);
    // StatusManager.Instance().SetAction(runAction);

    this.isUserStop = false;
  }

  OnProcess(): void {
    hilog.info(122, 'SmartMeterDetectFlow', 'OnProcess Start');

    // let flowManager = FlowManager.Instance();
    // flowManager.UpdateFlowMessage(this.name, "诊断中...");
    // ModbusInterface.detectResult = setting.modbusCoder.detectResultID.detecting;

    let status = false;

    const detect = (): void => {
      // op:DrainToWaste(setting.liquid.meterPipeVolume);

      // const meterReTry = setting.liquid.meterFailedReTry;
      // const pointNum = config.hardwareConfig.meterPoint.num;

      // op.SetMeterOverValue(MeterMode.Accurate, setting.liquid.accurateMeterOverValue);

      // for (let i = 1; i <= pointNum; i++) {
      //   const vol = config.hardwareConfig.meterPoint.point[i].setVolume;
      //   for (let repeatCount = 1; repeatCount <= meterReTry; repeatCount++) {
      //     try {
      //       op.Meter(MeterMode.Accurate, liquidTypes.blank, vol, RollDirection.Suck);
      //       break;
      //     } catch (err) {
      //       if (err instanceof Error) {
      //         if (err.message.includes("MeterFailedException") ||
      //             err.message.includes("MeterOverflowException") ||
      //             err.message.includes("MeterUnfinishedException") ||
      //             err.message.includes("MeterAirBubbleException") ||
      //             err.message.includes("MeterExpectTimeoutException")) {
      //           // ExceptionHandler.MakeAlarm(err);
      //         } else {
      //           throw err;
      //         }
      //       }
      //     }
      //     if (repeatCount >= meterReTry) {
      //       throw new Error("MeterFailedException");
      //     }
      //     // op.DrainToWaste(vol, WasteType.WasteWater);
      //   }
      // }

      status = true;
    };

    try {
      detect();
    } catch (err) {
      if (err instanceof Error) {
        if (err.message.includes("ExpectEventTimeoutException") ||
            err.message.includes("CommandTimeoutException")) {
          // ExceptionHandler.MakeAlarm(err);
        } else if (err.message.includes("PumpStoppedException") ||
                   err.message.includes("MeterStoppedException") ||
                   err.message.includes("UserStopException")) {
          this.isUserStop = true;
        } else if (err.message.includes("PumpFailedException")) {
          // ExceptionHandler.MakeAlarm(err);
        } else {
          hilog.warn(122, 'SmartMeterDetectFlow', 'OnProcess() => %{public}s', err.message);
        }
      }
    }
    status = true;   //todo 删除
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

      // op:DrainToWaste(setting.liquid.meterPipeVolume, WasteType.WasteWater);
      // op.SecludeLiquid(liquidTypes.blank);
    }

    hilog.info(122, 'SmartMeterDetectFlow', 'OnProcess End, result: %{public}s', this.result);
  }

  OnStop(): void {
    hilog.info(122, 'SmartMeterDetectFlow', 'OnStop');

    const controller = new BaseController();
    const deviceStatus = controller.GetIDeviceStatus();
    if (deviceStatus) {
      // deviceStatus.Initialize();
    }

    // ReagentRemainManager.SaveRemainStatus();

    hilog.info(122, 'SmartMeterDetectFlow', '智能定量模块诊断结束');
    hilog.info(122, 'SmartMeterDetectFlow', '定量模块诊断时间 = %{public}ds', DateTimeUtil.getTimestamp() - this.detectTime);
  }
}
