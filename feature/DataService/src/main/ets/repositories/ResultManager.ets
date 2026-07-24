// DataService/src/main/ets/repositories/ResultManager.ets

import { RdbManager } from '../database/relational/RdbManager';
import {
  MeasureRecord,
  CalibrateRecord,
  MeasureQueryCondition,
  CalibrateQueryCondition,
  MeasureType,
  ResultMode,
  ExportConfig,
  RecordCompareResult
} from '../database/relational/models/RelationalModels';
import fs from '@ohos.file.fs';
import { BusinessError } from '@ohos.base';
import picker from '@ohos.file.picker';

/**
 * 结果观察者接口（对应原C++的IResultNotifiable）
 */
export interface IResultNotifiable {
  onMeasureResultAdded?(name: string, record: MeasureRecord): void;
  onCalibrateResultAdded?(name: string, record: CalibrateRecord): void;
  onMeasureResultDeleted?(name: string, count: number): void;
  onCalibrateResultDeleted?(name: string, count: number): void;
  onDataMigrated?(fromVersion: string, toVersion: string, count: number): void;
}

/**
 * 结果管理器配置
 */
export interface ResultManagerConfig {
  decimalNum: number;           // 小数位数
  settingUseNum: number;        // 有效数字位数
  unitMultiple: number;         // 单位倍数
  autoBackupInterval: number;   // 自动备份间隔（毫秒），默认24小时
}

/**
 * 结果管理器
 * 对应原C++的ResultManager类
 */
export class ResultManager {
  private static instance: ResultManager;
  private rdbManager: RdbManager;
  private context: Context | null = null;

  // 观察者列表（对应原C++的m_notifise）
  private notifiableList: IResultNotifiable[] = [];

  // 读取者映射（对应原C++的多个文件访问者）
  private measureReaderIds: Map<string, number> = new Map();
  private calibrateReaderIds: Map<string, number> = new Map();

  // 显示配置（对应原C++的显示参数）
  private decimalNum: number = 3;
  private settingUseNum: number = 3;
  private unitMultiple: number = 1;

  // 定时器ID
  private backupTimerId: number = -1;
  private autoBackupInterval: number = 24 * 60 * 60 * 1000; // 24小时

  // 是否已初始化
  private isInitialized: boolean = false;

  // 初始化Promise，用于等待初始化完成
  private initPromise: Promise<boolean> | null = null;

  private constructor() {
    this.rdbManager = RdbManager.getInstance();
  }

  static getInstance(): ResultManager {
    if (!ResultManager.instance) {
      ResultManager.instance = new ResultManager();
    }
    return ResultManager.instance;
  }

  // ==================== 初始化 ====================

  /**
   * 初始化结果管理器（对应原C++的Init）
   * @param context 应用上下文
   * @param config 可选配置
   */
  async init(context: Context, config?: Partial<ResultManagerConfig>): Promise<boolean> {
    // 如果已经初始化完成，直接返回
    if (this.isInitialized) {
      return true;
    }

    // 如果正在初始化中，等待完成
    if (this.initPromise) {
      return this.initPromise;
    }

    this.context = context;

    // 执行初始化
    this.initPromise = this.doInit(context, config);
    const result = await this.initPromise;
    this.initPromise = null;
    return result;
    }

  /**
   * 实际执行初始化
   */
  private async doInit(context: Context, config?: Partial<ResultManagerConfig>): Promise<boolean> {
    try {
      this.context = context;

      // 应用配置
      if (config) {
        this.decimalNum = config.decimalNum ?? this.decimalNum;
        this.settingUseNum = config.settingUseNum ?? this.settingUseNum;
        this.unitMultiple = config.unitMultiple ?? this.unitMultiple;
        this.autoBackupInterval = config.autoBackupInterval ?? this.autoBackupInterval;
      }

      // 初始化数据库（传入context）
      const dbInit = await this.rdbManager.init(context);
      if (!dbInit) {
        console.error('ResultManager: Database init failed');
        return false;
      }

      // 初始化显示配置
      await this.initDisplayConfig();

      // 注册默认读取者
      this.initReaders();

      // 启动定时备份
      this.startAutoBackup();

      this.isInitialized = true;
      console.info('ResultManager initialized successfully at: ' + context.filesDir);
      return true;

    } catch (err) {
      console.error(`ResultManager init failed: ${err}`);
      return false;
    }
  }

