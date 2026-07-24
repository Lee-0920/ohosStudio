// lhipstudio/modbus/src/main/ets/model/Types.ets

// 数据类型定义
export interface ModbusRequest {
  slaveId: number;
  functionCode: number;
  startAddress: number;
  quantity: number;
  data?: Uint8Array;
}

export interface ModbusResponse {
  slaveId: number;
  functionCode: number;
  data?: Uint8Array;
  exceptionCode?: number;
}

// Modbus异常码
export enum ModbusExceptionCode {
  ILLEGAL_FUNCTION = 0x01,
  ILLEGAL_DATA_ADDRESS = 0x02,
  ILLEGAL_DATA_VALUE = 0x03,
  SLAVE_DEVICE_FAILURE = 0x04,
  ACKNOWLEDGE = 0x05,
  SLAVE_DEVICE_BUSY = 0x06,
  MEMORY_PARITY_ERROR = 0x08,
  GATEWAY_PATH_UNAVAILABLE = 0x0A,
  GATEWAY_TARGET_FAILED = 0x0B
}

// 寄存器定义
export interface RegisterInfo {
  address: number;      // 偏移地址
  name: string;         // 寄存器名称
  type: DataType;       // 数据类型
  length: number;       // 变量长度(寄存器数量)
  access: 'R' | 'RW';   // 读写权限
  description?: string; // 描述
}

export enum DataType {
  UINT16 = 'UINT16',
  INT16 = 'INT16',
  UINT32 = 'UINT32',
  INT32 = 'INT32',
  FLOAT32 = 'FLOAT32',
  STRING = 'STRING',
  TIME = 'TIME',        // 时间类型: 年(1B)+月(1B)+日(1B)+时(1B)+分(1B)+秒(1B) 实际使用3个寄存器
  FLOAT32_ARRAY = 'FLOAT32_ARRAY'
}

// 时间数据结构
export interface TimeData {
  year: number;   // 年份偏移，如19表示2019
  month: number;  // 1-12
  day: number;    // 1-31
  hour: number;   // 0-23
  minute: number; // 0-59
  second: number; // 0-59
}

// 系统状态枚举
export enum SystemStatus {
  IDLE = 0,
  MEASURING_WATER = 1,
  MEASURING_RANGE_CAL = 2,
  MEASURING_ZERO_CAL = 3,
  CALIBRATING = 4,
  CLEANING_DIGESTION = 5,
  CLEANING_QUANT_TUBE = 6,
  CLEANING_ALL_PIPES = 7,
  COLLECTING_WATER = 8,
  ONE_KEY_RUN = 9,
  DIGESTION_COOLING = 10,
  QUANT_PUMP_CAL = 11,
  PIPE_OPERATION = 12,
  SMART_DIAGNOSIS = 13,
  COMMUNICATION_TEST = 14,
  HARDWARE_TEST = 15,
  FAULT = 255
}

// 当前动作枚举
export enum CurrentAction {
  IDLE = 0,
  PRE_MEASURE_CLEAN = 1,
  READ_INITIAL = 2,
  RINSING = 3,
  ADD_SAMPLE = 4,
  ADD_REAGENT_1 = 5,
  ADD_REAGENT_2 = 6,
  ADD_REAGENT_3 = 7,
  ADD_REAGENT_4 = 8,
  ADD_REAGENT_5 = 9,
  ADD_REAGENT_6 = 10,
  CLEAN_QUANT_TUBE = 11,
  DIGESTION_PREHEAT = 12,
  HEAT_DIGESTION = 13,
  DIGESTION_COOLING = 14,
  READ_REACTION = 15,
  CLEANING = 16,
  COOLING = 17,
  COLLECTING = 18,
  STANDING = 19,
  CALIBRATING = 20
}
// 测量控制操作码
export enum MeasureControl {
  MEASURE_WATER = 0,
  CALIBRATE = 1,
  STOP = 2,
  MEASURE_RANGE_CAL = 3,
  MEASURE_ZERO_CAL = 4,
  CLEAN_QUANT_TUBE = 5,
  CLEAN_DIGESTION = 6,
  DEEP_CLEAN = 7,
  CLEAN_ALL_PIPES = 8,
  COLLECT_WATER = 9,
  QUANT_PUMP_CAL = 10,
  ZERO_CALIBRATE = 13,
  RANGE_CALIBRATE = 14,
  ZERO_CHECK = 20,
  MEASURE_SPAN_CHECK = 21
}

