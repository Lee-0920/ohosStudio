// lhipstudio/modbus/Index.d.ts

import { UIAbility } from "@kit.AbilityKit";

// ==================== 配置接口 ====================
export interface TcpConfig {
  address: string;
  port: number;
}

export interface SerialConfig {
  path: string;
  baudRate: number;
  dataBits: number;
  stopBits: number;
  parity: number;
}

// ==================== ModbusServer 类 ====================
export declare class ModbusServer {
  constructor();

  // 日志回调
  setLogCallback(callback: (log: CommLogEntry) => void): void;

  // TCP 配置
  setTcpConfig(config: TcpConfig): void;
  getTcpConfig(): TcpConfig;
  applyTcpConfig(): Promise<boolean>;

  // 串口配置
  setSerialConfig(config: SerialConfig): void;
  getSerialConfig(): SerialConfig;
  applySerialConfig(): boolean;

  // TCP 服务器
  initTCPServer(port: number): Promise<boolean>;
  sendToAllTcpClients(data: Uint8Array): number;
  sendToTcpClient(clientKey: string, data: Uint8Array): boolean;
  getTcpClientList(): string[];
  getTCPClientCount(): number;
  getTCPConnectionCount(): number;
  getTCPConnections(): string[];
  getTcpServerRunning(): boolean;

  // 串口
  initSerialPort(devicePath: string): Promise<boolean>;
  sendSerialData(data: Uint8Array): boolean;
  isSerialOpened(): boolean;
  getSerialStatus(): boolean;
  flushSerialBuffer(): boolean;

  // 数据存储
  getDataStore(): DataStore;

  // 协议表切换
  setProtocolTable(name: string): void;
  getProtocolTable(): string;

  // 关闭
  shutdown(): Promise<void>;
}

// ==================== ModbusRTUHandler 类 ====================
export declare class ModbusRTUHandler {
  constructor();
  setLogCallback(callback: (log: CommLogEntry) => void): void;
  parseRequest(buffer: Uint8Array): ModbusRequest | null;
  processRequest(request: ModbusRequest): Promise<Uint8Array | null>;
}

// ==================== ModbusTCPHandler 类 ====================
export declare class ModbusTCPHandler {
  constructor();
  setLogCallback(callback: (log: CommLogEntry) => void): void;
  setSendCallback(callback: (response: Uint8Array) => void): void;
  parseRequest(buffer: Uint8Array): ParseResult;
  processRequest(request: ModbusRequest, transactionId: number, protocolId: number, unitId: number): Promise<void>;
}

// ==================== DataStore 类 ====================
export declare class DataStore {
  static getInstance(): DataStore;
  readRegister(address: number, quantity: number): Uint8Array | null;
  writeRegister(address: number, data: Uint8Array): boolean;
  getRegisterInfo(address: number): RegisterInfo | undefined;
  setFloat32(address: number, value: number): void;
  getFloat32(address: number): number;
  setUInt16(address: number, value: number): void;
  getUInt16(address: number): number;
}

// ==================== 常量 ====================
export declare const REG_ADDR: RegAddrMap;
export declare const REGISTERS: Map<number, RegisterInfo>;

// ==================== 协议表抽象 ====================
export declare type ModbusProtocolType =
  | 'LS4.0'
  | 'LS1.0'
  | 'LS2.0'
  | 'JS'
  | 'SZBA'
  | '地表水1.0'
  | 'SC'
  | '西宁动态管控'
  | 'GZ'
  | 'JX'
  | 'XiAn'
  | 'YC';

export interface ProtocolTable {
  readonly name: ModbusProtocolType;
  getRegisterInfo(externalAddress: number, functionCode?: number): RegisterInfo | undefined;
  toInternalAddress(externalAddress: number, functionCode?: number): number;
  toExternalAddress(internalAddress: number, functionCode?: number): number;
}

export declare class Ls40ProtocolTable implements ProtocolTable {
  readonly name: ModbusProtocolType;
  getRegisterInfo(externalAddress: number, functionCode?: number): RegisterInfo | undefined;
  toInternalAddress(externalAddress: number, functionCode?: number): number;
  toExternalAddress(internalAddress: number, functionCode?: number): number;
}

export declare class OffsetProtocolTable implements ProtocolTable {
  readonly name: ModbusProtocolType;
  constructor(name: ModbusProtocolType, inputBase: number, holdingBase: number);
  getRegisterInfo(externalAddress: number, functionCode?: number): RegisterInfo | undefined;
  toInternalAddress(externalAddress: number, functionCode?: number): number;
  toExternalAddress(internalAddress: number, functionCode?: number): number;
}

export declare class Ls10ProtocolTable extends OffsetProtocolTable {
  readonly name: ModbusProtocolType;
  constructor();
}

export declare class Ls20ProtocolTable extends Ls40ProtocolTable {
  readonly name: ModbusProtocolType;
}

export declare class JsProtocolTable extends OffsetProtocolTable {
  readonly name: ModbusProtocolType;
  constructor();
}

export declare class SzbaProtocolTable extends Ls40ProtocolTable {
  readonly name: ModbusProtocolType;
}

export declare class SurfaceWaterProtocolTable extends OffsetProtocolTable {
  readonly name: ModbusProtocolType;
  constructor();
}