  /**
   * 初始化显示配置
   */
  private async initDisplayConfig(): Promise<void> {
    // TODO: 从PreferencesManager加载配置
    console.info('Display config initialized: decimalNum=%d, useNum=%d',
    this.decimalNum, this.settingUseNum);
  }

  /**
   * 初始化读取者
   */
  private initReaders(): void {
    // 测量记录读取者
    const measureTypes = ['default', 'wave', 'resultDetail', 'export'];
    for (const type of measureTypes) {
    const readerId = this.rdbManager.registerMeasureReader(type);
    this.measureReaderIds.set(type, readerId);
  }

  // 校准记录读取者
  const calibrateTypes = ['default', 'resultDetail'];
  for (const type of calibrateTypes) {
    const readerId = this.rdbManager.registerCalibrateReader(type);
    this.calibrateReaderIds.set(type, readerId);
  }
  }

  /**
   * 启动自动备份
   */
  private startAutoBackup(): void {
    if (this.backupTimerId !== -1) {
    clearInterval(this.backupTimerId);
  }

  this.backupTimerId = setInterval(() => {
  }, this.autoBackupInterval);
  }

  // ==================== 观察者模式 ====================

  registerNotifiable(handler: IResultNotifiable): void {
    if (!this.notifiableList.includes(handler)) {
      this.notifiableList.push(handler);
    }
  }

  unregisterNotifiable(handler: IResultNotifiable): void {
    const index = this.notifiableList.indexOf(handler);
    if (index !== -1) {
      this.notifiableList.splice(index, 1);
    }
  }

  private notifyMeasureResultAdded(name: string, record: MeasureRecord): void {
    for (const handler of this.notifiableList) {
      if (handler.onMeasureResultAdded) {
        handler.onMeasureResultAdded(name, record);
      }
    }
  }

  private notifyCalibrateResultAdded(name: string, record: CalibrateRecord): void {
    for (const handler of this.notifiableList) {
      if (handler.onCalibrateResultAdded) {
        handler.onCalibrateResultAdded(name, record);
      }
    }
  }

  private notifyMeasureResultDeleted(name: string, count: number): void {
    for (const handler of this.notifiableList) {
      if (handler.onMeasureResultDeleted) {
        handler.onMeasureResultDeleted(name, count);
      }
    }
  }

  private notifyCalibrateResultDeleted(name: string, count: number): void {
    for (const handler of this.notifiableList) {
      if (handler.onCalibrateResultDeleted) {
        handler.onCalibrateResultDeleted(name, count);
      }
    }
  }

  // ==================== 测量记录操作 ====================

  /**
   * 添加测量记录（对应原C++的AddMeasureRecord）
   */
  async addMeasureRecord(
    name: string,
    record: MeasureRecord,
    isUpload: boolean = true
  ): Promise<number> {
    if (!this.isInitialized) {
      throw new Error('ResultManager not initialized');
    }

    if (record.dateTime === 0) {
      record.dateTime = Math.floor(Date.now() / 1000);
    }

    const recordId = await this.rdbManager.addMeasureRecord(record);

    if (recordId > 0) {
      this.notifyMeasureResultAdded(name, record);
      if (isUpload) {
        await this.uploadMeasureData(name, record);
      }
    }

    return recordId;
  }

  /**
   * 检查记录是否存在
   */
  async isMeasureRecordExists(record: MeasureRecord): Promise<boolean> {
    return this.rdbManager.isMeasureRecordExists(record);
  }

  /**
   * 获取测量记录数量
   */
  async getMeasureRecordCount(conditions?: MeasureQueryCondition): Promise<number> {
    return this.rdbManager.getMeasureRecordCount(conditions);
  }

