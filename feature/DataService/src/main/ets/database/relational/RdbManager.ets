import relationalStore from '@ohos.data.relationalStore';
import { BusinessError } from '@ohos.base';
import {
  STORE_CONFIG,
  TABLE_MEASURE,
  TABLE_CALIBRATE,
  ALL_TABLE_SQL_S,
  ALL_INDEX_SQL_S,
  SQL_ADD_COLUMN_RANGE_INDEX,
} from './RdbConfig';
import {
  MeasureRecord,
  CalibrateRecord,
  MeasureQueryCondition,
  CalibrateQueryCondition,
  MeasureType,
  ResultMode,
} from './models/RelationalModels';

// 读取者上下文
interface MeasureReaderContext {
  pos: number;
  currentRecord: MeasureRecord | null;
  readerName: string;
}

interface CalibrateReaderContext {
  pos: number;
  currentRecord: CalibrateRecord | null;
  readerName: string;
}

export class RdbManager {
  private static instance: RdbManager;
  private rdbStore: relationalStore.RdbStore | null = null;
  private isInitialized: boolean = false;

  private measureReaders: Map<number, MeasureReaderContext> = new Map();
  private calibrateReaders: Map<number, CalibrateReaderContext> = new Map();
  private nextReaderId: number = 0;

  private constructor() {}

  static getInstance(): RdbManager {
    if (!RdbManager.instance) {
      RdbManager.instance = new RdbManager();
    }
    return RdbManager.instance;
  }

  // ==================== 初始化 ====================

  async init(context: Context): Promise<boolean> {
    if (this.isInitialized) {
      return true;
    }

    try {
      this.rdbStore = await relationalStore.getRdbStore(context, STORE_CONFIG);

      if (!this.rdbStore) {
        console.error('Failed to get RdbStore');
        return false;
      }

      await this.createAllTables();
      await this.createAllIndexes();
	  //数据库更改部分
      await this.addColumnRangeIndex();

      this.isInitialized = true;
      console.info('RdbManager initialized successfully');
      return true;
    } catch (err) {
      let error = err as BusinessError;
      console.error(`RdbManager init failed: ${error.message}`);
      return false;
    }
  }

  private async createAllTables(): Promise<void> {
    if (!this.rdbStore) return;
    for (const sql of ALL_TABLE_SQL_S) {
      await this.rdbStore.executeSql(sql);
    }
  }

  private async createAllIndexes(): Promise<void> {
    if (!this.rdbStore) return;
    for (const sql of ALL_INDEX_SQL_S) {
      await this.rdbStore.executeSql(sql);
    }
  }

  private async addColumnRangeIndex(): Promise<void> {
    if (!this.rdbStore) return;

    try {
      // 检查是否需要新增 rangeIndex 字段
      const hasRangeIndex = await this.checkColumnExists(TABLE_CALIBRATE, 'rangeIndex');

      if (!hasRangeIndex) {
        console.info('Adding rangeIndex column to calibrate_record table');
        await this.rdbStore.executeSql(SQL_ADD_COLUMN_RANGE_INDEX);
        console.info('rangeIndex column added successfully');

        // 预留：对已存在数据进行处理
        await this.processExistingCalibrateData();
      }
    } catch (err) {
      console.error(`Database upgrade failed: ${err}`);
    }
  }

  /**
   * 检查表中是否存在指定列
   */
  private async checkColumnExists(tableName: string, columnName: string): Promise<boolean> {
    if (!this.rdbStore) return false;

    try {
      const sql = `PRAGMA table_info(${tableName})`;
      const resultSet = await this.rdbStore.querySql(sql);
      let exists = false;

      if (resultSet.goToFirstRow()) {
        do {
          const name = resultSet.getString(resultSet.getColumnIndex('name'));
          if (name === columnName) {
            exists = true;
            break;
          }
        } while (resultSet.goToNextRow());
      }

      return exists;
    } catch (err) {
      console.error(`Check column exists failed: ${err}`);
      return false;
    }
  }

  /**
   * 增加范围索引的回调函数接口
   */
  private async processExistingCalibrateData(): Promise<void>{
    if (!this.rdbStore) return;


    try {

    } catch (err) {
      console.error(`Process existing calibrate data failed: ${err}`);
    }
  }

