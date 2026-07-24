import { config, status } from '../Config/Config';
import { DateTimeUtil } from 'base';
import {
  SettingsManager,
  MeasureStatusManager,
  MeasureMode,
  TimedPointConfig ,
  SchedulerConfig ,
  MeasureStatus,
  SimpleIntervalConfig,
  RangeCheckTimedConfig,
  CalibrateTimedConfig,
  StandardTimedConfig,
  CleanConfig,
  ResultManager,
  MeasureRecord,
  ResultMode,
  MeasureType,
  CalibrateRecord,
} from 'dataservice';
import { Setting } from '../Setting/Setting';

export interface MeasureData{
  dateTime: number,                 // 测量时间戳
  consistency: number,              // 浓度(mg/L)
  absorbance: number,               // 吸光度(mAbs)
  mode: number,                     // 标识（对应ResultMode）
  resultType: number,               // 类型（对应MeasureType）
  initReferenceAD: number,          // 空白参考AD
  initMeasureAD: number,            // 空白测量AD
  finalReferenceAD: number,         // 显色参考AD
  finalMeasureAD: number,           // 显色测量AD
  initThermostatTemp: number,       // 空白值消解室温度(℃)
  initEnvironmentTemp: number,      // 空白值环境温度(℃)
  finalThermostatTemp: number,      // 显色值消解室温度(℃)
  finalEnvironmentTemp: number,     // 显色值环境温度(℃)
  initConsistency: number,          // 空白吸光度(mAbs)
  measureTime: number,              // 测量时长(秒)
  addStandardConsistency: number,   // 加量程校准液浓度(mg/L)
  measureRange: number,             // 量程
  versionString?: string,            //版本
}

export interface CaliData{
  dateTime: number,                   // 校准时间戳

  // 曲线参数
  curveK: number,                     // 斜率（Double类型，8字节）
  curveB: number,                     // 截距（Double类型，8字节）

  // 0点数据
  point0InitAbsorbance: number,       // 0点空白吸光度
  point0Absorbance: number,           // 0点显色吸光度
  point0Consistency: number,          // 0点浓度
  initReferenceAD0: number,           // 0点空白参考AD
  initMeasureAD0: number,             // 0点空白测量AD
  finalReferenceAD0: number,          // 0点显色参考AD
  finalMeasureAD0: number,            // 0点显色测量AD
  point0InitThermostatTemp: number,   // 0点空白消解室温度
  point0InitEnvironmentTemp: number,  // 0点空白环境温度
  point0FinalThermostatTemp: number,  // 0点显色消解室温度
  point0FinalEnvironmentTemp: number, // 0点显色环境温度

  // 1点数据
  point1InitAbsorbance: number,       // 1点空白吸光度
  point1Absorbance: number,           // 1点显色吸光度
  point1Consistency: number,          // 1点浓度
  initReferenceAD1: number,           // 1点空白参考AD
  initMeasureAD1: number,             // 1点空白测量AD
  finalReferenceAD1: number,          // 1点显色参考AD
  finalMeasureAD1: number,            // 1点显色测量AD
  point1InitThermostatTemp: number,   // 1点空白消解室温度
  point1InitEnvironmentTemp: number,  // 1点空白环境温度
  point1FinalThermostatTemp: number,  // 1点显色消解室温度
  point1FinalEnvironmentTemp: number, // 1点显色环境温度

  R2: number,                         // 曲线线性度
  calibrateTime: number,              // 校准时长
  measureRange: number,               // 量程 (v2新增)
  versionString?: string,
}

/**
 * 数据库管理类
 * 用于统一管理数据库的初始化、读取和保存操作
 */
export class DatabaseManager {
  private static instance: DatabaseManager;
  private settingsManager: SettingsManager | null = null;
  private measureStatusManager: MeasureStatusManager | null = null;
  private resultManager: ResultManager | null = null;
  private isInitialized: boolean = false;
  private UIcontext: Context | null = null;

  // 私有构造函数，防止外部实例化
  private constructor(){
    // this.initialize(UIContext);
  }

  /**
   * 获取单例实例
   */
  public static getInstance(): DatabaseManager {
    if (!DatabaseManager.instance) {
      DatabaseManager.instance = new DatabaseManager();
    }
    return DatabaseManager.instance;
  }

