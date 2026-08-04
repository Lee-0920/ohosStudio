import { hilog } from "@kit.PerformanceAnalysisKit";
import { Flow } from './Flow';
import { DateTimeUtil } from 'base';
import { Measurer, MeasureResult} from './Measurer';
import { MeasureAD } from '../Common/MeasureAD';
import { config, status } from '../Config/Config';
import { setting, ResultMarkC } from '../Setting/Setting';
import { MeasureType } from './FlowInterface';
import { DatabaseManager, CaliData } from '../DataManager/DataBase';

export enum CalibrateType {
  calibrate = 0,
  oneKeyMaintain = 1,
  onlyCalibrateBlank = 2,
  onlyCalibrateStandard = 3,
}

/** 根据校准类型获取 Modbus 系统状态码 */
function getCalibrateSystemStatusCode(calibrateType: CalibrateType): number {
  switch (calibrateType) {
    case CalibrateType.onlyCalibrateBlank:
      return 29; // 零点校准
    case CalibrateType.onlyCalibrateStandard:
      return 30; // 量程校准
    case CalibrateType.calibrate:
    case CalibrateType.oneKeyMaintain:
    default:
      return 4; // 校准中
  }
}

export class CalibrateFlow extends Flow {
  calibrateType: CalibrateType = CalibrateType.calibrate;
  calibrateDateTime: number = 0;
  zeroCalibrateDateTime: number = 0;
  standardCalibrateDateTime: number = 0;
  measureBlank: boolean = true;
  measureStandard: boolean = true;
  currentRange: number = 1;
  isUseStart: boolean = false;
  curveCalibrateRange: number = 0;
  lastResultInfo: string = "N";
  diluteFactor: number = 1;
  isFinish: boolean = false;
  measure:Measurer = Measurer.getInstance();
  private currentStatusLabel: string = '';
  private currentStatusTotalSeconds: number = 0;
  // 本次测量生成的记录，由 worker 抛回主线程后统一入库
  lastCalibrateRecord: CaliData | null = null;


  constructor(name: string, caliType: CalibrateType) {
    super(name);
    this.calibrateDateTime = DateTimeUtil.getTimestamp();
    const calibrateRangeIndex = config.measureParam.calibrateRangeIndex;
    const rangeIndex = config.measureParam.range[calibrateRangeIndex + 1] + 1;
    this.zeroCalibrateDateTime = status.measureStatus.calibrate[rangeIndex].zeroCalibrateDateTime;
    this.standardCalibrateDateTime = status.measureStatus.calibrate[rangeIndex].standardCalibrateDateTime;
    this.calibrateType = caliType;
    this.currentRange = rangeIndex;
    this.isUseStart = false;
    this.curveCalibrateRange = 0;
    this.lastResultInfo = status.measureStatus.newResult.measure.resultInfo;
    this.diluteFactor = 1;
  }

  GetRuntime(): number {
    let runtime = 0;
    if (this.curveCalibrateRange == 1) {
      runtime = setting.runStatus.range1CurveCalibrate.GetTime?.() || 0;
    } else if (this.curveCalibrateRange == 2) {
      runtime = setting.runStatus.range2CurveCalibrate.GetTime?.() || 0;
    } else if (this.curveCalibrateRange == 3) {
      runtime = setting.runStatus.range3CurveCalibrate.GetTime?.() || 0;
    } else {
      if (this.calibrateType == CalibrateType.calibrate) {
        runtime = setting.runStatus.calibrate.GetTime?.() || 0;
      } else if (this.calibrateType == CalibrateType.oneKeyMaintain) {
        runtime = setting.runStatus.oneKeyMaintain.GetTime?.() || 0;
        this.isUseStart = true;
      } else if (this.calibrateType == CalibrateType.onlyCalibrateBlank) {
        runtime = setting.runStatus.onlyCalibrateBlank.GetTime?.() || 0;
      } else if (this.calibrateType == CalibrateType.onlyCalibrateStandard) {
        runtime = setting.runStatus.onlyCalibrateStandard.GetTime?.() || 0;
      }
    }
    return runtime;
  }

