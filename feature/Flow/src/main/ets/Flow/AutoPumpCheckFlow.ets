import { hilog } from "@kit.PerformanceAnalysisKit";
import { Flow } from './Flow';
import { BaseController } from 'controllerplugin';
import { PT65DriveController } from "pt65drivecontrollerplugin";
import { DateTimeUtil } from 'base';
import { liquidTypes , LiquidType} from '../Setting/LiquidType';
import { Operator, WasteType } from '../Flow/Operator';
import { setting } from '../Setting/Setting';
import { config } from '../Config/Config';
import { ThermostatMode, MeterMode, RollDirection } from 'communication'; //导入模块


export enum AutoPumpCheckType {
  AutoPumpCheck = 0,
}

export class AutoPumpCheckFlow extends Flow {
  private SPEED: number = 0.2;

  constructor(name: string) {
    super(name);
  }

  GetRuntime(): number {
    return 0;
  }

  OnStart(): void {
    hilog.info(122, 'AutoPumpCheckFlow', 'OnStart');

    // 初始化下位机
    const controller = new BaseController();
    const deviceStatus = controller.GetIDeviceStatus();
    if (deviceStatus) {
      // deviceStatus.Initialize(); // 需根据实际接口实现
    }

    // 检测消解室是否为安全温度
    // op.CheckDigestSafety()

    // 设置运行状态
    // let runStatus = Helper.Status.SetStatus(setting.runStatus.autoPumpCheck);
    // StatusManager.Instance().SetStatus(runStatus);
  }

  OnProcess(): void {
    hilog.info(122, 'AutoPumpCheckFlow', 'OnProcess Start');

    this.isUserStop = false;
    this.isFinish = false;
    let dateTime = DateTimeUtil.getTimestamp(); //Date.now();

    try {
      const source = liquidTypes.blank;  // 需要根据实际定义
      const op = Operator.getInstance();

      // 获取泵系数并设置速度
      const factor = op.IOpticalMeter.getPumpFactor();
      op.IOpticalMeter.setMeteSpeed(setting.liquid.meterSpeed * factor);
      hilog.info(122, 'AutoPumpCheckFlow', "Set Meter Speed " + (setting.liquid.meterSpeed * factor));

      // 设置运行动作状态
      // let runAction = Helper.Status.SetAction(setting.runAction.pumpCheck.drainMeterPipe);
      // StatusManager.Instance().SetAction(runAction);

      // 排走定量管液体
      op.DrainToWaste(setting.liquid.meterPipeVolume);

      // runAction = Helper.Status.SetAction(setting.runAction.pumpCheck.meterToMinMeterPoint);
      // StatusManager.Instance().SetAction(runAction);

      // 精确定量最小定量点的液体
      this.MeterToMinMeterPoint(source);

      // 设置速度
      op.IOpticalMeter.setMeteSpeed(30 * factor);
      hilog.info(122, 'AutoPumpCheckFlow', "Set Meter Speed " + (30 * factor));

      // runAction = Helper.Status.SetAction(setting.runAction.pumpCheck.meterToMaxMeterPoint);
      // StatusManager.Instance().SetAction(runAction);

      // 直接定量最大定量点的液体
      this.MeterToMaxMeterPoint(source);

      op.IOpticalMeter.setMeteSpeed(setting.liquid.meterSpeed * factor);
      hilog.info(122, 'AutoPumpCheckFlow', "Set Meter Speed " + (setting.liquid.meterSpeed * factor));

      // 计算新的泵系数
      const meterPoinNum = config.hardware.meterPoint.num;
      const step = op.IPeristalticPump.getPumpFactor(0) / factor;
      const setFactor = (config.hardware.meterPoint.point[1].realVolume -
                         config.hardware.meterPoint.point[0].setVolume) / step;

      // runAction = Helper.Status.SetAction(setting.runAction.pumpCheck.drainMeterPipe);
      // StatusManager.Instance().SetAction(runAction);

      op.DrainToWaste(setting.liquid.meterPipeVolume);

      // hilog.info(122, 'AutoPumpCheckFlow', "Set Meter Speed " , setFactor);
      // op.IOpticalMeter.setPumpFactor(setFactor);
      // this.result = setFactor.toFixed(8);

      // 保存配置到数据库 TODO
      hilog.info(122, 'AutoPumpCheckFlow', "### ");
    } catch (err) {
      hilog.info(122, 'AutoPumpCheckFlow', "Catch Err ");
      if (err instanceof Error) {
        // 检查异常类型
        if (err.message.includes("PumpStoppedException") || 
            err.message.includes("MeterStoppedException")) {
          this.isUserStop = true;
        }
        throw err;
      }
    }

    this.isFinish = true;
    hilog.info(122, 'AutoPumpCheckFlow', 'OnProcess End, duration: %{public}dms', DateTimeUtil.getTimestamp());
  }

