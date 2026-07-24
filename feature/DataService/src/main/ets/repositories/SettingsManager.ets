// repositories/SettingsManager.ets
import { PreferencesUtil } from '../database/preferences/PreferencesUtil';
import { Keys, INSTRUMENT_PREFERENCES } from '../database/preferences/PreferencesConfig';
import { RoleType } from 'permission';
import {
  InstrumentInfoConfig,
  MainBoardInfoConfig,
  HardwareConfig,
  MeasureParamConfig,
  SchedulerConfig,
  InterconnectionConfig,
  SystemConfig,
  AuthorizationConfig,
  RemainConfig,
  RemainStatus,
  ConsumableConfig,
  MeasureRunning,
  ManufactureType,
  Language,
  ReportMode,
  SettingIpMode,
  MeasureMode,
  TargetParam,
  CurveParam,
  TimedPointConfig,
  RangeCheckTimedConfig,
  CalibrateTimedConfig,
  StandardTimedConfig,
  CleanConfig,
  SimpleIntervalConfig,
  MeasureLedAd,
  CalibrateCheck,
  PumpPipeConfig,
  DateStruct,
  ReagentLicense,
  MeterPointItem,
  MeterPoint,
  PidParamItem,
  ThermostatParam,
  PumpFactor,
  TempCalibrate,
  MeterLedItem,
  MeterLed,
  MeasureLedInner,
  MeasureLed,
  ScreenSaver,
  AdcDetectItem,
  TargetMapItem,
  RangeViewMapItem,
  PrinterConfig,
  Hj212Platform,
  ValveSetting,
  RemainItem,
  SystemTargetMap,
  GainCalibrate,
} from '../database/preferences/models/PreferenceModels';

import {
  CalibrateRecord,
} from '../database/relational/models/RelationalModels';

/**
 * 设置管理器
 */
export class SettingsManager {
  private static instance: SettingsManager | null = null;
  private prefUtil: PreferencesUtil | null = null;
  private context: Context | null = null;

  private constructor() {}

  static getInstance(): SettingsManager {
    if (SettingsManager.instance === null) {
      SettingsManager.instance = new SettingsManager();
    }
    return SettingsManager.instance;
  }

  async init(context: Context): Promise<void> {
    this.context = context;
    this.prefUtil = new PreferencesUtil(INSTRUMENT_PREFERENCES);
    await this.prefUtil.init(context);
    await this.initDefaultConfigs();
  }

  private getPref(): PreferencesUtil {
    if (this.prefUtil === null) {
      throw new Error('SettingsManager not initialized, please call init() first');
    }
    return this.prefUtil;
  }

  //不重复创建默认数据库
  private async initDefaultConfigs(): Promise<void> {
    const hasInstrumentInfo = await this.getPref().hasKey(Keys.INSTRUMENT_INFO);
    if (!hasInstrumentInfo) {
      await this.loadDefaultConfigs();
    }
  }

  private async loadDefaultConfigs(): Promise<void> {
    await this.setInstrumentInfo(this.getDefaultInstrumentInfo());
    await this.setMainBoardInfo(this.getDefaultMainBoardInfo());
    await this.setHardwareConfig(this.getDefaultHardwareConfig());
    await this.setMeasureParamConfig(this.getDefaultMeasureParamConfig());
    await this.setSchedulerConfig(this.getDefaultSchedulerConfig());
    await this.setInterconnectionConfig(this.getDefaultInterconnectionConfig());
    await this.setSystemConfig(this.getDefaultSystemConfig());
    await this.setAuthorizationConfig(this.getDefaultAuthorizationConfig());
    await this.setRemainConfig(this.getDefaultRemainConfig());
    await this.setRemainStatus(this.getDefaultRemainStatus());
    await this.setConsumableConfig(this.getDefaultConsumableConfig());
    await this.setMeasureRunning(this.getDefaultMeasureRunning());

    await this.setInstrumentType(0);
    await this.setManufactureType(ManufactureType.Ls);
    await this.setProducerStatus(false);
    await this.setAppLanguage(Language.SimplifiedChinese);
  }

  // ==================== 仪器信息相关 ====================

  async getInstrumentInfo(): Promise<InstrumentInfoConfig | null> {
    return this.getPref().getObject<InstrumentInfoConfig | null>(Keys.INSTRUMENT_INFO, null);
  }

  async setInstrumentInfo(config: InstrumentInfoConfig): Promise<void> {
    await this.getPref().putObject(Keys.INSTRUMENT_INFO, config);
  }

  async getMainBoardInfo(): Promise<MainBoardInfoConfig | null> {
    return this.getPref().getObject<MainBoardInfoConfig | null>(Keys.MAIN_BOARD_INFO, null);
  }

  async setMainBoardInfo(config: MainBoardInfoConfig): Promise<void> {
    await this.getPref().putObject(Keys.MAIN_BOARD_INFO, config);
  }

  async getHardwareConfig(): Promise<HardwareConfig | null> {
    return this.getPref().getObject<HardwareConfig | null>(Keys.HARDWARE_CONFIG, null);
  }

  async setHardwareConfig(config: HardwareConfig): Promise<void> {
    await this.getPref().putObject(Keys.HARDWARE_CONFIG, config);
  }

  // ==================== 测量参数相关 ====================