  OnStart(): void {
    if (config.system.oem == 1 && this.calibrateType == CalibrateType.oneKeyMaintain) {
      this.calibrateType = CalibrateType.calibrate;
    }

    this.calibrateDateTime = DateTimeUtil.getTimestamp();

    status.measureStatus.isUseStart = this.isUseStart;
    status.measureStatus.newResult.measure.resultInfo = "C";
    status.measureStatus.newResult.measure.resultMarkC = ResultMarkC.Cz;

    let runStatus: string = "";
    if (this.curveCalibrateRange == 1) {
      runStatus = setting.runStatus.range1CurveCalibrate.name;
      this.currentRange = config.measureParam.range[0] + 1;
    } else if (this.curveCalibrateRange == 2) {
      runStatus = setting.runStatus.range2CurveCalibrate.name;
      this.currentRange = config.measureParam.range[1] + 1;
    } else if (this.curveCalibrateRange == 3) {
      runStatus = setting.runStatus.range3CurveCalibrate.name;
      this.currentRange = config.measureParam.range[2] + 1;
    } else {
      if (this.calibrateType == CalibrateType.oneKeyMaintain) {
        runStatus = setting.runStatus.oneKeyMaintain.name;
        this.currentRange = config.measureParam.range[config.measureParam.calibrateRangeIndex + 1] + 1;
      } else if (this.calibrateType == CalibrateType.onlyCalibrateBlank) {
        runStatus = setting.runStatus.onlyCalibrateBlank.name;
        this.currentRange = config.measureParam.range[config.measureParam.calibrateRangeIndex + 1] + 1;
      } else if (this.calibrateType == CalibrateType.onlyCalibrateStandard) {
        runStatus = setting.runStatus.onlyCalibrateStandard.name;
        this.currentRange = config.measureParam.range[config.measureParam.calibrateRangeIndex + 1] + 1;
      } else {
        runStatus = setting.runStatus.calibrate.name;
      }
    }

    hilog.info(122, 'CalibrateFlow', 'OnStart: runStatus=%{public}s', runStatus);
  }

