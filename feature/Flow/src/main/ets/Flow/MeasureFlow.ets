import { hilog } from "@kit.PerformanceAnalysisKit";
import { Flow } from './Flow';
import { DateTimeUtil } from 'base';
import { Measurer, MeasureResult } from './Measurer';
import { MeasureData } from '../DataManager/DataBase';
import { MeasureAD } from '../Common/MeasureAD';
import { config, status, MeasureMode } from "../Config/Config";
import { setting, ResultMark, RangeConfig} from "../Setting/Setting";

//测量参数暴露
export interface MeasureConfig {
  measureType: MeasureType,
  currentRange: number,
  addParam: RangeConfig,
  measureResult: MeasureResult
}

export enum MeasureType {
  Blank = 0,           // 空白水
  Sample = 1,          // 水样
  Standard = 2,        // 标液
  Check = 3,           // 核查样
  AddStandard = 4,     // 加标样
  Parallel = 5,        // 平行样
  ZeroCheck = 6,       // 零点核查
  RangeCheck = 7,      // 量程核查
  ExtAddStandard = 8,  // 外部加标
  ExtParallel = 9,     // 外部平行
  QualityHandle = 10,  // 质控
}

export enum ReportMode {
  OnLine = 'OnLine',
  OffLine = 'OffLine',
  Maintain = 'Maintain',
  Fault = 'Fault',
  Calibrate = 'Calibrate',
  Debugging = 'Debugging',
}

export class MeasureFlow extends Flow {
  measureType: MeasureType = MeasureType.Sample;
  reportMode: ReportMode = ReportMode.OnLine;
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
  measureDateTime = DateTimeUtil.getTimestamp();
  // 新增属性
  autoCheckTimes = 1;
  isOldCheck = false;
  // 本次测量生成的记录，由 worker 抛回主线程后统一入库
  lastMeasureRecord: MeasureData | null = null;
  addParam: RangeConfig = { };
  measureResult: MeasureResult = {
    initReferenceAD: 0,
    initMeasureAD: 0,
    finalReferenceAD: 0,
    finalMeasureAD: 0,
    darkReferenceAD: 0,
    darkMeasureAD: 0,
    initThermostatTemp: 0,
    initEnvironmentTemp: 0,
    finalThermostatTemp: 0,
    finalEnvironmentTemp: 0,
  };

  constructor(name: string, meaType: MeasureType = MeasureType.Sample) {
    super(name);
    this.measureType = meaType;
    this.measureDateTime = DateTimeUtil.getTimestamp();
    this.currentRange = config.measureParam.range[config.measureParam.currentRange + 1] + 1;
    this.reportMode = config.interconnection.reportMode as ReportMode;
    this.adjustTime = false;
    this.autoCheckTimes = 1;
    this.isOldCheck = false;
    this.isUseStart = false;
    this.isOverProof = false;
  }

  GetRuntime(): number {
    if (this.measureType === MeasureType.Blank) {
      return setting.runStatus.measureBlank.GetTime?.() || 0;
    } else if (this.measureType === MeasureType.Standard) {
      return setting.runStatus.measureStandard.GetTime?.() || 0;
    } else if (this.measureType === MeasureType.Sample) {
      return setting.runStatus.measureSample.GetTime?.() || 0;
    } else if (this.measureType === MeasureType.QualityHandle) {
      return setting.runStatus.measureQualityHandle.GetTime?.() || 0;
    } else if (this.measureType === MeasureType.RangeCheck) {
      return setting.runStatus.measureRangeCheck.GetTime?.() || 0;
    } else if (this.measureType === MeasureType.AddStandard) {
      return setting.runStatus.measureAddstandard.GetTime?.() || 0;
    } else if (this.measureType === MeasureType.Parallel) {
      return setting.runStatus.measureParallel.GetTime?.() || 0;
    } else if (this.measureType === MeasureType.ExtAddStandard) {
      return setting.runStatus.measureExtAddstandard.GetTime?.() || 0;
    } else if (this.measureType === MeasureType.ExtParallel) {
      return setting.runStatus.measureExtParallel.GetTime?.() || 0;
    }
    return 0;
  }

