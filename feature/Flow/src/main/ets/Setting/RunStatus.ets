
import { runAction } from './RunAction'
import { config } from '../Config/Config'

/**
 * 运行状态项接口
 */
export interface StatusItem {
  name: string;
  text: string;
  GetTime?: () => number;
}

/**
 * 运行状态配置接口
 */
export interface RunStatusConfig {
  collectSample: StatusItem;
  digesterCooling: StatusItem;
  cleanMeterPipe: StatusItem;
  cleanDigestionRoom: StatusItem;
  cleanDeeply: StatusItem;
  oneKeyRenew: StatusItem;
  multiValveAutoClean: StatusItem;
  cleanAll: StatusItem;
  measureBlank: StatusItem;
  measureSample: StatusItem;
  measureStandard: StatusItem;
  measureCheckStandard: StatusItem;
  measureZeroCheck: StatusItem;
  measureRangeCheck: StatusItem;
  measureQualityHandle: StatusItem;
  measureAddstandard: StatusItem;
  measureParallel: StatusItem;
  measureExtAddstandard: StatusItem;
  measureExtParallel: StatusItem;
  calibrate: StatusItem;
  oneKeyMaintain: StatusItem;
  onlyCalibrateBlank: StatusItem;
  onlyCalibrateStandard: StatusItem;
  range1CurveCalibrate: StatusItem;
  range2CurveCalibrate: StatusItem;
  range3CurveCalibrate: StatusItem;
  communication: StatusItem;
  smartDetect: StatusItem;
  liquidOperate: StatusItem;
  combineOperate: StatusItem;
  DCUpdate: StatusItem;
  hardwareTest: StatusItem;
  masterUpdate: StatusItem;
  autoPumpCheck: StatusItem;
  meterADAdjust: StatusItem;
  measureADAdjust: StatusItem;
}

/**
 * 运行状态配置
 */
