import { hilog } from "@kit.PerformanceAnalysisKit";
import type { Pump, MotionParam, PumpResult } from 'communication'; // 或分别从各文件 import type
import { PumpStatus, PumpOperateResult } from 'communication'; //导入模块
/**
 * 单个蠕动泵封装类
 * 对单个蠕动泵的功能进行封装
 */
@Sendable
export class PeristalticPump {
  index: number = 0;
  isRunning: boolean = false;
  peristalticPumpInterface: Pump; //TODO: 未实现

  constructor(index: number = 0, pumpInterface: Pump) {
    this.index = index;
    this.isRunning = false;
    this.peristalticPumpInterface = pumpInterface;
  }

  /**
   * 获取泵系数
   */
  GetFactor(): number {
    if (this.peristalticPumpInterface) {
      return this.peristalticPumpInterface.getPumpFactor(this.index);
    }
    return 0;
  }

  /**
   * 设置泵系数
   * @param factor 泵系数
   */
  SetFactor(factor: number): boolean {
    if (this.peristalticPumpInterface) {
      return this.peristalticPumpInterface.setPumpFactor(this.index, factor);
    }
    return false;
  }

  /**
   * 获取运动参数
   */
  GetMotionParam(): MotionParam {
    const param: MotionParam = { acceleration: 0, speed: 0};
    if (this.peristalticPumpInterface) {
      return this.peristalticPumpInterface.getMotionParam(this.index);
    }
    return param;
  }

  /**
   * 设置运动参数
   * @param param 运动参数
   */
  SetMotionParam(param: MotionParam): boolean {
    if (this.peristalticPumpInterface) {
      return this.peristalticPumpInterface.setMotionParam(this.index, param);
    }
    return false;
  }

  /**
   * 获取泵状态
   */
  GetStatus(): PumpStatus {
    if (this.peristalticPumpInterface) {
      return this.peristalticPumpInterface.getPumpStatus(this.index);
    }
    return 0;
  }

  /**
   * 启动泵
   * @param dir 方向
   * @param volume 体积
   * @param speed 速度
   */
  Start(dir: number, volume: number, speed: number): boolean {
    this.isRunning = true;
    if (this.peristalticPumpInterface) {
      return this.peristalticPumpInterface.startPump(this.index, dir, volume, speed);
    }
    return false;
  }

  /**
   * 停止泵
   */
  Stop(): boolean {
    this.isRunning = false;
    if (this.peristalticPumpInterface) {
      return this.peristalticPumpInterface.stopPump(this.index);
    }
    return false;
  }

  /**
   * 获取泵体积
   */
  GetVolume(): number {
    if (this.peristalticPumpInterface) {
      return this.peristalticPumpInterface.getPumpVolume(this.index);
    }
    return 0;
  }

  /**
   * 等待泵操作结果
   * @param timeout 超时时间
   */
  ExpectResult(timeout: number): PumpResult {  // TODO
    let pumpResult: PumpResult = { index: 0, result: PumpOperateResult.Failed};

    if (this.peristalticPumpInterface) {
      pumpResult = this.peristalticPumpInterface.expectPumpResult(timeout);
    }

    this.isRunning = false;
    return pumpResult;
  }
}
