import { hilog } from "@kit.PerformanceAnalysisKit";
import { Flow } from './Flow';
import { DateTimeUtil } from 'base';
import { BaseController } from 'controllerplugin';
import { PT65DriveController } from "pt65drivecontrollerplugin";
import { liquidTypes, LiquidType } from '../Setting/LiquidType';

export enum SmartValveDetectType {
  SmartBlankValveDetect,
  SmartSampleValveDetect,
  SmartStandardValveDetect,
  SmartRangeCheckValveDetect,
  SmartReagent1ValveDetect,
  SmartReagent2ValveDetect,
  SmartReagent3ValveDetect,
  SmartDigestionRoomValveDetect,
  SmartWasteValveDetect,
}

export class SmartValveDetectFlow extends Flow {
  valveTarget: LiquidType = liquidTypes.none;
  action: string = '';
  detectTime: number = DateTimeUtil.getTimestamp();

  constructor(name: string, target?: LiquidType, act: string = '') {
    super(name);
    this.valveTarget = target ?? liquidTypes.none;
    this.action = act;
    this.detectTime = DateTimeUtil.getTimestamp();
  }

  GetRuntime(): number {
    return 0;
  }

  OnStart(): void {
    hilog.info(122, 'SmartValveDetectFlow', 'OnStart');

    const controller = new BaseController();
    const deviceStatus = controller.GetIDeviceStatus();
    if (deviceStatus) {
      // deviceStatus.Initialize();
    }

    // op:CheckDigestSafety()

    // let runStatus = Helper.Status.SetStatus(setting.runStatus.smartDetect);
    // StatusManager.Instance().SetStatus(runStatus);
    // let runAction = Helper.Status.SetAction(this.action);
    // StatusManager.Instance().SetAction(runAction);

    this.isUserStop = false;
  }

  OnProcess(): void {
    hilog.info(122, 'SmartValveDetectFlow', 'OnProcess Start');

    // let flowManager = FlowManager.Instance();
    // flowManager.UpdateFlowMessage(this.name, "诊断中...");
    // ModbusInterface.detectResult = setting.modbusCoder.detectResultID.detecting;

    let status = false;

    const detect = (): void => {
      // op:DrainToWaste(setting.liquid.meterPipeVolume);

      // if (this.valveTarget == liquidTypes.digestionRoom) {
      //   op:DrainFromDigestionRoom();

      //   const DC = new PT65DriveController();
      //   DC.GetIOpticalAcquire().TurnOnLED();
      //   if (!this.Wait(2)) {
      //     throw new Error("用户终止");
      //   }
      //   const AD0 = op.StartAcquirerAD(2);
      //   DC.GetIOpticalAcquire().TurnOffLED();

      //   op.PumpToDigestionRoom(liquidTypes.blank, 4);
      //   op.SecludeLiquid(liquidTypes.blank);

      //   DC.GetIOpticalAcquire().TurnOnLED();
      //   if (!this.Wait(2)) {
      //     throw new Error("用户终止");
      //   }
      //   const AD1 = op.StartAcquirerAD(2);
      //   DC.GetIOpticalAcquire().TurnOffLED();

      //   if (AD1.GetMeasure() - AD0.GetMeasure() > 1000) {
      //     status = true;
      //   }
      // } else if (this.valveTarget == liquidTypes.waste) {
      //   const maxMP = config.hardwareConfig.meterPoint.point[config.hardwareConfig.meterPoint.num].setVolume;
      //   op.SetMeterOverValue(MeterMode.Smart, 0);
      //   op.Meter(MeterMode.Smart, liquidTypes.blank, maxMP, RollDirection.Suck);
      //   op.DrainToWaste(0);
      //   op.SetMeterOverValue(MeterMode.Smart, 0);
      //   op.Meter(MeterMode.Smart, liquidTypes.blank, maxMP, RollDirection.Suck);
      //   op.DrainToWaste(maxMP);
      //   status = true;
      // } else if (this.valveTarget == liquidTypes.wasteWater) {
      //   const maxMP = config.hardwareConfig.meterPoint.point[config.hardwareConfig.meterPoint.num].setVolume;
      //   op.SetMeterOverValue(MeterMode.Smart, 0);
      //   op.Meter(MeterMode.Smart, liquidTypes.blank, maxMP, RollDirection.Suck);
      //   op.DrainToWaste(0, WasteType.WasteWater);
      //   op.SetMeterOverValue(MeterMode.Smart, 0);
      //   op.Meter(MeterMode.Smart, liquidTypes.blank, maxMP, RollDirection.Suck);
      //   op.DrainToWaste(0, WasteType.WasteWater);
      //   status = true;
      // } else {
      //   const MP0 = config.hardwareConfig.meterPoint.point[1].setVolume;
      //   op.SetMeterOverValue(MeterMode.Smart, 0);
      //   op.Meter(MeterMode.Smart, this.valveTarget, MP0, RollDirection.Suck);
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
                   err.message.includes("MeterStoppedException") ||
                   err.message.includes("UserStopException") ||
                   err.message.includes("AcquirerADStoppedException")) {
          this.isUserStop = true;
        } else if (err.message.includes("AcquirerADFailedException") ||
                   err.message.includes("PumpFailedException") ||
                   err.message.includes("MeterFailedException") ||
                   err.message.includes("MeterUnfinishedException") ||
                   err.message.includes("MeterExpectTimeoutException")) {
          // ExceptionHandler.MakeAlarm(err);
        } else {
          hilog.warn(122, 'SmartValveDetectFlow', 'OnProcess() => %{public}s', err.message);
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

      // if (this.valveTarget == liquidTypes.digestionRoom) {
      //   op.DrainFromDigestionRoom();
      // } else if (this.valveTarget == liquidTypes.waste) {
      //   op.DrainToWaste(setting.liquid.meterPipeVolume);
      // } else if (this.valveTarget == liquidTypes.wasteWater) {
      //   op.DrainToWasteWater(setting.liquid.meterPipeVolume);
      // } else {
      //   op.DrainToWaste(setting.liquid.meterPipeVolume);
      //   op.SecludeLiquid(this.valveTarget);
      // }
    }

    hilog.info(122, 'SmartValveDetectFlow', 'OnProcess End, result: %{public}s', this.result);
  }

  OnStop(): void {
    hilog.info(122, 'SmartValveDetectFlow', 'OnStop');

    const controller = new BaseController();
    const deviceStatus = controller.GetIDeviceStatus();
    if (deviceStatus) {
      // deviceStatus.Initialize();
    }

    // ReagentRemainManager.SaveRemainStatus();

    hilog.info(122, 'SmartValveDetectFlow', '智能阀诊断结束');
    hilog.info(122, 'SmartValveDetectFlow', '诊断时间 = %{public}ds', DateTimeUtil.getTimestamp() - this.detectTime);
  }
}
