import { common } from '@kit.AbilityKit';
import { relationalStore } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import {
  ALL_FILTER_OPTION,
  AlarmRecord,
  AlarmRecordInput,
  AlarmRecordQuery,
  CalibrationCurveInput,
  CalibrationCurveQuery,
  CalibrationCurveRecord,
  DataPageQueryResult,
  MeasurementRecord,
  MeasurementRecordInput,
  MeasurementRecordQuery,
  MeasurementTrendQuery,
  OperationLogInput,
  OperationLogQuery,
  OperationLogRecord
} from '../models/dataRecordTypes';

const DOMAIN = 0x0003;
const TAG = 'DataRecordDao';

const STORE_CONFIG: relationalStore.StoreConfig = {
  name: 'waterquality_data_records.db',
  securityLevel: relationalStore.SecurityLevel.S1
};

const TABLE_ALARM = 'alarm_records';
const TABLE_OPERATION_LOG = 'operation_logs';
const TABLE_MEASUREMENT = 'measurement_records';
const TABLE_CALIBRATION_CURVE = 'calibration_curve_records';

const CREATE_ALARM_TABLE_SQL =
  'CREATE TABLE IF NOT EXISTS alarm_records (' +
    'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
    'alarm_time INTEGER NOT NULL, ' +
    'alarm_code INTEGER NOT NULL, ' +
    'alarm_type TEXT NOT NULL, ' +
    'category TEXT NOT NULL, ' +
    'content TEXT NOT NULL, ' +
    'source TEXT NOT NULL, ' +
    'status TEXT NOT NULL, ' +
    'created_at INTEGER NOT NULL, ' +
    'unique_key TEXT NOT NULL' +
  ')';

const CREATE_OPERATION_LOG_TABLE_SQL =
  'CREATE TABLE IF NOT EXISTS operation_logs (' +
    'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
    'log_time INTEGER NOT NULL, ' +
    'log_type TEXT NOT NULL, ' +
    'action TEXT NOT NULL, ' +
    'content TEXT NOT NULL, ' +
    'log_result TEXT NOT NULL, ' +
    'source TEXT NOT NULL, ' +
    'operator_name TEXT NOT NULL, ' +
    'detail TEXT NOT NULL, ' +
    'created_at INTEGER NOT NULL' +
  ')';

const CREATE_MEASUREMENT_TABLE_SQL =
  'CREATE TABLE IF NOT EXISTS measurement_records (' +
    'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
    'measurement_time INTEGER NOT NULL, ' +
    'parameter_code INTEGER NOT NULL, ' +
    'parameter_name TEXT NOT NULL, ' +
    'result_value REAL NOT NULL, ' +
    'result_unit TEXT NOT NULL, ' +
    'absorbance REAL, ' +
    'flag_code TEXT NOT NULL, ' +
    'flag_label TEXT NOT NULL, ' +
    'result_type_code TEXT NOT NULL, ' +
    'result_type_label TEXT NOT NULL, ' +
    'range_value REAL, ' +
    'range_label TEXT NOT NULL, ' +
    'created_at INTEGER NOT NULL, ' +
    'unique_key TEXT NOT NULL' +
  ')';

const CREATE_CALIBRATION_CURVE_TABLE_SQL =
  'CREATE TABLE IF NOT EXISTS calibration_curve_records (' +
    'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
    'calibration_time INTEGER NOT NULL, ' +
    'slope REAL NOT NULL, ' +
    'intercept REAL NOT NULL, ' +
    'zero_absorbance REAL, ' +
    'span_absorbance REAL, ' +
    'zero_concentration REAL, ' +
    'span_concentration REAL, ' +
    'range_value REAL, ' +
    'range_label TEXT NOT NULL, ' +
    'is_current INTEGER NOT NULL, ' +
    'source TEXT NOT NULL, ' +
    'operator_name TEXT NOT NULL, ' +
    'created_at INTEGER NOT NULL, ' +
    'unique_key TEXT NOT NULL' +
  ')';

const CREATE_ALARM_UNIQUE_INDEX_SQL =
  'CREATE UNIQUE INDEX IF NOT EXISTS idx_alarm_records_unique_key ON alarm_records(unique_key)';
const CREATE_ALARM_QUERY_INDEX_SQL =
  'CREATE INDEX IF NOT EXISTS idx_alarm_records_query ON alarm_records(alarm_time, alarm_type)';
