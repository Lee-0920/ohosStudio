
import { AlarmConfig, alarm, alarm_sc } from './Alarm';
import { LiquidTypes, liquidTypes } from './LiquidType';
import { ModbusCoderType, modbusCoder } from './ModbusCoder';
import { RunActionConfig, runAction } from './RunAction';
import { RunStatusConfig, runStatus } from './RunStatus';
import { RollDirection } from 'communication';
import { MeasureType } from '../Flow/MeasureFlow';
import { CleanType } from '../Flow/CleanFlow';

// 枚举定义
export enum PointNum {
  First = 1,
  Second = 2,
}

export enum Target {
  COD = 1,
  EXTEND = 2,
}

export enum ResultMark {
  N = 0,      // 正常/在线
  B = 1,      // 离线
  M = 2,      // 维护
  D = 3,      // 故障
  C = 4,      // 校准
  E = 5,      // 超量程
  T = 6,      // 超上限（超标）
  K = 7,      // 质控
  A = 8,      // 调试
}

export enum ResultMarkC {
  N = 0,      // 正常/在线
  Z = 1,      // 零点核查
  R = 2,      // 量程(跨度)核查
  Cz = 3,     // 零点校准
  Cr = 4,     // 量程校准
  K = 5,      // 质控
  C = 6,      // 校准/核查
}

export enum MaintenceType {
  AutoMeasure = 0,        // 测量
  AutoCalibrate = 1,      // 校准
  AutoClean = 2,          // 清洗
  AutoPumpCalibrate = 3,  // 泵校准
  AutoADAdjust = 4,       // AD调节
  AutoCollectSample = 5,  // 采集水样
}

// 接口定义
export interface UnitItem {
  text: string;
  multiple: number;
}

export interface TypeChange {
  type: string;
  ShowDetails: string;
  bindCmd?: string;
  unBindCmd?: string;
  isReStart?: boolean;
}

export interface MeterLimit {
  sampleLimitVolume: number;
  blankLimitVolume: number;
  reagentLimitVolume: number;
  digestionRoomLimitVolume: number;
  pumpTimeoutFactor: number;
  meterTimeoutFactor: number;
}

export interface CleanVolume {
  cleanAftMeaBlankVol: number;
  readInitADBlankVolume: number;
}

export interface LiquidConfig {
  meterLimit: MeterLimit;
  reagent1Volume: number;
  reagent2Volume: number;
  reagentReNewVolume: number;
  sampleMeterPoint: number;
  standardMeterPoint: number;
  zeroCheckMeterPoint: number;
  rangeCheckMeterPoint: number;
  blankMeterPoint: number;
  reagent1MeterPoint: number;
  reagent2MeterPoint: number;
  digestionRoomMeterPoint: number;
  samplePipeVolume: number;
  standardPipeVolume: number;
  blankPipeVolume: number;
  zeroCheckPipeVolume: number;
  rangeCheckPipeVolume: number;
  reagent1PipeVolume: number;
  reagent2PipeVolume: number;
  meterPipeVolume: number;
  multipleValvePipeVolume: number;
  digestionRoomPipeVolume: number;
  wastePipeVolume: number;
  wasteWaterPipeVolume: number;
  pumpAirVolume: number;
  pumpAirSpeed: number;
  pumpAirStepSpeed: number;
  liquidSecludeVolume: number;
  liquidSecludeSpeed: number;
  meterPointMaxNum: number;
  slowMeterSpeed: number;
  meterSpeed: number;
  drainSpeed: number;
  prefabricateDrainSpeed: number;
  meterFailedReTry: number;
  meterOverflowReTry: number;
  meterUnfinishedReTry: number;
  meterAirBubbleReTry: number;
  meterTimeoutReTry: number;
  meterCleanVolume: number;
  readInitADBlankVolume: number;
  pipeRenewVolume: number;
  ropinessMeterOverValue: number;
  accurateMeterOverValue: number;
  cleanVolume: CleanVolume;
}

