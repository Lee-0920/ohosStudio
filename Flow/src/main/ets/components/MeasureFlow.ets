
import { hilog } from "@kit.PerformanceAnalysisKit";
import { Flow } from './Flow';
import { Measurer, MeasureType } from './Measurer';


export class MeasureFlow extends Flow {
  measureTarget: string = 'none';
  measureType: MeasureType = 'Sample';
  reportMode: string = 'OnLine';
  adjustTime = false;
  currentRange = 1;
  isCheck = false;
  consistency = 0;
  absorbance = 0;
  isUseStart = false;
  faultTimes = 0;
  isRetryMeasure = false;
  isRetryOnStart = false;
  isCrashMeasure = false;
  diluteFactor = 1;
  isOverProof = false;
  isChangeRangeAtTheEnd = false;
  targetRange = 1;
  measureDateTime = Date.now();

  constructor(name: string, meaType: MeasureType = 'Sample') {
    super(name); // 调用父类构造函数，传入初始化参数
    this.measureType = meaType; // 设置测量类型
    this.measureDateTime = Date.now(); // 设置测量日期时间为当前时间
    this.currentRange = 1; // 设置当前测量范围为默认值1
    this.reportMode = 'OnLine'; // 设置报告模式为在线模式
    this.adjustTime = false; // 初始化时间调整标志为false
    this.isUseStart = false; // 初始化是否使用启动标志为false
    this.isOverProof = false; // 初始化是否超出范围标志为false
  }

  GetRuntime(): number {
    return 5;
  }

  OnStart(resetTime = true): void {
    if (resetTime) {
      this.measureDateTime = Date.now();
    }
    hilog.info(122, 'MeasurerFlow', 'OnStart');
  }

  OnProcess(): void {
    hilog.info(122, 'MeasurerFlow', 'Onprocess Start');
    let measure = Measurer.getInstance();
    measure.flow = this;
    measure.Measure();
    hilog.info(122, 'MeasurerFlow', 'Onprocess End');
  }

  OnStop(): void {
    hilog.info(122, 'MeasurerFlow', 'OnStop');
  }

  CollectSample(): void {
    // TODO：完整实现采样逻辑
  }

  RetryMeasureCheck(): void {
    // TODO：CCEP 崩溃重启逻辑
  }

}