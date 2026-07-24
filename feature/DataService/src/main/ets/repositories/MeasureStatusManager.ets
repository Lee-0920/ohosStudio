// repositories/MeasureStatusManager.ets
import preferences from '@ohos.data.preferences';
import { MEASURE_STATUS_PREFERENCES, } from '../database/preferences/PreferencesConfig';
import { PreferencesUtil } from '../database/preferences/PreferencesUtil';
import { RoleType } from 'permission';
import {
  MeasureRunning,
  MeasureStatus,
  MeasureStatusSchedule,
  MeasureStatusReport,
  MeasureStatusOffline,
  MeasureStatusProformaResult,
  MeasureStatusNewResult,
  CalibrateItem,
  MeasurerSaveTimeItem,
  MeasurerTimeItem,
  MeasureReportItem,
  RangeCheckReportItem,
  QualityHandleReportItem,
  MeasureOfflineItem,
  ProformaResultMeasure,
  NewResultMain,
  NewResultMeasure,
  NewResultCalibrate,
  ScheduleAutoItem,
  ScheduleZeroCheckItem,
  ScheduleRangeCheckItem,
  ScheduleAutoCalibrateItem,
  ScheduleAutoCleanItem,
  ScheduleAutoBlankCheckItem,
  ScheduleAutoCheckItem,
  ScheduleAutoAddStandardItem,
  ScheduleAutoParallelItem
} from '../database/preferences/models/PreferenceModels';

const MEASURE_STATUS_KEY = 'measure_status';

/**
 * 测量状态管理器
 * 使用独立的偏好数据库文件，与 SettingsManager 隔离
 */
export class MeasureStatusManager {
  private static instance: MeasureStatusManager | null = null;
  private prefUtil: PreferencesUtil | null = null;

  private constructor() {}

  static getInstance(): MeasureStatusManager {
    if (MeasureStatusManager.instance === null) {
      MeasureStatusManager.instance = new MeasureStatusManager();
    }
    return MeasureStatusManager.instance;
  }

  async init(context: Context): Promise<void> {
    this.prefUtil = new PreferencesUtil(MEASURE_STATUS_PREFERENCES);
    await this.prefUtil.init(context);
    await this.initDefaultConfig();
  }

  private getPref(): PreferencesUtil {
    if (this.prefUtil === null) {
      throw new Error('MeasureStatusManager not initialized, please call init() first');
    }
    return this.prefUtil;
  }

  //不重复创建默认数据库
  private async initDefaultConfig(): Promise<void> {
    const hasData = await this.getPref().hasKey(MEASURE_STATUS_KEY);
    if (!hasData) {
      await this.setMeasureStatus(this.getDefaultMeasureStatus());
    }
  }

  // ==================== 测量状态 ====================

  async getMeasureStatus(): Promise<MeasureStatus | null> {
    return this.getPref().getObject<MeasureStatus | null>(MEASURE_STATUS_KEY, null);
  }

  async setMeasureStatus(status: MeasureStatus): Promise<void> {
    await this.getPref().putObject(MEASURE_STATUS_KEY, status);
  }

  // ==================== 排程时间更新 ====================

  async updateAutoMeasureDateTime(dateTime: number): Promise<void> {
    const status = await this.getMeasureStatus();
    if (status) {
      status.schedule.autoMeasure.dateTime = dateTime;
      await this.setMeasureStatus(status);
    }
  }

  async updateZeroCheckDateTime(dateTime: number): Promise<void> {
    const status = await this.getMeasureStatus();
    if (status) {
      status.schedule.zeroCheck.dateTime = dateTime;
      await this.setMeasureStatus(status);
    }
  }

  async updateRangeCheckDateTime(dateTime: number): Promise<void> {
    const status = await this.getMeasureStatus();
    if (status) {
      status.schedule.rangeCheck.dateTime = dateTime;
      await this.setMeasureStatus(status);
    }
  }

  async updateAutoCalibrateDateTime(dateTime: number): Promise<void> {
    const status = await this.getMeasureStatus();
    if (status) {
      status.schedule.autoCalibrate.dateTime = dateTime;
      await this.setMeasureStatus(status);
    }
  }