export interface SignalConfig {
  readADTime: number;
  readDarkADTime: number;
  dryFireReadADTime: number;
}

export interface TemperatureConfig {
  readInitADTemp: number;
  digestTempTimeout: number;
  reactTempTimeout: number;
  naturalCoolingTimeout: number;
  digestToReactCoolingTimeout: number;
  naturalCoolingTempValue: number;
  preheating: number;
  cleanDigestTemp: number;
  digestSafetyTemp: number;
  insideEnvironmentTemp: number;
  toleranceTemp: number;
  smartHeatDetectTemp: number;
  smartHeatDetectTime: number;
  digestAirPumpingTemp: number;
  oneKeyHeatingTemp: number;
  oneKeyHeatingTempTimeout: number;
  oneKeyHeatingCoolingTemp: number;
  oneKeyHeatingCoolingTempTimeout: number;
  digestTemperatureLimitTop: number;
  reactTemperatureLimitTop: number;
}

export interface CurveParam {
  curveKUpLimit: number;
  curveKLowLimit: number;
  curveBUpLimit: number;
  curveBLowLimit: number;
}

export interface MeasureResultConfig {
  decimalNum: number;
  getDecimalNum: () => number;
  useNum: number;
  quantifyLowLimit: number;
  measureUpLimit: number;
  measureLowLimit: number;
  zeroReviseValue: number;
  faultValue: number;
  normalMeasureTime: number;
  resultWaveRange: number;
  zeroDrift: number;
  rangeDrift: number;
  absLimit: number;
  checkErrorLimit: number;
  negativeReviseBaseValue: number;
  negativeReviseWaveRange: number;
  curve: CurveParam[];
}

export interface CommonConfig {
  zeroCalibrateWaveRange: number;
  standardCalibrateWaveRange: number;
  dataCopyDir: string;
  skipFlow: boolean;
  minRandomData: number;
  maxRandomData: number;
}

export interface RangeConfig {
  viewRange?: number;
  rangeWindowMin?: number;
  rangeWindowMax?: number;
  sampleVolume?: number;
  standardVolume?: number;
  zeroCheckVolume?: number;
  rangeCheckVolume?: number;
  blankVolume?: number;
  dilutionExtractVolume1?: number;
  dilutionAddBlankVolume1?: number;
  dilutionExtractVolume2?: number;
  dilutionAddBlankVolume2?: number;
  dilutionExtractVolume3?: number;
  dilutionAddBlankVolume3?: number;
  afterReagent1AddBlankVolume?: number;
  rinseEnable?: boolean;
  rinseSampleVolume?: number;
  rinseStandardVolume?: number;
  rinseZeroCheckVolume?: number;
  rinseRangeCheckVolume?: number;
  rinseBlankVolume?: number;
  diluteFactor?: number;
  excursion?: number;
}

export interface CleanConfig {
  cleanSource: number;
  cleanVolume: number;
  cleanTime: number;
}

export interface InstrumentConfig {
  name: string;
  argus: string[];
  deviceTypeNum: number ;
  oldTypeNum: number ;
  typeChanges: TypeChange[];
}

// 常量定义
export const unitVolume: number = 1.0;

export interface UintChange {
  text:string;
  multiple:number;
}

export interface Uint{
  valid: boolean;
  uintChange: UintChange [];
}

export const unit:Uint = {
  valid: true,
  uintChange:[
    {text:'mg/L', multiple:1},
    {text:'ug/L', multiple:1000},
  ],
}

export const instrument: InstrumentConfig = {

  // TODO: 设备类型
  name: "化学需氧量水质自动在线监测仪",
  argus: ["化学需氧量"],
  deviceTypeNum: 1018,
  oldTypeNum: 11,
  typeChanges: [
    { type: "PT65", ShowDetails: "(有屏软件)" },
    { type: "PT70", ShowDetails: "(有屏软件)" },
    {
      type: "PT71",
      ShowDetails: "(无屏软件)",
      bindCmd: "echo [vnc]=1 >/mnt/datadisk/Data/DeviceParam", 
      unBindCmd: "echo [vnc]=0 >/mnt/datadisk/Data/DeviceParam",
      isReStart: true,
    },
  ],
};