  /**
   * 获取测量记录列表
   */
  async getMeasureRecords(
    conditions?: MeasureQueryCondition,
    recordType: string = 'default'
  ): Promise<MeasureRecord[]> {
    const readerId = this.measureReaderIds.get(recordType);
    return this.rdbManager.getMeasureRecords(conditions, readerId);
  }

  /**
   * 获取最新的N条测量记录
   */
  async getLatestMeasureRecords(limit: number = 10): Promise<MeasureRecord[]> {
    return this.rdbManager.getLatestMeasureRecords(limit);
  }

  /**
   * 获取最新的单条测量记录
   */
  async getLatestMeasureRecord(): Promise<MeasureRecord | null> {
    return this.rdbManager.getLatestMeasureRecord();
  }

  /**
   * 根据类型获取测量记录
   */
  async getMeasureRecordsByType(
    resultType: MeasureType,
    limit?: number
  ): Promise<MeasureRecord[]> {
    return this.rdbManager.getMeasureRecordsByType(resultType, limit);
  }

  /**
   * 根据时间范围获取测量记录
   */
  async getMeasureRecordsByTimeRange(
    startTime: number,
    endTime: number,
    limit?: number
  ): Promise<MeasureRecord[]> {
    return this.rdbManager.getMeasureRecordsByTimeRange(startTime, endTime, limit);
  }

  /**
   * 获取今日测量记录
   */
  async getTodayMeasureRecords(): Promise<MeasureRecord[]> {
    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);
    const tomorrowStart = new Date(todayStart);
    tomorrowStart.setDate(tomorrowStart.getDate() + 1);

