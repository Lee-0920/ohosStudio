import {
  PhotoTekCodeDescription,
  PhotoTekInputRegisterDefinition,
  PhotoTekMeasurementParameterInfo
} from './PhotoTekTypes';

export interface PhotoTekInputRegisterKeyMap {
  MEASUREMENT_RESULT: string;
  CALIBRATION_SOLUTION_RESULT: string;
  MEASUREMENT_PARAMETER: string;
  MEASUREMENT_RESULT_TYPE: string;
  MEASUREMENT_DURATION: string;
  MEASUREMENT_TIME: string;
  CALIBRATION_SOLUTION_TIME: string;
  CALIBRATION_TIME: string;
  SYSTEM_STATUS: string;
  CURRENT_ACTION: string;
  CURRENT_TEMPERATURE: string;
  ALARM_TIME: string;
  ALARM_CODE: string;
  RANGE_TABLE: string;
  PRODUCT_NAME: string;
  PRODUCT_MODEL: string;
  MANUFACTURER: string;
  SERIAL_NUMBER: string;
  LIQUID_BOARD_FIRMWARE: string;
  TEMPERATURE_BOARD_FIRMWARE: string;
  SIGNAL_BOARD_FIRMWARE: string;
  MAIN_BOARD_FIRMWARE: string;
  DRIVER_BOARD_FIRMWARE: string;
  REACTION_BOARD_FIRMWARE: string;
  SPAN_CHECK_RESULT: string;
  SPAN_CHECK_TIME: string;
  WATER_SAMPLE_ABSORBANCE: string;
  WATER_SAMPLE_DATA_FLAG: string;
  CALIBRATION_SOLUTION_ABSORBANCE: string;
  CALIBRATION_SOLUTION_DATA_FLAG: string;
  CHECK_SOLUTION_ABSORBANCE: string;
  CHECK_SOLUTION_DATA_FLAG: string;
  CALIBRATION_ZERO_CONCENTRATION: string;
  CALIBRATION_ZERO_ABSORBANCE: string;
  ZERO_DRIFT: string;
  CALIBRATION_SPAN_CONCENTRATION: string;
  CALIBRATION_SPAN_ABSORBANCE: string;
  SPAN_DRIFT: string;
  COMPOSITE_MEASUREMENT_RESULT: string;
  COMPOSITE_RESULT_TIME: string;
  COMPOSITE_DATA_FLAG: string;
  TOC_FACTOR_CONSTANT: string;
  TOC_FACTOR_RATIO: string;
  TOC_FLOW_CONTROL: string;
  TOC_MEASUREMENT_RESULT: string;
}

export interface PhotoTekInputRegisterMap {
  MEASUREMENT_RESULT: PhotoTekInputRegisterDefinition;
  CALIBRATION_SOLUTION_RESULT: PhotoTekInputRegisterDefinition;
  MEASUREMENT_PARAMETER: PhotoTekInputRegisterDefinition;
  MEASUREMENT_RESULT_TYPE: PhotoTekInputRegisterDefinition;
  MEASUREMENT_DURATION: PhotoTekInputRegisterDefinition;
  MEASUREMENT_TIME: PhotoTekInputRegisterDefinition;
  CALIBRATION_SOLUTION_TIME: PhotoTekInputRegisterDefinition;
  CALIBRATION_TIME: PhotoTekInputRegisterDefinition;
  SYSTEM_STATUS: PhotoTekInputRegisterDefinition;
  CURRENT_ACTION: PhotoTekInputRegisterDefinition;
  CURRENT_TEMPERATURE: PhotoTekInputRegisterDefinition;
  ALARM_TIME: PhotoTekInputRegisterDefinition;
  ALARM_CODE: PhotoTekInputRegisterDefinition;
  RANGE_TABLE: PhotoTekInputRegisterDefinition;
  PRODUCT_NAME: PhotoTekInputRegisterDefinition;
  PRODUCT_MODEL: PhotoTekInputRegisterDefinition;
  MANUFACTURER: PhotoTekInputRegisterDefinition;
  SERIAL_NUMBER: PhotoTekInputRegisterDefinition;
  LIQUID_BOARD_FIRMWARE: PhotoTekInputRegisterDefinition;
  TEMPERATURE_BOARD_FIRMWARE: PhotoTekInputRegisterDefinition;
  SIGNAL_BOARD_FIRMWARE: PhotoTekInputRegisterDefinition;
  MAIN_BOARD_FIRMWARE: PhotoTekInputRegisterDefinition;
  DRIVER_BOARD_FIRMWARE: PhotoTekInputRegisterDefinition;
  REACTION_BOARD_FIRMWARE: PhotoTekInputRegisterDefinition;
  SPAN_CHECK_RESULT: PhotoTekInputRegisterDefinition;
  SPAN_CHECK_TIME: PhotoTekInputRegisterDefinition;
  WATER_SAMPLE_ABSORBANCE: PhotoTekInputRegisterDefinition;
  WATER_SAMPLE_DATA_FLAG: PhotoTekInputRegisterDefinition;
  CALIBRATION_SOLUTION_ABSORBANCE: PhotoTekInputRegisterDefinition;
  CALIBRATION_SOLUTION_DATA_FLAG: PhotoTekInputRegisterDefinition;
  CHECK_SOLUTION_ABSORBANCE: PhotoTekInputRegisterDefinition;
  CHECK_SOLUTION_DATA_FLAG: PhotoTekInputRegisterDefinition;
  CALIBRATION_ZERO_CONCENTRATION: PhotoTekInputRegisterDefinition;
  CALIBRATION_ZERO_ABSORBANCE: PhotoTekInputRegisterDefinition;
  ZERO_DRIFT: PhotoTekInputRegisterDefinition;
  CALIBRATION_SPAN_CONCENTRATION: PhotoTekInputRegisterDefinition;
  CALIBRATION_SPAN_ABSORBANCE: PhotoTekInputRegisterDefinition;
  SPAN_DRIFT: PhotoTekInputRegisterDefinition;
  COMPOSITE_MEASUREMENT_RESULT: PhotoTekInputRegisterDefinition;
  COMPOSITE_RESULT_TIME: PhotoTekInputRegisterDefinition;
  COMPOSITE_DATA_FLAG: PhotoTekInputRegisterDefinition;
  TOC_FACTOR_CONSTANT: PhotoTekInputRegisterDefinition;
  TOC_FACTOR_RATIO: PhotoTekInputRegisterDefinition;
  TOC_FLOW_CONTROL: PhotoTekInputRegisterDefinition;
  TOC_MEASUREMENT_RESULT: PhotoTekInputRegisterDefinition;
}

