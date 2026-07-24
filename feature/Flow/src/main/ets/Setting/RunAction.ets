
import { config } from '../Config/Config';

/**
 * 运行动作项接口
 */
export interface ActionItem {
  name: string;
  text: string;
  GetTime?: () => number;
}

/**
 * 采集样品动作接口
 */
export interface CollectSampleAction {
  collect: ActionItem;
  silent: ActionItem;
}

/**
 * 采集样品动作
 */
export const collectSample: CollectSampleAction = {
  collect: {
    name: "Collect",
    text: "采集",
    GetTime: (): number => {
       return config.interconnection.miningWaterTime;
    },
  },
  silent: {
    name: "Silent",
    text: "静置",
    GetTime: (): number => {
      return config.interconnection.silentTime;
    },
  },
};

/**
 * 消解安全检查动作
 */
export const digestSafetyCheck: ActionItem = {
  name: "Cooling",
  text: "冷却",
  GetTime: (): number => {
    return 50;
  },
};

/**
 * 测量动作接口
 */
export interface MeasureAction {
  drainBeforeMeasure: ActionItem;
  cleanBeforeMeasure: ActionItem;
  rinse: ActionItem;
  addSample: ActionItem;
  addReagent1: ActionItem;
  cleanMeterPipe: ActionItem;
  preheating: ActionItem;
  addReagent2: ActionItem;
  digest: ActionItem;
  digestCooling: ActionItem;
  readMeasureAD: ActionItem;
  drainAfterMeasure: ActionItem;
  cleanAfterMeasure: ActionItem;
  readInitialAD: ActionItem;
}

/**
 * 测量动作
 */