export declare class ScProtocolTable extends Ls40ProtocolTable {
  readonly name: ModbusProtocolType;
}

export declare class XnProtocolTable extends Ls40ProtocolTable {
  readonly name: ModbusProtocolType;
}

export declare class GzProtocolTable extends OffsetProtocolTable {
  readonly name: ModbusProtocolType;
  constructor();
}

export declare class JxProtocolTable extends OffsetProtocolTable {
  readonly name: ModbusProtocolType;
  constructor();
}

export declare class XianProtocolTable extends OffsetProtocolTable {
  readonly name: ModbusProtocolType;
  constructor();
}

export declare class YcProtocolTable extends Ls40ProtocolTable {
  readonly name: ModbusProtocolType;
}

export declare class ProtocolTableRegistry {
  static register(table: ProtocolTable): void;
  static get(name: string): ProtocolTable;
  static getDefault(): ProtocolTable;
  static getAllNames(): string[];
  static isRegistered(name: string): boolean;
}

// ==================== EventBus 类 ====================
export declare class EventBus {
  static getInstance(): EventBus;
  onLog(callback: (log: CommLogEntry) => void): void;
  offLog(callback: (log: CommLogEntry) => void): void;
  emitLog(log: CommLogEntry): void;
}

// ==================== ModbusAbility 类 ====================
export declare class ModbusAbility extends UIAbility {
  startModbusServer(): Promise<void>;
}

// ==================== 全局实例获取函数 ====================
export declare function getGlobalModbusServer(): ModbusServer | null;
export declare function setGlobalModbusServer(server: ModbusServer | null): void;

// ==================== 接口类型 ====================
export interface CommLogEntry {
  id: number;
  timestamp: string;
  direction: 'RECEIVE' | 'SEND';
  protocol: 'RTU' | 'TCP';
  data: string;
  description: string;
}

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

export interface RegisterInfo {
  address: number;
  name: string;
  type: DataType;
  length: number;
  access: 'R' | 'RW';
  description?: string;
}

export interface ParseResult {
  request: ModbusRequest | null;
  transactionId: number;
  protocolId: number;
  unitId: number;
}

export interface TimeData {
  year: number;
  month: number;
  day: number;
  hour: number;
  minute: number;
  second: number;
}

export interface RegAddrMap {
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

// ==================== 枚举类型 ====================
export enum DataType {
  UINT16 = 'UINT16',
  INT16 = 'INT16',
  UINT32 = 'UINT32',
  INT32 = 'INT32',
  FLOAT32 = 'FLOAT32',
  STRING = 'STRING',
  TIME = 'TIME',
  FLOAT32_ARRAY = 'FLOAT32_ARRAY'
}

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
  MASTER_UPDATE = 16,
  LIQUID_BOARD_UPDATE = 17,
  TEMP_CTRL_UPDATE = 18,
  SIGNAL_BOARD_UPDATE = 19,
  REACTION_BOARD_UPDATE = 20,
  DRIVE_BOARD_UPDATE = 21,
  DEEP_CLEANING = 22,
  COMBINE_OPERATION = 28,
  ZERO_CALIBRATE = 29,
  RANGE_CALIBRATE = 30,
  QUALITY_CONTROL = 33,
  CHECK_SOLUTION = 41,
  METER_AD_ADJUST = 44,
  MEASURE_AD_ADJUST = 45,
  ONE_KEY_RENEW = 46,
  FAULT = 255
}

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
  CALIBRATING = 20,
  FILL_BLANK = 21,
  DRAIN_BLANK = 22,
  FILL_SAMPLE = 23,
  DRAIN_SAMPLE = 24,
  FILL_STANDARD = 25,
  DRAIN_STANDARD = 26,
  FILL_REAGENT_1 = 27,
  DRAIN_REAGENT_1 = 28,
  FILL_REAGENT_2 = 29,
  DRAIN_REAGENT_2 = 30,
  FILL_REAGENT_3 = 31,
  DRAIN_REAGENT_3 = 32,
  FILL_REAGENT_4 = 33,
  DRAIN_REAGENT_4 = 34,
  FILL_REAGENT_5 = 35,
  DRAIN_REAGENT_5 = 36,
  FILL_REAGENT_6 = 37,
  DRAIN_REAGENT_6 = 38
}

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

export declare const MODBUS_CONTROL_COMMAND_EVENT: string;

export interface ModbusControlCommandEventData {
  commandId: string;
  sourceAddress: number;
  value: number;
}

export enum DiagnosticResult {
  NORMAL = 0,
  IN_PROGRESS = 1,
  PASSED = 2,
  FAILED = 3,
  STOPPED = 4
}

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

// ==================== 串口原生接口 ====================
export declare function openUart(devicePath?: string): boolean;
export declare function closeUart(): void;
export declare function writeUart(data: string | Uint8Array): boolean;
export declare function readUart(): string;
export declare function readUartBinary(): ArrayBuffer;
export declare function setSerialConfig(config: { baudRate: number; dataBits: number; stopBits: number; parity: number }): boolean;
export declare function flushUart(): boolean;
export declare function getUartStatus(): UartStatus;

export interface UartStatus {
  isOpened: boolean;
  fd: number;
}