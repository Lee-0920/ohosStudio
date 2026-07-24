
import { MeasureStatus,CalibrateItem,MeasurerSaveTimeItem,MeasurerTimeItem } from 'dataservice';
import { DateTimeUtil } from 'base';

// export interface ScheduleItem {
//   dateTime: number; // 日期时间
// }
//
// export interface Schedule {
//   autoMeasure: ScheduleItem;      // 自动测量
//   zeroCheck: ScheduleItem;        // 零点核查
//   rangeCheck: ScheduleItem;       // 标样(跨度)核查
//   autoCalibrate: ScheduleItem;    // 自动校准
//   autoClean: ScheduleItem;        // 自动清洗
//   autoBlankCheck: ScheduleItem;   // 自动测零点校准液
//   autoCheck: ScheduleItem;        // 自动核查
//   autoAddStandard: ScheduleItem;  // 自动加标
//   autoParallel: ScheduleItem;     // 自动平行
// }
//
// export interface ReportItem {
//   dateTime: number;      // 日期时间
//   consistency: number;   // 4-20输出浓度
//   absorbance: number;    // 吸光度
//   resultInfo: string;    // 数据标识
//   resultType?: number;   // 测量类型
//   measureTime?: number;  // 测量时长
//   deviceTypeNum?: number; // 设备参数类型号
//   oldTypeNum?: number;   // 旧设备参数类型号
//   checkError?: number;   // 偏差值
// }
//
// export interface Report {
//   measure: ReportItem;          // 测量结果上报
//   addStandard: ReportItem;      // 加标样上报
//   parallel: ReportItem;         // 平行样上报
//   check: ReportItem;            // 核查上报
//   blankCheck: ReportItem;       // 零点校准液核查上报
//   zeroCheck: ReportItem;        // 零点核查上报
//   rangeCheck: ReportItem;       // 标样(跨度)核查上报
//   qualityHandle: ReportItem;    // 质控样上报
//   complexResult: ReportItem;    // 复合测量结果上报
// }
//
// export interface OfflineItem {
//   dateTime: number;      // 日期时间
//   consistency: number;   // 4-20输出浓度
//   absorbance: number;    // 吸光度
//   resultInfo: string;    // 数据标识
//   resultType?: number;   // 测量类型
//   measureTime?: number;  // 测量时长
//   deviceTypeNum?: number; // 设备参数类型号
//   oldTypeNum?: number;   // 旧设备参数类型号
// }
//
// export interface Offline {
//   measure: OfflineItem;         // 测量结果离线缓存
//   addStandard: OfflineItem;     // 加标样离线缓存
//   parallel: OfflineItem;        // 平行样离线缓存
//   check: OfflineItem;           // 核查离线缓存
//   blankCheck: OfflineItem;      // 零点校准液核查离线缓存
//   zeroCheck: OfflineItem;       // 零点核查离线缓存
//   rangeCheck: OfflineItem;      // 标样(跨度)核查离线缓存
//   qualityHandle: OfflineItem;   // 质控样离线缓存
// }
//
// export interface ProformaResultItem {
//   dateTime: number;      // 测量日期
//   consistency: number;   // 测量浓度
//   absorbance: number;    // 吸光度
//   blankReference: number; // 空白参考AD值
//   blankMeasure: number;  // 空白测量AD值
//   initReference: number; // 初始参考AD值
//   initMeasure: number;   // 初始测量AD值
//   finalReference: number; // 反应参考AD值
//   finalMeasure: number;  // 反应测量AD值
// }
//
// export interface ProformaResult {
//   measure: ProformaResultItem;  // 预估结果
// }
//
// export interface MainResult {
//   dateTime: number;      // 测量日期
//   resultType: number;    // 测量类型
//   consistency: number;   // 测量浓度
// }
//
// export interface NewMeasureResult {
//   dateTime: number;      // 测量日期
//   endDateTime: number;   // 测量日期（结束时间）
//   errorDateTime: number; // 流程错误日期
//   consistency: number;   // 测量浓度
//   resultType: number;    // 测量类型
//   absorbance: number;    // 吸光度
//   resultInfo: string;    // 数据标识
//   resultMark: string;    // 数据标识(兼容初版地表水协议)
//   isUseStart: boolean;   // 是否为用户手动启动
//   isFault: boolean;      // 流程是否出错
//   resultMark_C: number;  // 结果标识(扩展核查和校准)
// }
//
// export interface NewCalibrateResult {
//   dateTime: number;                // 测量日期
//   curveB: number;                  // 曲线截距
//   curveK: number;                  // 曲线斜率
//   point0Consistency: number;       // 零点浓度
//   point1Consistency: number;       // 标点浓度
//   point0Absorbance: number;        // 零点吸光度值
//   point1Absorbance: number;        // 标点吸光度值
//   zeroCalculateConsistency: number; // 零点计算浓度
//   standardCalculateConsistency: number; // 标点计算浓度
//   zeroCheckError: number;          // 零点偏差
//   standardCheckError: number;      // 标点偏差
//   R2: number;                      // 相关系数
//   zeroCalibrateDateTime: number;   // 零点校准时间
//   standardCalibrateDateTime: number; // 量程校准时间
// }
//
// export interface NewResult {
//   mainResult: MainResult;          // 主界面显示结果
//   measure: NewMeasureResult;       // 新测量结果
//   calibrate: NewCalibrateResult;   // 新校准结果
// }
//
// export interface CalibrateItem {
//   dateTime: number;                // 测量日期
//   curveB: number;                  // 曲线截距
//   curveK: number;                  // 曲线斜率
//   point0Consistency: number;       // 零点浓度
//   point1Consistency: number;       // 标点浓度
//   point0Absorbance: number;        // 零点吸光度值
//   point1Absorbance: number;        // 标点吸光度值
//   zeroCalculateConsistency: number; // 零点计算浓度
//   standardCalculateConsistency: number; // 标点计算浓度
//   zeroCheckError: number;          // 零点偏差
//   standardCheckError: number;      // 标点偏差
//   R2: number;                      // 相关系数
//   zeroCalibrateDateTime: number;   // 零点校准时间
//   standardCalibrateDateTime: number; // 量程校准时间
//   userSettings: boolean;           // 是否用户设置
// }
//
// export interface MeasurerSaveTimeItem {
//   name: string;          // 流程名称
//   time1: number;         // 流程时间(第一次)
//   time2: number;         // 流程时间(第二次)
//   time3: number;         // 流程时间(第三次)
//   isBlocking: boolean;   // 异常是否停机
//   checkParam: number;    // 重要参数(参数变化则不检查)
// }
//
// export interface MeasurerTimeItem {
//   name: string;          // 流程名称
//   time1: number;         // 流程时间1
//   time2: number;         // 流程时间2
// }
//
// export interface MeasureStatus {
//   schedule: Schedule;               // 自动测量排期状态
//   report: Report;                   // 上报状态
//   offline: Offline;                 // 离线数据缓存
//   proformaResult: ProformaResult;   // 预估结果
//   newResult: NewResult;             // 新结果
//   calibrate: CalibrateItem[];       // 各量程校准数据
//   standardCurve: number;            // 基准曲线（最新一次完整定标的量程）
//   lastMeasureEndTime: number;       // 上一次测量流程结束日期
//   isDeviceFault: boolean;           // 设备故障状态
//   isFatalError: boolean;            // 致命错误状态
//   isUseStart: boolean;              // 是否为用户手动启动(正在进行的流程)
//   digestionRoomIsBlank: boolean;    // 消解室当前液体是否为空白水
//   isCleanDeeply: boolean;           // 是否进行了深度清洗
//   measurerSaveTime: MeasurerSaveTimeItem[]; // 流程时间记录
//   measurerTime: MeasurerTimeItem[];         // 流程时间记录(简化版)
// }

