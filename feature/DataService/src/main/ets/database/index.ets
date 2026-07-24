// ==================== 关系型数据库 ====================
// 导出管理器（单例）
export { RdbManager } from './relational/RdbManager';
export { PreferencesUtil } from './preferences/PreferencesUtil'

// 导出数据模型（供业务层使用）
export {
  MeasureRecord,
  CalibrateRecord,
  MeasureType,
  ResultMode,
  CalibrateType,
  FieldType,
  MeasureQueryCondition,
  CalibrateQueryCondition,
} from './relational/models/RelationalModels';

export * from './preferences/models/PreferenceModels';

// 导出配置常量（如需要直接使用表名等）
export {
  TABLE_MEASURE,
  TABLE_CALIBRATE,
} from './relational/RdbConfig';

export {
  Keys,
  MEASURE_STATUS_PREFERENCES,
  INSTRUMENT_PREFERENCES,
} from './preferences/PreferencesConfig';