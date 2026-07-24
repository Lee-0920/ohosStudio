import { FlowTask } from '../FlowManager/FlowTask';
import { DateTimeUtil } from 'base';
import { FlowType, MeasureType, CalibrateType, CleanType } from '../Flow/FlowInterface';
import { DatabaseManager } from '../DataManager/DataBase';
import { config, status } from '../Config/Config'
import {
  SettingsManager,
  MeasureStatusManager,
  MeasureMode,
  TimedPointConfig,
  SchedulerConfig,
  MeasureStatus,
} from 'dataservice';

// 初始化默认值
let measureStatus: MeasureStatus;
let schedulerConfig: SchedulerConfig;

// 初始化数据库
export async function InitDataBase(UIContext: Context): Promise<void> {
  try {
    await DatabaseManager.getInstance().initialize(UIContext);
    await DatabaseManager.getInstance().getMeasureStatus();
    await DatabaseManager.getInstance().getScheduler();
    measureStatus = status.measureStatus;
    schedulerConfig = config.scheduler;
  } catch (err) {
    console.info('Failed to initialize databases: %s', JSON.stringify(err));
  }
}

export async function UpdateSchedulerConfig(): Promise<void> {
  await DatabaseManager.getInstance().getMeasureStatus();
  await DatabaseManager.getInstance().getScheduler();
  measureStatus = status.measureStatus;
  schedulerConfig = config.scheduler;
  console.info('配置更新完成');
}


interface Scheduler {
  name: string;
  text: string;

  isOpen: () => [isOpen: boolean, isTimedMeasure: boolean];
  getPriority: () => number;
  getInterval: () => number;
  getLastTime: () => number;
  getNextTime: () => [isValid: boolean, nextTime: number];
  isRetry: () => boolean;
  calculateNextTime: (startTime: number, runTime: number) => [isValid: boolean, nextTime: number];
  getRunTime: () => number;
  createFlow: (UIContext: Context) => void;
}