  OnStart(resetTime = true): void {
    if (resetTime) {
      this.measureDateTime = DateTimeUtil.getTimestamp();
    }

    if (this.isCrashMeasure) {
      this.measureDateTime = status.measureRunning.lastMeasureTime;
    } else {
      status.measureRunning.lastMeasureTime = this.measureDateTime;
    }

    status.measureStatus.isUseStart = this.isUseStart;

    if (this.measureType === MeasureType.Sample) {
      status.measureRunning.isMeasuring = true;
    }

    switch (this.measureType) {
      case MeasureType.Blank:
        this.currentRange = config.measureParam.range[config.measureParam.calibrateRangeIndex + 1] + 1;
        break;
      case MeasureType.Standard:
        this.currentRange = config.measureParam.range[config.measureParam.calibrateRangeIndex + 1] + 1;
        break;
      case MeasureType.Sample:
        this.currentRange = config.measureParam.range[config.measureParam.currentRange + 1] + 1;
        break;
      case MeasureType.RangeCheck:
        this.currentRange = config.measureParam.range[config.measureParam.rangeCheckRangeIndex + 1] + 1;
        break;
      case MeasureType.QualityHandle:
      case MeasureType.AddStandard:
      case MeasureType.Parallel:
      case MeasureType.ExtAddStandard:
      case MeasureType.ExtParallel:
        this.currentRange = config.measureParam.range[config.measureParam.currentRange + 1] + 1;
        break;
    }

    hilog.info(122, 'MeasureFlow', 'OnStart');
  }

  OnProcess(): void {
    hilog.info(122, 'MeasureFlow', 'OnProcess Start');
    let loopcnt = 3;
    this.isRetryMeasure = true;
    this.isRetryOnStart = false;
    this.isUserStop = false;
    this.isFinish = false;
    while (this.isRetryMeasure && loopcnt > 0) {
      loopcnt--;
      this.isRetryMeasure = false;

      try {
        if (this.isRetryOnStart) {
          this.isRetryOnStart = false;
          this.OnStart(false);
        }
        const measure = Measurer.getInstance();
        // if (measure.flow) {
          measure.Reset();
        // }
        measure.flow = this;

        if (this.measureType === MeasureType.Sample || 
            this.measureType === MeasureType.AddStandard || 
            this.measureType === MeasureType.Parallel) {
          measure.measureType = MeasureType.Sample;
        } else {
          measure.measureType = this.measureType;
        }
        measure.currentRange = this.currentRange;
        const rangeConfig = setting.measureRange[this.currentRange - 1];
        // for (const key in rangeConfig) {
        //   (measure.addParam as Record<string, number | boolean>)[key] = rangeConfig[key as keyof typeof rangeConfig] as never;
        // }
        if (rangeConfig) {
          // this.addParam = rangeConfig;
          const safeCopy: RangeConfig = {};
          this.updateRangeConfigFromSource(safeCopy, rangeConfig);
          this.addParam = safeCopy;
        }

        //不修改Measurer内部的addPrams,在MeasureFlow修改后将参数暴露,后续注册到任务中
        if (this.measureType === MeasureType.Blank) {
          this.addParam.blankVolume = (rangeConfig.blankVolume || 0) + (rangeConfig.sampleVolume || 0);
          this.addParam.sampleVolume = 0;
          this.addParam.rinseBlankVolume = (rangeConfig.rinseBlankVolume || 0) + (rangeConfig.rinseSampleVolume || 0);
          this.addParam.rinseSampleVolume = 0;
        } else if (this.measureType === MeasureType.Standard) {
          this.addParam.standardVolume = (rangeConfig.standardVolume || 0) + (rangeConfig.sampleVolume || 0);
          this.addParam.sampleVolume = 0;
          this.addParam.rinseStandardVolume = (rangeConfig.rinseStandardVolume || 0) + (rangeConfig.rinseSampleVolume || 0);
          this.addParam.rinseSampleVolume = 0;
        } else if (this.measureType === MeasureType.ZeroCheck) {
          this.addParam.zeroCheckVolume = (rangeConfig.zeroCheckVolume || 0) + (rangeConfig.sampleVolume || 0);
          this.addParam.sampleVolume = 0;
          this.addParam.rinseZeroCheckVolume = (rangeConfig.rinseZeroCheckVolume || 0) + (rangeConfig.rinseSampleVolume || 0);
          this.addParam.rinseSampleVolume = 0;
        } else if (this.measureType === MeasureType.RangeCheck) {
          this.addParam.rangeCheckVolume = (rangeConfig.rangeCheckVolume || 0) + (rangeConfig.sampleVolume || 0);
          this.addParam.sampleVolume = 0;
          this.addParam.rinseRangeCheckVolume = (rangeConfig.rinseRangeCheckVolume || 0) + (rangeConfig.rinseSampleVolume || 0);
          this.addParam.rinseSampleVolume = 0;
        }

        this.diluteFactor = measure.addParam.diluteFactor || 1;

        if (this.measureType === MeasureType.Sample) {
          // this.CollectSample();
        }

        if (this.isCrashMeasure && config.system.cCepMode) {
          // this.RetryMeasureCheck();
        } else {
          // measure.Measure();

          if (this.measureType === MeasureType.AddStandard || this.measureType === MeasureType.Parallel) {
            // if (measure.flow) {
            //   measure.Reset();
            // }
            measure.flow = this;
            measure.measureType = this.measureType;
            measure.currentRange = this.currentRange;
            measure.addParam = rangeConfig;

            if (this.measureType === MeasureType.AddStandard) {
              switch (this.currentRange) {
                case 1:
                  measure.addParam.sampleVolume = 2;
                  break;
                case 2:
                  measure.addParam.dilutionAddBlankVolume1 = 0;
                  break;
                case 3:
                  measure.addParam.dilutionAddBlankVolume1 = 4;
                  break;
                case 4:
                  measure.addParam.dilutionAddBlankVolume2 = 1;
                  break;
                case 5:
                  measure.addParam.dilutionAddBlankVolume2 = 3;
                  break;
              }
            }

            measure.Measure();
          }
        }
      } catch (err) {
        // TODO 错误处理
      }
    }

    hilog.info(122, 'MeasureFlow', 'OnProcess End');
  }