  async getMeasureParamConfig(): Promise<MeasureParamConfig | null> {
    return this.getPref().getObject<MeasureParamConfig | null>(Keys.MEASURE_PARAM_CONFIG, null);
  }

  async setMeasureParamConfig(config: MeasureParamConfig): Promise<void> {
    await this.getPref().putObject(Keys.MEASURE_PARAM_CONFIG, config);
  }

  // ==================== 排期配置相关 ====================

  async getSchedulerConfig(): Promise<SchedulerConfig | null> {
    return this.getPref().getObject<SchedulerConfig | null>(Keys.SCHEDULER_CONFIG, null);
  }

  async setSchedulerConfig(config: SchedulerConfig): Promise<void> {
    await this.getPref().putObject(Keys.SCHEDULER_CONFIG, config);
  }

  // ==================== 对外接口配置 ====================

  async getInterconnectionConfig(): Promise<InterconnectionConfig | null> {
    return this.getPref().getObject<InterconnectionConfig | null>(Keys.INTERCONNECTION_CONFIG, null);
  }

  async setInterconnectionConfig(config: InterconnectionConfig): Promise<void> {
    await this.getPref().putObject(Keys.INTERCONNECTION_CONFIG, config);
  }

  // ==================== 系统配置 ====================

  async getSystemConfig(): Promise<SystemConfig | null> {
    return this.getPref().getObject<SystemConfig | null>(Keys.SYSTEM_CONFIG, null);
  }

  async setSystemConfig(config: SystemConfig): Promise<void> {
    await this.getPref().putObject(Keys.SYSTEM_CONFIG, config);
  }

  // ==================== 用户授权配置 ====================

  async getAuthorizationConfig(): Promise<AuthorizationConfig | null> {
    return this.getPref().getObject<AuthorizationConfig | null>(Keys.AUTHORIZATION_CONFIG, null);
  }

  async setAuthorizationConfig(config: AuthorizationConfig): Promise<void> {
    await this.getPref().putObject(Keys.AUTHORIZATION_CONFIG, config);
  }

  async verifyPassword(password: string, userType: RoleType): Promise<boolean> {
    const auth = await this.getAuthorizationConfig();
    if (auth === null) return false;
    switch (userType) {
      case RoleType.OPERATOR: return auth.normalUserPassword === password || auth.maintenancePassword === password;
      case RoleType.ADMIN: return auth.administratorPassword === password || auth.superPassword === password;
      default: return false;
    }
  }

  // ==================== 试剂/耗材配置 ====================

  async getRemainConfig(): Promise<RemainConfig | null> {
    return this.getPref().getObject<RemainConfig | null>(Keys.REMAIN_CONFIG, null);
  }

  async setRemainConfig(config: RemainConfig): Promise<void> {
    await this.getPref().putObject(Keys.REMAIN_CONFIG, config);
  }

  async getRemainStatus(): Promise<RemainStatus | null> {
    return this.getPref().getObject<RemainStatus | null>(Keys.REMAIN_STATUS, null);
  }

  async setRemainStatus(status: RemainStatus): Promise<void> {
    await this.getPref().putObject(Keys.REMAIN_STATUS, status);
  }

  /**
   * 更新试剂余量（不使用索引访问，改用显式字段判断）
   */
  async updateReagentRemain(reagentType: keyof RemainStatus, usedVolume: number): Promise<void> {
    const status = await this.getRemainStatus();
    if (status === null) return;
    let newValue: number;
    switch (reagentType) {
      case 'standard':
        newValue = Math.max(0, status.standard - usedVolume);
        status.standard = newValue;
        break;
      case 'blank':
        newValue = Math.max(0, status.blank - usedVolume);
        status.blank = newValue;
        break;
      case 'zeroCheck':
        newValue = Math.max(0, status.zeroCheck - usedVolume);
        status.zeroCheck = newValue;
        break;
      case 'rangeCheck':
        newValue = Math.max(0, status.rangeCheck - usedVolume);
        status.rangeCheck = newValue;
        break;
      case 'waste':
        newValue = Math.max(0, status.waste - usedVolume);
        status.waste = newValue;
        break;
      case 'wasteWater':
        newValue = Math.max(0, status.wasteWater - usedVolume);
        status.wasteWater = newValue;
        break;
      case 'reagent1':
        newValue = Math.max(0, status.reagent1 - usedVolume);
        status.reagent1 = newValue;
        break;
      case 'reagent2':
        newValue = Math.max(0, status.reagent2 - usedVolume);
        status.reagent2 = newValue;
        break;
      case 'reagentClean':
        newValue = Math.max(0, status.reagentClean - usedVolume);
        status.reagentClean = newValue;
        break;
      default:
        return;
    }
    await this.setRemainStatus(status);
  }
  async resetRemainStatus(): Promise<void> {
    const defaultStatus = this.getDefaultRemainStatus();
    await this.setRemainStatus(defaultStatus);
  }

  async getConsumableConfig(): Promise<ConsumableConfig | null> {
    return this.getPref().getObject<ConsumableConfig | null>(Keys.CONSUMABLE_CONFIG, null);
  }

  async setConsumableConfig(config: ConsumableConfig): Promise<void> {
    await this.getPref().putObject(Keys.CONSUMABLE_CONFIG, config);
  }

  // ==================== 测量运行状态 (MeasureRunning) ====================

