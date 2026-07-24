import {
  PhotoTekCodeDescription,
  PhotoTekHoldRegisterDefinition
} from './PhotoTekTypes';

export interface PhotoTekHoldRegisterKeyMap {
  CURRENT_RANGE: string;
  CALIBRATION_CURVE_SLOPE: string;
  CALIBRATION_CURVE_INTERCEPT: string;
  DIGESTION_TEMPERATURE: string;
  DIGESTION_TIME: string;
  REACTION_TEMPERATURE: string;
  REACTION_TIME: string;
  CORRECTION_FACTOR: string;
  MEASUREMENT_CONTROL: string;
  WATER_COLLECTION_CONTROL: string;
  SYSTEM_TIME: string;
  MEASUREMENT_MODE: string;
  AUTO_MEASUREMENT_INTERVAL: string;
  AUTO_CALIBRATION_MODE: string;
  AUTO_CALIBRATION_INTERVAL: string;
  CURRENT_RANGE_DILUTION_FACTOR: string;
  ZERO_CALIBRATION_SOLUTION_CONCENTRATION: string;
  SPAN_CALIBRATION_SOLUTION_CONCENTRATION: string;
  REAGENT_ONE_VOLUME: string;
  REAGENT_TWO_VOLUME: string;
  REAGENT_THREE_VOLUME: string;
  REAGENT_FOUR_VOLUME: string;
  REAGENT_FIVE_VOLUME: string;
  CURRENT_RANGE_CORRECTION_FACTOR: string;
  SPAN_CHECK_ALLOWED_DEVIATION: string;
  SPAN_CHECK_DEVIATION: string;
}

export interface PhotoTekHoldRegisterMap {
  CURRENT_RANGE: PhotoTekHoldRegisterDefinition;
  CALIBRATION_CURVE_SLOPE: PhotoTekHoldRegisterDefinition;
  CALIBRATION_CURVE_INTERCEPT: PhotoTekHoldRegisterDefinition;
  DIGESTION_TEMPERATURE: PhotoTekHoldRegisterDefinition;
  DIGESTION_TIME: PhotoTekHoldRegisterDefinition;
  REACTION_TEMPERATURE: PhotoTekHoldRegisterDefinition;
  REACTION_TIME: PhotoTekHoldRegisterDefinition;
  CORRECTION_FACTOR: PhotoTekHoldRegisterDefinition;
  MEASUREMENT_CONTROL: PhotoTekHoldRegisterDefinition;
  WATER_COLLECTION_CONTROL: PhotoTekHoldRegisterDefinition;
  SYSTEM_TIME: PhotoTekHoldRegisterDefinition;
  MEASUREMENT_MODE: PhotoTekHoldRegisterDefinition;
  AUTO_MEASUREMENT_INTERVAL: PhotoTekHoldRegisterDefinition;
  AUTO_CALIBRATION_MODE: PhotoTekHoldRegisterDefinition;
  AUTO_CALIBRATION_INTERVAL: PhotoTekHoldRegisterDefinition;
  CURRENT_RANGE_DILUTION_FACTOR: PhotoTekHoldRegisterDefinition;
  ZERO_CALIBRATION_SOLUTION_CONCENTRATION: PhotoTekHoldRegisterDefinition;
  SPAN_CALIBRATION_SOLUTION_CONCENTRATION: PhotoTekHoldRegisterDefinition;
  REAGENT_ONE_VOLUME: PhotoTekHoldRegisterDefinition;
  REAGENT_TWO_VOLUME: PhotoTekHoldRegisterDefinition;
  REAGENT_THREE_VOLUME: PhotoTekHoldRegisterDefinition;
  REAGENT_FOUR_VOLUME: PhotoTekHoldRegisterDefinition;
  REAGENT_FIVE_VOLUME: PhotoTekHoldRegisterDefinition;
  CURRENT_RANGE_CORRECTION_FACTOR: PhotoTekHoldRegisterDefinition;
  SPAN_CHECK_ALLOWED_DEVIATION: PhotoTekHoldRegisterDefinition;
  SPAN_CHECK_DEVIATION: PhotoTekHoldRegisterDefinition;
}