  /**
   * 初始化所有数据库
   * @param UIContext 上下文
   */
  public async initialize(UIContext: Context): Promise<boolean> {
    this.UIcontext = UIContext;
    if (this.isInitialized) {
      console.info('数据库已经初始化，跳过重复初始化');
      return true;
    }

    try {
      // 1. 初始化 SettingsManager（管理 instrument_config 数据库）
      this.settingsManager = SettingsManager.getInstance();
      await this.settingsManager.init(UIContext);

      // 2. 初始化 MeasureStatusManager（管理 measure_status_config 数据库）
      this.measureStatusManager = MeasureStatusManager.getInstance();
      await this.measureStatusManager.init(UIContext);

      // 3. 初始化 ResultManager（关系型数据库）
      this.resultManager = ResultManager.getInstance();
      await this.resultManager.init(UIContext, { decimalNum: 3, settingUseNum: 3 });

      this.isInitialized = true;
      console.info('所有数据库初始化成功');
      return true;
    } catch (err) {
      console.error('数据库初始化失败: %s', JSON.stringify(err));
      this.isInitialized = false;
      return false;
    }
  }

  /**
   * 获取 SettingsManager 实例
   */
  public getSettingsManager(): SettingsManager | null {
    return this.settingsManager;
  }

  /**
   * 获取 MeasureStatusManager 实例
   */
  public getMeasureStatusManager(): MeasureStatusManager | null {
    return this.measureStatusManager;
  }

  /**
   * 获取 ResultManager 实例
   */
  public getResultManager(): ResultManager | null {
    return this.resultManager;
  }

  /**
   * 检查数据库是否已初始化
   */
  public getInitializationStatus(): boolean {
    return this.isInitialized;
  }

  async getMeasureParam(): Promise<void> {
    if (!this.isInitialized) { return; }
    try {
      const sm = SettingsManager.getInstance();
      const mp = await sm.getMeasureParamConfig();
      if (mp) {
        config.measureParam = mp;
        console.log('测量参数读取成功:');
      } else {
        console.warn('测量参数为空,使用默认值');
      }
    } catch (err) {
      console.error(`测量参数异常: ${err}`);
    }
  }

  async saveMeasureParam(): Promise<void> {
    if (!this.isInitialized) { return; }
    try {
      const sm = SettingsManager.getInstance();
      await sm.setMeasureParamConfig(config.measureParam);
      console.log('测量参数保存成功:');
    } catch (err) {
      console.error(`测量参数保存异常: ${err}`);
    }
  }

  async getInstrumentInfo(): Promise<void> {
    if (!this.isInitialized) { return; }
    try {
      const sm = SettingsManager.getInstance();
      const info = await sm.getInstrumentInfo();
      if (info) {
        config.instrumentInformation = info;
        console.log('仪器信息读取成功:');
      } else {
        console.warn('仪器信息为空,使用默认值');
      }
    } catch (err) {
      console.error(`仪器信息异常: ${err}`);
    }
  }

  async saveInstrumentInfo(): Promise<void> {
    if (!this.isInitialized) { return; }
    try {
      const sm = SettingsManager.getInstance();
      await sm.setInstrumentInfo(config.instrumentInformation);
      console.log('仪器信息保存成功:');
    } catch (err) {
      console.error(`仪器信息保存异常: ${err}`);
    }
  }

  async getMainBoardInfo(): Promise<void> {
    if (!this.isInitialized) { return; }
    try {
      const sm = SettingsManager.getInstance();
      const info = await sm.getMainBoardInfo();
      if (info) {
        config.mainBoardInformation = info;
        console.log('主板信息读取成功:');
      } else {
        console.warn('主板信息为空');
      }
    } catch (err) {
      console.error(`主板信息异常: ${err}`);
    }
  }

  async saveMainBoardInfo(): Promise<void> {
    if (!this.isInitialized) { return; }
    try {
      const sm = SettingsManager.getInstance();
      await sm.setMainBoardInfo(config.mainBoardInformation);
      console.log('主板信息保存成功:');
    } catch (err) {
      console.error(`主板信息保存异常: ${err}`);
    }
  }

  async getHardwareConfig(): Promise<void> {
    if (!this.isInitialized) { return; }
    try {
      const sm = SettingsManager.getInstance();
      const hw = await sm.getHardwareConfig();
      if (hw) {
        config.hardware = hw;
        console.log('硬件配置读取成功:');
      } else {
        console.warn('硬件配置为空');
      }
    } catch (err) {
      console.error(`硬件配置异常: ${err}`);
    }
  }