export let measureScheduler: Scheduler[] = [
  // 1、校准
  {
    name: "Calibrate",
    text: "校准",

    isOpen: () => {
      let mode = schedulerConfig.calibrate.mode;
      let open = false;
      let isTimedMeasure = false;
      switch (mode) {
        case MeasureMode.Periodic:
          open = true;
          isTimedMeasure = false;
          break;
        case MeasureMode.Continuous:
          open = true;
          isTimedMeasure = false;
          break;
        case MeasureMode.Timed:
          open = true;
          isTimedMeasure = true;
          break;
        case MeasureMode.Trigger:
        case MeasureMode.Manual:
        default:
          open = false;
          isTimedMeasure = false;
      }
      return [open, isTimedMeasure];
    },

    getPriority: () => {
      return 1;
    },

    getInterval: () => {
      let interval = 0;
      let mode = schedulerConfig.calibrate.mode;
      if (mode === MeasureMode.Periodic) {
        interval = schedulerConfig.calibrate.interval;
      } else if (mode === MeasureMode.Timed) {
        interval = 0;
      } else if (mode === MeasureMode.Continuous) {
        let runTime = 1800;
        interval = runTime / 3600;
      }
      return interval;
    },

    getLastTime: () => {
      return measureStatus.schedule.autoCalibrate.dateTime;
    },

    getNextTime: () => {
      let lastTime = measureStatus.schedule.autoCalibrate.dateTime;
      return nextTimeInternal(schedulerConfig.calibrate, lastTime);
    },

    isRetry: () => {
      return false;
    },

    calculateNextTime: (startTime: number, runTime: number) => {
      return calculateNextTimeInternal(schedulerConfig.calibrate,startTime,runTime);
    },

    getRunTime: () => {
      return 1800;
    },

    createFlow: (UIContext: Context) => {
      FlowTask.GetInstance().runFlow('Calibrate', FlowType.Calibrate, CalibrateType.calibrate, UIContext);
    },
  },
  // 2、跨度(量程)核查
  {
    name: "RangeCheck",
    text: "标样(跨度)核查",

    isOpen: () => {
      let mode = schedulerConfig.rangeCheck.mode;
      let open = false;
      let isTimedMeasure = false;
      switch (mode) {
        case MeasureMode.Periodic:
          open = true;
          isTimedMeasure = false;
          break;
        case MeasureMode.Continuous:
          open = false;
          isTimedMeasure = false;
          break;
        case MeasureMode.Timed:
          open = true;
          isTimedMeasure = true;
          break;
        case MeasureMode.Trigger:
        case MeasureMode.Manual:
        default:
          open = false;
          isTimedMeasure = false;
      }
      return [open, isTimedMeasure];
    },

    getPriority: () => {
      return 1;
    },

    getInterval: () => {
      let interval = 0;
      let mode = schedulerConfig.rangeCheck.mode;
      if (mode === MeasureMode.Periodic) {
        interval = schedulerConfig.rangeCheck.interval;
      } else if (mode === MeasureMode.Timed) {
        interval = 0;
      } else if (mode === MeasureMode.Continuous) {
        let runTime = 1800;
        interval = runTime / 3600;
      }
      return interval;
    },

    getLastTime: () => {
      return measureStatus.schedule.rangeCheck.dateTime;
    },

    getNextTime: () => {
      let lastTime = measureStatus.schedule.rangeCheck.dateTime;
      return nextTimeInternal(schedulerConfig.rangeCheck, lastTime);
    },

    isRetry: () => {
      return false;
    },

    calculateNextTime: (startTime: number, runTime: number) => {
      return calculateNextTimeInternal(schedulerConfig.rangeCheck,startTime,runTime);
    },

    getRunTime: () => {
      return 1800;
    },

    createFlow: (UIContext: Context) => {
      FlowTask.GetInstance().runFlow('RangeCheck', FlowType.Measure, MeasureType.RangeCheck, UIContext);
    },
  },
  // 3、零点核查
  {
    name: "ZeroCheck",
    text: "零点核查",

    isOpen: () => {
      let mode = schedulerConfig.zeroCheck.mode;
      let open = false;
      let isTimedMeasure = false;
      switch (mode) {
        case MeasureMode.Periodic:
          open = true;
          isTimedMeasure = false;
          break;
        case MeasureMode.Continuous:
          open = false;
          isTimedMeasure = false;
          break;
        case MeasureMode.Timed:
          open = true;
          isTimedMeasure = true;
          break;
        case MeasureMode.Trigger:
        case MeasureMode.Manual:
        default:
          open = false;
          isTimedMeasure = false;
      }
      return [open, isTimedMeasure];
    },

    getPriority: () => {
      return 0;
    },

    getInterval: () => {
      let interval = 0;
      let mode = schedulerConfig.zeroCheck.mode;
      if (mode === MeasureMode.Periodic) {
        interval = schedulerConfig.zeroCheck.interval;
      } else if (mode === MeasureMode.Timed) {
        interval = 0;
      } else if (mode === MeasureMode.Continuous) {
        let runTime = 1800;
        interval = runTime / 3600;
      }
      return interval;
    },

    getLastTime: () => {
      return measureStatus.schedule.zeroCheck.dateTime;
    },

    getNextTime: () => {
      let lastTime = measureStatus.schedule.rangeCheck.dateTime;
      return nextTimeInternal(schedulerConfig.zeroCheck, lastTime);
    },

    isRetry: () => {
      return false;
    },

    calculateNextTime: (startTime: number, runTime: number) => {
      return calculateNextTimeInternal(schedulerConfig.zeroCheck, startTime, runTime);
    },

    getRunTime: () => {
      return 1800;
    },

    createFlow: (UIContext: Context) => {
      FlowTask.GetInstance().runFlow('ZeroCheck', FlowType.Measure, MeasureType.ZeroCheck, UIContext);
    },
  },
  // 4、测量水样
  {
    name: "MeasureSample",
    text: "测量水样",

    isOpen: () => {
      let mode = schedulerConfig.measure.mode;
      let open = false;
      let isTimedMeasure = false;
      switch (mode) {
        case MeasureMode.Periodic:
          open = true;
          isTimedMeasure = false;
          break;
        case MeasureMode.Continuous:
          open = true;
          isTimedMeasure = false;
          break;
        case MeasureMode.Timed:
          open = true;
          isTimedMeasure = true;
          break;
        case MeasureMode.Trigger:
        case MeasureMode.Manual:
        default:
          open = false;
          isTimedMeasure = false;
      }
      return [open, isTimedMeasure];
    },

    getPriority: () => {
      let priority = 2;
      if (schedulerConfig.measure.mode == MeasureMode.Continuous) {
        priority = 20;
      }
      return priority;
    },

    getInterval: () => {
      let interval = 0;
      let mode = schedulerConfig.measure.mode;
      if (mode === MeasureMode.Periodic) {
        interval = schedulerConfig.measure.interval;
      } else if (mode === MeasureMode.Timed) {
        interval = 0;
      } else if (mode === MeasureMode.Continuous) {
        let runTime = 1800;
        interval = runTime / 3600;
      }
      return interval;
    },

    getLastTime: () => {
      return measureStatus.schedule.autoMeasure.dateTime;
    },

    getNextTime: () => {
      let lastTime = measureStatus.schedule.autoMeasure.dateTime;
      return nextTimeInternal(schedulerConfig.measure, lastTime);
    },

    isRetry: () => {
      return false;
    },

    calculateNextTime: (startTime: number, runTime: number) => {
      return calculateNextTimeInternal(schedulerConfig.measure, startTime, runTime);
    },

    getRunTime: () => {
      return 1800;
    },

    createFlow: (UIContext: Context) => {
      FlowTask.GetInstance().runFlow('MeasureSample', FlowType.Measure, MeasureType.Sample, UIContext);
    },
  },
  // 5、量程校准液核查
  {
    name: "MeasureStandard",
    text: "测量程校准液",

    isOpen: () => {
      if (schedulerConfig.standard.enable == true) {
        return [true, false];
      }
      return [false, false];
    },

    getPriority: () => {
      return 3;
    },

    getInterval: () => {
      return schedulerConfig.standard.interval;
    },

    getLastTime: () => {
      return measureStatus.schedule.autoCheck.dateTime;
    },

    getNextTime: () => {
      return [true, measureStatus.schedule.autoCheck.dateTime + 3600 * schedulerConfig.standard.interval];
    },

    isRetry: () => {
      return false;
    },

    calculateNextTime: (startTime: number, runTime: number) => {
      let nextTime = startTime + 3600 * schedulerConfig.standard.interval;
      return [true, nextTime];
    },

    getRunTime: () => {
      return 1800;
    },

    createFlow: (UIContext: Context) => {
      FlowTask.GetInstance().runFlow('MeasureStandard', FlowType.Measure, MeasureType.Standard, UIContext);
    },
  },
  // 6、清洗
  {
    name: "Clean",
    text: "清洗",

    isOpen: () => {
      if (schedulerConfig.clean.enable == true) {
        return [true, false];
      }
      return [false, false];
    },

    getPriority: () => {
      return 10;
    },

    getInterval: () => {
      return schedulerConfig.clean.interval;
    },

    getLastTime: () => {
      return measureStatus.schedule.autoClean.dateTime;
    },

    getNextTime: () => {
      let nextTime = measureStatus.schedule.autoClean.dateTime + 3600 * schedulerConfig.clean.interval;
      return [true, nextTime];
    },

    isRetry: () => {
      return false;
    },

    calculateNextTime: (startTime: number, runTime: number) => {
      let nextTime = startTime + 3600 * schedulerConfig.clean.interval;
      return [true, nextTime];
    },

    getRunTime: () => {
      return 1800;
    },

    createFlow: (UIContext: Context) => {
      FlowTask.GetInstance().runFlow('Clean', FlowType.Clean, CleanType.cleanDeeply, UIContext);
    },
  },
  // 7、测零点校准液
  {
    name: "MeasureBlank",
    text: "测零点校准液",

    isOpen: () => {
      if (schedulerConfig.blankCheck.enable == true) {
        return [true, false];
      }
      return [false, false];
    },

    getPriority: () => {
      return 5;
    },

    getInterval: () => {
      return schedulerConfig.blankCheck.interval;
    },

    getLastTime: () => {
      return measureStatus.schedule.autoBlankCheck.dateTime;
    },

    getNextTime: () => {
      let nextTime = measureStatus.schedule.autoBlankCheck.dateTime;
      return [true, nextTime];
    },

    isRetry: () => {
      return false;
    },

    calculateNextTime: (startTime: number, runTime: number) => {
      let nextTime = startTime + 3600 * schedulerConfig.blankCheck.interval;
      return [true, nextTime];
    },

    getRunTime: () => {
      return 1800;
    },

    createFlow: (UIContext: Context) => {
      FlowTask.GetInstance().runFlow('MeasureBlank', FlowType.Measure, MeasureType.Blank, UIContext);
    },
  },
  // 8、测加标样
  // 9、测平行样
];