export const PhotoTekInputRegisterKeys: PhotoTekInputRegisterKeyMap = {
  MEASUREMENT_RESULT: 'measurementResult',
  CALIBRATION_SOLUTION_RESULT: 'calibrationSolutionResult',
  MEASUREMENT_PARAMETER: 'measurementParameter',
  MEASUREMENT_RESULT_TYPE: 'measurementResultType',
  MEASUREMENT_DURATION: 'measurementDuration',
  MEASUREMENT_TIME: 'measurementTime',
  CALIBRATION_SOLUTION_TIME: 'calibrationSolutionTime',
  CALIBRATION_TIME: 'calibrationTime',
  SYSTEM_STATUS: 'systemStatus',
  CURRENT_ACTION: 'currentAction',
  CURRENT_TEMPERATURE: 'currentTemperature',
  ALARM_TIME: 'alarmTime',
  ALARM_CODE: 'alarmCode',
  RANGE_TABLE: 'rangeTable',
  PRODUCT_NAME: 'productName',
  PRODUCT_MODEL: 'productModel',
  MANUFACTURER: 'manufacturer',
  SERIAL_NUMBER: 'serialNumber',
  LIQUID_BOARD_FIRMWARE: 'liquidBoardFirmware',
  TEMPERATURE_BOARD_FIRMWARE: 'temperatureBoardFirmware',
  SIGNAL_BOARD_FIRMWARE: 'signalBoardFirmware',
  MAIN_BOARD_FIRMWARE: 'mainBoardFirmware',
  DRIVER_BOARD_FIRMWARE: 'driverBoardFirmware',
  REACTION_BOARD_FIRMWARE: 'reactionBoardFirmware',
  SPAN_CHECK_RESULT: 'spanCheckResult',
  SPAN_CHECK_TIME: 'spanCheckTime',
  WATER_SAMPLE_ABSORBANCE: 'waterSampleAbsorbance',
  WATER_SAMPLE_DATA_FLAG: 'waterSampleDataFlag',
  CALIBRATION_SOLUTION_ABSORBANCE: 'calibrationSolutionAbsorbance',
  CALIBRATION_SOLUTION_DATA_FLAG: 'calibrationSolutionDataFlag',
  CHECK_SOLUTION_ABSORBANCE: 'checkSolutionAbsorbance',
  CHECK_SOLUTION_DATA_FLAG: 'checkSolutionDataFlag',
  CALIBRATION_ZERO_CONCENTRATION: 'calibrationZeroConcentration',
  CALIBRATION_ZERO_ABSORBANCE: 'calibrationZeroAbsorbance',
  ZERO_DRIFT: 'zeroDrift',
  CALIBRATION_SPAN_CONCENTRATION: 'calibrationSpanConcentration',
  CALIBRATION_SPAN_ABSORBANCE: 'calibrationSpanAbsorbance',
  SPAN_DRIFT: 'spanDrift',
  COMPOSITE_MEASUREMENT_RESULT: 'compositeMeasurementResult',
  COMPOSITE_RESULT_TIME: 'compositeResultTime',
  COMPOSITE_DATA_FLAG: 'compositeDataFlag',
  TOC_FACTOR_CONSTANT: 'tocFactorConstant',
  TOC_FACTOR_RATIO: 'tocFactorRatio',
  TOC_FLOW_CONTROL: 'tocFlowControl',
  TOC_MEASUREMENT_RESULT: 'tocMeasurementResult'
};

