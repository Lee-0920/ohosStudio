import { hilog } from "@kit.PerformanceAnalysisKit";
import { Flow } from './Flow';
import { DateTimeUtil } from 'base';
import { BaseController } from 'controllerplugin';
import { PT65DriveController } from "pt65drivecontrollerplugin";
import { liquidTypes, LiquidType } from '../Setting/LiquidType';

export enum CombineOperateType {
  SuckBlankToDigestionRoom,
  SuckDigestionRoomToWaste,
  GasSealCheck,
  OneKeyHeating,
}

export class CombineOperateFlow extends Flow {
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
    hilog.info(122, 'CombineOperateFlow', 'OnStart');

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
    hilog.info(122, 'CombineOperateFlow', 'OnProcess Start');

    this.isUserStop = false;
    this.isFinish = false;
    this.dateTime = DateTimeUtil.getTimestamp();

    try {
      // 设置运行状态
      // let runStatus = Helper.Status.SetStatus(setting.runStatus.combineOperate);
      // StatusManager.Instance().SetStatus(runStatus);

      // 设置运行动作
      // let runAction = Helper.Status.SetAction(this.action);
      // StatusManager.Instance().SetAction(runAction);

      if (this.source != liquidTypes.none) {
        const DC = new PT65DriveController();
        // const factor = DC.GetIPeristalticPump().GetPumpFactor(0);
        // DC.GetIOpticalMeter().SetMeteSpeed(setting.liquid.meterSpeed * factor);

        if (this.source == liquidTypes.blank && this.dest == liquidTypes.digestionRoom) {
          // op:PumpToDigestionRoom(this.source, this.sVolume);
        } else if (this.source == liquidTypes.digestionRoom && this.dest == liquidTypes.waste) {
          // op:DrainFromDigestionRoom(WasteType.WasteReagent);
        } else if (this.source == liquidTypes.digestionRoom && this.dest == liquidTypes.wasteWater) {
          // op:DrainFromDigestionRoom(WasteType.WasteWater);
        } else if (this.source == liquidTypes.gas && this.dest == liquidTypes.none) {
          // const drainSpeed = 400 * factor;
          // op:Pump(this.source, this.sVolume, drainSpeed);
        } else if (this.source == liquidTypes.blank && this.dest == liquidTypes.wasteWater) {
          // 排空液体
          // op:DrainToWaste(setting.liquid.meterPipeVolume);
          // op:DrainFromDigestionRoom();
          // 加零点校准液至消解管
          // op:PumpToDigestionRoom(this.source, this.sVolume);
          // 加热
          // this.Heating(setting.temperature.oneKeyHeatingTemp);
          // 冷却
          // this.Cooling(setting.temperature.oneKeyHeatingCoolingTemp);
          // 排液
          // op:DrainFromDigestionRoom(this.dest);
        } else if (this.source == liquidTypes.blank && this.dest == liquidTypes.blank) {
          // op:Pump(liquidTypes.none, 0.5, 0.2, false);
          // DC.GetIOpticalMeter().SetMeteSpeed(setting.liquid.meterSpeed * 0.3 * factor);
          // op:SetMeterOverValue(MeterMode.Accurate, setting.liquid.accurateMeterOverValue);
          // op:Meter(MeterMode.Accurate, this.source, this.sVolume, RollDirection.Suck);
        } else if (this.source == liquidTypes.standard && this.dest == liquidTypes.standard) {
          // op:Drain(liquidTypes.none, 0.5, 0.2);
          // op:Drain(this.source, this.sVolume, 0.2);
        } else {
          hilog.warn(122, 'CombineOperateFlow', '此模式不支持');
          return;
        }
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
    hilog.info(122, 'CombineOperateFlow', 'OnProcess End');
  }

  OnStop(): void {
    hilog.info(122, 'CombineOperateFlow', 'OnStop');

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
        hilog.info(122, 'CombineOperateFlow', '用户终止');
      } else {
        this.result = "故障终止";
        hilog.warn(122, 'CombineOperateFlow', '故障终止');
      }
    } else {
      this.result = "组合操作结束";
      hilog.info(122, 'CombineOperateFlow', '组合操作结束');
      hilog.info(122, 'CombineOperateFlow', '组合操作流程总时间 = %{public}ds', DateTimeUtil.getTimestamp() - this.dateTime);
    }
  }

  /**
   * 加热
   * @param targetTemp 目标温度
   */
  private Heating(targetTemp: number): void {
    const startTime = DateTimeUtil.getTimestamp();

    // 干烧保护
    // if (config.system.dryFireProtection == true) {
    //   const DC = new PT65DriveController();
    //   DC.GetIOpticalAcquire().TurnOnLED();
    //   hilog.info(122, 'CombineOperateFlow', '打开LED,不带PID');

    //   if (!this.Wait(10)) {
    //     throw new Error("用户终止");
    //   }

    //   // op:dryFireDitect();

    //   // 关闭LED
    //   DC.GetIOpticalAcquire().TurnOffLED();
    //   hilog.info(122, 'CombineOperateFlow', '关闭LED');
    // }

    // const DC = new PT65DriveController();
    // const thermostatTemp = DC.GetCurrentTemperature().GetThermostatTemp();
    // hilog.info(122, 'CombineOperateFlow', '加热消解前温度 = %{public}d℃', thermostatTemp);

    // const temp = targetTemp - thermostatTemp;
    // if (temp > 0.01) {
    //   // op:StartThermostat(ThermostatMode.Auto, targetTemp, setting.temperature.toleranceTemp, setting.temperature.oneKeyHeatingTempTimeout);
    //   // op:StopThermostat();
    // }

    // hilog.info(122, 'CombineOperateFlow', '加热时间 = %{public}ds', DateTimeUtil.getTimestamp() - startTime);
  }

  /**
   * 降温
   * @param targetTemp 目标温度
   */
  private Cooling(targetTemp: number): void {
    const startTime = DateTimeUtil.getTimestamp();

    // const DC = new PT65DriveController();
    // const thermostatTemp = DC.GetCurrentTemperature().GetThermostatTemp();
    // hilog.info(122, 'CombineOperateFlow', '降温前温度 = %{public}d℃', thermostatTemp);

    // const difference = thermostatTemp - targetTemp;
    // if (difference > 0.01) {
    //   // op:StartThermostat(ThermostatMode.Auto, targetTemp, setting.temperature.toleranceTemp, setting.temperature.oneKeyHeatingCoolingTempTimeout);
    // }

    // hilog.info(122, 'CombineOperateFlow', '消解冷却时间 = %{public}ds', DateTimeUtil.getTimestamp() - startTime);
  }
}