  OnProcess(): void {
    hilog.info(122, 'CalibrateFlow', 'OnProcess Start');
    const absorbance: number[] = [0, 0];
    const consistency: number[] = [
      config.measureParam.curveParam[this.currentRange].zeroConsistency,
      config.measureParam.curveParam[this.currentRange].rangeConsistency
    ];
    const addParam = [setting.calibrate[0], setting.calibrate[1]];

    let measureResult1 = this.measure.GetZeroMeasureResult();
    let measureResult2 = this.measure.GetZeroMeasureResult();
    const measureAD1 = new MeasureAD();
    const measureAD2 = new MeasureAD();
    let curveK = 1;
    let curveB = 0;
    const meausureConsistency: number[] = [];
    const checkError: number[] = [];
    let oneTimesCreateCurve = false;
    const currentWorkRange = config.measureParam.range[config.measureParam.currentRange + 1] + 1;
    this.isUserStop = false;
    this.isFinish = false;

    // 根据校准类型设置底部状态栏显示的状态覆盖，避免显示成默认的"测量零点/量程校准液"
    this.updateStatusOverride();

    this.CleanDeeplyCheckTime();

    if (this.curveCalibrateRange > 0) {
      if (status.measureStatus.standardCurve > 0) {
        this.measureBlank = false;
        this.measureStandard = true;
        absorbance[0] = status.measureStatus.calibrate[status.measureStatus.standardCurve].point0Absorbance;
      } else {
        hilog.info(122, 'CalibrateFlow', '不存在基准标线，无法进行量程系数校正');
        return;
      }
    } else {
      if (this.calibrateType == CalibrateType.oneKeyMaintain) {
        oneTimesCreateCurve = true;
        this.PipeRenew();
      } else if (this.calibrateType == CalibrateType.onlyCalibrateBlank) {
        this.measureBlank = true;
        this.measureStandard = false;
        absorbance[1] = status.measureStatus.calibrate[this.currentRange].point1Absorbance;
      } else if (this.calibrateType == CalibrateType.onlyCalibrateStandard) {
        this.measureBlank = false;
        this.measureStandard = true;
        absorbance[0] = status.measureStatus.calibrate[this.currentRange].point0Absorbance;
      }
    }

    const timeRecord = DateTimeUtil.getTimestamp();
    if (this.measureBlank && this.measureStandard) {
      this.zeroCalibrateDateTime = timeRecord;
      this.standardCalibrateDateTime = timeRecord;
    } else if (!this.measureBlank && this.measureStandard) {
      this.standardCalibrateDateTime = timeRecord;
    } else if (this.measureBlank && !this.measureStandard) {
      this.zeroCalibrateDateTime = timeRecord;
    }

    if (config.system.rangeViewMap && config.system.rangeViewMap[this.currentRange]?.view !== undefined) {
      hilog.debug(122, 'CalibrateFlow', '当前量程 = 0 ~ %{public}d', config.system.rangeViewMap[this.currentRange].view);
    }

    if (this.measureBlank) {
      hilog.debug(122, 'CalibrateFlow', '校准-零点测量');
      if (this.measure.flow) {
        this.measure.Reset();
      }
      this.measure.flow = this;
      this.measure.measureType = MeasureType.Blank;
      this.measure.currentRange = this.currentRange;

      this.measure.addParam = addParam[0];

      const rangeConfig = setting.measureRange[this.currentRange];
      this.measure.addParam.standardVolume = 0;
      this.measure.addParam.blankVolume = (rangeConfig.blankVolume || 0) + (rangeConfig.sampleVolume || 0);
      this.measure.addParam.dilutionExtractVolume1 = rangeConfig.dilutionExtractVolume1 || 0;
      this.measure.addParam.dilutionAddBlankVolume1 = rangeConfig.dilutionAddBlankVolume1 || 0;
      this.measure.addParam.dilutionExtractVolume2 = rangeConfig.dilutionExtractVolume2 || 0;
      this.measure.addParam.dilutionAddBlankVolume2 = rangeConfig.dilutionAddBlankVolume2 || 0;
      this.measure.addParam.dilutionExtractVolume3 = rangeConfig.dilutionExtractVolume3 || 0;
      this.measure.addParam.dilutionAddBlankVolume3 = rangeConfig.dilutionAddBlankVolume3 || 0;
      this.measure.addParam.diluteFactor = rangeConfig.diluteFactor || 1;
      this.measure.addParam.rinseSampleVolume = 0;
      this.measure.addParam.rinseBlankVolume = (rangeConfig.rinseStandardVolume || 0) + (rangeConfig.rinseSampleVolume || 0);
      this.measure.addParam.rinseStandardVolume = 0;

      // 重新设置状态覆盖，防止前面 measure.Measure() 的 finally 清除了覆盖状态
      this.measure.setStatusOverride(
        this.currentStatusLabel,
        this.currentStatusTotalSeconds,
        getCalibrateSystemStatusCode(this.calibrateType)
      );

      try {
        const result = this.measure.Measure();
        measureAD1.initReference = result.initReferenceAD;
        measureAD1.initMeasure = result.initMeasureAD;
        measureAD1.finalReference = result.finalReferenceAD;
        measureAD1.finalMeasure = result.finalMeasureAD;

        absorbance[0] = measureAD1.CalculateRelAbsorbance();
        if (absorbance[0] == 0) {
          absorbance[0] = setting.measureResult.zeroReviseValue;
        }
        measureResult1 = result;

        status.measureStatus.newResult.measure.resultMarkC = ResultMarkC.Cz;
        meausureConsistency[0] = this.CalculateConsistency(absorbance[0], this.diluteFactor);
        const StdConsistency = config.measureParam.curveParam[this.currentRange].zeroConsistency;
        const currentViewRange = config.system.rangeViewMap[currentWorkRange]?.view || 1;

        if (status.measureStatus.newResult.calibrate.zeroCalculateConsistency !== undefined) {
          checkError[0] = (meausureConsistency[0] - status.measureStatus.newResult.calibrate.zeroCalculateConsistency) / currentViewRange;
        } else {
          checkError[0] = Math.abs(meausureConsistency[0] - StdConsistency) / (config.system.rangeViewMap[this.currentRange]?.view || 1);
        }

        hilog.debug(122, 'CalibrateFlow', '零点计算浓度 = %{public}d，偏差为 %{public}d %%', meausureConsistency[0], checkError[0] * 100);

        if (config.measureParam.zeroAccurateCalibrate) {
          const reviseAbsorbance = this.AccurateCalibrate(absorbance[0], setting.common.zeroCalibrateWaveRange);
          absorbance[0] = reviseAbsorbance;
        }
      } catch (err) {
        this.isUserStop = true;
        hilog.error(122, 'CalibrateFlow', '零点测量异常: %{public}s', String(err));
        throw new Error(err);
      }
    }

    if (this.measureStandard) {
      this.standardCalibrateDateTime = DateTimeUtil.getTimestamp();
      hilog.debug(122, 'CalibrateFlow', '校准-标点测量');

      if (this.measure.flow) {
        this.measure.Reset();
      }
      this.measure.flow = this;
      this.measure.measureType = MeasureType.Standard;
      this.measure.currentRange = this.currentRange;

      const rangeConfig = setting.measureRange[this.currentRange];
      this.measure.addParam.standardVolume = rangeConfig.sampleVolume || 0;
      this.measure.addParam.blankVolume = rangeConfig.blankVolume || 0;
      this.measure.addParam.dilutionExtractVolume1 = rangeConfig.dilutionExtractVolume1 || 0;
      this.measure.addParam.dilutionAddBlankVolume1 = rangeConfig.dilutionAddBlankVolume1 || 0;
      this.measure.addParam.dilutionExtractVolume2 = rangeConfig.dilutionExtractVolume2 || 0;
      this.measure.addParam.dilutionAddBlankVolume2 = rangeConfig.dilutionAddBlankVolume2 || 0;
      this.measure.addParam.dilutionExtractVolume3 = rangeConfig.dilutionExtractVolume3 || 0;
      this.measure.addParam.dilutionAddBlankVolume3 = rangeConfig.dilutionAddBlankVolume3 || 0;
      this.measure.addParam.afterReagent1AddBlankVolume = rangeConfig.afterReagent1AddBlankVolume || 0;
      this.measure.addParam.diluteFactor = rangeConfig.diluteFactor || 1;
      this.measure.addParam.rinseSampleVolume = 0;
      this.measure.addParam.rinseBlankVolume = 0;
      this.measure.addParam.rinseStandardVolume = (rangeConfig.rinseStandardVolume || 0) + (rangeConfig.rinseSampleVolume || 0);

      // 重新设置状态覆盖，防止前面 measure.Measure() 的 finally 清除了覆盖状态
      this.measure.setStatusOverride(
        this.currentStatusLabel,
        this.currentStatusTotalSeconds,
        getCalibrateSystemStatusCode(this.calibrateType)
      );

      try {
        const result = this.measure.Measure();
        measureAD2.initReference = result.initReferenceAD;
        measureAD2.initMeasure = result.initMeasureAD;
        measureAD2.finalReference = result.finalReferenceAD;
        measureAD2.finalMeasure = result.finalMeasureAD;

        absorbance[1] = measureAD2.CalculateRelAbsorbance();
        measureResult2 = result;

        meausureConsistency[1] = this.CalculateConsistency(absorbance[1], this.diluteFactor);
        status.measureStatus.newResult.measure.resultMarkC = ResultMarkC.Cr;
        const StdConsistency = config.measureParam.curveParam[this.currentRange].rangeConsistency;
        const currentViewRange = config.system.rangeViewMap[this.currentRange]?.view || 1;

        if (status.measureStatus.newResult.calibrate.standardCalculateConsistency !== undefined) {
          checkError[1] = (meausureConsistency[1] - status.measureStatus.newResult.calibrate.standardCalculateConsistency) / (config.system.rangeViewMap[currentWorkRange]?.view || 1);
        } else {
          checkError[1] = Math.abs(meausureConsistency[1] - StdConsistency) / currentViewRange;
        }

        hilog.debug(122, 'CalibrateFlow', '标点计算浓度 = %{public}d，偏差为 %{public}d %%', meausureConsistency[1], checkError[1] * 100);

        if (config.measureParam.standardAccurateCalibrate) {
          const reviseAbsorbance = this.AccurateCalibrate(absorbance[1], setting.common.standardCalibrateWaveRange);
          absorbance[1] = reviseAbsorbance;
        }
      } catch (err) {
        this.isUserStop = true;
        hilog.error(122, 'CalibrateFlow', '标点测量异常: %{public}s', String(err));
        throw new Error(err);
      }
    }

    if (this.calibrateType == CalibrateType.oneKeyMaintain || this.calibrateType == CalibrateType.calibrate) {
      status.measureStatus.standardCurve = this.currentRange;
    }

    const calibrateRange = this.currentRange;
    const rangeTable: number[] = [this.currentRange];

    if (oneTimesCreateCurve) {
      rangeTable.shift();
      for (let i = 1; i <= setting.measureRange.length; i++) {
        if (i != this.currentRange) {
          rangeTable.push(i);
        }
      }
      rangeTable.push(this.currentRange);
    }

    for (let i = 0; i < rangeTable.length; i++) {
      const range = rangeTable[i];
      let showAbsorbance = [absorbance[0], absorbance[1]];

      if (oneTimesCreateCurve) {
        this.currentRange = range;
        const curveParam = config.measureParam.curveParam[this.currentRange];
        consistency[0] = curveParam.zeroConsistency;
        consistency[1] = curveParam.rangeConsistency;

        absorbance[1] = absorbance[0]
          + ((absorbance[1] - absorbance[0]) / (setting.measureRange[calibrateRange].diluteFactor || 1))
          * (setting.measureRange[this.currentRange].diluteFactor || 1)
          * consistency[1]
          * (config.measureParam.reviseParameter[this.currentRange] || 1)
          / (config.measureParam.curveParam[calibrateRange].rangeConsistency || 1)
          / (config.measureParam.reviseParameter[calibrateRange] || 1);

        if (this.currentRange != calibrateRange) {
          showAbsorbance = [0, 0];
        } else {
          showAbsorbance = [absorbance[0], absorbance[1]];
        }
      }

      if (Math.abs(consistency[1] - consistency[0]) < 0.000001) {
        hilog.info(122, 'CalibrateFlow', '斜率结果计算异常');
        throw new Error('CalibrateResultWrongException');
      } else {
        curveK = (absorbance[1] - absorbance[0]) / (consistency[1] - consistency[0]);
        curveB = absorbance[1] - curveK * consistency[1];
      }

      if (this.curveCalibrateRange > 0) {
        config.measureParam.reviseParameter[this.currentRange] = this.CalculateReviseParam(absorbance[1]);
      }

      let curveQualified = false;
      if (config.measureParam.curveQualifiedDetermination) {
        const curveConfig = setting.measureResult.curve[this.currentRange];
        if (curveK > curveConfig.curveKUpLimit || curveK < curveConfig.curveKLowLimit) {
          hilog.warn(122, 'CalibrateFlow', 'curveK = %{public}d, 斜率合理范围为 %{public}d ~ %{public}d，斜率异常',
            curveK, curveConfig.curveKLowLimit, curveConfig.curveKUpLimit);
          curveQualified = true;
        }
      }

      const record:CaliData = {
        dateTime: this.calibrateDateTime,   // 校准时间戳
        curveK: curveK,                     // 斜率（Double类型，8字节）
        curveB: curveB,                     // 截距（Double类型，8字节）
        // 0点数据
        point0InitAbsorbance: 0,       // 0点空白吸光度
        point0Absorbance: showAbsorbance[0],           // 0点显色吸光度
        point0Consistency: consistency[0],          // 0点浓度
        initReferenceAD0: measureResult1.initReferenceAD,           // 0点空白参考AD
        initMeasureAD0: measureResult1.initMeasureAD,             // 0点空白测量AD
        finalReferenceAD0: measureResult1.finalReferenceAD,          // 0点显色参考AD
        finalMeasureAD0: measureResult1.finalMeasureAD,            // 0点显色测量AD
        point0InitThermostatTemp: measureResult1.initThermostatTemp,   // 0点空白消解室温度
        point0InitEnvironmentTemp: measureResult1.initEnvironmentTemp,  // 0点空白环境温度
        point0FinalThermostatTemp: measureResult1.finalThermostatTemp,  // 0点显色消解室温度
        point0FinalEnvironmentTemp: measureResult1.finalEnvironmentTemp, // 0点显色环境温度
        // 1点数据
        point1InitAbsorbance: 0,       // 1点空白吸光度
        point1Absorbance: showAbsorbance[1],           // 1点显色吸光度
        point1Consistency: consistency[1],          // 1点浓度
        initReferenceAD1: measureResult2.initReferenceAD,           // 1点空白参考AD
        initMeasureAD1: measureResult2.initMeasureAD,             // 1点空白测量AD
        finalReferenceAD1: measureResult2.finalReferenceAD,          // 1点显色参考AD
        finalMeasureAD1: measureResult2.finalMeasureAD,            // 1点显色测量AD
        point1InitThermostatTemp: measureResult2.initThermostatTemp,   // 1点空白消解室温度
        point1InitEnvironmentTemp: measureResult2.initEnvironmentTemp,  // 1点空白环境温度
        point1FinalThermostatTemp: measureResult2.finalThermostatTemp,  // 1点显色消解室温度
        point1FinalEnvironmentTemp: measureResult2.finalEnvironmentTemp, // 1点显色环境温度

        R2: 1,                         // 曲线线性度
        calibrateTime: DateTimeUtil.getTimestamp() - this.calibrateDateTime,              // 校准时长
        measureRange: config.system.rangeViewMap[this.currentRange].view,               // 量程 (v2新增)
      };
      this.lastCalibrateRecord = record;

      console.info(`CalibrateFlow ${JSON.stringify(record)}`);

      // DatabaseManager.getInstance().addCalibrateRecord(record);

      hilog.debug(122, 'CalibrateFlow', '保存量程 %{public}d, 校准结果，K：%{public}d B：%{public}d',
        this.currentRange, curveK, curveB);

      this.isFinish = true;

      if (this.measureBlank) {
        hilog.debug(122, 'CalibrateFlow',
          '校准-零点 iRef = %{public}d, iMea = %{public}d, fRef = %{public}d, fMea = %{public}d, A = %{public}d',
          measureResult1.initReferenceAD, measureResult1.initMeasureAD,
          measureResult1.finalReferenceAD, measureResult1.finalMeasureAD, absorbance[0]);
      }
      if (this.measureStandard) {
        hilog.debug(122, 'CalibrateFlow',
          '校准-标点 iRef = %{public}d, iMea = %{public}d, fRef = %{public}d, fMea = %{public}d, A = %{public}d',
          measureResult2.initReferenceAD, measureResult2.initMeasureAD,
          measureResult2.finalReferenceAD, measureResult2.finalMeasureAD, absorbance[1]);
      }
      hilog.debug(122, 'CalibrateFlow', '曲线 k = %{public}d B = %{public}d', curveK, curveB);
    }

    hilog.info(122, 'CalibrateFlow', 'OnProcess End');
  }