/**
 * 计算下次启动时间（内部方法）
 */
function calculateNextTimeInternal(scheduleKey: TimedPointConfig, startTime: number, runTime: number): [isValid: boolean, nextTime: number] {
  const schedule = scheduleKey;
  const mode = schedule.mode;
  let nextTime = 0;
  let isValid = false;
  let currentTime = Date.now();

  switch (mode) {
    case MeasureMode.Periodic: {
      nextTime = startTime + 3600 * schedule.interval;
      isValid = true;
      break;
    }
    case MeasureMode.Timed: {
      const timeList: number[] = [];
      schedule.timedPoint.forEach((enabled: boolean, index: number) => {
        if (enabled) {
          timeList.push(index);
        }
      });

      if (timeList.length > 0) {
        let curDateTime = new Date(currentTime);
        let ret = false;

        for (const hour of timeList) {
          if (curDateTime.getHours() === hour
            && (curDateTime.getMinutes() * 60 + curDateTime.getSeconds()) <= schedulerConfig.timedPointJudgeTime) {
            curDateTime.setHours(hour, 0, 0, 0);
            if (DateTimeUtil.toTimestamp(curDateTime) > runTime) {
              nextTime = DateTimeUtil.toTimestamp(curDateTime);
              ret = true;
              break;
            }
          } else if (curDateTime.getHours() < hour) {
            curDateTime.setHours(hour, 0, 0, 0);
            nextTime = DateTimeUtil.toTimestamp(curDateTime);
            ret = true;
            break;
          }
        }
        if (!ret) {
          let targetDate = new Date(currentTime);
          targetDate.setDate(targetDate.getDate() + 1);
          targetDate.setHours(timeList[0], 0, 0, 0);
          nextTime = DateTimeUtil.toTimestamp(targetDate);
        }

        isValid = true;
      }
      break;
    }
    case MeasureMode.Continuous: {
      nextTime = DateTimeUtil.getTimestamp() + runTime;
      isValid = true;
      break;
    }
    case MeasureMode.Trigger:
    case MeasureMode.Manual:
    default: {
      nextTime = 0;
      isValid = true;
    }
  }

  return [isValid, nextTime];
}