  async updateAutoCleanDateTime(dateTime: number): Promise<void> {
    const status = await this.getMeasureStatus();
    if (status) {
      status.schedule.autoClean.dateTime = dateTime;
      await this.setMeasureStatus(status);
    }
  }

  async updateAutoBlankCheckDateTime(dateTime: number): Promise<void> {
    const status = await this.getMeasureStatus();
    if (status) {
      status.schedule.autoBlankCheck.dateTime = dateTime;
      await this.setMeasureStatus(status);
    }
  }

  async updateAutoCheckDateTime(dateTime: number): Promise<void> {
    const status = await this.getMeasureStatus();
    if (status) {
      status.schedule.autoCheck.dateTime = dateTime;
      await this.setMeasureStatus(status);
    }
  }

  async updateAutoAddStandardDateTime(dateTime: number): Promise<void> {
    const status = await this.getMeasureStatus();
    if (status) {
      status.schedule.autoAddStandard.dateTime = dateTime;
      await this.setMeasureStatus(status);
    }
  }

  async updateAutoParallelDateTime(dateTime: number): Promise<void> {
    const status = await this.getMeasureStatus();
    if (status) {
      status.schedule.autoParallel.dateTime = dateTime;
      await this.setMeasureStatus(status);
    }
  }

  // ==================== 测量结果上报更新 ====================

  async updateMeasureReport(report: MeasureReportItem): Promise<void> {
    const status = await this.getMeasureStatus();
    if (status) {
      status.report.measure = report;
      await this.setMeasureStatus(status);
    }
  }

  async updateAddStandardReport(report: MeasureReportItem): Promise<void> {
    const status = await this.getMeasureStatus();
    if (status) {
      status.report.addStandard = report;
      await this.setMeasureStatus(status);
    }
  }

  async updateParallelReport(report: MeasureReportItem): Promise<void> {
    const status = await this.getMeasureStatus();
    if (status) {
      status.report.parallel = report;
      await this.setMeasureStatus(status);
    }
  }

  async updateCheckReport(report: MeasureReportItem): Promise<void> {
    const status = await this.getMeasureStatus();
    if (status) {
      status.report.check = report;
      await this.setMeasureStatus(status);
    }
  }

  async updateBlankCheckReport(report: MeasureReportItem): Promise<void> {
    const status = await this.getMeasureStatus();
    if (status) {
      status.report.blankCheck = report;
      await this.setMeasureStatus(status);
    }
  }

  async updateZeroCheckReport(report: MeasureReportItem): Promise<void> {
    const status = await this.getMeasureStatus();
    if (status) {
      status.report.zeroCheck = report;
      await this.setMeasureStatus(status);
    }
  }

  async updateRangeCheckReport(report: RangeCheckReportItem): Promise<void> {
    const status = await this.getMeasureStatus();
    if (status) {
      status.report.rangeCheck = report;
      await this.setMeasureStatus(status);
    }
  }

  async updateQualityHandleReport(report: QualityHandleReportItem): Promise<void> {
    const status = await this.getMeasureStatus();
    if (status) {
      status.report.qualityHandle = report;
      await this.setMeasureStatus(status);
    }
  }

  async updateComplexResultReport(report: MeasureReportItem): Promise<void> {
    const status = await this.getMeasureStatus();
    if (status) {
      status.report.complexResult = report;
      await this.setMeasureStatus(status);
    }
  }

  // ==================== 离线数据更新 ====================

  async updateOfflineMeasure(item: MeasureOfflineItem): Promise<void> {
    const status = await this.getMeasureStatus();
    if (status) {
      status.offline.measure = item;
      await this.setMeasureStatus(status);
    }
  }

  async updateOfflineAddStandard(item: MeasureOfflineItem): Promise<void> {
    const status = await this.getMeasureStatus();
    if (status) {
      status.offline.addStandard = item;
      await this.setMeasureStatus(status);
    }
  }