    return this.getMeasureRecordsByTimeRange(todayStart.getTime(), tomorrowStart.getTime());
  }

  /**
   * 清空所有测量记录
   */
  async clearMeasureRecords(): Promise<number> {
    const count = await this.getMeasureRecordCount();
    const result = await this.rdbManager.clearMeasureRecords();
    if (result > 0) {
      this.notifyMeasureResultDeleted('all', count);
    }
    return result;
  }

  // ==================== 校准记录操作 ====================

  /**
   * 添加校准记录
   */
  async addCalibrateRecord(name: string, record: CalibrateRecord): Promise<number> {
    if (!this.isInitialized) {
      throw new Error('ResultManager not initialized');
    }

    if (record.dateTime === 0) {
      record.dateTime = Math.floor(Date.now() / 1000);
    }

    const recordId = await this.rdbManager.addCalibrateRecord(record);

    if (recordId > 0) {
      this.notifyCalibrateResultAdded(name, record);
      await this.uploadCalibrateData(name, record);
    }

    return recordId;
  }

  /**
   * 获取最新校准记录
   */
  async getLatestCalibrateRecord(): Promise<CalibrateRecord | null> {
    return this.rdbManager.getLatestCalibrateRecord();
  }

  /**
   * 获取当前有效的校准曲线
   */
  async getValidCalibrateRecord(minR2: number = 0.99): Promise<CalibrateRecord | null> {
    return this.rdbManager.getValidCalibrateRecord(minR2);
  }

  /**
   * 获取所有校准记录
   */
  async getCalibrateRecords(conditions?: CalibrateQueryCondition): Promise<CalibrateRecord[]> {
    return this.rdbManager.getCalibrateRecords(conditions);
  }

  /**
   * 获取校准记录数量
   */
  async getCalibrateRecordCount(conditions?: CalibrateQueryCondition): Promise<number> {
    const records = await this.getCalibrateRecords(conditions);
    return records.length;
  }

  /**
   * 清空所有校准记录
   */
  async clearCalibrateRecords(): Promise<number> {
    const count = await this.getCalibrateRecordCount();
    const result = await this.rdbManager.clearCalibrateRecords();
    if (result > 0) {
      this.notifyCalibrateResultDeleted('all', count);
    }
    return result;
  }

  private formatDateTime(timestamp: number): string {
    const date = new Date(timestamp * 1000);
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    return `${year}-${month}-${day} ${hours}:${minutes}`;
  }

  // ==================== 数据导出 ====================

  /**
   * 导出测量记录到CSV
   */
  async exportMeasureRecordsToCsv(config: ExportConfig): Promise<string> {
    const conditions: MeasureQueryCondition = {};
    if (config.startTime !== undefined) {
      conditions.startTime = config.startTime;
    }
    if (config.endTime !== undefined) {
      conditions.endTime = config.endTime;
    }

    const records = await this.getMeasureRecords(conditions, 'export');

    if (records.length === 0) {
      throw new Error('No data to export');
    }

    const csvContent = this.generateMeasureCsv(records);
    const filePath = await this.saveCsvFile(config.fileName, csvContent);
    return filePath;
  }

  /**
   * 生成测量记录CSV内容
   */
  private generateMeasureCsv(records: MeasureRecord[]): string {
    // 使用字符串拼接而不是数组
    let csvContent = '';

    // 添加表头
    csvContent += '时间,浓度(mg/L),吸光度(mAbs),标识,类型,';
    csvContent += '空白参考AD,空白测量AD,显色参考AD,显色测量AD,';
    csvContent += '空白消解室温度(℃),空白环境温度(℃),显色消解室温度(℃),显色环境温度(℃),';
    csvContent += '空白吸光度(mAbs),测量时长(秒),加标浓度(mg/L),量程\n';

    // 添加数据行
    for (let i = 0; i < records.length; i++) {
      const record = records[i];
      const dateStr = this.formatDateTime(record.dateTime);
      const modeText = this.getModeText(record.mode);
      const typeText = this.getResultTypeText(record.resultType);

      csvContent += `${dateStr},`;
      csvContent += `${this.displayResult(record.consistency)},`;
      csvContent += `${this.displayAbsorbance(record.absorbance)},`;
      csvContent += `${modeText},`;
      csvContent += `${typeText},`;
      csvContent += `${record.initReferenceAD},`;
      csvContent += `${record.initMeasureAD},`;
      csvContent += `${record.finalReferenceAD},`;
      csvContent += `${record.finalMeasureAD},`;
      csvContent += `${record.initThermostatTemp.toFixed(1)},`;
      csvContent += `${record.initEnvironmentTemp.toFixed(1)},`;
      csvContent += `${record.finalThermostatTemp.toFixed(1)},`;
      csvContent += `${record.finalEnvironmentTemp.toFixed(1)},`;
      csvContent += `${this.displayAbsorbance(record.initConsistency)},`;
      csvContent += `${record.measureTime},`;
      csvContent += `${this.displayResult(record.addStandardConsistency)},`;
      csvContent += `${this.displayResult(record.measureRange)}\n`;
    }

    return csvContent;
  }

  /**
   * 导出校准记录到CSV
   */
  async exportCalibrateRecordsToCsv(config: ExportConfig): Promise<string> {
    const conditions: CalibrateQueryCondition = {};
    if (config.startTime !== undefined) {
      conditions.startTime = config.startTime;
    }
    if (config.endTime !== undefined) {
      conditions.endTime = config.endTime;
    }

    const records = await this.getCalibrateRecords(conditions);

    if (records.length === 0) {
      throw new Error('No calibrate data to export');
    }

    const csvContent = this.generateCalibrateCsv(records);
    const filePath = await this.saveCsvFile(config.fileName, csvContent);
    return filePath;
  }

  /**
   * 生成校准记录CSV内容
   */
  private generateCalibrateCsv(records: CalibrateRecord[]): string {
    let csvContent = '';
    // 完整表头 - 包含所有字段（版本除外）
    csvContent += '时间,斜率(K),截距(B),R²,校准时长(秒),量程,量程索引,';
    csvContent += '0点空白吸光度(mAbs),0点显色吸光度(mAbs),0点浓度(mg/L),';
    csvContent += '0点空白参考AD,0点空白测量AD,0点显色参考AD,0点显色测量AD,';
    csvContent += '0点空白消解室温度(℃),0点空白环境温度(℃),0点显色消解室温度(℃),0点显色环境温度(℃),';
    csvContent += '1点空白吸光度(mAbs),1点显色吸光度(mAbs),1点浓度(mg/L),';
    csvContent += '1点空白参考AD,1点空白测量AD,1点显色参考AD,1点显色测量AD,';
    csvContent += '1点空白消解室温度(℃),1点空白环境温度(℃),1点显色消解室温度(℃),1点显色环境温度(℃)\n';

    for (let i = 0; i < records.length; i++) {
      const record = records[i];
      const dateStr = this.formatDateTime(record.dateTime);

      csvContent += `${dateStr},`;
      csvContent += `${record.curveK.toFixed(6)},`;
      csvContent += `${record.curveB.toFixed(6)},`;
      csvContent += `${record.R2.toFixed(6)},`;
      csvContent += `${record.calibrateTime},`;
      csvContent += `${record.measureRange},`;
      csvContent += `${record.rangeIndex},`;  // 新增

      // 0点数据 - 直接使用平铺字段
      csvContent += `${record.point0InitAbsorbance.toFixed(3)},`;
      csvContent += `${record.point0Absorbance.toFixed(3)},`;
      csvContent += `${record.point0Consistency},`;
      csvContent += `${record.initReferenceAD0},`;
      csvContent += `${record.initMeasureAD0},`;
      csvContent += `${record.finalReferenceAD0},`;
      csvContent += `${record.finalMeasureAD0},`;
      csvContent += `${record.point0InitThermostatTemp.toFixed(1)},`;
      csvContent += `${record.point0InitEnvironmentTemp.toFixed(1)},`;
      csvContent += `${record.point0FinalThermostatTemp.toFixed(1)},`;
      csvContent += `${record.point0FinalEnvironmentTemp.toFixed(1)},`;

      // 1点数据 - 直接使用平铺字段
      csvContent += `${record.point1InitAbsorbance.toFixed(3)},`;
      csvContent += `${record.point1Absorbance.toFixed(3)},`;
      csvContent += `${record.point1Consistency},`;
      csvContent += `${record.initReferenceAD1},`;
      csvContent += `${record.initMeasureAD1},`;
      csvContent += `${record.finalReferenceAD1},`;
      csvContent += `${record.finalMeasureAD1},`;
      csvContent += `${record.point1InitThermostatTemp.toFixed(1)},`;
      csvContent += `${record.point1InitEnvironmentTemp.toFixed(1)},`;
      csvContent += `${record.point1FinalThermostatTemp.toFixed(1)},`;
      csvContent += `${record.point1FinalEnvironmentTemp.toFixed(1)}\n`;
    }

    return csvContent;
  }

  /**
   * 保存CSV文件
   */
  private async saveCsvFile(fileName: string, content: string): Promise<string> {
    if (!this.context) {
      throw new Error('Context not available');
    }

    const filesDir = this.context.filesDir;
    const fullPath = `${filesDir}/${fileName}.csv`;

    try {
      // 添加 UTF-8 BOM 头，解决 Excel 打开中文乱码问题
      // BOM (Byte Order Mark) 告诉 Excel 这个文件是 UTF-8 编码
      const bom = '\uFEFF';
      const contentWithBom = bom + content;

      const file = fs.openSync(fullPath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY);
      fs.writeSync(file.fd, contentWithBom);
      fs.closeSync(file.fd);

      console.info(`CSV exported to: ${fullPath}`);
      return fullPath;
    } catch (err) {
      let error = err as BusinessError;
      console.error(`Failed to save CSV: ${error.message}`);
      throw new Error(`Failed to save CSV: ${error.message}`);
    }
  }

  /**
   * 导出测量记录到CSV（可选择目录）
   * @param config 导出配置
   * @param showPicker 是否显示文件选择器，默认true
   * @returns 导出文件路径
   */
  async exportMeasureRecordsToCsvWithPicker(
    config: ExportConfig,
    showPicker: boolean = true
  ): Promise<string> {
    const conditions: MeasureQueryCondition = {};
    if (config.startTime !== undefined) {
      conditions.startTime = config.startTime;
    }
    if (config.endTime !== undefined) {
      conditions.endTime = config.endTime;
    }

    const records = await this.getMeasureRecords(conditions, 'export');

    if (records.length === 0) {
      throw new Error('No data to export');
    }

    const csvContent = this.generateMeasureCsv(records);

    if (showPicker) {
      const targetPath = await this.selectDirectoryAndSave(config.fileName, csvContent);
      return targetPath;
    } else {
      return await this.saveCsvFile(config.fileName, csvContent);
    }
  }

  /**
   * 导出校准记录到CSV（可选择目录）
   */
  async exportCalibrateRecordsToCsvWithPicker(
    config: ExportConfig,
    showPicker: boolean = true
  ): Promise<string> {
    const conditions: CalibrateQueryCondition = {};
    if (config.startTime !== undefined) {
      conditions.startTime = config.startTime;
    }
    if (config.endTime !== undefined) {
      conditions.endTime = config.endTime;
    }

    const records = await this.getCalibrateRecords(conditions);

    if (records.length === 0) {
      throw new Error('No calibrate data to export');
    }

    const csvContent = this.generateCalibrateCsv(records);

    if (showPicker) {
      const targetPath = await this.selectDirectoryAndSave(config.fileName, csvContent);
      return targetPath;
    } else {
      return await this.saveCsvFile(config.fileName, csvContent);
    }
  }

  /**
   * 选择目录并保存文件（使用 @ohos.file.picker）
   * @param fileName 文件名（不含扩展名）
   * @param content 文件内容
   * @returns 保存的文件路径
   */
  private async selectDirectoryAndSave(fileName: string, content: string): Promise<string> {
    if (!this.context) {
      throw new Error('Context not available');
    }

    try {
      // 创建文件选择器
      const documentPicker = new picker.DocumentViewPicker();

      // 设置保存选项
      const saveOptions = new picker.DocumentSaveOptions();
      saveOptions.newFileNames = [`${fileName}.csv`];
      saveOptions.fileSuffixChoices = ['csv'];

      // 显示保存对话框，让用户选择保存位置
      const uri = await documentPicker.save(saveOptions);

      if (!uri) {
        throw new Error('User cancelled save operation');
      }

      const targetUri = Array.isArray(uri) ? uri[0] : uri;

      // 写入文件
      const bom = '\uFEFF';
      const contentWithBom = bom + content;

      const file = fs.openSync(targetUri, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY);
      fs.writeSync(file.fd, contentWithBom);
      fs.closeSync(file.fd);

      console.info(`CSV exported to user selected location: ${uri}`);
      return targetUri;

    } catch (err) {
      let error = err as BusinessError;
      console.error(`Failed to save CSV with picker: ${error.message}`);
      throw new Error(`Failed to save CSV: ${error.message}`);
    }
  }

  // ==================== 数据显示格式化 ====================

  /**
   * 格式化显示结果
   */
  displayResult(value: number): string {
    let formatted = value.toFixed(this.decimalNum);

    const numValue = parseFloat(formatted);
    if (Math.abs(numValue) < 0.000001 && formatted.startsWith('-')) {
      formatted = Math.abs(value).toFixed(this.decimalNum);
    }

    return formatted;
  }

  /**
   * 格式化显示有用结果
   */
  displayUsefulResult(value: number): string {
    let useNumber = this.settingUseNum;

    if (value >= 100) {
      useNumber -= 3;
    } else if (value >= 10) {
      useNumber -= 2;
    } else if (value >= 1) {
      useNumber -= 1;
    }

    useNumber = Math.max(0, useNumber);
    let formatted = value.toFixed(useNumber);

    const numValue = parseFloat(formatted);
    if (Math.abs(numValue) < 0.000001 && formatted.startsWith('-')) {
      formatted = Math.abs(value).toFixed(useNumber);
    }

    return formatted;
  }

  /**
   * 格式化显示吸光度
   */
  displayAbsorbance(absorbance: number): string {
    let decimalPlaces = 3;

    if (Math.abs(absorbance) < 100) {
      decimalPlaces = 3;
    } else if (Math.abs(absorbance) < 1000) {
      decimalPlaces = 2;
    } else {
      decimalPlaces = 1;
    }

    let formatted = absorbance.toFixed(decimalPlaces);

    const numValue = parseFloat(formatted);
    if (Math.abs(numValue) < 0.000001 && formatted.startsWith('-')) {
      formatted = Math.abs(absorbance).toFixed(decimalPlaces);
    }

    return formatted;
  }

  // ==================== 辅助方法 ====================

  /**
   * 获取标识文本
   */
  getModeText(mode: number): string {
    switch (mode) {
      case ResultMode.Normal: return '正常';
      case ResultMode.Offline: return '离线';
      case ResultMode.Maintain: return '维护';
      case ResultMode.Fault: return '故障';
      case ResultMode.Calibrate: return '校准';
      case ResultMode.OverRange: return '超量程';
      case ResultMode.OverUpper: return '超上限';
      case ResultMode.Quality: return '质控';
      case ResultMode.Debug: return '调试';
      default: return '未知';
    }
  }

  /**
   * 获取结果类型文本
   */
  getResultTypeText(resultType: number): string {
    switch (resultType) {
      case MeasureType.Blank: return '空白水';
      case MeasureType.Sample: return '水样';
      case MeasureType.Standard: return '标液';
      case MeasureType.Check: return '核查样';
      case MeasureType.AddStandard: return '加标样';
      case MeasureType.Parallel: return '平行样';
      case MeasureType.ZeroCheck: return '零点核查';
      case MeasureType.RangeCheck: return '量程核查';
      case MeasureType.ExtAddStandard: return '外部加标';
      case MeasureType.ExtParallel: return '外部平行';
      case MeasureType.QualityHandle: return '质控';
      default: return '未知';
    }
  }

  /**
   * 比较两条记录是否相等
   */
  compareMeasureRecords(record1: MeasureRecord, record2: MeasureRecord): RecordCompareResult {
    const diffFields: string[] = [];

    if (record1.dateTime !== record2.dateTime) diffFields.push('dateTime');
    if (Math.abs(record1.consistency - record2.consistency) > 0.0001) diffFields.push('consistency');
    if (Math.abs(record1.absorbance - record2.absorbance) > 0.0001) diffFields.push('absorbance');
    if (record1.mode !== record2.mode) diffFields.push('mode');
    if (record1.resultType !== record2.resultType) diffFields.push('resultType');
    if (Math.abs(record1.measureRange - record2.measureRange) > 0.0001) diffFields.push('measureRange');

    return {
      isEqual: diffFields.length === 0,
      diffFields: diffFields
    };
  }

  /**
   * 上传测量数据到服务器
   */
  private async uploadMeasureData(name: string, record: MeasureRecord): Promise<void> {
    // TODO: 实现数据上传逻辑
    console.info(`Upload measure data: ${name}, id: ${record.id}`);
  }

  /**
   * 上传校准数据到服务器
   */
  private async uploadCalibrateData(name: string, record: CalibrateRecord): Promise<void> {
    // TODO: 实现校准数据上传逻辑
    console.info(`Upload calibrate data: ${name}, id: ${record.id}`);
  }

  // ==================== 其他 ====================

  /**
   * 获取RdbManager实例
   */
  getRdbManager(): RdbManager {
    return this.rdbManager;
  }

  /**
   * 获取当前小数位数配置
   */
  getDecimalNum(): number {
    return this.decimalNum;
  }

  /**
   * 设置小数位数
   */
  setDecimalNum(num: number): void {
    this.decimalNum = Math.max(0, Math.min(6, num));
  }

  /**
   * 获取当前配置
   */
  getConfig(): ResultManagerConfig {
    return {
      decimalNum: this.decimalNum,
      settingUseNum: this.settingUseNum,
      unitMultiple: this.unitMultiple,
      autoBackupInterval: this.autoBackupInterval
    };
  }

  /**
   * 关闭结果管理器
   */
  async close(): Promise<void> {
    if (this.backupTimerId !== -1) {
      clearInterval(this.backupTimerId);
      this.backupTimerId = -1;
    }

    await this.rdbManager.close();
    this.isInitialized = false;
    console.info('ResultManager closed');
  }

  /**
   * 检查是否已初始化
   */
  isReady(): boolean {
    return this.isInitialized && this.rdbManager.isReady();
  }
}