export const measure: MeasureAction = {
  drainBeforeMeasure: {
    name: "DrainBeforeMeasure",
    text: "测量前排液",
    GetTime: (): number => {
      let totalTime = 60;
      // if (Measurer.GetExecuteTime(measure.drainBeforeMeasure.text) !== -1) {
      //   totalTime = Measurer.GetExecuteTime(measure.drainBeforeMeasure.text);
      // }
      return totalTime;
    },
  },
  cleanBeforeMeasure: {
    name: "CleanBeforeMeasure",
    text: "测量前清洗",
    GetTime: (): number => {
      let totalTime = config.measureParam.cleanBefMeaBlankVol * 60;
      // if (Measurer.GetExecuteTime(measure.cleanBeforeMeasure.text) !== -1) {
      //   totalTime = Measurer.GetExecuteTime(measure.cleanBeforeMeasure.text);
      // }
      return totalTime;
    },
  },
  rinse: {
    name: "Rinse",
    text: "润洗",
    GetTime: (): number => {
      let totalTime = 60 + (config.measureParam.sampleRenewVolume * 35);
      // if (Measurer.GetExecuteTime(measure.rinse.text) !== -1) {
      //   totalTime = Measurer.GetExecuteTime(measure.rinse.text);
      // }
      return totalTime;
    },
  },
  addSample: {
    name: "AddSample",
    text: "加待测样",
    GetTime: (): number => {
      let totalTime = 400;
      // if (Measurer.GetExecuteTime(measure.addSample.text) !== -1) {
      //   totalTime = Measurer.GetExecuteTime(measure.addSample.text);
      // }
      return totalTime;
    },
  },
  addReagent1: {
    name: "AddReagent1",
    text: "加试剂一",
    GetTime: (): number => {
      let totalTime = 95;
      // if (Measurer.GetExecuteTime(measure.addReagent1.text) !== -1) {
      //   totalTime = Measurer.GetExecuteTime(measure.addReagent1.text);
      // }
      return totalTime;
    },
  },
  cleanMeterPipe: {
    name: "CleanMeterPipe",
    text: "清洗定量管",
    GetTime: (): number => {
      let totalTime = 80;
      // if (Measurer.GetExecuteTime(measure.cleanMeterPipe.text) !== -1) {
      //   totalTime = Measurer.GetExecuteTime(measure.cleanMeterPipe.text);
      // }
      return totalTime;
    },
  },
  preheating: {
    name: "Preheating",
    text: "消解液预热",
    GetTime: (): number => {
      let totalTime = 60;
      // if (Measurer.GetExecuteTime(measure.preheating.text) !== -1) {
      //   totalTime = Measurer.GetExecuteTime(measure.preheating.text);
      // }
      return totalTime;
    },
  },
  addReagent2: {
    name: "AddReagent2",
    text: "加试剂二",
    GetTime: (): number => {
      let totalTime = 240;
      // if (Measurer.GetExecuteTime(measure.addReagent2.text) !== -1) {
      //   totalTime = Measurer.GetExecuteTime(measure.addReagent2.text);
      // }
      return totalTime;
    },
  },
  digest: {
    name: "Digest",
    text: "消解加热",
    GetTime: (): number => {
      let totalTime = config.measureParam.digestTime + 180;
      // if (Measurer.GetExecuteTime(measure.digest.text) !== -1) {
      //   totalTime = Measurer.GetExecuteTime(measure.digest.text);
      // }
      return totalTime;
    },
  },
  digestCooling: {
    name: "DigestCooling",
    text: "消解冷却",
    GetTime: (): number => {
      let totalTime = 400;
      // if (Measurer.GetExecuteTime(measure.digestCooling.text) !== -1) {
      //   totalTime = Measurer.GetExecuteTime(measure.digestCooling.text);
      // }
      return totalTime;
    },
  },
  readMeasureAD: {
    name: "ReadMeasureAD",
    text: "读反应值",
    GetTime: (): number => {
      let totalTime = 12;
      // if (Measurer.GetExecuteTime(measure.readMeasureAD.text) !== -1) {
      //   totalTime = Measurer.GetExecuteTime(measure.readMeasureAD.text);
      // }
      return totalTime;
    },
  },
  drainAfterMeasure: {
    name: "DrainAfterMeasure",
    text: "测量后排液",
    GetTime: (): number => {
      let totalTime = 100;
      // if (Measurer.GetExecuteTime(measure.drainAfterMeasure.text) !== -1) {
      //   totalTime = Measurer.GetExecuteTime(measure.drainAfterMeasure.text);
      // }
      return totalTime;
    },
  },
  cleanAfterMeasure: {
    name: "CleanAfterMeasure",
    text: "测量后清洗",
    GetTime: (): number => {
      let totalTime = 110;
      // if (Measurer.GetExecuteTime(measure.cleanAfterMeasure.text) !== -1) {
      //   totalTime = Measurer.GetExecuteTime(measure.cleanAfterMeasure.text);
      // }
      return totalTime;
    },
  },
  readInitialAD: {
    name: "ReadInitialAD",
    text: "读空白值",
    GetTime: (): number => {
      let totalTime = 80 + config.measureParam.readInitRilentTime;
      // if (Measurer.GetExecuteTime(measure.readInitialAD.text) !== -1) {
      //   totalTime = Measurer.GetExecuteTime(measure.readInitialAD.text);
      // }
      return totalTime;
    },
  },
};

/**
 * 一键维护动作接口
 */
export interface OneKeyMaintainAction {
  clearWaste: ActionItem;
  clearReagent1Pipe: ActionItem;
  clearStandardPipe: ActionItem;
  clearReagent2Pipe: ActionItem;
  clearBlankPipe: ActionItem;
  clearZeroCheckPipe: ActionItem;
  clearRangeCheckPipe: ActionItem;
}

/**
 * 一键维护动作
 */
export const oneKeyMaintain: OneKeyMaintainAction = {
  clearWaste: {
    name: "ClearWaste",
    text: "清空残留液",
    GetTime: (): number => 100,
  },
  clearReagent1Pipe: {
    name: "ClearReagent1Pipe",
    text: "清空试剂一管",
    GetTime: (): number => 120,
  },
  clearStandardPipe: {
    name: "ClearStandardPipe",
    text: "清空量程校准液管",
    GetTime: (): number => 120,
  },
  clearReagent2Pipe: {
    name: "ClearReagent2Pipe",
    text: "清空试剂二管",
    GetTime: (): number => 120,
  },
  clearBlankPipe: {
    name: "ClearBlankPipe",
    text: "清空零点校准液管",
    GetTime: (): number => 120,
  },
  clearZeroCheckPipe: {
    name: "ClearZeroCheckPipe",
    text: "清空零点核查液管",
    GetTime: (): number => 120,
  },
  clearRangeCheckPipe: {
    name: "ClearRangeCheckPipe",
    text: "清空标样(跨度)核查液管",
    GetTime: (): number => 120,
  },
};

