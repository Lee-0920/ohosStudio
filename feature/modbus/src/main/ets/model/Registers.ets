// lhipstudio/modbus/src/main/ets/model/Registers.ets

import { RegisterInfo, DataType } from './Types';

// 寄存器地址常量接口定义
export interface RegAddrMap {
  // 只读寄存器
  MEASURE_RESULT: number;
  RANGE_CAL_RESULT: number;
  MEASURE_PARAM: number;
  RESULT_TYPE: number;
  MEASURE_DURATION: number;
  MEASURE_TIME: number;
  RANGE_CAL_TIME: number;
  CALIBRATION_TIME: number;
  SYSTEM_STATUS: number;
  CURRENT_ACTION: number;
  CURRENT_TEMP: number;
  ALARM_TIME: number;
  ALARM_CODE: number;
  RANGE_TABLE: number;
  PRODUCT_NAME: number;
  PRODUCT_MODEL: number;
  MANUFACTURER: number;
  SERIAL_NUMBER: number;
  FW_VERSION_LIQUID: number;
  FW_VERSION_TEMP: number;
  FW_VERSION_SIGNAL: number;
  FW_VERSION_MAIN: number;
  FW_VERSION_DRIVER: number;
  FW_VERSION_REACTION: number;
  SPAN_CHECK_SET: number;
  SPAN_CHECK_RESULT: number;
  SPAN_CHECK_TIME: number;
  SPAN_CHECK_INTERVAL: number;
  WATER_ABSORBANCE: number;
  WATER_DATA_FLAG: number;
  RANGE_CAL_ABSORBANCE: number;
  RANGE_CAL_DATA_FLAG: number;
  CHECK_ABSORBANCE: number;
  CHECK_DATA_FLAG: number;
  ZERO_CAL_TIME: number;
  ZERO_CAL_CONC: number;
  ZERO_CAL_ABSORBANCE: number;
  ZERO_DRIFT: number;
  RANGE_CAL_START_TIME: number;
  CAL_STANDARD_CONC: number;
  CAL_STANDARD_ABSORBANCE: number;
  RANGE_DRIFT: number;
  COMPOSITE_RESULT: number;
  COMPOSITE_TIME: number;
  COMPOSITE_DATA_FLAG: number;
  COEFF_CONST: number;
  COEFF_RATIO: number;
  FLOW_CONTROL: number;
  TOC_RESULT: number;
  // 读写寄存器
  CURRENT_RANGE_INDEX: number;
  CURRENT_RANGE_LOWER: number;
  CURRENT_RANGE: number;
  CAL_SLOPE: number;
  CAL_INTERCEPT: number;
  DIGESTION_TEMP: number;
  DIGESTION_TIME: number;
  REACTION_TEMP: number;
  REACTION_TIME: number;
  CORRECT_SLOPE: number;
  CORRECT_INTERCEPT: number;
  MEASURE_CONTROL: number;
  WATER_COLLECT: number;
  SYSTEM_TIME: number;
  MEASURE_MODE: number;
  AUTO_MEASURE_INTERVAL: number;
  AUTO_CAL_MODE: number;
  AUTO_CAL_INTERVAL: number;
  DILUTION_FACTOR: number;
  ZERO_CAL_CONCENTRATION: number;
  RANGE_CAL_CONCENTRATION: number;
  REAGENT1_VOLUME: number;
  REAGENT2_VOLUME: number;
  REAGENT3_VOLUME: number;
  REAGENT4_VOLUME: number;
  REAGENT5_VOLUME: number;
  CALIBRATION_FACTOR: number;
  CHECK_ALLOW_DEVIATION: number;
  CHECK_DEVIATION: number;
  DEVICE_UNIQUE_ID: number;
  SYSTEM_RANGE_TABLE: number;
  ZERO_CAL_TABLE: number;
  RANGE_CAL_TABLE: number;
  SMART_DIAG_CMD: number;
  SMART_DIAG_RESULT: number;
  DIGESTION_ROOM_TEMP: number;
  AMBIENT_TEMP: number;
  QUANT_POINT1_SIGNAL: number;
  QUANT_POINT2_SIGNAL: number;
  REFERENCE_AD_SIGNAL: number;
  MEASURE_AD_SIGNAL: number;
  PUMP_TUBE_COEFF: number;
  LOG_COUNT: number;
  LOG_CONTENT: number;
}