  OnStop(): void {
    hilog.info(122, 'CalibrateFlow', 'OnStop');

    if (this.calibrateType == CalibrateType.calibrate || this.calibrateType == CalibrateType.oneKeyMaintain) {
      status.measureStatus.schedule.autoCalibrate.dateTime = this.calibrateDateTime;
    }

    if (!this.isFinish) {
      status.measureStatus.newResult.measure.isFault = true;
      if (this.isUserStop) {
        status.measureStatus.newResult.measure.resultInfo = this.lastResultInfo;
        this.result = "用户终止";
        hilog.info(122, 'CalibrateFlow', '用户终止');
      } else {
        status.measureStatus.newResult.measure.resultInfo = "D";
        this.result = "故障终止";
        hilog.warn(122, 'CalibrateFlow', '故障终止');
      }
    } else {
      status.measureStatus.newResult.measure.isFault = false;
      let flowStr = "校准";
      if (this.calibrateType == CalibrateType.oneKeyMaintain) {
        flowStr = "一键校准";
      } else if (this.calibrateType == CalibrateType.onlyCalibrateBlank) {
        flowStr = "零点校准";
      } else if (this.calibrateType == CalibrateType.onlyCalibrateStandard) {
        flowStr = "量程校准";
      }

      this.result = flowStr + "完成";
      hilog.info(122, 'CalibrateFlow', this.result);
      hilog.info(122, 'CalibrateFlow', '%{public}s总时间 = %{public}d', flowStr, DateTimeUtil.getTimestamp() - this.calibrateDateTime);
    }

    status.measureStatus.isUseStart = false;
  }