  async forceCheckpoint(): Promise<void> {
    if (!this.rdbStore) {
      throw new Error('Database not initialized');
    }
    try {
      await this.rdbStore.executeSql('PRAGMA wal_checkpoint(TRUNCATE);');
      console.info('WAL checkpoint completed');
    } catch (err) {
      console.error(`WAL checkpoint failed: ${err}`);
    }
  }

  // ==================== 辅助方法 ====================

  private applyMeasureConditions(
    predicates: relationalStore.RdbPredicates,
    conditions?: MeasureQueryCondition
  ): relationalStore.RdbPredicates {
    if (!conditions) return predicates;

    if (conditions.startTime !== undefined && conditions.endTime !== undefined) {
      predicates.between('dateTime', conditions.startTime, conditions.endTime);
    } else if (conditions.startTime !== undefined) {
      predicates.greaterThanOrEqualTo('dateTime', conditions.startTime);
    } else if (conditions.endTime !== undefined) {
      predicates.lessThanOrEqualTo('dateTime', conditions.endTime);
    }

    if (conditions.resultType !== undefined) {
      predicates.equalTo('resultType', conditions.resultType);
    }
    if (conditions.mode !== undefined) {
      predicates.equalTo('mode', conditions.mode);
    }
    return predicates;
  }

  private applyCalibrateConditions(
    predicates: relationalStore.RdbPredicates,
    conditions?: CalibrateQueryCondition
  ): relationalStore.RdbPredicates {
    if (!conditions) return predicates;

    if (conditions.startTime !== undefined && conditions.endTime !== undefined) {
      predicates.between('dateTime', conditions.startTime, conditions.endTime);
    } else if (conditions.startTime !== undefined) {
      predicates.greaterThanOrEqualTo('dateTime', conditions.startTime);
    } else if (conditions.endTime !== undefined) {
      predicates.lessThanOrEqualTo('dateTime', conditions.endTime);
    }

    if (conditions.calibrateType !== undefined) {
      predicates.equalTo('calibrateType', conditions.calibrateType);
    }
    if (conditions.minR2 !== undefined) {
      predicates.greaterThanOrEqualTo('R2', conditions.minR2);
    }
    return predicates;
  }

  private resultSetToMeasureRecord(resultSet: relationalStore.ResultSet): MeasureRecord {
    const record = new MeasureRecord();
    record.id = resultSet.getLong(resultSet.getColumnIndex('id'));
    record.dateTime = resultSet.getLong(resultSet.getColumnIndex('dateTime'));
    record.consistency = resultSet.getDouble(resultSet.getColumnIndex('consistency'));
    record.absorbance = resultSet.getDouble(resultSet.getColumnIndex('absorbance'));
    record.mode = resultSet.getLong(resultSet.getColumnIndex('mode'));
    record.resultType = resultSet.getLong(resultSet.getColumnIndex('resultType'));
    record.initReferenceAD = resultSet.getLong(resultSet.getColumnIndex('initReferenceAD'));
    record.initMeasureAD = resultSet.getLong(resultSet.getColumnIndex('initMeasureAD'));
    record.finalReferenceAD = resultSet.getLong(resultSet.getColumnIndex('finalReferenceAD'));
    record.finalMeasureAD = resultSet.getLong(resultSet.getColumnIndex('finalMeasureAD'));
    record.initThermostatTemp = resultSet.getDouble(resultSet.getColumnIndex('initThermostatTemp'));
    record.initEnvironmentTemp = resultSet.getDouble(resultSet.getColumnIndex('initEnvironmentTemp'));
    record.finalThermostatTemp = resultSet.getDouble(resultSet.getColumnIndex('finalThermostatTemp'));
    record.finalEnvironmentTemp = resultSet.getDouble(resultSet.getColumnIndex('finalEnvironmentTemp'));
    record.initConsistency = resultSet.getDouble(resultSet.getColumnIndex('initConsistency'));
    record.measureTime = resultSet.getLong(resultSet.getColumnIndex('measureTime'));
    record.addStandardConsistency = resultSet.getDouble(resultSet.getColumnIndex('addStandardConsistency'));
    record.measureRange = resultSet.getDouble(resultSet.getColumnIndex('measureRange'));
    record.versionString = resultSet.getString(resultSet.getColumnIndex('version'));
    return record;
  }