/**
 * 清洗定量管动作
 */
export const cleanMeterPipe: ActionItem = {
  name: "Clean",
  text: "清洗",
  GetTime: (): number => 50,
};

/**
 * 清洗消解室动作
 */
export const cleanDigestionRoom: ActionItem = {
  name: "Clean",
  text: "清洗",
  GetTime: (): number => 335,
};

/**
 * 深度清洗动作
 */
export const cleanDeeply: ActionItem = {
  name: "Clean",
  text: "清洗",
  GetTime: (): number => 870,
};

/**
 * 清洗所有管路动作接口
 */
export interface CleanAllAction {
  cleanDigestionRoom: ActionItem;
  cleanSamplePipe: ActionItem;
  cleanStandardPipe: ActionItem;
  cleanReagent1Pipe: ActionItem;
  cleanReagent2Pipe: ActionItem;
  cleanBlankPipe: ActionItem;
  cleanZeroCheckPipe: ActionItem;
  cleanRangeCheckPipe: ActionItem;
  drainSamplePipe: ActionItem;
  drainStandardPipe: ActionItem;
  drainReagent1Pipe: ActionItem;
  drainReagent2Pipe: ActionItem;
  drainBlankPipe: ActionItem;
  drainZeroCheckPipe: ActionItem;
  drainRangeCheckPipe: ActionItem;
  drainWastePipe: ActionItem;
  drainWasteWaterPipe: ActionItem;
}

/**
 * 清洗所有管路动作
 */
export const cleanAll: CleanAllAction = {
  cleanDigestionRoom: {
    name: "CleanDigestionRoom",
    text: "清洗消解室",
    GetTime: (): number => 335,
  },
  cleanSamplePipe: {
    name: "CleanSamplePipe",
    text: "清洗水样管",
    GetTime: (): number => 120,
  },
  cleanStandardPipe: {
    name: "CleanStandardPipe",
    text: "清洗量程校准液管",
    GetTime: (): number => 120,
  },
  cleanReagent1Pipe: {
    name: "CleanReagent1Pipe",
    text: "清洗试剂一管",
    GetTime: (): number => 120,
  },
  cleanReagent2Pipe: {
    name: "CleanReagent2Pipe",
    text: "清洗试剂二管",
    GetTime: (): number => 120,
  },
  cleanBlankPipe: {
    name: "CleanBlankPipe",
    text: "清洗零点校准液管",
    GetTime: (): number => 100,
  },
  cleanZeroCheckPipe: {
    name: "CleanZeroCheckPipe",
    text: "清洗零点核查液管",
    GetTime: (): number => 120,
  },
  cleanRangeCheckPipe: {
    name: "CleanRangeCheckPipe",
    text: "清洗标样(跨度)核查液管",
    GetTime: (): number => 120,
  },
  drainSamplePipe: {
    name: "DrainSamplePipe",
    text: "排空水样管",
    GetTime: (): number => 20,
  },
  drainStandardPipe: {
    name: "DrainStandardPipe",
    text: "排空量程校准液管",
    GetTime: (): number => 20,
  },
  drainReagent1Pipe: {
    name: "DrainReagent1Pipe",
    text: "排空试剂一管",
    GetTime: (): number => 20,
  },
  drainReagent2Pipe: {
    name: "DrainReagent2Pipe",
    text: "排空试剂二管",
    GetTime: (): number => 20,
  },
  drainBlankPipe: {
    name: "DrainBlankPipe",
    text: "排空零点校准液管",
    GetTime: (): number => 20,
  },
  drainZeroCheckPipe: {
    name: "DrainZeroCheckPipe",
    text: "排空零点核查液管",
    GetTime: (): number => 20,
  },
  drainRangeCheckPipe: {
    name: "DrainRangeCheckPipe",
    text: "排空标样(跨度)核查液管",
    GetTime: (): number => 20,
  },
  drainWastePipe: {
    name: "DrainWastePipe",
    text: "排空分析废液管",
    GetTime: (): number => 20,
  },
  drainWasteWaterPipe: {
    name: "DrainWasteWaterPipe",
    text: "排空清洗废水管",
    GetTime: (): number => 20,
  },
};

/**
 * 自动泵检查动作
 */