// 创建校准数据数组的辅助函数
function createCalibrateArray(): CalibrateItem[] {
  const array: CalibrateItem[] = [];
  for (let i = 0; i < 7; i++) {
    array.push({
      dateTime: 0,
      curveB: 0,
      curveK: 1,
      point0Consistency: 0,
      point1Consistency: 0,
      point0Absorbance: 0,
      point1Absorbance: 0,
      zeroCalculateConsistency: 0,
      standardCalculateConsistency: 0,
      zeroCheckError: 0,
      standardCheckError: 0,
      r2: 1,
      zeroCalibrateDateTime: 0,
      standardCalibrateDateTime: 0,
      userSettings: false,
    });
  }
  return array;
}

// 创建测量器保存时间数组的辅助函数
function createMeasurerSaveTimeArray(): MeasurerSaveTimeItem[] {
  const array: MeasurerSaveTimeItem[] = [];
  for (let i = 0; i < 10; i++) {
    array.push({
      name: "",
      time1: -1,
      time2: -1,
      time3: -1,
      isBlocking: false,
      checkParam: 0,
    });
  }
  return array;
}

// 创建测量器时间数组的辅助函数
function createMeasurerTimeArray(): MeasurerTimeItem[] {
  const array: MeasurerTimeItem[] = [];
  for (let i = 0; i < 30; i++) {
    array.push({
      name: "",
      time1: -1,
      time2: -1,
    });
  }
  return array;
}