export const liquid: LiquidConfig = {
  meterLimit: {
    sampleLimitVolume: 8,
    blankLimitVolume: 8,
    reagentLimitVolume: 5,
    digestionRoomLimitVolume: 4,
    pumpTimeoutFactor: 60000,
    meterTimeoutFactor: 30000,
  },
  reagent1Volume: unitVolume * 1,
  reagent2Volume: 2,
  reagentReNewVolume: 0.5,
  sampleMeterPoint: 1,
  standardMeterPoint: 1,
  zeroCheckMeterPoint: 1,
  rangeCheckMeterPoint: 1,
  blankMeterPoint: 1,
  reagent1MeterPoint: 1,
  reagent2MeterPoint: 1,
  digestionRoomMeterPoint: 1,
  samplePipeVolume: 5,
  standardPipeVolume: 4,
  blankPipeVolume: 4,
  zeroCheckPipeVolume: 4,
  rangeCheckPipeVolume: 4,
  reagent1PipeVolume: 4,
  reagent2PipeVolume: 4,
  meterPipeVolume: 2.5,
  multipleValvePipeVolume: 1,
  digestionRoomPipeVolume: 2,
  wastePipeVolume: 1,
  wasteWaterPipeVolume: 2,
  pumpAirVolume: 4.5,
  pumpAirSpeed: 0.6,
  pumpAirStepSpeed: 400,
  liquidSecludeVolume: 0.1,
  liquidSecludeSpeed: 0.1,
  meterPointMaxNum: 2,
  slowMeterSpeed: 20,
  meterSpeed: 200,
  drainSpeed: 300,
  prefabricateDrainSpeed: 300,
  meterFailedReTry: 3,
  meterOverflowReTry: 3,
  meterUnfinishedReTry: 3,
  meterAirBubbleReTry: 6,
  meterTimeoutReTry: 3,
  meterCleanVolume: 3,
  readInitADBlankVolume: 4,
  pipeRenewVolume: 4,
  ropinessMeterOverValue: 100,
  accurateMeterOverValue: 40,
  cleanVolume: {
      cleanAftMeaBlankVol: 9.2,
      readInitADBlankVolume: 7.2,
  },
};

export const signal: SignalConfig = {
  readADTime: 20,
  readDarkADTime: 0.5,
  dryFireReadADTime: 0.5,
};

export const temperature: TemperatureConfig = {
  readInitADTemp: 50,
  digestTempTimeout: 720,
  reactTempTimeout: 720,
  naturalCoolingTimeout: 720,
  digestToReactCoolingTimeout: 720,
  naturalCoolingTempValue: 3,
  preheating: 60,
  cleanDigestTemp: 175,
  digestSafetyTemp: 70,
  insideEnvironmentTemp: 40,
  toleranceTemp: 1,
  smartHeatDetectTemp: 5,
  smartHeatDetectTime: 300,
  digestAirPumpingTemp: 110,
  oneKeyHeatingTemp: 90,
  oneKeyHeatingTempTimeout: 600,
  oneKeyHeatingCoolingTemp: 40,
  oneKeyHeatingCoolingTempTimeout: 600,
  digestTemperatureLimitTop: 200,
  reactTemperatureLimitTop: 100,
};