export const PhotoTekInputRegisters: PhotoTekInputRegisterMap = {
  MEASUREMENT_RESULT: {
    key: PhotoTekInputRegisterKeys.MEASUREMENT_RESULT,
    address: 0,
    name: '测量结果',
    dataType: '浮点型',
    registerCount: 2,
    unit: 'mg/L',
    valueType: 'floatCdab',
    description: '上一次测量的结果。'
  },
  CALIBRATION_SOLUTION_RESULT: {
    key: PhotoTekInputRegisterKeys.CALIBRATION_SOLUTION_RESULT,
    address: 2,
    name: '测量校准液结果',
    dataType: '浮点型',
    registerCount: 2,
    unit: 'mg/L',
    valueType: 'floatCdab',
    description: '上一次测量校准液的结果。'
  },
  MEASUREMENT_PARAMETER: {
    key: PhotoTekInputRegisterKeys.MEASUREMENT_PARAMETER,
    address: 4,
    name: '测量参数',
    dataType: '无符号整型',
    registerCount: 1,
    unit: '',
    valueType: 'uint16',
    codeTable: 'measurementParameters',
    description: '仪器当前测试的水质参数码。'
  },
  MEASUREMENT_RESULT_TYPE: {
    key: PhotoTekInputRegisterKeys.MEASUREMENT_RESULT_TYPE,
    address: 5,
    name: '测试结果类型',
    dataType: '无符号整型',
    registerCount: 1,
    unit: '',
    valueType: 'uint16',
    codeTable: 'measurementResultTypes',
    description: '最新测试结果对应的样品或质控类型。'
  },
  MEASUREMENT_DURATION: {
    key: PhotoTekInputRegisterKeys.MEASUREMENT_DURATION,
    address: 6,
    name: '测量时长',
    dataType: '无符号整型',
    registerCount: 1,
    unit: '秒',
    valueType: 'uint16',
    description: '上一次测量所花的时间。'
  },
  MEASUREMENT_TIME: {
    key: PhotoTekInputRegisterKeys.MEASUREMENT_TIME,
    address: 7,
    name: '测量时间',
    dataType: '时间类型',
    registerCount: 3,
    unit: '',
    valueType: 'time',
    description: '上一次测量的时间。'
  },
  CALIBRATION_SOLUTION_TIME: {
    key: PhotoTekInputRegisterKeys.CALIBRATION_SOLUTION_TIME,
    address: 10,
    name: '测量校准液时间',
    dataType: '时间类型',
    registerCount: 3,
    unit: '',
    valueType: 'time',
    description: '上一次测量校准液结果的测量时间。'
  },
  CALIBRATION_TIME: {
    key: PhotoTekInputRegisterKeys.CALIBRATION_TIME,
    address: 13,
    name: '校准时间',
    dataType: '时间类型',
    registerCount: 3,
    unit: '',
    valueType: 'time',
    description: '上一次校准时间。'
  },
  SYSTEM_STATUS: {
    key: PhotoTekInputRegisterKeys.SYSTEM_STATUS,
    address: 16,
    name: '系统状态',
    dataType: '无符号整型',
    registerCount: 1,
    unit: '',
    valueType: 'uint16',
    codeTable: 'systemStatuses',
    description: '仪器当前系统运行状态。'
  },
  CURRENT_ACTION: {
    key: PhotoTekInputRegisterKeys.CURRENT_ACTION,
    address: 17,
    name: '当前动作',
    dataType: '无符号整型',
    registerCount: 1,
    unit: '',
    valueType: 'uint16',
    codeTable: 'currentActions',
    description: '仪器当前执行的细分动作。'
  },
  CURRENT_TEMPERATURE: {
    key: PhotoTekInputRegisterKeys.CURRENT_TEMPERATURE,
    address: 18,
    name: '当前温度',
    dataType: '浮点型数组',
    registerCount: 4,
    unit: '℃',
    valueType: 'floatArrayCdab',
    description: '当前消解室温度和当前环境温度。'
  },
  ALARM_TIME: {
    key: PhotoTekInputRegisterKeys.ALARM_TIME,
    address: 22,
    name: '报警时间',
    dataType: '时间类型',
    registerCount: 3,
    unit: '',
    valueType: 'time',
    description: '报警发生时的时间。'
  },
  ALARM_CODE: {
    key: PhotoTekInputRegisterKeys.ALARM_CODE,
    address: 25,
    name: '报警代码',
    dataType: '无符号整型',
    registerCount: 1,
    unit: '',
    valueType: 'uint16',
    codeTable: 'alarmCodes',
    description: '报警代码。'
  },
  RANGE_TABLE: {
    key: PhotoTekInputRegisterKeys.RANGE_TABLE,
    address: 26,
    name: '量程表',
    dataType: '浮点型数组',
    registerCount: 6,
    unit: 'mg/L',
    valueType: 'floatArrayCdab',
    description: '系统支持的量程上限表，0 表示结束。'
  },
  PRODUCT_NAME: {
    key: PhotoTekInputRegisterKeys.PRODUCT_NAME,
    address: 36,
    name: '产品名称',
    dataType: '字符串',
    registerCount: 32,
    unit: '',
    valueType: 'utf16String',
    description: '产品名称，UTF-16BE 编码，不足补 0。'
  },
  PRODUCT_MODEL: {
    key: PhotoTekInputRegisterKeys.PRODUCT_MODEL,
    address: 68,
    name: '产品型号',
    dataType: '字符串',
    registerCount: 32,
    unit: '',
    valueType: 'utf16String',
    description: '产品型号，UTF-16BE 编码，不足补 0。'
  },
  MANUFACTURER: {
    key: PhotoTekInputRegisterKeys.MANUFACTURER,
    address: 100,
    name: '生产厂商',
    dataType: '字符串',
    registerCount: 32,
    unit: '',
    valueType: 'utf16String',
    description: '生产厂商，UTF-16BE 编码，不足补 0。'
  },
  SERIAL_NUMBER: {
    key: PhotoTekInputRegisterKeys.SERIAL_NUMBER,
    address: 132,
    name: '生产序列号',
    dataType: '字符串',
    registerCount: 16,
    unit: '',
    valueType: 'utf16String',
    description: '生产序列号，UTF-16BE 编码，不足补 0。'
  },
  LIQUID_BOARD_FIRMWARE: {
    key: PhotoTekInputRegisterKeys.LIQUID_BOARD_FIRMWARE,
    address: 148,
    name: '液路板固件版本',
    dataType: '无符号整型',
    registerCount: 2,
    unit: '',
    valueType: 'firmwareVersion',
    description: '液路板主版本、次版本、修订版本和内部版本。'
  },
  TEMPERATURE_BOARD_FIRMWARE: {
    key: PhotoTekInputRegisterKeys.TEMPERATURE_BOARD_FIRMWARE,
    address: 150,
    name: '温控板固件版本',
    dataType: '无符号整型',
    registerCount: 2,
    unit: '',
    valueType: 'firmwareVersion',
    description: '温控板主版本、次版本、修订版本和内部版本。'
  },
  SIGNAL_BOARD_FIRMWARE: {
    key: PhotoTekInputRegisterKeys.SIGNAL_BOARD_FIRMWARE,
    address: 152,
    name: '信号板固件版本',
    dataType: '无符号整型',
    registerCount: 2,
    unit: '',
    valueType: 'firmwareVersion',
    description: '信号板主版本、次版本、修订版本和内部版本。'
  },
  MAIN_BOARD_FIRMWARE: {
    key: PhotoTekInputRegisterKeys.MAIN_BOARD_FIRMWARE,
    address: 154,
    name: '主控板固件版本',
    dataType: '无符号整型',
    registerCount: 2,
    unit: '',
    valueType: 'firmwareVersion',
    description: '主控板主版本、次版本、修订版本和内部版本。'
  },
  DRIVER_BOARD_FIRMWARE: {
    key: PhotoTekInputRegisterKeys.DRIVER_BOARD_FIRMWARE,
    address: 156,
    name: '驱动板固件版本',
    dataType: '无符号整型',
    registerCount: 2,
    unit: '',
    valueType: 'firmwareVersion',
    description: '驱动板主版本、次版本、修订版本和内部版本。'
  },
  REACTION_BOARD_FIRMWARE: {
    key: PhotoTekInputRegisterKeys.REACTION_BOARD_FIRMWARE,
    address: 158,
    name: '反应板固件版本',
    dataType: '无符号整型',
    registerCount: 2,
    unit: '',
    valueType: 'firmwareVersion',
    description: '反应板主版本、次版本、修订版本和内部版本。'
  },
  SPAN_CHECK_RESULT: {
    key: PhotoTekInputRegisterKeys.SPAN_CHECK_RESULT,
    address: 165,
    name: '跨度标样核查结果',
    dataType: '浮点数',
    registerCount: 2,
    unit: 'mg/L',
    valueType: 'floatCdab',
    description: '跨度或标样核查结果浓度。'
  },
  SPAN_CHECK_TIME: {
    key: PhotoTekInputRegisterKeys.SPAN_CHECK_TIME,
    address: 167,
    name: '跨度标样核查时间',
    dataType: '时间类型',
    registerCount: 3,
    unit: '',
    valueType: 'time',
    description: '跨度或标样核查时间。'
  },
  WATER_SAMPLE_ABSORBANCE: {
    key: PhotoTekInputRegisterKeys.WATER_SAMPLE_ABSORBANCE,
    address: 190,
    name: '水样吸光度',
    dataType: '浮点数',
    registerCount: 2,
    unit: '',
    valueType: 'floatCdab',
    description: '水样测量过程原始吸光度值。'
  },
  WATER_SAMPLE_DATA_FLAG: {
    key: PhotoTekInputRegisterKeys.WATER_SAMPLE_DATA_FLAG,
    address: 192,
    name: '水样数据标识',
    dataType: '字符',
    registerCount: 1,
    unit: '',
    valueType: 'char',
    codeTable: 'dataFlags',
    description: '测量结果的数据标识。'
  },
  CALIBRATION_SOLUTION_ABSORBANCE: {
    key: PhotoTekInputRegisterKeys.CALIBRATION_SOLUTION_ABSORBANCE,
    address: 193,
    name: '测量校准液吸光度',
    dataType: '浮点数',
    registerCount: 2,
    unit: '',
    valueType: 'floatCdab',
    description: '量程校准液测量过程原始吸光度值。'
  },
  CALIBRATION_SOLUTION_DATA_FLAG: {
    key: PhotoTekInputRegisterKeys.CALIBRATION_SOLUTION_DATA_FLAG,
    address: 195,
    name: '测量校准液数据标识',
    dataType: '字符',
    registerCount: 1,
    unit: '',
    valueType: 'char',
    codeTable: 'dataFlags',
    description: '量程校准液结果的数据标识。'
  },
  CHECK_SOLUTION_ABSORBANCE: {
    key: PhotoTekInputRegisterKeys.CHECK_SOLUTION_ABSORBANCE,
    address: 199,
    name: '测核查液吸光度',
    dataType: '浮点数',
    registerCount: 2,
    unit: '',
    valueType: 'floatCdab',
    description: '测核查液或标样核查测量过程原始吸光度值。'
  },
  CHECK_SOLUTION_DATA_FLAG: {
    key: PhotoTekInputRegisterKeys.CHECK_SOLUTION_DATA_FLAG,
    address: 201,
    name: '测核查液数据标识',
    dataType: '字符',
    registerCount: 1,
    unit: '',
    valueType: 'char',
    codeTable: 'dataFlags',
    description: '测核查液结果的数据标识。'
  },
  CALIBRATION_ZERO_CONCENTRATION: {
    key: PhotoTekInputRegisterKeys.CALIBRATION_ZERO_CONCENTRATION,
    address: 220,
    name: '校准零点浓度',
    dataType: '浮点数',
    registerCount: 2,
    unit: 'mg/L',
    valueType: 'floatCdab',
    description: '校准校零浓度。'
  },
  CALIBRATION_ZERO_ABSORBANCE: {
    key: PhotoTekInputRegisterKeys.CALIBRATION_ZERO_ABSORBANCE,
    address: 222,
    name: '校准零点吸光度',
    dataType: '浮点数',
    registerCount: 2,
    unit: '',
    valueType: 'floatCdab',
    description: '校准零点的原始测量吸光度值。'
  },
  ZERO_DRIFT: {
    key: PhotoTekInputRegisterKeys.ZERO_DRIFT,
    address: 224,
    name: '零点漂移',
    dataType: '浮点数',
    registerCount: 2,
    unit: '%',
    valueType: 'floatCdab',
    description: '仪器 24 小时零点漂移。'
  },
  CALIBRATION_SPAN_CONCENTRATION: {
    key: PhotoTekInputRegisterKeys.CALIBRATION_SPAN_CONCENTRATION,
    address: 230,
    name: '校准标点浓度',
    dataType: '浮点数',
    registerCount: 2,
    unit: 'mg/L',
    valueType: 'floatCdab',
    description: '校准校标浓度。'
  },
  CALIBRATION_SPAN_ABSORBANCE: {
    key: PhotoTekInputRegisterKeys.CALIBRATION_SPAN_ABSORBANCE,
    address: 232,
    name: '校准标点吸光度',
    dataType: '浮点数',
    registerCount: 2,
    unit: '',
    valueType: 'floatCdab',
    description: '校准标点的原始测量吸光度值。'
  },
  SPAN_DRIFT: {
    key: PhotoTekInputRegisterKeys.SPAN_DRIFT,
    address: 234,
    name: '量程漂移',
    dataType: '浮点数',
    registerCount: 2,
    unit: '%',
    valueType: 'floatCdab',
    description: '仪器 24 小时量程漂移。'
  },
  COMPOSITE_MEASUREMENT_RESULT: {
    key: PhotoTekInputRegisterKeys.COMPOSITE_MEASUREMENT_RESULT,
    address: 236,
    name: '复合测量结果',
    dataType: '浮点型',
    registerCount: 2,
    unit: 'mg/L',
    valueType: 'floatCdab',
    description: '最新水样、空白、标样、量程校准液、测核查液等共用测量结果。'
  },
  COMPOSITE_RESULT_TIME: {
    key: PhotoTekInputRegisterKeys.COMPOSITE_RESULT_TIME,
    address: 238,
    name: '复合结果时间',
    dataType: '时间类型',
    registerCount: 3,
    unit: '',
    valueType: 'time',
    description: '各类复合测量结果的时间。'
  },
  COMPOSITE_DATA_FLAG: {
    key: PhotoTekInputRegisterKeys.COMPOSITE_DATA_FLAG,
    address: 241,
    name: '复合测量数据标识',
    dataType: '字符',
    registerCount: 1,
    unit: '',
    valueType: 'char',
    codeTable: 'compositeDataFlags',
    description: '复合测量结果的数据标识。'
  },
  TOC_FACTOR_CONSTANT: {
    key: PhotoTekInputRegisterKeys.TOC_FACTOR_CONSTANT,
    address: 242,
    name: '系数常数',
    dataType: '浮点型',
    registerCount: 2,
    unit: '',
    valueType: 'floatCdab',
    description: 'TOC 因子转换系数常数。'
  },
  TOC_FACTOR_RATIO: {
    key: PhotoTekInputRegisterKeys.TOC_FACTOR_RATIO,
    address: 244,
    name: '系数比例',
    dataType: '浮点型',
    registerCount: 2,
    unit: '',
    valueType: 'floatCdab',
    description: 'TOC 因子转换系数比例。'
  },
  TOC_FLOW_CONTROL: {
    key: PhotoTekInputRegisterKeys.TOC_FLOW_CONTROL,
    address: 246,
    name: '流量控制',
    dataType: '浮点型',
    registerCount: 2,
    unit: 'ml/min',
    valueType: 'floatCdab',
    description: 'TOC 因子流量。'
  },
  TOC_MEASUREMENT_RESULT: {
    key: PhotoTekInputRegisterKeys.TOC_MEASUREMENT_RESULT,
    address: 248,
    name: 'TOC测量结果',
    dataType: '浮点型',
    registerCount: 2,
    unit: 'mg/L',
    valueType: 'floatCdab',
    description: '上一次 TOC 测量结果。'
  }
};

