import relationalStore from '@ohos.data.relationalStore';

// 数据库配置
export const STORE_CONFIG: relationalStore.StoreConfig = {
  name: 'ResultData.db',
  securityLevel: relationalStore.SecurityLevel.S1
};

// 表名常量
export const TABLE_MEASURE = 'measure_record';
export const TABLE_CALIBRATE = 'calibrate_record';

// ==================== 建表SQL ====================

export const SQL_CREATE_TABLE_MEASURE = `
  CREATE TABLE IF NOT EXISTS ${TABLE_MEASURE} (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    dateTime INTEGER NOT NULL,
    consistency REAL DEFAULT 0,
    absorbance REAL DEFAULT 0,
    mode INTEGER DEFAULT 0,
    resultType INTEGER DEFAULT 0,
    initReferenceAD INTEGER DEFAULT 0,
    initMeasureAD INTEGER DEFAULT 0,
    finalReferenceAD INTEGER DEFAULT 0,
    finalMeasureAD INTEGER DEFAULT 0,
    initThermostatTemp REAL DEFAULT 0,
    initEnvironmentTemp REAL DEFAULT 0,
    finalThermostatTemp REAL DEFAULT 0,
    finalEnvironmentTemp REAL DEFAULT 0,
    initConsistency REAL DEFAULT 0,
    measureTime INTEGER DEFAULT 0,
    addstandardConsistency REAL DEFAULT 0,
    measureRange REAL DEFAULT 0,
    version TEXT DEFAULT '1.0.0.2'
  )
`;

export const SQL_CREATE_TABLE_CALIBRATE = `
  CREATE TABLE IF NOT EXISTS ${TABLE_CALIBRATE} (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    dateTime INTEGER NOT NULL,
    curveK REAL DEFAULT 0,
    curveB REAL DEFAULT 0,
    R2 REAL DEFAULT 0,
    point0_initAbsorbance REAL DEFAULT 0,
    point0_absorbance REAL DEFAULT 0,
    point0_consistency REAL DEFAULT 0,
    initReferenceAD0 INTEGER DEFAULT 0,
    initMeasureAD0 INTEGER DEFAULT 0,
    finalReferenceAD0 INTEGER DEFAULT 0,
    finalMeasureAD0 INTEGER DEFAULT 0,
    point0_initThermostatTemp REAL DEFAULT 0,
    point0_initEnvironmentTemp REAL DEFAULT 0,
    point0_finalThermostatTemp REAL DEFAULT 0,
    point0_finalEnvironmentTemp REAL DEFAULT 0,
    point1_initAbsorbance REAL DEFAULT 0,
    point1_absorbance REAL DEFAULT 0,
    point1_consistency REAL DEFAULT 0,
    initReferenceAD1 INTEGER DEFAULT 0,
    initMeasureAD1 INTEGER DEFAULT 0,
    finalReferenceAD1 INTEGER DEFAULT 0,
    finalMeasureAD1 INTEGER DEFAULT 0,
    point1_initThermostatTemp REAL DEFAULT 0,
    point1_initEnvironmentTemp REAL DEFAULT 0,
    point1_finalThermostatTemp REAL DEFAULT 0,
    point1_finalEnvironmentTemp REAL DEFAULT 0,
    calibrateTime INTEGER DEFAULT 0,
    measureRange REAL DEFAULT 0,
    rangeIndex INTEGER DEFAULT 0,
    version TEXT DEFAULT '1.0.0.2'
  )
`;

// 新增字段的SQL（用于数据库升级）
export const SQL_ADD_COLUMN_RANGE_INDEX = `
  ALTER TABLE ${TABLE_CALIBRATE} ADD COLUMN rangeIndex INTEGER DEFAULT 0
`;

// ==================== 索引SQL ====================

export const SQL_CREATE_INDEX_MEASURE_TIME = `
  CREATE INDEX IF NOT EXISTS idx_measure_time ON ${TABLE_MEASURE}(dateTime DESC)
`;
export const SQL_CREATE_INDEX_MEASURE_TYPE = `
  CREATE INDEX IF NOT EXISTS idx_measure_type ON ${TABLE_MEASURE}(resultType)
`;
export const SQL_CREATE_INDEX_MEASURE_TIME_TYPE = `
  CREATE INDEX IF NOT EXISTS idx_measure_time_type ON ${TABLE_MEASURE}(resultType, dateTime DESC)
`;
export const SQL_CREATE_INDEX_MEASURE_MODE = `
  CREATE INDEX IF NOT EXISTS idx_measure_mode ON ${TABLE_MEASURE}(mode)
`;
export const SQL_CREATE_INDEX_CALIBRATE_TIME = `
  CREATE INDEX IF NOT EXISTS idx_calibrate_time ON ${TABLE_CALIBRATE}(dateTime DESC)
`;
export const SQL_CREATE_INDEX_CALIBRATE_R2 = `
  CREATE INDEX IF NOT EXISTS idx_calibrate_r2 ON ${TABLE_CALIBRATE}(R2 DESC)
`;
export const SQL_CREATE_INDEX_CALIBRATE_VERSION = `
  CREATE INDEX IF NOT EXISTS idx_calibrate_version ON ${TABLE_CALIBRATE}(version)
`;

// 批量创建用的数组
export const ALL_TABLE_SQL_S: string[] = [
  SQL_CREATE_TABLE_MEASURE,
  SQL_CREATE_TABLE_CALIBRATE,
];

export const ALL_INDEX_SQL_S: string[] = [
  SQL_CREATE_INDEX_MEASURE_TIME,
  SQL_CREATE_INDEX_MEASURE_TYPE,
  SQL_CREATE_INDEX_MEASURE_TIME_TYPE,
  SQL_CREATE_INDEX_MEASURE_MODE,
  SQL_CREATE_INDEX_CALIBRATE_TIME,
  SQL_CREATE_INDEX_CALIBRATE_R2,
  SQL_CREATE_INDEX_CALIBRATE_VERSION
];