export const measureResult: MeasureResultConfig = {
  decimalNum: 1,
  getDecimalNum: (): number => {
    // 实际实现需要依赖 config.system.decimalNum
    return 1;
  },
  useNum: 3,
  quantifyLowLimit: 5,
  measureUpLimit: 10000,
  measureLowLimit: 50,
  zeroReviseValue: 0.001,
  faultValue: 0.002,
  normalMeasureTime: 3200,
  resultWaveRange: 0.02,
  zeroDrift: 5,
  rangeDrift: 5,
  absLimit: 1000,
  checkErrorLimit: 0.1,
  negativeReviseBaseValue: 25.05,
  negativeReviseWaveRange: 24.95,
  curve: [
    { curveKUpLimit: 0.59, curveKLowLimit: 0.36, curveBUpLimit: 500, curveBLowLimit: -500 },
    { curveKUpLimit: 0.59, curveKLowLimit: 0.36, curveBUpLimit: 500, curveBLowLimit: -500 },
    { curveKUpLimit: 0.35, curveKLowLimit: 0.17, curveBUpLimit: 500, curveBLowLimit: -500 },
    { curveKUpLimit: 0.18, curveKLowLimit: 0.08, curveBUpLimit: 500, curveBLowLimit: -500 },
    { curveKUpLimit: 0.1, curveKLowLimit: 0.03, curveBUpLimit: 500, curveBLowLimit: -500 },
    { curveKUpLimit: 0.046, curveKLowLimit: 0.017, curveBUpLimit: 500, curveBLowLimit: -500 },
    { curveKUpLimit: 0.027, curveKLowLimit: 0.008, curveBUpLimit: 500, curveBLowLimit: -500 },
  ],
};

export const common: CommonConfig = {
  zeroCalibrateWaveRange: 2,
  standardCalibrateWaveRange: 20,
  dataCopyDir: "/mnt/udisk/PT70-CODC_", //TODO
  skipFlow: false,
  minRandomData: 0,
  maxRandomData: 1,
};

