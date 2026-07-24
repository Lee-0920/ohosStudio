/**
 * Modbus编码器配置接口
 */
export interface StatusItem {
  ID: number;
  jsID?: number;
  dbsID?: number;
  szbaID?: number;
  scID?: number;
}

export interface ActionItem {
  ID: number;
  dbsID?: number;
}

export interface DetectResultItem {
  idle: number;
  detecting: number;
  passed: number;
  fail: number;
  stop: number;
}


export interface StatusIDMap {
  Idle: StatusItem;
  MeasureSample: StatusItem;
  MeasureStandard: StatusItem;
  MeasureBlank: StatusItem;
  Calibrate: StatusItem;
  CleanDigestionRoom: StatusItem;
  CleanMeterPipe: StatusItem;
  CleanAll: StatusItem;
  CollectSample: StatusItem;
  OneKeyMaintain: StatusItem;
  DigesterCooling: StatusItem;
  AutoPumpCheck: StatusItem;
  LiquidOperate: StatusItem;
  SmartDetect: StatusItem;
  CommunicationCheck: StatusItem;
  HardwareTest: StatusItem;
  MASTER: StatusItem;
  LCUpdate: StatusItem;
  TCUpdate: StatusItem;
  OAUpdate: StatusItem;
  RCUpdate: StatusItem;
  DCUpdate: StatusItem;
  CleanDeeply: StatusItem;
  Range3CurveCalibrate: StatusItem;
  Range4CurveCalibrate: StatusItem;
  Range5CurveCalibrate: StatusItem;
  Range2CurveCalibrate: StatusItem;
  CleanPretreatment: StatusItem;
  CombineOperate: StatusItem;
  OnlyCalibrateBlank: StatusItem;
  OnlyCalibrateStandard: StatusItem;
  MeasureExtAddstandard: StatusItem;
  MeasureExtParallel: StatusItem;
  MeasureQualityHandle: StatusItem;
  MeasureZeroCheck: StatusItem;
  MeasureRangeCheck: StatusItem;
  MeasureAddstandard: StatusItem;
  MeasureParallel: StatusItem;
  MeterADAdjust: StatusItem;
  MeasureADAdjust: StatusItem;
  OneKeyRenew: StatusItem;
  Range6CurveCalibrate: StatusItem;
  Range7CurveCalibrate: StatusItem;
  Range8CurveCalibrate: StatusItem;
  Fault: StatusItem;
}

/**
 * 状态ID映射
 */