const CREATE_OPERATION_LOG_QUERY_INDEX_SQL =
  'CREATE INDEX IF NOT EXISTS idx_operation_logs_query ON operation_logs(log_time, log_type)';
const CREATE_MEASUREMENT_UNIQUE_INDEX_SQL =
  'CREATE UNIQUE INDEX IF NOT EXISTS idx_measurement_records_unique_key ON measurement_records(unique_key)';
const CREATE_MEASUREMENT_QUERY_INDEX_SQL =
  'CREATE INDEX IF NOT EXISTS idx_measurement_records_query ON measurement_records(measurement_time, flag_label, result_type_label)';
const CREATE_CALIBRATION_CURVE_UNIQUE_INDEX_SQL =
  'CREATE UNIQUE INDEX IF NOT EXISTS idx_calibration_curve_records_unique_key ON calibration_curve_records(unique_key)';
const CREATE_CALIBRATION_CURVE_QUERY_INDEX_SQL =
  'CREATE INDEX IF NOT EXISTS idx_calibration_curve_records_query ON calibration_curve_records(calibration_time, is_current)';

interface QueryParts {
  whereSql: string;
  bindArgs: Array<relationalStore.ValueType>;
}

export class DataRecordDao {
  private static store: relationalStore.RdbStore | null = null;
  private static initPromise: Promise<boolean> | null = null;

  static async init(context: common.Context): Promise<boolean> {
    if (DataRecordDao.store) {
      return true;
    }
    if (DataRecordDao.initPromise) {
      return DataRecordDao.initPromise;
    }

    DataRecordDao.initPromise = DataRecordDao.initInternal(context);
    try {
      return await DataRecordDao.initPromise;
    } finally {
      DataRecordDao.initPromise = null;
    }
  }

  static isInitialized(): boolean {
    return DataRecordDao.store !== null;
  }