  private resultSetToCalibrateRecord(resultSet: relationalStore.ResultSet): CalibrateRecord {
    const record = new CalibrateRecord();
    record.id = resultSet.getLong(resultSet.getColumnIndex('id'));
    record.dateTime = resultSet.getLong(resultSet.getColumnIndex('dateTime'));
    record.curveK = resultSet.getDouble(resultSet.getColumnIndex('curveK'));
    record.curveB = resultSet.getDouble(resultSet.getColumnIndex('curveB'));
    record.R2 = resultSet.getDouble(resultSet.getColumnIndex('R2'));

    record.point0InitAbsorbance = resultSet.getDouble(resultSet.getColumnIndex('point0_initAbsorbance'));
    record.point0Absorbance = resultSet.getDouble(resultSet.getColumnIndex('point0_absorbance'));
    record.point0Consistency = resultSet.getDouble(resultSet.getColumnIndex('point0_consistency'));
    record.initReferenceAD0 = resultSet.getLong(resultSet.getColumnIndex('initReferenceAD0'));
    record.initMeasureAD0 = resultSet.getLong(resultSet.getColumnIndex('initMeasureAD0'));
    record.finalReferenceAD0 = resultSet.getLong(resultSet.getColumnIndex('finalReferenceAD0'));
    record.finalMeasureAD0 = resultSet.getLong(resultSet.getColumnIndex('finalMeasureAD0'));
    record.point0InitThermostatTemp = resultSet.getDouble(resultSet.getColumnIndex('point0_initThermostatTemp'));
    record.point0InitEnvironmentTemp = resultSet.getDouble(resultSet.getColumnIndex('point0_initEnvironmentTemp'));
    record.point0FinalThermostatTemp = resultSet.getDouble(resultSet.getColumnIndex('point0_finalThermostatTemp'));
    record.point0FinalEnvironmentTemp = resultSet.getDouble(resultSet.getColumnIndex('point0_finalEnvironmentTemp'));

    record.point1InitAbsorbance = resultSet.getDouble(resultSet.getColumnIndex('point1_initAbsorbance'));
    record.point1Absorbance = resultSet.getDouble(resultSet.getColumnIndex('point1_absorbance'));
    record.point1Consistency = resultSet.getDouble(resultSet.getColumnIndex('point1_consistency'));
    record.initReferenceAD1 = resultSet.getLong(resultSet.getColumnIndex('initReferenceAD1'));
    record.initMeasureAD1 = resultSet.getLong(resultSet.getColumnIndex('initMeasureAD1'));
    record.finalReferenceAD1 = resultSet.getLong(resultSet.getColumnIndex('finalReferenceAD1'));
    record.finalMeasureAD1 = resultSet.getLong(resultSet.getColumnIndex('finalMeasureAD1'));
    record.point1InitThermostatTemp = resultSet.getDouble(resultSet.getColumnIndex('point1_initThermostatTemp'));
    record.point1InitEnvironmentTemp = resultSet.getDouble(resultSet.getColumnIndex('point1_initEnvironmentTemp'));
    record.point1FinalThermostatTemp = resultSet.getDouble(resultSet.getColumnIndex('point1_finalThermostatTemp'));
    record.point1FinalEnvironmentTemp = resultSet.getDouble(resultSet.getColumnIndex('point1_finalEnvironmentTemp'));

    record.calibrateTime = resultSet.getLong(resultSet.getColumnIndex('calibrateTime'));
    record.measureRange = resultSet.getDouble(resultSet.getColumnIndex('measureRange'));
    record.rangeIndex = resultSet.getLong(resultSet.getColumnIndex('rangeIndex'));  // 新增
    record.versionString = resultSet.getString(resultSet.getColumnIndex('version'));
    return record;
  }
  // ==================== 测量记录读取者管理 ====================