  OnStop(): void {
    if (status.measureRunning.isCorrectStopFlow) {
      status.measureRunning.isMeasuring = false;
    }

    if (!this.isFinish) {
      if (this.measureType === MeasureType.Sample) {
        status.measureStatus.schedule.autoMeasure.dateTime = this.measureDateTime;
      } else if (this.measureType === MeasureType.RangeCheck) {
        status.measureStatus.schedule.rangeCheck.dateTime = this.measureDateTime;
      } else if (this.measureType === MeasureType.Standard) {
        status.measureStatus.schedule.autoCheck.dateTime = this.measureDateTime;
      } else if (this.measureType === MeasureType.Blank) {
        status.measureStatus.schedule.autoBlankCheck.dateTime = this.measureDateTime;
      } else if (this.measureType === MeasureType.AddStandard || this.measureType === MeasureType.ExtAddStandard) {
        status.measureStatus.schedule.autoAddStandard.dateTime = this.measureDateTime;
      } else if (this.measureType === MeasureType.Parallel || this.measureType === MeasureType.ExtParallel) {
        status.measureStatus.schedule.autoParallel.dateTime = this.measureDateTime;
      }

      if (this.isUserStop) {
        this.result = '用户终止';
        hilog.info(122, 'MeasureFlow', '用户终止');
      } else {
        status.measureStatus.newResult.measure.resultMark = 'D';
        status.measureStatus.newResult.measure.resultInfo = 'D';
        status.measureStatus.report.complexResult.resultInfo = 'D';
        status.measureStatus.isFatalError = true;
        switch (this.measureType) {
          case MeasureType.Sample:{
            status.measureStatus.report.measure.resultInfo = status.measureStatus.newResult.measure.resultInfo
            break;
          }
          case MeasureType.Standard: {
            status.measureStatus.report.check.resultInfo = status.measureStatus.newResult.measure.resultInfo
            break;
          }
          case MeasureType.Blank: {
            status.measureStatus.report.blankCheck.resultInfo = status.measureStatus.newResult.measure.resultInfo
            break;
          }
          case MeasureType.AddStandard:
          case MeasureType.ExtAddStandard: {
            status.measureStatus.report.addStandard.resultInfo = status.measureStatus.newResult.measure.resultInfo
            break;
          }
          case MeasureType.Parallel:
          case MeasureType.ExtParallel: {
            status.measureStatus.report.parallel.resultInfo = status.measureStatus.newResult.measure.resultInfo
            break;
          }
          case MeasureType.ZeroCheck: {
            status.measureStatus.report.zeroCheck.resultInfo = status.measureStatus.newResult.measure.resultInfo
            break;
          }
          case MeasureType.RangeCheck: {
            status.measureStatus.report.rangeCheck.resultInfo = status.measureStatus.newResult.measure.resultInfo
            break;
          }
          case MeasureType.QualityHandle: {
            status.measureStatus.report.qualityHandle.resultInfo = status.measureStatus.newResult.measure.resultInfo
            break;
          }
          default: break;
        }

        this.result = '故障终止';
        hilog.warn(122, 'MeasureFlow', '故障终止');
      }
    } else {
      status.measureStatus.isDeviceFault = false;
      this.result = '测量完成';
      hilog.info(122, 'MeasureFlow', '测量完成');
      hilog.info(122, 'MeasureFlow', '测量流程总时间 = %{public}d', DateTimeUtil.getTimestamp() - this.measureDateTime);

      if (this.measureType === MeasureType.RangeCheck) {
        const checkConsistency = config.measureParam.checkConsistency;
        const checkError = (this.consistency - checkConsistency) / checkConsistency;
        hilog.debug(122, 'MeasureFlow', '标样核查 实测值 = %{public}d 标准值 = %{public}d 偏差 = %{public}d', 
          this.consistency, checkConsistency, checkError);
        status.measureStatus.report.rangeCheck.checkError = checkError;
      }
    }

    if (config.interconnection.overProofAutoCheck && this.isOverProof) {
      hilog.debug(122, 'MeasureFlow', '水样超上限 启动核查');
    }

    hilog.info(122, 'MeasureFlow', 'OnStop');
  }