  OnStop(): void {
    hilog.info(122, 'AutoPumpCheckFlow', 'OnStop');

    // 初始化下位机 TODO

    // 保存试剂余量表
    // ReagentRemainManager.SaveRemainStatus();

    if (!this.isFinish) {
      if (this.isUserStop) {
        this.result = "用户终止";
        hilog.info(122, 'AutoPumpCheckFlow', '用户终止');
      } else {
        this.result = "故障终止";
        hilog.warn(122, 'AutoPumpCheckFlow', '故障终止');
      }
    } else {
      this.result = "定量泵自动校准结束";
      hilog.info(122, 'AutoPumpCheckFlow', '定量泵自动校准结束');
      
      // 更新Widget
      // UpdateWidgetManager.Instance().Update(UpdateEvent.AutoPumpCheck, "AutoPumpCheckFlow");
    }
  }

  private MeterToMinMeterPoint(source: LiquidType): void {
    const minMeterPointVolume = config.hardware.meterPoint.point[0].setVolume;
    const meterPoinNum = config.hardware.meterPoint.num;
    const maxMeterPointVolume = config.hardware.meterPoint.point[1].setVolume;

    // 重试次数配置
    const meterFailedReTry = setting.liquid.meterFailedReTry;
    const meterOverflowReTry = setting.liquid.meterOverflowReTry;
    const meterUnfinishedReTry = setting.liquid.meterUnfinishedReTry;
    const meterAirBubbleReTry = setting.liquid.meterAirBubbleReTry;
    const meterTimeoutReTry = setting.liquid.meterTimeoutReTry;

    let failedCnt = 0;
    let overflowCnt = 0;
    let unfinishedCnt = 0;
    let airBubbleCnt = 0;
    let timeoutCnt = 0;

    // 分析废液类型
    let wasteType = WasteType.WasteReagent;
    if (source == liquidTypes.blank) {
      wasteType = WasteType.WasteWater;
    }
    const op = Operator.getInstance();

    const factor = op.IPeristalticPump.getPumpFactor(0);
    const drainSpeed = setting.liquid.prefabricateDrainSpeed * factor;

    op.SetMeterOverValue(MeterMode.Accurate, setting.liquid.accurateMeterOverValue);

    // while (true)
    {
      // try
      {
        op.Meter(MeterMode.Accurate, source, minMeterPointVolume, RollDirection.Suck);
        failedCnt = 0;
        overflowCnt = 0;
        unfinishedCnt = 0;
        airBubbleCnt = 0;
        timeoutCnt = 0;
        // break;
      }
      // catch (err) {
      //   // 异常处理逻辑
      //   if (err instanceof ExpectEventTimeoutException) {
      //     timeoutCnt++;
      //     hilog.warn(122, 'AutoPumpCheckFlow', '%{public}s', err.message);
      //     if (timeoutCnt >= meterTimeoutReTry) {
      //       // op.DrainToWaste(minMeterPointVolume, wasteType);
      //       throw new Error("MeterExpectTimeoutException");
      //     }
      //   } else if (err instanceof MeterFailedException) {
      //     failedCnt++;
      //     hilog.warn(122, 'AutoPumpCheckFlow', '%{public}s', err.message);
      //     if (failedCnt >= meterFailedReTry) {
      //       // op.DrainToWaste(minMeterPointVolume, wasteType);
      //       throw err;
      //     }
      //   } else if (err instanceof MeterOverflowException) {
      //     overflowCnt++;
      //     hilog.warn(122, 'AutoPumpCheckFlow', '%{public}s', err.message);
      //     if (overflowCnt >= meterOverflowReTry) {
      //       // op.DrainToWaste(minMeterPointVolume, wasteType);
      //       throw err;
      //     }
      //   } else if (err instanceof MeterUnfinishedException) {
      //     unfinishedCnt++;
      //     hilog.warn(122, 'AutoPumpCheckFlow', '%{public}s', err.message);
      //     if (unfinishedCnt >= meterUnfinishedReTry) {
      //       // op.DrainToWaste(minMeterPointVolume, wasteType);
      //       throw err;
      //     }
      //   } else if (err instanceof MeterAirBubbleException) {
      //     airBubbleCnt++;
      //     hilog.warn(122, 'AutoPumpCheckFlow', '%{public}s', err.message);
      //     if (airBubbleCnt >= meterAirBubbleReTry) {
      //       // op.DrainToWaste(minMeterPointVolume, wasteType);
      //       throw err;
      //     }
      //   } else {
      //     throw err;
      //   }
      // }
    }
  }

  private MeterToMaxMeterPoint(source: LiquidType): void {
    const meterPoinNum = config.hardware.meterPoint.num;
    const maxMeterPointVolume = config.hardware.meterPoint.point[meterPoinNum - 1].setVolume;

    // 分析废液类型
    let wasteType = WasteType.WasteReagent;
    if (source == liquidTypes.blank) {
      wasteType = WasteType.WasteWater;
    }
    const op = Operator.getInstance();

    op.SetMeterOverValue(MeterMode.Direct, 0);

    // try
    {
      op.Meter(MeterMode.Direct, source, maxMeterPointVolume, RollDirection.Suck);
    }
    // catch (err) {
    //   // 异常处理
    //   // op.DrainToWaste(maxMeterPointVolume, wasteType);
    //   throw err;
    // }
  }
}