  async updateOfflineParallel(item: MeasureOfflineItem): Promise<void> {
    const status = await this.getMeasureStatus();
    if (status) {
      status.offline.parallel = item;
      await this.setMeasureStatus(status);
    }
  }

  // ==================== 设备状态更新 ====================

  async setDeviceFault(flag: boolean): Promise<void> {
    const status = await this.getMeasureStatus();
    if (status) {
      status.isDeviceFault = flag;
      await this.setMeasureStatus(status);
    }
  }

  async setFatalError(flag: boolean): Promise<void> {
    const status = await this.getMeasureStatus();
    if (status) {
      status.isFatalError = flag;
      await this.setMeasureStatus(status);
    }
  }

  async setUseStart(flag: boolean): Promise<void> {
    const status = await this.getMeasureStatus();
    if (status) {
      status.isUseStart = flag;
      await this.setMeasureStatus(status);
    }
  }

  async setDigestionRoomIsBlank(flag: boolean): Promise<void> {
    const status = await this.getMeasureStatus();
    if (status) {
      status.digestionRoomIsBlank = flag;
      await this.setMeasureStatus(status);
    }
  }

  async setLastMeasureFail(value: number): Promise<void> {
    const status = await this.getMeasureStatus();
    if (status) {
      status.lastMeasureFail = value;
      await this.setMeasureStatus(status);
    }
  }

  async setLastMeasureEndTime(timestamp: number): Promise<void> {
    const status = await this.getMeasureStatus();
    if (status) {
      status.lastMeasureEndTime = timestamp;
      await this.setMeasureStatus(status);
    }
  }

  // ==================== 校准曲线操作 ====================

  async addCalibrateItem(item: CalibrateItem): Promise<void> {
    const status = await this.getMeasureStatus();
    if (status) {
      status.calibrate.push(item);
      if (status.calibrate.length > 10) {
        status.calibrate = status.calibrate.slice(-10);
      }
      await this.setMeasureStatus(status);
    }
  }

  async getValidCalibrateItem(): Promise<CalibrateItem | null> {
    const status = await this.getMeasureStatus();
    if (status && status.calibrate.length > 0) {
      for (let i = status.calibrate.length - 1; i >= 0; i--) {
        if (status.calibrate[i].r2 >= 0.99) {
          return status.calibrate[i];
        }
      }
      return status.calibrate[status.calibrate.length - 1];
    }
    return null;
  }

  async setStandardCurve(index: number): Promise<void> {
    const status = await this.getMeasureStatus();
    if (status) {
      status.standardCurve = index;
      await this.setMeasureStatus(status);
    }
  }

  async updateCalibrateRecord(index: number, item: CalibrateItem): Promise<void> {
    const status = await this.getMeasureStatus();
    if (status && index >= 0 && index < status.calibrate.length) {
      status.calibrate[index] = item;
      await this.setMeasureStatus(status);
    }
  }

  // ==================== 新结果更新 ====================

  async updateNewResultMain(dateTime: number, resultType: number, consistency: number): Promise<void> {
    const status = await this.getMeasureStatus();
    if (status) {
      status.newResult.mainResult.dateTime = dateTime;
      status.newResult.mainResult.resultType = resultType;
      status.newResult.mainResult.consistency = consistency;
      await this.setMeasureStatus(status);
    }
  }

  async updateNewResultMeasure(measure: NewResultMeasure): Promise<void> {
    const status = await this.getMeasureStatus();
    if (status) {
      status.newResult.measure = measure;
      await this.setMeasureStatus(status);
    }
  }

  async updateNewResultCalibrate(calibrate: NewResultCalibrate): Promise<void> {
    const status = await this.getMeasureStatus();
    if (status) {
      status.newResult.calibrate = calibrate;
      await this.setMeasureStatus(status);
    }
  }

  // ==================== 预估结果更新 ====================

  async updateProformaResultMeasure(measure: ProformaResultMeasure): Promise<void> {
    const status = await this.getMeasureStatus();
    if (status) {
      status.proformaResult.measure = measure;
      await this.setMeasureStatus(status);
    }
  }

