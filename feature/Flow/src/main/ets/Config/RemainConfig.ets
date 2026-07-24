import { DateTimeUtil } from "base";
import { RemainConfig } from 'dataservice';

// export interface RemainItem {
//   total: number;  // 总量
//   cycle: number;  // 更换周期
//   lastTime: number; // 上次更换时间
// }
//
// export interface RemainConfig {
//   standard: RemainItem;    // 标样
//   blank: RemainItem;       // 零点校准液
//   zeroCheck: RemainItem;   // 零点核查液
//   rangeCheck: RemainItem;  // 量程核查液
//   waste: RemainItem;       // 废液桶
//   wasteWater: RemainItem;  // 废水桶
//   reagent1: RemainItem;    // 试剂1
//   reagent2: RemainItem;    // 试剂2
// }

// 余量配置
export let remainConfig: RemainConfig = {
  standard: {
    total: 500,
    cycle: 1,
    lastTime: DateTimeUtil.getTimestamp(),
  },
  blank: {
    total: 10000,
    cycle: 1,
    lastTime: DateTimeUtil.getTimestamp(),
  },
  zeroCheck: {
    total: 500,
    cycle: 1,
    lastTime: DateTimeUtil.getTimestamp(),
  },
  rangeCheck: {
    total: 500,
    cycle: 1,
    lastTime: DateTimeUtil.getTimestamp(),
  },
  waste: {
    total: 25000,
    cycle: 3,
    lastTime: DateTimeUtil.getTimestamp(),
  },
  wasteWater: {
    total: 25000,
    cycle: 3,
    lastTime: DateTimeUtil.getTimestamp(),
  },
  reagent1: {
    total: 500,
    cycle: 1,
    lastTime: DateTimeUtil.getTimestamp(),
  },
  reagent2: {
    total: 500,
    cycle: 1,
    lastTime: DateTimeUtil.getTimestamp(),
  },
  reagentClean:{
    total: 500,
    cycle: 1,
    lastTime: DateTimeUtil.getTimestamp(),
  },
};
