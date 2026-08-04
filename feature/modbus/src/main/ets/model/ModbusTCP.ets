// lhipstudio/modbus/src/main/ets/model/ModbusTCP.ets

import { systemDateTime, emitter } from '@kit.BasicServicesKit';
import {
  ModbusRequest,
  ModbusExceptionCode,
  CommLogEntry,
  DataFlag,
  MeasureControl,
  DiagnosticResult,
  MODBUS_CONTROL_COMMAND_EVENT,
  ModbusControlCommandEventData
} from './Types';
import { DataStore } from './DataStore';
import { REG_ADDR } from './Registers';
import { ProtocolTable, ProtocolTableRegistry } from './ProtocolTable';
import { SettingsManager, MeasureStatusManager, ManufactureType, Language, ReportMode, MeasureMode, InstrumentInfoConfig } from 'dataservice';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Logger,LogFileInfo } from 'logger';
import { AlarmManager, AlarmCode, AlarmRecord, AlarmCallback } from 'alarm';

// 定义返回类型接口
export interface ParseResult {
  request: ModbusRequest | null;
  transactionId: number;
  protocolId: number;
  unitId: number;
}

export interface DateTimeResult {
  year: number;
  month: number;
  day: number;
  hour: number;
  minute: number;
  second: number;
}
// 定义日志回调函数类型
export type LogCallback = (log: CommLogEntry) => void;

// 定义TCP响应发送回调类型
export type TcpSendCallback = (response: Uint8Array) => void;

export class ModbusTCPHandler {
  private dataStore: DataStore;
  private logCallback: LogCallback | null = null;
  private sendCallback: TcpSendCallback | null = null;
  private logId: number = 0;
  private currentTable: ProtocolTable = ProtocolTableRegistry.getDefault();

  constructor() {
    this.dataStore = DataStore.getInstance();
  }

  // 设置日志回调
  setLogCallback(callback: LogCallback): void {
    this.logCallback = callback;
  }

  // 设置发送回调
  setSendCallback(callback: TcpSendCallback): void {
    this.sendCallback = callback;
  }

  // 切换当前协议表
  setProtocolTable(table: ProtocolTable): void {
    this.currentTable = table;
  }
  private getCurrentDateTime(): DateTimeResult {
    const now = new Date();

    // 计算东八区时间（UTC+8）
    // 方法：获取 UTC 时间然后加上 16 小时
    const utcTime = now.getTime() + now.getTimezoneOffset() * 60 * 1000;
    const beijingTime = new Date(utcTime + 16 * 60 * 60 * 1000);

    return {
      year: beijingTime.getUTCFullYear(),
      month: beijingTime.getUTCMonth() + 1,
      day: beijingTime.getUTCDate(),
      hour: beijingTime.getUTCHours(),
      minute: beijingTime.getUTCMinutes(),
      second: beijingTime.getUTCSeconds()
    };
  }

  // 添加日志
  private addLog(direction: 'RECEIVE' | 'SEND', data: string, description: string): void {
    if (this.logCallback) {
      const log: CommLogEntry = {
        id: this.logId++,
        timestamp: new Date().toLocaleTimeString(),
        direction: direction,
        protocol: 'TCP',
        data: data,
        description: description
      };
      this.logCallback(log);
    }
  }
  // 发送TCP响应
  private sendResponse(response: Uint8Array): void {
    if (this.sendCallback) {
      this.sendCallback(response);
    }
    const hexStr = this.bytesToHex(response);
    this.addLog('SEND', hexStr, `📤 响应报文`);
  }

  // 解析TCP请求
  parseRequest(buffer: Uint8Array): ParseResult {
    if (buffer.length < 8) {
      return { request: null, transactionId: 0, protocolId: 0, unitId: 0 };
    }

    const hexStr = this.bytesToHex(buffer);
    const transactionId = (buffer[0] << 8) | buffer[1];
    const protocolId = (buffer[2] << 8) | buffer[3];
    const length = (buffer[4] << 8) | buffer[5];
    const unitId = buffer[6];
    const functionCode = buffer[7];
    let request: ModbusRequest | null = null;
    let description = '';

    if (functionCode === 0x03) { // 读保持寄存器
      // Modbus TCP读请求: 功能码(1) + 起始地址(2) + 寄存器数量(2) = 5字节
      if (length >= 5) {
        const externalAddress = (buffer[8] << 8) | buffer[9];
        const quantity = (buffer[10] << 8) | buffer[11];
        const startAddress = this.currentTable.toInternalAddress(externalAddress, functionCode);

        const registerName = this.getRegisterName(externalAddress, functionCode);
        description = `📥 读取保持寄存器请求: 地址=${externalAddress}(${registerName}), 数量=${quantity}`;
        request = {
          slaveId: unitId,
          functionCode: functionCode,
          startAddress: startAddress,
          quantity: quantity
        };
      } else {
        description = `📥 读取保持寄存器请求: 报文长度不足`;
      }
    } else if (functionCode === 0x04) { // 读输入寄存器
      // Modbus TCP输入寄存器读请求: 功能码(1) + 起始地址(2) + 寄存器数量(2) = 5字节
      if (length >= 5) {
        const externalAddress = (buffer[8] << 8) | buffer[9];
        const quantity = (buffer[10] << 8) | buffer[11];
        const startAddress = this.currentTable.toInternalAddress(externalAddress, functionCode);

        const registerName = this.getRegisterName(externalAddress, functionCode);
        description = `📥 读取输入寄存器请求: 地址=${externalAddress}(${registerName}), 数量=${quantity}`;
        request = {
          slaveId: unitId,
          functionCode: functionCode,
          startAddress: startAddress,
          quantity: quantity
        };
      } else {
        description = `📥 读取输入寄存器请求: 报文长度不足`;
      }
    } else if (functionCode === 0x06) { // 写单个寄存器
      // Modbus TCP写单个寄存器请求: 功能码(1) + 寄存器地址(2) + 寄存器值(2) = 5字节
      if (length >= 5) {
        const externalAddress = (buffer[8] << 8) | buffer[9];
        const value = (buffer[10] << 8) | buffer[11];
        const dataBytes = buffer.slice(8, 12);

        const startAddress = this.currentTable.toInternalAddress(externalAddress, functionCode);
        const registerName = this.getRegisterName(externalAddress, functionCode);

        if (startAddress === REG_ADDR.MEASURE_CONTROL) {
          description = `📥 测量控制请求: 地址=${externalAddress}(${registerName}), 命令码=${value}(${this.getControlCommandName(value)})`;
        }
        else if (startAddress === REG_ADDR.SMART_DIAG_CMD) {
          description = `📥 智能诊断指令请求: 地址=${externalAddress}(${registerName}), 命令码=${value}})`;
        }
        else {
          description = `📥 写单个寄存器请求: 地址=${externalAddress}(${registerName}), 值=${value}`;
        }

        request = {
          slaveId: unitId,
          functionCode: functionCode,
          startAddress: startAddress,
          quantity: 1,
          data: dataBytes
        };
      } else {
        description = `📥 写单个寄存器请求: 报文长度不足`;
      }
    } else if (functionCode === 0x10) { // 写多个寄存器
      // Modbus TCP写多个寄存器请求: 功能码(1) + 起始地址(2) + 寄存器数量(2) + 字节数(1) = 6字节 + 数据
      if (length >= 6) {
        const externalAddress = (buffer[8] << 8) | buffer[9];
        const quantity = (buffer[10] << 8) | buffer[11];
        const byteCount = buffer[12];

        if (length >= 6 + byteCount) {
          const dataBytes = buffer.slice(13, 13 + byteCount);

          const startAddress = this.currentTable.toInternalAddress(externalAddress, functionCode);
          const registerName = this.getRegisterName(externalAddress, functionCode);
          description = `📥 写多个寄存器请求: 地址=${externalAddress}(${registerName}), 数量=${quantity}`;

          if (startAddress === REG_ADDR.SYSTEM_TIME && quantity === 4) {
            if (dataBytes.length >= 8) {
              const yearOffset = (dataBytes[0] << 8) | dataBytes[1];
              const month = (dataBytes[2] << 8) | dataBytes[3];
              const day = (dataBytes[4] << 8) | dataBytes[5];
              const hour = (dataBytes[6] << 8) | dataBytes[7];
              const year = 1970 + yearOffset;
              description += ` [设置时间: ${year}-${month}-${day} ${hour}:00:00]`;
            }
          }

          request = {
            slaveId: unitId,
            functionCode: functionCode,
            startAddress: startAddress,
            quantity: quantity,
            data: dataBytes
          };
        } else {
          description = `📥 写多个寄存器请求: 数据长度不足`;
        }
      } else {
        description = `📥 写多个寄存器请求: 报文长度不足`;
      }
    }

    if (request) {
      this.addLog('RECEIVE', hexStr, description);
    } else if (description) {
      this.addLog('RECEIVE', hexStr, description);
    }

    return { request: request, transactionId: transactionId, protocolId: protocolId, unitId: unitId };
  }

  private getControlCommandName(command: number): string {
    const commandMap: Map<number, string> = new Map();
    commandMap.set(0, '测量水样');
    commandMap.set(1, '校准');
    commandMap.set(2, '停止');
    commandMap.set(3, '测量量程校准液');
    commandMap.set(4, '测量零点校准液');
    commandMap.set(5, '清洗定量管');
    commandMap.set(6, '清洗消解');
    commandMap.set(7, '深度清洗');
    commandMap.set(8, '清洗所有管路');
    commandMap.set(9, '采水');
    commandMap.set(10, '定量泵校准');
    commandMap.set(13, '零点校准');
    commandMap.set(14, '量程校准');
    commandMap.set(20, '零点核查');
    commandMap.set(21, '测量跨度核查');
    return commandMap.get(command) || `未知命令(${command})`;
  }