export const measureRange: RangeConfig[] = [
  {
    viewRange: 100,
    rangeWindowMin: 0,
    rangeWindowMax: 110,
    sampleVolume: unitVolume * 2,
    standardVolume: 0,
    zeroCheckVolume: 0,
    rangeCheckVolume: 0,
    blankVolume: 0,
    dilutionExtractVolume1: 0,
    dilutionAddBlankVolume1: 0,
    dilutionExtractVolume2: 0,
    dilutionAddBlankVolume2: 0,
    dilutionExtractVolume3: 0,
    dilutionAddBlankVolume3: 0,
    afterReagent1AddBlankVolume: 0,
    rinseEnable: true,
    rinseSampleVolume: 4.6,
    rinseStandardVolume: 0,
    rinseZeroCheckVolume: 0,
    rinseRangeCheckVolume: 0,
    rinseBlankVolume: 0,
    diluteFactor: 1,
    excursion: 1,
  },
  {
    viewRange: 200,
    rangeWindowMin: 90,
    rangeWindowMax: 220,
    sampleVolume: unitVolume * 2,
    standardVolume: 0,
    zeroCheckVolume: 0,
    rangeCheckVolume: 0,
    blankVolume: 0,
    dilutionExtractVolume1: 0,
    dilutionAddBlankVolume1: 0,
    dilutionExtractVolume2: 0,
    dilutionAddBlankVolume2: 0,
    dilutionExtractVolume3: 0,
    dilutionAddBlankVolume3: 0,
    afterReagent1AddBlankVolume: 0,
    rinseEnable: true,
    rinseSampleVolume: 4.6,
    rinseStandardVolume: 0,
    rinseZeroCheckVolume: 0,
    rinseRangeCheckVolume: 0,
    rinseBlankVolume: 0,
    diluteFactor: 1,
    excursion: 1,
  },
  {
    viewRange: 500,
    rangeWindowMin: 180,
    rangeWindowMax: 550,
    sampleVolume: unitVolume * 2,
    standardVolume: 0,
    zeroCheckVolume: 0,
    rangeCheckVolume: 0,
    blankVolume: unitVolume * 2,
    dilutionExtractVolume1: 2,
    dilutionAddBlankVolume1: 0,
    dilutionExtractVolume2: 0,
    dilutionAddBlankVolume2: 0,
    dilutionExtractVolume3: 0,
    dilutionAddBlankVolume3: 0,
    afterReagent1AddBlankVolume: 0,
    rinseEnable: true,
    rinseSampleVolume: 4.6,
    rinseStandardVolume: 0,
    rinseZeroCheckVolume: 0,
    rinseRangeCheckVolume: 0,
    rinseBlankVolume: 0,
    diluteFactor: 2,
    excursion: 1.00508,
  },
  {
    viewRange: 1000,
    rangeWindowMin: 450,
    rangeWindowMax: 1100,
    sampleVolume: unitVolume * 2,
    standardVolume: 0,
    zeroCheckVolume: 0,
    rangeCheckVolume: 0,
    blankVolume: unitVolume * 6,
    dilutionExtractVolume1: unitVolume * 6,
    dilutionAddBlankVolume1: 0,
    dilutionExtractVolume2: 0,
    dilutionAddBlankVolume2: 0,
    dilutionExtractVolume3: 0,
    dilutionAddBlankVolume3: 0,
    afterReagent1AddBlankVolume: 0,
    rinseEnable: true,
    rinseSampleVolume: 4.6,
    rinseStandardVolume: 0,
    rinseZeroCheckVolume: 0,
    rinseRangeCheckVolume: 0,
    rinseBlankVolume: 0,
    diluteFactor: 4,
    excursion: 1.038,
  },
  {
    viewRange: 5000,
    rangeWindowMin: 900,
    rangeWindowMax: 5500,
    sampleVolume: unitVolume * 1,
    standardVolume: 0,
    zeroCheckVolume: 0,
    rangeCheckVolume: 0,
    blankVolume: unitVolume * 6,
    dilutionExtractVolume1: unitVolume * 4,
    dilutionAddBlankVolume1: unitVolume * 2,
    dilutionExtractVolume2: unitVolume * 3,
    dilutionAddBlankVolume2: 0,
    dilutionExtractVolume3: 0,
    dilutionAddBlankVolume3: 0,
    afterReagent1AddBlankVolume: 0,
    rinseEnable: true,
    rinseSampleVolume: 4.6,
    rinseStandardVolume: 0,
    rinseZeroCheckVolume: 0,
    rinseRangeCheckVolume: 0,
    rinseBlankVolume: 0,
    diluteFactor: 11,
    excursion: 0.996,
  },
  {
    viewRange: 10000,
    rangeWindowMin: 4500,
    rangeWindowMax: 11000,
    sampleVolume: unitVolume * 1,
    standardVolume: 0,
    zeroCheckVolume: 0,
    rangeCheckVolume: 0,
    blankVolume: unitVolume * 6,
    dilutionExtractVolume1: unitVolume * 5,
    dilutionAddBlankVolume1: unitVolume * 4,
    dilutionExtractVolume2: unitVolume * 4,
    dilutionAddBlankVolume2: 0,
    dilutionExtractVolume3: 0,
    dilutionAddBlankVolume3: 0,
    afterReagent1AddBlankVolume: 0,
    rinseEnable: true,
    rinseSampleVolume: 4.6,
    rinseStandardVolume: 0,
    rinseZeroCheckVolume: 0,
    rinseRangeCheckVolume: 0,
    rinseBlankVolume: 0,
    diluteFactor: 21,
    excursion: 1.09,
  },
  {
    viewRange: 20000,
    rangeWindowMin: 9000,
    rangeWindowMax: 20000,
    sampleVolume: unitVolume * 1,
    standardVolume: 0,
    zeroCheckVolume: 0,
    rangeCheckVolume: 0,
    blankVolume: unitVolume * 6,
    dilutionExtractVolume1: unitVolume * 5,
    dilutionAddBlankVolume1: unitVolume * 6,
    dilutionExtractVolume2: unitVolume * 6,
    dilutionAddBlankVolume2: 0,
    dilutionExtractVolume3: 0,
    dilutionAddBlankVolume3: 0,
    afterReagent1AddBlankVolume: 0,
    rinseEnable: true,
    rinseSampleVolume: 4.6,
    rinseStandardVolume: 0,
    rinseZeroCheckVolume: 0,
    rinseRangeCheckVolume: 0,
    rinseBlankVolume: 0,
    diluteFactor: 28,
    excursion: 1.074,
  },
];