  registerMeasureReader(readerName: string = 'default'): number {
    const readerId = this.nextReaderId++;
    this.measureReaders.set(readerId, { pos: 0, currentRecord: null, readerName });
    return readerId;
  }

  unregisterMeasureReader(readerId: number): void {
    this.measureReaders.delete(readerId);
  }

  // ==================== 测量记录CRUD ====================

  async addMeasureRecord(record: MeasureRecord): Promise<number> {
    if (!this.rdbStore) throw new Error('Database not initialized');

    record.versionString = '1.0.0.2';

    const valueBucket: relationalStore.ValuesBucket = {
      dateTime: record.dateTime,
      consistency: record.consistency,
      absorbance: record.absorbance,
      mode: record.mode,
      resultType: record.resultType,
      initReferenceAD: record.initReferenceAD,
      initMeasureAD: record.initMeasureAD,
      finalReferenceAD: record.finalReferenceAD,
      finalMeasureAD: record.finalMeasureAD,
      initThermostatTemp: record.initThermostatTemp,
      initEnvironmentTemp: record.initEnvironmentTemp,
      finalThermostatTemp: record.finalThermostatTemp,
      finalEnvironmentTemp: record.finalEnvironmentTemp,
      initConsistency: record.initConsistency,
      measureTime: record.measureTime,
      addStandardConsistency: record.addStandardConsistency,
      measureRange: record.measureRange,
      version: record.versionString,
    };

    const rowId = await this.rdbStore.insert(TABLE_MEASURE, valueBucket);
    if (rowId > 0) record.id = rowId;
    return rowId;
  }

  async getMeasureRecordById(id: number): Promise<MeasureRecord | null> {
    if (!this.rdbStore) return null;
    const predicates = new relationalStore.RdbPredicates(TABLE_MEASURE);
    predicates.equalTo('id', id);
    const resultSet = await this.rdbStore.query(predicates);
    let record: MeasureRecord | null = null;
    if (resultSet.goToFirstRow()) {
      record = this.resultSetToMeasureRecord(resultSet);
    }
    resultSet.close();
    return record;
  }

  async getMeasureRecordCount(conditions?: MeasureQueryCondition): Promise<number> {
    if (!this.rdbStore) return 0;
    let predicates = new relationalStore.RdbPredicates(TABLE_MEASURE);
    predicates = this.applyMeasureConditions(predicates, conditions);
    const resultSet = await this.rdbStore.query(predicates, ['COUNT(*)']);
    let count = 0;
    if (resultSet.goToFirstRow()) {
      count = resultSet.getLong(0);
    }
    resultSet.close();
    return count;
  }

  async getMeasureRecords(
    conditions?: MeasureQueryCondition,
    readerId?: number
  ): Promise<MeasureRecord[]> {
    if (!this.rdbStore) return [];

    let predicates = new relationalStore.RdbPredicates(TABLE_MEASURE);
    predicates = this.applyMeasureConditions(predicates, conditions);

    if (conditions?.orderBy === 'desc') {
      predicates.orderByDesc('dateTime');
    } else {
      predicates.orderByAsc('dateTime');
    }

    if (conditions?.limit !== undefined) predicates.limitAs(conditions.limit);
    if (conditions?.offset !== undefined) predicates.offsetAs(conditions.offset);

    const resultSet = await this.rdbStore.query(predicates);
    const records: MeasureRecord[] = [];
    while (resultSet.goToNextRow()) {
      records.push(this.resultSetToMeasureRecord(resultSet));
    }

    if (readerId !== undefined && this.measureReaders.has(readerId) && records.length > 0) {
      const reader = this.measureReaders.get(readerId);
      if (reader) {
        reader.currentRecord = records[records.length - 1];
        if (conditions?.offset !== undefined) {
          reader.pos = conditions.offset + records.length;
        }
      }
    }

    resultSet.close();
    return records;
  }

  async getLatestMeasureRecords(limit: number = 10): Promise<MeasureRecord[]> {
    return this.getMeasureRecords({ limit, orderBy: 'desc' });
  }

  async getLatestMeasureRecord(): Promise<MeasureRecord | null> {
    const records = await this.getLatestMeasureRecords(1);
    return records.length > 0 ? records[0] : null;
  }