export const PhotoTekMeasurementParameters: PhotoTekMeasurementParameterInfo[] = [
  { code: 1001, legacyCode: '001', name: 'PH', unit: '无' },
  { code: 1007, legacyCode: '', name: '总硬度', unit: 'mg/L' },
  { code: 1017, legacyCode: '010', name: 'BOD', unit: 'mg/L' },
  { code: 1018, legacyCode: '011', name: 'COD', unit: 'mg/L' },
  { code: 1019, legacyCode: '011', name: '高锰酸盐指数', unit: 'mg/L' },
  { code: 1020, legacyCode: '015', name: '总有机碳', unit: 'mg/L' },
  { code: 20111, legacyCode: '020', name: '总汞', unit: 'mg/L' },
  { code: 20113, legacyCode: '021', name: '烷基汞', unit: 'mg/L' },
  { code: 20115, legacyCode: '022', name: '总镉', unit: 'mg/L' },
  { code: 20116, legacyCode: '023', name: '总铬', unit: 'mg/L' },
  { code: 20117, legacyCode: '024', name: '六价铬', unit: 'mg/L' },
  { code: 20119, legacyCode: '026', name: '总砷', unit: 'mg/L' },
  { code: 20120, legacyCode: '027', name: '总铅', unit: 'mg/L' },
  { code: 20121, legacyCode: '028', name: '总镍', unit: 'mg/L' },
  { code: 20122, legacyCode: '029', name: '总铜', unit: 'mg/L' },
  { code: 20123, legacyCode: '030', name: '总锌', unit: 'mg/L' },
  { code: 20124, legacyCode: '031', name: '总锰', unit: 'mg/L' },
  { code: 20125, legacyCode: '032', name: '总铁', unit: 'mg/L' },
  { code: 20126, legacyCode: '033', name: '总银', unit: 'mg/L' },
  { code: 20127, legacyCode: '034', name: '总铍', unit: 'mg/L' },
  { code: 20128, legacyCode: '035', name: '总硒', unit: 'mg/L' },
  { code: 20092, legacyCode: '036', name: '锡', unit: 'mg/L' },
  { code: 20023, legacyCode: '037', name: '硼', unit: 'mg/L' },
  { code: 20061, legacyCode: '038', name: '钼', unit: 'mg/L' },
  { code: 20012, legacyCode: '039', name: '钡', unit: 'mg/L' },
  { code: 20038, legacyCode: '040', name: '钴', unit: 'mg/L' },
  { code: 20089, legacyCode: '041', name: '铊', unit: 'mg/L' },
  { code: 21003, legacyCode: '060', name: '氨氮', unit: 'mg/L' },
  { code: 99001, legacyCode: '061', name: '有机氮', unit: 'mg/L' },
  { code: 21001, legacyCode: '065', name: '总氮', unit: 'mg/L' },
  { code: 21016, legacyCode: '070', name: '氰化物', unit: 'mg/L' },
  { code: 21017, legacyCode: '072', name: '氟化物', unit: 'mg/L' },
  { code: 22001, legacyCode: '080', name: '石油类', unit: 'mg/L' },
  { code: 21022, legacyCode: '090', name: '氯化物', unit: 'mg/L' },
  { code: 21011, legacyCode: '101', name: '总磷', unit: 'mg/L' },
  { code: 20002, legacyCode: '', name: '铝', unit: 'mg/L' },
  { code: 21033, legacyCode: '', name: '总碱度', unit: 'mg/L' }
];