export const autoPumpCheck: ActionItem = {
  name: "AutoPumpCheck",
  text: "定量泵自动校准",
  GetTime: (): number => 180,
};

/**
 * 泵检查动作接口
 */
export interface PumpCheckAction {
  drainMeterPipe: ActionItem;
  meterToMinMeterPoint: ActionItem;
  meterToMaxMeterPoint: ActionItem;
}

/**
 * 泵检查动作
 */
export const pumpCheck: PumpCheckAction = {
  drainMeterPipe: {
    name: "DrainMeterPipe",
    text: "排空定量管",
    GetTime: (): number => 12,
  },
  meterToMinMeterPoint: {
    name: "MeterToMinMeterPoint",
    text: "定量至最小定量点",
    GetTime: (): number => 25,
  },
  meterToMaxMeterPoint: {
    name: "MeterToMaxMeterPoint",
    text: "定量至最大定量点",
    GetTime: (): number => {
      const valve = config.hardware.meterPoint.point[1].setVolume - config.hardware.meterPoint.point[0].setVolume;
      return Math.floor(valve * 20);
    },
  },
};

/**
 * 驱动板通信检查
 */
export const DCCommunication: ActionItem = {
  name: "DCCommunicationCheck",
  text: "驱动板检测",
};

/**
 * 智能诊断动作
 */
export const smartCoolDetect: ActionItem = {
  name: "SmartCoolDetect",
  text: "冷却模块诊断",
};

export const smartHeatDetect: ActionItem = {
  name: "SmartHeatDetect",
  text: "加热模块诊断",
};

export const smartMeasureDetect: ActionItem = {
  name: "SmartMeasureDetect",
  text: "测量模块诊断",
};

export const smartMeterDetect: ActionItem = {
  name: "SmartMeterDetect",
  text: "定量模块诊断",
};

export const smartBlankValveDetect: ActionItem = {
  name: "SmartBlankValveDetect",
  text: "零点校准液阀诊断",
};

export const smartSampleValveDetect: ActionItem = {
  name: "SmartSampleValveDetect",
  text: "水样阀诊断",
};

export const smartStandardValveDetect: ActionItem = {
  name: "SmartStandardValveDetect",
  text: "量程校准液阀诊断",
};

export const smartZeroCheckValveDetect: ActionItem = {
  name: "SmartZeroCheckValveDetect",
  text: "零点核查阀诊断",
};

export const smartRangeCheckValveDetect: ActionItem = {
  name: "SmartRangeCheckValveDetect",
  text: "标样(跨度)核查阀诊断",
};

export const smartReagent1ValveDetect: ActionItem = {
  name: "SmartReagent1ValveDetect",
  text: "试剂一阀诊断",
};

export const smartReagent2ValveDetect: ActionItem = {
  name: "SmartReagent2ValveDetect",
  text: "试剂二阀诊断",
};

export const smartDigestionRoomValveDetect: ActionItem = {
  name: "SmartDigestionRoomValveDetect",
  text: "消解室阀诊断",
};

export const smartWasteValveDetect: ActionItem = {
  name: "SmartWasteValveDetect",
  text: "分析废液阀诊断",
};

export const smartWasteWaterValveDetect: ActionItem = {
  name: "SmartWasteWaterValveDetect",
  text: "清洗废水阀诊断",
};

/**
 * 液体操作动作
 */
export const suckFromBlank: ActionItem = {
  name: "SuckFromBlank",
  text: "填充零点校准液",
};

export const drainToBlank: ActionItem = {
  name: "DrainToBlank",
  text: "排至零点校准液管",
};

export const suckFromSample: ActionItem = {
  name: "SuckFromSample",
  text: "填充水样",
};

export const drainToSample: ActionItem = {
  name: "DrainToSample",
  text: "排至水样管",
};

export const suckFromStandard: ActionItem = {
  name: "SuckFromStandard",
  text: "填充量程校准液",
};

export const drainToStandard: ActionItem = {
  name: "DrainToStandard",
  text: "排至量程校准液管",
};

export const suckFromZeroCheck: ActionItem = {
  name: "SuckFromZeroCheck",
  text: "填充零点核查液",
};

export const drainToZeroCheck: ActionItem = {
  name: "DrainToZeroCheck",
  text: "排至零点核查液管",
};