  AccurateCalibrate(refAbs: number, waveRange: number): number {
    const measureAD = new MeasureAD();
    let tempAbsorbance1 = refAbs;
    let tempAbsorbance2: number;
    let tempAbsorbance3: number;
    let absorbance: number;

    hilog.debug(122, 'CalibrateFlow', '第1次校准测量吸光度 Absorbance = %{public}d', tempAbsorbance1);

    // 精确校准仍属于当前校准流程，重新设置状态覆盖
    this.measure.setStatusOverride(
      this.currentStatusLabel,
      this.currentStatusTotalSeconds,
      getCalibrateSystemStatusCode(this.calibrateType)
    );

    try {
      const result = this.measure.Measure();
      measureAD.initReference = result.initReferenceAD;
      measureAD.initMeasure = result.initMeasureAD;
      measureAD.finalReference = result.finalReferenceAD;
      measureAD.finalMeasure = result.finalMeasureAD;

      tempAbsorbance2 = measureAD.CalculateRelAbsorbance();
      hilog.debug(122, 'CalibrateFlow', '第2次校准测量吸光度 Absorbance = %{public}d', tempAbsorbance2);
    } catch (err) {
      this.isUserStop = true;
      throw new Error(err);
    }

    const deviation12 = Math.abs(tempAbsorbance1 - tempAbsorbance2);
    if (deviation12 < waveRange) {
      absorbance = (tempAbsorbance1 + tempAbsorbance2) / 2;
      hilog.debug(122, 'CalibrateFlow', '吸光度平均修正 Absorbance = %{public}d', absorbance);
    } else {
      try {
        const result = this.measure.Measure();
        measureAD.blankReference = result.initReferenceAD - result.darkReferenceAD;
        measureAD.blankMeasure = result.initMeasureAD - result.darkMeasureAD;
        measureAD.finalReference = result.finalReferenceAD - result.darkReferenceAD;
        measureAD.finalMeasure = result.finalMeasureAD - result.darkMeasureAD;

        tempAbsorbance3 = measureAD.CalculateRelAbsorbance();
        hilog.debug(122, 'CalibrateFlow', '第3次校准测量吸光度 Absorbance = %{public}d', tempAbsorbance3);

        const deviation13 = Math.abs(tempAbsorbance1 - tempAbsorbance3);
        const deviation23 = Math.abs(tempAbsorbance2 - tempAbsorbance3);

        if (deviation13 >= waveRange && deviation23 >= waveRange) {
          absorbance = (tempAbsorbance1 + tempAbsorbance2 + tempAbsorbance3) / 3;
          hilog.debug(122, 'CalibrateFlow', '吸光度123平均修正 Absorbance = %{public}d', absorbance);
        } else {
          if (deviation13 < deviation23) {
            absorbance = (tempAbsorbance1 + tempAbsorbance3) / 2;
            hilog.debug(122, 'CalibrateFlow', '吸光度13平均修正 Absorbance = %{public}d', absorbance);
          } else {
            absorbance = (tempAbsorbance2 + tempAbsorbance3) / 2;
            hilog.debug(122, 'CalibrateFlow', '吸光度23平均修正 Absorbance = %{public}d', absorbance);
          }
        }
      } catch (err) {
        this.isUserStop = true;
        throw new Error(err);
      }
    }

    return absorbance;
  }