  async getMeasureRecordsByType(resultType: MeasureType, limit?: number): Promise<MeasureRecord[]> {
    return this.getMeasureRecords({ resultType, limit, orderBy: 'desc' });
  }

  async getMeasureRecordsByTimeRange(
    startTime: number,
    endTime: number,
    limit?: number
  ): Promise<MeasureRecord[]> {
    return this.getMeasureRecords({ startTime, endTime, limit, orderBy: 'desc' });
  }

  async getMeasureRecordsByMode(mode: ResultMode, limit?: number): Promise<MeasureRecord[]> {
    return this.getMeasureRecords({ mode, limit, orderBy: 'desc' });
  }

  async isMeasureRecordExists(record: MeasureRecord): Promise<boolean> {
    if (!this.rdbStore) return false;
    const predicates = new relationalStore.RdbPredicates(TABLE_MEASURE);
    predicates.equalTo('dateTime', record.dateTime);
    predicates.equalTo('resultType', record.resultType);
    const resultSet = await this.rdbStore.query(predicates);
    const exists = resultSet.goToFirstRow();
    resultSet.close();
    return exists;
  }

  async updateMeasureRecord(record: MeasureRecord): Promise<number> {
    if (!this.rdbStore || !record.id) return 0;

    const valueBucket: relationalStore.ValuesBucket = {
      consistency: record.consistency,
      absorbance: record.absorbance,
      mode: record.mode,
      resultType: record.resultType,
      measureRange: record.measureRange,
      version: record.versionString || '1.0.0.2'
    };

    const predicates = new relationalStore.RdbPredicates(TABLE_MEASURE);
    predicates.equalTo('id', record.id);
    return await this.rdbStore.update(valueBucket, predicates);
  }

  async deleteMeasureRecordById(id: number): Promise<number> {
    if (!this.rdbStore) return 0;
    const predicates = new relationalStore.RdbPredicates(TABLE_MEASURE);
    predicates.equalTo('id', id);
    return await this.rdbStore.delete(predicates);
  }

  async deleteMeasureRecordsByTimeRange(startTime: number, endTime: number): Promise<number> {
    if (!this.rdbStore) return 0;
    const predicates = new relationalStore.RdbPredicates(TABLE_MEASURE);
    predicates.between('dateTime', startTime, endTime);
    return await this.rdbStore.delete(predicates);
  }

  async clearMeasureRecords(): Promise<number> {
    if (!this.rdbStore) return 0;
    const predicates = new relationalStore.RdbPredicates(TABLE_MEASURE);
    const deletedRows = await this.rdbStore.delete(predicates);
    this.measureReaders.forEach((reader) => {
      reader.pos = 0;
      reader.currentRecord = null;
    });
    return deletedRows;
  }

  // ==================== 校准记录读取者管理 ====================
  registerCalibrateReader(readerName: string = 'default'): number {
    const readerId = this.nextReaderId++;
    this.calibrateReaders.set(readerId, { pos: 0, currentRecord: null, readerName });
    return readerId;
  }

  unregisterCalibrateReader(readerId: number): void {
    this.calibrateReaders.delete(readerId);
  }

  // ==================== 校准记录CRUD ====================