export const PhotoTekHoldRegisterKeys: PhotoTekHoldRegisterKeyMap = {
  CURRENT_RANGE: 'currentRange',
  CALIBRATION_CURVE_SLOPE: 'calibrationCurveSlope',
  CALIBRATION_CURVE_INTERCEPT: 'calibrationCurveIntercept',
  DIGESTION_TEMPERATURE: 'digestionTemperature',
  DIGESTION_TIME: 'digestionTime',
  REACTION_TEMPERATURE: 'reactionTemperature',
  REACTION_TIME: 'reactionTime',
  CORRECTION_FACTOR: 'correctionFactor',
  MEASUREMENT_CONTROL: 'measurementControl',
  WATER_COLLECTION_CONTROL: 'waterCollectionControl',
  SYSTEM_TIME: 'systemTime',
  MEASUREMENT_MODE: 'measurementMode',
  AUTO_MEASUREMENT_INTERVAL: 'autoMeasurementInterval',
  AUTO_CALIBRATION_MODE: 'autoCalibrationMode',
  AUTO_CALIBRATION_INTERVAL: 'autoCalibrationInterval',
  CURRENT_RANGE_DILUTION_FACTOR: 'currentRangeDilutionFactor',
  ZERO_CALIBRATION_SOLUTION_CONCENTRATION: 'zeroCalibrationSolutionConcentration',
  SPAN_CALIBRATION_SOLUTION_CONCENTRATION: 'spanCalibrationSolutionConcentration',
  REAGENT_ONE_VOLUME: 'reagentOneVolume',
  REAGENT_TWO_VOLUME: 'reagentTwoVolume',
  REAGENT_THREE_VOLUME: 'reagentThreeVolume',
  REAGENT_FOUR_VOLUME: 'reagentFourVolume',
  REAGENT_FIVE_VOLUME: 'reagentFiveVolume',
  CURRENT_RANGE_CORRECTION_FACTOR: 'currentRangeCorrectionFactor',
  SPAN_CHECK_ALLOWED_DEVIATION: 'spanCheckAllowedDeviation',
  SPAN_CHECK_DEVIATION: 'spanCheckDeviation'
};