  async saveHardwareConfig(): Promise<void> {
    if (!this.isInitialized) { return; }
    try {
      const sm = SettingsManager.getInstance();
      await sm.setHardwareConfig(config.hardware);
      console.log('硬件配置保存成功:');
    } catch (err) {
      console.error(`硬件配置保存异常: ${err}`);
    }
  }

  async getInterconnection(): Promise<void> {
    if (!this.isInitialized) { return; }
    try {
      const sm = SettingsManager.getInstance();
      const ic = await sm.getInterconnectionConfig();
      if (ic) {
        config.interconnection = ic;
        console.log('对外接口配置读取成功:');
      } else {
        console.warn('对外接口配置为空');
      }
    } catch (err) {
      console.error(`对外接口配置异常: ${err}`);
    }
  }

  async saveInterconnection(): Promise<void> {
    if (!this.isInitialized) { return; }
    try {
      const sm = SettingsManager.getInstance();
      await sm.setInterconnectionConfig(config.interconnection);
      console.log('对外接口配置保存成功:');
    } catch (err) {
      console.error(`对外接口配置保存异常: ${err}`);
    }
  }
  

  async getScheduler(): Promise<void> {
    if (!this.isInitialized) { return; }
    try {
      const sm = SettingsManager.getInstance();
      const sc = await sm.getSchedulerConfig();
      if (sc) {
        config.scheduler = sc;
        console.log('排期配置读取成功:');
      } else {
        console.warn('排期配置为空');
      }
    } catch (err) {
      console.error(`排期配置异常: ${err}`);
    }
  }

  async saveScheduler(): Promise<void> {
    if (!this.isInitialized) { return; }
    try {
      const sm = SettingsManager.getInstance();
      await sm.setSchedulerConfig(config.scheduler);
      console.log('排期配置保存成功:');
    } catch (err) {
      console.error(`排期配置保存异常: ${err}`);
    }
  }

  async getSystemConfig(): Promise<void> {
    if (!this.isInitialized) { return; }
    try {
      const sm = SettingsManager.getInstance();
      const sys = await sm.getSystemConfig();
      if (sys) {
        config.system = sys;
        console.log('系统配置读取成功:', sys);
      } else {
        console.warn('系统配置为空');
      }
    } catch (err) {
      console.error(`系统配置异常: ${err}`);
    }
  }

  async saveSystemConfig(): Promise<void> {
    if (!this.isInitialized) { return; }
    try {
      const sm = SettingsManager.getInstance();
      await sm.setSystemConfig(config.system);
      console.log('系统配置保存成功:');
    } catch (err) {
      console.error(`系统配置保存异常: ${err}`);
    }
  }

  async getMeasureRunning(): Promise<void> {
    if (!this.isInitialized) { return; }
    try {
      const sm = SettingsManager.getInstance();
      const running = await sm.getMeasureRunning();
      if (running) {
        status.measureRunning = running;
        console.log('测量运行状态读取成功:');
      } else {
        console.warn('测量运行状态为空');
      }
    } catch (err) {
      console.error(`测量运行状态异常: ${err}`);
    }
  }

  async saveMeasureRunning(): Promise<void> {
    if (!this.isInitialized) { return; }
    try {
      const sm = SettingsManager.getInstance();
      await sm.setMeasureRunning(status.measureRunning);
      console.log('测量运行状态保存成功:');
    } catch (err) {
      console.error(`测量运行状态保存异常: ${err}`);
    }
  }

  async getRemainStatus(): Promise<void> {
    if (!this.isInitialized) { return; }
    try {
      const sm = SettingsManager.getInstance();
      const remain = await sm.getRemainStatus();
      if (remain) {
        status.remainStatus = remain;
        console.log('试剂余量状态读取成功:');
      } else {
        console.warn('试剂余量状态为空');
      }
    } catch (err) {
      console.error(`试剂余量状态异常: ${err}`);
    }
  }

  async saveRemainStatus(): Promise<void> {
    if (!this.isInitialized) {
      return;
    }
    try {
      const sm = SettingsManager.getInstance();
      await sm.setRemainStatus(status.remainStatus);
      console.log('试剂余量状态保存成功:');
    } catch (err) {
      console.error(`试剂余量状态保存异常: ${err}`);
    }
  }