// 诊断结果枚举
export enum DiagnosticResult {
  NORMAL = 0,      // 正常
  IN_PROGRESS = 1, // 进行中
  PASSED = 2,      // 通过
  FAILED = 3,      // 失败
  STOPPED = 4      // 停止
}

// 智能诊断指令操作码
export enum SmartDiagnosisCommand {
  ZERO_CAL_VALVE = 1,      // 零点校准液阀
  WATER_SAMPLE_VALVE = 2,  // 水样阀
  RANGE_CAL_VALVE = 3,     // 量程校准液阀
  ZERO_CHECK_VALVE = 4,    // 零点核查阀
  SPAN_CHECK_VALVE = 5,    // 标样(跨度)核查阀
  REAGENT1_VALVE = 6,      // 试剂一阀
  REAGENT2_VALVE = 7,      // 试剂二阀
  REAGENT3_VALVE = 8,      // 试剂三阀
  REAGENT4_VALVE = 9,      // 试剂四阀
  REAGENT5_VALVE = 10,     // 试剂五阀
  DIGESTION_CHAMBER_VALVE = 11,  // 消解室阀
  ANALYSIS_WASTE_VALVE = 12,     // 分析废液阀
  CLEANING_WASTE_VALVE = 13,     // 清洗废水阀
  QUANT_MODULE = 14,       // 定量模块
  MEASURE_MODULE = 15,     // 测量模块
  HEAT_MODULE = 16,        // 加热模块
  COOL_MODULE = 17         // 冷却模块
}

// 获取智能诊断指令名称
export function getSmartDiagnosisCommandName(command: number): string {
  const commandMap: Map<number, string> = new Map();
  commandMap.set(SmartDiagnosisCommand.ZERO_CAL_VALVE, '零点校准液阀');
  commandMap.set(SmartDiagnosisCommand.WATER_SAMPLE_VALVE, '水样阀');
  commandMap.set(SmartDiagnosisCommand.RANGE_CAL_VALVE, '量程校准液阀');
  commandMap.set(SmartDiagnosisCommand.ZERO_CHECK_VALVE, '零点核查阀');
  commandMap.set(SmartDiagnosisCommand.SPAN_CHECK_VALVE, '标样(跨度)核查阀');
  commandMap.set(SmartDiagnosisCommand.REAGENT1_VALVE, '试剂一阀');
  commandMap.set(SmartDiagnosisCommand.REAGENT2_VALVE, '试剂二阀');
  commandMap.set(SmartDiagnosisCommand.REAGENT3_VALVE, '试剂三阀');
  commandMap.set(SmartDiagnosisCommand.REAGENT4_VALVE, '试剂四阀');
  commandMap.set(SmartDiagnosisCommand.REAGENT5_VALVE, '试剂五阀');
  commandMap.set(SmartDiagnosisCommand.DIGESTION_CHAMBER_VALVE, '消解室阀');
  commandMap.set(SmartDiagnosisCommand.ANALYSIS_WASTE_VALVE, '分析废液阀');
  commandMap.set(SmartDiagnosisCommand.CLEANING_WASTE_VALVE, '清洗废水阀');
  commandMap.set(SmartDiagnosisCommand.QUANT_MODULE, '定量模块');
  commandMap.set(SmartDiagnosisCommand.MEASURE_MODULE, '测量模块');
  commandMap.set(SmartDiagnosisCommand.HEAT_MODULE, '加热模块');
  commandMap.set(SmartDiagnosisCommand.COOL_MODULE, '冷却模块');
  return commandMap.get(command) || `未知指令(${command})`;
}

// 数据标识枚举
export enum DataFlag {
  NORMAL = 'N',
  OVER_UPPER = 'T',
  UNDER_LOWER = 'L',
  POWER_FAULT = 'P',
  DEVICE_FAULT = 'D',
  COMM_FAULT = 'F',
  DEVICE_OFFLINE = 'B',
  NO_WATER_SAMPLE = 'Z',
  MANUAL_INPUT = 'S',
  MAINTENANCE = 'M',
  NON_WATER_SAMPLE = 'C'
}

// 通信日志条目
export interface CommLogEntry {
  id: number;
  timestamp: string;
  direction: 'RECEIVE' | 'SEND';
  protocol: 'RTU' | 'TCP';
  data: string;
  description: string;
}