  async getMeasureRunning(): Promise<MeasureRunning | null> {
    return this.getPref().getObject<MeasureRunning | null>(Keys.MEASURE_RUNNING, null);
  }

  async setMeasureRunning(running: MeasureRunning): Promise<void> {
    await this.getPref().putObject(Keys.MEASURE_RUNNING, running);
  }

  async updateMeasureRunningFlag(flag: boolean): Promise<void> {
    const running = await this.getMeasureRunning();
    if (running) {
      running.isMeasuring = flag;
      await this.setMeasureRunning(running);
    }
  }

  async updateCorrectStopFlow(flag: boolean): Promise<void> {
    const running = await this.getMeasureRunning();
    if (running) {
      running.isCorrectStopFlow = flag;
      await this.setMeasureRunning(running);
    }
  }

  async updateLastMeasureTime(timestamp: number): Promise<void> {
    const running = await this.getMeasureRunning();
    if (running) {
      running.lastMeasureTime = timestamp;
      await this.setMeasureRunning(running);
    }
  }

  async isMeasuring(): Promise<boolean> {
    const running = await this.getMeasureRunning();
    return running?.isMeasuring ?? false;
  }

  // ==================== 其他配置 ====================

  async getInstrumentType(): Promise<number> {
    return this.getPref().getNumber(Keys.INSTRUMENT_TYPE, 0);
  }

  async setInstrumentType(type: number): Promise<void> {
    await this.getPref().putNumber(Keys.INSTRUMENT_TYPE, type);
  }

  async getManufactureType(): Promise<ManufactureType> {
    const value = await this.getPref().getNumber(Keys.MANUFACTURE_TYPE, ManufactureType.Ls);
    return value as ManufactureType;
  }

  async setManufactureType(type: ManufactureType): Promise<void> {
    await this.getPref().putNumber(Keys.MANUFACTURE_TYPE, type);
  }

  async getProducerStatus(): Promise<boolean> {
    return this.getPref().getBoolean(Keys.PRODUCER_STATUS, false);
  }

  async setProducerStatus(status: boolean): Promise<void> {
    await this.getPref().putBoolean(Keys.PRODUCER_STATUS, status);
  }

  async getAppLanguage(): Promise<Language> {
    const value = await this.getPref().getNumber(Keys.APP_LANGUAGE, Language.SimplifiedChinese);
    return value as Language;
  }

  async setAppLanguage(language: Language): Promise<void> {
    await this.getPref().putNumber(Keys.APP_LANGUAGE, language);
  }

  // ==================== 业务辅助方法 ====================
  async getValidInstrumentInfoArgus(argusList: string[]): Promise<string> {
    const paramType = await this.getInstrumentType();
    let result = '';
    let mask = 1;
    for (let i = 0; i < argusList.length; i++) {
      if ((mask & paramType) !== 0) {
        result += argusList[i];
      }
      mask = mask << 1;
    }
    return result;
  }
  async getParamTypeName(): Promise<string> {
    const instrumentType = await this.getInstrumentType();
    if (instrumentType === 1 || instrumentType === 3) {
      return 'Plus';
    }
    return '';
  }

  async getTimedPoint(schedulerName: string): Promise<boolean[]> {
    const scheduler = await this.getSchedulerConfig();
    if (scheduler === null) return [];
    // 使用显式属性访问，而非索引
    if (schedulerName === 'config.scheduler.measure') {
      return scheduler.measure.timedPoint;
    } else if (schedulerName === 'config.scheduler.zeroCheck') {
      return scheduler.zeroCheck.timedPoint;
    } else if (schedulerName === 'config.scheduler.rangeCheck') {
      return scheduler.rangeCheck.timedPoint;
    } else if (schedulerName === 'config.scheduler.calibrate') {
      return scheduler.calibrate.timedPoint;
    }
    return [];
  }

  async setTimedPoint(schedulerName: string, points: boolean[]): Promise<boolean> {
    const scheduler = await this.getSchedulerConfig();
    if (scheduler === null) return false;
    if (schedulerName === 'config.scheduler.measure') {
      scheduler.measure.timedPoint = points;
    } else if (schedulerName === 'config.scheduler.zeroCheck') {
      scheduler.zeroCheck.timedPoint = points;
    } else if (schedulerName === 'config.scheduler.rangeCheck') {
      scheduler.rangeCheck.timedPoint = points;
    } else if (schedulerName === 'config.scheduler.calibrate') {
      scheduler.calibrate.timedPoint = points;
    } else {
      return false;
    }
    await this.setSchedulerConfig(scheduler);
    return true;
  }

  async saveAll(): Promise<void> {
    // 所有 put 操作已自动 flush
  }

  // ==================== 恢复出厂设置 ====================