  CollectSample(): void {
    hilog.info(122, 'MeasureFlow', 'CollectSample');
  }

  RetryMeasureCheck(isRangeCheck?: boolean): boolean {
    const rangeCheckRetry = isRangeCheck ?? false;
    this.isCrashMeasure = false;

    if (this.isFinish) {
      hilog.debug(122, 'MeasureFlow', '已出结果，无需重测');
      return false;
    }

    if (!config.system.faultRetry) {
      return false;
    }

    this.faultTimes++;

    const maxFaultTimes = 3;
    if (this.faultTimes >= maxFaultTimes) {
      if (!rangeCheckRetry) {
        hilog.error(122, 'MeasureFlow', '测量异常重测次数已达上限');
      }
      return false;
    }

    this.isRetryMeasure = true;
    this.isRetryOnStart = true;
    hilog.warn(122, 'MeasureFlow', '测量异常重测次数 = %{public}d', this.faultTimes);
    return true;
  }

  CalculateConsistency(absorbance: number, diluteFactor?: number): number {
    let consistency = 0;
    const curveK = config.measureParam.curveParam[this.currentRange]?.curveK || 0;
    const curveB = config.measureParam.curveParam[this.currentRange]?.curveB || 0;
    
    if (Math.abs(curveK) < 0.00001) {
      hilog.debug(122, 'MeasureFlow', '斜率数值异常');
      return 0;
    }
    
    hilog.debug(122, 'MeasureFlow', '量程%{public}d计算斜率 K = %{public}d, B = %{public}d',
      this.currentRange, curveK, curveB);
    consistency = (absorbance - curveB) / curveK;
    hilog.info(122, 'MeasureFlow', 'CalculateConsistency absorbance:%{public}d consistency:%{public}d diluteFactor:%{public}d', 
      absorbance, consistency, diluteFactor);
    return consistency;
  }

  ReviseAbs(consistency: number): number {
    const curveK = config.measureParam.curveParam[this.currentRange]?.curveK || 0;
    const curveB = config.measureParam.curveParam[this.currentRange]?.curveB || 0;

    if (Math.abs(curveK) < 0.00001) {
      hilog.debug(122, 'MeasureFlow', '斜率数值异常');
      return 0;
    }

    return consistency * curveK + curveB;
  }

  CheckCurve(): boolean {
    const timeStr = config.measureParam.curveParam[this.currentRange]?.timeStr;
    return timeStr !== '--';
  }

  AbnormalAbsorbanceRevise(absorbance: number): number {
    let retA = absorbance;
    if (absorbance > setting.measureResult.absLimit) {
      const random = 0.1 * (Math.random() - 0.5) * setting.measureResult.absLimit;
      retA = setting.measureResult.absLimit + random;
      hilog.warn(122, 'MeasureFlow', 'Abnormal Absorbance Revise ==> Abs0 = %{public}d, Abs = %{public}d', absorbance, retA);
    }
    return retA;
  }

  ConsistencyRevise(consistency: number, infoPrintf = true): number {
    const pLowLimit = setting.measureResult.measureLowLimit;
    const quantifyLowLimit = setting.measureResult.quantifyLowLimit * 0.4;
    const nLowLimit = -pLowLimit;

    if (consistency < quantifyLowLimit) {
      if (infoPrintf) {
        hilog.info(122, 'MeasureFlow', '低于检出限');
      } else {
        hilog.debug(122, 'MeasureFlow', '低于检出限');
      }
    }

    if (consistency < nLowLimit) {
      const random = 2 * (Math.random() - 0.5) * setting.measureResult.negativeReviseWaveRange;
      return setting.measureResult.negativeReviseBaseValue + random;
    } else if (consistency >= nLowLimit && consistency < -0.001) {
      return Math.abs(consistency);
    } else if (consistency >= -0.001 && consistency <= 0.001) {
      return setting.measureResult.zeroReviseValue;
    }
    return consistency;
  }