export const runStatus: RunStatusConfig = {
  collectSample: {
    name: "CollectSample",
    text: "采集水样",
    GetTime: (): number => {
      return config.interconnection.miningWaterTime + config.interconnection.silentTime;
    },
  },
  digesterCooling: {
    name: "DigesterCooling",
    text: "消解室冷却",
    GetTime: (): number => {
      // return setting.runAction.digestSafetyCheck.GetTime();
      if ( runAction.digestSafetyCheck.GetTime ) {
        return runAction.digestSafetyCheck.GetTime();
      } else {
        return 50;
      }
    },
  },
  cleanMeterPipe: {
    name: "CleanMeterPipe",
    text: "清洗定量管",
    GetTime: (): number => {
      // return setting.runAction.cleanMeterPipe.GetTime();
      if ( runAction.cleanMeterPipe.GetTime ) {
        return runAction.cleanMeterPipe.GetTime();
      } else {
        return 50;
      }
    },
  },
  cleanDigestionRoom: {
    name: "CleanDigestionRoom",
    text: "清洗消解室",
    GetTime: (): number => {
      // return setting.runAction.cleanDigestionRoom.GetTime();
      if ( runAction.cleanDigestionRoom.GetTime ) {
        return runAction.cleanDigestionRoom.GetTime();
      } else {
        return 335;
      }
    },
  },
  cleanDeeply: {
    name: "CleanDeeply",
    text: "深度清洗",
    GetTime: (): number => {
      // return setting.runAction.cleanDeeply.GetTime();
      if ( runAction.cleanDeeply.GetTime ) {
        return runAction.cleanDeeply.GetTime();
      } else {
        return 870;
      }
    },
  },
  oneKeyRenew: {
    name: "OneKeyRenew",
    text: "一键填充试剂",
    GetTime: (): number => 600,
  },
  multiValveAutoClean: {
    name: "MultiValveAutoClean",
    text: "多联阀自动清洗",
    GetTime: (): number => 600,
  },
  cleanAll: {
    name: "CleanAll",
    text: "清洗所有管路",
    GetTime: (): number => {
      let totalTime = 940;
      // if (config.system.targetMap.EXTEND.enable === true) {
      //   totalTime += 240;
      // }
      return totalTime;
    },
  },
  measureBlank: {
    name: "MeasureBlank",
    text: "测量零点校准液",
    GetTime: (): number => {
      let totalTime = 2300;
      // const range = config.measureParam.range[config.measureParam.currentRange + 1];
      const range = config.measureParam.range[config.measureParam.currentRange + 1];
      if (range === 1) {
        totalTime += 150;
      } else if (range === 2) {
        totalTime += 350;
      } else if (range === 3) {
        totalTime += 500;
      }
      // let executeTime = 0;
      // for (const [, v] of Object.entries(status.measure.measurerTime)) {
      //   if (v.name !== "" && v.time1 !== -1 && v.time2 !== -1) {
      //     if (Math.abs(v.time1 - v.time2) <= v.time2 * 0.3) {
      //       executeTime += v.time2;
      //     } else {
      //       executeTime += v.time1;
      //     }
      //   }
      // }
      // if (executeTime !== 0) {
      //   totalTime = executeTime;
      // }
      return totalTime;
    },
  },
  measureSample: {
    name: "MeasureSample",
    text: "测量水样",
    GetTime: (): number => {
      let totalTime = 2300;
      const range = config.measureParam.range[config.measureParam.currentRange + 1];
      if (range === 1) {
        totalTime += 150;
      } else if (range === 2) {
        totalTime += 350;
      } else if (range === 3) {
        totalTime += 500;
      }
      // let executeTime = 0;
      // for (const [, v] of Object.entries(status.measure.measurerTime)) {
      //   if (v.name !== "" && v.time1 !== -1 && v.time2 !== -1) {
      //     if (Math.abs(v.time1 - v.time2) <= v.time2 * 0.3) {
      //       executeTime += v.time2;
      //     } else {
      //       executeTime += v.time1;
      //     }
      //   }
      // }
      // if (executeTime !== 0) {
      //   totalTime = executeTime;
      // }
      return totalTime;
    },
  },
  measureStandard: {
    name: "MeasureStandard",
    text: "测量量程校准液",
    GetTime: (): number => {
      let totalTime = 2300;
      const range = config.measureParam.range[config.measureParam.currentRange + 1];
      if (range === 1) {
        totalTime += 150;
      } else if (range === 2) {
        totalTime += 350;
      } else if (range === 3) {
        totalTime += 500;
      }
      // let executeTime = 0;
      // for (const [, v] of Object.entries(status.measure.measurerTime)) {
      //   if (v.name !== "" && v.time1 !== -1 && v.time2 !== -1) {
      //     if (Math.abs(v.time1 - v.time2) <= v.time2 * 0.3) {
      //       executeTime += v.time2;
      //     } else {
      //       executeTime += v.time1;
      //     }
      //   }
      // }
      // if (executeTime !== 0) {
      //   totalTime = executeTime;
      // }
      return totalTime;
    },
  },
  measureCheckStandard: {
    name: "MeasureRangeCheck",
    text: "测量标样(跨度)核查液",
    GetTime: (): number => {
      let totalTime = 2300;
      const range = config.measureParam.range[config.measureParam.currentRange + 1];
      if (range === 1) {
        totalTime += 150;
      } else if (range === 2) {
        totalTime += 350;
      } else if (range === 3) {
        totalTime += 500;
      }
      // let executeTime = 0;
      // for (const [, v] of Object.entries(status.measure.measurerTime)) {
      //   if (v.name !== "" && v.time1 !== -1 && v.time2 !== -1) {
      //     if (Math.abs(v.time1 - v.time2) <= v.time2 * 0.3) {
      //       executeTime += v.time2;
      //     } else {
      //       executeTime += v.time1;
      //     }
      //   }
      // }
      // if (executeTime !== 0) {
      //   totalTime = executeTime;
      // }
      return totalTime;
    },
  },
  measureZeroCheck: {
    name: "MeasureZeroCheck",
    text: "零点核查",
    GetTime: (): number => {
      let totalTime = 2300;
      const range = config.measureParam.range[config.measureParam.currentRange + 1];
      if (range === 1) {
        totalTime += 150;
      } else if (range === 2) {
        totalTime += 350;
      } else if (range === 3) {
        totalTime += 500;
      }
      // let executeTime = 0;
      // for (const [, v] of Object.entries(status.measure.measurerTime)) {
      //   if (v.name !== "" && v.time1 !== -1 && v.time2 !== -1) {
      //     if (Math.abs(v.time1 - v.time2) <= v.time2 * 0.3) {
      //       executeTime += v.time2;
      //     } else {
      //       executeTime += v.time1;
      //     }
      //   }
      // }
      // if (executeTime !== 0) {
      //   totalTime = executeTime;
      // }
      return totalTime;
    },
  },
  measureRangeCheck: {
    name: "MeasureRangeCheck",
    text: "测量标样(跨度)核查液",
    GetTime: (): number => {
      let totalTime = 2300;
      const range = config.measureParam.range[config.measureParam.currentRange + 1];
      if (range === 1) {
        totalTime += 150;
      } else if (range === 2) {
        totalTime += 350;
      } else if (range === 3) {
        totalTime += 500;
      }
      // let executeTime = 0;
      // for (const [, v] of Object.entries(status.measure.measurerTime)) {
      //   if (v.name !== "" && v.time1 !== -1 && v.time2 !== -1) {
      //     if (Math.abs(v.time1 - v.time2) <= v.time2 * 0.3) {
      //       executeTime += v.time2;
      //     } else {
      //       executeTime += v.time1;
      //     }
      //   }
      // }
      // if (executeTime !== 0) {
      //   totalTime = executeTime;
      // }
      return totalTime;
    },
  },
  measureQualityHandle: {
    name: "MeasureQualityHandle",
    text: "测质控样",
    GetTime: (): number => 2300,
  },
  measureAddstandard: {
    name: "MeasureAddstandard",
    text: "加标回收",
    GetTime: (): number => 4500,
  },
  measureParallel: {
    name: "MeasureParallel",
    text: "平行测量",
    GetTime: (): number => 4500,
  },
  measureExtAddstandard: {
    name: "MeasureExtAddstandard",
    text: "测加标样",
    GetTime: (): number => {
      let totalTime = 2300;
      const range = config.measureParam.range[config.measureParam.currentRange + 1];
      if (range !== undefined) {
        totalTime += Math.floor(150 * range);
      }
      return totalTime;
    },
  },
  measureExtParallel: {
    name: "MeasureExtParallel",
    text: "测平行样",
    GetTime: (): number => {
      let totalTime = 2300;
      const range = config.measureParam.range[config.measureParam.currentRange + 1];
      if (range !== undefined) {
        totalTime += Math.floor(150 * range);
      }
      return totalTime;
    },
  },
  calibrate: {
    name: "Calibrate",
    text: "校准",
    GetTime: (): number => {
      let totalTime = 2300;
      const range = config.measureParam.range[config.measureParam.currentRange + 1];
      if (range === 1) {
        totalTime += 150;
      } else if (range === 2) {
        totalTime += 350;
      } else if (range === 3) {
        totalTime += 500;
      }
      totalTime *= 2;
      // let executeTime = 0;
      // for (const [, v] of Object.entries(status.measure.measurerTime)) {
      //   if (v.name !== "" && v.time1 !== -1 && v.time2 !== -1) {
      //     if (Math.abs(v.time1 - v.time2) <= v.time2 * 0.3) {
      //       executeTime += v.time2;
      //     } else {
      //       executeTime += v.time1;
      //     }
      //   }
      // }
      // if (executeTime !== 0) {
      //   totalTime = executeTime * 2;
      // }
      // if (config.measureParam.zeroAccurateCalibrate === true) {
      //   totalTime += 2300;
      // }
      // if (config.measureParam.standardAccurateCalibrate === true) {
      //   totalTime += 2300;
      // }
      return totalTime;
    },
  },
  oneKeyMaintain: {
    name: "OneKeyMaintain",
    text: "一键校准",
    GetTime: (): number => {
      let totalTime = 5000;
      // let executeTime = 0;
      // for (const [, v] of Object.entries(status.measure.measurerTime)) {
      //   if (v.name !== "" && v.time1 !== -1 && v.time2 !== -1) {
      //     if (Math.abs(v.time1 - v.time2) <= v.time2 * 0.3) {
      //       executeTime += v.time2;
      //     } else {
      //       executeTime += v.time1;
      //     }
      //   }
      // }
      // if (executeTime !== 0) {
      //   totalTime = executeTime * 2 + runStatus.oneKeyRenew.GetTime();
      // }
      // const currentTime = Date.now() / 1000;
      // const lastTime = status.measure.newResult.calibrate.dateTime + 144 * 3600;
      // if (lastTime - currentTime < 0) {
      //   totalTime += runStatus.cleanDeeply.GetTime();
      // }
      // if (config.measureParam.zeroAccurateCalibrate === true) {
      //   totalTime += 2300;
      // }
      // if (config.measureParam.standardAccurateCalibrate === true) {
      //   totalTime += 2300;
      // }
      // if (config.system.targetMap.EXTEND.enable === true) {
      //   totalTime += 100;
      // }
      return totalTime;
    },
  },
  onlyCalibrateBlank: {
    name: "OnlyCalibrateBlank",
    text: "零点校准",
    GetTime: (): number => {
      let totalTime = 2300;
      if (config.measureParam.zeroAccurateCalibrate === true) {
        totalTime += 4600;
      }
      return totalTime;
    },
  },
  onlyCalibrateStandard: {
    name: "OnlyCalibrateStandard",
    text: "量程校准",
    GetTime: (): number => {
      let totalTime = 2300;
      if (config.measureParam.standardAccurateCalibrate === true) {
        totalTime += 4600;
      }
      return totalTime;
    },
  },
  range1CurveCalibrate: {
    name: "Range1CurveCalibrate",
    text: "量程一因子",
    GetTime: (): number => 2300,
  },
  range2CurveCalibrate: {
    name: "Range2CurveCalibrate",
    text: "量程二因子",
    GetTime: (): number => 2450,
  },
  range3CurveCalibrate: {
    name: "Range3CurveCalibrate",
    text: "量程三因子",
    GetTime: (): number => 2590,
  },
  communication: {
    name: "CommunicationCheck",
    text: "通信检测",
  },
  smartDetect: {
    name: "SmartDetect",
    text: "智能诊断",
  },
  liquidOperate: {
    name: "LiquidOperate",
    text: "管道操作",
  },
  combineOperate: {
    name: "CombineOperate",
    text: "组合操作",
  },
  DCUpdate: {
    name: "DCUpdate",
    text: "驱动板升级",
  },
  hardwareTest: {
    name: "HardwareTest",
    text: "硬件测试",
  },
  masterUpdate: {
    name: "MASTER",
    text: "主控板升级",
  },
  autoPumpCheck: {
    name: "AutoPumpCheck",
    text: "定量泵自动校准",
    GetTime: (): number => {
      if(runAction.pumpCheck.drainMeterPipe.GetTime !== undefined
        && runAction.pumpCheck.meterToMinMeterPoint.GetTime !== undefined
        && runAction.pumpCheck.meterToMaxMeterPoint.GetTime !== undefined){
          return 2 * runAction.pumpCheck.drainMeterPipe.GetTime()
              + runAction.pumpCheck.meterToMinMeterPoint.GetTime()
              + runAction.pumpCheck.meterToMaxMeterPoint.GetTime();
        }
        return 180;
    },
  },
  meterADAdjust: {
    name: "MeterADAdjust",
    text: "定量AD调节",
    GetTime: (): number => {
      if(runAction.meterADAdjust.GetTime !== undefined) {
        return runAction.meterADAdjust.GetTime();
      }
      return 35;
    },
  },
  measureADAdjust: {
    name: "MeasureADAdjust",
    text: "测量AD调节",
    GetTime: (): number => {
      if(runAction.measureADAdjust.GetTime !== undefined) {
        return runAction.measureADAdjust.GetTime();
      }
      return 280;
    },
  },
};