// 寄存器地址常量定义
export const REG_ADDR: RegAddrMap = {
  // ==================== 只读寄存器 ====================
  MEASURE_RESULT: 0,           // 测量结果 (FLOAT32)
  RANGE_CAL_RESULT: 2,         // 测量程校准液结果 (FLOAT32)
  MEASURE_PARAM: 4,            // 测量参数 (UINT16)
  RESULT_TYPE: 5,              // 测试结果类型 (UINT16)
  MEASURE_DURATION: 6,         // 测量时长 (UINT16)
  MEASURE_TIME: 7,             // 测量时间 (TIME)
  RANGE_CAL_TIME: 10,          // 测量程校准液时间 (TIME)
  CALIBRATION_TIME: 13,        // 校准时间 (TIME)
  SYSTEM_STATUS: 16,           // 系统状态 (UINT16)
  CURRENT_ACTION: 17,          // 当前动作 (UINT16)
  CURRENT_TEMP: 18,            // 当前温度 (FLOAT32)
  ALARM_TIME: 22,              // 报警时间 (TIME)
  ALARM_CODE: 25,              // 报警代码 (UINT16)
  RANGE_TABLE: 26,             // 量程表 (FLOAT32_ARRAY, 6个)
  PRODUCT_NAME: 36,            // 产品名称 (STRING, 32个寄存器)
  PRODUCT_MODEL: 68,           // 产品型号 (STRING, 32个寄存器)
  MANUFACTURER: 100,           // 生产厂商 (STRING, 32个寄存器)
  SERIAL_NUMBER: 132,          // 生产序列号 (STRING, 16个寄存器)
  FW_VERSION_LIQUID: 148,      // 液路板固件版本 (UINT32)
  FW_VERSION_TEMP: 150,        // 温控板固件版本 (UINT32)
  FW_VERSION_SIGNAL: 152,      // 信号板固件版本 (UINT32)
  FW_VERSION_MAIN: 154,        // 主控板固件版本 (UINT32)
  FW_VERSION_DRIVER: 156,      // 驱动板固件版本 (UINT32)
  FW_VERSION_REACTION: 158,    // 反应板固件版本 (UINT32)
  SPAN_CHECK_SET: 163,         // 跨度核查设置浓度 (FLOAT32)
  SPAN_CHECK_RESULT: 165,      // 跨度核查结果 (FLOAT32)
  SPAN_CHECK_TIME: 167,        // 跨度核查时间 (TIME)
  SPAN_CHECK_INTERVAL: 170,    // 跨度核查间隔 (UINT16, RW)
  WATER_ABSORBANCE: 190,       // 水样吸光度 (FLOAT32)
  WATER_DATA_FLAG: 192,        // 水样数据标识 (UINT16)
  RANGE_CAL_ABSORBANCE: 193,   // 测量程校准液吸光度 (FLOAT32)
  RANGE_CAL_DATA_FLAG: 195,    // 测量程校准液数据标识 (UINT16)
  CHECK_ABSORBANCE: 199,       // 核查液吸光度 (FLOAT32)
  CHECK_DATA_FLAG: 201,        // 核查液数据标识 (UINT16)
  ZERO_CAL_TIME: 217,          // 零点校准时间 (TIME)
  ZERO_CAL_CONC: 220,          // 校准零点浓度 (FLOAT32)
  ZERO_CAL_ABSORBANCE: 222,    // 校准零点吸光度 (FLOAT32)
  ZERO_DRIFT: 224,             // 零点漂移 (FLOAT32)
  RANGE_CAL_START_TIME: 227,   // 量程校准开始时间 (TIME)
  CAL_STANDARD_CONC: 230,      // 校准标点浓度 (FLOAT32)
  CAL_STANDARD_ABSORBANCE: 232, // 校准标点吸光度 (FLOAT32)
  RANGE_DRIFT: 234,            // 量程漂移 (FLOAT32)
  COMPOSITE_RESULT: 236,       // 复合测量结果 (FLOAT32)
  COMPOSITE_TIME: 238,         // 复合结果时间 (TIME)
  COMPOSITE_DATA_FLAG: 241,    // 复合测量数据标识 (UINT16)
  COEFF_CONST: 242,            // 系数常数 (FLOAT32)
  COEFF_RATIO: 244,            // 系数比例 (FLOAT32)
  FLOW_CONTROL: 246,           // 流量控制 (FLOAT32)
  TOC_RESULT: 248,             // TOC测量结果 (FLOAT32)

  // ==================== 读写寄存器 ====================
  CURRENT_RANGE_INDEX: 253,    // 当前量程索引 (UINT16, RW)
  CURRENT_RANGE_LOWER: 254,    // 当前量程下限值 (FLOAT32)
  CURRENT_RANGE: 256,          // 当前量程 (FLOAT32, RW)
  CAL_SLOPE: 258,              // 校准曲线斜率 (FLOAT32, RW)
  CAL_INTERCEPT: 260,          // 校准曲线截距 (FLOAT32, RW)
  DIGESTION_TEMP: 262,         // 消解温度 (FLOAT32, RW)
  DIGESTION_TIME: 264,         // 消解时间 (UINT16, RW)
  REACTION_TEMP: 265,          // 反应温度 (FLOAT32, RW)
  REACTION_TIME: 267,          // 反应时间 (UINT16, RW)
  CORRECT_SLOPE: 268,          // 修正斜率 (FLOAT32, RW)
  CORRECT_INTERCEPT: 270,      // 修正截距 (FLOAT32, RW)
  MEASURE_CONTROL: 272,        // 测量控制 (UINT16, W)
  WATER_COLLECT: 273,          // 采水控制 (UINT16, W)
  SYSTEM_TIME: 274,            // 系统时间 (TIME, RW)
  MEASURE_MODE: 277,           // 自动测量模式 (UINT16, RW)
  AUTO_MEASURE_INTERVAL: 278,  // 自动测量时间间隔 (UINT16, RW)
  AUTO_CAL_MODE: 279,          // 自动校准模式 (UINT16, RW)
  AUTO_CAL_INTERVAL: 280,      // 自动校准时间间隔 (UINT16, RW)
  DILUTION_FACTOR: 283,        // 当前量程稀释倍数 (FLOAT32)
  ZERO_CAL_CONCENTRATION: 293, // 零点校准液浓度 (FLOAT32)
  RANGE_CAL_CONCENTRATION: 295, // 量程校准液浓度 (FLOAT32)
  REAGENT1_VOLUME: 300,        // 试剂一加液体积 (FLOAT32)
  REAGENT2_VOLUME: 302,        // 试剂二加液体积 (FLOAT32)
  REAGENT3_VOLUME: 304,        // 试剂三加液体积 (FLOAT32)
  REAGENT4_VOLUME: 306,        // 试剂四加液体积 (FLOAT32)
  REAGENT5_VOLUME: 308,        // 试剂五加液体积 (FLOAT32)
  CALIBRATION_FACTOR: 310,     // 当前量程校正因子 (FLOAT32)
  CHECK_ALLOW_DEVIATION: 312,  // 核查允许偏差值 (FLOAT32)
  CHECK_DEVIATION: 314,        // 核查偏差值 (FLOAT32)
  DEVICE_UNIQUE_ID: 316,       // 设备唯一标识 (STRING, 24个寄存器)
  SYSTEM_RANGE_TABLE: 340,     // 量程上限浓度表 (FLOAT32_ARRAY, 20个)
  ZERO_CAL_TABLE: 360,         // 零点校准液浓度表 (FLOAT32_ARRAY, 20个)
  RANGE_CAL_TABLE: 380,        // 量程校准液浓度表 (FLOAT32_ARRAY, 20个)
  SMART_DIAG_CMD: 400,         // 智能诊断指令 (UINT16, RW)
  SMART_DIAG_RESULT: 401,      // 智能诊断结果 (UINT16)
  DIGESTION_ROOM_TEMP: 402,    // 消解室温度 (FLOAT32)
  AMBIENT_TEMP: 404,           // 环境温度 (FLOAT32)
  QUANT_POINT1_SIGNAL: 406,    // 定量点1信号 (UINT32)
  QUANT_POINT2_SIGNAL: 408,    // 定量点2信号 (UINT32)
  REFERENCE_AD_SIGNAL: 410,    // 参考AD信号 (UINT32)
  MEASURE_AD_SIGNAL: 412,      // 测量AD信号 (UINT32)
  PUMP_TUBE_COEFF: 414,        // 泵管系数 (FLOAT32)
  LOG_COUNT: 500,              // 日志条数 (UINT16)
  LOG_CONTENT: 501             // 日志 (STRING, 99个寄存器)
};