export const PhotoTekHoldRegisters: PhotoTekHoldRegisterMap = {
  CURRENT_RANGE: {
    key: PhotoTekHoldRegisterKeys.CURRENT_RANGE,
    address: 256,
    name: '当前量程',
    dataType: '浮点型',
    registerCount: 2,
    unit: 'mg/L',
    valueType: 'floatCdab',
    access: 'readWrite',
    description: '当前量程上限；写入后仪器自动匹配最接近的可用量程。'
  },
  CALIBRATION_CURVE_SLOPE: {
    key: PhotoTekHoldRegisterKeys.CALIBRATION_CURVE_SLOPE,
    address: 258,
    name: '校准曲线/斜率',
    dataType: '浮点型',
    registerCount: 2,
    unit: '',
    valueType: 'floatCdab',
    access: 'readWrite',
    description: '当前校准曲线斜率。'
  },
  CALIBRATION_CURVE_INTERCEPT: {
    key: PhotoTekHoldRegisterKeys.CALIBRATION_CURVE_INTERCEPT,
    address: 260,
    name: '校准曲线/截距',
    dataType: '浮点型',
    registerCount: 2,
    unit: '',
    valueType: 'floatCdab',
    access: 'readWrite',
    description: '当前校准曲线截距。'
  },
  DIGESTION_TEMPERATURE: {
    key: PhotoTekHoldRegisterKeys.DIGESTION_TEMPERATURE,
    address: 262,
    name: '消解温度',
    dataType: '浮点型',
    registerCount: 2,
    unit: '℃',
    valueType: 'floatCdab',
    access: 'readWrite',
    description: '消解阶段目标温度。'
  },
  DIGESTION_TIME: {
    key: PhotoTekHoldRegisterKeys.DIGESTION_TIME,
    address: 264,
    name: '消解时间',
    dataType: '无符号整型',
    registerCount: 1,
    unit: '秒',
    valueType: 'uint16',
    access: 'readWrite',
    description: '消解阶段持续时间，取值范围 0~65535 秒。'
  },
  REACTION_TEMPERATURE: {
    key: PhotoTekHoldRegisterKeys.REACTION_TEMPERATURE,
    address: 265,
    name: '反应温度',
    dataType: '浮点型',
    registerCount: 2,
    unit: '℃',
    valueType: 'floatCdab',
    access: 'readWrite',
    description: '反应阶段目标温度。'
  },
  REACTION_TIME: {
    key: PhotoTekHoldRegisterKeys.REACTION_TIME,
    address: 267,
    name: '反应时间',
    dataType: '无符号整型',
    registerCount: 1,
    unit: '秒',
    valueType: 'uint16',
    access: 'readWrite',
    description: '反应阶段持续时间，取值范围 0~65535 秒。'
  },
  CORRECTION_FACTOR: {
    key: PhotoTekHoldRegisterKeys.CORRECTION_FACTOR,
    address: 268,
    name: '修正因子',
    dataType: '浮点型',
    registerCount: 2,
    unit: '',
    valueType: 'floatCdab',
    access: 'readWrite',
    description: '结果修正因子。'
  },
  MEASUREMENT_CONTROL: {
    key: PhotoTekHoldRegisterKeys.MEASUREMENT_CONTROL,
    address: 272,
    name: '测量控制',
    dataType: '无符号整型',
    registerCount: 1,
    unit: '',
    valueType: 'uint16',
    access: 'write',
    codeTable: 'measurementControlCodes',
    description: '写入控制码触发测量、校准、清洗、采样或核查动作。'
  },
  WATER_COLLECTION_CONTROL: {
    key: PhotoTekHoldRegisterKeys.WATER_COLLECTION_CONTROL,
    address: 273,
    name: '采水控制',
    dataType: '无符号整型',
    registerCount: 1,
    unit: '',
    valueType: 'uint16',
    access: 'write',
    codeTable: 'waterCollectionControlCodes',
    description: '写入 0 关闭采水，写入 1 开启采水。'
  },
  SYSTEM_TIME: {
    key: PhotoTekHoldRegisterKeys.SYSTEM_TIME,
    address: 274,
    name: '系统时间',
    dataType: '时间类型',
    registerCount: 3,
    unit: '',
    valueType: 'time',
    access: 'readWrite',
    description: '仪器系统时间，3 个寄存器依次存储年偏移、月、日、时、分、秒；V1.x 不支持。'
  },
  MEASUREMENT_MODE: {
    key: PhotoTekHoldRegisterKeys.MEASUREMENT_MODE,
    address: 277,
    name: '测量模式',
    dataType: '无符号整型',
    registerCount: 1,
    unit: '',
    valueType: 'uint16',
    access: 'readWrite',
    codeTable: 'measurementModes',
    description: '自动测量模式，支持触发、周期、整点和连续模式。'
  },
  AUTO_MEASUREMENT_INTERVAL: {
    key: PhotoTekHoldRegisterKeys.AUTO_MEASUREMENT_INTERVAL,
    address: 278,
    name: '自动测量/时间间隔',
    dataType: '无符号整型',
    registerCount: 1,
    unit: '小时',
    valueType: 'uint16',
    access: 'readWrite',
    description: '周期或整点测量模式下的自动测量间隔。'
  },
  AUTO_CALIBRATION_MODE: {
    key: PhotoTekHoldRegisterKeys.AUTO_CALIBRATION_MODE,
    address: 279,
    name: '自动校准模式',
    dataType: '无符号整型',
    registerCount: 1,
    unit: '',
    valueType: 'uint16',
    access: 'readWrite',
    codeTable: 'autoCalibrationModes',
    description: '自动校准模式，支持触发、周期和整点模式。'
  },
  AUTO_CALIBRATION_INTERVAL: {
    key: PhotoTekHoldRegisterKeys.AUTO_CALIBRATION_INTERVAL,
    address: 280,
    name: '自动校准/时间间隔',
    dataType: '无符号整型',
    registerCount: 1,
    unit: '小时',
    valueType: 'uint16',
    access: 'readWrite',
    description: '周期或整点校准模式下的自动校准间隔。'
  },
  CURRENT_RANGE_DILUTION_FACTOR: {
    key: PhotoTekHoldRegisterKeys.CURRENT_RANGE_DILUTION_FACTOR,
    address: 283,
    name: '当前量程/稀释倍数',
    dataType: '浮点型',
    registerCount: 2,
    unit: '',
    valueType: 'floatCdab',
    access: 'read',
    description: '当前量程对应的稀释倍数。'
  },
  ZERO_CALIBRATION_SOLUTION_CONCENTRATION: {
    key: PhotoTekHoldRegisterKeys.ZERO_CALIBRATION_SOLUTION_CONCENTRATION,
    address: 293,
    name: '零点校准液浓度',
    dataType: '浮点型',
    registerCount: 2,
    unit: 'mg/L',
    valueType: 'floatCdab',
    access: 'read',
    description: '零点校准液浓度。'
  },
  SPAN_CALIBRATION_SOLUTION_CONCENTRATION: {
    key: PhotoTekHoldRegisterKeys.SPAN_CALIBRATION_SOLUTION_CONCENTRATION,
    address: 295,
    name: '量程校准液浓度',
    dataType: '浮点型',
    registerCount: 2,
    unit: 'mg/L',
    valueType: 'floatCdab',
    access: 'read',
    description: '量程校准液浓度。'
  },
  REAGENT_ONE_VOLUME: {
    key: PhotoTekHoldRegisterKeys.REAGENT_ONE_VOLUME,
    address: 300,
    name: '试剂一/加液体积',
    dataType: '浮点型',
    registerCount: 2,
    unit: 'mL',
    valueType: 'floatCdab',
    access: 'read',
    description: '试剂一加液体积。'
  },
  REAGENT_TWO_VOLUME: {
    key: PhotoTekHoldRegisterKeys.REAGENT_TWO_VOLUME,
    address: 302,
    name: '试剂二/加液体积',
    dataType: '浮点型',
    registerCount: 2,
    unit: 'mL',
    valueType: 'floatCdab',
    access: 'read',
    description: '试剂二加液体积。'
  },
  REAGENT_THREE_VOLUME: {
    key: PhotoTekHoldRegisterKeys.REAGENT_THREE_VOLUME,
    address: 304,
    name: '试剂三/加液体积',
    dataType: '浮点型',
    registerCount: 2,
    unit: 'mL',
    valueType: 'floatCdab',
    access: 'read',
    description: '试剂三加液体积。'
  },
  REAGENT_FOUR_VOLUME: {
    key: PhotoTekHoldRegisterKeys.REAGENT_FOUR_VOLUME,
    address: 306,
    name: '试剂四/加液体积',
    dataType: '浮点型',
    registerCount: 2,
    unit: 'mL',
    valueType: 'floatCdab',
    access: 'read',
    description: '试剂四加液体积。'
  },
  REAGENT_FIVE_VOLUME: {
    key: PhotoTekHoldRegisterKeys.REAGENT_FIVE_VOLUME,
    address: 308,
    name: '试剂五/加液体积',
    dataType: '浮点型',
    registerCount: 2,
    unit: 'mL',
    valueType: 'floatCdab',
    access: 'read',
    description: '试剂五加液体积。'
  },
  CURRENT_RANGE_CORRECTION_FACTOR: {
    key: PhotoTekHoldRegisterKeys.CURRENT_RANGE_CORRECTION_FACTOR,
    address: 310,
    name: '当前量程校正因子',
    dataType: '浮点型',
    registerCount: 2,
    unit: '',
    valueType: 'floatCdab',
    access: 'read',
    description: '当前量程对应的校正因子。'
  },
  SPAN_CHECK_ALLOWED_DEVIATION: {
    key: PhotoTekHoldRegisterKeys.SPAN_CHECK_ALLOWED_DEVIATION,
    address: 312,
    name: '跨度(标样)核查允许偏差值',
    dataType: '浮点型',
    registerCount: 2,
    unit: '%',
    valueType: 'floatCdab',
    access: 'read',
    description: '跨度或标样核查允许偏差百分比。'
  },
  SPAN_CHECK_DEVIATION: {
    key: PhotoTekHoldRegisterKeys.SPAN_CHECK_DEVIATION,
    address: 314,
    name: '跨度(标样)核查偏差值',
    dataType: '浮点型',
    registerCount: 2,
    unit: '%',
    valueType: 'floatCdab',
    access: 'read',
    description: '最近一次跨度或标样核查偏差百分比。'
  }
};