  CalculateConsistency(absorbance: number, diluteFactor: number): number {
    let consistency = 0;
    const curveK = config.measureParam.curveParam[this.currentRange].curveK;
    const curveB = config.measureParam.curveParam[this.currentRange].curveB;

    if (Math.abs(curveK) < 0.00001) {
      hilog.debug(122, 'CalibrateFlow', '校准数值异常');
      return 0;
    }
    hilog.debug(122, 'CalibrateFlow', '当前计算标线 K = %{public}d, B = %{public}d', curveK, curveB);
    consistency = (absorbance - curveB) / curveK;
    consistency = consistency * diluteFactor;

    return consistency;
  }

  PipeRenew(): void {
    hilog.debug(122, 'CalibrateFlow', 'PipeRenew');
  }

  CleanDeeplyCheckTime(): void {

      hilog.debug(122, 'CalibrateFlow', '初次使用仪器，进行深度清洗');
      // TODO
  }

  /**
   * 根据当前校准类型更新状态覆盖信息。
   * 用于让底部进度条显示"校准"/"零点校准"/"量程校准"/"一键校准"，
   * 而不是 Measurer 默认映射出的"测量零点/量程校准液"。
   */
  private updateStatusOverride(): void {
    switch (this.calibrateType) {
      case CalibrateType.oneKeyMaintain:
        this.currentStatusLabel = setting.runStatus.oneKeyMaintain.text;
        this.currentStatusTotalSeconds = setting.runStatus.oneKeyMaintain.GetTime?.() ?? 0;
        break;
      case CalibrateType.onlyCalibrateBlank:
        this.currentStatusLabel = setting.runStatus.onlyCalibrateBlank.text;
        this.currentStatusTotalSeconds = setting.runStatus.onlyCalibrateBlank.GetTime?.() ?? 0;
        break;
      case CalibrateType.onlyCalibrateStandard:
        this.currentStatusLabel = setting.runStatus.onlyCalibrateStandard.text;
        this.currentStatusTotalSeconds = setting.runStatus.onlyCalibrateStandard.GetTime?.() ?? 0;
        break;
      case CalibrateType.calibrate:
      default:
        this.currentStatusLabel = setting.runStatus.calibrate.text;
        this.currentStatusTotalSeconds = setting.runStatus.calibrate.GetTime?.() ?? 0;
        break;
    }
    this.measure.setStatusOverride(
      this.currentStatusLabel,
      this.currentStatusTotalSeconds,
      getCalibrateSystemStatusCode(this.calibrateType)
    );
  }