export const statusID: StatusIDMap = {
  Idle: {
    ID: 0,
    jsID: 1,
    dbsID: 0,
    szbaID: 2048,
    scID: 0,
  },
  MeasureSample: {
    ID: 1,
    jsID: 4,
    dbsID: 1,
    szbaID: 1,
    scID: 1,
  },
  MeasureStandard: {
    ID: 2,
    jsID: 8,
    dbsID: 2,
  },
  MeasureBlank: {
    ID: 3,
    jsID: 8,
    dbsID: 5,
  },
  Calibrate: {
    ID: 4,
    jsID: 7,
    dbsID: 19,
    szbaID: 2,
    scID: 3,
  },
  CleanDigestionRoom: {
    ID: 5,
    jsID: 3,
    dbsID: 10,
    szbaID: 4,
  },
  CleanMeterPipe: {
    ID: 6,
    jsID: 3,
    dbsID: 10,
    szbaID: 4,
  },
  CleanAll: {
    ID: 7,
    jsID: 3,
    dbsID: 10,
    szbaID: 4,
  },
  CollectSample: {
    ID: 8,
    jsID: 8,
    dbsID: 1001,
  },
  OneKeyMaintain: {
    ID: 9,
    jsID: 7,
    dbsID: 19,
  },
  DigesterCooling: {
    ID: 10,
    jsID: 5,
    dbsID: 1001,
  },
  AutoPumpCheck: {
    ID: 11,
    jsID: 5,
    dbsID: 1001,
  },
  LiquidOperate: {
    ID: 12,
    jsID: 5,
    dbsID: 1001,
  },
  SmartDetect: {
    ID: 13,
    jsID: 5,
    dbsID: 1001,
  },
  CommunicationCheck: {
    ID: 14,
    jsID: 5,
    dbsID: 1001,
  },
  HardwareTest: {
    ID: 15,
    jsID: 5,
    dbsID: 1001,
  },
  MASTER: {
    ID: 16,
    jsID: 5,
    dbsID: 1001,
  },
  LCUpdate: {
    ID: 17,
    jsID: 5,
    dbsID: 1001,
  },
  TCUpdate: {
    ID: 18,
    jsID: 5,
    dbsID: 1001,
  },
  OAUpdate: {
    ID: 19,
    jsID: 5,
    dbsID: 1001,
  },
  RCUpdate: {
    ID: 20,
    jsID: 5,
    dbsID: 1001,
  },
  DCUpdate: {
    ID: 21,
    jsID: 5,
    dbsID: 1001,
  },
  CleanDeeply: {
    ID: 22,
    jsID: 3,
    dbsID: 10,
    szbaID: 4,
  },
  Range3CurveCalibrate: {
    ID: 23,
    jsID: 2,
    dbsID: 9,
  },
  Range4CurveCalibrate: {
    ID: 24,
    jsID: 2,
    dbsID: 9,
  },
  Range5CurveCalibrate: {
    ID: 25,
    jsID: 2,
    dbsID: 9,
  },
  Range2CurveCalibrate: {
    ID: 26,
    jsID: 2,
    dbsID: 9,
  },
  CleanPretreatment: {
    ID: 27,
    jsID: 3,
    dbsID: 10,
    szbaID: 4,
  },
  CombineOperate: {
    ID: 28,
    jsID: 5,
    dbsID: 1001,
  },
  OnlyCalibrateBlank: {
    ID: 29,
    jsID: 7,
    dbsID: 19,
    szbaID: 16,
  },
  OnlyCalibrateStandard: {
    ID: 30,
    jsID: 7,
    dbsID: 19,
    szbaID: 8,
  },
  MeasureExtAddstandard: {
    ID: 31,
    jsID: 8,
    dbsID: 7,
  },
  MeasureExtParallel: {
    ID: 32,
    jsID: 8,
    dbsID: 6,
  },
  MeasureQualityHandle: {
    jsID: 8,
    szbaID: 7,
    ID: 33,
  },
  MeasureZeroCheck: {
    ID: 40,
    jsID: 8,
    dbsID: 3,
    szbaID: 256,
  },
  MeasureRangeCheck: {
    ID: 41,
    jsID: 9,
    dbsID: 4,
    szbaID: 32,
    scID: 3,
  },
  MeasureAddstandard: {
    ID: 42,
    jsID: 8,
    dbsID: 7,
  },
  MeasureParallel: {
    ID: 43,
    jsID: 8,
    dbsID: 6,
  },
  MeterADAdjust: {
    ID: 44,
    jsID: 5,
    dbsID: 1001,
  },
  MeasureADAdjust: {
    ID: 45,
    jsID: 5,
    dbsID: 1001,
  },
  OneKeyRenew: {
    ID: 46,
    jsID: 3,
    dbsID: 10,
  },
  Range6CurveCalibrate: {
    ID: 50,
    jsID: 2,
    dbsID: 9,
  },
  Range7CurveCalibrate: {
    ID: 51,
    jsID: 2,
    dbsID: 9,
  },
  Range8CurveCalibrate: {
    ID: 52,
    jsID: 2,
    dbsID: 9,
  },
  Fault: {
    ID: 255,
    jsID: 6,
    dbsID: 1000,
  },
};