  /**
   * 将 Modbus 控制码映射为 OperationTaskService 的 commandId。
   * 地址 272（测量控制）与 273（采水控制）共用此映射。
   */
  private getOperationCommandId(address: number, value: number): string | null {
    if (address === REG_ADDR.WATER_COLLECT) {
      // 采水控制：1 表示开启采水，0 表示关闭；目前统一映射为采集水样任务。
      return value === 0 ? '' : 'collect-water-sample';
    }

    if (address !== REG_ADDR.MEASURE_CONTROL) {
      return null;
    }

    switch (value) {
      case MeasureControl.MEASURE_WATER:
        return 'sample';
      case MeasureControl.CALIBRATE:
        return 'calibration';
      case MeasureControl.STOP:
        return 'stop';
      case MeasureControl.MEASURE_RANGE_CAL:
        return 'measure-range-calibration-solution';
      case MeasureControl.MEASURE_ZERO_CAL:
        return 'measure-zero-calibration-solution';
      case MeasureControl.CLEAN_QUANT_TUBE:
        return 'clean-quantitative-tube';
      case MeasureControl.CLEAN_DIGESTION:
        return 'clean-digestion-chamber';
      case MeasureControl.DEEP_CLEAN:
        return 'deep-cleaning';
      case MeasureControl.CLEAN_ALL_PIPES:
        return 'clean-all-pipelines';
      case MeasureControl.COLLECT_WATER:
        return 'collect-water-sample';
      case MeasureControl.QUANT_PUMP_CAL:
        return 'quantitative-pump-calibration';
      case MeasureControl.ZERO_CALIBRATE:
        return 'zero-calibration';
      case MeasureControl.RANGE_CALIBRATE:
        return 'range-calibration';
      case MeasureControl.ZERO_CHECK:
        return 'zero-check';
      case MeasureControl.MEASURE_SPAN_CHECK:
        return 'span-check';
      default:
        return null;
    }
  }

  /**
   * 通过 emitter 把 Modbus 控制指令转发给 entry 模块，由 entry 调用 OperationTaskService 执行。
   */
  private emitControlCommand(address: number, value: number): void {
    const commandId = this.getOperationCommandId(address, value);
    if (!commandId || commandId.length === 0) {
      return;
    }
    const eventData: emitter.EventData = {
      data: {
        commandId: commandId,
        sourceAddress: address,
        value: value
      } as ModbusControlCommandEventData
    };
    hilog.info(0x0000, 'ModbusTCP', 'emit control command address=%{public}d value=%{public}d commandId=%{public}s',
      address, value, commandId);
    emitter.emit(MODBUS_CONTROL_COMMAND_EVENT, eventData);
  }

  private getRegisterName(address: number, functionCode?: number): string {
    const regInfo = this.currentTable.getRegisterInfo(address, functionCode);
    return regInfo?.name || `未知寄存器(0x${address.toString(16)})`;
  }

  // 处理请求并生成TCP响应
  processRequest(request: ModbusRequest, transactionId: number, protocolId: number, unitId: number): void {
    if (request.functionCode === 0x03 || request.functionCode === 0x04) {
      this.handleRead(request, transactionId, protocolId, unitId);
    } else if (request.functionCode === 0x06) {
      this.handleWriteSingle(request, transactionId, protocolId, unitId);
    } else if (request.functionCode === 0x10) {
      this.handleWriteMultiple(request, transactionId, protocolId, unitId);
    } else {
      const response = this.handleException(request.slaveId, request.functionCode, ModbusExceptionCode.ILLEGAL_FUNCTION);
      const tcpResponse = this.buildTCPResponse(transactionId, protocolId, unitId, response);
      this.sendResponse(tcpResponse);
    }
  }