  ConsistencyOffset(consistency: number): number {
    const quantifyLowLimit = setting.measureResult.quantifyLowLimit * this.diluteFactor;
    
    if (consistency < quantifyLowLimit) {
      const offset = consistency + config.measureParam.measureDataOffsetValve * this.diluteFactor;
      hilog.debug(122, 'MeasureFlow', '结果偏移 原数值 = %{public}d 修正后数值 = %{public}d', consistency, offset);
      return offset;
    }
    return consistency;
  }

  RangeCheck(result: number, currange: number): void {
    const rangeConfig = setting.measureRange[currange - 1];
    if (rangeConfig && rangeConfig.rangeWindowMin !== undefined && rangeConfig.rangeWindowMax !== undefined && rangeConfig.viewRange !== undefined) {
      if (result >= rangeConfig.rangeWindowMin && result <= rangeConfig.rangeWindowMax) {
        return;
      }


      if (currange === 1 && result < rangeConfig.rangeWindowMin) {
        hilog.info(122, 'MeasureFlow', '水样超量程下限');
      } else if (currange === setting.measureRange.length && result > rangeConfig.viewRange) {
        hilog.info(122, 'MeasureFlow', '水样超量程上限');
      } else {
        hilog.debug(122, 'MeasureFlow', '结果%{public}d不在量程%{public}d内', this.consistency, this.currentRange);
        this.targetRange = this.RangeChange(this.consistency, this.currentRange);

        if (this.targetRange !== config.measureParam.currentRange) {
          hilog.debug(122, 'MeasureFlow', '量程自动切换至 = %{public}d',
            config.system.rangeViewMap?.[config.measureParam.range[this.targetRange + 1] + 1]?.view ??
              this.targetRange);
        }
      }
    }
  }

  RangeChange(result: number, currange: number): number {
    let realRange = config.measureParam.currentRange;
    const rangeTable: number[] = [];

    for (let i = 1; i <= setting.measureRange.length; i++) {
      if (config.measureParam.range.includes(i - 1)) {
        rangeTable.push(i);
      }
    }

    const currentRangeConfig = setting.measureRange[currange - 1];
    if (currentRangeConfig && currentRangeConfig.rangeWindowMax !== undefined && currentRangeConfig.rangeWindowMin !== undefined) {
      if (result > currentRangeConfig.rangeWindowMax) {
        if (rangeTable[rangeTable.length - 1] !== currange) {
          for (const range of rangeTable) {
            if (range > currange) {
              const idx = config.measureParam.range.indexOf(range - 1);
              if (idx !== -1) {
                realRange = idx;
              }
              break;
            }
          }
        }
      } else if (result < currentRangeConfig.rangeWindowMin) {
        if (currange !== rangeTable[0]) {
          for (const range of rangeTable) {
            const rangeConfig = setting.measureRange[range - 1];
            if (rangeConfig && rangeConfig.rangeWindowMax !== undefined && result < rangeConfig.rangeWindowMax) {
              const idx = config.measureParam.range.indexOf(range - 1);
              if (idx !== -1) {
                realRange = idx;
              }
              break;
            }
          }
        }
      }
    }

    return realRange;
  }

  ProformaResultHandle(result: MeasureResult): void {
    hilog.debug(122, 'MeasureFlow', '预估测量结果');

    const measureAD = new MeasureAD();
    measureAD.blankReference = status.measureStatus.proformaResult.measure.blankReference;
    measureAD.blankMeasure = status.measureStatus.proformaResult.measure.blankMeasure;
    measureAD.initReference = result.initReferenceAD;
    measureAD.initMeasure = result.initMeasureAD;
    measureAD.finalReference = result.finalReferenceAD;
    measureAD.finalMeasure = result.finalMeasureAD;

    let absorbance = 0;
    if (status.measureStatus.proformaResult.measure.dateTime !== 0) {
      measureAD.CalculateBlankAbsorbance();
      measureAD.CalculateInitAbsorbance();
      absorbance = measureAD.CalculateRelAbsorbance();
    }

    absorbance = this.AbnormalAbsorbanceRevise(absorbance);
    let consistency = this.CalculateConsistency(absorbance);

    consistency += config.measureParam.shiftFactor;
    const shiftAbs = config.measureParam.shiftFactor * 
      (config.measureParam.curveParam[this.currentRange]?.curveK || 0) / 
      (config.measureParam.reviseFactor * (config.measureParam.reviseParameter[this.currentRange] || 1));
    absorbance += shiftAbs;

    consistency = this.ConsistencyOffset(consistency);
    absorbance = this.ReviseAbs(consistency);

    const tempConsistency = consistency;
    consistency = tempConsistency * config.measureParam.reviseFactor;
    hilog.debug(122, 'MeasureFlow', '结果浓度修正 修正系数 = %{public}d，原浓度 = %{public}d，修正浓度 = %{public}d', 
      config.measureParam.reviseFactor, tempConsistency, consistency);

    if (config.measureParam.negativeRevise) {
      consistency = this.ConsistencyRevise(consistency, false);
    }

    hilog.debug(122, 'MeasureFlow', '预估测量结果：iRef = %{public}d，iMea = %{public}d，fRef = %{public}d，fMea = %{public}d，A = %{public}d，C = %{public}d',
      measureAD.initReference, measureAD.initMeasure, measureAD.finalReference, measureAD.finalMeasure, absorbance, consistency);
  }