  /**
   * 恢复出厂设置 - 配置部分
   * 对应 LS 脚本 FactoryTime.ls defaultRestore 的逻辑，根据 userType 权限恢复不同配置：
   *
   * Super（超级用户）：恢复所有配置
   *   - 完整 HardwareConfig（含 tempCalibrate、meterLed、measureLed 等）
   *   - 完整 MeasureParamConfig（保留 reviseParameter 和 curveParam 校准数据）
   *   - 完整 SystemConfig（保留 EXTEND 拓展功能）
   *
   * Administrator（管理员）：恢复部分配置
   *   - 部分 MeasureParamConfig（量程、检查、环境、消化/反应参数等）
   *   - 部分 SystemConfig（故障、HJ212、ADC 等）
   *
   * Maintain（维护人员）：恢复最少配置
   *   - 仅恢复 MeasureParamConfig 的量程相关字段
   *
   * @param userType 用户类型：RoleType
   */
  async restoreFactorySettings(userType: RoleType): Promise<void> {
    // ========== 所有用户都恢复的公共配置 ==========
    // 1. 恢复外联接口配置
    await this.setInterconnectionConfig(this.getDefaultInterconnectionConfig());

    // 2. 恢复测量排期配置
    await this.setSchedulerConfig(this.getDefaultSchedulerConfig());

    // 3. 恢复试剂配置
    await this.setRemainConfig(this.getDefaultRemainConfig());

    // 4. 恢复试剂记录
    await this.setRemainStatus(this.getDefaultRemainStatus());

    // 5. 恢复耗材配置
    await this.setConsumableConfig(this.getDefaultConsumableConfig());

    // 6. 恢复硬件配置（公共部分：定量点设置、meterLed.point）
    await this.restoreHardwareConfigPartial(userType);

    // 7. 恢复测量参数配置（根据权限恢复不同字段）
    await this.restoreMeasureParamConfigPartial(userType);

    // 8. 恢复系统配置（根据权限恢复不同字段）
    await this.restoreSystemConfigPartial(userType);
  }

  /**
   * 恢复硬件配置（根据权限恢复不同字段）
   */
  private async restoreHardwareConfigPartial(userType: RoleType): Promise<void> {
    const defaultConfig = this.getDefaultHardwareConfig();
    let currentConfig = await this.getHardwareConfig();
    if (!currentConfig) {
      await this.setHardwareConfig(defaultConfig);
      return;
    }

    // 恢复定量点设置
    const currentPoints = currentConfig.meterPoint.point;
    const defaultPoints = defaultConfig.meterPoint.point;
    if (currentPoints.length > 2 && defaultPoints.length > 2 &&
        (currentPoints[0].setVolume !== defaultPoints[0].setVolume ||
         currentPoints[1].setVolume !== defaultPoints[1].setVolume)) {
      currentConfig.meterPoint = defaultConfig.meterPoint;
    }

    // 恢复 meterLed.point（所有用户）
    currentConfig.meterLed.point = defaultConfig.meterLed.point;

    // 管理员额外恢复以下字段
    if (userType === RoleType.ADMIN) {
      currentConfig.tempCalibrate = defaultConfig.tempCalibrate;
      currentConfig.meterLed.maxValue = defaultConfig.meterLed.maxValue;
      currentConfig.measureLed = defaultConfig.measureLed;
    }

    await this.setHardwareConfig(currentConfig);
  }

  /**
   * 恢复测量参数配置（根据权限恢复不同字段）
   */
  private async restoreMeasureParamConfigPartial(userType: RoleType): Promise<void> {
    const defaultConfig = this.getDefaultMeasureParamConfig();
    let currentConfig = await this.getMeasureParamConfig();
    if (!currentConfig) {
      await this.setMeasureParamConfig(defaultConfig);
      return;
    }

    if (userType === RoleType.ADMIN) {
      // 管理员：恢复完整配置，但保留 reviseParameter（修正参数）和 curveParam（校准曲线数据）
      const savedReviseParameter = [...currentConfig.reviseParameter];
      const savedCurveParam = currentConfig.curveParam.map((cp): CurveParam => ({
        curveK: cp.curveK,
        curveB: cp.curveB,
        zeroConsistency: cp.zeroConsistency,
        rangeConsistency: cp.rangeConsistency,
        timeStr: cp.timeStr,
      }));

      // 恢复默认配置
      currentConfig = defaultConfig;

      // 恢复保留字段
      currentConfig.reviseParameter = savedReviseParameter;
      currentConfig.curveParam = savedCurveParam;
    } else if (userType === RoleType.OPERATOR) {
      // 运维员：仅恢复量程相关字段
      currentConfig.currentRange = defaultConfig.currentRange;
      currentConfig.calibrateRangeIndex = defaultConfig.calibrateRangeIndex;
      currentConfig.zeroCheckRangeIndex = defaultConfig.zeroCheckRangeIndex;
      currentConfig.rangeCheckRangeIndex = defaultConfig.rangeCheckRangeIndex;
      currentConfig.autoChangeRange = defaultConfig.autoChangeRange;
      currentConfig.activeRangeMode = defaultConfig.activeRangeMode;
      currentConfig.range = [...defaultConfig.range];
    }

    await this.setMeasureParamConfig(currentConfig);
  }

  /**
   * 恢复系统配置（根据权限恢复不同字段）
   */
  private async restoreSystemConfigPartial(userType: RoleType): Promise<void> {
    const defaultConfig = this.getDefaultSystemConfig();
    let currentConfig = await this.getSystemConfig();
    if (!currentConfig) {
      await this.setSystemConfig(defaultConfig);
      return;
    }

    if (userType === RoleType.ADMIN) {
      // 管理员：恢复完整配置，但保留 EXTEND 拓展功能
      const savedTargetEnable = currentConfig.targetMap?.EXTEND?.enable ?? false;
      currentConfig = defaultConfig;
      // 恢复 EXTEND 拓展功能
      if (currentConfig.targetMap?.EXTEND) {
        currentConfig.targetMap.EXTEND.enable = savedTargetEnable;
      }
    }
    // 运维员不恢复系统配置

    await this.setSystemConfig(currentConfig);
  }

