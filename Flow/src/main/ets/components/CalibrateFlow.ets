import { hilog } from "@kit.PerformanceAnalysisKit";
import { Flow } from './Flow';
import { Measurer, MeasureType } from './Measurer';


export type CalibrateType = 'calibrate' | 'oneKeyMaintain' | 'onlyCalibrateBlank' | 'onlyCalibrateStandard' | 'none';


export class CalibrateFlow extends Flow {
  calibrateType: CalibrateType = 'calibrate';
  measureDateTime = Date.now();

  constructor(name: string, caliType: CalibrateType = 'calibrate') {
    super(name); // 调用父类构造函数，传入初始化参数
    this.calibrateType = caliType; // 设置测量类型
  }

  GetRuntime(): number {
    return 5;
  }

  OnStart(resetTime = true): void {
    if (resetTime) {
      this.measureDateTime = Date.now();
    }
    hilog.info(122, 'CalibrateFlow', 'OnStart');
  }

  OnProcess(): void {
    hilog.info(122, 'CalibrateFlow', 'Onprocess Start');
    let measure = Measurer.getInstance();
    measure.flow = this;
    measure.Measure();
    hilog.info(122, 'CalibrateFlow', 'Onprocess End');
  }

  OnStop(): void {
    hilog.info(122, 'CalibrateFlow', 'OnStop');
  }

  CollectSample(): void {
    // TODO：完整实现采样逻辑
  }

  RetryMeasureCheck(): void {
    // TODO：CCEP 崩溃重启逻辑
  }

}