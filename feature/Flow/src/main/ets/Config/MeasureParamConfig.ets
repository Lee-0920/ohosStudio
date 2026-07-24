import {
  MeasureParamConfig,
} from 'dataservice';
//
// export interface CurveParamItem {
//   curveK: number;           // 曲线斜率
//   curveB: number;           // 曲线截距
//   ZeroConsistency: number;  // 零点浓度
//   RangeConsistency: number; // 量程浓度
//   timeStr: string;          // 校准时间字符串
// }
//
// export interface CalibrateCheck {
//   zeroCheckErrorLimit: number;         // 零点允许偏差值
//   standardCheckErrorLimit: number;     // 标点允许偏差值
// }
//
// export interface MeasureLedAD {
//   reference: number;                // 参考通道AD值
//   measure: number;                  // 测量通道AD值
// };
//
// export interface MeasureParamConfig {
//   currentRange: number;                 // 当前量程（三量程）
//   calibrateRangeIndex: number;          // 校准量程索引
//   zeroCheckRangeIndex: number;          // 零点核查量程索引
//   rangeCheckRangeIndex: number;         // 标样(跨度)核查量程索引
//   range: number[];                      // 量程列表 [量程一, 量程二, 量程三]
//   timeStr: string;                      // 当前量程校准时间
//   ZeroConsistency: number;              // 当前量程零点校准液浓度
//   RangeConsistency: number;             // 当前量程量程校准液浓度
//   curveK: number;                       // 当前量程曲线斜率
//   curveB: number;                       // 当前量程曲线截距
//   currentRangeIndex: number;            // 当前量程索引
//   autoChangeRange: boolean;             // 量程自动切换
//   activeRangeMode: number;              // 量程自动切换后生效模式
//   highClMode: boolean;                  // 高氯模式
//   digestTemperature: number;            // 消解温度
//   digestTime: number;                   // 消解时间
//   reactTemperature: number;             // 反应温度
//   preDrainCoolingTemp: number;          // 排液温度
//   reactTime: number;                    // 反应时间
//   temperatureIncrement: number;         // 温度增量(加试剂二)
//   negativeRevise: boolean;              // 负值修正
//   reviseFactor: number;                 // 修正因子
//   shiftFactor: number;                  // 平移因子
//   meterLedAD: number[];                 // 测光LED AD值
//   measureLedAD: MeasureLedAD;
//   pidCtrl: boolean;                     // PID调光
//   calibratePointConsistency: number[];  // 标定浓度列表
//   range2StandardConsistency: number;    // 量程二校正液浓度
//   range3StandardConsistency: number;    // 量程三校正液浓度
//   range4StandardConsistency: number;    // 量程四校正液浓度
//   range5StandardConsistency: number;    // 量程五校正液浓度
//   range6StandardConsistency: number;    // 量程六校正液浓度
//   range7StandardConsistency: number;    // 量程七校正液浓度
//   cleanBefMeaBlankVol: number;          // 测量前清洗，零点校准液体积
//   cleanAftMeaBlankVol: number;          // 测量后清洗，零点校准液体积
//   wasteWaterEnvironment: boolean;       // 污水环境
//   tapWaterEnvironment: boolean;         // 自来水环境
//   cleanSampleVol: number;               // 加完水样后，零点校准液清洗水样管体积
//   extendSamplePipeVolume: number;       // 水样管延长体积
//   sampleRenewVolume: number;            // 样品更新体积
//   reagentUpdate: boolean;               // 试剂更新
//   zeroAccurateCalibrate: boolean;       // 零点精准校准
//   standardAccurateCalibrate: boolean;   // 标点精准校准
//   calibrateMarkOutput: boolean;         // 定标时是否输出零点与标点结果
//   rangeAccurateCalibrate: boolean;      // 量程精准校正
//   curveQualifiedDetermination: boolean; // 标线合格判定
//   rangeCalibrateDeviation: number;      // 量程精准校正偏差阈值
//   checkConsistency: number;             // 标样核查浓度
//   checkErrorLimit: number;              // 标样核查偏差限值
//   checkReporting: boolean;              // 核查上报
//   failAutoRevise: boolean;              // 核查失败自动校准
//   highlyOxidized: boolean;              // 强氧化模式
//   readInitSilentTime: number;           // 读空白值前静置时间
//   heaterMaxDutyCycle: number;           // 加热丝最大占空比
//   digestionFanLevel: number;            // 消解风扇功率等级
//   addCalibrateRecord: boolean;          // 定标时是否输出零点与标点结果(使用旧标线计算结果)
//   updateAllCalibrateKB: boolean;        // 定标更新所有曲线
//   curveParam: CurveParamItem[];         // 各量程曲线参数
//   reviseParameter: number[];            // 内部校正参数
//   measureDataOffsetValve: number;       // 测量数据偏移阀值
//   calibrateCheck: CalibrateCheck;       // 校准检查参数
// }