export const PhotoTekMeasurementResultTypes: PhotoTekCodeDescription[] = [
  { code: 0, label: '零点校准液' },
  { code: 1, label: '水样' },
  { code: 2, label: '量程校准液' },
  { code: 7, label: '跨度(标样)核查' },
  { code: 10, label: '质控样' }
];

export const PhotoTekSystemStatuses: PhotoTekCodeDescription[] = [
  { code: 0, label: '空闲' },
  { code: 1, label: '测量水样' },
  { code: 2, label: '测量程校准液' },
  { code: 3, label: '测零点校准液' },
  { code: 4, label: '校准' },
  { code: 5, label: '清洗消解室' },
  { code: 6, label: '清洗定量管' },
  { code: 7, label: '清洗所有管路' },
  { code: 8, label: '采集水样' },
  { code: 9, label: '一键运行' },
  { code: 10, label: '消解室冷却' },
  { code: 11, label: '定量泵自动校准' },
  { code: 12, label: '管道操作' },
  { code: 13, label: '智能诊断' },
  { code: 14, label: '通信检测' },
  { code: 15, label: '硬件测试' },
  { code: 16, label: '主控板升级' },
  { code: 17, label: '液路板升级' },
  { code: 18, label: '温控板升级' },
  { code: 19, label: '信号板升级' },
  { code: 20, label: '反应板升级' },
  { code: 21, label: '驱动板升级' },
  { code: 22, label: '深度清洗' },
  { code: 28, label: '组合操作' },
  { code: 29, label: '零点校准' },
  { code: 30, label: '量程校准' },
  { code: 33, label: '测质控样' },
  { code: 41, label: '测核查液' },
  { code: 44, label: '定量模块AD校准' },
  { code: 45, label: '测量模块AD校准' },
  { code: 46, label: '一键更新试剂' },
  { code: 255, label: '故障' }
];