  CalculateReviseParam(absorbance: number): number {
    const standardCurve = status.measureStatus.standardCurve;
    const calibrateStandard = status.measureStatus.calibrate[standardCurve];
    const absorbancess = (calibrateStandard.point1Absorbance - calibrateStandard.point0Absorbance)
      * (setting.measureRange[standardCurve].diluteFactor || 1)
      / config.measureParam.curveParam[standardCurve].rangeConsistency
      / (config.measureParam.reviseParameter[standardCurve] || 1);

    const reviseParameter = (absorbance - calibrateStandard.point0Absorbance)
      * (setting.measureRange[this.currentRange].diluteFactor || 1)
      / absorbancess
      / config.measureParam.curveParam[this.currentRange].rangeConsistency;

    hilog.debug(122, 'CalibrateFlow', '基准线为量程 %{public}d, 校正量程为 %{public}d, 校正系数计算结果 = %{public}d',
      standardCurve, this.currentRange, reviseParameter);

    return reviseParameter;
  }

  ProformaResultHandle(result: MeasureResult): void {
    //校准流程不做处理
  }

  ResultHandle(result: MeasureResult): void {
    if (false == config.measureParam.addCalibrateRecord) {
      return;
    }

    if (this.measure.measureType == MeasureType.Blank) {
      status.measureStatus.newResult.measure.resultType = MeasureType.Blank;
    } else if (this.measure.measureType == MeasureType.Standard) {
      status.measureStatus.newResult.measure.resultType = MeasureType.Standard;
    }
  }
}