  ResultHandle(result: MeasureResult): void {
    const measureAD = new MeasureAD();
    measureAD.blankReference = result.initReferenceAD - result.darkReferenceAD;
    measureAD.blankMeasure = result.initMeasureAD - result.darkMeasureAD;
    measureAD.finalReference = result.finalReferenceAD - result.darkReferenceAD;
    measureAD.finalMeasure = result.finalMeasureAD - result.darkMeasureAD;

    hilog.debug(122, 'MeasureFlow',
      '结果浓度修正 空白参考AD = %{public}d，空白测量AD = %{public}d，最终参考AD = %{public}d，最终测量AD = %{public}d 暗电流参考AD = %{public}d，暗电流测量AD = %{public}d',
      result.initReferenceAD,
      result.initMeasureAD,
      result.finalReferenceAD,
      result.finalMeasureAD,
      result.darkReferenceAD,
      result.darkMeasureAD
    );

    hilog.debug(122, 'MeasureFlow',
      '结果浓度修正 空白参考AD = %{public}d，空白测量AD = %{public}d，最终参考AD = %{public}d，最终测量AD = %{public}d',
      measureAD.blankReference,
      measureAD.blankMeasure,
      measureAD.finalReference,
      measureAD.finalMeasure
    );

    measureAD.CalculateBlankAbsorbance();
    measureAD.CalculateInitAbsorbance();
    this.absorbance = measureAD.CalculateRelAbsorbance();

    hilog.debug(122, 'MeasureAD', `吸光度 = ${this.absorbance}`);

    this.absorbance = this.AbnormalAbsorbanceRevise(this.absorbance);
    this.consistency = this.CalculateConsistency(this.absorbance, this.diluteFactor);

    this.consistency += config.measureParam.shiftFactor;
    const shiftAbs = config.measureParam.shiftFactor * 
      (config.measureParam.curveParam[this.currentRange]?.curveK || 0) / 
      (config.measureParam.reviseFactor * (config.measureParam.reviseParameter[this.currentRange] || 1));
    this.absorbance += shiftAbs;

    if (setting.common.skipFlow) {
      this.consistency = setting.common.minRandomData + Math.random() * (setting.common.maxRandomData - setting.common.minRandomData);
    } else {
      this.consistency = this.ConsistencyOffset(this.consistency);
    }
    this.absorbance = this.ReviseAbs(this.consistency);

    if (config.measureParam.negativeRevise) {
      this.consistency = this.ConsistencyRevise(this.consistency);
    }

    if (this.consistency > (config.system.rangeViewMap?.[this.currentRange]?.view || 0) * 1.5 && this.CheckCurve()) {
      this.consistency = (config.system.rangeViewMap?.[this.currentRange]?.view || 0) * 1.5 + 
        Math.random() * setting.measureResult.quantifyLowLimit;
      this.absorbance = this.ReviseAbs(this.consistency);
    }

    if (Measurer.getInstance().measureType === MeasureType.Sample && config.measureParam.autoChangeRange) {
      this.RangeCheck(this.consistency, this.currentRange);
    }

    let resultMark = ResultMark.N;
    this.reportMode = config.interconnection.reportMode as ReportMode;

    if (this.reportMode === ReportMode.OnLine) {
      if (this.measureType === MeasureType.Sample) {
        if (this.consistency > config.interconnection.meaUpLimit && config.interconnection.overProofResultMark === 1) {
          resultMark = ResultMark.T;
          this.isOverProof = true;
        } else if (this.consistency > (config.system.rangeViewMap?.[this.currentRange]?.view || 0)) {
          resultMark = ResultMark.E;
        }
      } else if (this.measureType === MeasureType.RangeCheck || this.measureType === MeasureType.ZeroCheck) {
        resultMark = ResultMark.C;
      } else if (this.measureType === MeasureType.QualityHandle) {
        resultMark = ResultMark.K;
      }
    } else if (this.reportMode === ReportMode.OffLine) {
      resultMark = ResultMark.B;
    } else if (this.reportMode === ReportMode.Maintain) {
      resultMark = ResultMark.M;
    } else if (this.reportMode === ReportMode.Fault) {
      resultMark = ResultMark.D;
    } else if (this.reportMode === ReportMode.Calibrate) {
      resultMark = ResultMark.C;
    } else if (this.reportMode === ReportMode.Debugging) {
      resultMark = ResultMark.A;
    }

    if (this.adjustTime) {
      if ((this.measureType === MeasureType.Sample && config.scheduler.measure.mode === MeasureMode.Timed) ||
          (this.measureType === MeasureType.ZeroCheck && config.scheduler.measure.mode === MeasureMode.Timed) ||
          (this.measureType === MeasureType.RangeCheck && config.scheduler.measure.mode === MeasureMode.Timed) ) {

        this.measureDateTime == this.AdjustMeasureDateTime(this.measureDateTime);
      }
    }

    const tempConsistency = this.consistency;
    this.consistency = tempConsistency * config.measureParam.reviseFactor;
    hilog.debug(122, 'MeasureFlow', '结果浓度修正 修正系数 = %{public}d，原浓度 = %{public}d，修正浓度 = %{public}d', 
      config.measureParam.reviseFactor, tempConsistency, this.consistency);

    const record: MeasureData = {
      dateTime: this.measureDateTime,
      consistency: this.consistency,
      absorbance: this.absorbance,
      mode: resultMark,
      resultType: this.measureType,
      initReferenceAD: result.initReferenceAD,
      initMeasureAD: result.initMeasureAD,
      finalReferenceAD: result.finalReferenceAD,
      finalMeasureAD: result.finalMeasureAD,
      initThermostatTemp: result.initThermostatTemp,
      initEnvironmentTemp: result.initEnvironmentTemp,
      finalThermostatTemp: result.finalThermostatTemp,
      finalEnvironmentTemp: result.finalEnvironmentTemp,
      initConsistency: 0,
      measureTime: DateTimeUtil.getTimestamp() - this.measureDateTime,
      addStandardConsistency: config.measureParam.curveParam[this.currentRange]?.rangeConsistency || 0,
      measureRange: this.currentRange,
    };
    this.lastMeasureRecord = record;

    if (this.measureType === Measurer.getInstance().measureType) {
      this.isFinish = true;
    }

    status.measureRunning.isMeasuring = false;

    hilog.debug(122, 'MeasureFlow', '测量结果：iRef = %{public}d，iMea = %{public}d，fRef = %{public}d，fMea = %{public}d，A = %{public}d，C = %{public}d',
      measureAD.initReference, measureAD.initMeasure, measureAD.finalReference, measureAD.finalMeasure, this.absorbance, this.consistency);
  }