export const PhotoTekCurrentActions: PhotoTekCodeDescription[] = [
  { code: 0, label: '空闲' },
  { code: 1, label: '测量前清洗' },
  { code: 2, label: '读初始值' },
  { code: 3, label: '润洗' },
  { code: 4, label: '加待测样' },
  { code: 5, label: '加试剂一' },
  { code: 6, label: '加试剂二' },
  { code: 7, label: '加试剂三' },
  { code: 8, label: '加试剂四' },
  { code: 9, label: '加试剂五' },
  { code: 10, label: '加试剂六' },
  { code: 11, label: '清洗定量管' },
  { code: 12, label: '消解液预热' },
  { code: 13, label: '加热消解' },
  { code: 14, label: '消解冷却' },
  { code: 15, label: '读反应值' },
  { code: 16, label: '清洗' },
  { code: 17, label: '冷却' },
  { code: 18, label: '采集' },
  { code: 19, label: '静置' },
  { code: 20, label: '校准' },
  { code: 21, label: '填充零点校准液' },
  { code: 22, label: '排至零点校准液管' },
  { code: 23, label: '填充水样' },
  { code: 24, label: '排至水样管' },
  { code: 25, label: '填充量程校准液' },
  { code: 26, label: '排至量程校准液管' },
  { code: 27, label: '填充试剂1' },
  { code: 28, label: '排至试剂1管' },
  { code: 29, label: '填充试剂2' },
  { code: 30, label: '排至试剂2管' },
  { code: 31, label: '填充试剂3' },
  { code: 32, label: '排至试剂3管' },
  { code: 33, label: '填充试剂4' },
  { code: 34, label: '排至试剂4管' },
  { code: 35, label: '填充试剂5' },
  { code: 36, label: '排至试剂5管' },
  { code: 37, label: '填充试剂6' },
  { code: 38, label: '排至试剂6管' },
  { code: 39, label: '吸消解液' },
  { code: 40, label: '排至消解器' },
  { code: 41, label: '排至废液' },
  { code: 42, label: '液路板检测' },
  { code: 43, label: '信号板检测' },
  { code: 44, label: '温控板检测' },
  { code: 45, label: '加热模块诊断' },
  { code: 46, label: '冷却模块诊断' },
  { code: 47, label: '测量模块诊断' },
  { code: 48, label: '定量模块诊断' },
  { code: 49, label: '零点校准液阀诊断' },
  { code: 50, label: '水样阀诊断' },
  { code: 51, label: '量程校准液阀诊断' },
  { code: 52, label: '试剂一阀诊断' },
  { code: 53, label: '试剂二阀诊断' },
  { code: 54, label: '试剂三阀诊断' },
  { code: 55, label: '试剂四阀诊断' },
  { code: 56, label: '试剂五阀诊断' },
  { code: 57, label: '试剂六阀诊断' },
  { code: 58, label: '消解阀诊断' },
  { code: 59, label: '废液阀诊断' },
  { code: 60, label: '泵测试' },
  { code: 61, label: '水样阀测试' },
  { code: 62, label: '零点校准液阀测试' },
  { code: 63, label: '量程校准液阀测试' },
  { code: 64, label: '试剂一阀测试' },
  { code: 65, label: '试剂二阀测试' },
  { code: 66, label: '试剂三阀测试' },
  { code: 67, label: '试剂四阀测试' },
  { code: 68, label: '试剂五阀测试' },
  { code: 69, label: '试剂六阀测试' },
  { code: 70, label: '废液阀测试' },
  { code: 71, label: '消解上阀测试' },
  { code: 72, label: '消解下阀测试' },
  { code: 73, label: '加热测试' },
  { code: 74, label: '冷却测试' },
  { code: 76, label: '定量点一LED' },
  { code: 77, label: '定量点二LED' },
  { code: 78, label: '采水继电器' },
  { code: 79, label: '继电器1' },
  { code: 80, label: '继电器2' },
  { code: 81, label: '样品4mA输出' },
  { code: 82, label: '样品12mA输出' },
  { code: 83, label: '样品20mA输出' },
  { code: 84, label: '核查4mA输出' },
  { code: 85, label: '核查12mA输出' },
  { code: 86, label: '核查20mA输出' },
  { code: 87, label: '复制' },
  { code: 88, label: '升级' },
  { code: 89, label: '擦除' },
  { code: 90, label: '烧写' },
  { code: 91, label: '测量前排液' },
  { code: 92, label: '测量后排液' },
  { code: 93, label: '测量后清洗' },
  { code: 94, label: '反应' },
  { code: 95, label: '机箱冷却' },
  { code: 96, label: '清空残留液' },
  { code: 97, label: '清空零点校准液管' },
  { code: 98, label: '清空量程校准液管' },
  { code: 99, label: '清空试剂一管' },
  { code: 100, label: '清空试剂二管' },
  { code: 101, label: '清空试剂三管' },
  { code: 102, label: '清空试剂四管' },
  { code: 103, label: '清空试剂五管' },
  { code: 104, label: '清空试剂六管' },
  { code: 105, label: '清洗消解室' },
  { code: 106, label: '清洗水样管' },
  { code: 107, label: '清洗量程校准液管' },
  { code: 108, label: '清洗零点校准液管' },
  { code: 109, label: '清洗试剂1管' },
  { code: 110, label: '清洗试剂2管' },
  { code: 111, label: '清洗试剂3管' },
  { code: 112, label: '清洗试剂4管' },
  { code: 113, label: '清洗试剂5管' },
  { code: 114, label: '清洗试剂6管' },
  { code: 115, label: '排空水样管' },
  { code: 116, label: '排空量程校准液管' },
  { code: 117, label: '排空零点校准液管' },
  { code: 118, label: '排空试剂1管' },
  { code: 119, label: '排空试剂2管' },
  { code: 120, label: '排空试剂3管' },
  { code: 121, label: '排空试剂4管' },
  { code: 122, label: '排空试剂5管' },
  { code: 123, label: '排空试剂6管' },
  { code: 124, label: '排空废液管' },
  { code: 125, label: '读空白值' },
  { code: 126, label: '驱动板测试' },
  { code: 127, label: '反应板测试' },
  { code: 128, label: '抽零点校准液到消解室' },
  { code: 129, label: '排消解液至废液' },
  { code: 130, label: '气密性检查' },
  { code: 131, label: '排消解液至废水' },
  { code: 132, label: '读空白值后排液' },
  { code: 141, label: '填充零点核查液' },
  { code: 142, label: '排至零点核查液管' },
  { code: 143, label: '填充量程核查液' },
  { code: 144, label: '排至量程核查液管' },
  { code: 148, label: '排空零点核查液管' },
  { code: 149, label: '排空量程核查液管' },
  { code: 150, label: '排至废水' },
  { code: 151, label: '定量AD调节' },
  { code: 152, label: '测量AD调节' },
  { code: 153, label: '一键加热' }
];