  async getConsumable(): Promise<void> {
    if (!this.isInitialized) { return;}
    try {
      const sm = SettingsManager.getInstance();
      const cons = await sm.getConsumableConfig();
      if (cons) {
        config.consumable = cons;
        console.log('耗材配置读取成功:');
      } else {
        console.warn('耗材配置为空');
      }
    } catch (err) {
      console.error(`耗材配置异常: ${err}`);
    }
  }

  async saveConsumable(): Promise<void> {
    if (!this.isInitialized) {
      return;
    }
    try {
      const sm = SettingsManager.getInstance();
      await sm.setConsumableConfig(config.consumable);
      console.log('耗材配置保存成功:');
    } catch (err) {
      console.error(`耗材配置保存异常: ${err}`);
    }
  }

  async getMeasureStatus(): Promise<void> {
    if (!this.isInitialized) { return; }
    try {
      const msm = MeasureStatusManager.getInstance();
      const sta = await msm.getMeasureStatus();
      if (sta) {
        status.measureStatus = sta;
        console.log('测量状态读取成功:');
      } else {
        console.warn('测量状态为空');
      }
    } catch (err) {
      console.error(`测量状态异常: ${err}`);
    }
  }

  async saveMeasureStatus(): Promise<void> {
    if (!this.isInitialized) { return; }
    try {
      const msm = MeasureStatusManager.getInstance();
      await msm.setMeasureStatus(status.measureStatus);
      console.log('测量状态保存成功:');
    } catch (err) {
      console.error(`测量状态保存异常: ${err}`);
    }
  }

  async getAll(): Promise<void> {
    await this.getMeasureParam();
    await this.getInstrumentInfo();
    await this.getMainBoardInfo();
    await this.getHardwareConfig();
    await this.getInterconnection();
    await this.getScheduler();
    await this.getSystemConfig();
    await this.getMeasureRunning();
    await this.getRemainStatus();
    await this.getConsumable();
    await this.getMeasureStatus();
  }

  async saveAll(): Promise<void> {
    await this.saveMeasureParam();
    await this.saveInstrumentInfo();
    await this.saveMainBoardInfo();
    await this.saveHardwareConfig();
    await this.saveInterconnection();
    await this.saveScheduler();
    await this.saveSystemConfig();
    await this.saveMeasureRunning();
    await this.saveRemainStatus();
    await this.saveConsumable();
    await this.saveMeasureStatus();
  }

  /**
   * 保存测量结果到数据库
   * @param result 测量结果
   */
  async addMeasureRecord(result:MeasureData): Promise<void> {
    if (!this.isInitialized) { return; }
    try {
      const resultManager = ResultManager.getInstance();
      const record = new MeasureRecord();
      record.dateTime = result.dateTime;
      record.initReferenceAD = result.initReferenceAD;
      record.initMeasureAD = result.initMeasureAD;
      record.finalReferenceAD = result.finalReferenceAD;
      record.finalMeasureAD = result.finalMeasureAD;
      record.initThermostatTemp = result.initThermostatTemp;
      record.initEnvironmentTemp = result.initEnvironmentTemp;
      record.finalThermostatTemp = result.finalThermostatTemp;
      record.finalEnvironmentTemp = result.finalEnvironmentTemp;
      record.consistency = result.consistency;
      record.absorbance = result.absorbance;
      record.mode = result.mode;
      record.resultType = result.resultType;
      record.versionString = '1, 0, 0, 2';

      const id = await resultManager.addMeasureRecord('test', record, false);
      if (id > 0) {
        console.log(`添加测量记录成功: ${id}`);
      } else {
        console.error('添加测量记录失败');
      }
    } catch (err) {
      console.error(`添加测量记录异常: ${err}`);
    }
  }

  /**
   * 从数据库查询测量结果
   * @param query 查询条件
   */
  async queryResults(): Promise<void> {
    if (!this.isInitialized) { return; }
    try {
      const resultManager = ResultManager.getInstance();
      const records = await resultManager.getLatestMeasureRecords(5);
      const totalCount = await resultManager.getMeasureRecordCount();
      if (records.length === 0) {

      } else {
        let msg = `总记录数: ${totalCount}\n最新 ${records.length} 条:\n`;
        for (let i = 0; i < records.length; i++) {
          const r = records[i];
          msg += `${i + 1}. ${DateTimeUtil.getDateTime(r.dateTime)} - ${resultManager.getResultTypeText(r.resultType)}: ${resultManager.displayResult(r.consistency)} mg/L\n`;
        }
        console.log(msg);
      }
    } catch (err) {
      console.error(`查询测量记录异常: ${err}`);
 
    }
  }