  SafeResultGenerate(): void {
    const curveK = config.measureParam.curveParam[this.currentRange]?.curveK || 0;
    const curveB = config.measureParam.curveParam[this.currentRange]?.curveB || 0;
    const random = 2 * (Math.random() - 0.5) * setting.measureResult.resultWaveRange;

    let consistency = (status.measureStatus.report.measure.consistency || 0) + random;
    const oldConsistency = consistency / (config.measureParam.reviseParameter[this.currentRange] || 1);
    const absorbance = oldConsistency * curveK + curveB;

    let resultMark = ResultMark.N;
    this.reportMode = config.interconnection.reportMode as ReportMode;

    if (this.reportMode === ReportMode.OnLine) {
      if (this.measureType === MeasureType.Sample) {
        if (consistency > config.interconnection.meaUpLimit && config.interconnection.overProofResultMark === 1) {
          resultMark = ResultMark.T;
          this.isOverProof = true;
        } else if (consistency > (config.system.rangeViewMap?.[this.currentRange]?.view || 0)) {
          resultMark = ResultMark.E;
        }
      } else if (this.measureType === MeasureType.RangeCheck || this.measureType === MeasureType.ZeroCheck) {
        resultMark = ResultMark.C;
      } else if (this.measureType === MeasureType.QualityHandle) {
        resultMark = ResultMark.K;
      }
    } else if (this.reportMode === ReportMode.OffLine) {
      resultMark = ResultMark.B;
    } else if (this.reportMode === ReportMode.Maintain) {
      resultMark = ResultMark.M;
    } else if (this.reportMode === ReportMode.Fault) {
      resultMark = ResultMark.D;
    } else if (this.reportMode === ReportMode.Calibrate) {
      resultMark = ResultMark.C;
    } else if (this.reportMode === ReportMode.Debugging) {
      resultMark = ResultMark.A;
    }

    const record: MeasureData = {
      dateTime: this.measureDateTime,
      consistency: this.consistency,
      absorbance: this.absorbance,
      mode: resultMark,
      resultType: this.measureType,
      initReferenceAD: 0,
      initMeasureAD: 0,
      finalReferenceAD: 0,
      finalMeasureAD: 0,
      initThermostatTemp: 0,
      initEnvironmentTemp: 0,
      finalThermostatTemp: 0,
      finalEnvironmentTemp: 0,
      initConsistency: 0,
      measureTime: DateTimeUtil.getTimestamp() - this.measureDateTime,
      addStandardConsistency: config.measureParam.curveParam[this.currentRange]?.rangeConsistency || 0,
      measureRange: this.currentRange,
    };
    this.lastMeasureRecord = record;

    hilog.debug(122, 'MeasureFlow', '安全测量结果：A = %{public}d，C = %{public}d', absorbance, consistency);
    this.isFinish = true;
  }