// 测量参数设置配置
export const measureParamConfig: MeasureParamConfig = {
  currentRange: 0,
  calibrateRangeIndex: 0,
  zeroCheckRangeIndex: 0,
  rangeCheckRangeIndex: 0,
  range: [0, 1, 2],
  timeStr: "--",
  zeroConsistency: 0,
  rangeConsistency: 0,
  curveK: 0,
  curveB: 0,
  currentRangeIndex: 1,
  autoChangeRange: false,
  activeRangeMode: 0,
  highClMode: false,
  digestTemperature: 165,
  digestTime: 900,
  reactTemperature: 60,
  //preDrainCoolingTemp: 70,
  reactTime: 0,
  digestAirPumpingTemp: 70,
  temperatureIncrement: 10,
  negativeRevise: true,
  reviseFactor: 1,
  shiftFactor: 0,
  meterLedAD: [3500, 3500],
  measureLedAD: {
    reference: 11000000,
    measure: 11000000,
  },
  pidCtrl: false,
  calibratePointConsistency: [0.0, 100.0, 100.0, 100.0, 500.0, 2500.0, 5000.0, 10000.0],
  range2StandardConsistency: 500,
  range3StandardConsistency: 2500,
  range4StandardConsistency: 500,
  range5StandardConsistency: 2500,
  range6StandardConsistency: 5000,
  range7StandardConsistency: 10000,
  cleanBefMeaBlankVol: 0,
  cleanAftMeaBlankVol: 16,
  sampleSoakExtendVol: 0,
  deepCleanBefCalibrate: false,
  wasteWaterEnvironment: true,
  tapWaterEnvironment: false,
  ignoreSampleAssertion: false,
  cleanSampleVol: 0,
  extendSamplePipeVolume: 0,
  sampleRenewVolume: 2,
  //reagentUpdate: false,
  zeroAccurateCalibrate: false,
  standardAccurateCalibrate: false,
  calibrateMarkOutput: false,
  rangeAccurateCalibrate: false,
  curveQualifiedDetermination: false,
  rangeCalibrateDeviation: 0.01,
  checkConsistency: 100,
  checkErrorLimit: 0.1,
  checkReporting: true,
  failAutoRevise: false,
  highlyOxidized: false,
  readInitRilentTime: 60,
  readFinalBubbling: false,
  heaterMaxDutyCycle: 0.22,
  digestionFanLevel: 1,
  addCalibrateRecord: false,
  updateAllCalibrateKB: false,
  curveParam: [
    { curveK: 1, curveB: 0, zeroConsistency: 0, rangeConsistency: 50, timeStr: "--" },
    { curveK: 1, curveB: 0, zeroConsistency: 0, rangeConsistency: 100, timeStr: "--" },
    { curveK: 1, curveB: 0, zeroConsistency: 0, rangeConsistency: 250, timeStr: "--" },
    { curveK: 1, curveB: 0, zeroConsistency: 0, rangeConsistency: 500, timeStr: "--" },
    { curveK: 1, curveB: 0, zeroConsistency: 0, rangeConsistency: 2500, timeStr: "--" },
    { curveK: 1, curveB: 0, zeroConsistency: 0, rangeConsistency: 5000, timeStr: "--" },
    { curveK: 1, curveB: 0, zeroConsistency: 0, rangeConsistency: 10000, timeStr: "--" },
  ],
  reviseParameter: [0, 0, 0, 0, 0, 0, 0],
  excursionSample: [0, 0, 0, 0, 0, 0, 0],
  diluteFactor: [0, 0, 0, 0, 0, 0, 0],
  measureDataOffsetValve: 0,
  calibrateCheck: {
    zeroCheckErrorLimit: 0.1,
    standardCheckErrorLimit: 0.1,
  },
};
