// 业务层（主要对外接口）
export { ResultManager } from './src/main/ets/repositories';
export type { IResultNotifiable, ResultManagerConfig } from './src/main/ets/repositories';

// 数据模型（如需要直接访问）
export {
  MeasureRecord,
  CalibrateRecord,
  MeasureQueryCondition,
  CalibrateQueryCondition,
  MeasureType,
  ResultMode,
  CalibrateType
} from './src/main/ets/database/relational/models/RelationalModels';


// 业务层（主要对外接口）
export { SettingsManager, MeasureStatusManager } from './src/main/ets/repositories';

// 底层存储管理器及配置常量
export { PreferencesUtil } from './src/main/ets/database/preferences/PreferencesUtil';
export { Keys } from './src/main/ets/database/preferences/PreferencesConfig';

// 数据模型（所有类型）
export * from './src/main/ets/database/preferences/models/PreferenceModels';