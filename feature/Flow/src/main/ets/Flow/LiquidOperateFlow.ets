import { hilog } from "@kit.PerformanceAnalysisKit";
import { Flow } from './Flow';
import { DateTimeUtil } from 'base';
import { BaseController } from 'controllerplugin';
import { PT65DriveController } from "pt65drivecontrollerplugin";
import { liquidTypes, LiquidType } from '../Setting/LiquidType';

export enum LiquidOperateType {
  SuckFromSample,
  SuckFromStandard,
  SuckFromBlank,
  SuckFromRangeCheck,
  SuckFromReagent1,
  SuckFromReagent2,
  SuckFromReagent3,
  SuckFromDigestionRoom,
  DrainToWaste,
  DrainToDigestionRoom,
  DrainToSample,
  DrainToStandard,
  DrainToBlank,
  DrainToRangeCheck,
  DrainToReagent1,
  DrainToReagent2,
  DrainToReagent3,
}

export class LiquidOperateFlow extends Flow {
  source: LiquidType = liquidTypes.none;
  dest: LiquidType = liquidTypes.none;
  mode: number = 0;
  sVolume: number = 0;
  dVolume: number = 0;
  action: string = '';
  dateTime: number = DateTimeUtil.getTimestamp();

  constructor(name: string, source?: LiquidType, dest?: LiquidType, mode: number = 0, sVol: number = 0, dVol: number = 0, action: string = '') {
    super(name);
    this.source = source ?? liquidTypes.none;
    this.dest = dest ?? liquidTypes.none;
    this.mode = mode;
    this.sVolume = sVol;
    this.dVolume = dVol;
    this.action = action;
  }

  GetRuntime(): number {
    return 0;
  }

  OnStart(): void {
    hilog.info(122, 'LiquidOperateFlow', 'OnStart');

    // 初始化下位机
    const controller = new BaseController();
    const deviceStatus = controller.GetIDeviceStatus();
    if (deviceStatus) {
      // deviceStatus.Initialize();
    }

    // 检测消解室是否为安全温度
    // op:CheckDigestSafety()
  }

  OnProcess(): void {
    hilog.info(122, 'LiquidOperateFlow', 'OnProcess Start');

    this.isUserStop = false;
    this.isFinish = false;
    this.dateTime = DateTimeUtil.getTimestamp();

    try {
      // 设置运行状态
      // let runStatus = Helper.Status.SetStatus(setting.runStatus.liquidOperate);
      // StatusManager.Instance().SetStatus(runStatus);

      // 设置运行动作
      // let runAction = Helper.Status.SetAction(this.action);
      // StatusManager.Instance().SetAction(runAction);

      if (this.source != liquidTypes.none) {
        const DC = new PT65DriveController();
        // const factor = DC.GetIPeristalticPump().GetPumpFactor(0);

        if (this.source == liquidTypes.reagent2) {
          // DC.GetIOpticalMeter().SetMeteSpeed(setting.liquid.slowMeterSpeed * factor);
        } else {
          // DC.GetIOpticalMeter().SetMeteSpeed(setting.liquid.meterSpeed * factor);
        }

        switch (this.mode) {
          case 0:
            // op:Pump(this.source, this.sVolume, 0.2);
            break;
          case 1:
            // op:SetMeterOverValue(MeterMode.Smart, 0);
            // op:Meter(MeterMode.Smart, this.source, this.sVolume, RollDirection.Suck);
            break;
          case 2:
            // op:SetMeterOverValue(MeterMode.Accurate, setting.liquid.accurateMeterOverValue);
            // 根据定量点选择LED检测方向
            // if (this.sVolume == config.hardwareConfig.meterPoint.point[1].setVolume) {
            //   DC.GetIOpticalMeter().TurnOnLED(1);
            //   App.Sleep(200);
            //   const meterLed1AD = DC.GetIOpticalMeter().GetSingleOpticalAD(1);
            //   DC.GetIOpticalMeter().TurnOffLED(1);
            //   App.Sleep(200);
            //   if (meterLed1AD > 1000) {
            //     op:Meter(MeterMode.Accurate, this.source, this.sVolume, RollDirection.Suck);
            //   } else {
            //     op:Meter(MeterMode.Accurate, this.source, this.sVolume, RollDirection.Drain);
            //   }
            // } else {
            //   DC.GetIOpticalMeter().TurnOnLED(2);
            //   App.Sleep(200);
            //   const meterLed2AD = DC.GetIOpticalMeter().GetSingleOpticalAD(2);
            //   DC.GetIOpticalMeter().TurnOffLED(2);
            //   App.Sleep(200);
            //   if (meterLed2AD > 1000) {
            //     op:Meter(MeterMode.Accurate, this.source, this.sVolume, RollDirection.Suck);
            //   } else {
            //     op:Meter(MeterMode.Accurate, this.source, this.sVolume, RollDirection.Drain);
            //   }
            // }
            break;
          default:
            // op:Pump(this.source, this.sVolume, 0.2);
            break;
        }
      }

      if (this.dest != liquidTypes.none) {
        // op:Drain(this.dest, this.dVolume, 0.2);
      }

    } catch (err) {
      if (err instanceof Error) {
        if (err.message.includes("PumpStoppedException") ||
            err.message.includes("MeterStoppedException")) {
          this.isUserStop = true;
        }
        throw err;
      }
    }

    this.isFinish = true;
    hilog.info(122, 'LiquidOperateFlow', 'OnProcess End');
  }

  OnStop(): void {
    hilog.info(122, 'LiquidOperateFlow', 'OnStop');

    // 初始化下位机
    const controller = new BaseController();
    const deviceStatus = controller.GetIDeviceStatus();
    if (deviceStatus) {
      // deviceStatus.Initialize();
    }

    // 保存试剂余量表
    // ReagentRemainManager.SaveRemainStatus();

    if (!this.isFinish) {
      if (this.isUserStop) {
        this.result = "用户终止";
        hilog.info(122, 'LiquidOperateFlow', '用户终止');
      } else {
        this.result = "故障终止";
        hilog.warn(122, 'LiquidOperateFlow', '故障终止');
      }
    } else {
      this.result = "管路操作结束";
      hilog.info(122, 'LiquidOperateFlow', '管路操作结束');
      hilog.info(122, 'LiquidOperateFlow', '管路操作流程总时间 = %{public}ds', DateTimeUtil.getTimestamp() - this.dateTime);
    }
  }
}