export const PhotoTekAlarmCodes: PhotoTekCodeDescription[] = [
  { code: 0, label: '无报警' },
  { code: 1, label: '零点校准液抽取失败' },
  { code: 2, label: '量程校准液抽取失败' },
  { code: 3, label: '水样抽取失败' },
  { code: 4, label: '消解液抽取失败' },
  { code: 5, label: '试剂一抽取失败' },
  { code: 6, label: '试剂二抽取失败' },
  { code: 7, label: '试剂三抽取失败' },
  { code: 8, label: '试剂四抽取失败' },
  { code: 9, label: '试剂五抽取失败' },
  { code: 10, label: '试剂六抽取失败' },
  { code: 11, label: '请更换零点校准液' },
  { code: 12, label: '请更换量程校准液' },
  { code: 13, label: '请更换试剂一' },
  { code: 14, label: '请更换试剂二' },
  { code: 15, label: '请更换试剂三' },
  { code: 16, label: '请更换试剂四' },
  { code: 17, label: '请更换试剂五' },
  { code: 18, label: '请更换试剂六' },
  { code: 19, label: '温控故障' },
  { code: 20, label: '液路板通信异常' },
  { code: 21, label: '温控板通信异常' },
  { code: 22, label: '信号板通信异常' },
  { code: 23, label: '液路板升级失败' },
  { code: 24, label: '温控板升级失败' },
  { code: 25, label: '信号板升级失败' },
  { code: 26, label: '仪器运行故障' },
  { code: 27, label: '排消解液异常' },
  { code: 28, label: '蠕动泵校准失败' },
  { code: 29, label: '水样超标' },
  { code: 30, label: '校准结果错误' },
  { code: 31, label: '蠕动泵软管已过期' },
  { code: 32, label: '夹断阀软管已过期' },
  { code: 33, label: '计量管已过期' },
  { code: 34, label: '计量O形圈已过期' },
  { code: 35, label: 'PTFE硬管已过期' },
  { code: 36, label: '驱动板通信异常' },
  { code: 37, label: '反应板通信异常' },
  { code: 38, label: '驱动板升级失败' },
  { code: 39, label: '反应板升级失败' },
  { code: 40, label: '请更换废液' },
  { code: 41, label: '水样超量程' },
  { code: 42, label: '量程校准结果错误' },
  { code: 43, label: '请更换废水' },
  { code: 44, label: '静态AD调节失败' },
  { code: 45, label: '消解室加液异常' },
  { code: 46, label: '核查结果错误' },
  { code: 47, label: '仪器漏液' },
  { code: 80, label: '总阀压力过低', description: 'TOC特殊告警码' },
  { code: 81, label: '总阀压力过高', description: 'TOC特殊告警码' },
  { code: 82, label: '载气压力过高', description: 'TOC特殊告警码' },
  { code: 83, label: '载气压力过低', description: 'TOC特殊告警码' },
  { code: 84, label: '载气调节失败', description: 'TOC特殊告警码' },
  { code: 85, label: '位置异常，滑块处于非原点', description: 'TOC特殊告警码' },
  { code: 86, label: '传感器故障，请检查传感器线路', description: 'TOC特殊告警码' },
  { code: 87, label: '滑块零点校准失败', description: 'TOC特殊告警码' },
  { code: 88, label: '基线无效', description: 'TOC特殊告警码' }
];