  // ==================== 默认配置（所有对象字面量显式使用已声明的接口） ====================
  private getDefaultInstrumentInfo(): InstrumentInfoConfig {
    const manuDate: DateStruct = { year: 2024, month: 1, day: 17 };
    const reagentLicense: ReagentLicense = { enable: false, expirationDate: 0 };
    return {
      model: 'PhotoTek 6000 COD',
      manuDate: manuDate,
      type: 'PT72-CODC',
      manufacturer: '深圳市朗石科学仪器有限公司',
      MfrN: '683776325001W',
      uuid: '',
      sn: 'B00000000',
      reagentLicense: reagentLicense,
      expirationDate: 2145888000,
      license: true,
      permanent: true,
      manufactureType: ManufactureType.Ls,
      showModel: 'PhotoTek 6000 COD',
      showName: '化学需氧量水质自动在线监测仪',
    };
  }

  private getDefaultMainBoardInfo(): MainBoardInfoConfig {
    const manuDate: DateStruct = { year: 2024, month: 1, day: 17 };
    return {
      manufacturer: 'LABSUN',
      sn: '00000000',
      type: 'LUMC-S',
      manuDate: manuDate,
      model: 'LUMC8101',
    };
  }

  private getDefaultHardwareConfig(): HardwareConfig {
    const point0: MeterPointItem = { setVolume: 0.08, realVolume: 0.08 };
    const point1: MeterPointItem = { setVolume: 0.5, realVolume: 0.5 };
    const meterPoint: MeterPoint = { num: 2, point: [point0, point1] };
    const proportion: PidParamItem = { set: 35, real: 35 };
    const integration: PidParamItem = { set: 0.37, real: 0.37 };
    const differential: PidParamItem = { set: 65, real: 65 };
    const thermostatParam: ThermostatParam = { proportion, integration, differential };
    const pumpFactor: PumpFactor = { ref: 0.00076, real: 0.00076 };
    const tempCalibrate: TempCalibrate = { negativeInput: 1.2475, referenceVoltage: 2.495, calibrationVoltage: 0 };
    const meterLedPoint0: MeterLedItem = { set: 40, real: 40 };
    const meterLedPoint1: MeterLedItem = { set: 40, real: 40 };
    const meterLed: MeterLed = { num: 2, maxValue: 1023, point: [meterLedPoint0, meterLedPoint1] };
    const refInner: MeasureLedInner = { set: 128, real: 128 };
    const meaInner: MeasureLedInner = { set: 128, real: 128 };
    const targetInner: MeasureLedInner = { set: 1100, real: 1100 };
    const dacInner: MeasureLedInner = { set: 0.7, real: 0.7 };
    const measureLed: MeasureLed = {
      maxValue: 1023,
      reference: refInner,
      measure: meaInner,
      targetAD: targetInner,
      ledDAC: dacInner,
    };
    const gainCalibrate: GainCalibrate =  {
      maxValue: 3,
      gain: {
        reference: {
          set: 1,
          real: 1,
        },
        measure: {
          set: 1,
          real: 1,
        },
      },
    }
    return {
      reactionCamera: { volume: 2.5 },
      meterPoint,
      thermostatParam,
      pumpFactor,
      tempCalibrate,
      meterLed,
      measureLed,
      gainCalibrate
    };
  }