export const suckFromRangeCheck: ActionItem = {
  name: "SuckFromRangeCheck",
  text: "填充标样(跨度)核查液",
};

export const drainToRangeCheck: ActionItem = {
  name: "DrainToRangeCheck",
  text: "排至标样(跨度)核查液管",
};

export const suckFromReagent1: ActionItem = {
  name: "SuckFromReagent1",
  text: "填充试剂1",
};

export const drainToReagent1: ActionItem = {
  name: "DrainToReagent1",
  text: "排至试剂1管",
};

export const suckFromReagent2: ActionItem = {
  name: "SuckFromReagent2",
  text: "填充试剂2",
};

export const drainToReagent2: ActionItem = {
  name: "DrainToReagent2",
  text: "排至试剂2管",
};

export const suckFromReagent2Spare: ActionItem = {
  name: "SuckFromReagent2Spare",
  text: "填充试剂2(备用)",
};

export const drainToReagent2Spare: ActionItem = {
  name: "DrainToReagent2Spare",
  text: "排至试剂2管(备用)",
};

export const suckFromDigestionRoom: ActionItem = {
  name: "SuckFromDigestionRoom",
  text: "吸消解室溶液",
};

export const drainToDigestionRoom: ActionItem = {
  name: "DrainToDigestionRoom",
  text: "排至消解室",
};

export const drainToWaste: ActionItem = {
  name: "DrainToWaste",
  text: "定量管排至分析废液",
};

export const drainToWasteWater: ActionItem = {
  name: "DrainToWasteWater",
  text: "定量管排至清洗废水",
};

export const suckBlankToDigestionRoom: ActionItem = {
  name: "SuckBlankToDigestionRoom",
  text: "吸零点校准液至消解室",
};

export const suckDigestionRoomToWaste: ActionItem = {
  name: "SuckDigestionRoomToWaste",
  text: "排消解液至分析废液",
};

export const suckDigestionRoomToWasteWater: ActionItem = {
  name: "SuckDigestionRoomToWasteWater",
  text: "排消解液至清洗废水",
};

export const gasSealCheck: ActionItem = {
  name: "GasSealCheck",
  text: "气密性检查",
};

export const oneKeyHeating: ActionItem = {
  name: "OneKeyHeating",
  text: "一键加热",
};

/**
 * 定量AD调节动作接口
 */
export interface MeterADAdjustFlowAction {
  drainMeterPipe: ActionItem;
  adjustMeterPointOne: ActionItem;
  adjustMeterPointTwo: ActionItem;
}

/**
 * 定量AD调节动作
 */
export const meterADAdjust: ActionItem = {
  name: "MeterADAdjust",
  text: "定量AD调节",
  GetTime: (): number => 35,
};

export const meterADAdjustFlow: MeterADAdjustFlowAction = {
  drainMeterPipe: {
    name: "DrainMeterPipe",
    text: "排空定量管",
    GetTime: (): number => 12,
  },
  adjustMeterPointOne: {
    name: "AdjustMeterPointOne",
    text: "调节定量点1",
  },
  adjustMeterPointTwo: {
    name: "AdjustMeterPointTwo",
    text: "调节定量点2",
  },
};

/**
 * 测量AD调节动作接口
 */
export interface MeasureADAdjustFlowAction {
  drainFromDigestionRoom: ActionItem;
  pumpToDigestionRoom: ActionItem;
  adjustReference: ActionItem;
  adjustMeasure: ActionItem;
}

/**
 * 测量AD调节动作
 */
export const measureADAdjust: ActionItem = {
  name: "MeasureADAdjust",
  text: "测量AD调节",
  GetTime: (): number => 280,
};

export const measureADAdjustFlow: MeasureADAdjustFlowAction = {
  drainFromDigestionRoom: {
    name: "DrainFromDigestionRoom",
    text: "排空消解室",
    GetTime: (): number => 40,
  },
  pumpToDigestionRoom: {
    name: "PumpToDigestionRoom",
    text: "吸零点校准液至消解室",
    GetTime: (): number => {
      const maxValve = config.hardware.meterPoint.point[1].setVolume;
      return Math.floor(4 / maxValve * 20);
    },
  },
  adjustReference: {
    name: "AdjustReference",
    text: "调节参考端",
  },
  adjustMeasure: {
    name: "AdjustMeasure",
    text: "调节测量端",
  },
};