export const calibrate: RangeConfig[] = [
  {
    viewRange: 0,
    rangeWindowMin: 0,
    rangeWindowMax: 0,
    sampleVolume: 0,
    standardVolume: 0,
    zeroCheckVolume: 0,
    rangeCheckVolume: 0,
    blankVolume: unitVolume * 2,
    dilutionExtractVolume1: 0,
    dilutionAddBlankVolume1: 0,
    dilutionExtractVolume2: 0,
    dilutionAddBlankVolume2: 0,
    dilutionExtractVolume3: 0,
    dilutionAddBlankVolume3: 0,
    afterReagent1AddBlankVolume: 0,
    rinseEnable: true,
    rinseSampleVolume: 0,
    rinseStandardVolume: 0,
    rinseZeroCheckVolume: 0,
    rinseRangeCheckVolume: 0,
    rinseBlankVolume: unitVolume * 2,
    diluteFactor: 1,
  },
  {
    viewRange: 0,
    rangeWindowMin: 0,
    rangeWindowMax: 0,
    sampleVolume: 0,
    standardVolume: unitVolume * 2,
    zeroCheckVolume: 0,
    rangeCheckVolume: 0,
    blankVolume: 0,
    dilutionExtractVolume1: 0,
    dilutionAddBlankVolume1: 0,
    dilutionExtractVolume2: 0,
    dilutionAddBlankVolume2: 0,
    dilutionExtractVolume3: 0,
    dilutionAddBlankVolume3: 0,
    afterReagent1AddBlankVolume: 0,
    rinseEnable: true,
    rinseSampleVolume: 0,
    rinseStandardVolume: unitVolume * 2,
    rinseZeroCheckVolume: 0,
    rinseRangeCheckVolume: 0,
    rinseBlankVolume: 0,
    diluteFactor: 1,
  },
];

export const clean: CleanConfig = {
  cleanSource: 1,
  cleanVolume: 7,
  cleanTime: 3,
};

export interface Setting{
  unitVolume: number;
  unit: Uint;
  instrument: InstrumentConfig;
  liquid: LiquidConfig;
  signal: SignalConfig;
  temperature: TemperatureConfig;
  measureResult: MeasureResultConfig;
  common: CommonConfig;
  measureRange: RangeConfig[];
  calibrate: RangeConfig[];
  clean: CleanConfig;
  alarm: AlarmConfig;
  alarm_sc: AlarmConfig;
  liquidTypes: LiquidTypes;
  modbusCoder: ModbusCoderType;
  runAction: RunActionConfig;
  runStatus: RunStatusConfig;
}

// 导出所有配置
export const setting:Setting = {
  unitVolume,
  unit,
  instrument,
  liquid,
  signal,
  temperature,
  measureResult,
  common,
  measureRange,
  calibrate,
  clean,
  alarm,
  alarm_sc,
  liquidTypes,
  modbusCoder,
  runAction,
  runStatus,
};

// 维护操作参数接口
export interface MaintainOperationParams {
  maintenceTypes: MaintenceType;
  params: MeasureType | CleanType;
  runTimes: number;
}

// 管道操作参数接口
export interface PipeOperationParams {
  liquidName: string;
  dir: RollDirection;
  mode: string,
  volume: number; // 单位建议统一为 mL 或 μL，需在注释中标明
}

// 硬件测试操作参数接口
export interface HardwareOperationParams {
  operationName: string;
  status: number;
}

export default setting;