  private getDefaultMeasureParamConfig(): MeasureParamConfig {
    // meterLedAD =
    const measureLedAd: MeasureLedAd = {
      reference: 11000000,
      measure: 11000000
    };

    // calibratePointConsistency =                         -- 标定浓度
    const calibratePointConsistency: number[] = [
      0,
      100.0,
      100.0,
      100.0,
      500.0,
      2500.0,
      5000.0,
      10000.0
    ];

    // curveParam =                                        -- 曲线参数
    const curveParamList: CurveParam[] = [
      { curveK: 1, curveB: 0, zeroConsistency: 0, rangeConsistency: 50, timeStr: '--' },      // 量程一
      { curveK: 1, curveB: 0, zeroConsistency: 0, rangeConsistency: 100, timeStr: '--' },     // 量程二
      { curveK: 1, curveB: 0, zeroConsistency: 0, rangeConsistency: 250, timeStr: '--' },     // 量程三
      { curveK: 1, curveB: 0, zeroConsistency: 0, rangeConsistency: 500, timeStr: '--' },     // 量程四
      { curveK: 1, curveB: 0, zeroConsistency: 0, rangeConsistency: 2500, timeStr: '--' },    // 量程五
      { curveK: 1, curveB: 0, zeroConsistency: 0, rangeConsistency: 5000, timeStr: '--' },    // 量程六
      { curveK: 1, curveB: 0, zeroConsistency: 0, rangeConsistency: 10000, timeStr: '--' },   // 量程七
    ];

    //保存在其他文件中
    const reviseParam: number[] = [1, 1, 1, 1, 1, 1, 1];    //修正参数
    const excursionSample: number[] = [1, 1, 1, 1, 1, 1, 1];//水样偏差
    const diluteFactor: number[] = [1, 1, 2, 4, 10, 20, 40];   //稀释系数

    // calibrateCheck =
    const calibrateCheck: CalibrateCheck = { zeroCheckErrorLimit: 0.1, standardCheckErrorLimit: 0.1 };
    return {
      currentRange: 0,
      calibrateRangeIndex: 0,
      zeroCheckRangeIndex: 0,
      rangeCheckRangeIndex: 0,
      range: [0, 1, 2],
      timeStr: '--',
      zeroConsistency: 0,
      rangeConsistency: 0,
      curveK: 0,
      curveB: 0,
      currentRangeIndex: 1,
      autoChangeRange: false,
      activeRangeMode: 0,
      highClMode: false,
      digestTemperature: 165,
      digestTime: 300,
      reactTemperature: 80,
      reactTime: 60,
      digestAirPumpingTemp: 85,
      temperatureIncrement: 5,
      negativeRevise: true,
      reviseFactor: 1,
      shiftFactor: 0,
      meterLedAD: [3600, 3600],
      measureLedAD: measureLedAd,
      pidCtrl: false,
      calibratePointConsistency: calibratePointConsistency,
      range2StandardConsistency: 500,
      range3StandardConsistency: 2500,
      range4StandardConsistency: 500,
      range5StandardConsistency: 2500,
      range6StandardConsistency: 5000,
      range7StandardConsistency: 10000,
      cleanBefMeaBlankVol: 0.5,
      cleanAftMeaBlankVol: 4,
      sampleSoakExtendVol: 0,
      deepCleanBefCalibrate: true,
      wasteWaterEnvironment: false,
      tapWaterEnvironment: false,
      ignoreSampleAssertion: false,
      cleanSampleVol: 0,
      extendSamplePipeVolume: 0,
      sampleRenewVolume: 2,
      zeroAccurateCalibrate: false,
      standardAccurateCalibrate: false,
      rangeAccurateCalibrate: false,
      calibrateMarkOutput: false,
      curveQualifiedDetermination: false,
      rangeCalibrateDeviation: 0.01,
      checkConsistency: 100,
      checkErrorLimit: 0.1,
      checkReporting: true,
      failAutoRevise: false,
      highlyOxidized: false,
      readInitRilentTime: 120,
      readFinalBubbling: true,
      heaterMaxDutyCycle: 0.62,
      digestionFanLevel: 1,
      addCalibrateRecord: false,
      updateAllCalibrateKB: false,
      curveParam: curveParamList,
      reviseParameter: reviseParam,
      excursionSample: excursionSample,
      diluteFactor: diluteFactor,
      measureDataOffsetValve: 0,
      calibrateCheck: calibrateCheck,
    };
  }

  private getDefaultSchedulerConfig(): SchedulerConfig {
    const defaultTimedPoint: boolean[] = Array(24).fill(true);
    const defaultFalseTimedPoint: boolean[] = Array(24).fill(false);
    const currentTime: number = Date.now();

    // measure =		-- 测量排期
    const measureTimed: TimedPointConfig = {
      mode: MeasureMode.Trigger,
      interval: 2,
      timedPoint: defaultTimedPoint
    };

    // zeroCheck =		-- 零点核查
    const zeroCheckTimed: TimedPointConfig = {
      mode: MeasureMode.Trigger,
      interval: 168,
      timedPoint: defaultFalseTimedPoint,
      oneTimedPoint: 8,
      timedPointInterval: 1,
      configChangeTime: currentTime,
    };

    // rangeCheck =		-- 标样(跨度)核查
    const rangeCheckTimed: TimedPointConfig = {
      mode: MeasureMode.Trigger,
      interval: 168,
      timedPoint: defaultFalseTimedPoint,
      oneTimedPoint: 8,
      timedPointInterval: 1,
      configChangeTime: currentTime,
      timing: '12:00:00',
      timingTagTime: 0,
      // ZJ: {
      //   lastMode: MeasureMode.Trigger,
      //   nextStartTime: 0
      // },
    };

    // calibrate =		-- 校准排期
    const calibrateTimed: TimedPointConfig = {
      enable: false,
      mode: MeasureMode.Trigger,
      interval: 168,
      timedPoint: defaultFalseTimedPoint,
      oneTimedPoint: 8,
      timedPointInterval: 7,
      configChangeTime: currentTime,
    };

    // clean =			-- 清洗排期
    const cleanCfg: TimedPointConfig = {
      mode: MeasureMode.Trigger,
      timedPoint: defaultFalseTimedPoint,
      enable: false,
      interval: 168
    };

    // blankCheck =			-- 测零点校准液
    const blankCheckCfg: TimedPointConfig = {
      mode: MeasureMode.Trigger,
      timedPoint: defaultFalseTimedPoint,
      enable: false,
      interval: 168
    };

    // check =			-- 测量程校准液排期
    const checkCfg: TimedPointConfig = {
      mode: MeasureMode.Trigger,
      timedPoint: defaultFalseTimedPoint,
      enable: false,
      interval: 168
    };

    // standard =			-- 测核查液排期
    const standardTimed: TimedPointConfig = {
      enable: false,
      mode: MeasureMode.Trigger,
      interval: 168,
      timedPoint: defaultFalseTimedPoint,
    };

    // addstandard =			-- 加标排期
    const addStandardCfg: TimedPointConfig = {
      mode: MeasureMode.Trigger,
      timedPoint: defaultFalseTimedPoint,
      enable: false,
      interval: 168
    };

    // parallel =			-- 平行排期
    const parallelCfg: TimedPointConfig = {
      mode: MeasureMode.Trigger,
      timedPoint: defaultFalseTimedPoint,
      enable: false,
      interval: 168
    };

    return {
      measure: measureTimed,
      zeroCheck: zeroCheckTimed,
      rangeCheck: rangeCheckTimed,
      calibrate: calibrateTimed,
      clean: cleanCfg,
      blankCheck: blankCheckCfg,
      check: checkCfg,
      standard: standardTimed,
      addStandard: addStandardCfg,
      parallel: parallelCfg,
      timedPointJudgeTime: 5,
    };
  }

