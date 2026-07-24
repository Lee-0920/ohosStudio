import { DateTimeUtil } from 'base';
import { SchedulerConfig } from 'dataservice';

/**
 * 测量模式枚举
 */
export enum MeasureMode {
  Trigger = 0,       // 触发测量
  Timed = 1,         // 整点测量
  Periodic = 2,      // 周期测量
  Continuous = 3,    // 连续测量
  Manual = 4,        // 手动测量
}

// export interface ScheduleBase {
//   mode: number; // 测量模式
//   interval: number; // 间隔周期
//   timedPoint: boolean[]; // 定时点列表
//   oneTimedPoint?: number; // 整点测量时间
//   timedPointInterval?: number; // 整点测量间隔时间
//   configChangeTime?: number; // 参数修改时间
//   enable?: boolean; // 是否启用
// }
//
// export interface SchedulerConfig {
//   measure: ScheduleBase; // 测量排期
//   zeroCheck: ScheduleBase; // 零点核查排期
//   rangeCheck: ScheduleBase; // 标样(跨度)核查排期
//   calibrate: ScheduleBase; // 校准排期
//   clean: ScheduleBase; // 清洗排期
//   blankCheck: ScheduleBase; // 测零点校准液排期
//   check: ScheduleBase; // 测量程校准液排期
//   standard: ScheduleBase; // 测核查液排期
//   addStandard: ScheduleBase; // 加标排期
//   parallel: ScheduleBase; // 平行排期
//   timedPointJudgeTime: number; // 整点启动-延长时间
// }


// 创建定时点数组的辅助函数
function createTimedPointArray(value: boolean): boolean[] {
  return new Array(24).fill(value);
}

// 任务调度配置
export const schedulerConfig: SchedulerConfig = {
  measure: {
    mode: MeasureMode.Continuous,
    interval: 2,
    timedPoint: createTimedPointArray(true),
  },
  zeroCheck: {
    mode: MeasureMode.Trigger,
    interval: 168,
    timedPoint: createTimedPointArray(false),
    oneTimedPoint: 8,
    timedPointInterval: 1,
    configChangeTime: DateTimeUtil.getTimestamp(),
  },
  rangeCheck: {
    mode: MeasureMode.Trigger,
    interval: 168,
    timedPoint: createTimedPointArray(false),
    oneTimedPoint: 8,
    timedPointInterval: 1,
    configChangeTime: DateTimeUtil.getTimestamp(),
  },
  calibrate: {
    enable: false,
    mode: MeasureMode.Trigger,
    interval: 168,
    timedPoint: createTimedPointArray(false),
    oneTimedPoint: 8,
    timedPointInterval: 7,
    configChangeTime: DateTimeUtil.getTimestamp(),
  },
  clean: {
    enable: false,
    interval: 168,
    mode: MeasureMode.Trigger,
    timedPoint: [],
  },
  blankCheck: {
    enable: false,
    interval: 168,
    mode: MeasureMode.Trigger,
    timedPoint: [],
  },
  check: {
    enable: false,
    interval: 168,
    mode: MeasureMode.Trigger,
    timedPoint: [],
  },
  standard: {
    enable: false,
    mode: MeasureMode.Trigger,
    interval: 168,
    timedPoint: createTimedPointArray(false),
  },
  addStandard: {
    enable: false,
    interval: 168,
    mode: MeasureMode.Trigger,
    timedPoint: [],
  },
  parallel: {
    enable: false,
    interval: 168,
    mode: MeasureMode.Trigger,
    timedPoint: [],
  },
  timedPointJudgeTime: 5,
};