export const PhotoTekDataFlags: PhotoTekCodeDescription[] = [
  { code: 'N', label: '正常' },
  { code: 'T', label: '超上限' },
  { code: 'L', label: '超下限' },
  { code: 'P', label: '电源故障' },
  { code: 'D', label: '仪器故障' },
  { code: 'F', label: '仪器通信故障' },
  { code: 'B', label: '仪器离线' },
  { code: 'Z', label: '取水点无水样' },
  { code: 'S', label: '手工输入数据' },
  { code: 'M', label: '维护调试数据' }
];

export const PhotoTekCompositeDataFlags: PhotoTekCodeDescription[] = [
  ...PhotoTekDataFlags,
  {
    code: 'C',
    label: '非水样结果',
    description: '除水样外，零点校准液、标样、量程校准液、零点核查、量程核查、加标、平行等测量结果标识。'
  }
];

/**
 * 根据协议 key 获取输入寄存器定义。
 *
 * @param key PhotoTekInputRegisterKeys 中定义的寄存器 key。
 * @returns 成功返回寄存器定义；未知 key 返回 null。
 */
export function getPhotoTekInputRegisterByKey(key: string): PhotoTekInputRegisterDefinition | null {
  const registerList: PhotoTekInputRegisterDefinition[] = [
    PhotoTekInputRegisters.MEASUREMENT_RESULT,
    PhotoTekInputRegisters.CALIBRATION_SOLUTION_RESULT,
    PhotoTekInputRegisters.MEASUREMENT_PARAMETER,
    PhotoTekInputRegisters.MEASUREMENT_RESULT_TYPE,
    PhotoTekInputRegisters.MEASUREMENT_DURATION,
    PhotoTekInputRegisters.MEASUREMENT_TIME,
    PhotoTekInputRegisters.CALIBRATION_SOLUTION_TIME,
    PhotoTekInputRegisters.CALIBRATION_TIME,
    PhotoTekInputRegisters.SYSTEM_STATUS,
    PhotoTekInputRegisters.CURRENT_ACTION,
    PhotoTekInputRegisters.CURRENT_TEMPERATURE,
    PhotoTekInputRegisters.ALARM_TIME,
    PhotoTekInputRegisters.ALARM_CODE,
    PhotoTekInputRegisters.RANGE_TABLE,
    PhotoTekInputRegisters.PRODUCT_NAME,
    PhotoTekInputRegisters.PRODUCT_MODEL,
    PhotoTekInputRegisters.MANUFACTURER,
    PhotoTekInputRegisters.SERIAL_NUMBER,
    PhotoTekInputRegisters.LIQUID_BOARD_FIRMWARE,
    PhotoTekInputRegisters.TEMPERATURE_BOARD_FIRMWARE,
    PhotoTekInputRegisters.SIGNAL_BOARD_FIRMWARE,
    PhotoTekInputRegisters.MAIN_BOARD_FIRMWARE,
    PhotoTekInputRegisters.DRIVER_BOARD_FIRMWARE,
    PhotoTekInputRegisters.REACTION_BOARD_FIRMWARE,
    PhotoTekInputRegisters.SPAN_CHECK_RESULT,
    PhotoTekInputRegisters.SPAN_CHECK_TIME,
    PhotoTekInputRegisters.WATER_SAMPLE_ABSORBANCE,
    PhotoTekInputRegisters.WATER_SAMPLE_DATA_FLAG,
    PhotoTekInputRegisters.CALIBRATION_SOLUTION_ABSORBANCE,
    PhotoTekInputRegisters.CALIBRATION_SOLUTION_DATA_FLAG,
    PhotoTekInputRegisters.CHECK_SOLUTION_ABSORBANCE,
    PhotoTekInputRegisters.CHECK_SOLUTION_DATA_FLAG,
    PhotoTekInputRegisters.CALIBRATION_ZERO_CONCENTRATION,
    PhotoTekInputRegisters.CALIBRATION_ZERO_ABSORBANCE,
    PhotoTekInputRegisters.ZERO_DRIFT,
    PhotoTekInputRegisters.CALIBRATION_SPAN_CONCENTRATION,
    PhotoTekInputRegisters.CALIBRATION_SPAN_ABSORBANCE,
    PhotoTekInputRegisters.SPAN_DRIFT,
    PhotoTekInputRegisters.COMPOSITE_MEASUREMENT_RESULT,
    PhotoTekInputRegisters.COMPOSITE_RESULT_TIME,
    PhotoTekInputRegisters.COMPOSITE_DATA_FLAG,
    PhotoTekInputRegisters.TOC_FACTOR_CONSTANT,
    PhotoTekInputRegisters.TOC_FACTOR_RATIO,
    PhotoTekInputRegisters.TOC_FLOW_CONTROL,
    PhotoTekInputRegisters.TOC_MEASUREMENT_RESULT
  ];

  for (const item of registerList) {
    if (item.key === key) {
      return item;
    }
  }
  return null;
}

/**
 * 根据测量参数新码值获取参数名称、旧码值和单位。
 *
 * @param code 仪器返回的测量参数新码值。
 * @returns 成功返回参数信息；未知码值返回 null。
 */
export function getPhotoTekMeasurementParameterByCode(code: number): PhotoTekMeasurementParameterInfo | null {
  for (const item of PhotoTekMeasurementParameters) {
    if (item.code === code) {
      return item;
    }
  }
  return null;
}

/**
 * 在指定码表中查找码值含义。
 *
 * @param table 码表数组。
 * @param code 需要解析的数字或字符码值。
 * @returns 成功返回码值说明；未知码值返回 null。
 */
export function getPhotoTekCodeDescription(
  table: PhotoTekCodeDescription[],
  code: number | string
): PhotoTekCodeDescription | null {
  for (const item of table) {
    if (item.code === code) {
      return item;
    }
  }
  return null;
}