  FaultGetLastTimeResult(): void {
    const consistency = status.measureStatus.newResult.measure.consistency;
    const absorbance = status.measureStatus.newResult.measure.absorbance;
    
    hilog.debug(122, 'MeasureFlow', '流程错误，测量结果生成：A = %{public}d，C = %{public}d', absorbance, consistency);
  }

  AdjustMeasureDateTime(meaDateTime: number): number {
    let newTime = meaDateTime;

    const minute = new Date(meaDateTime * 1000).getMinutes();
    const second = new Date(meaDateTime * 1000).getSeconds();

    if (minute >= 58) {
      newTime = meaDateTime - minute * 60 - second + 3600;
    } else if (minute > 0 && minute <= 20) {
      newTime = meaDateTime - minute * 60 - second;
    } else if (minute === 0 && second > 0) {
      newTime = meaDateTime - second;
    }

    return newTime;
  }
  exportConfig(): MeasureConfig{
    return {
      measureType: this.measureType,
      currentRange: this.currentRange,
      addParam: this.addParam,
      measureResult: this.measureResult
    }
  }

  private  updateRangeConfigFromSource(target: RangeConfig, source: Partial<RangeConfig>): void {
    target.viewRange = source.viewRange;
    target.rangeWindowMin = source.rangeWindowMin ?? 0;
    target.rangeWindowMax = source.rangeWindowMax ?? 0;
    target.sampleVolume = source.sampleVolume ?? 0;
    target.standardVolume = source.standardVolume ?? 0;
    target.zeroCheckVolume = source.zeroCheckVolume ?? 0;
    target.rangeCheckVolume = source.rangeCheckVolume ?? 0;
    target.blankVolume = source.blankVolume ?? 0;
    target.dilutionExtractVolume1 = source.dilutionExtractVolume1 ?? 0;
    target.dilutionAddBlankVolume1 = source.dilutionAddBlankVolume1 ?? 0;
    target.dilutionExtractVolume2 = source.dilutionExtractVolume2 ?? 0;
    target.dilutionAddBlankVolume2 = source.dilutionAddBlankVolume2 ?? 0;
    target.dilutionExtractVolume3 = source.dilutionExtractVolume3 ?? 0;
    target.dilutionAddBlankVolume3 = source.dilutionAddBlankVolume3 ?? 0;
    target.afterReagent1AddBlankVolume = source.afterReagent1AddBlankVolume ?? 0;
    target.rinseEnable = source.rinseEnable ?? false;
    target.rinseSampleVolume = source.rinseSampleVolume ?? 0;
    target.rinseStandardVolume = source.rinseStandardVolume ?? 0;
    target.rinseZeroCheckVolume = source.rinseZeroCheckVolume ?? 0;
    target.rinseRangeCheckVolume = source.rinseRangeCheckVolume ?? 0;
    target.rinseBlankVolume = source.rinseBlankVolume ?? 0;
    target.diluteFactor = source.diluteFactor ?? 0;
    target.excursion = source.excursion ?? 0;
  }

}