  async addCalibrateRecord(record: CalibrateRecord): Promise<number> {
    if (!this.rdbStore) throw new Error('Database not initialized');

    record.versionString = '1.0.0.2';

    const valueBucket: relationalStore.ValuesBucket = {
      dateTime: record.dateTime,
      curveK: record.curveK,
      curveB: record.curveB,
      R2: record.R2,
      point0_initAbsorbance: record.point0InitAbsorbance,
      point0_absorbance: record.point0Absorbance,
      point0_consistency: record.point0Consistency,
      initReferenceAD0: record.initReferenceAD0,
      initMeasureAD0: record.initMeasureAD0,
      finalReferenceAD0: record.finalReferenceAD0,
      finalMeasureAD0: record.finalMeasureAD0,
      point0_initThermostatTemp: record.point0InitThermostatTemp,
      point0_initEnvironmentTemp: record.point0InitEnvironmentTemp,
      point0_finalThermostatTemp: record.point0FinalThermostatTemp,
      point0_finalEnvironmentTemp: record.point0FinalEnvironmentTemp,
      point1_initAbsorbance: record.point1InitAbsorbance,
      point1_absorbance: record.point1Absorbance,
      point1_consistency: record.point1Consistency,
      initReferenceAD1: record.initReferenceAD1,
      initMeasureAD1: record.initMeasureAD1,
      finalReferenceAD1: record.finalReferenceAD1,
      finalMeasureAD1: record.finalMeasureAD1,
      point1_initThermostatTemp: record.point1InitThermostatTemp,
      point1_initEnvironmentTemp: record.point1InitEnvironmentTemp,
      point1_finalThermostatTemp: record.point1FinalThermostatTemp,
      point1_finalEnvironmentTemp: record.point1FinalEnvironmentTemp,
      calibrateTime: record.calibrateTime,
      measureRange: record.measureRange,
      rangeIndex: record.rangeIndex,  // 新增字段
      version: record.versionString,
    };

    const rowId = await this.rdbStore.insert(TABLE_CALIBRATE, valueBucket);
    if (rowId > 0) record.id = rowId;
    return rowId;
  }

  async getLatestCalibrateRecord(): Promise<CalibrateRecord | null> {
    if (!this.rdbStore) return null;
    const predicates = new relationalStore.RdbPredicates(TABLE_CALIBRATE);
    predicates.orderByDesc('dateTime').limitAs(1);
    const resultSet = await this.rdbStore.query(predicates);
    let record: CalibrateRecord | null = null;
    if (resultSet.goToFirstRow()) {
      record = this.resultSetToCalibrateRecord(resultSet);
    }
    resultSet.close();
    return record;
  }

  async getValidCalibrateRecord(minR2: number = 0.99): Promise<CalibrateRecord | null> {
    if (!this.rdbStore) return null;
    const predicates = new relationalStore.RdbPredicates(TABLE_CALIBRATE);
    predicates.greaterThanOrEqualTo('R2', minR2);
    predicates.orderByDesc('dateTime').limitAs(1);
    const resultSet = await this.rdbStore.query(predicates);
    let record: CalibrateRecord | null = null;
    if (resultSet.goToFirstRow()) {
      record = this.resultSetToCalibrateRecord(resultSet);
    }
    resultSet.close();
    return record;
  }

  async getCalibrateRecords(conditions?: CalibrateQueryCondition): Promise<CalibrateRecord[]> {
    if (!this.rdbStore) return [];

    let predicates = new relationalStore.RdbPredicates(TABLE_CALIBRATE);
    predicates = this.applyCalibrateConditions(predicates, conditions);

    if (conditions?.orderBy === 'desc') {
      predicates.orderByDesc('dateTime');
    } else {
      predicates.orderByAsc('dateTime');
    }

    if (conditions?.limit !== undefined) predicates.limitAs(conditions.limit);
    if (conditions?.offset !== undefined) predicates.offsetAs(conditions.offset);

    const resultSet = await this.rdbStore.query(predicates);
    const records: CalibrateRecord[] = [];
    while (resultSet.goToNextRow()) {
      records.push(this.resultSetToCalibrateRecord(resultSet));
    }
    resultSet.close();
    return records;
  }

  async deleteCalibrateRecordById(id: number): Promise<number> {
    if (!this.rdbStore) return 0;
    const predicates = new relationalStore.RdbPredicates(TABLE_CALIBRATE);
    predicates.equalTo('id', id);
    return await this.rdbStore.delete(predicates);
  }

  async clearCalibrateRecords(): Promise<number> {
    if (!this.rdbStore) return 0;
    const predicates = new relationalStore.RdbPredicates(TABLE_CALIBRATE);
    return await this.rdbStore.delete(predicates);
  }

  // ==================== 关闭 ====================

  async close(): Promise<void> {
    if (this.rdbStore) {
      await this.rdbStore.close();
      this.rdbStore = null;
      this.isInitialized = false;
    }
  }

  isReady(): boolean {
    return this.isInitialized && this.rdbStore !== null;
  }
}