export const PhotoTekMeasurementControlCodes: PhotoTekCodeDescription[] = [
  { code: 0, label: '测量水样' },
  { code: 1, label: '校准' },
  { code: 2, label: '停止' },
  { code: 3, label: '测量量程校准液' },
  { code: 4, label: '测量零点校准液' },
  { code: 5, label: '清洗定量管' },
  { code: 6, label: '清洗消解室' },
  { code: 7, label: '深度清洗' },
  { code: 8, label: '清洗所有管路' },
  { code: 9, label: '采集水样' },
  { code: 10, label: '定量泵自动校准' },
  { code: 13, label: '零点校准' },
  { code: 14, label: '量程(标点)校准' },
  { code: 20, label: '零点核查' },
  { code: 21, label: '测跨度(标样)核查液' }
];

export const PhotoTekWaterCollectionControlCodes: PhotoTekCodeDescription[] = [
  { code: 0, label: '关闭采水' },
  { code: 1, label: '开启采水' }
];

export const PhotoTekMeasurementModes: PhotoTekCodeDescription[] = [
  { code: 0, label: '触发模式' },
  { code: 1, label: '周期模式' },
  { code: 2, label: '整点模式' },
  { code: 3, label: '连续模式' }
];

export const PhotoTekAutoCalibrationModes: PhotoTekCodeDescription[] = [
  { code: 0, label: '触发模式' },
  { code: 1, label: '周期模式' },
  { code: 2, label: '整点模式' }
];