export interface ActionIDMap {
  Idle: ActionItem;
  CleanBeforeMeasure: ActionItem;
  ReadInitialAD: ActionItem;
  Rinse: ActionItem;
  AddSample: ActionItem;
  AddReagent1: ActionItem;
  AddReagent2: ActionItem;
  AddReagent3: ActionItem;
  AddReagent4: ActionItem;
  AddReagent5: ActionItem;
  AddReagent6: ActionItem;
  CleanMeterPipe: ActionItem;
  Preheating: ActionItem;
  Digest: ActionItem;
  DigestCooling: ActionItem;
  ReadMeasureAD: ActionItem;
  Clean: ActionItem;
  Cooling: ActionItem;
  Collect: ActionItem;
  Silent: ActionItem;
  AutoPumpCheck: ActionItem;
  SuckFromBlank: ActionItem;
  DrainToBlank: ActionItem;
  SuckFromSample: ActionItem;
  DrainToSample: ActionItem;
  SuckFromStandard: ActionItem;
  DrainToStandard: ActionItem;
  SuckFromReagent1: ActionItem;
  DrainToReagent1: ActionItem;
  SuckFromReagent2: ActionItem;
  DrainToReagent2: ActionItem;
  SuckFromReagent3: ActionItem;
  DrainToReagent3: ActionItem;
  SuckFromReagent4: ActionItem;
  DrainToReagent4: ActionItem;
  SuckFromReagent5: ActionItem;
  DrainToReagent5: ActionItem;
  SuckFromReagent6: ActionItem;
  DrainToReagent6: ActionItem;
  SuckFromDigestionRoom: ActionItem;
  DrainToDigestionRoom: ActionItem;
  DrainToWaste: ActionItem;
  LCCommunicationCheck: ActionItem;
  OACommunicationCheck: ActionItem;
  TCCommunicationCheck: ActionItem;
  SmartHeatDetect: ActionItem;
  SmartCoolDetect: ActionItem;
  SmartMeasureDetect: ActionItem;
  SmartMeterDetect: ActionItem;
  SmartBlankValveDetect: ActionItem;
  SmartSampleValveDetect: ActionItem;
  SmartStandardValveDetect: ActionItem;
  SmartReagent1ValveDetect: ActionItem;
  SmartReagent2ValveDetect: ActionItem;
  SmartReagent3ValveDetect: ActionItem;
  SmartReagent4ValveDetect: ActionItem;
  SmartReagent5ValveDetect: ActionItem;
  SmartReagent6ValveDetect: ActionItem;
  SmartDigestionRoomValveDetect: ActionItem;
  SmartWasteValveDetect: ActionItem;
  PumpTest: ActionItem;
  SampleValveTest: ActionItem;
  BlankValveTest: ActionItem;
  StandardValveTest: ActionItem;
  Reagent1ValveTest: ActionItem;
  Reagent2ValveTest: ActionItem;
  Reagent3ValveTest: ActionItem;
  Reagent4ValveTest: ActionItem;
  Reagent5ValveTest: ActionItem;
  Reagent6ValveTest: ActionItem;
  WasteValveTest: ActionItem;
  DigestUpValveTest: ActionItem;
  DigestBottomValveTest: ActionItem;
  HeaterTest: ActionItem;
  CoolerTest: ActionItem;
  MeasuerLEDTest: ActionItem;
  Meter1LEDTest: ActionItem;
  Meter2LEDTest: ActionItem;
  CollectSampleRelayTest: ActionItem;
  Relay1Test: ActionItem;
  Relay2Test: ActionItem;
  SampleCurrent4Output: ActionItem;
  SampleCurrent12Output: ActionItem;
  SampleCurrent20Output: ActionItem;
  CheckCurrent4Output: ActionItem;
  CheckCurrent12Output: ActionItem;
  CheckCurrent20Output: ActionItem;
  Copy: ActionItem;
  Updater: ActionItem;
  Erase: ActionItem;
  WriteProgram: ActionItem;
  DrainBeforeMeasure: ActionItem;
  DrainAfterMeasure: ActionItem;
  CleanAfterMeasure: ActionItem;
  React: ActionItem;
  SystemFanTest: ActionItem;
  ClearWaste: ActionItem;
  ClearBlankPipe: ActionItem;
  ClearStandardPipe: ActionItem;
  ClearReagent1Pipe: ActionItem;
  ClearReagent2Pipe: ActionItem;
  ClearReagent3Pipe: ActionItem;
  ClearReagent4Pipe: ActionItem;
  ClearReagent5Pipe: ActionItem;
  ClearReagent6Pipe: ActionItem;
  CleanDigestionRoom: ActionItem;
  CleanSamplePipe: ActionItem;
  CleanStandardPipe: ActionItem;
  CleanBlankPipe: ActionItem;
  CleanReagent1Pipe: ActionItem;
  CleanReagent2Pipe: ActionItem;
  CleanReagent3Pipe: ActionItem;
  CleanReagent4Pipe: ActionItem;
  CleanReagent5Pipe: ActionItem;
  CleanReagent6Pipe: ActionItem;
  DrainSamplePipe: ActionItem;
  DrainStandardPipe: ActionItem;
  DrainBlankPipe: ActionItem;
  DrainReagent1Pipe: ActionItem;
  DrainReagent2Pipe: ActionItem;
  DrainReagent3Pipe: ActionItem;
  DrainReagent4Pipe: ActionItem;
  DrainReagent5Pipe: ActionItem;
  DrainReagent6Pipe: ActionItem;
  DrainWastePipe: ActionItem;
  ReadBlankAD: ActionItem;
  DCCommunicationCheck: ActionItem;
  RCCommunicationCheck: ActionItem;
  SuckBlankToDigestionRoom: ActionItem;
  SuckDigestionRoomToWaste: ActionItem;
  GasSealCheck: ActionItem;
  SuckDigestionRoomToWasteWater: ActionItem;
  DrainAfterReadBlankAD: ActionItem;
  SuckFromZeroCheck: ActionItem;
  DrainToZeroCheck: ActionItem;
  SuckFromRangeCheck: ActionItem;
  DrainToRangeCheck: ActionItem;
  SmartWasteWaterValveDetect: ActionItem;
  SmartZeroCheckValveDetect: ActionItem;
  SmartRangeCheckValveDetect: ActionItem;
  DrainZeroCheckPipe: ActionItem;
  DrainRangeCheckPipe: ActionItem;
  DrainWasteWaterPipe: ActionItem;
  MeterADAdjust: ActionItem;
  MeasureADAdjust: ActionItem;
  OneKeyHeating: ActionItem;
}