  async addCalibrateRecord(result:CaliData): Promise<void> {
    if (!this.isInitialized) {
      return;
    }
    try {
      const resultManager = ResultManager.getInstance();
      const record = new CalibrateRecord();
      record.dateTime = result.dateTime;
      record.curveK = result.curveK;
      record.curveB = result.curveB;
      record.R2 = result.R2;
      record.calibrateTime = result.calibrateTime;
      record.measureRange = result.measureRange;

      record.point0InitAbsorbance = result.point0InitAbsorbance;
      record.point0Absorbance = result.point0Absorbance;
      record.point0Consistency = result.point0Consistency;
      record.initReferenceAD0 = result.initReferenceAD0;
      record.initMeasureAD0 = result.initMeasureAD0;
      record.finalReferenceAD0 = result.finalReferenceAD0;
      record.finalMeasureAD0 = result.finalMeasureAD0;
      record.point0InitThermostatTemp = result.point0InitThermostatTemp;
      record.point0InitEnvironmentTemp = result.point0InitEnvironmentTemp;
      record.point0FinalThermostatTemp = result.point0FinalThermostatTemp;
      record.point0FinalEnvironmentTemp = result.point0FinalEnvironmentTemp;

      record.point1InitAbsorbance = result.point1InitAbsorbance;
      record.point1Absorbance = result.point1Absorbance;
      record.point1Consistency = result.point1Consistency;
      record.initReferenceAD1 = result.initReferenceAD1;
      record.initMeasureAD1 = result.initMeasureAD1;
      record.finalReferenceAD1 = result.finalReferenceAD1;
      record.finalMeasureAD1 = result.finalMeasureAD1;
      record.point1InitThermostatTemp = result.point1InitThermostatTemp;
      record.point1InitEnvironmentTemp = result.point1InitEnvironmentTemp;
      record.point1FinalThermostatTemp = result.point1FinalThermostatTemp;
      record.point1FinalEnvironmentTemp = result.point1FinalEnvironmentTemp;

      record.versionString = '1.0.0.2';

      const id = await resultManager.addCalibrateRecord('test', record);
      if (id > 0) {
        console.log(`校准记录成功！\nID: ${id}\nK: ${record.curveK}, B: ${record.curveB}, R²: ${record.R2}`);
      } else {
        console.error('添加校准记录失败');
      }
    } catch (err) {
      console.info('校准记录添加失败:', err);
    }
  }

  async queryLatestCalibrateRecords(): Promise<void> {
    if (!this.isInitialized) { return; }
    try {
      const resultManager = ResultManager.getInstance();
      const records = await resultManager.getCalibrateRecords({ orderBy: 'desc', limit: 5 });
      const validCurve = await resultManager.getValidCalibrateRecord();
      if (records.length === 0) {
      } else {
        let msg = `总记录数: ${records.length}\n`;
        if (validCurve) {
          msg += `✅ 有效曲线: K=${validCurve.curveK}, B=${validCurve.curveB}, R²=${validCurve.R2}\n`;
        }
        msg += `最新记录:\n`;
        for (let i = 0; i < Math.min(3, records.length); i++) {
          const r = records[i];
          msg += `${i + 1}. ${DateTimeUtil.getDateTime(r.dateTime)} - K=${r.curveK.toFixed(4)}, R²=${r.R2.toFixed(4)}\n`;
        }
        console.log(msg);
      }
    } catch (err) {
      console.error(`查询校准记录异常: ${err}`);
    }
  }

  /**
   * 关闭所有数据库连接
   */
  public async closeAll(): Promise<void> {
    try {
      // if (this.settingsManager) {
      //   await this.settingsManager.close();
      // }
      // if (this.measureStatusManager) {
      //   await this.measureStatusManager.close();
      // }
      if (this.resultManager) {
        await this.resultManager.close();
      }
      this.isInitialized = false;
      console.info('所有数据库连接已关闭');
    } catch (err) {
      console.error('关闭数据库连接失败: %s', JSON.stringify(err));
    }
  }
}
