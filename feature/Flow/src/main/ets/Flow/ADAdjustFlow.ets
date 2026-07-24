import { hilog } from "@kit.PerformanceAnalysisKit";
import { Flow } from './Flow';
import { DateTimeUtil } from 'base';
import { BaseController } from 'controllerplugin';
import { PT65DriveController } from "pt65drivecontrollerplugin";
import { liquidTypes , LiquidType} from '../Setting/LiquidType';
import { Operator, WasteType } from '../Flow/Operator';
import { setting } from '../Setting/Setting';
import { config } from '../Config/Config';
import { ThermostatMode, MeterMode, RollDirection } from 'communication'; //导入模块

export enum ADAdjustType {
  MeterADAdjust = 0,
  MeasureADAdjust = 1,
}

export class ADAdjustFlow extends Flow {
  action: ADAdjustType = ADAdjustType.MeterADAdjust;

  constructor(name: string, action: ADAdjustType) {
    super(name);
    this.action = action;
  }

  GetRuntime(): number {
    // TODO: 根据 action 获取运行时间
    // 需要实现 setting.runStatus.meterADAdjust.GetTime() 和 setting.runStatus.measureADAdjust.GetTime()
    return 30; // 默认返回30秒
  }

  OnStart(): void {
    hilog.info(122, 'ADAdjustFlow', 'OnStart');

    // // 初始化下位机
    // const controller = new BaseController();
    // const deviceStatus = controller.GetIDeviceStatus();
    // if (deviceStatus) {
    //   // deviceStatus.Initialize(); // 需根据实际接口实现
    // }

    // 检测消解室是否为安全温度
    // op.CheckDigestSafety() - 需根据实际接口实现
  }

  OnProcess(): void {
    hilog.info(122, 'ADAdjustFlow', 'OnProcess Start');

    this.isUserStop = false;
    this.isFinish = false;

    let dateTime = DateTimeUtil.getTimestamp();

    console.info(`${JSON.stringify(this.action)}`);

    try {
      if (this.action == ADAdjustType.MeterADAdjust) {
        hilog.info(122, 'ADAdjustFlow', 'MeterADAdjust');
        this.MeterADAdjust();
      } else if (this.action == ADAdjustType.MeasureADAdjust) {
        hilog.info(122, 'ADAdjustFlow', 'MeasureADAdjust');
        this.MeasureADAdjust();
      }
    } catch (err) {
      if (err instanceof Error) {
        // 检查异常类型
        if (err.message.includes("用户终止")) {
          this.isUserStop = true;
        }
        throw err;
      }
    }

    this.isFinish = true;
    hilog.info(122, 'ADAdjustFlow', 'OnProcess End, duration: %{public}dms', DateTimeUtil.getTimestamp() - dateTime);
  }

  OnStop(): void {
    hilog.info(122, 'ADAdjustFlow', 'OnStop');

    // // 初始化下位机
    // const controller = new BaseController();
    // const deviceStatus = controller.GetIDeviceStatus();
    // if (deviceStatus) {
    //   // deviceStatus.Initialize(); // 需根据实际接口实现
    // }

    if (!this.isFinish) {
      if (this.isUserStop) {
        this.result = "用户终止";
        hilog.info(122, 'ADAdjustFlow', '用户终止');
      } else {
        this.result = "故障终止";
        hilog.warn(122, 'ADAdjustFlow', '故障终止');
      }
    } else {
      let actionText = this.action == ADAdjustType.MeterADAdjust ? "定量AD调节" : "测量AD调节";
      this.result = actionText + "结束";
      hilog.info(122, 'ADAdjustFlow', '%{public}s', this.result);
    }
  }

  private MeterADAdjust(): void {
    hilog.info(122, 'ADAdjustFlow', 'MeterADAdjust Start');

    const op = Operator.getInstance();

    // 获取蠕动泵系数
    const factor = op.IPeristalticPump.getPumpFactor(0);
    // 设置测光速度
    op.IOpticalMeter.setMeteSpeed(setting.liquid.meterSpeed * factor);

    // 设置运行动作状态
    // local runAction = Helper.Status.SetAction(setting.runAction.meterADAdjustFlow.drainMeterPipe)
    // StatusManager.Instance():SetAction(runAction)

    // 排液操作
    op.Drain(liquidTypes.waste, 3, setting.liquid.prefabricateDrainSpeed * factor)

    // 定量点1 AD调节
    // runAction = Helper.Status.SetAction(setting.runAction.meterADAdjustFlow.adjustMeterPointOne)
    // StatusManager.Instance():SetAction(runAction)
    let ret = op.AutoStaticADControl(2, config.measureParam.meterLedAD[0])
    if (this.Wait(1.5)) {
      throw new Error("用户终止");
    }

    // 定量点2 AD调节
    // runAction = Helper.Status.SetAction(setting.runAction.meterADAdjustFlow.adjustMeterPointTwo)
    // StatusManager.Instance():SetAction(runAction)
    ret = op.AutoStaticADControl(3, config.measureParam.meterLedAD[1])
    if (this.Wait(1.5)) {
      throw new Error("用户终止");
    }

    // 保存配置到数据库 TODO
    // let meter1Value = string.format("%d", dc:GetIOpticalAcquire():GetStaticADControlParam(2))
    // let meter2Value = string.format("%d", dc:GetIOpticalAcquire():GetStaticADControlParam(3))
    // WqimcManager.Instance():updateConfigs(configVector)

    hilog.info(122, 'ADAdjustFlow', 'MeterADAdjust End');
  }

  private MeasureADAdjust(): void {
    hilog.info(122, 'ADAdjustFlow', 'MeasureADAdjust Start');

    const op = Operator.getInstance();

    // 获取蠕动泵系数
    const factor = op.IPeristalticPump.getPumpFactor(0);
    // 设置测光速度
    op.IOpticalMeter.setMeteSpeed(setting.liquid.meterSpeed * factor);

    // 从消解室排液
    op.DrainFromDigestionRoom(WasteType.WasteReagent)

    // 向消解室泵入空白液
    op.PumpToDigestionRoom(liquidTypes.blank, 6)

    // 参考AD调节
    let ret = op.AutoStaticADControl(0, config.measureParam.measureLedAD.reference)
    if (this.Wait(1.5)) {
      throw new Error("用户终止");
    }

    // 测量AD调节
    ret = op.AutoStaticADControl(1, config.measureParam.measureLedAD.measure)
    if (this.Wait(1.5)) {
      throw new Error("用户终止");
    }

    // 保存配置到数据库 TODO
    // let referenceValue = string.format("%d", dc:GetIOpticalAcquire():GetStaticADControlParam(0))
    // let measureValue = string.format("%d", dc:GetIOpticalAcquire():GetStaticADControlParam(1))
    // WqimcManager.Instance():updateConfigs(configVector)

    // 再次从消解室排液
    op.DrainFromDigestionRoom(WasteType.WasteReagent)

    hilog.info(122, 'ADAdjustFlow', 'MeasureADAdjust End');
  }
}