/**
 * 根据协议 key 获取保持寄存器定义。
 *
 * @param key PhotoTekHoldRegisterKeys 中定义的寄存器 key。
 * @returns 成功返回寄存器定义；未知 key 返回 null。
 */
export function getPhotoTekHoldRegisterByKey(key: string): PhotoTekHoldRegisterDefinition | null {
  const registerList: PhotoTekHoldRegisterDefinition[] = [
    PhotoTekHoldRegisters.CURRENT_RANGE,
    PhotoTekHoldRegisters.CALIBRATION_CURVE_SLOPE,
    PhotoTekHoldRegisters.CALIBRATION_CURVE_INTERCEPT,
    PhotoTekHoldRegisters.DIGESTION_TEMPERATURE,
    PhotoTekHoldRegisters.DIGESTION_TIME,
    PhotoTekHoldRegisters.REACTION_TEMPERATURE,
    PhotoTekHoldRegisters.REACTION_TIME,
    PhotoTekHoldRegisters.CORRECTION_FACTOR,
    PhotoTekHoldRegisters.MEASUREMENT_CONTROL,
    PhotoTekHoldRegisters.WATER_COLLECTION_CONTROL,
    PhotoTekHoldRegisters.SYSTEM_TIME,
    PhotoTekHoldRegisters.MEASUREMENT_MODE,
    PhotoTekHoldRegisters.AUTO_MEASUREMENT_INTERVAL,
    PhotoTekHoldRegisters.AUTO_CALIBRATION_MODE,
    PhotoTekHoldRegisters.AUTO_CALIBRATION_INTERVAL,
    PhotoTekHoldRegisters.CURRENT_RANGE_DILUTION_FACTOR,
    PhotoTekHoldRegisters.ZERO_CALIBRATION_SOLUTION_CONCENTRATION,
    PhotoTekHoldRegisters.SPAN_CALIBRATION_SOLUTION_CONCENTRATION,
    PhotoTekHoldRegisters.REAGENT_ONE_VOLUME,
    PhotoTekHoldRegisters.REAGENT_TWO_VOLUME,
    PhotoTekHoldRegisters.REAGENT_THREE_VOLUME,
    PhotoTekHoldRegisters.REAGENT_FOUR_VOLUME,
    PhotoTekHoldRegisters.REAGENT_FIVE_VOLUME,
    PhotoTekHoldRegisters.CURRENT_RANGE_CORRECTION_FACTOR,
    PhotoTekHoldRegisters.SPAN_CHECK_ALLOWED_DEVIATION,
    PhotoTekHoldRegisters.SPAN_CHECK_DEVIATION
  ];

  for (const item of registerList) {
    if (item.key === key) {
      return item;
    }
  }
  return null;
}
