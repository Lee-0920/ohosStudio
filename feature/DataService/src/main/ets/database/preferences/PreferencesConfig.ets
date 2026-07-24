// database/preferences/PreferencesConfig.ets
/**
 * 偏好型数据库存储Key常量定义
 * 键名与LS脚本文件名保持一致
 */

export const INSTRUMENT_PREFERENCES = 'instrument_config';
export const MEASURE_STATUS_PREFERENCES = 'measure_status_config';

export interface PreferenceKeys {
  INSTRUMENT_INFO: string;
  MAIN_BOARD_INFO: string;
  HARDWARE_CONFIG: string;
  MEASURE_PARAM_CONFIG: string;
  SCHEDULER_CONFIG: string;
  INTERCONNECTION_CONFIG: string;
  SYSTEM_CONFIG: string;
  AUTHORIZATION_CONFIG: string;
  REMAIN_CONFIG: string;
  REMAIN_STATUS: string;
  CONSUMABLE_CONFIG: string;
  MEASURE_RUNNING: string;
  INSTRUMENT_TYPE: string;
  MANUFACTURE_TYPE: string;
  APP_LANGUAGE: string;
  PRODUCER_STATUS: string;
}

export const Keys: PreferenceKeys = {
  INSTRUMENT_INFO: 'InstrumentInfomation',
  MAIN_BOARD_INFO: 'MainBoardInfomation',
  HARDWARE_CONFIG: 'HardwareConfig',
  MEASURE_PARAM_CONFIG: 'MeasureParamConfig',
  SCHEDULER_CONFIG: 'SchedulerConfig',
  INTERCONNECTION_CONFIG: 'InterconnectionConfig',
  SYSTEM_CONFIG: 'SystemConfig',
  AUTHORIZATION_CONFIG: 'Authorization',
  REMAIN_CONFIG: 'RemainConfig',
  REMAIN_STATUS: 'RemainStatus',
  CONSUMABLE_CONFIG: 'ConsumableConfig',
  MEASURE_RUNNING: 'MeasureRunning',
  INSTRUMENT_TYPE: 'instrument_type',
  MANUFACTURE_TYPE: 'manufacture_type',
  APP_LANGUAGE: 'app_language',
  PRODUCER_STATUS: 'producer_status',
};