  // ==================== 测量流程时间存储 ====================

  async updateMeasurerSaveTime(index: number, item: MeasurerSaveTimeItem): Promise<void> {
    const status = await this.getMeasureStatus();
    if (status && index >= 0 && index < status.measurerSaveTime.length) {
      status.measurerSaveTime[index] = item;
      await this.setMeasureStatus(status);
    }
  }

  async updateMeasurerTime(index: number, item: MeasurerTimeItem): Promise<void> {
    const status = await this.getMeasureStatus();
    if (status && index >= 0 && index < status.measurerTime.length) {
      status.measurerTime[index] = item;
      await this.setMeasureStatus(status);
    }
  }

  // ==================== 工具方法 ====================

  async getDeviceFault(): Promise<boolean> {
    const status = await this.getMeasureStatus();
    return status?.isDeviceFault ?? false;
  }

  async getLastMeasureFail(): Promise<number> {
    const status = await this.getMeasureStatus();
    return status?.lastMeasureFail ?? 2;
  }

  async getStandardCurve(): Promise<number> {
    const status = await this.getMeasureStatus();
    return status?.standardCurve ?? 0;
  }

  async getCalibrateList(): Promise<CalibrateItem[]> {
    const status = await this.getMeasureStatus();
    return status?.calibrate ?? [];
  }

  async resetMeasureStatus(): Promise<void> {
    await this.setMeasureStatus(this.getDefaultMeasureStatus());
  }

  /**
   * 恢复出厂设置 - 测量状态部分
   * 对应 LS 脚本 FactoryTime.ls defaultRestore 中恢复测量状态的逻辑：
   * - 仅管理员可恢复测量状态（schedule、lastMeasureEndTime、standardCurve、calibrate）
   *
   * @param userType 用户类型：RoleType
   */
  async restoreFactorySettings(userType: RoleType): Promise<void> {
    // 只有管理员才能恢复测量状态
    if (userType !== RoleType.ADMIN) {
      return;
    }

    const defaultStatus = this.getDefaultMeasureStatus();
    const currentStatus = await this.getMeasureStatus();

    if (currentStatus) {
      // 恢复排期时间
      currentStatus.schedule = defaultStatus.schedule;
      // 恢复上次测量结束时间
      currentStatus.lastMeasureEndTime = defaultStatus.lastMeasureEndTime;
      // 恢复标准曲线索引
      currentStatus.standardCurve = defaultStatus.standardCurve;
      // // 恢复 7 个校准量程的数据
      // currentStatus.calibrate = defaultStatus.calibrate;
      // // 恢复测量状态报告数据
      // currentStatus.report = defaultStatus.report;
      // // 恢复离线数据缓存
      // currentStatus.offline = defaultStatus.offline;
      // // 恢复预估结果
      // currentStatus.proformaResult = defaultStatus.proformaResult;
      // // 恢复新测量结果
      // currentStatus.newResult = defaultStatus.newResult;

      await this.setMeasureStatus(currentStatus);
    } else {
      await this.setMeasureStatus(defaultStatus);
    }
  }

  // ==================== 默认配置 ====================