  // 处理读请求 (功能码03)
  private async handleRead(request: ModbusRequest, transactionId: number, protocolId: number, unitId: number): Promise<void> {

    const startAddress = request.startAddress;
    const quantity = request.quantity;
    const functionCode = request.functionCode;
    if (quantity < 1 || quantity > 125) {
      const response = this.handleException(0, functionCode, ModbusExceptionCode.ILLEGAL_DATA_VALUE);
      const tcpResponse = this.buildTCPResponse(transactionId, protocolId, unitId, response);
      this.sendResponse(tcpResponse);
      return;
    }

    let response: Uint8Array | null = null;
    const measureStatusManager = MeasureStatusManager.getInstance();
    const status = await measureStatusManager.getMeasureStatus();

    const setting = SettingsManager.getInstance();
    const info = await setting.getInstrumentInfo();
    const measureParam = await setting.getMeasureParamConfig();
    const system = await setting.getSystemConfig();
    const scheduler = await setting.getSchedulerConfig();
    const hardwareConfig = await setting.getHardwareConfig();


    // 地址0: 测量结果 (FLOAT32, 2个寄存器)
    if (startAddress === REG_ADDR.MEASURE_RESULT && quantity === 2 && status) {
      const value = status.report.measure.consistency;
      //const value = 19.779709;
      response = this.responseFloat32(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回测量结果: ${value.toFixed(6)} mg/L`);
    }
    // 地址2: 量程校准液结果 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.RANGE_CAL_RESULT && quantity === 2 && status) {
      const value = status.report.check.consistency;
      response = this.responseFloat32(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回量程校准液结果: ${value.toFixed(6)} mg/L`);
    }
    // 地址4: 测量参数 (UINT16, 1个寄存器)
    else if (startAddress === REG_ADDR.MEASURE_PARAM && quantity === 1 && status) {
      const value = status.report.measure.deviceTypeNum || 0;
      response = this.responseUint16(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回测量参数: ${value}`);
    }
    // 地址5: 测试结果类型 (UINT16, 1个寄存器)
    else if (startAddress === REG_ADDR.RESULT_TYPE && quantity === 1 && status) {
      const value = status.report.measure.resultType || 0;
      response = this.responseUint16(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回测试结果类型: ${value}`);
    }
    // 地址6: 测量时长 (UINT16, 1个寄存器)
    else if (startAddress === REG_ADDR.MEASURE_DURATION && quantity === 1 && status) {
      const value = status.report.measure.measureTime || 0;
      response = this.responseUint16(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回测量时长: ${value}秒`);
    }
    // 地址7: 测量时间 (TIME, 3个寄存器)
    else if (startAddress === REG_ADDR.MEASURE_TIME && quantity === 3 && status) {
      const timestamp  = status.report.measure.dateTime;
      // 将时间戳转换为日期对象
      const date = new Date(timestamp);
      const year = date.getFullYear();
      const month = date.getMonth() + 1;
      const day = date.getDate();
      const hour = date.getHours();
      const minute = date.getMinutes();
      const second = date.getSeconds();

      response = this.responseTime(transactionId, protocolId, unitId, year, month, day, hour, minute, second, functionCode);
      this.addLog('SEND', '', `📤 返回测量时间: ${year}-${month}-${day} ${hour}:${minute}:${second}`);
    }
    // 地址10: 测量量程校准液时间 (TIME, 3个寄存器)
    else if (startAddress === REG_ADDR.RANGE_CAL_TIME && quantity === 3 && status) {
      const timestamp  = status.report.check.dateTime;
      // 将时间戳转换为日期对象
      const date = new Date(timestamp);
      const year = date.getFullYear();
      const month = date.getMonth() + 1;
      const day = date.getDate();
      const hour = date.getHours();
      const minute = date.getMinutes();
      const second = date.getSeconds();

      response = this.responseTime(transactionId, protocolId, unitId, year, month, day, hour, minute, second, functionCode);
      this.addLog('SEND', '', `📤 返回测量量程校准液时间: ${year}-${month}-${day} ${hour}:${minute}:${second}`);
    }
    // 地址13: 校准时间 (TIME, 3个寄存器)
    else if (startAddress === REG_ADDR.CALIBRATION_TIME && quantity === 3 && status) {
      const timestamp  = status.newResult.calibrate.dateTime;
      // 将时间戳转换为日期对象
      const date = new Date(timestamp);
      const year = date.getFullYear();
      const month = date.getMonth() + 1;
      const day = date.getDate();
      const hour = date.getHours();
      const minute = date.getMinutes();
      const second = date.getSeconds();

      response = this.responseTime(transactionId, protocolId, unitId, year, month, day, hour, minute, second, functionCode);
      this.addLog('SEND', '', `📤 返回校准时间: ${year}-${month}-${day} ${hour}:${minute}:${second}`);
    }
    // 地址16: 系统状态 (UINT16, 1个寄存器)
    else if (startAddress === REG_ADDR.SYSTEM_STATUS && quantity === 1) {
      const value = DataStore.getInstance().getUInt16(startAddress);
      response = this.responseUint16(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回系统状态: ${value}`);
    }
    // 地址17: 当前动作 (UINT16, 1个寄存器)
    else if (startAddress === REG_ADDR.CURRENT_ACTION && quantity === 1) {
      const value = DataStore.getInstance().getUInt16(startAddress);
      response = this.responseUint16(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回当前动作: ${value}`);
    }
    // 地址18: 当前温度 (FLOAT32, 4个寄存器,包含消解室温度和环境温度)
    else if (startAddress === REG_ADDR.CURRENT_TEMP && quantity === 2 && status) {
      const value = 25.5;
      response = this.responseFloat32(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回当前温度: ${value.toFixed(1)}°C`);
    }
    // 地址22: 报警时间 (TIME, 3个寄存器)
    else if (startAddress === REG_ADDR.ALARM_TIME && quantity === 3 && status) {
      const timestamp  = status.newResult.calibrate.dateTime;
      // 将时间戳转换为日期对象
      const date = new Date(timestamp);
      const year = date.getFullYear();
      const month = date.getMonth() + 1;
      const day = date.getDate();
      const hour = date.getHours();
      const minute = date.getMinutes();
      const second = date.getSeconds();
      response = this.responseTime(transactionId, protocolId, unitId, year, month, day, hour, minute, second, functionCode);
      this.addLog('SEND', '', `📤 返回报警时间: ${year}-${month}-${day} ${hour}:${minute}:${second}`);
    }
    // 地址25: 报警代码 (UINT16, 1个寄存器)
    else if (startAddress === REG_ADDR.ALARM_CODE && quantity === 1 && status) {
      //const value = 0;
      const value = AlarmManager.getInstance().getCurrentAlarmCode() as number;
      response = this.responseUint16(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回报警代码: ${value}`);
    }
    // 地址26: 预设量程表上限（一） (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.RANGE_TABLE && quantity === 2 && system && measureParam) {
      const rangeIndex = measureParam.range[1] + 1;
      const rangeViewItem = system.rangeViewMap[rangeIndex];
      const value = rangeViewItem ? rangeViewItem.view : 0;  // 获取 view 属性，默认为 0
      Logger.debug('预设量程表上限（一）：%f', value);
      response = this.responseFloat32(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回预设量程表上限（一）: ${value} mg/L`);
    }
    // 地址28: 预设量程表上限（二） (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.RANGE_TABLE+2 && quantity === 2 && system && measureParam) {
      const rangeIndex = measureParam.range[2] + 1;
      const rangeViewItem = system.rangeViewMap[rangeIndex];
      const value = rangeViewItem ? rangeViewItem.view : 0;  // 获取 view 属性，默认为 0
      response = this.responseFloat32(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回预设量程表上限（二）: ${value} mg/L`);
    }
    // 地址30: 预设量程表上限（三） (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.RANGE_TABLE+4 && quantity === 2 && system && measureParam) {
      const rangeIndex = measureParam.range[3] + 1;
      const rangeViewItem = system.rangeViewMap[rangeIndex];
      const value = rangeViewItem ? rangeViewItem.view : 0;  // 获取 view 属性，默认为 0
      response = this.responseFloat32(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回预设量程表上限（三）: ${value} mg/L`);
    }
    // 地址36: 产品名称 (STRING, 32个寄存器)
    else if (startAddress === REG_ADDR.PRODUCT_NAME && quantity <= 32 && info) {
      const str  = info.showName;
      response = this.responseString(transactionId, protocolId, unitId, str, 32, functionCode);
      this.addLog('SEND', '', `📤 返回产品名称: ${str}`);
    }
    // 地址68: 产品型号 (STRING, 32个寄存器)
    else if (startAddress === REG_ADDR.PRODUCT_MODEL && quantity <= 32 && info) {
      const str  = info.showModel;
      response = this.responseString(transactionId, protocolId, unitId, str, 32, functionCode);
      this.addLog('SEND', '', `📤 返回产品型号: ${str}`);
    }
    // 地址100: 生产厂商 (STRING, 32个寄存器)
    else if (startAddress === REG_ADDR.MANUFACTURER && quantity <= 32 && info) {
      const str  = info.manufacturer;
      response = this.responseString(transactionId, protocolId, unitId, str, 32, functionCode);
      this.addLog('SEND', '', `📤 返回生产厂商: ${str}`);
    }
    // 地址132: 生产序列号 (STRING, 16个寄存器)
    else if (startAddress === REG_ADDR.SERIAL_NUMBER && quantity <= 16 && info) {
      const str  = info.sn;
      response = this.responseString(transactionId, protocolId, unitId, str, 16, functionCode);
      this.addLog('SEND', '', `📤 返回生产序列号: ${str}`);
    }
    // 地址148: 液路板固件版本 (UINT32, 2个寄存器)
    else if (startAddress === REG_ADDR.FW_VERSION_LIQUID && quantity === 2) {
      const value = 0x01000001;  // v1.0.0.1
      response = this.responseFWVersion(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回液路板固件版本: ${value}`);
    }
    // 地址150: 温控板固件版本 (UINT32, 2个寄存器)
    else if (startAddress === REG_ADDR.FW_VERSION_TEMP && quantity === 2) {
      const value = 0x01000002;  // v1.0.0.2
      response = this.responseFWVersion(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回温控板固件版本: ${value}`);
    }
    // 地址152: 信号板固件版本 (UINT32, 2个寄存器)
    else if (startAddress === REG_ADDR.FW_VERSION_SIGNAL && quantity === 2) {
      const value = 0x01000003;  // v1.0.0.3
      response = this.responseFWVersion(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回信号板固件版本: ${value}`);
    }
    // 地址154: 主控板固件版本 (UINT32, 2个寄存器)
    else if (startAddress === REG_ADDR.FW_VERSION_MAIN && quantity === 2) {
      const value = 0x01000004;  // v1.0.0.4
      response = this.responseFWVersion(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回主控板固件版本: ${value}`);
    }
    // 地址156: 驱动板固件版本 (UINT32, 2个寄存器)
    else if (startAddress === REG_ADDR.FW_VERSION_DRIVER && quantity === 2) {
      const value = 0x01000005;  // v1.0.0.5
      response = this.responseFWVersion(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回驱动板固件版本: ${value}`);
    }
    // 地址158: 反应板固件版本 (UINT32, 2个寄存器)
    else if (startAddress === REG_ADDR.FW_VERSION_REACTION && quantity === 2) {
      const value = 0x01000006;  // v1.0.0.6
      response = this.responseFWVersion(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回反应板固件版本: ${value}`);
    }
    // 地址163: 跨度核查设置浓度 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.SPAN_CHECK_SET && quantity === 2 && measureParam) {
      const value = measureParam.checkConsistency;
      response = this.responseFloat32(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回跨度核查设置浓度: ${value.toFixed(6)} mg/L`);
    }
    // 地址165: 跨度核查结果 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.SPAN_CHECK_RESULT && quantity === 2 && status) {
      const value = status.report.rangeCheck.consistency;
      Logger.debug('跨度核查结果：%f', value);
      response = this.responseFloat32(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回跨度核查结果: ${value} mg/L`);
    }
    // 地址167: 跨度核查时间 (TIME, 3个寄存器)
    else if (startAddress === REG_ADDR.SPAN_CHECK_TIME && quantity === 3 && status) {
      const timestamp  = status.report.rangeCheck.dateTime;
      // 将时间戳转换为日期对象
      const date = new Date(timestamp);
      const year = date.getFullYear();
      const month = date.getMonth() + 1;
      const day = date.getDate();
      const hour = date.getHours();
      const minute = date.getMinutes();
      const second = date.getSeconds();

      response = this.responseTime(transactionId, protocolId, unitId, year, month, day, hour, minute, second, functionCode);
      this.addLog('SEND', '', `📤 返回跨度核查时间: ${year}-${month}-${day} ${hour}:${minute}:${second}`);
    }
    // 地址170: 跨度核查间隔 (UINT16, 1个寄存器)
    else if (startAddress === REG_ADDR.SPAN_CHECK_INTERVAL && quantity === 1 && scheduler) {
      const value = scheduler.rangeCheck.interval;
      response = this.responseUint16(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回跨度核查间隔: ${value}小时`);
    }
    // 地址190: 水样吸光度 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.WATER_ABSORBANCE && quantity === 2 && status) {
      const value = status.report.measure.absorbance || 0;
      response = this.responseFloat32(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回水样吸光度: ${value} abs`);
    }
    // 地址192: 水样数据标识 (Uint16, 1个寄存器)
    else if (startAddress === REG_ADDR.WATER_DATA_FLAG && quantity === 1 && status) {
      const resultInfo = status.report.measure.resultInfo || 'N';  // 默认为 'N' (正常)
      const value = resultInfo.charCodeAt(0);
      response = this.responseUint16(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回水样数据标识: ${value}`);
    }
    // 地址193: 测量程校准液吸光度 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.RANGE_CAL_ABSORBANCE && quantity === 2 && status) {
      const value = status.report.check.absorbance || 0;
      response = this.responseFloat32(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回测量程校准液吸光度: ${value.toFixed(6)} abs`);
    }
    // 地址195: 测量程校准液数据标识 (Uint16, 1个寄存器)
    else if (startAddress === REG_ADDR.RANGE_CAL_DATA_FLAG && quantity === 1 && status) {
      const resultInfo = status.report.check.resultInfo || 'N';  // 默认为 'N' (正常)
      const value = resultInfo.charCodeAt(0);
      response = this.responseUint16(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回测量程校准液数据标识: ${value}`);
    }
    // 地址199: 核查液吸光度 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.CHECK_ABSORBANCE && quantity === 2 && status) {
      const value = status.report.rangeCheck.absorbance || 0;
      response = this.responseFloat32(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回核查液吸光度: ${value.toFixed(6)} abs`);
    }
    // 地址201: 核查液数据标识 (Uint16, 1个寄存器)
    else if (startAddress === REG_ADDR.CHECK_DATA_FLAG && quantity === 1 && status) {
      const resultInfo = status.report.rangeCheck.resultInfo || 'N';  // 默认为 'N' (正常)
      const value = resultInfo.charCodeAt(0);
      response = this.responseUint16(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回核查液数据标识: ${value}`);
    }
    // 地址217: 零点校准时间 (TIME, 3个寄存器)
    else if (startAddress === REG_ADDR.ZERO_CAL_TIME && quantity === 3 && status && measureParam) {
      const timestamp  = status.calibrate[measureParam.range[measureParam.currentRange + 1]+1].zeroCalibrateDateTime;
      // 将时间戳转换为日期对象
      const date = new Date(timestamp);
      const year = date.getFullYear();
      const month = date.getMonth() + 1;
      const day = date.getDate();
      const hour = date.getHours();
      const minute = date.getMinutes();
      const second = date.getSeconds();

      response = this.responseTime(transactionId, protocolId, unitId, year, month, day, hour, minute, second, functionCode);
      this.addLog('SEND', '', `📤 返回零点校准时间: ${year}-${month}-${day} ${hour}:${minute}:${second}`);
    }
    // 地址220: 校准零点浓度 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.ZERO_CAL_CONC && quantity === 2 && status && measureParam) {
      const value = status.calibrate[measureParam.range[measureParam.currentRange + 1]+1].zeroCalculateConsistency;
      response = this.responseFloat32(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回校准零点浓度: ${value} mg/L`);
    }
    // 地址222: 校准零点吸光度 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.ZERO_CAL_ABSORBANCE && quantity === 2 && status && measureParam) {
      const value = status.calibrate[measureParam.range[measureParam.currentRange + 1]+1].point0Absorbance;
      response = this.responseFloat32(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回校准零点吸光度: ${value} abs`);
    }
    // 地址224: 零点漂移 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.ZERO_DRIFT && quantity === 2) {
      const value = 50.72;
      response = this.responseFloat32(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回零点漂移: ${value.toFixed(2)} %`);
    }
    // 地址227: 量程校准开始时间 (TIME, 3个寄存器)
    else if (startAddress === REG_ADDR.RANGE_CAL_START_TIME && quantity === 3 && status && measureParam) {
      const timestamp  = status.calibrate[measureParam.range[measureParam.currentRange + 1]+1].standardCalibrateDateTime;
      // 将时间戳转换为日期对象
      const date = new Date(timestamp);
      const year = date.getFullYear();
      const month = date.getMonth() + 1;
      const day = date.getDate();
      const hour = date.getHours();
      const minute = date.getMinutes();
      const second = date.getSeconds();
      response = this.responseTime(transactionId, protocolId, unitId, year, month, day, hour, minute, second, functionCode);
      this.addLog('SEND', '', `📤 返回量程校准开始时间: ${year}-${month}-${day} ${hour}:${minute}:${second}`);
    }
    // 地址230: 校准标点浓度 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.CAL_STANDARD_CONC && quantity === 2 && status && measureParam) {
      const value = status.calibrate[measureParam.range[measureParam.currentRange + 1]+1].standardCalculateConsistency;
      response = this.responseFloat32(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回校准标点浓度: ${value.toFixed(6)} mg/L`);
    }
    // 地址232: 校准标点吸光度 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.CAL_STANDARD_ABSORBANCE && quantity === 2 && status && measureParam) {
      const value = status.calibrate[measureParam.range[measureParam.currentRange + 1]+1].point1Absorbance;
      response = this.responseFloat32(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回校准标点吸光度: ${value.toFixed(6)} abs`);
    }
    // 地址234: 量程漂移 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.RANGE_DRIFT && quantity === 2) {
      const value = 60.72;
      response = this.responseFloat32(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回量程漂移: ${value.toFixed(2)} %`);
    }
    // 地址236: 复合测量结果 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.COMPOSITE_RESULT && quantity === 2 && status) {
      const value = status.report.complexResult.consistency || 0;
      response = this.responseFloat32(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回复合测量结果: ${value.toFixed(6)} mg/L`);
    }
    // 地址238: 复合结果时间 (TIME, 3个寄存器)
    else if (startAddress === REG_ADDR.COMPOSITE_TIME && quantity === 3 && status) {
      const timestamp  = status.report.complexResult.dateTime;
      // 将时间戳转换为日期对象
      const date = new Date(timestamp);
      const year = date.getFullYear();
      const month = date.getMonth() + 1;
      const day = date.getDate();
      const hour = date.getHours();
      const minute = date.getMinutes();
      const second = date.getSeconds();

      response = this.responseTime(transactionId, protocolId, unitId, year, month, day, hour, minute, second, functionCode);
      this.addLog('SEND', '', `📤 返回复合结果时间: ${year}-${month}-${day} ${hour}:${minute}:${second}`);
    }
    // 地址241: 复合测量数据标识 (Uint16, 1个寄存器)
    else if (startAddress === REG_ADDR.COMPOSITE_DATA_FLAG && quantity === 1 && status) {
      const resultInfo = status.report.complexResult.resultInfo || 'N';  // 默认为 'N' (正常)
      const value = resultInfo.charCodeAt(0);
      response = this.responseUint16(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回复合测量数据标识: ${value}`);
    }
    // 地址242: 系数常数 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.COEFF_CONST && quantity === 2) {
      const value = 10.0;
      response = this.responseFloat32(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回系数常数: ${value} `);
    }
    // 地址244: 系数比例 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.COEFF_RATIO && quantity === 2) {
      const value = 2.0;
      response = this.responseFloat32(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回系数比例: ${value} `);
    }
    // 地址246: 流量控制 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.FLOW_CONTROL && quantity === 2) {
      const value = 3.0;
      response = this.responseFloat32(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回流量控制: ${value} `);
    }
    // 地址248: TOC测量结果 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.TOC_RESULT && quantity === 2) {
      const value = 12.0;
      response = this.responseFloat32(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回TOC测量结果: ${value} `);
    }
    // 地址253: 当前量程索引 (Uint16, 1个寄存器)
    else if (startAddress === REG_ADDR.CURRENT_RANGE_INDEX && quantity === 1 && measureParam) {
      Logger.debug('索引值: %d', measureParam.currentRange);
      const value = measureParam.currentRange + 1;
      response = this.responseUint16(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回当前量程索引: ${value}`);
    }
    // 地址254: 当前量程下限值 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.CURRENT_RANGE_LOWER && quantity === 2) {
      const value = 4.00;
      response = this.responseFloat32(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回当前量程下限值: ${value} `);
    }
    // 地址256: 当前量程 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.CURRENT_RANGE && quantity === 2 && system && measureParam) {
      const value = system.rangeViewMap[measureParam.range[measureParam.currentRange]].view;
      response = this.responseFloat32(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回当前量程: ${value} `);
    }
    // 地址258: 校准曲线斜率 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.CAL_SLOPE && quantity === 2 && measureParam) {
      const value = measureParam.curveParam[measureParam.range[measureParam.currentRange + 1]+1].curveK;
      response = this.responseFloat32(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回校准曲线斜率: ${value} `);
    }
    // 地址260: 校准曲线截距 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.CAL_INTERCEPT && quantity === 2 && measureParam) {
      const value = measureParam.curveParam[measureParam.range[measureParam.currentRange + 1]+1].curveB;
      response = this.responseFloat32(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回校准曲线截距: ${value} `);
    }
    // 地址262: 消解温度 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.DIGESTION_TEMP && quantity === 2 && measureParam) {
      const value = measureParam.digestTemperature;
      response = this.responseFloat32(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回消解温度: ${value} `);
    }
    // 地址264: 消解时间 (Uint16, 1个寄存器)
    else if (startAddress === REG_ADDR.DIGESTION_TIME && quantity === 1 && measureParam) {
      const value = measureParam.digestTime;
      response = this.responseUint16(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回消解时间: ${value}`);
    }
    // 地址265: 反应温度 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.REACTION_TEMP && quantity === 2 && measureParam) {
      const value = measureParam.reactTemperature;
      response = this.responseFloat32(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回反应温度: ${value} `);
    }
    // 地址267: 反应时间 (Uint16, 1个寄存器)
    else if (startAddress === REG_ADDR.REACTION_TIME && quantity === 1 && measureParam) {
      const value = measureParam.reactTime;
      response = this.responseUint16(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回反应时间: ${value}`);
    }
    // 地址268: 修正斜率 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.CORRECT_SLOPE && quantity === 2 && measureParam) {
      const value = measureParam.reviseFactor;
      response = this.responseFloat32(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回修正斜率: ${value} `);
    }
    // 地址270: 修正截距 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.CORRECT_INTERCEPT && quantity === 2 && measureParam) {
      const value = measureParam.shiftFactor;
      response = this.responseFloat32(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回修正截距: ${value} `);
    }
    // 地址274: 系统时间 (TIME, 3个寄存器)
    else if (startAddress === REG_ADDR.SYSTEM_TIME && quantity === 3) {
      const currentTime = this.getCurrentDateTime();
      response = this.responseTime(
        transactionId, protocolId, unitId,
        currentTime.year, currentTime.month, currentTime.day,
        currentTime.hour, currentTime.minute, currentTime.second,
        functionCode
      );
      this.addLog('SEND', '', `📤 返回系统时间: ${currentTime.year}-${currentTime.month}-${currentTime.day} ${currentTime.hour}:${currentTime.minute}:${currentTime.second}`);
    }
    // 地址277: 测量模式 (Uint16, 1个寄存器)
    else if (startAddress === REG_ADDR.MEASURE_MODE && quantity === 1 && scheduler) {
      const value = scheduler.measure.mode;
      response = this.responseUint16(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回测量模式: ${value}`);
    }
    // 地址278: 自动测量时间间隔 (Uint16, 1个寄存器)
    else if (startAddress === REG_ADDR.AUTO_MEASURE_INTERVAL && quantity === 1 && scheduler) {
      const value = scheduler.measure.interval;
      response = this.responseUint16(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回自动测量时间间隔: ${value}`);
    }
    // 地址279: 自动校准模式 (Uint16, 1个寄存器)
    else if (startAddress === REG_ADDR.AUTO_CAL_MODE && quantity === 1 && scheduler) {
      const value = scheduler.calibrate.mode;
      response = this.responseUint16(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回自动校准模式: ${value}`);
    }
    // 地址280: 自动校准时间间隔 (Uint16, 1个寄存器)
    else if (startAddress === REG_ADDR.AUTO_CAL_INTERVAL && quantity === 1 && scheduler) {
      const value = scheduler.calibrate.interval;
      response = this.responseUint16(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回自动校准时间间隔: ${value}`);
    }
    // 地址283: 当前量程稀释倍数 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.DILUTION_FACTOR && quantity === 2 && measureParam) {
      const value = measureParam.range[measureParam.currentRange + 1] + 1;
      response = this.responseFloat32(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回当前量程稀释倍数: ${value} `);
    }
    // 地址293: 零点校准液浓度 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.ZERO_CAL_CONCENTRATION && quantity === 2 && measureParam) {
      const value = measureParam.curveParam[measureParam.range[measureParam.currentRange + 1]+1].zeroConsistency;
      response = this.responseFloat32(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回零点校准液浓度: ${value} `);
    }
    // 地址295: 量程校准液浓度 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.RANGE_CAL_CONCENTRATION && quantity === 2 && measureParam) {
      const value = measureParam.curveParam[measureParam.range[measureParam.currentRange + 1]+1].rangeConsistency;
      response = this.responseFloat32(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回量程校准液浓度: ${value} `);
    }
    // 地址300: 试剂一加液体积 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.REAGENT1_VOLUME && quantity === 2) {
      const value = 3.0125;
      response = this.responseFloat32(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回试剂一加液体积: ${value} `);
    }
    // 地址302: 试剂二加液体积 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.REAGENT2_VOLUME && quantity === 2) {
      const value = 5.0;
      response = this.responseFloat32(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回试剂二加液体积: ${value} `);
    }
    // 地址304: 试剂三加液体积 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.REAGENT3_VOLUME && quantity === 2) {
      const value = 3.0125;
      response = this.responseFloat32(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回试剂三加液体积: ${value} `);
    }
    // 地址306: 试剂四加液体积 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.REAGENT4_VOLUME && quantity === 2) {
      const value = 5.0;
      response = this.responseFloat32(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回试剂四加液体积: ${value} `);
    }
    // 地址308: 试剂五加液体积 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.REAGENT5_VOLUME && quantity === 2) {
      const value = 3.0125;
      response = this.responseFloat32(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回试剂五加液体积: ${value} `);
    }
    // 地址310: 当前量程校正因子 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.CALIBRATION_FACTOR && quantity === 2 && measureParam) {
      const value = measureParam.reviseParameter[measureParam.range[measureParam.currentRange + 1]+1];
      response = this.responseFloat32(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回当前量程校正因子: ${value} `);
    }
    // 地址312: 核查允许偏差值 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.CHECK_ALLOW_DEVIATION && quantity === 2 && measureParam) {
      const value = measureParam.checkErrorLimit;
      response = this.responseFloat32(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回核查允许偏差值: ${value} `);
    }
    // 地址314: 核查偏差值 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.CHECK_DEVIATION && quantity === 2 && status) {
      const value = status.report.rangeCheck.checkError;
      response = this.responseFloat32(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回核查偏差值: ${value} `);
    }
    // 地址316: 设备唯一标识 (STRING, 24个寄存器)
    else if (startAddress === REG_ADDR.DEVICE_UNIQUE_ID && quantity <= 24 && info) {
      const mfrN = info.MfrN || '';
      const sn = info.sn || '';

      // 构建唯一标识：MfrN + "00" + sn
      // 示例：MfrN=683776325001, sn=W00B00000000 -> 68377632500100W00B00000000
      let value = mfrN + '00' + sn;
      if (value.length < 24) {
        value = value.padEnd(24, '0');
      } else if (value.length > 24) {
        value = value.substring(0, 24);
      }

      response = this.responseString(transactionId, protocolId, unitId, value, 24, functionCode);
      this.addLog('SEND', '', `📤 返回设备唯一标识: ${value} (MfrN:${mfrN}, SN:${sn})`);
    }
    // 地址340: 量程上限浓度表 (FLOAT32_ARRAY, 20个寄存器)
    else if (startAddress === REG_ADDR.SYSTEM_RANGE_TABLE && quantity <= 20 && system) {
      const rangeValues: number[] = [];
      const maxItems = Math.min(system.rangeViewMap.length, 10);
      for (let i = 0; i < maxItems; i++) {
        rangeValues.push(system.rangeViewMap[i].view);
      }
      // 补齐到10个元素（如果不足10个，用0填充）
      while (rangeValues.length < 10) {
        rangeValues.push(0);
      }

      response = this.responseFloat32Array(transactionId, protocolId, unitId, rangeValues, quantity, functionCode);
      this.addLog('SEND', '', `📤 返回量程上限浓度表: ${rangeValues.slice(0, quantity / 2).join(', ')} mg/L`);
    }
    // 地址360: 零点校准液浓度表 (FLOAT32_ARRAY, 20个寄存器)
    else if (startAddress === REG_ADDR.ZERO_CAL_TABLE && quantity <= 20 && measureParam) {
      const rangeValues: number[] = [];
      const maxItems = Math.min(measureParam.curveParam.length, 10);
      for (let i = 0; i < maxItems; i++) {
        rangeValues.push(measureParam.curveParam[i].zeroConsistency);
      }
      // 补齐到10个元素（如果不足10个，用0填充）
      while (rangeValues.length < 10) {
        rangeValues.push(0);
      }
      response = this.responseFloat32Array(transactionId, protocolId, unitId, rangeValues, quantity, functionCode);
      this.addLog('SEND', '', `📤 返回零点校准液浓度表: ${rangeValues.slice(0, quantity / 2).join(', ')} mg/L`);
    }
    // 地址380: 量程校准液浓度表 (FLOAT32_ARRAY, 20个寄存器)
    else if (startAddress === REG_ADDR.RANGE_CAL_TABLE && quantity <= 20 && measureParam) {
      const rangeValues: number[] = [];
      const maxItems = Math.min(measureParam.curveParam.length, 10);
      for (let i = 0; i < maxItems; i++) {
        rangeValues.push(measureParam.curveParam[i].rangeConsistency);
      }
      // 补齐到10个元素（如果不足10个，用0填充）
      while (rangeValues.length < 10) {
        rangeValues.push(0);
      }
      response = this.responseFloat32Array(transactionId, protocolId, unitId, rangeValues, quantity, functionCode);
      this.addLog('SEND', '', `📤 返回量程校准液浓度表: ${rangeValues.slice(0, quantity / 2).join(', ')} mg/L`);
    }
    // 地址401: 智能诊断结果 (Uint16, 1个寄存器)
    else if (startAddress === REG_ADDR.SMART_DIAG_RESULT && quantity === 1) {
      const value = 2; //DiagnosticResult.PASSED.charCodeAt(0);通过
      response = this.responseUint16(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回智能诊断结果: ${value}`);
    }
    // 地址402: 消解室温度 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.DIGESTION_ROOM_TEMP && quantity === 2) {
      const value = 23.0;
      response = this.responseFloat32(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回消解室温度: ${value.toFixed(1)}°C`);
    }
    // 地址404: 环境温度 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.AMBIENT_TEMP && quantity === 2) {
      const value = 22.6;
      response = this.responseFloat32(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回环境温度: ${value.toFixed(1)}°C`);
    }
    // 地址406: 定量点1信号 (UINT32, 2个寄存器)
    else if (startAddress === REG_ADDR.QUANT_POINT1_SIGNAL && quantity === 2) {
      const value = 7;
      response = this.responseSignalValue(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回定量点1信号: ${value}`);
    }
    // 地址408: 定量点2信号 (UINT32, 2个寄存器)
    else if (startAddress === REG_ADDR.QUANT_POINT2_SIGNAL && quantity === 2) {
      const value = 8;
      response = this.responseSignalValue(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回定量点2信号: ${value}`);
    }
    // 地址410: 参考AD信号 (UINT32, 2个寄存器)
    else if (startAddress === REG_ADDR.REFERENCE_AD_SIGNAL && quantity === 2) {
      const value = 9;
      response = this.responseSignalValue(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回参考AD信号: ${value}`);
    }
    // 地址412: 测量AD信号 (UINT32, 2个寄存器)
    else if (startAddress === REG_ADDR.MEASURE_AD_SIGNAL && quantity === 2) {
      const value = 10;
      response = this.responseSignalValue(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回测量AD信号: ${value}`);
    }
    // 地址414: 泵管系数 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.PUMP_TUBE_COEFF && quantity === 2 && hardwareConfig) {
      const value = hardwareConfig.pumpFactor.real;
      response = this.responseFloat32(transactionId, protocolId, unitId, value, functionCode);
      this.addLog('SEND', '', `📤 返回泵管系数: ${value}`);
    }
    // 地址500: 日志条数 (Uint16, 1个寄存器)
    else if (startAddress === REG_ADDR.LOG_COUNT && quantity === 1) {
      const filesInfo = Logger.getAllLogFilesInfo();
      const sysLogFiles = filesInfo.filter((f: LogFileInfo) => f.fileName.includes('RunLog.txt'));
      if(sysLogFiles.length > 0){
        const value = sysLogFiles[0].lineCount;//99;
        Logger.debug('日志条数：%d', value);
        response = this.responseUint16(transactionId, protocolId, unitId, value, functionCode);
        this.addLog('SEND', '', `📤 返回日志条数: ${value}`);
      }
    }
    // 地址501: 日志 (STRING, 99个寄存器)
    else if (startAddress === REG_ADDR.LOG_CONTENT && quantity <= 99) {
      Logger.debug('日志 (STRING, 99个寄存器)');
      const logStr = Logger.readAllLogs('RunLog.txt');
      //const logStr = Logger.readLogsFromFile('RunLog.txt',100);
      hilog.info(0x0000,'地址501','日志内容：%{public}s 长度：%{public}d',logStr,logStr.length);
      response = this.responseString(transactionId, protocolId, unitId, logStr, 99, functionCode);
      this.addLog('SEND', '', `📤 返回日志: ${logStr}`);
    }

    // 默认：返回非法数据地址异常
    else {
      const exception = this.handleException(0, functionCode, ModbusExceptionCode.ILLEGAL_DATA_ADDRESS);
      response = this.buildTCPResponse(transactionId, protocolId, unitId, exception);
      this.addLog('SEND', '', `⚠️ 非法数据地址: ${startAddress}`);
    }

    if (response) {
      this.sendResponse(response);
    }
  }

  // 处理写单个寄存器请求 (功能码06)
  private async handleWriteSingle(request: ModbusRequest, transactionId: number, protocolId: number, unitId: number): Promise<void> {
    const startAddress = request.startAddress;
    const data = request.data;
    const functionCode = request.functionCode;

    if (!data || data.length !== 4) {
      const response = this.handleException(0, functionCode, ModbusExceptionCode.ILLEGAL_DATA_VALUE);
      const tcpResponse = this.buildTCPResponse(transactionId, protocolId, unitId, response);
      this.sendResponse(tcpResponse);
      return;
    }

    const registerValue = (data[2] << 8) | data[3];
    Logger.debug('registerValue data[2]: %d, data[3]: %d', data[2], data[3]);
    const registerData = data.slice(2, 4);

    const regInfo = this.dataStore.getRegisterInfo(startAddress);
    if (regInfo && regInfo.access === 'R') {
      const response = this.handleException(0, functionCode, ModbusExceptionCode.ILLEGAL_DATA_ADDRESS);
      const tcpResponse = this.buildTCPResponse(transactionId, protocolId, unitId, response);
      this.sendResponse(tcpResponse);
      return;
    }

    const success = this.dataStore.writeRegister(startAddress, registerData);
    if (!success) {
      const response = this.handleException(0, functionCode, ModbusExceptionCode.SLAVE_DEVICE_FAILURE);
      const tcpResponse = this.buildTCPResponse(transactionId, protocolId, unitId, response);
      this.sendResponse(tcpResponse);
      return;
    }
    let response: Uint8Array | null = null;
    const setting = SettingsManager.getInstance();
    const scheduler = await setting.getSchedulerConfig();
    const measureParam = await setting.getMeasureParamConfig();

    // 地址170: 跨度核查间隔 (UINT16, 1个寄存器)
    if (startAddress === REG_ADDR.SPAN_CHECK_INTERVAL && scheduler) {
      if (registerValue >= 0 && registerValue <= 999) {
        scheduler.rangeCheck.interval = registerValue;
        await setting.setSchedulerConfig(scheduler);
      } else {
        Logger.warn('跨度核查间隔超出范围: %d', registerValue);
      }
      response = this.responseWriteSingle(transactionId, protocolId, unitId, startAddress, registerValue);
    }
    // 地址253: 当前量程索引 (UINT16, 1个寄存器)
    else if (startAddress === REG_ADDR.CURRENT_RANGE_INDEX && measureParam) {

      if (registerValue > 0 && registerValue <= 3) {
        measureParam.currentRange = registerValue - 1;
        Logger.debug('写入的索引值: %d (0x%s)', registerValue, registerValue.toString(16));
        await setting.setMeasureParamConfig(measureParam);
      } else {
        Logger.warn('当前量程索引超出范围: %d', registerValue);
      }

      response = this.responseWriteSingle(transactionId, protocolId, unitId, startAddress, registerValue);
    }
    // 地址264: 消解时间 (UINT16, 1个寄存器)
    else if (startAddress === REG_ADDR.DIGESTION_TIME && measureParam) {
      Logger.debug('消解时间: %d (0x%s)', registerValue, registerValue.toString(16));
      if (registerValue >= 0 && registerValue <= 10000) {
        measureParam.digestTime = registerValue;
        await setting.setMeasureParamConfig(measureParam);
      } else {
        Logger.warn('消解时间超出范围: %d', registerValue);
      }
      response = this.responseWriteSingle(transactionId, protocolId, unitId, startAddress, registerValue);
    }
    // 地址267: 反应时间 (UINT16, 1个寄存器)
    else if (startAddress === REG_ADDR.REACTION_TIME && measureParam) {
      if (registerValue >= 0 && registerValue <= 10000) {
        measureParam.reactTime = registerValue;
        await setting.setMeasureParamConfig(measureParam);
      } else {
        Logger.warn('反应时间超出范围: %d', registerValue);
      }
      response = this.responseWriteSingle(transactionId, protocolId, unitId, startAddress, registerValue);
    }
    // 地址272: 测量控制 (UINT16, 1个寄存器)
    else if (startAddress === REG_ADDR.MEASURE_CONTROL) {
      this.emitControlCommand(startAddress, registerValue);
      response = this.responseWriteSingle(transactionId, protocolId, unitId, startAddress, registerValue);
    }
    // 地址273: 采水控制 (UINT16, 1个寄存器)
    else if (startAddress === REG_ADDR.WATER_COLLECT) {
      this.emitControlCommand(startAddress, registerValue);
      response = this.responseWriteSingle(transactionId, protocolId, unitId, startAddress, registerValue);
    }
    // 地址277: 自动测量模式 (UINT16, 1个寄存器)
    else if (startAddress === REG_ADDR.MEASURE_MODE && scheduler) {
      scheduler.measure.mode = registerValue;
      await setting.setSchedulerConfig(scheduler);
      response = this.responseWriteSingle(transactionId, protocolId, unitId, startAddress, registerValue);
    }
    // 地址278: 自动测量时间间隔 (UINT16, 1个寄存器)
    else if (startAddress === REG_ADDR.AUTO_MEASURE_INTERVAL && scheduler) {
      if (registerValue >= 0 && registerValue <= 999) {
        scheduler.measure.interval = registerValue;
        await setting.setSchedulerConfig(scheduler);
      } else {
        Logger.warn('自动测量时间间隔超出范围: %d', registerValue);
      }
      response = this.responseWriteSingle(transactionId, protocolId, unitId, startAddress, registerValue);
    }
    // 地址279: 自动校准模式 (UINT16, 1个寄存器)
    else if (startAddress === REG_ADDR.AUTO_CAL_MODE && scheduler) {
      scheduler.calibrate.mode = registerValue;
      await setting.setSchedulerConfig(scheduler);
      response = this.responseWriteSingle(transactionId, protocolId, unitId, startAddress, registerValue);
    }
    // 地址280: 自动校准时间间隔 (UINT16, 1个寄存器)
    else if (startAddress === REG_ADDR.AUTO_CAL_INTERVAL && scheduler) {
      if (registerValue >= 0 && registerValue <= 999) {
        scheduler.calibrate.interval = registerValue;
        await setting.setSchedulerConfig(scheduler);
      } else {
        Logger.warn('自动校准时间间隔超出范围: %d', registerValue);
      }
      response = this.responseWriteSingle(transactionId, protocolId, unitId, startAddress, registerValue);
    }
    // 地址400: 智能诊断指令 (UINT16, 1个寄存器)
    else if (startAddress === REG_ADDR.SMART_DIAG_CMD) {
      response = this.responseWriteSingle(transactionId, protocolId, unitId, startAddress, registerValue);
    }
    else {
      response = this.responseWriteSingle(transactionId, protocolId, unitId, startAddress, registerValue);
    }
    if (response) {
      this.sendResponse(response);
    }
  }

  // 处理写多个寄存器请求 (功能码10)
  private async handleWriteMultiple(request: ModbusRequest, transactionId: number, protocolId: number, unitId: number): Promise<void> {
    const startAddress = request.startAddress;
    const quantity = request.quantity;
    const data = request.data;
    const functionCode = request.functionCode;

    if (!data || data.length !== quantity * 2) {
      const response = this.handleException(0, functionCode, ModbusExceptionCode.ILLEGAL_DATA_VALUE);
      const tcpResponse = this.buildTCPResponse(transactionId, protocolId, unitId, response);
      this.sendResponse(tcpResponse);
      return;
    }

    for (let i = 0; i < quantity; i++) {
      const regData = data.slice(i * 2, i * 2 + 2);
      const regAddress = startAddress + i;

      const regInfo = this.dataStore.getRegisterInfo(regAddress);
      if (regInfo && regInfo.access === 'R') {
        const response = this.handleException(0, functionCode, ModbusExceptionCode.ILLEGAL_DATA_ADDRESS);
        const tcpResponse = this.buildTCPResponse(transactionId, protocolId, unitId, response);
        this.sendResponse(tcpResponse);
        return;
      }

      const success = this.dataStore.writeRegister(regAddress, regData);
      if (!success) {
        const response = this.handleException(0, functionCode, ModbusExceptionCode.SLAVE_DEVICE_FAILURE);
        const tcpResponse = this.buildTCPResponse(transactionId, protocolId, unitId, response);
        this.sendResponse(tcpResponse);
        return;
      }
    }

    let response: Uint8Array | null = null;
    const setting = SettingsManager.getInstance();
    const measureParam = await setting.getMeasureParamConfig();
    const system = await setting.getSystemConfig();

    // 地址256: 当前量程 (FLOAT32, 2个寄存器)
    if (startAddress === REG_ADDR.CURRENT_RANGE && quantity === 2 && measureParam && system) {
      if (data && data.length >= 4) {
        // 解析浮点数（小端序）
        const buffer = new ArrayBuffer(4);
        const view = new DataView(buffer);
        view.setUint8(0, data[1]);
        view.setUint8(1, data[0]);
        view.setUint8(2, data[3]);
        view.setUint8(3, data[2]);
        const inputValue = view.getFloat32(0, true);
        // 确保 rangeViewMap 数据有效
        if (!system.rangeViewMap || system.rangeViewMap.length === 0) {
          Logger.warn('当前量程rangeViewMap 为空');
          response = this.responseWriteMultiple(transactionId, protocolId, unitId, startAddress, quantity);
          return;
        }

        // 打印配置信息用于调试
        for (let idx = 0; idx < system.rangeViewMap.length; idx++) {
          const item = system.rangeViewMap[idx];
          Logger.debug('当前量程 rangeViewMap[%d]: range=%d, view=%f',
            idx, item?.range, item?.view);
        }
        Logger.debug('当前量程 measureParam.range: [%d, %d, %d]',
          measureParam.range[0], measureParam.range[1], measureParam.range[2]);

        // 第一步：构建激活的量程表
        // measureParam.range 存储的是 rangeViewMap 的索引（0-based）
        // 例如 measureParam.range = [0, 1, 2] 表示使用 rangeViewMap 的第1、2、3个量程
        const rangeTable: number[] = [];
        const activeViewValues: number[] = [];

        for (let i = 0; i < 3; i++) {
          const rangeIndex = measureParam.range[i];
          if (rangeIndex >= 0 && rangeIndex < system.rangeViewMap.length) {
            const rangeItem = system.rangeViewMap[rangeIndex];
            rangeTable.push(rangeItem.range);
            activeViewValues.push(rangeItem.view);
            Logger.debug('当前量程 激活量程[%d]: 索引=%d, 编号=%d, 显示值=%f',
              i, rangeIndex, rangeItem.range, rangeItem.view);
          }
        }
        Logger.debug('当前量程 激活量程编号: %s', JSON.stringify(rangeTable));
        Logger.debug('当前量程 激活量程显示值: %s', JSON.stringify(activeViewValues));

        let matched = false;
        // 第二步：遍历激活的量程显示值，查找匹配项
        for (let v = 0; v < activeViewValues.length; v++) {
          const targetViewValue = activeViewValues[v];
          const targetRangeNumber = rangeTable[v];
          if (inputValue === targetViewValue) {
            // 找到匹配的量程，更新当前量程索引
            measureParam.currentRange = v;
            Logger.debug('当前量程✅ 设置量程成功: currentRange = %d (对应量程编号: %d, 显示值: %f)',
              measureParam.currentRange, targetRangeNumber, targetViewValue);

            await setting.setMeasureParamConfig(measureParam);
            matched = true;
            break;
          }
        }
        if (!matched) {
          Logger.debug('当前量程 ⚠️ 未找到匹配的量程，输入值: %f', inputValue);
          Logger.debug('当前量程 可用的激活量程显示值: %s', JSON.stringify(activeViewValues));
        }
        response = this.responseWriteMultiple(transactionId, protocolId, unitId, startAddress, quantity);
      }
    }
    // 地址260: 校准曲线截距 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.CAL_INTERCEPT && quantity === 2 && measureParam) {
      // data 格式: [byte0, byte1, byte2, byte3] (4个字节，2个寄存器)
      if (data && data.length >= 4) {
        const buffer = new ArrayBuffer(4);
        const view = new DataView(buffer);
        const bytes = new Uint8Array(buffer);
        bytes[0] = data[1];
        bytes[1] = data[0];
        bytes[2] = data[3];
        bytes[3] = data[2];
        const registerValue = view.getFloat32(0, true);

        if (registerValue >= -999999.999999 && registerValue <= 999999.999999) {
          measureParam.curveParam[measureParam.range[measureParam.currentRange + 1]+1].curveB = registerValue
          await setting.setMeasureParamConfig(measureParam);
        }
      }
      response = this.responseWriteMultiple(transactionId, protocolId, unitId, startAddress, quantity);
    }
    // 地址262: 消解温度 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.DIGESTION_TEMP && quantity === 2 && measureParam) {
      // data 格式: [byte0, byte1, byte2, byte3] (4个字节，2个寄存器)
      if (data && data.length >= 4) {
        const buffer = new ArrayBuffer(4);
        const view = new DataView(buffer);
        const bytes = new Uint8Array(buffer);
        bytes[0] = data[1];
        bytes[1] = data[0];
        bytes[2] = data[3];
        bytes[3] = data[2];
        const registerValue = view.getFloat32(0, true);

        if (registerValue >= 0 && registerValue < 200) {
          measureParam.digestTemperature = registerValue
          await setting.setMeasureParamConfig(measureParam);
        }
      }
      response = this.responseWriteMultiple(transactionId, protocolId, unitId, startAddress, quantity);
    }
    // 地址265: 反应温度 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.REACTION_TEMP && quantity === 2 && measureParam) {
      // data 格式: [byte0, byte1, byte2, byte3] (4个字节，2个寄存器)
      if (data && data.length >= 4) {
        const buffer = new ArrayBuffer(4);
        const view = new DataView(buffer);
        const bytes = new Uint8Array(buffer);
        bytes[0] = data[1];
        bytes[1] = data[0];
        bytes[2] = data[3];
        bytes[3] = data[2];
        const registerValue = view.getFloat32(0, true);

        if (registerValue >= 0 && registerValue < 200) {
          measureParam.reactTemperature = registerValue
          await setting.setMeasureParamConfig(measureParam);
        }
      }
      response = this.responseWriteMultiple(transactionId, protocolId, unitId, startAddress, quantity);
    }
    // 地址268: 修正斜率 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.CORRECT_SLOPE && quantity === 2 && measureParam) {
      // data 格式: [byte0, byte1, byte2, byte3] (4个字节，2个寄存器)
      if (data && data.length >= 4) {
        const buffer = new ArrayBuffer(4);
        const view = new DataView(buffer);
        const bytes = new Uint8Array(buffer);
        bytes[0] = data[1];
        bytes[1] = data[0];
        bytes[2] = data[3];
        bytes[3] = data[2];
        const registerValue = view.getFloat32(0, true);

        if (registerValue >= 0 && registerValue < 200) {
          measureParam.reviseFactor = registerValue
          await setting.setMeasureParamConfig(measureParam);
        }
      }
      response = this.responseWriteMultiple(transactionId, protocolId, unitId, startAddress, quantity);
    }
    // 地址270: 修正截距 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.CORRECT_INTERCEPT && quantity === 2 && measureParam) {
      // data 格式: [byte0, byte1, byte2, byte3] (4个字节，2个寄存器)
      if (data && data.length >= 4) {
        const buffer = new ArrayBuffer(4);
        const view = new DataView(buffer);
        const bytes = new Uint8Array(buffer);
        bytes[0] = data[1];
        bytes[1] = data[0];
        bytes[2] = data[3];
        bytes[3] = data[2];
        const registerValue = view.getFloat32(0, true);

        if (registerValue >= 0 && registerValue < 200) {
          measureParam.shiftFactor = registerValue
          await setting.setMeasureParamConfig(measureParam);
        }
      }
      response = this.responseWriteMultiple(transactionId, protocolId, unitId, startAddress, quantity);
    }
    // 地址274: 系统时间 (TIME, 4个寄存器)
    else if (startAddress === REG_ADDR.SYSTEM_TIME && quantity === 4) {
      response = this.responseWriteMultiple(transactionId, protocolId, unitId, startAddress, quantity);
    }
    else {
      response = this.responseWriteMultiple(transactionId, protocolId, unitId, startAddress, quantity);
    }

    if (response) {
      this.sendResponse(response);
    }
  }

  // ==================== 响应构建方法 ====================

  // 构建TCP报文头 + PDU
  private buildTCPResponse(transactionId: number, protocolId: number, unitId: number, pdu: Uint8Array): Uint8Array {
    const response = new Uint8Array(7 + pdu.length);
    response[0] = (transactionId >> 8) & 0xFF;
    response[1] = transactionId & 0xFF;
    response[2] = (protocolId >> 8) & 0xFF;
    response[3] = protocolId & 0xFF;
    response[4] = ((pdu.length + 1) >> 8) & 0xFF;
    response[5] = (pdu.length + 1) & 0xFF;
    response[6] = unitId;
    response.set(pdu, 7);
    return response;
  }
  // 构建UINT8类型PDU
  private buildUint8PDU(functionCode: number, value: number): Uint8Array {
    const pdu = new Uint8Array(3);
    pdu[0] = functionCode;
    pdu[1] = 0x01;
    pdu[2] = value & 0xFF;
    return pdu;
  }
  // 构建UINT16类型PDU
  private buildUint16PDU(functionCode: number, value: number): Uint8Array {
    const pdu = new Uint8Array(4);
    pdu[0] = functionCode;
    pdu[1] = 0x02;
    pdu[2] = (value >> 8) & 0xFF;
    pdu[3] = value & 0xFF;
    return pdu;
  }
  // 构建UINT32类型PDU (大端序)
  private buildUINT32PDU(functionCode: number, value: number): Uint8Array {
    const pdu = new Uint8Array(6);
    pdu[0] = functionCode;
    pdu[1] = 0x04;
    pdu[2] = (value >> 24) & 0xFF;
    pdu[3] = (value >> 16) & 0xFF;
    pdu[4] = (value >> 8) & 0xFF;
    pdu[5] = value & 0xFF;
    return pdu;
  }
  // 构建UINT32类型PDU (小端序)
  private buildSEUINT32PDU(functionCode: number, value: number): Uint8Array {
    const pdu = new Uint8Array(6);
    pdu[0] = functionCode;
    pdu[1] = 0x04;
    pdu[4] = (value >> 24) & 0xFF;
    pdu[5] = (value >> 16) & 0xFF;
    pdu[2] = (value >> 8) & 0xFF;
    pdu[3] = value & 0xFF;
    return pdu;
  }
  // 构建FLOAT32类型PDU (小端序)
  private buildFloat32PDU(functionCode: number, value: number): Uint8Array {
    const buffer = new ArrayBuffer(4);
    const view = new DataView(buffer);
    view.setFloat32(0, value, true);
    const bytes = new Uint8Array(buffer);
    const pdu = new Uint8Array(6);
    pdu[0] = functionCode;
    pdu[1] = 0x04;
    pdu[2] = bytes[1];
    pdu[3] = bytes[0];
    pdu[4] = bytes[3];
    pdu[5] = bytes[2];
    return pdu;
  }
  private buildFloat32ArrayPDU(functionCode: number, values: number[], quantity: number): Uint8Array {
    // quantity 是请求的寄存器数量，每个 FLOAT32 占用 2 个寄存器
    const maxFloats = Math.min(Math.floor(quantity / 2), values.length);
    const byteCount = quantity * 2;
    const pdu = new Uint8Array(2 + byteCount);
    pdu[0] = functionCode;
    pdu[1] = byteCount;

    let byteIndex = 2;
    for (let i = 0; i < maxFloats; i++) {
      const buffer = new ArrayBuffer(4);
      const view = new DataView(buffer);
      view.setFloat32(0, values[i], true); // 小端序
      const bytes = new Uint8Array(buffer);
      // 小端序转 Modbus 大端序寄存器格式
      pdu[byteIndex++] = bytes[1];
      pdu[byteIndex++] = bytes[0];
      pdu[byteIndex++] = bytes[3];
      pdu[byteIndex++] = bytes[2];
    }

    // 剩余寄存器填充0
    while (byteIndex < 2 + byteCount) {
      pdu[byteIndex++] = 0x00;
    }

    return pdu;
  }
  // 构建TIME类型PDU
  private buildTimePDU(functionCode: number, year: number, month: number, day: number, hour: number, minute: number, second: number): Uint8Array {
    const yearOffset = year - 1970;
    const pdu = new Uint8Array(9);
    pdu[0] = functionCode;
    pdu[1] = 0x06;
    pdu[2] = yearOffset & 0xFF;
    pdu[3] = month & 0xFF;
    pdu[4] = day & 0xFF;
    pdu[5] = hour & 0xFF;
    pdu[6] = minute & 0xFF;
    pdu[7] = second & 0xFF;
    return pdu;
  }

  // 构建STRING类型PDU
  private buildStringPDU(functionCode: number, value: string, maxRegisters: number): Uint8Array {
    const maxBytes = maxRegisters * 2;
    const bytes = new Uint8Array(maxBytes);
    for (let i = 0; i < value.length && i < maxRegisters; i++) {
      const code = value.charCodeAt(i);
      bytes[i * 2 + 1] = code & 0xFF ;
      bytes[i * 2] = (code >> 8) & 0xFF ;
    }
    const pdu = new Uint8Array(2 + bytes.length);
    pdu[0] = functionCode;
    pdu[1] = bytes.length;
    pdu.set(bytes, 2);
    return pdu;
  }

  // 构建写单个寄存器PDU
  private buildWriteSinglePDU(address: number, value: number): Uint8Array {
    const pdu = new Uint8Array(5);
    pdu[0] = 0x06;
    pdu[1] = (address >> 8) & 0xFF;
    pdu[2] = address & 0xFF;
    pdu[3] = (value >> 8) & 0xFF;
    pdu[4] = value & 0xFF;
    return pdu;
  }

  // 构建写多个寄存器PDU
  private buildWriteMultiplePDU(startAddress: number, quantity: number): Uint8Array {
    const pdu = new Uint8Array(5);
    pdu[0] = 0x10;
    pdu[1] = (startAddress >> 8) & 0xFF;
    pdu[2] = startAddress & 0xFF;
    pdu[3] = (quantity >> 8) & 0xFF;
    pdu[4] = quantity & 0xFF;
    return pdu;
  }

  // 处理异常PDU
  private handleException(slaveId: number, functionCode: number, exceptionCode: ModbusExceptionCode): Uint8Array {
    const response = new Uint8Array(2);
    response[0] = functionCode | 0x80;
    response[1] = exceptionCode;
    return response;
  }

  // 字节数组转十六进制字符串
  private bytesToHex(bytes: Uint8Array): string {
    let hex: string = '';
    for (let i: number = 0; i < bytes.length; i++) {
      const byteStr: string = bytes[i].toString(16).padStart(2, '0').toUpperCase();
      hex += byteStr;
      if (i < bytes.length - 1) {
        hex += ' ';
      }
    }
    return hex;
  }

  // ==================== 便捷响应方法 ====================

  responseUint16(transactionId: number, protocolId: number, unitId: number, value: number, functionCode: number = 0x03): Uint8Array {
    return this.buildTCPResponse(transactionId, protocolId, unitId, this.buildUint16PDU(functionCode, value));
  }

  responseFloat32(transactionId: number, protocolId: number, unitId: number, value: number, functionCode: number = 0x03): Uint8Array {
    return this.buildTCPResponse(transactionId, protocolId, unitId, this.buildFloat32PDU(functionCode, value));
  }
  responseFloat32Array(transactionId: number, protocolId: number, unitId: number, values: number[], quantity: number, functionCode: number = 0x03): Uint8Array {
    return this.buildTCPResponse(transactionId, protocolId, unitId, this.buildFloat32ArrayPDU(functionCode, values, quantity));
  }
  // 回复读取时间
  responseTime(transactionId: number, protocolId: number, unitId: number, year: number, month: number, day: number, hour: number, minute: number, second: number, functionCode: number = 0x03): Uint8Array {
    return this.buildTCPResponse(transactionId, protocolId, unitId, this.buildTimePDU(functionCode, year, month, day, hour, minute, second));
  }

  responseString(transactionId: number, protocolId: number, unitId: number, value: string, maxRegisters: number, functionCode: number = 0x03): Uint8Array {
    return this.buildTCPResponse(transactionId, protocolId, unitId, this.buildStringPDU(functionCode, value, maxRegisters));
  }
  // 开发板固件版本
  responseFWVersion(transactionId: number, protocolId: number, unitId: number, value: number, functionCode: number = 0x03): Uint8Array {
    return this.buildTCPResponse(transactionId, protocolId, unitId, this.buildUINT32PDU(functionCode, value));
  }
  // 信号值
  responseSignalValue(transactionId: number, protocolId: number, unitId: number, value: number, functionCode: number = 0x03): Uint8Array {
    return this.buildTCPResponse(transactionId, protocolId, unitId, this.buildSEUINT32PDU(functionCode, value));
  }

  responseWriteSingle(transactionId: number, protocolId: number, unitId: number, address: number, value: number): Uint8Array {
    const externalAddress = this.currentTable.toExternalAddress(address);
    return this.buildTCPResponse(transactionId, protocolId, unitId, this.buildWriteSinglePDU(externalAddress, value));
  }

  responseWriteMultiple(transactionId: number, protocolId: number, unitId: number, startAddress: number, quantity: number): Uint8Array {
    const externalAddress = this.currentTable.toExternalAddress(startAddress);
    return this.buildTCPResponse(transactionId, protocolId, unitId, this.buildWriteMultiplePDU(externalAddress, quantity));
  }
}

