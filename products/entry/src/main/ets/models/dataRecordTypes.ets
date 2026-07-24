export const ALL_FILTER_OPTION: string = '全部';

export const ALARM_TYPE_SYSTEM_EXCEPTION: string = '系统异常';
export const ALARM_TYPE_COMMUNICATION_EXCEPTION: string = '通信异常';
export const ALARM_TYPE_INSTRUMENT_FAULT: string = '仪器故障';
export const ALARM_TYPE_MAINTENANCE_TIP: string = '维护提示';
export const ALARM_TYPE_UPGRADE_EXCEPTION: string = '升级异常';
export const ALARM_TYPE_MEASUREMENT_EXCEPTION: string = '测量异常';
export const ALARM_TYPE_REAGENT_EXCEPTION: string = '试剂异常';
export const ALARM_TYPE_CALIBRATION_EXCEPTION: string = '校准异常';

export const OPERATION_LOG_TYPE_LOGIN: string = '用户登录';
export const OPERATION_LOG_TYPE_MAINTENANCE: string = '维护操作';
export const OPERATION_LOG_TYPE_PARAMETER: string = '参数设置';
export const OPERATION_LOG_TYPE_INSTRUMENT_FAULT: string = '仪器故障';
export const OPERATION_LOG_TYPE_SYSTEM: string = '系统操作';
export const OPERATION_LOG_TYPE_COMMUNICATION: string = '通信操作';
export const OPERATION_LOG_TYPE_RUNTIME: string = '仪器运行';

export const LOG_RESULT_SUCCESS: string = 'success';
export const LOG_RESULT_FAILED: string = 'failed';
export const LOG_RESULT_INFO: string = 'info';

export const MEASUREMENT_RESULT_TYPE_ZERO_CALIBRATION: string = '零点校准液';
export const MEASUREMENT_RESULT_TYPE_WATER_SAMPLE: string = '水样';
export const MEASUREMENT_RESULT_TYPE_RANGE_CALIBRATION: string = '量程校准液';
export const MEASUREMENT_RESULT_TYPE_SPAN_CHECK: string = '跨度(标样)核查';
export const MEASUREMENT_RESULT_TYPE_QUALITY_CONTROL: string = '质控样';

export interface DataPageQueryResult<T> {
  records: T[];
  total: number;
  page: number;
  pageSize: number;
  totalPages: number;
}

export interface AlarmRecord {
  id: number;
  alarmTime: number;
  alarmCode: number;
  alarmType: string;
  category: string;
  content: string;
  source: string;
  status: string;
  createdAt: number;
  uniqueKey: string;
}

export interface AlarmRecordInput {
  alarmTime: number;
  alarmCode: number;
  alarmType: string;
  category: string;
  content: string;
  source: string;
  status: string;
  uniqueKey: string;
}

export interface AlarmRecordQuery {
  startTime: number;
  endTime: number;
  alarmType: string;
  page: number;
  pageSize: number;
}

export interface OperationLogRecord {
  id: number;
  logTime: number;
  logType: string;
  action: string;
  content: string;
  result: string;
  source: string;
  operatorName: string;
  detail: string;
  createdAt: number;
}

export interface OperationLogInput {
  logTime: number;
  logType: string;
  action: string;
  content: string;
  result: string;
  source: string;
  operatorName: string;
  detail: string;
}

export interface OperationLogQuery {
  startTime: number;
  endTime: number;
  logType: string;
  page: number;
  pageSize: number;
}

export interface OperationLogRequest {
  logType: string;
  action: string;
  content: string;
  source: string;
  operatorName?: string;
  detail?: string;
}

export interface MeasurementRecord {
  id: number;
  measurementTime: number;
  parameterCode: number;
  parameterName: string;
  resultValue: number;
  resultUnit: string;
  absorbance: number | null;
  flagCode: string;
  flagLabel: string;
  resultTypeCode: string;
  resultTypeLabel: string;
  rangeValue: number | null;
  rangeLabel: string;
  createdAt: number;
  uniqueKey: string;
}

export interface MeasurementRecordInput {
  measurementTime: number;
  parameterCode: number;
  parameterName: string;
  resultValue: number;
  resultUnit: string;
  absorbance: number | null;
  flagCode: string;
  flagLabel: string;
  resultTypeCode: string;
  resultTypeLabel: string;
  rangeValue: number | null;
  rangeLabel: string;
  uniqueKey: string;
}

export interface MeasurementRecordQuery {
  startTime: number;
  endTime: number;
  flagLabel: string;
  resultTypeLabel: string;
  page: number;
  pageSize: number;
}

export interface MeasurementTrendQuery {
  startTime: number;
  endTime: number;
  resultTypeLabels: string[];
}

export interface CalibrationCurveRecord {
  id: number;
  calibrationTime: number;
  slope: number;
  intercept: number;
  zeroAbsorbance: number | null;
  spanAbsorbance: number | null;
  zeroConcentration: number | null;
  spanConcentration: number | null;
  rangeValue: number | null;
  rangeLabel: string;
  isCurrent: boolean;
  source: string;
  operatorName: string;
  createdAt: number;
  uniqueKey: string;
}

export interface CalibrationCurveInput {
  calibrationTime: number;
  slope: number;
  intercept: number;
  zeroAbsorbance: number | null;
  spanAbsorbance: number | null;
  zeroConcentration: number | null;
  spanConcentration: number | null;
  rangeValue: number | null;
  rangeLabel: string;
  isCurrent: boolean;
  source: string;
  operatorName: string;
  uniqueKey: string;
}

export interface CurrentCalibrationCurveSummary {
  slope: number;
  intercept: number;
  zeroConcentration: number | null;
  spanConcentration: number | null;
}

export interface CalibrationCurveQuery {
  startTime: number;
  endTime: number;
  page: number;
  pageSize: number;
}