/**
 * 主控板升级动作
 */
export const masterUpdate: ActionItem = {
  name: "Updater",
  text: "升级中",
};

export const erase: ActionItem = {
  name: "Erase",
  text: "擦除",
};

export const writeProgram: ActionItem = {
  name: "WriteProgram",
  text: "烧写",
};

/**
 * 硬件测试动作接口
 */
export interface HardwareTestAction {
  pumpTest: ActionItem;
  sampleValveTest: ActionItem;
  reagent1ValveTest: ActionItem;
  reagent2ValveTest: ActionItem;
  standardValveTest: ActionItem;
  zeroCheckkValveTest: ActionItem;
  rangeCheckValveTest: ActionItem;
  blankValveTest: ActionItem;
  wasteValveTest: ActionItem;
  wasteWaterValveTest: ActionItem;
  digestUpValveTest: ActionItem;
  digestBottomValveTest: ActionItem;
  heaterTest: ActionItem;
  coolerTest: ActionItem;
  measuerLEDTest: ActionItem;
  meter1LEDTest: ActionItem;
  meter2LEDTest: ActionItem;
  collectSampleRelayTest: ActionItem;
  relay1Test: ActionItem;
  relay2Test: ActionItem;
  sampleCurrent4Output: ActionItem;
  sampleCurrent12Output: ActionItem;
  sampleCurrent20Output: ActionItem;
  systemFanTest: ActionItem;
}

/**
 * 硬件测试动作
 */
export const hardwareTest: HardwareTestAction = {
  pumpTest: {
    name: "PumpTest",
    text: "泵测试",
  },
  sampleValveTest: {
    name: "SampleValveTest",
    text: "水样阀测试",
  },
  reagent1ValveTest: {
    name: "Reagent1ValveTest",
    text: "试剂一阀测试",
  },
  reagent2ValveTest: {
    name: "Reagent2ValveTest",
    text: "试剂二阀测试",
  },
  standardValveTest: {
    name: "StandardValveTest",
    text: "量程校准液阀测试",
  },
  zeroCheckkValveTest: {
    name: "ZeroCheckkValveTest",
    text: "零点核查阀测试",
  },
  rangeCheckValveTest: {
    name: "RangeCheckValveTest",
    text: "标样(跨度)核查阀测试",
  },
  blankValveTest: {
    name: "BlankValveTest",
    text: "零点校准液阀测试",
  },
  wasteValveTest: {
    name: "WasteValveTest",
    text: "分析废液阀测试",
  },
  wasteWaterValveTest: {
    name: "WasteWaterValveTest",
    text: "清洗废水阀测试",
  },
  digestUpValveTest: {
    name: "DigestUpValveTest",
    text: "消解上阀测试",
  },
  digestBottomValveTest: {
    name: "DigestBottomValveTest",
    text: "消解下阀测试",
  },
  heaterTest: {
    name: "HeaterTest",
    text: "消解加热测试",
  },
  coolerTest: {
    name: "CoolerTest",
    text: "消解冷却测试",
  },
  measuerLEDTest: {
    name: "MeasuerLEDTest",
    text: "测量LED",
  },
  meter1LEDTest: {
    name: "Meter1LEDTest",
    text: "定量点一LED",
  },
  meter2LEDTest: {
    name: "Meter2LEDTest",
    text: "定量点二LED",
  },
  collectSampleRelayTest: {
    name: "CollectSampleRelayTest",
    text: "采水继电器",
  },
  relay1Test: {
    name: "Relay1Test",
    text: "继电器1",
  },
  relay2Test: {
    name: "Relay2Test",
    text: "继电器2",
  },
  sampleCurrent4Output: {
    name: "SampleCurrent4Output",
    text: "样品4mA输出",
  },
  sampleCurrent12Output: {
    name: "SampleCurrent12Output",
    text: "样品12mA输出",
  },
  sampleCurrent20Output: {
    name: "SampleCurrent20Output",
    text: "样品20mA输出",
  },
  systemFanTest: {
    name: "SystemFanTest",
    text: "机箱冷却",
  },
};

/**
 * 运行动作配置接口
 */