// 测量状态配置
export const measureStatus: MeasureStatus = {
  schedule: {
    autoMeasure: { dateTime: DateTimeUtil.getTimestamp() },
    zeroCheck: { dateTime: DateTimeUtil.getTimestamp() },
    rangeCheck: { dateTime: DateTimeUtil.getTimestamp() },
    autoCalibrate: { dateTime: DateTimeUtil.getTimestamp() },
    autoClean: { dateTime: DateTimeUtil.getTimestamp() },
    autoBlankCheck: { dateTime: DateTimeUtil.getTimestamp() },
    autoCheck: { dateTime: DateTimeUtil.getTimestamp() },
    autoAddStandard: { dateTime: DateTimeUtil.getTimestamp() },
    autoParallel: { dateTime: DateTimeUtil.getTimestamp() },
  },
  report: {
    measure: { dateTime: 0, consistency: 0, resultType: 0, measureTime: 0, absorbance: 0, deviceTypeNum: 0, oldTypeNum: 0, resultInfo: "N" },
    addStandard: { dateTime: 0, consistency: 0, absorbance: 0, resultInfo: "N" },
    parallel: { dateTime: 0, consistency: 0, absorbance: 0, resultInfo: "N" },
    check: { dateTime: 0, consistency: 0, absorbance: 0, resultInfo: "N" },
    blankCheck: { dateTime: 0, consistency: 0, absorbance: 0, resultInfo: "N" },
    zeroCheck: { dateTime: 0, consistency: 0, absorbance: 0, resultInfo: "N" },
    rangeCheck: { dateTime: 0, consistency: 0, absorbance: 0, resultInfo: "N", checkError: 0 },
    qualityHandle: { dateTime: 0, consistency: 0, absorbance: 0, resultInfo: "N", checkError: 0 },
    complexResult: { dateTime: 0, consistency: 0, resultType: 0, measureTime: 0, absorbance: 0, deviceTypeNum: 0, oldTypeNum: 0, resultInfo: "N" },
  },
  offline: {
    measure: { dateTime: 0, consistency: 0, resultType: 0, measureTime: 0, absorbance: 0, deviceTypeNum: 0, oldTypeNum: 0, resultInfo: "B" },
    addStandard: { dateTime: 0, consistency: 0, absorbance: 0, resultInfo: "B" },
    parallel: { dateTime: 0, consistency: 0, absorbance: 0, resultInfo: "B" },
    check: { dateTime: 0, consistency: 0, absorbance: 0, resultInfo: "B" },
    blankCheck: { dateTime: 0, consistency: 0, absorbance: 0, resultInfo: "B" },
    zeroCheck: { dateTime: 0, consistency: 0, absorbance: 0, resultInfo: "B" },
    rangeCheck: { dateTime: 0, consistency: 0, absorbance: 0, resultInfo: "B" },
    qualityHandle: { dateTime: 0, consistency: 0, absorbance: 0, resultInfo: "B" },
  },
  proformaResult: {
    measure: {
      dateTime: 0,
      consistency: 0,
      absorbance: 0,
      blankReference: 0,
      blankMeasure: 0,
      initReference: 0,
      initMeasure: 0,
      finalReference: 0,
      finalMeasure: 0,
    },
  },
  newResult: {
    mainResult: { dateTime: 0, resultType: 255, consistency: 0 },
    measure: {
      dateTime: 0,
      endDateTime: 0,
      errorDateTime: 0,
      consistency: 0,
      resultType: 255,
      absorbance: 0,
      resultInfo: "N",
      resultMark: "N",
      isUseStart: false,
      isFault: false,
      resultMarkC: 0,
    },
    calibrate: {
      dateTime: 0,
      curveB: 0,
      curveK: 1,
      point0Consistency: 0,
      point1Consistency: 0,
      point0Absorbance: 0,
      point1Absorbance: 0,
      zeroCalculateConsistency: 0,
      standardCalculateConsistency: 0,
      zeroCheckError: 0,
      standardCheckError: 0,
      r2: 1,
      zeroCalibrateDateTime: 0,
      standardCalibrateDateTime: 0,
    },
  },
  calibrate: createCalibrateArray(),
  standardCurve: 0,
  lastMeasureEndTime: 0,
  isDeviceFault: false,
  isFatalError: false,
  isUseStart: false,
  digestionRoomIsBlank: false,
  lastMeasureFail: 0,
  measurerSaveTime: createMeasurerSaveTimeArray(),
  measurerTime: createMeasurerTimeArray(),
};