  private getDefaultInterconnectionConfig(): InterconnectionConfig {
    return {
      alarmValue: false,
      outputType: 0,
      meaUpLimit: 20000,
      meaLowLimit: 0,
      overProofResultMark: 0,
      rangeCheckResultMark: 0,
      overProofAutoCheck: false,
      connectAddress: 1,
      rs485BaudRate: 0,
      rs485Parity: 0,
      rs232BaudRate: 0,
      rs232Parity: 0,
      sampleLowLimit: 0,
      sampleUpLimit: 200,
      currentFactor: 1,
      collectSampleMode: 0,
      miningWaterTime: 20,
      silentTime: 20,
      relayOne: 5,
      relayTwo: 0,
      reportMode: ReportMode.OnLine,
      settingIpMode: SettingIpMode.Dhcp,
    };
  }

  private getDefaultSystemConfig(): SystemConfig {
    // screenSaver =
    const screenSaver: ScreenSaver = {
      enable: true,
      darkTime: 300,
      offTime: 600,
      loginKeepingTime: 600
    };

    // adcDetect =
    const adcDetect: AdcDetectItem[] = [
      { enable: false },
      { enable: false }
    ];

    const targetCod: TargetMapItem = {
      enable: true,
      num: TargetParam.Cod
    };
    const targetExtend: TargetMapItem = {
      enable: false,
      num: TargetParam.Extend
    };

    // targetMap =
    const targetMap: SystemTargetMap = {
      Cod: targetCod,
      EXTEND: targetExtend
    };

    // rangeViewMap =                                      -- 量程显示映射
    const rangeViewMap: RangeViewMapItem[] = [
      { range: 100, view: 100 },
      { range: 200, view: 200 },
      { range: 500, view: 500 },
      { range: 1000, view: 1000 },
      { range: 5000, view: 5000 },
      { range: 10000, view: 10000 },
      { range: 20000, view: 20000 },
    ];

    // printer =
    const printer: PrinterConfig = { enable: false, address: '192.168.1.99', autoPrint: false };

    // hj212Platform =
    const hj212: Hj212Platform = {
      hj212DataType: 0,
      status: false,
      address: '127.0.0.1',
      port: '11110',
      mn: 'A20800000_TCP30',
      pw: '123456',
      st: '21',                     // 编码
      respond: false,
      heartPackTime: 5,
      overtime: 3,
      recount: 3,
      hj212CommunicationMode: 0,    // 0:232 1:485 2:TCP
      hj212Type: 0,                 // 0:None 1: 2017DBS 2: 2017WRY
    };

    // 阀号更改
    const valveSetting: ValveSetting = {
      sample: 1,
      standard: 2,
      blank: 3,
      digestionRoom: [4, 5],
      wasteWater: 10,
      waste: 6,
      reagent1: 7,
      reagent2: 8,
      zeroCheck: 14,
      rangeCheck: 15,
    };

    return {
      screenSaver,
      adcDetect,
      language: Language.SimplifiedChinese,
      faultBlocking: false,
      displayProformaResult: true,
      faultRetry: true,
      reagentLackWarn: false,
      dryFireProtection: false,
      drainDigestRoomCheck: true,
      reagent2SpareValve: false,
      curveXYChange: false,
      debugMode: false,
      bridgeMode: false,
      bridgeIP: '192.168.2.1',
      modbusTableType: 0,
      cCepMode: false,
      solidifyMeaParamFromUI: false,
      solidifyMeaParamFromModbus: false,
      displayMeaParamInGeneral: false,
      changeParamLog: false,
      newDbsModbusLog: false,
      useQrEncode: false,
      serverIP: 'ins.watertestcloud.com',
      serverPort: 8800,
      serverMode: true,
      targetMap,
      internationalSupported: false,
      standardRegister: false,
      rangeViewMap,
      printer,
      nfsAddr: '192.168.0.218',
      nfsEnable: true,
      hj212Platform: hj212,
      valveSetting,
      decimalNum: 1,
      oem: 0,
      weepingLimitValve: 70,
      isLoadingReagentManager: true,
      rinseSolution: 1,
      deviceStartupTime: 0,
    };
  }

  private getDefaultAuthorizationConfig(): AuthorizationConfig {
    const usedPasswords: string[] = ['000000', '111111', '222222', '333333', '444444', '555555', '666666', '777777', '888888', '999999'];
    return {
      normalUserPassword: '000000',
      maintenancePassword: '666666',
      administratorPassword: '112008',
      superPassword: '032018',
      usedPasswords: usedPasswords,
      usedReagentPasswords: usedPasswords,
    };
  }