export interface RunActionConfig {
  collectSample: CollectSampleAction;
  digestSafetyCheck: ActionItem;
  measure: MeasureAction;
  oneKeyMaintain: OneKeyMaintainAction;
  cleanMeterPipe: ActionItem;
  cleanDigestionRoom: ActionItem;
  cleanDeeply: ActionItem;
  cleanAll: CleanAllAction;
  autoPumpCheck: ActionItem;
  pumpCheck: PumpCheckAction;
  DCCommunication: ActionItem;
  smartCoolDetect: ActionItem;
  smartHeatDetect: ActionItem;
  smartMeasureDetect: ActionItem;
  smartMeterDetect: ActionItem;
  smartBlankValveDetect: ActionItem;
  smartSampleValveDetect: ActionItem;
  smartStandardValveDetect: ActionItem;
  smartZeroCheckValveDetect: ActionItem;
  smartRangeCheckValveDetect: ActionItem;
  smartReagent1ValveDetect: ActionItem;
  smartReagent2ValveDetect: ActionItem;
  smartDigestionRoomValveDetect: ActionItem;
  smartWasteValveDetect: ActionItem;
  smartWasteWaterValveDetect: ActionItem;
  suckFromBlank: ActionItem;
  drainToBlank: ActionItem;
  suckFromSample: ActionItem;
  drainToSample: ActionItem;
  suckFromStandard: ActionItem;
  drainToStandard: ActionItem;
  suckFromZeroCheck: ActionItem;
  drainToZeroCheck: ActionItem;
  suckFromRangeCheck: ActionItem;
  drainToRangeCheck: ActionItem;
  suckFromReagent1: ActionItem;
  drainToReagent1: ActionItem;
  suckFromReagent2: ActionItem;
  drainToReagent2: ActionItem;
  suckFromReagent2Spare: ActionItem;
  drainToReagent2Spare: ActionItem;
  suckFromDigestionRoom: ActionItem;
  drainToDigestionRoom: ActionItem;
  drainToWaste: ActionItem;
  drainToWasteWater: ActionItem;
  suckBlankToDigestionRoom: ActionItem;
  suckDigestionRoomToWaste: ActionItem;
  suckDigestionRoomToWasteWater: ActionItem;
  gasSealCheck: ActionItem;
  oneKeyHeating: ActionItem;
  meterADAdjust: ActionItem;
  meterADAdjustFlow: MeterADAdjustFlowAction;
  measureADAdjust: ActionItem;
  measureADAdjustFlow: MeasureADAdjustFlowAction;
  masterUpdate: ActionItem;
  erase: ActionItem;
  writeProgram: ActionItem;
  hardwareTest: HardwareTestAction;
}

/**
 * 运行动作配置导出
 */
export const runAction: RunActionConfig = {
  collectSample,
  digestSafetyCheck,
  measure,
  oneKeyMaintain,
  cleanMeterPipe,
  cleanDigestionRoom,
  cleanDeeply,
  cleanAll,
  autoPumpCheck,
  pumpCheck,
  DCCommunication,
  smartCoolDetect,
  smartHeatDetect,
  smartMeasureDetect,
  smartMeterDetect,
  smartBlankValveDetect,
  smartSampleValveDetect,
  smartStandardValveDetect,
  smartZeroCheckValveDetect,
  smartRangeCheckValveDetect,
  smartReagent1ValveDetect,
  smartReagent2ValveDetect,
  smartDigestionRoomValveDetect,
  smartWasteValveDetect,
  smartWasteWaterValveDetect,
  suckFromBlank,
  drainToBlank,
  suckFromSample,
  drainToSample,
  suckFromStandard,
  drainToStandard,
  suckFromZeroCheck,
  drainToZeroCheck,
  suckFromRangeCheck,
  drainToRangeCheck,
  suckFromReagent1,
  drainToReagent1,
  suckFromReagent2,
  drainToReagent2,
  suckFromReagent2Spare,
  drainToReagent2Spare,
  suckFromDigestionRoom,
  drainToDigestionRoom,
  drainToWaste,
  drainToWasteWater,
  suckBlankToDigestionRoom,
  suckDigestionRoomToWaste,
  suckDigestionRoomToWasteWater,
  gasSealCheck,
  oneKeyHeating,
  meterADAdjust,
  meterADAdjustFlow,
  measureADAdjust,
  measureADAdjustFlow,
  masterUpdate,
  erase,
  writeProgram,
  hardwareTest,
};
