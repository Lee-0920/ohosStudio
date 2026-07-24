// lhipstudio/modbus/src/main/ets/index.ets

// 模块统一导出入口
export { ModbusServer } from './model/ModbusServer';
export type { TcpConfig, SerialConfig } from './model/ModbusServer';
export { ModbusRTUHandler } from './model/ModbusRTU';
export { ModbusTCPHandler } from './model/ModbusTCP';
export { DataStore } from './model/DataStore';
export { REG_ADDR, REGISTERS } from './model/Registers';
export {
  ProtocolTable,
  Ls40ProtocolTable,
  JsProtocolTable,
  SzbaProtocolTable,
  SurfaceWaterProtocolTable,
  ProtocolTableRegistry,
  ModbusProtocolType
} from './model/ProtocolTable';
export { default as EventBus } from './utils/EventBus';
export * from './model/Types';
export { default as ModbusAbility, getGlobalModbusServer, setGlobalModbusServer } from './ability/ModbusAbility';

// 重新导出串口函数
export { openUart, writeUart, readUartBinary, closeUart, setSerialConfig, flushUart, getUartStatus } from 'libentry.so';
export type { UartStatus } from 'libentry.so';