  private getDefaultMeasureStatus(): MeasureStatus {
    const currentTime: number = Date.now();
    const autoItem: ScheduleAutoItem = { dateTime: currentTime };
    const zeroItem: ScheduleZeroCheckItem = { dateTime: currentTime };
    const rangeItem: ScheduleRangeCheckItem = { dateTime: currentTime };
    const autoCalItem: ScheduleAutoCalibrateItem = { dateTime: currentTime };
    const autoCleanItem: ScheduleAutoCleanItem = { dateTime: currentTime };
    const autoBlankItem: ScheduleAutoBlankCheckItem = { dateTime: currentTime };
    const autoCheckItem: ScheduleAutoCheckItem = { dateTime: currentTime };
    const autoAddStdItem: ScheduleAutoAddStandardItem = { dateTime: currentTime };
    const autoParallelItem: ScheduleAutoParallelItem = { dateTime: currentTime };

    // schedule =                      -- 自动测量
    const schedule: MeasureStatusSchedule = {
      autoMeasure: autoItem,
      zeroCheck: zeroItem,
      rangeCheck: rangeItem,
      autoCalibrate: autoCalItem,
      autoClean: autoCleanItem,
      autoBlankCheck: autoBlankItem,
      autoCheck: autoCheckItem,
      autoAddStandard: autoAddStdItem,
      autoParallel: autoParallelItem,
    };

    const defaultReportItem: MeasureReportItem = {
      dateTime: 0,
      consistency: 0,
      resultType: 0,
      measureTime: 0,
      absorbance: 0,
      deviceTypeNum: 0,
      oldTypeNum: 0,
      resultInfo: 'N',
    };
    const rangeCheckReport: RangeCheckReportItem = {
      dateTime: 0,
      consistency: 0,
      absorbance: 0,
      resultInfo: 'N',
      checkError: 0
    };
    const qualityHandleReport: QualityHandleReportItem = {
      dateTime: 0,
      consistency: 0,
      absorbance: 0,
      resultInfo: 'N',
      checkError: 0
    };
    const complexReport: MeasureReportItem = {
      dateTime: 0,
      consistency: 0,
      resultType: 0,
      measureTime: 0,
      absorbance: 0,
      deviceTypeNum: 0,
      oldTypeNum: 0,
      resultInfo: 'N',
    };

    // report =
    const report: MeasureStatusReport = {
      measure: defaultReportItem,
      addStandard: defaultReportItem,
      parallel: defaultReportItem,
      check: defaultReportItem,
      blankCheck: defaultReportItem,
      zeroCheck: defaultReportItem,
      rangeCheck: rangeCheckReport,
      qualityHandle: qualityHandleReport,
      complexResult: complexReport,
    };

    const offlineBase: MeasureOfflineItem = {
      dateTime: 0,
      consistency: 0,
      resultType: 0,
      measureTime: 0,
      absorbance: 0,
      deviceTypeNum: 0,
      oldTypeNum: 0,
      resultInfo: 'B',
    };

    const offlineRange: MeasureOfflineItem = {
      dateTime: 0,
      consistency: 0,
      absorbance: 0,
      resultInfo: 'B'
    };

    // offline =                       --离线数据缓存
    const offline: MeasureStatusOffline = {
      measure: offlineBase,
      addStandard: offlineRange,
      parallel: offlineRange,
      check: offlineRange,
      blankCheck: offlineRange,
      zeroCheck: offlineRange,
      rangeCheck: offlineRange,
      qualityHandle: offlineRange,
    };

    const proformaMeasure: ProformaResultMeasure = {
      dateTime: 0,
      consistency: 0,
      absorbance: 0,
      blankReference: 0,
      blankMeasure: 0,
      initReference: 0,
      initMeasure: 0,
      finalReference: 0,
      finalMeasure: 0,
    };

    // proformaResult =
    const proformaResult: MeasureStatusProformaResult = {
      measure: proformaMeasure
    };

    // mainResult =                -- 主界面显示结果
    const mainResult: NewResultMain = {
      dateTime: 0,
      resultType: 255,
      consistency: 0
    };

    // measure =                   -- 新测量结果
    const newMeasure: NewResultMeasure = {
      dateTime: 0,
      endDateTime: 0,
      errorDateTime: 0,
      consistency: 0,
      resultType: 255,
      absorbance: 0,
      resultInfo: 'N',
      resultMark: 'N',
      isUseStart: false,
      isFault: false,
      resultMarkC: 0,
    };

    // calibrate =                 -- 新校准结果
    const newCalibrate: NewResultCalibrate = {
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
    };

    // newResult =
    const newResult: MeasureStatusNewResult = {
      mainResult,
      measure: newMeasure,
      calibrate: newCalibrate
    };

    const calibrateItem: CalibrateItem = {
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
    };

    // calibrate = 7个校准量程的数据
    const calibrateArray: CalibrateItem[] = Array(7).fill(calibrateItem);

    const saveTimeItem: MeasurerSaveTimeItem = {
      name: '',
      time1: -1,
      time2: -1,
      time3: -1,
      isBlocking: false,
      checkParam: 0
    };

    // measurerSaveTime = {
    const measurerSaveTime: MeasurerSaveTimeItem[] = Array(10).fill(saveTimeItem);

    const timeItem: MeasurerTimeItem = {
      name: '',
      time1: -1,
      time2: -1
    };

    // measurerTime =
    const measurerTime: MeasurerTimeItem[] = Array(30).fill(timeItem);

    return {
      schedule,
      report,
      offline,
      proformaResult,
      newResult,
      calibrate: calibrateArray,
      standardCurve: 0,
      lastMeasureEndTime: 0,
      isDeviceFault: false,
      isFatalError: false,
      isUseStart: false,
      digestionRoomIsBlank: false,
      lastMeasureFail: 2,
      measurerSaveTime,
      measurerTime,
    };
  }