/**
 * 下次启动时间（内部方法）
 */
function nextTimeInternal(scheduleKey: TimedPointConfig, lastTime: number): [isValid: boolean, nextTime: number] {
  const schedule = scheduleKey;
  const mode = schedule.mode;
  let nextTime = 0;
  let isValid = false;
  let currentTime = Date.now(); //当前时间（ms）

  switch (mode) {
    case MeasureMode.Periodic: {
      nextTime = lastTime + 3600 * schedule.interval;
      isValid = true;
      break;
    }
    case MeasureMode.Timed: {
      const timeList: number[] = [];
      schedule.timedPoint.forEach((enabled: boolean, index: number) => {
        if (enabled) {
          timeList.push(index);
        }
      });

      if (timeList.length > 0) {
        let curDateTime = new Date(currentTime);
        let ret = false;

        for (const hour of timeList) {
          if (curDateTime.getHours() === hour
            && (curDateTime.getMinutes() * 60 + curDateTime.getSeconds()) <= schedulerConfig.timedPointJudgeTime) {
            curDateTime.setHours(hour, 0, 0, 0);
            if (DateTimeUtil.toTimestamp(curDateTime) > lastTime) {
              nextTime = DateTimeUtil.toTimestamp(curDateTime);
              ret = true;
              break;
            }
          } else if (curDateTime.getHours() < hour) {
            curDateTime.setHours(hour, 0, 0, 0);
            nextTime = DateTimeUtil.toTimestamp(curDateTime);
            ret = true;
            break;
          }
        }
        if (!ret) {
          let targetDate = new Date(currentTime);
          targetDate.setDate(targetDate.getDate() + 1);
          targetDate.setHours(timeList[0], 0, 0, 0);
          nextTime = DateTimeUtil.toTimestamp(targetDate);
        }
        isValid = true;
      }
      break;
    }
    case MeasureMode.Continuous: {
      nextTime = DateTimeUtil.getTimestamp();
      isValid = true;
      break;
    }
    case MeasureMode.Trigger:
    case MeasureMode.Manual:
    default: {
      nextTime = 0;
      isValid = true;
    }
  }

  return [isValid, nextTime];
}