// 寄存器映射表
export const REGISTERS: Map<number, RegisterInfo> = new Map();

// 初始化寄存器定义
function initRegisters(): void {
  // ==================== 只读寄存器 (R) ====================
  addRegister(REG_ADDR.MEASURE_RESULT, '测量结果', DataType.FLOAT32, 2, 'R', '上一次测量的结果，单位（mg/L）');
  addRegister(REG_ADDR.RANGE_CAL_RESULT, '测量程校准液结果', DataType.FLOAT32, 2, 'R', '上一次测量程校准液的结果，单位（mg/L）');
  addRegister(REG_ADDR.MEASURE_PARAM, '测量参数', DataType.UINT16, 1, 'R', '仪器当前测试的水质参数');
  addRegister(REG_ADDR.RESULT_TYPE, '测试结果类型', DataType.UINT16, 1, 'R', '测试结果类型寄存器值说明');
  addRegister(REG_ADDR.MEASURE_DURATION, '测量时长', DataType.UINT16, 1, 'R', '上一次测量所花的时间，单位为秒');
  addRegister(REG_ADDR.MEASURE_TIME, '测量时间', DataType.TIME, 3, 'R', '上一次测量的时间');
  addRegister(REG_ADDR.RANGE_CAL_TIME, '测量程校准液时间', DataType.TIME, 3, 'R', '上一次测量程校准液结果的测量时间');
  addRegister(REG_ADDR.CALIBRATION_TIME, '校准时间', DataType.TIME, 3, 'R', '上一次校准时间');
  addRegister(REG_ADDR.SYSTEM_STATUS, '系统状态', DataType.UINT16, 1, 'R', '系统状态');
  addRegister(REG_ADDR.CURRENT_ACTION, '当前动作', DataType.UINT16, 1, 'R', '当前动作');
  addRegister(REG_ADDR.CURRENT_TEMP, '当前温度', DataType.FLOAT32, 2, 'R', '当前消解室温度，单位℃');
  addRegister(REG_ADDR.ALARM_TIME, '报警时间', DataType.TIME, 3, 'R', '报警发生时的时间');
  addRegister(REG_ADDR.ALARM_CODE, '报警代码', DataType.UINT16, 1, 'R', '报警代码');
  addRegister(REG_ADDR.RANGE_TABLE, '量程表', DataType.FLOAT32_ARRAY, 6, 'R', '预设的量程（上限）表');
  addRegister(REG_ADDR.PRODUCT_NAME, '产品名称', DataType.STRING, 32, 'R', '产品名称');
  addRegister(REG_ADDR.PRODUCT_MODEL, '产品型号', DataType.STRING, 32, 'R', '产品型号');
  addRegister(REG_ADDR.MANUFACTURER, '生产厂商', DataType.STRING, 32, 'R', '生产厂商');
  addRegister(REG_ADDR.SERIAL_NUMBER, '生产序列号', DataType.STRING, 16, 'R', '生产序列号');
  addRegister(REG_ADDR.FW_VERSION_LIQUID, '液路板固件版本', DataType.UINT32, 2, 'R', '液路板固件版本');
  addRegister(REG_ADDR.FW_VERSION_TEMP, '温控板固件版本', DataType.UINT32, 2, 'R', '温控板固件版本');
  addRegister(REG_ADDR.FW_VERSION_SIGNAL, '信号板固件版本', DataType.UINT32, 2, 'R', '信号板固件版本');
  addRegister(REG_ADDR.FW_VERSION_MAIN, '主控板固件版本', DataType.UINT32, 2, 'R', '主控板固件版本');
  addRegister(REG_ADDR.FW_VERSION_DRIVER, '驱动板固件版本', DataType.UINT32, 2, 'R', '驱动板固件版本');
  addRegister(REG_ADDR.FW_VERSION_REACTION, '反应板固件版本', DataType.UINT32, 2, 'R', '反应板固件版本');
  addRegister(REG_ADDR.SPAN_CHECK_SET, '跨度核查设置浓度', DataType.FLOAT32, 2, 'R', '跨度(标样)核查设置浓度');
  addRegister(REG_ADDR.SPAN_CHECK_RESULT, '跨度核查结果', DataType.FLOAT32, 2, 'R', '跨度(标样)核查结果浓度');
  addRegister(REG_ADDR.SPAN_CHECK_TIME, '跨度核查时间', DataType.TIME, 3, 'R', '跨度(标样)核查的时间');
  addRegister(REG_ADDR.SPAN_CHECK_INTERVAL, '跨度核查间隔', DataType.UINT16, 1, 'RW', '跨度(标样)核查的间隔周期，单位：小时');
  addRegister(REG_ADDR.WATER_ABSORBANCE, '水样吸光度', DataType.FLOAT32, 2, 'R', '水样测量过程原始吸光度值');
  addRegister(REG_ADDR.WATER_DATA_FLAG, '水样数据标识', DataType.UINT16, 1, 'R', '测量结果的数据标识');
  addRegister(REG_ADDR.RANGE_CAL_ABSORBANCE, '测量程校准液吸光度', DataType.FLOAT32, 2, 'R', '量程校准液测量过程原始吸光度值');
  addRegister(REG_ADDR.RANGE_CAL_DATA_FLAG, '测量程校准液数据标识', DataType.UINT16, 1, 'R', '量程校准液数据标识');
  addRegister(REG_ADDR.CHECK_ABSORBANCE, '核查液吸光度', DataType.FLOAT32, 2, 'R', '核查液测量过程原始吸光度值');
  addRegister(REG_ADDR.CHECK_DATA_FLAG, '核查液数据标识', DataType.UINT16, 1, 'R', '核查液数据标识');
  addRegister(REG_ADDR.ZERO_CAL_TIME, '零点校准时间', DataType.TIME, 3, 'R', '零点校准时间');
  addRegister(REG_ADDR.ZERO_CAL_CONC, '校准零点浓度', DataType.FLOAT32, 2, 'R', '校准校零浓度');
  addRegister(REG_ADDR.ZERO_CAL_ABSORBANCE, '校准零点吸光度', DataType.FLOAT32, 2, 'R', '校准零点的原始测量吸光度值');
  addRegister(REG_ADDR.ZERO_DRIFT, '零点漂移', DataType.FLOAT32, 2, 'R', '仪器24小时零点漂移，单位:%');
  addRegister(REG_ADDR.RANGE_CAL_START_TIME, '量程校准开始时间', DataType.TIME, 3, 'R', '量程校准开始时间');
  addRegister(REG_ADDR.CAL_STANDARD_CONC, '校准标点浓度', DataType.FLOAT32, 2, 'R', '校准校标浓度');
  addRegister(REG_ADDR.CAL_STANDARD_ABSORBANCE, '校准标点吸光度', DataType.FLOAT32, 2, 'R', '校准标点的原始测量吸光度值');
  addRegister(REG_ADDR.RANGE_DRIFT, '量程漂移', DataType.FLOAT32, 2, 'R', '仪器24小时量程漂移，单位:%');
  addRegister(REG_ADDR.COMPOSITE_RESULT, '复合测量结果', DataType.FLOAT32, 2, 'R', '最新水样、空白、标样等测量的结果');
  addRegister(REG_ADDR.COMPOSITE_TIME, '复合结果时间', DataType.TIME, 3, 'R', '各类测量结果的时间');
  addRegister(REG_ADDR.COMPOSITE_DATA_FLAG, '复合测量数据标识', DataType.UINT16, 1, 'R', '复合测量结果的数据标识');
  addRegister(REG_ADDR.COEFF_CONST, '系数常数', DataType.FLOAT32, 2, 'R', 'TOC因子转换系数常数');
  addRegister(REG_ADDR.COEFF_RATIO, '系数比例', DataType.FLOAT32, 2, 'R', 'TOC因子转换系数比例');
  addRegister(REG_ADDR.FLOW_CONTROL, '流量控制', DataType.FLOAT32, 2, 'R', 'TOC因子流量，单位ml/min');
  addRegister(REG_ADDR.TOC_RESULT, 'TOC测量结果', DataType.FLOAT32, 2, 'R', 'TOC测量结果，单位mg/L');

  // ==================== 读写寄存器 (RW) ====================
  addRegister(REG_ADDR.CURRENT_RANGE_INDEX, '当前量程索引', DataType.UINT16, 1, 'RW', '当前工作量程序号');
  addRegister(REG_ADDR.CURRENT_RANGE_LOWER, '当前量程下限值', DataType.FLOAT32, 2, 'R', '当前使用的量程下限值');
  addRegister(REG_ADDR.CURRENT_RANGE, '当前量程', DataType.FLOAT32, 2, 'RW', '当前使用的量程上限值');
  addRegister(REG_ADDR.CAL_SLOPE, '校准曲线斜率', DataType.FLOAT32, 2, 'RW', '校准曲线斜率');
  addRegister(REG_ADDR.CAL_INTERCEPT, '校准曲线截距', DataType.FLOAT32, 2, 'RW', '校准曲线截距');
  addRegister(REG_ADDR.DIGESTION_TEMP, '消解温度', DataType.FLOAT32, 2, 'RW', '单位：℃');
  addRegister(REG_ADDR.DIGESTION_TIME, '消解时间', DataType.UINT16, 1, 'RW', '单位：秒');
  addRegister(REG_ADDR.REACTION_TEMP, '反应温度', DataType.FLOAT32, 2, 'RW', '单位：℃');
  addRegister(REG_ADDR.REACTION_TIME, '反应时间', DataType.UINT16, 1, 'RW', '单位：秒');
  addRegister(REG_ADDR.CORRECT_SLOPE, '修正斜率', DataType.FLOAT32, 2, 'RW', '用于结果计算的修正系数');
  addRegister(REG_ADDR.CORRECT_INTERCEPT, '修正截距', DataType.FLOAT32, 2, 'RW', '用于结果计算的修正截距');
  addRegister(REG_ADDR.MEASURE_CONTROL, '测量控制', DataType.UINT16, 1, 'RW', '测量控制操作码');
  addRegister(REG_ADDR.WATER_COLLECT, '采水控制', DataType.UINT16, 1, 'RW', '采水控制');
  addRegister(REG_ADDR.SYSTEM_TIME, '系统时间', DataType.TIME, 3, 'RW', '系统时间');
  addRegister(REG_ADDR.MEASURE_MODE, '测量模式', DataType.UINT16, 1, 'RW', '测量模式');
  addRegister(REG_ADDR.AUTO_MEASURE_INTERVAL, '自动测量时间间隔', DataType.UINT16, 1, 'RW', '水样周期测量间隔，小时');
  addRegister(REG_ADDR.AUTO_CAL_MODE, '自动校准模式', DataType.UINT16, 1, 'RW', '自动校准模式');
  addRegister(REG_ADDR.AUTO_CAL_INTERVAL, '自动校准时间间隔', DataType.UINT16, 1, 'RW', '自动校准时间间隔，小时');
  addRegister(REG_ADDR.DILUTION_FACTOR, '当前量程稀释倍数', DataType.FLOAT32, 2, 'R', '当前量程对应的稀释倍数');
  addRegister(REG_ADDR.ZERO_CAL_CONCENTRATION, '零点校准液浓度', DataType.FLOAT32, 2, 'R', '当前零点校准浓度');
  addRegister(REG_ADDR.RANGE_CAL_CONCENTRATION, '量程校准液浓度', DataType.FLOAT32, 2, 'R', '当前量程校准浓度');
  addRegister(REG_ADDR.REAGENT1_VOLUME, '试剂一加液体积', DataType.FLOAT32, 2, 'R', '加试剂一的体积，单位mL');
  addRegister(REG_ADDR.REAGENT2_VOLUME, '试剂二加液体积', DataType.FLOAT32, 2, 'R', '加试剂二的体积，单位mL');
  addRegister(REG_ADDR.REAGENT3_VOLUME, '试剂三加液体积', DataType.FLOAT32, 2, 'R', '加试剂三的体积，单位mL');
  addRegister(REG_ADDR.REAGENT4_VOLUME, '试剂四加液体积', DataType.FLOAT32, 2, 'R', '加试剂四的体积，单位mL');
  addRegister(REG_ADDR.REAGENT5_VOLUME, '试剂五加液体积', DataType.FLOAT32, 2, 'R', '加试剂五的体积，单位mL');
  addRegister(REG_ADDR.CALIBRATION_FACTOR, '当前量程校正因子', DataType.FLOAT32, 2, 'R', '当前量程自动生成标线使用的校正因子');
  addRegister(REG_ADDR.CHECK_ALLOW_DEVIATION, '核查允许偏差值', DataType.FLOAT32, 2, 'R', '单位：%');
  addRegister(REG_ADDR.CHECK_DEVIATION, '核查偏差值', DataType.FLOAT32, 2, 'R', '单位：%');
  addRegister(REG_ADDR.DEVICE_UNIQUE_ID, '设备唯一标识', DataType.STRING, 24, 'R', '设备唯一标识');
  addRegister(REG_ADDR.SYSTEM_RANGE_TABLE, '量程表_系统支持', DataType.FLOAT32_ARRAY, 20, 'R', '系统支持的量程表');
  addRegister(REG_ADDR.ZERO_CAL_TABLE, '零点校准液浓度表', DataType.FLOAT32_ARRAY, 20, 'R', '零点校准液浓度表');
  addRegister(REG_ADDR.RANGE_CAL_TABLE, '量程校准液浓度表', DataType.FLOAT32_ARRAY, 20, 'R', '量程校准液浓度表');
  addRegister(REG_ADDR.SMART_DIAG_CMD, '智能诊断指令', DataType.UINT16, 1, 'RW', '智能诊断指令');
  addRegister(REG_ADDR.SMART_DIAG_RESULT, '智能诊断结果', DataType.UINT16, 1, 'R', '智能诊断结果');
  addRegister(REG_ADDR.DIGESTION_ROOM_TEMP, '消解室温度', DataType.FLOAT32, 2, 'R', '消解室实时温度');
  addRegister(REG_ADDR.AMBIENT_TEMP, '环境温度', DataType.FLOAT32, 2, 'R', '环境实时温度');
  addRegister(REG_ADDR.QUANT_POINT1_SIGNAL, '定量点1信号', DataType.UINT16, 1, 'R', '定量点1实时信号');
  addRegister(REG_ADDR.QUANT_POINT2_SIGNAL, '定量点2信号', DataType.UINT16, 1, 'R', '定量点2实时信号');
  addRegister(REG_ADDR.REFERENCE_AD_SIGNAL, '参考AD信号', DataType.UINT16, 1, 'R', '参考AD信号');
  addRegister(REG_ADDR.MEASURE_AD_SIGNAL, '测量AD信号', DataType.UINT16, 1, 'R', '测量AD信号');
  addRegister(REG_ADDR.PUMP_TUBE_COEFF, '泵管系数', DataType.FLOAT32, 2, 'R', '泵系数，单位:ml/step');
  addRegister(REG_ADDR.LOG_COUNT, '日志条数', DataType.UINT16, 1, 'R', '当前日志条数');
  addRegister(REG_ADDR.LOG_CONTENT, '日志', DataType.STRING, 99, 'R', '日志内容');
}

function addRegister(address: number, name: string, type: DataType, length: number, access: 'R' | 'RW', description?: string): void {
  REGISTERS.set(address, {
    address,
    name,
    type,
    length,
    access,
    description
  });
}

// 执行初始化
initRegisters();