  private getDefaultRemainConfig(): RemainConfig {
    const currentTime: number = Date.now();
    const makeItem = (total: number): RemainItem => ({
      total,
      cycle: 3,
      lastTime: currentTime
    });

    return {
      standard: makeItem(250),
      blank: makeItem(5000),
      zeroCheck: makeItem(250),
      rangeCheck: makeItem(250),
      waste: makeItem(10000),
      wasteWater: makeItem(10000),
      reagent1: makeItem(250),
      reagent2: makeItem(500),
      reagentClean: makeItem(1000),
    };
  }

  private getDefaultRemainStatus(): RemainStatus {
    return {
      standard: 250,
      blank: 5000,
      zeroCheck: 250,
      rangeCheck: 250,
      waste: 10000,
      wasteWater: 10000,
      reagent1: 250,
      reagent2: 500,
      reagentClean: 1000,
    };
  }

  private getDefaultConsumableConfig(): ConsumableConfig {
    // config.consumable =
    const pumpPipe: PumpPipeConfig = {
      cycle: 36,
      lastTime: Date.now()
    };
    return { pumpPipe };
  }

  private getDefaultMeasureRunning(): MeasureRunning {
    // status.running =
    return {
      isMeasuring: false,
      isCorrectStopFlow: true,
      lastMeasureTime: 0
    };
  }

  // 修改用户密码（根据用户类型）
  async updatePassword(userType: RoleType, newPassword: string): Promise<boolean> {
    const auth = await this.getAuthorizationConfig();
    if (!auth) return false;
    switch (userType) {
      case RoleType.OPERATOR: auth.normalUserPassword = newPassword; auth.maintenancePassword = newPassword; break;
      case RoleType.ADMIN: auth.administratorPassword = newPassword; auth.superPassword = newPassword; break;
      default: return false;
    }
    await this.setAuthorizationConfig(auth);
    return true;
  }

  // 重置耗材配置到默认值
  async resetConsumableConfig(): Promise<void> {
    const defaultConfig = this.getDefaultConsumableConfig();
    await this.setConsumableConfig(defaultConfig);
  }

  async getAllSettingConfig(): Promise<string> {
    let summary = '========== 仪器信息配置 ==========\\n';

    const measureParam = await this.getMeasureParamConfig();
    if (measureParam) {
      summary += `\n【测量参数】\n`;
      summary += `  当前量程索引: ${measureParam.currentRangeIndex.toFixed(4)}\n`;
      summary += `  当前校准时间: ${measureParam.timeStr}\n`;
      summary += `  零点校准浓度: ${measureParam.zeroConsistency.toFixed(4)}\n`;
      summary += `  量程校准浓度: ${measureParam.rangeConsistency.toFixed(4)}\n`;
      summary += `  量程曲线斜率: ${measureParam.curveK.toFixed(4)}\n`;
      summary += `  量程曲线截距: ${measureParam.curveB.toFixed(4)}\n`;

      if (measureParam.curveParam && measureParam.curveParam.length > 0) {
        summary += `\n  【曲线参数列表】 (共${measureParam.curveParam.length}条)\n`;
        for (let i = 0; i < measureParam.curveParam.length; i++) {
          const cp = measureParam.curveParam[i];
          summary += `    量程${i +
            1}: K=${cp.curveK.toFixed(4)}, B=${cp.curveB.toFixed(4)}, 零点浓度=${cp.zeroConsistency.toFixed(4)}, 量程浓度=${cp.rangeConsistency}, 时间=${cp.timeStr}\n`;
        }
      }
    }

    summary += `\n========== 打印完成 ==========`;
    return summary;
  }

  private formatDateTime(timestamp: number): string {
    const date = new Date(timestamp);
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    const seconds = String(date.getSeconds()).padStart(2, '0');
    return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`;
  }

  // 修改当前量程数据
  async modifyMeasureParamConfigRangeData(measureParamConfig: MeasureParamConfig, record: CalibrateRecord): Promise<void> {
    if (measureParamConfig !== null)
    {
      measureParamConfig.timeStr = this.formatDateTime(record.dateTime);
      measureParamConfig.zeroConsistency = record.point0Consistency;
      measureParamConfig.rangeConsistency = record.measureRange;
      measureParamConfig.curveK = record.curveK;
      measureParamConfig.curveB = record.curveB;
      measureParamConfig.currentRange = record.rangeIndex + 1;  // 当前量程需要加1？

      // 修改曲线参数中对应索引下的量程数据
      if (record.rangeIndex >= 0 && record.rangeIndex < measureParamConfig.curveParam.length){
        measureParamConfig.curveParam[record.rangeIndex].curveK = record.curveK;
        measureParamConfig.curveParam[record.rangeIndex].curveB = record.curveB;
        measureParamConfig.curveParam[record.rangeIndex].zeroConsistency = record.point0Consistency;
        measureParamConfig.curveParam[record.rangeIndex].rangeConsistency = record.measureRange;
        measureParamConfig.curveParam[record.rangeIndex].timeStr = this.formatDateTime(record.dateTime);
      }
      else {
        console.error(`rangeIndex ${record.rangeIndex} out of bounds, length=${measureParamConfig.curveParam.length}`);
      }
      this.setMeasureParamConfig(measureParamConfig);
    }
  }

}