/**
 * 动作ID映射
 */
export const actionID: ActionIDMap = {
  Idle: {
    ID: 0,
    dbsID: 0xffff,
  },
  CleanBeforeMeasure: {
    ID: 1,
    dbsID: 12,
  },
  ReadInitialAD: {
    ID: 2,
    dbsID: 13,
  },
  Rinse: {
    ID: 3,
    dbsID: 3,
  },
  AddSample: {
    ID: 4,
    dbsID: 4,
  },
  AddReagent1: {
    ID: 5,
    dbsID: 5,
  },
  AddReagent2: {
    ID: 6,
    dbsID: 6,
  },
  AddReagent3: {
    ID: 7,
  },
  AddReagent4: {
    ID: 8,
  },
  AddReagent5: {
    ID: 9,
  },
  AddReagent6: {
    ID: 10,
  },
  CleanMeterPipe: {
    ID: 11,
  },
  Preheating: {
    ID: 12,
  },
  Digest: {
    ID: 13,
    dbsID: 8,
  },
  DigestCooling: {
    ID: 14,
    dbsID: 10,
  },
  ReadMeasureAD: {
    ID: 15,
    dbsID: 11,
  },
  Clean: {
    ID: 16,
  },
  Cooling: {
    ID: 17,
  },
  Collect: {
    ID: 18,
  },
  Silent: {
    ID: 19,
  },
  AutoPumpCheck: {
    ID: 20,
  },
  SuckFromBlank: {
    ID: 21,
  },
  DrainToBlank: {
    ID: 22,
  },
  SuckFromSample: {
    ID: 23,
  },
  DrainToSample: {
    ID: 24,
  },
  SuckFromStandard: {
    ID: 25,
  },
  DrainToStandard: {
    ID: 26,
  },
  SuckFromReagent1: {
    ID: 27,
  },
  DrainToReagent1: {
    ID: 28,
  },
  SuckFromReagent2: {
    ID: 29,
  },
  DrainToReagent2: {
    ID: 30,
  },
  SuckFromReagent3: {
    ID: 31,
  },
  DrainToReagent3: {
    ID: 32,
  },
  SuckFromReagent4: {
    ID: 33,
  },
  DrainToReagent4: {
    ID: 34,
  },
  SuckFromReagent5: {
    ID: 35,
  },
  DrainToReagent5: {
    ID: 36,
  },
  SuckFromReagent6: {
    ID: 37,
  },
  DrainToReagent6: {
    ID: 38,
  },
  SuckFromDigestionRoom: {
    ID: 39,
  },
  DrainToDigestionRoom: {
    ID: 40,
  },
  DrainToWaste: {
    ID: 41,
  },
  LCCommunicationCheck: {
    ID: 42,
  },
  OACommunicationCheck: {
    ID: 43,
  },
  TCCommunicationCheck: {
    ID: 44,
  },
  SmartHeatDetect: {
    ID: 45,
  },
  SmartCoolDetect: {
    ID: 46,
  },
  SmartMeasureDetect: {
    ID: 47,
  },
  SmartMeterDetect: {
    ID: 48,
  },
  SmartBlankValveDetect: {
    ID: 49,
  },
  SmartSampleValveDetect: {
    ID: 50,
  },
  SmartStandardValveDetect: {
    ID: 51,
  },
  SmartReagent1ValveDetect: {
    ID: 52,
  },
  SmartReagent2ValveDetect: {
    ID: 53,
  },
  SmartReagent3ValveDetect: {
    ID: 54,
  },
  SmartReagent4ValveDetect: {
    ID: 55,
  },
  SmartReagent5ValveDetect: {
    ID: 56,
  },
  SmartReagent6ValveDetect: {
    ID: 57,
  },
  SmartDigestionRoomValveDetect: {
    ID: 58,
  },
  SmartWasteValveDetect: {
    ID: 59,
  },
  PumpTest: {
    ID: 60,
  },
  SampleValveTest: {
    ID: 61,
  },
  BlankValveTest: {
    ID: 62,
  },
  StandardValveTest: {
    ID: 63,
  },
  Reagent1ValveTest: {
    ID: 64,
  },
  Reagent2ValveTest: {
    ID: 65,
  },
  Reagent3ValveTest: {
    ID: 66,
  },
  Reagent4ValveTest: {
    ID: 67,
  },
  Reagent5ValveTest: {
    ID: 68,
  },
  Reagent6ValveTest: {
    ID: 69,
  },
  WasteValveTest: {
    ID: 70,
  },
  DigestUpValveTest: {
    ID: 71,
  },
  DigestBottomValveTest: {
    ID: 72,
  },
  HeaterTest: {
    ID: 73,
  },
  CoolerTest: {
    ID: 74,
  },
  MeasuerLEDTest: {
    ID: 75,
  },
  Meter1LEDTest: {
    ID: 76,
  },
  Meter2LEDTest: {
    ID: 77,
  },
  CollectSampleRelayTest: {
    ID: 78,
  },
  Relay1Test: {
    ID: 79,
  },
  Relay2Test: {
    ID: 80,
  },
  SampleCurrent4Output: {
    ID: 81,
  },
  SampleCurrent12Output: {
    ID: 82,
  },
  SampleCurrent20Output: {
    ID: 83,
  },
  CheckCurrent4Output: {
    ID: 84,
  },
  CheckCurrent12Output: {
    ID: 85,
  },
  CheckCurrent20Output: {
    ID: 86,
  },
  Copy: {
    ID: 87,
  },
  Updater: {
    ID: 88,
  },
  Erase: {
    ID: 89,
  },
  WriteProgram: {
    ID: 90,
  },
  DrainBeforeMeasure: {
    ID: 91,
    dbsID: 0,
  },
  DrainAfterMeasure: {
    ID: 92,
    dbsID: 45,
  },
  CleanAfterMeasure: {
    ID: 93,
    dbsID: 12,
  },
  React: {
    ID: 94,
    dbsID: 25,
  },
  SystemFanTest: {
    ID: 95,
  },
  ClearWaste: {
    ID: 96,
  },
  ClearBlankPipe: {
    ID: 97,
  },
  ClearStandardPipe: {
    ID: 98,
  },
  ClearReagent1Pipe: {
    ID: 99,
  },
  ClearReagent2Pipe: {
    ID: 100,
  },
  ClearReagent3Pipe: {
    ID: 101,
  },
  ClearReagent4Pipe: {
    ID: 102,
  },
  ClearReagent5Pipe: {
    ID: 103,
  },
  ClearReagent6Pipe: {
    ID: 104,
  },
  CleanDigestionRoom: {
    ID: 105,
  },
  CleanSamplePipe: {
    ID: 106,
  },
  CleanStandardPipe: {
    ID: 107,
  },
  CleanBlankPipe: {
    ID: 108,
  },
  CleanReagent1Pipe: {
    ID: 109,
  },
  CleanReagent2Pipe: {
    ID: 110,
  },
  CleanReagent3Pipe: {
    ID: 111,
  },
  CleanReagent4Pipe: {
    ID: 112,
  },
  CleanReagent5Pipe: {
    ID: 113,
  },
  CleanReagent6Pipe: {
    ID: 114,
  },
  DrainSamplePipe: {
    ID: 115,
  },
  DrainStandardPipe: {
    ID: 116,
  },
  DrainBlankPipe: {
    ID: 117,
  },
  DrainReagent1Pipe: {
    ID: 118,
  },
  DrainReagent2Pipe: {
    ID: 119,
  },
  DrainReagent3Pipe: {
    ID: 120,
  },
  DrainReagent4Pipe: {
    ID: 121,
  },
  DrainReagent5Pipe: {
    ID: 122,
  },
  DrainReagent6Pipe: {
    ID: 123,
  },
  DrainWastePipe: {
    ID: 124,
  },
  ReadBlankAD: {
    ID: 125,
    dbsID: 12,
  },
  DCCommunicationCheck: {
    ID: 126,
  },
  RCCommunicationCheck: {
    ID: 127,
  },
  SuckBlankToDigestionRoom: {
    ID: 128,
  },
  SuckDigestionRoomToWaste: {
    ID: 129,
  },
  GasSealCheck: {
    ID: 130,
  },
  SuckDigestionRoomToWasteWater: {
    ID: 131,
  },
  DrainAfterReadBlankAD: {
    ID: 132,
  },
  SuckFromZeroCheck: {
    ID: 141,
  },
  DrainToZeroCheck: {
    ID: 142,
  },
  SuckFromRangeCheck: {
    ID: 143,
  },
  DrainToRangeCheck: {
    ID: 144,
  },
  SmartWasteWaterValveDetect: {
    ID: 145,
  },
  SmartZeroCheckValveDetect: {
    ID: 146,
  },
  SmartRangeCheckValveDetect: {
    ID: 147,
  },
  DrainZeroCheckPipe: {
    ID: 148,
  },
  DrainRangeCheckPipe: {
    ID: 149,
  },
  DrainWasteWaterPipe: {
    ID: 150,
  },
  MeterADAdjust: {
    ID: 151,
  },
  MeasureADAdjust: {
    ID: 152,
    dbsID: 53,
  },
  OneKeyHeating: {
    ID: 153,
  },
};

/**
 * 检测结果ID映射
 */
export const detectResultID = {
  idle: 0,
  detecting: 1,
  passed: 2,
  fail: 3,
  stop: 4,
} as DetectResultItem;

export interface ModbusCoderType {
  statusID: StatusIDMap;
  actionID: ActionIDMap;
  detectResultID: DetectResultItem;
}

/**
 * Modbus编码器配置导出
 */
export const modbusCoder: ModbusCoderType = {
  statusID,
  actionID,
  detectResultID,
};