  static async insertAlarmRecord(record: AlarmRecordInput): Promise<boolean> {
    const store = DataRecordDao.store;
    if (!store) {
      hilog.warn(DOMAIN, TAG, 'insert alarm ignored: database is not initialized');
      return false;
    }

    if (await DataRecordDao.hasAlarmRecord(record.uniqueKey)) {
      return false;
    }

    try {
      const bucket: relationalStore.ValuesBucket = {
        alarm_time: record.alarmTime,
        alarm_code: record.alarmCode,
        alarm_type: record.alarmType,
        category: record.category,
        content: record.content,
        source: record.source,
        status: record.status,
        created_at: Date.now(),
        unique_key: record.uniqueKey
      };
      await store.insert(TABLE_ALARM, bucket);
      return true;
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'insert alarm failed: %{public}s', JSON.stringify(err));
      return false;
    }
  }

  static async insertOperationLog(record: OperationLogInput): Promise<boolean> {
    const store = DataRecordDao.store;
    if (!store) {
      hilog.warn(DOMAIN, TAG, 'insert operation log ignored: database is not initialized');
      return false;
    }

    try {
      const bucket: relationalStore.ValuesBucket = {
        log_time: record.logTime,
        log_type: record.logType,
        action: record.action,
        content: record.content,
        log_result: record.result,
        source: record.source,
        operator_name: record.operatorName,
        detail: record.detail,
        created_at: Date.now()
      };
      await store.insert(TABLE_OPERATION_LOG, bucket);
      return true;
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'insert operation log failed: %{public}s', JSON.stringify(err));
      return false;
    }
  }

  static async insertMeasurementRecord(record: MeasurementRecordInput): Promise<boolean> {
    const store = DataRecordDao.store;
    if (!store) {
      hilog.warn(DOMAIN, TAG, 'insert measurement ignored: database is not initialized');
      return false;
    }

    if (await DataRecordDao.hasMeasurementRecord(record.uniqueKey)) {
      return false;
    }

    try {
      const bucket: relationalStore.ValuesBucket = {
        measurement_time: record.measurementTime,
        parameter_code: record.parameterCode,
        parameter_name: record.parameterName,
        result_value: record.resultValue,
        result_unit: record.resultUnit,
        absorbance: record.absorbance,
        flag_code: record.flagCode,
        flag_label: record.flagLabel,
        result_type_code: record.resultTypeCode,
        result_type_label: record.resultTypeLabel,
        range_value: record.rangeValue,
        range_label: record.rangeLabel,
        created_at: Date.now(),
        unique_key: record.uniqueKey
      };
      await store.insert(TABLE_MEASUREMENT, bucket);
      return true;
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'insert measurement failed: %{public}s', JSON.stringify(err));
      return false;
    }
  }

  static async insertCalibrationCurveRecord(record: CalibrationCurveInput): Promise<boolean> {
    const store = DataRecordDao.store;
    if (!store) {
      hilog.warn(DOMAIN, TAG, 'insert calibration curve ignored: database is not initialized');
      return false;
    }

    if (await DataRecordDao.hasCalibrationCurveRecord(record.uniqueKey)) {
      return false;
    }

    try {
      const bucket: relationalStore.ValuesBucket = {
        calibration_time: record.calibrationTime,
        slope: record.slope,
        intercept: record.intercept,
        zero_absorbance: record.zeroAbsorbance,
        span_absorbance: record.spanAbsorbance,
        zero_concentration: record.zeroConcentration,
        span_concentration: record.spanConcentration,
        range_value: record.rangeValue,
        range_label: record.rangeLabel,
        is_current: record.isCurrent ? 1 : 0,
        source: record.source,
        operator_name: record.operatorName,
        created_at: Date.now(),
        unique_key: record.uniqueKey
      };
      await store.insert(TABLE_CALIBRATION_CURVE, bucket);
      return true;
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'insert calibration curve failed: %{public}s', JSON.stringify(err));
      return false;
    }
  }

  static async queryAlarmRecords(query: AlarmRecordQuery): Promise<DataPageQueryResult<AlarmRecord>> {
    const emptyResult = DataRecordDao.emptyPage<AlarmRecord>(query.page, query.pageSize);
    const store = DataRecordDao.store;
    if (!store) {
      return emptyResult;
    }

    const parts = DataRecordDao.buildAlarmQueryParts(query);
    const total = await DataRecordDao.queryCount(store, TABLE_ALARM, parts);
    const page = DataRecordDao.normalizePage(query.page, total, query.pageSize);
    const offset = (page - 1) * query.pageSize;
    const bindArgs = DataRecordDao.copyBindArgs(parts.bindArgs);
    bindArgs.push(query.pageSize);
    bindArgs.push(offset);

    const sql =
      'SELECT id, alarm_time, alarm_code, alarm_type, category, content, source, status, created_at, unique_key ' +
      `FROM ${TABLE_ALARM} ${parts.whereSql} ` +
      'ORDER BY alarm_time DESC, id DESC LIMIT ? OFFSET ?';

    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await store.querySql(sql, bindArgs);
      const records: AlarmRecord[] = [];
      while (resultSet.goToNextRow()) {
        records.push(DataRecordDao.readAlarmRecord(resultSet));
      }
      return {
        records: records,
        total: total,
        page: page,
        pageSize: query.pageSize,
        totalPages: DataRecordDao.totalPages(total, query.pageSize)
      };
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'query alarm records failed: %{public}s', JSON.stringify(err));
      return emptyResult;
    } finally {
      if (resultSet) {
        resultSet.close();
      }
    }
  }

  static async queryOperationLogs(query: OperationLogQuery): Promise<DataPageQueryResult<OperationLogRecord>> {
    const emptyResult = DataRecordDao.emptyPage<OperationLogRecord>(query.page, query.pageSize);
    const store = DataRecordDao.store;
    if (!store) {
      return emptyResult;
    }

    const parts = DataRecordDao.buildOperationLogQueryParts(query);
    const total = await DataRecordDao.queryCount(store, TABLE_OPERATION_LOG, parts);
    const page = DataRecordDao.normalizePage(query.page, total, query.pageSize);
    const offset = (page - 1) * query.pageSize;
    const bindArgs = DataRecordDao.copyBindArgs(parts.bindArgs);
    bindArgs.push(query.pageSize);
    bindArgs.push(offset);

    const sql =
      'SELECT id, log_time, log_type, action, content, log_result, source, operator_name, detail, created_at ' +
      `FROM ${TABLE_OPERATION_LOG} ${parts.whereSql} ` +
      'ORDER BY log_time DESC, id DESC LIMIT ? OFFSET ?';

    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await store.querySql(sql, bindArgs);
      const records: OperationLogRecord[] = [];
      while (resultSet.goToNextRow()) {
        records.push(DataRecordDao.readOperationLogRecord(resultSet));
      }
      return {
        records: records,
        total: total,
        page: page,
        pageSize: query.pageSize,
        totalPages: DataRecordDao.totalPages(total, query.pageSize)
      };
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'query operation logs failed: %{public}s', JSON.stringify(err));
      return emptyResult;
    } finally {
      if (resultSet) {
        resultSet.close();
      }
    }
  }

  static async queryMeasurementRecords(query: MeasurementRecordQuery): Promise<DataPageQueryResult<MeasurementRecord>> {
    const emptyResult = DataRecordDao.emptyPage<MeasurementRecord>(query.page, query.pageSize);
    const store = DataRecordDao.store;
    if (!store) {
      return emptyResult;
    }

    const parts = DataRecordDao.buildMeasurementQueryParts(query);
    const total = await DataRecordDao.queryCount(store, TABLE_MEASUREMENT, parts);
    const page = DataRecordDao.normalizePage(query.page, total, query.pageSize);
    const offset = (page - 1) * query.pageSize;
    const bindArgs = DataRecordDao.copyBindArgs(parts.bindArgs);
    bindArgs.push(query.pageSize);
    bindArgs.push(offset);

    const sql =
      'SELECT id, measurement_time, parameter_code, parameter_name, result_value, result_unit, absorbance, ' +
      'flag_code, flag_label, result_type_code, result_type_label, range_value, range_label, created_at, unique_key ' +
      `FROM ${TABLE_MEASUREMENT} ${parts.whereSql} ` +
      'ORDER BY measurement_time DESC, id DESC LIMIT ? OFFSET ?';

    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await store.querySql(sql, bindArgs);
      const records: MeasurementRecord[] = [];
      while (resultSet.goToNextRow()) {
        records.push(DataRecordDao.readMeasurementRecord(resultSet));
      }
      return {
        records: records,
        total: total,
        page: page,
        pageSize: query.pageSize,
        totalPages: DataRecordDao.totalPages(total, query.pageSize)
      };
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'query measurement records failed: %{public}s', JSON.stringify(err));
      return emptyResult;
    } finally {
      if (resultSet) {
        resultSet.close();
      }
    }
  }

  static async queryMeasurementTrendRecords(query: MeasurementTrendQuery): Promise<MeasurementRecord[]> {
    const store = DataRecordDao.store;
    if (!store) {
      return [];
    }

    const parts = DataRecordDao.buildMeasurementTrendQueryParts(query);
    const sql =
      'SELECT id, measurement_time, parameter_code, parameter_name, result_value, result_unit, absorbance, ' +
      'flag_code, flag_label, result_type_code, result_type_label, range_value, range_label, created_at, unique_key ' +
      `FROM ${TABLE_MEASUREMENT} ${parts.whereSql} ` +
      'ORDER BY measurement_time ASC, id ASC';

    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await store.querySql(sql, parts.bindArgs);
      const records: MeasurementRecord[] = [];
      while (resultSet.goToNextRow()) {
        records.push(DataRecordDao.readMeasurementRecord(resultSet));
      }
      return records;
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'query measurement trend failed: %{public}s', JSON.stringify(err));
      return [];
    } finally {
      if (resultSet) {
        resultSet.close();
      }
    }
  }

  static async queryCalibrationCurveRecords(
    query: CalibrationCurveQuery
  ): Promise<DataPageQueryResult<CalibrationCurveRecord>> {
    const emptyResult = DataRecordDao.emptyPage<CalibrationCurveRecord>(query.page, query.pageSize);
    const store = DataRecordDao.store;
    if (!store) {
      return emptyResult;
    }

    const parts = DataRecordDao.buildCalibrationCurveQueryParts(query);
    const total = await DataRecordDao.queryCount(store, TABLE_CALIBRATION_CURVE, parts);
    const page = DataRecordDao.normalizePage(query.page, total, query.pageSize);
    const offset = (page - 1) * query.pageSize;
    const bindArgs = DataRecordDao.copyBindArgs(parts.bindArgs);
    bindArgs.push(query.pageSize);
    bindArgs.push(offset);

    const sql =
      'SELECT id, calibration_time, slope, intercept, zero_absorbance, span_absorbance, ' +
      'zero_concentration, span_concentration, range_value, ' +
      'range_label, is_current, source, operator_name, created_at, unique_key ' +
      `FROM ${TABLE_CALIBRATION_CURVE} ${parts.whereSql} ` +
      'ORDER BY calibration_time DESC, id DESC LIMIT ? OFFSET ?';

    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await store.querySql(sql, bindArgs);
      const records: CalibrationCurveRecord[] = [];
      while (resultSet.goToNextRow()) {
        records.push(DataRecordDao.readCalibrationCurveRecord(resultSet));
      }
      return {
        records: records,
        total: total,
        page: page,
        pageSize: query.pageSize,
        totalPages: DataRecordDao.totalPages(total, query.pageSize)
      };
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'query calibration curve records failed: %{public}s', JSON.stringify(err));
      return emptyResult;
    } finally {
      if (resultSet) {
        resultSet.close();
      }
    }
  }

  static async getCalibrationCurveRecord(id: number): Promise<CalibrationCurveRecord | null> {
    const store = DataRecordDao.store;
    if (!store) {
      return null;
    }

    const sql =
      'SELECT id, calibration_time, slope, intercept, zero_absorbance, span_absorbance, ' +
      'zero_concentration, span_concentration, range_value, ' +
      'range_label, is_current, source, operator_name, created_at, unique_key ' +
      `FROM ${TABLE_CALIBRATION_CURVE} WHERE id = ? LIMIT 1`;

    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await store.querySql(sql, [id]);
      if (resultSet.goToNextRow()) {
        return DataRecordDao.readCalibrationCurveRecord(resultSet);
      }
      return null;
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'get calibration curve record failed: %{public}s', JSON.stringify(err));
      return null;
    } finally {
      if (resultSet) {
        resultSet.close();
      }
    }
  }

  static async markCurrentCalibrationCurve(id: number): Promise<boolean> {
    const store = DataRecordDao.store;
    if (!store) {
      return false;
    }

    try {
      await store.executeSql(`UPDATE ${TABLE_CALIBRATION_CURVE} SET is_current = 0`);
      await store.executeSql(`UPDATE ${TABLE_CALIBRATION_CURVE} SET is_current = 1 WHERE id = ?`, [id]);
      return true;
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'mark current calibration curve failed: %{public}s', JSON.stringify(err));
      return false;
    }
  }

  static async markCurrentCalibrationCurveByUniqueKey(uniqueKey: string): Promise<boolean> {
    const store = DataRecordDao.store;
    if (!store) {
      return false;
    }

    try {
      await store.executeSql(`UPDATE ${TABLE_CALIBRATION_CURVE} SET is_current = 0`);
      await store.executeSql(`UPDATE ${TABLE_CALIBRATION_CURVE} SET is_current = 1 WHERE unique_key = ?`, [uniqueKey]);
      return true;
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'mark current calibration curve by unique key failed: %{public}s', JSON.stringify(err));
      return false;
    }
  }

  private static async initInternal(context: common.Context): Promise<boolean> {
    try {
      const store = await relationalStore.getRdbStore(context, STORE_CONFIG);
      await store.executeSql(CREATE_ALARM_TABLE_SQL);
      await store.executeSql(CREATE_OPERATION_LOG_TABLE_SQL);
      await store.executeSql(CREATE_MEASUREMENT_TABLE_SQL);
      await store.executeSql(CREATE_CALIBRATION_CURVE_TABLE_SQL);
      await DataRecordDao.ensureColumn(store, TABLE_CALIBRATION_CURVE, 'zero_concentration', 'REAL');
      await DataRecordDao.ensureColumn(store, TABLE_CALIBRATION_CURVE, 'span_concentration', 'REAL');
      await store.executeSql(CREATE_ALARM_UNIQUE_INDEX_SQL);
      await store.executeSql(CREATE_ALARM_QUERY_INDEX_SQL);
      await store.executeSql(CREATE_OPERATION_LOG_QUERY_INDEX_SQL);
      await store.executeSql(CREATE_MEASUREMENT_UNIQUE_INDEX_SQL);
      await store.executeSql(CREATE_MEASUREMENT_QUERY_INDEX_SQL);
      await store.executeSql(CREATE_CALIBRATION_CURVE_UNIQUE_INDEX_SQL);
      await store.executeSql(CREATE_CALIBRATION_CURVE_QUERY_INDEX_SQL);
      DataRecordDao.store = store;
      return true;
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'init database failed: %{public}s', JSON.stringify(err));
      DataRecordDao.store = null;
      return false;
    }
  }

  private static async ensureColumn(
    store: relationalStore.RdbStore,
    tableName: string,
    columnName: string,
    columnType: string
  ): Promise<void> {
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await store.querySql(`PRAGMA table_info(${tableName})`);
      while (resultSet.goToNextRow()) {
        if (DataRecordDao.readString(resultSet, 'name') === columnName) {
          return;
        }
      }
    } finally {
      if (resultSet) {
        resultSet.close();
      }
    }
    await store.executeSql(`ALTER TABLE ${tableName} ADD COLUMN ${columnName} ${columnType}`);
  }

  private static async hasAlarmRecord(uniqueKey: string): Promise<boolean> {
    const store = DataRecordDao.store;
    if (!store) {
      return false;
    }

    const sql = `SELECT id FROM ${TABLE_ALARM} WHERE unique_key = ? LIMIT 1`;
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await store.querySql(sql, [uniqueKey]);
      return resultSet.goToNextRow();
    } catch (err) {
      hilog.warn(DOMAIN, TAG, 'check alarm unique key failed: %{public}s', JSON.stringify(err));
      return false;
    } finally {
      if (resultSet) {
        resultSet.close();
      }
    }
  }

  private static async hasMeasurementRecord(uniqueKey: string): Promise<boolean> {
    const store = DataRecordDao.store;
    if (!store) {
      return false;
    }

    const sql = `SELECT id FROM ${TABLE_MEASUREMENT} WHERE unique_key = ? LIMIT 1`;
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await store.querySql(sql, [uniqueKey]);
      return resultSet.goToNextRow();
    } catch (err) {
      hilog.warn(DOMAIN, TAG, 'check measurement unique key failed: %{public}s', JSON.stringify(err));
      return false;
    } finally {
      if (resultSet) {
        resultSet.close();
      }
    }
  }

  private static async hasCalibrationCurveRecord(uniqueKey: string): Promise<boolean> {
    const store = DataRecordDao.store;
    if (!store) {
      return false;
    }

    const sql = `SELECT id FROM ${TABLE_CALIBRATION_CURVE} WHERE unique_key = ? LIMIT 1`;
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await store.querySql(sql, [uniqueKey]);
      return resultSet.goToNextRow();
    } catch (err) {
      hilog.warn(DOMAIN, TAG, 'check calibration curve unique key failed: %{public}s', JSON.stringify(err));
      return false;
    } finally {
      if (resultSet) {
        resultSet.close();
      }
    }
  }

  private static buildAlarmQueryParts(query: AlarmRecordQuery): QueryParts {
    const clauses: string[] = [];
    const bindArgs: Array<relationalStore.ValueType> = [];
    if (query.startTime > 0) {
      clauses.push('alarm_time >= ?');
      bindArgs.push(query.startTime);
    }
    if (query.endTime > 0) {
      clauses.push('alarm_time <= ?');
      bindArgs.push(query.endTime);
    }
    if (query.alarmType.length > 0 && query.alarmType !== ALL_FILTER_OPTION) {
      clauses.push('alarm_type = ?');
      bindArgs.push(query.alarmType);
    }
    return {
      whereSql: clauses.length > 0 ? `WHERE ${clauses.join(' AND ')}` : '',
      bindArgs: bindArgs
    };
  }

  private static buildOperationLogQueryParts(query: OperationLogQuery): QueryParts {
    const clauses: string[] = [];
    const bindArgs: Array<relationalStore.ValueType> = [];
    if (query.startTime > 0) {
      clauses.push('log_time >= ?');
      bindArgs.push(query.startTime);
    }
    if (query.endTime > 0) {
      clauses.push('log_time <= ?');
      bindArgs.push(query.endTime);
    }
    if (query.logType.length > 0 && query.logType !== ALL_FILTER_OPTION) {
      clauses.push('log_type = ?');
      bindArgs.push(query.logType);
    }
    return {
      whereSql: clauses.length > 0 ? `WHERE ${clauses.join(' AND ')}` : '',
      bindArgs: bindArgs
    };
  }

  private static buildMeasurementQueryParts(query: MeasurementRecordQuery): QueryParts {
    const clauses: string[] = [];
    const bindArgs: Array<relationalStore.ValueType> = [];
    if (query.startTime > 0) {
      clauses.push('measurement_time >= ?');
      bindArgs.push(query.startTime);
    }
    if (query.endTime > 0) {
      clauses.push('measurement_time <= ?');
      bindArgs.push(query.endTime);
    }
    if (query.flagLabel.length > 0 && query.flagLabel !== ALL_FILTER_OPTION) {
      clauses.push('flag_label = ?');
      bindArgs.push(query.flagLabel);
    }
    if (query.resultTypeLabel.length > 0 && query.resultTypeLabel !== ALL_FILTER_OPTION) {
      clauses.push('result_type_label = ?');
      bindArgs.push(query.resultTypeLabel);
    }
    return {
      whereSql: clauses.length > 0 ? `WHERE ${clauses.join(' AND ')}` : '',
      bindArgs: bindArgs
    };
  }

  private static buildMeasurementTrendQueryParts(query: MeasurementTrendQuery): QueryParts {
    const clauses: string[] = [];
    const bindArgs: Array<relationalStore.ValueType> = [];
    if (query.startTime > 0) {
      clauses.push('measurement_time >= ?');
      bindArgs.push(query.startTime);
    }
    if (query.endTime > 0) {
      clauses.push('measurement_time <= ?');
      bindArgs.push(query.endTime);
    }

    const placeholders: string[] = [];
    query.resultTypeLabels.forEach((label: string) => {
      if (label.length > 0 && label !== ALL_FILTER_OPTION) {
        placeholders.push('?');
        bindArgs.push(label);
      }
    });
    if (placeholders.length > 0) {
      clauses.push(`result_type_label IN (${placeholders.join(', ')})`);
    }

    return {
      whereSql: clauses.length > 0 ? `WHERE ${clauses.join(' AND ')}` : '',
      bindArgs: bindArgs
    };
  }

  private static buildCalibrationCurveQueryParts(query: CalibrationCurveQuery): QueryParts {
    const clauses: string[] = [];
    const bindArgs: Array<relationalStore.ValueType> = [];
    if (query.startTime > 0) {
      clauses.push('calibration_time >= ?');
      bindArgs.push(query.startTime);
    }
    if (query.endTime > 0) {
      clauses.push('calibration_time <= ?');
      bindArgs.push(query.endTime);
    }
    return {
      whereSql: clauses.length > 0 ? `WHERE ${clauses.join(' AND ')}` : '',
      bindArgs: bindArgs
    };
  }

  private static async queryCount(
    store: relationalStore.RdbStore,
    tableName: string,
    parts: QueryParts
  ): Promise<number> {
    const sql = `SELECT COUNT(*) AS total_count FROM ${tableName} ${parts.whereSql}`;
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await store.querySql(sql, parts.bindArgs);
      if (resultSet.goToNextRow()) {
        return resultSet.getLong(resultSet.getColumnIndex('total_count'));
      }
      return 0;
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'query count failed: %{public}s', JSON.stringify(err));
      return 0;
    } finally {
      if (resultSet) {
        resultSet.close();
      }
    }
  }

  private static readAlarmRecord(resultSet: relationalStore.ResultSet): AlarmRecord {
    return {
      id: DataRecordDao.readLong(resultSet, 'id'),
      alarmTime: DataRecordDao.readLong(resultSet, 'alarm_time'),
      alarmCode: DataRecordDao.readLong(resultSet, 'alarm_code'),
      alarmType: DataRecordDao.readString(resultSet, 'alarm_type'),
      category: DataRecordDao.readString(resultSet, 'category'),
      content: DataRecordDao.readString(resultSet, 'content'),
      source: DataRecordDao.readString(resultSet, 'source'),
      status: DataRecordDao.readString(resultSet, 'status'),
      createdAt: DataRecordDao.readLong(resultSet, 'created_at'),
      uniqueKey: DataRecordDao.readString(resultSet, 'unique_key')
    };
  }

  private static readOperationLogRecord(resultSet: relationalStore.ResultSet): OperationLogRecord {
    return {
      id: DataRecordDao.readLong(resultSet, 'id'),
      logTime: DataRecordDao.readLong(resultSet, 'log_time'),
      logType: DataRecordDao.readString(resultSet, 'log_type'),
      action: DataRecordDao.readString(resultSet, 'action'),
      content: DataRecordDao.readString(resultSet, 'content'),
      result: DataRecordDao.readString(resultSet, 'log_result'),
      source: DataRecordDao.readString(resultSet, 'source'),
      operatorName: DataRecordDao.readString(resultSet, 'operator_name'),
      detail: DataRecordDao.readString(resultSet, 'detail'),
      createdAt: DataRecordDao.readLong(resultSet, 'created_at')
    };
  }

  private static readMeasurementRecord(resultSet: relationalStore.ResultSet): MeasurementRecord {
    return {
      id: DataRecordDao.readLong(resultSet, 'id'),
      measurementTime: DataRecordDao.readLong(resultSet, 'measurement_time'),
      parameterCode: DataRecordDao.readLong(resultSet, 'parameter_code'),
      parameterName: DataRecordDao.readString(resultSet, 'parameter_name'),
      resultValue: DataRecordDao.readDouble(resultSet, 'result_value'),
      resultUnit: DataRecordDao.readString(resultSet, 'result_unit'),
      absorbance: DataRecordDao.readNullableDouble(resultSet, 'absorbance'),
      flagCode: DataRecordDao.readString(resultSet, 'flag_code'),
      flagLabel: DataRecordDao.readString(resultSet, 'flag_label'),
      resultTypeCode: DataRecordDao.readString(resultSet, 'result_type_code'),
      resultTypeLabel: DataRecordDao.readString(resultSet, 'result_type_label'),
      rangeValue: DataRecordDao.readNullableDouble(resultSet, 'range_value'),
      rangeLabel: DataRecordDao.readString(resultSet, 'range_label'),
      createdAt: DataRecordDao.readLong(resultSet, 'created_at'),
      uniqueKey: DataRecordDao.readString(resultSet, 'unique_key')
    };
  }

  private static readCalibrationCurveRecord(resultSet: relationalStore.ResultSet): CalibrationCurveRecord {
    return {
      id: DataRecordDao.readLong(resultSet, 'id'),
      calibrationTime: DataRecordDao.readLong(resultSet, 'calibration_time'),
      slope: DataRecordDao.readDouble(resultSet, 'slope'),
      intercept: DataRecordDao.readDouble(resultSet, 'intercept'),
      zeroAbsorbance: DataRecordDao.readNullableDouble(resultSet, 'zero_absorbance'),
      spanAbsorbance: DataRecordDao.readNullableDouble(resultSet, 'span_absorbance'),
      zeroConcentration: DataRecordDao.readNullableDouble(resultSet, 'zero_concentration'),
      spanConcentration: DataRecordDao.readNullableDouble(resultSet, 'span_concentration'),
      rangeValue: DataRecordDao.readNullableDouble(resultSet, 'range_value'),
      rangeLabel: DataRecordDao.readString(resultSet, 'range_label'),
      isCurrent: DataRecordDao.readLong(resultSet, 'is_current') === 1,
      source: DataRecordDao.readString(resultSet, 'source'),
      operatorName: DataRecordDao.readString(resultSet, 'operator_name'),
      createdAt: DataRecordDao.readLong(resultSet, 'created_at'),
      uniqueKey: DataRecordDao.readString(resultSet, 'unique_key')
    };
  }

  private static readLong(resultSet: relationalStore.ResultSet, columnName: string): number {
    const index = resultSet.getColumnIndex(columnName);
    if (index < 0 || resultSet.isColumnNull(index)) {
      return 0;
    }
    return resultSet.getLong(index);
  }

  private static readDouble(resultSet: relationalStore.ResultSet, columnName: string): number {
    const index = resultSet.getColumnIndex(columnName);
    if (index < 0 || resultSet.isColumnNull(index)) {
      return 0;
    }
    return resultSet.getDouble(index);
  }

  private static readNullableDouble(resultSet: relationalStore.ResultSet, columnName: string): number | null {
    const index = resultSet.getColumnIndex(columnName);
    if (index < 0 || resultSet.isColumnNull(index)) {
      return null;
    }
    return resultSet.getDouble(index);
  }

  private static readString(resultSet: relationalStore.ResultSet, columnName: string): string {
    const index = resultSet.getColumnIndex(columnName);
    if (index < 0 || resultSet.isColumnNull(index)) {
      return '';
    }
    return resultSet.getString(index);
  }

  private static normalizePage(page: number, total: number, pageSize: number): number {
    const totalPages = DataRecordDao.totalPages(total, pageSize);
    const safePage = page > 0 ? page : 1;
    return Math.min(totalPages, safePage);
  }

  private static totalPages(total: number, pageSize: number): number {
    const safePageSize = pageSize > 0 ? pageSize : 1;
    const pages = Math.ceil(total / safePageSize);
    return pages > 0 ? pages : 1;
  }

  private static emptyPage<T>(page: number, pageSize: number): DataPageQueryResult<T> {
    return {
      records: [],
      total: 0,
      page: page > 0 ? page : 1,
      pageSize: pageSize > 0 ? pageSize : 1,
      totalPages: 1
    };
  }

  private static copyBindArgs(args: Array<relationalStore.ValueType>): Array<relationalStore.ValueType> {
    const copied: Array<relationalStore.ValueType> = [];
    args.forEach((item: relationalStore.ValueType) => {
      copied.push(item);
    });
    return copied;
  }
}