  async saveCalibrateConsistencyAdded(status: MeasureStatus, calibrateItem: CalibrateItem, currentRangeIndex: number): Promise<void> {
    if (calibrateItem)
    {
      if (currentRangeIndex >= 0 && currentRangeIndex < status.calibrate.length)
      {
        status.calibrate[currentRangeIndex].zeroCalculateConsistency = calibrateItem.zeroCalculateConsistency;
        status.calibrate[currentRangeIndex].zeroCheckError = calibrateItem.zeroCheckError;

        status.calibrate[currentRangeIndex].standardCalculateConsistency = calibrateItem.standardCalculateConsistency;
        status.calibrate[currentRangeIndex].standardCheckError = calibrateItem.standardCheckError;
      }

      status.newResult.calibrate.zeroCalculateConsistency = calibrateItem.zeroCalculateConsistency;
      status.newResult.calibrate.zeroCheckError = calibrateItem.zeroCheckError;

      status.newResult.calibrate.standardCalculateConsistency = calibrateItem.standardCalculateConsistency;
      status.newResult.calibrate.standardCheckError = calibrateItem.standardCheckError;

      this.setMeasureStatus(status);
    }
  }

  async calibrateResultAdded(status: MeasureStatus, calibrateItem: CalibrateItem, currentRangeIndex: number): Promise<void> {
    if (calibrateItem)
    {
      status.newResult.calibrate.dateTime = calibrateItem.dateTime;
      status.newResult.calibrate.zeroCalibrateDateTime = calibrateItem.zeroCalibrateDateTime;
      status.newResult.calibrate.standardCalculateConsistency = calibrateItem.standardCalibrateDateTime;
      status.newResult.calibrate.curveK = calibrateItem.curveK;
      status.newResult.calibrate.curveB = calibrateItem.curveB;
      status.newResult.calibrate.point0Consistency = calibrateItem.point0Consistency;
      status.newResult.calibrate.point1Consistency = calibrateItem.point1Consistency;
      status.newResult.calibrate.point0Absorbance = calibrateItem.point1Absorbance;

      if (currentRangeIndex >= 0 && currentRangeIndex < status.calibrate.length)
      {
        status.calibrate[currentRangeIndex].dateTime = calibrateItem.dateTime;
        status.calibrate[currentRangeIndex].zeroCalibrateDateTime = calibrateItem.zeroCalibrateDateTime;
        status.calibrate[currentRangeIndex].standardCalculateConsistency = calibrateItem.standardCalibrateDateTime;
        status.calibrate[currentRangeIndex].curveK = calibrateItem.curveK;
        status.calibrate[currentRangeIndex].curveB = calibrateItem.curveB;
        status.calibrate[currentRangeIndex].point0Consistency = calibrateItem.point0Consistency;
        status.calibrate[currentRangeIndex].point1Consistency = calibrateItem.point1Consistency;
        status.calibrate[currentRangeIndex].point0Absorbance = calibrateItem.point1Absorbance;
      }

      this.setMeasureStatus(status);
    }
  }
}