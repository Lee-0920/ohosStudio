// lhipstudio/modbus/src/main/ets/model/ModbusRTU.ets

import { hilog } from '@kit.PerformanceAnalysisKit';
import { emitter } from '@kit.BasicServicesKit';
import {
  ModbusRequest,
  ModbusResponse,
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
import { util } from '@kit.ArkTS';
import { SettingsManager, MeasureStatusManager, ManufactureType, Language, ReportMode, MeasureMode, InstrumentInfoConfig } from 'dataservice';
import { Logger,LogFileInfo } from 'logger';
import { AlarmManager, AlarmCode, AlarmRecord, AlarmCallback } from 'alarm';
// import { WorkerManager } from 'flow';

// 定义日志回调函数类型
export type LogCallback = (log: CommLogEntry) => void;

// 定义日期时间接口
interface DateTimeResult {
  year: number;
  month: number;
  day: number;
  hour: number;
  minute: number;
  second: number;
}

export class ModbusRTUHandler {
  private dataStore: DataStore;
  private logCallback: LogCallback | null = null;
  private logId: number = 0;
  private currentTable: ProtocolTable = ProtocolTableRegistry.getDefault();

  constructor() {
    this.dataStore = DataStore.getInstance();
  }

  // 设置日志回调
  setLogCallback(callback: LogCallback): void {
    this.logCallback = callback;
  }

  // 切换当前协议表
  setProtocolTable(table: ProtocolTable): void {
    this.currentTable = table;
  }

  // 获取当前东八区时间
  private getCurrentDateTime(): DateTimeResult {
    const now = new Date();
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
        protocol: 'RTU',
        data: data,
        description: description
      };
      this.logCallback(log);
    }
  }

  // 解析RTU请求
  parseRequest(buffer: Uint8Array): ModbusRequest | null {
    if (buffer.length < 8) return null;

    const hexStr = this.bytesToHex(buffer);
    Logger.debug('ModbusRTU Parsing request: %s', hexStr);

    // 验证CRC
    const receivedCrcLow = buffer[buffer.length - 2];
    const receivedCrcHigh = buffer[buffer.length - 1];
    const receivedCrc = (receivedCrcHigh << 8) | receivedCrcLow;
    const calculatedCrc = this.calculateCRC(buffer.slice(0, buffer.length - 2));

    Logger.debug('ModbusRTU Received CRC (high<<8|low): 0x%s', receivedCrc.toString(16));
    Logger.debug('ModbusRTU Calculated CRC: 0x%s', calculatedCrc.toString(16));

    // 正确比较CRC（两种字节序都要比较）
    const calculatedCrcLow = calculatedCrc & 0xFF;
    const calculatedCrcHigh = (calculatedCrc >> 8) & 0xFF;
    const crcMatch = (receivedCrcLow === calculatedCrcLow && receivedCrcHigh === calculatedCrcHigh);

    if (!crcMatch) {
      Logger.warn('ModbusRTU CRC check failed: received=%02X%02X, calculated=%02X%02X',
        receivedCrcHigh, receivedCrcLow, calculatedCrcHigh, calculatedCrcLow);
      return null;
    }

    const slaveId = buffer[0];
    const functionCode = buffer[1];

    // 从机地址过滤（支持地址1）
    if (slaveId !== 0x01 && slaveId !== 0x00) {
      Logger.warn('ModbusRTU Slave ID mismatch: expected=1, received=%d', slaveId);
      return null;
    }
    let request: ModbusRequest | null = null;
    let description = '';

    if (functionCode === 0x03) { // 读保持寄存器
      if (buffer.length >= 8) {
        const externalAddress = (buffer[2] << 8) | buffer[3];
        const quantity = (buffer[4] << 8) | buffer[5];

        if (quantity < 1 || quantity > 125) {
          Logger.warn('ModbusRTU Invalid quantity: %d', quantity);
          return null;
        }

        const startAddress = this.currentTable.toInternalAddress(externalAddress, functionCode);
        const registerName = this.getRegisterName(externalAddress, functionCode);
        description = `📥 读取保持寄存器请求: 地址=${externalAddress}(${registerName}), 数量=${quantity}`;

        request = {
          slaveId: slaveId,
          functionCode: functionCode,
          startAddress: startAddress,
          quantity: quantity
        };
        Logger.debug('ModbusRTU Parsed read request: externalAddress=%d, internalAddress=%d, quantity=%d',
          externalAddress, startAddress, quantity);
      }
    } else if (functionCode === 0x04) { // 读输入寄存器
      if (buffer.length >= 8) {
        const externalAddress = (buffer[2] << 8) | buffer[3];
        const quantity = (buffer[4] << 8) | buffer[5];

        if (quantity < 1 || quantity > 125) {
          Logger.warn('ModbusRTU Invalid quantity: %d', quantity);
          return null;
        }

        const startAddress = this.currentTable.toInternalAddress(externalAddress, functionCode);
        const registerName = this.getRegisterName(externalAddress, functionCode);
        description = `📥 读取输入寄存器请求: 地址=${externalAddress}(${registerName}), 数量=${quantity}`;

        request = {
          slaveId: slaveId,
          functionCode: functionCode,
          startAddress: startAddress,
          quantity: quantity
        };
        Logger.debug('ModbusRTU Parsed input read request: externalAddress=%d, internalAddress=%d, quantity=%d',
          externalAddress, startAddress, quantity);
      }
    } else if (functionCode === 0x06) { // 写单个寄存器
      if (buffer.length >= 8) {
        const externalAddress = (buffer[2] << 8) | buffer[3];
        const value = (buffer[4] << 8) | buffer[5];
        const dataBytes = buffer.slice(4, 6);

        const startAddress = this.currentTable.toInternalAddress(externalAddress, functionCode);
        const registerName = this.getRegisterName(externalAddress, functionCode);

        if (startAddress === REG_ADDR.MEASURE_CONTROL) {
          description = `📥 测量控制请求: 地址=${externalAddress}(${registerName}), 命令码=${value}(${this.getControlCommandName(value)})`;
        } else if (startAddress === REG_ADDR.SMART_DIAG_CMD) {
          description = `📥 智能诊断指令请求: 地址=${externalAddress}(${registerName}), 命令码=${value}(${this.getSmartDiagnosisCommandName(value)})`;
        } else if (startAddress === REG_ADDR.WATER_COLLECT) {
          description = `📥 采水控制请求: 地址=${externalAddress}(${registerName}), 命令码=${value}`;
        } else {
          description = `📥 写单个寄存器请求: 地址=${externalAddress}(${registerName}), 值=${value}`;
        }

        request = {
          slaveId: slaveId,
          functionCode: functionCode,
          startAddress: startAddress,
          quantity: 1,
          data: dataBytes
        };
        Logger.debug('ModbusRTU Parsed write request: externalAddress=%d, internalAddress=%d, value=%d',
          externalAddress, startAddress, value);
      }
    } else if (functionCode === 0x10) { // 写多个寄存器
      if (buffer.length >= 9) {
        const externalAddress = (buffer[2] << 8) | buffer[3];
        const quantity = (buffer[4] << 8) | buffer[5];
        const byteCount = buffer[6];

        if (buffer.length >= 7 + byteCount + 2) {
          const dataBytes = buffer.slice(7, 7 + byteCount);

          const startAddress = this.currentTable.toInternalAddress(externalAddress, functionCode);
          const registerName = this.getRegisterName(externalAddress, functionCode);
          description = `📥 写多个寄存器请求: 地址=${externalAddress}(${registerName}), 数量=${quantity}, 字节数=${byteCount}`;

          if (startAddress === REG_ADDR.SYSTEM_TIME && quantity === 3) {
            if (dataBytes.length >= 6) {
              const yearOffset = dataBytes[0];
              const month = dataBytes[1];
              const day = dataBytes[2];
              const hour = dataBytes[3];
              const minute = dataBytes[4];
              const second = dataBytes[5];
              const year = 1970 + yearOffset;
              description += ` [设置时间: ${year}-${month}-${day} ${hour}:${minute}:${second}]`;
            }
          }

          request = {
            slaveId: slaveId,
            functionCode: functionCode,
            startAddress: startAddress,
            quantity: quantity,
            data: dataBytes
          };
          Logger.debug('ModbusRTU Parsed write multiple request: externalAddress=%d, internalAddress=%d, quantity=%d',
            externalAddress, startAddress, quantity);
        }
      }
    }

    if (request) {
      this.addLog('RECEIVE', hexStr, description);
    } else if (description) {
      this.addLog('RECEIVE', hexStr, description);
    }

    return request;
  }

  // 获取寄存器名称（address 为外部协议地址）
  private getRegisterName(address: number, functionCode?: number): string {
    const regInfo = this.currentTable.getRegisterInfo(address, functionCode);
    if (regInfo && regInfo.name) {
      return regInfo.name;
    }
    return `未知寄存器(0x${address.toString(16)})`;
  }

  // 获取控制命令名称
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
    hilog.info(0x0000, 'ModbusRTU', 'emit control command address=%{public}d value=%{public}d commandId=%{public}s',
      address, value, commandId);
    emitter.emit(MODBUS_CONTROL_COMMAND_EVENT, eventData);
  }

  // 获取智能诊断指令名称
  private getSmartDiagnosisCommandName(command: number): string {
    const commandMap: Map<number, string> = new Map();
    commandMap.set(1, '零点校准液阀');
    commandMap.set(2, '水样阀');
    commandMap.set(3, '量程校准液阀');
    commandMap.set(4, '零点核查阀');
    commandMap.set(5, '标样(跨度)核查阀');
    commandMap.set(6, '试剂一阀');
    commandMap.set(7, '试剂二阀');
    commandMap.set(8, '试剂三阀');
    commandMap.set(9, '试剂四阀');
    commandMap.set(10, '试剂五阀');
    commandMap.set(11, '消解室阀');
    commandMap.set(12, '分析废液阀');
    commandMap.set(13, '清洗废水阀');
    commandMap.set(14, '定量模块');
    commandMap.set(15, '测量模块');
    commandMap.set(16, '加热模块');
    commandMap.set(17, '冷却模块');
    return commandMap.get(command) || `未知指令(${command})`;
  }

  // 处理请求并生成响应
  async processRequest(request: ModbusRequest): Promise<Uint8Array | null> {
    Logger.debug('ModbusRTU Processing request: FC=%d, Addr=%d, Quantity=%d',
      request.functionCode, request.startAddress, request.quantity);

    let response: Uint8Array | null = null;

    if (request.functionCode === 0x03 || request.functionCode === 0x04) {
      response = await this.handleRead(request);
    } else if (request.functionCode === 0x06) {
      response = await this.handleWriteSingle(request);
    } else if (request.functionCode === 0x10) {
      response = await this.handleWriteMultiple(request);
    } else {
      response = this.handleException(request.slaveId, request.functionCode, ModbusExceptionCode.ILLEGAL_FUNCTION);
    }

    if (response) {
      const hexStr = this.bytesToHex(response);
      Logger.debug('ModbusRTU Response: %s', hexStr);
      this.addLog('SEND', hexStr, `📤 响应报文`);
    }

    return response;
  }

  // ==================== 处理读请求 (功能码03) ====================
  private  async handleRead(request: ModbusRequest): Promise<Uint8Array | null> {
    const slaveId = request.slaveId;
    const functionCode = request.functionCode;
    const startAddress = request.startAddress;
    const quantity = request.quantity;

    if (quantity < 1 || quantity > 125) {
      return this.handleException(slaveId, functionCode, ModbusExceptionCode.ILLEGAL_DATA_VALUE);
    }

    let responseData: Uint8Array | null = null;
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
      responseData = this.buildFloat32ResponseData(value);
    }
    // 地址2: 量程校准液结果 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.RANGE_CAL_RESULT && quantity === 2 && status) {
      const value = status.report.check.consistency;
      responseData = this.buildFloat32ResponseData(value);
    }
    // 地址4: 测量参数 (UINT16, 1个寄存器)
    else if (startAddress === REG_ADDR.MEASURE_PARAM && quantity === 1 && status) {
      const value = status.report.measure.deviceTypeNum || 0;
      responseData = this.buildUint16ResponseData(value);
    }
    // 地址5: 测试结果类型 (UINT16, 1个寄存器)
    else if (startAddress === REG_ADDR.RESULT_TYPE && quantity === 1 && status) {
      const value = status.report.measure.resultType || 0;
      responseData = this.buildUint16ResponseData(value);
    }
    // 地址6: 测量时长 (UINT16, 1个寄存器)
    else if (startAddress === REG_ADDR.MEASURE_DURATION && quantity === 1 && status) {
      const value = status.report.measure.measureTime || 0;
      responseData = this.buildUint16ResponseData(value);
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
      responseData = this.buildTimeResponseData(year, month, day, hour, minute, second);
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
      responseData = this.buildTimeResponseData(year, month, day, hour, minute, second);
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
      responseData = this.buildTimeResponseData(year, month, day, hour, minute, second);
    }
    // 地址16: 系统状态 (UINT16, 1个寄存器)
    else if (startAddress === REG_ADDR.SYSTEM_STATUS && quantity === 1) {
      const value = DataStore.getInstance().getUInt16(startAddress);
      responseData = this.buildUint16ResponseData(value);
      this.addLog('SEND', '', `📤 返回系统状态: ${value}`);
    }
    // 地址17: 当前动作 (UINT16, 1个寄存器)
    else if (startAddress === REG_ADDR.CURRENT_ACTION && quantity === 1) {
      const value = DataStore.getInstance().getUInt16(startAddress);
      responseData = this.buildUint16ResponseData(value);
      this.addLog('SEND', '', `📤 返回当前动作: ${value}`);
    }
    // 地址18: 当前温度 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.CURRENT_TEMP && quantity === 2) {
      const value = 25.5;
      responseData = this.buildFloat32ResponseData(value);
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
      responseData = this.buildTimeResponseData(year, month, day, hour, minute, second);
    }
    // 地址25: 报警代码 (UINT16, 1个寄存器)
    else if (startAddress === REG_ADDR.ALARM_CODE && quantity === 1) {
      /* 其他模块调用告警模块方式：
      // 触发告警
      const alarmMgr = AlarmManager.getInstance();
      alarmMgr.triggerAlarm(AlarmCode.SAMPLE_FAIL, '额外信息');

      // 消除告警
      alarmMgr.clearAlarm(recordId, 'userId');

      // 获取当前告警码（用于 Modbus 寄存器返回）
      const currentCode = alarmMgr.getCurrentAlarmCode(); // 无告警时返回 AlarmCode.NO_ALARM (0)
      */
      //const value = 0;
      const value = AlarmManager.getInstance().getCurrentAlarmCode() as number;
      responseData = this.buildUint16ResponseData(value);
      this.addLog('SEND', '', `📤 返回报警代码: ${value}`);
    }
    // 地址26: 预设量程表上限（一） (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.RANGE_TABLE && quantity === 2 && system && measureParam) {
      const rangeIndex = measureParam.range[1] + 1;
      const rangeViewItem = system.rangeViewMap[rangeIndex];
      const value = rangeViewItem ? rangeViewItem.view : 0;  // 获取 view 属性，默认为 0
      Logger.info('预设量程表上限：%f', value);
      responseData = this.buildFloat32ResponseData(value);
    }
    // 地址28: 预设量程表上限（二） (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.RANGE_TABLE+2 && quantity === 2 && system && measureParam) {
      const rangeIndex = measureParam.range[2] + 1;
      const rangeViewItem = system.rangeViewMap[rangeIndex];
      const value = rangeViewItem ? rangeViewItem.view : 0;  // 获取 view 属性，默认为 0
      Logger.info('预设量程表上限（二）：%f', value);
      responseData = this.buildFloat32ResponseData(value);
    }
    // 地址30: 预设量程表上限（三） (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.RANGE_TABLE+4 && quantity === 2 && system && measureParam) {
      const rangeIndex = measureParam.range[3] + 1;
      const rangeViewItem = system.rangeViewMap[rangeIndex];
      const value = rangeViewItem ? rangeViewItem.view : 0;  // 获取 view 属性，默认为 0
      Logger.info('预设量程表上限（三）：%f', value);
      responseData = this.buildFloat32ResponseData(value);
    }
    // 地址36: 产品名称 (STRING, 32个寄存器)
    else if (startAddress === REG_ADDR.PRODUCT_NAME && quantity <= 32 && info) {
      const str  = info.showName;
      responseData = this.buildStringResponseData(str, quantity);
    }
    // 地址68: 产品型号 (STRING, 32个寄存器)
    else if (startAddress === REG_ADDR.PRODUCT_MODEL && quantity <= 32 && info) {
      const str  = info.showModel;
      responseData = this.buildStringResponseData(str, quantity);
    }
    // 地址100: 生产厂商 (STRING, 32个寄存器)
    else if (startAddress === REG_ADDR.MANUFACTURER && quantity <= 32 && info) {
      const str  = info.manufacturer;
      responseData = this.buildStringResponseData(str, quantity);
    }
    // 地址132: 生产序列号 (STRING, 16个寄存器)
    else if (startAddress === REG_ADDR.SERIAL_NUMBER && quantity <= 16 && info) {
      const str  = info.sn;
      responseData = this.buildStringResponseData(str, quantity);
    }
    // 地址148: 液路板固件版本 (UINT32, 2个寄存器)
    else if (startAddress === REG_ADDR.FW_VERSION_LIQUID && quantity === 2) {
      const value = 0x01000001;
      responseData = this.buildUint32ResponseData(value);
      this.addLog('SEND', '', `📤 返回液路板固件版本: v1.0.0.1`);
    }
    // 地址150: 温控板固件版本 (UINT32, 2个寄存器)
    else if (startAddress === REG_ADDR.FW_VERSION_TEMP && quantity === 2) {
      const value = 0x01000002;
      responseData = this.buildUint32ResponseData(value);
      this.addLog('SEND', '', `📤 返回温控板固件版本: v1.0.0.2`);
    }
    // 地址152: 信号板固件版本 (UINT32, 2个寄存器)
    else if (startAddress === REG_ADDR.FW_VERSION_SIGNAL && quantity === 2) {
      const value = 0x01000003;
      responseData = this.buildUint32ResponseData(value);
      this.addLog('SEND', '', `📤 返回信号板固件版本: v1.0.0.3`);
    }
    // 地址154: 主控板固件版本 (UINT32, 2个寄存器)
    else if (startAddress === REG_ADDR.FW_VERSION_MAIN && quantity === 2) {
      const value = 0x01000004;
      responseData = this.buildUint32ResponseData(value);
      this.addLog('SEND', '', `📤 返回主控板固件版本: v1.0.0.4`);
    }
    // 地址156: 驱动板固件版本 (UINT32, 2个寄存器)
    else if (startAddress === REG_ADDR.FW_VERSION_DRIVER && quantity === 2) {
      const value = 0x01000005;
      responseData = this.buildUint32ResponseData(value);
      this.addLog('SEND', '', `📤 返回驱动板固件版本: v1.0.0.5`);
    }
    // 地址158: 反应板固件版本 (UINT32, 2个寄存器)
    else if (startAddress === REG_ADDR.FW_VERSION_REACTION && quantity === 2) {
      const value = 0x01000006;
      responseData = this.buildUint32ResponseData(value);
      this.addLog('SEND', '', `📤 返回反应板固件版本: v1.0.0.6`);
    }
    // 地址163: 跨度核查设置浓度 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.SPAN_CHECK_SET && quantity === 2 && measureParam) {
      const value = measureParam.checkConsistency;
      responseData = this.buildFloat32ResponseData(value);
    }
    // 地址165: 跨度核查结果 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.SPAN_CHECK_RESULT && quantity === 2 && status) {
      const value = status.report.rangeCheck.consistency;
      responseData = this.buildFloat32ResponseData(value);
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
      responseData = this.buildTimeResponseData(year, month, day, hour, minute, second);
    }
    // 地址170: 跨度核查间隔 (UINT16, 1个寄存器)
    else if (startAddress === REG_ADDR.SPAN_CHECK_INTERVAL && quantity === 1 && scheduler) {
      const value = scheduler.rangeCheck.interval;
      responseData = this.buildUint16ResponseData(value);
    }
    // 地址190: 水样吸光度 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.WATER_ABSORBANCE && quantity === 2 && status) {
      const value = status.report.measure.absorbance || 0;
      responseData = this.buildFloat32ResponseData(value);
    }
    // 地址192: 水样数据标识 (Uint16, 1个寄存器)
    else if (startAddress === REG_ADDR.WATER_DATA_FLAG && quantity === 1 && status) {
      const resultInfo = status.report.measure.resultInfo || 'N';  // 默认为 'N' (正常)
      const value = resultInfo.charCodeAt(0);
      responseData = this.buildUint16ResponseData(value);
    }
    // 地址193: 测量程校准液吸光度 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.RANGE_CAL_ABSORBANCE && quantity === 2 && status) {
      const value = status.report.check.absorbance || 0;
      responseData = this.buildFloat32ResponseData(value);
    }
    // 地址195: 测量程校准液数据标识 (Uint16, 1个寄存器)
    else if (startAddress === REG_ADDR.RANGE_CAL_DATA_FLAG && quantity === 1 && status) {
      const resultInfo = status.report.check.resultInfo || 'N';  // 默认为 'N' (正常)
      const value = resultInfo.charCodeAt(0);
      responseData = this.buildUint16ResponseData(value);
    }
    // 地址199: 核查液吸光度 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.CHECK_ABSORBANCE && quantity === 2 && status) {
      const value = status.report.rangeCheck.absorbance || 0;
      responseData = this.buildFloat32ResponseData(value);
    }
    // 地址201: 核查液数据标识 (Uint16, 1个寄存器)
    else if (startAddress === REG_ADDR.CHECK_DATA_FLAG && quantity === 1 && status) {
      const resultInfo = status.report.rangeCheck.resultInfo || 'N';  // 默认为 'N' (正常)
      const value = resultInfo.charCodeAt(0);
      responseData = this.buildUint16ResponseData(value);
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
      responseData = this.buildTimeResponseData(year, month, day, hour, minute, second);
    }
    // 地址220: 校准零点浓度 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.ZERO_CAL_CONC && quantity === 2 && status && measureParam) {
      const value = status.calibrate[measureParam.range[measureParam.currentRange + 1]+1].zeroCalculateConsistency;
      responseData = this.buildFloat32ResponseData(value);
    }
    // 地址222: 校准零点吸光度 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.ZERO_CAL_ABSORBANCE && quantity === 2 && status && measureParam) {
      const value = status.calibrate[measureParam.range[measureParam.currentRange + 1]+1].point0Absorbance;
      responseData = this.buildFloat32ResponseData(value);
    }
    // 地址224: 零点漂移 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.ZERO_DRIFT && quantity === 2) {
      const value = 50.72;
      responseData = this.buildFloat32ResponseData(value);
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
      responseData = this.buildTimeResponseData(year, month, day, hour, minute, second);
    }
    // 地址230: 校准标点浓度 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.CAL_STANDARD_CONC && quantity === 2 && status && measureParam) {
      const value = status.calibrate[measureParam.range[measureParam.currentRange + 1]+1].standardCalculateConsistency;
      responseData = this.buildFloat32ResponseData(value);
    }
    // 地址232: 校准标点吸光度 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.CAL_STANDARD_ABSORBANCE && quantity === 2 && status && measureParam) {
      const value = status.calibrate[measureParam.range[measureParam.currentRange + 1]+1].point1Absorbance;
      responseData = this.buildFloat32ResponseData(value);
    }
    // 地址234: 量程漂移 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.RANGE_DRIFT && quantity === 2) {
      const value = 60.72;
      responseData = this.buildFloat32ResponseData(value);
      this.addLog('SEND', '', `📤 返回量程漂移: ${value.toFixed(2)} %`);
    }
    // 地址236: 复合测量结果 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.COMPOSITE_RESULT && quantity === 2 && status) {
      const value = status.report.complexResult.consistency || 0;
      responseData = this.buildFloat32ResponseData(value);
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
      responseData = this.buildTimeResponseData(year, month, day, hour, minute, second);
    }
    // 地址241: 复合测量数据标识 (Uint16, 1个寄存器)
    else if (startAddress === REG_ADDR.COMPOSITE_DATA_FLAG && quantity === 1 && status) {
      const resultInfo = status.report.complexResult.resultInfo || 'N';  // 默认为 'N' (正常)
      const value = resultInfo.charCodeAt(0);
      responseData = this.buildUint16ResponseData(value);
    }
    // 地址242: 系数常数 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.COEFF_CONST && quantity === 2) {
      const value = 10.0;
      responseData = this.buildFloat32ResponseData(value);
      this.addLog('SEND', '', `📤 返回系数常数: ${value}`);
    }
    // 地址244: 系数比例 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.COEFF_RATIO && quantity === 2) {
      const value = 2.0;
      responseData = this.buildFloat32ResponseData(value);
      this.addLog('SEND', '', `📤 返回系数比例: ${value}`);
    }
    // 地址246: 流量控制 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.FLOW_CONTROL && quantity === 2) {
      const value = 3.0;
      responseData = this.buildFloat32ResponseData(value);
      this.addLog('SEND', '', `📤 返回流量控制: ${value}`);
    }
    // 地址248: TOC测量结果 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.TOC_RESULT && quantity === 2) {
      const value = 12.0;
      responseData = this.buildFloat32ResponseData(value);
      this.addLog('SEND', '', `📤 返回TOC测量结果: ${value}`);
    }
    // 地址253: 当前量程索引 (Uint16, 1个寄存器)
    else if (startAddress === REG_ADDR.CURRENT_RANGE_INDEX && quantity === 1 && measureParam) {
      const value = measureParam.currentRange + 1;
      responseData = this.buildUint16ResponseData(value);
    }
    // 地址254: 当前量程下限值 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.CURRENT_RANGE_LOWER && quantity === 2) {
      const value = 4.00;
      responseData = this.buildFloat32ResponseData(value);
      this.addLog('SEND', '', `📤 返回当前量程下限值: ${value}`);
    }
    // 地址256: 当前量程 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.CURRENT_RANGE && quantity === 2 && system && measureParam) {
      const value = system.rangeViewMap[measureParam.range[measureParam.currentRange]].view;
      responseData = this.buildFloat32ResponseData(value);
    }
    // 地址258: 校准曲线斜率 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.CAL_SLOPE && quantity === 2 && measureParam) {
      const value = measureParam.curveParam[measureParam.range[measureParam.currentRange + 1]+1].curveK;
      responseData = this.buildFloat32ResponseData(value);
    }
    // 地址260: 校准曲线截距 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.CAL_INTERCEPT && quantity === 2 && measureParam) {
      const value = measureParam.curveParam[measureParam.range[measureParam.currentRange + 1]+1].curveB;
      responseData = this.buildFloat32ResponseData(value);
    }
    // 地址262: 消解温度 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.DIGESTION_TEMP && quantity === 2 && measureParam) {
      const value = measureParam.digestTemperature;
      responseData = this.buildFloat32ResponseData(value);
    }
    // 地址264: 消解时间 (Uint16, 1个寄存器)
    else if (startAddress === REG_ADDR.DIGESTION_TIME && quantity === 1 && measureParam) {
      const value = measureParam.digestTime;
      responseData = this.buildUint16ResponseData(value);
    }
    // 地址265: 反应温度 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.REACTION_TEMP && quantity === 2 && measureParam) {
      const value = measureParam.reactTemperature;
      responseData = this.buildFloat32ResponseData(value);
    }
    // 地址267: 反应时间 (Uint16, 1个寄存器)
    else if (startAddress === REG_ADDR.REACTION_TIME && quantity === 1 && measureParam) {
      const value = measureParam.reactTime;
      responseData = this.buildUint16ResponseData(value);
    }
    // 地址268: 修正斜率 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.CORRECT_SLOPE && quantity === 2 && measureParam) {
       const value = measureParam.reviseFactor;
      responseData = this.buildFloat32ResponseData(value);
    }
    // 地址270: 修正截距 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.CORRECT_INTERCEPT && quantity === 2 && measureParam) {
      const value = measureParam.shiftFactor;
      responseData = this.buildFloat32ResponseData(value);
    }
    // 地址274: 系统时间 (TIME, 3个寄存器)
    else if (startAddress === REG_ADDR.SYSTEM_TIME && quantity === 3) {
      const currentTime = this.getCurrentDateTime();
      responseData = this.buildTimeResponseData(
        currentTime.year, currentTime.month, currentTime.day,
        currentTime.hour, currentTime.minute, currentTime.second
      );
      this.addLog('SEND', '', `📤 返回系统时间: ${currentTime.year}-${currentTime.month}-${currentTime.day} ${currentTime.hour}:${currentTime.minute}:${currentTime.second}`);
    }
    // 地址277: 测量模式 (Uint16, 1个寄存器)
    else if (startAddress === REG_ADDR.MEASURE_MODE && quantity === 1 && scheduler) {
      const value = scheduler.measure.mode;
      responseData = this.buildUint16ResponseData(value);
    }
    // 地址278: 自动测量时间间隔 (Uint16, 1个寄存器)
    else if (startAddress === REG_ADDR.AUTO_MEASURE_INTERVAL && quantity === 1 && scheduler) {
      const value = scheduler.measure.interval;
      responseData = this.buildUint16ResponseData(value);
    }
    // 地址279: 自动校准模式 (Uint16, 1个寄存器)
    else if (startAddress === REG_ADDR.AUTO_CAL_MODE && quantity === 1 && scheduler) {
      const value = scheduler.calibrate.mode;
      responseData = this.buildUint16ResponseData(value);
    }
    // 地址280: 自动校准时间间隔 (Uint16, 1个寄存器)
    else if (startAddress === REG_ADDR.AUTO_CAL_INTERVAL && quantity === 1 && scheduler) {
      const value = scheduler.calibrate.interval;
      responseData = this.buildUint16ResponseData(value);
    }
    // 地址283: 当前量程稀释倍数 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.DILUTION_FACTOR && quantity === 2 && measureParam) {
      const value = measureParam.range[measureParam.currentRange + 1] + 1;
      responseData = this.buildFloat32ResponseData(value);
    }
    // 地址293: 零点校准液浓度 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.ZERO_CAL_CONCENTRATION && quantity === 2 && measureParam) {
      const value = measureParam.curveParam[measureParam.range[measureParam.currentRange + 1]+1].zeroConsistency;
      responseData = this.buildFloat32ResponseData(value);
    }
    // 地址295: 量程校准液浓度 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.RANGE_CAL_CONCENTRATION && quantity === 2 && measureParam) {
      const value = measureParam.curveParam[measureParam.range[measureParam.currentRange + 1]+1].rangeConsistency;
      responseData = this.buildFloat32ResponseData(value);
    }
    // 地址300: 试剂一加液体积 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.REAGENT1_VOLUME && quantity === 2) {
      const value = 3.0125;
      responseData = this.buildFloat32ResponseData(value);
      this.addLog('SEND', '', `📤 返回试剂一加液体积: ${value}`);
    }
    // 地址302: 试剂二加液体积 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.REAGENT2_VOLUME && quantity === 2) {
      const value = 5.0;
      responseData = this.buildFloat32ResponseData(value);
      this.addLog('SEND', '', `📤 返回试剂二加液体积: ${value}`);
    }
    // 地址304: 试剂三加液体积 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.REAGENT3_VOLUME && quantity === 2) {
      const value = 3.0125;
      responseData = this.buildFloat32ResponseData(value);
      this.addLog('SEND', '', `📤 返回试剂三加液体积: ${value}`);
    }
    // 地址306: 试剂四加液体积 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.REAGENT4_VOLUME && quantity === 2) {
      const value = 5.0;
      responseData = this.buildFloat32ResponseData(value);
      this.addLog('SEND', '', `📤 返回试剂四加液体积: ${value}`);
    }
    // 地址308: 试剂五加液体积 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.REAGENT5_VOLUME && quantity === 2) {
      const value = 3.0125;
      responseData = this.buildFloat32ResponseData(value);
      this.addLog('SEND', '', `📤 返回试剂五加液体积: ${value}`);
    }
    // 地址310: 当前量程校正因子 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.CALIBRATION_FACTOR && quantity === 2 && measureParam) {
      const value = measureParam.reviseParameter[measureParam.range[measureParam.currentRange + 1]+1];
      responseData = this.buildFloat32ResponseData(value);
    }
    // 地址312: 核查允许偏差值 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.CHECK_ALLOW_DEVIATION && quantity === 2 && measureParam) {
      const value = measureParam.checkErrorLimit;
      responseData = this.buildFloat32ResponseData(value);
    }
    // 地址314: 核查偏差值 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.CHECK_DEVIATION && quantity === 2&& status) {
      const value = status.report.rangeCheck.checkError;
      responseData = this.buildFloat32ResponseData(value);
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
      responseData = this.buildStringResponseData(value, quantity);
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
      responseData = this.buildFloat32ArrayResponseData(rangeValues, quantity);
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
      responseData = this.buildFloat32ArrayResponseData(rangeValues, quantity);
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
      responseData = this.buildFloat32ArrayResponseData(rangeValues, quantity);
    }
    // 地址401: 智能诊断结果 (UINT16, 1个寄存器)
    else if (startAddress === REG_ADDR.SMART_DIAG_RESULT && quantity === 1) {
      const value = 2; //DiagnosticResult.PASSED.charCodeAt(0);通过
      responseData = this.buildUint16ResponseData(value);
    }
    // 地址402: 消解室温度 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.DIGESTION_ROOM_TEMP && quantity === 2) {
      const value = 25.0;
      responseData = this.buildFloat32ResponseData(value);
      this.addLog('SEND', '', `📤 返回消解室温度: ${value.toFixed(1)}°C`);
    }
    // 地址404: 环境温度 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.AMBIENT_TEMP && quantity === 2) {
      const value = 22.0;
      responseData = this.buildFloat32ResponseData(value);
      this.addLog('SEND', '', `📤 返回环境温度: ${value.toFixed(1)}°C`);
    }
    // 地址406: 定量点1信号 (UINT32, 2个寄存器)
    else if (startAddress === REG_ADDR.QUANT_POINT1_SIGNAL && quantity === 2) {
      const value = 7;
      responseData = this.buildUint32ResponseData(value);
      this.addLog('SEND', '', `📤 返回定量点1信号: ${value}`);
    }
    // 地址408: 定量点2信号 (UINT32, 2个寄存器)
    else if (startAddress === REG_ADDR.QUANT_POINT2_SIGNAL && quantity === 2) {
      const value = 8;
      responseData = this.buildUint32ResponseData(value);
      this.addLog('SEND', '', `📤 返回定量点2信号: ${value}`);
    }
    // 地址410: 参考AD信号 (UINT32, 2个寄存器)
    else if (startAddress === REG_ADDR.REFERENCE_AD_SIGNAL && quantity === 2) {
      const value = 9;
      responseData = this.buildUint32ResponseData(value);
      this.addLog('SEND', '', `📤 返回参考AD信号: ${value}`);
    }
    // 地址412: 测量AD信号 (UINT32, 2个寄存器)
    else if (startAddress === REG_ADDR.MEASURE_AD_SIGNAL && quantity === 2) {
      const value = 10;
      responseData = this.buildUint32ResponseData(value);
      this.addLog('SEND', '', `📤 返回测量AD信号: ${value}`);
    }
    // 地址414: 泵管系数 (FLOAT32, 2个寄存器)
    else if (startAddress === REG_ADDR.PUMP_TUBE_COEFF && quantity === 2 && hardwareConfig) {
      const value = hardwareConfig.pumpFactor.real;
      responseData = this.buildFloat32ResponseData(value);
    }
    // 地址500: 日志条数 (Uint16, 1个寄存器)
    else if (startAddress === REG_ADDR.LOG_COUNT && quantity === 1) {
      const filesInfo = Logger.getAllLogFilesInfo();
      const sysLogFiles = filesInfo.filter((f: LogFileInfo) => f.fileName.includes('RunLog.txt'));
      if(sysLogFiles.length > 0){
        const value = sysLogFiles[0].lineCount;//99;
        Logger.info('日志条数：%d', value);
        responseData = this.buildUint16ResponseData(value);
        this.addLog('SEND', '', `📤 返回日志条数: ${value}`);
      }
    }
    // 地址501: 日志 (STRING, 99个寄存器)
    else if (startAddress === REG_ADDR.LOG_CONTENT && quantity <= 99) {
      Logger.info('日志 (STRING, 99个寄存器)');
      const logStr = Logger.readAllLogs('RunLog.txt');
      //const logStr = Logger.readLogsFromFile('RunLog.txt',100);
      hilog.info(0x0000,'地址501','日志内容：%{public}s 长度：%{public}d',logStr,logStr.length);
      responseData = this.buildStringResponseData(logStr, quantity);
      this.addLog('SEND', '', `📤 返回日志: ${logStr}`);
    }
    // 默认：返回非法数据地址异常
    else {
      return this.handleException(slaveId, functionCode, ModbusExceptionCode.ILLEGAL_DATA_ADDRESS);
    }

    if (responseData) {
      return this.buildReadResponse(slaveId, functionCode, responseData);
    }

    return null;
  }

  // ==================== 处理写单个寄存器请求 (功能码06) ====================
  private async handleWriteSingle(request: ModbusRequest): Promise<Uint8Array | null> {
    const slaveId = request.slaveId;
    const functionCode = request.functionCode;
    const startAddress = request.startAddress;
    const data = request.data;

    if (!data || data.length !== 2) {
      return this.handleException(slaveId, functionCode, ModbusExceptionCode.ILLEGAL_DATA_VALUE);
    }

    const value = (data[0] << 8) | data[1];
    Logger.debug('ModbusRTU Write single register: address=%d, value=0x%s (%d)',
      startAddress, value.toString(16), value);

    // 检查寄存器是否存在且可写
    const regInfo = this.dataStore.getRegisterInfo(startAddress);
    if (regInfo && regInfo.access === 'R') {
      return this.handleException(slaveId, functionCode, ModbusExceptionCode.ILLEGAL_DATA_ADDRESS);
    }

    // 写入数据
    const success = this.dataStore.writeRegister(startAddress, data);
    if (!success) {
      return this.handleException(slaveId, functionCode, ModbusExceptionCode.SLAVE_DEVICE_FAILURE);
    }
    const setting = SettingsManager.getInstance();
    const scheduler = await setting.getSchedulerConfig();
    const measureParam = await setting.getMeasureParamConfig();

    // 地址170: 跨度核查间隔 (UINT16, 1个寄存器)
    if (startAddress === REG_ADDR.SPAN_CHECK_INTERVAL && scheduler) {
      if (value >= 0 && value <= 999) {
        scheduler.rangeCheck.interval = value;
        await setting.setSchedulerConfig(scheduler);
      } else {
        Logger.warn('跨度核查间隔超出范围: %d', value);
      }
      return this.buildEchoResponse(slaveId, functionCode, startAddress, value);
    }
    // 地址253: 当前量程索引 (UINT16, 1个寄存器)
    else if (startAddress === REG_ADDR.CURRENT_RANGE_INDEX && measureParam) {
      if (value > 0 && value <= 3) {
        measureParam.currentRange = value - 1;
        Logger.info('写入当前量程索引值: %d (0x%s)', value, value.toString(16));
        await setting.setMeasureParamConfig(measureParam);
      } else {
        Logger.warn('当前量程索引超出范围: %d', value);
      }
      return this.buildEchoResponse(slaveId, functionCode, startAddress, value);
    }
    // 地址264: 消解时间 (UINT16, 1个寄存器)
    else if (startAddress === REG_ADDR.DIGESTION_TIME && measureParam) {
      Logger.info('消解时间: %d (0x%s)', value, value.toString(16));
      if (value >= 0 && value <= 10000) {
        measureParam.digestTime = value;
        await setting.setMeasureParamConfig(measureParam);
      } else {
        Logger.warn('消解时间超出范围: %d', value);
      }
      return this.buildEchoResponse(slaveId, functionCode, startAddress, value);
    }
    // 地址267: 反应时间 (UINT16, 1个寄存器)
    else if (startAddress === REG_ADDR.REACTION_TIME && measureParam) {
      if (value >= 0 && value <= 10000) {
        measureParam.reactTime = value;
        await setting.setMeasureParamConfig(measureParam);
      } else {
        Logger.warn('反应时间超出范围: %d', value);
      }
      return this.buildEchoResponse(slaveId, functionCode, startAddress, value);
    }
    // 地址272: 测量控制 (UINT16, 1个寄存器)
    else if (startAddress === REG_ADDR.MEASURE_CONTROL) {
      this.emitControlCommand(startAddress, value);
      return this.buildEchoResponse(slaveId, functionCode, startAddress, value);
    }
    // 地址273: 采水控制 (UINT16, 1个寄存器)
    else if (startAddress === REG_ADDR.WATER_COLLECT) {
      this.emitControlCommand(startAddress, value);
      return this.buildEchoResponse(slaveId, functionCode, startAddress, value);
    }
    // 地址277: 自动测量模式 (UINT16, 1个寄存器)
    else if (startAddress === REG_ADDR.MEASURE_MODE && scheduler) {
      scheduler.measure.mode = value;
      await setting.setSchedulerConfig(scheduler);
      return this.buildEchoResponse(slaveId, functionCode, startAddress, value);
    }
    // 地址278: 自动测量时间间隔 (UINT16, 1个寄存器)
    else if (startAddress === REG_ADDR.AUTO_MEASURE_INTERVAL && scheduler) {
      if (value >= 0 && value <= 999) {
        scheduler.measure.interval = value;
        await setting.setSchedulerConfig(scheduler);
      } else {
        Logger.warn('自动测量时间间隔超出范围: %d', value);
      }
      return this.buildEchoResponse(slaveId, functionCode, startAddress, value);
    }
    // 地址279: 自动校准模式 (UINT16, 1个寄存器)
    else if (startAddress === REG_ADDR.AUTO_CAL_MODE && scheduler) {
      scheduler.calibrate.mode = value;
      await setting.setSchedulerConfig(scheduler);
      return this.buildEchoResponse(slaveId, functionCode, startAddress, value);
    }
    // 地址280: 自动校准时间间隔 (UINT16, 1个寄存器)
    else if (startAddress === REG_ADDR.AUTO_CAL_INTERVAL && scheduler) {
      if (value >= 0 && value <= 999) {
        scheduler.calibrate.interval = value;
        await setting.setSchedulerConfig(scheduler);
      } else {
        Logger.warn('自动校准时间间隔超出范围: %d', value);
      }
      return this.buildEchoResponse(slaveId, functionCode, startAddress, value);
    }
    // 地址400: 智能诊断指令 (UINT16, 1个寄存器)
    else if (startAddress === REG_ADDR.SMART_DIAG_CMD) {
      return this.buildEchoResponse(slaveId, functionCode, startAddress, value);
    }
    else {
      return this.buildEchoResponse(slaveId, functionCode, startAddress, value);
    }
    // 返回回显响应
    //return this.buildEchoResponse(slaveId, functionCode, startAddress, value);
  }

  // ==================== 处理写多个寄存器请求 (功能码10) ====================
  private async handleWriteMultiple(request: ModbusRequest): Promise<Uint8Array | null> {
    const slaveId = request.slaveId;
    const functionCode = request.functionCode;
    const startAddress = request.startAddress;
    const quantity = request.quantity;
    const data = request.data;

    if (!data || data.length !== quantity * 2) {
      return this.handleException(slaveId, functionCode, ModbusExceptionCode.ILLEGAL_DATA_VALUE);
    }

    Logger.debug('ModbusRTU Write multiple registers: address=%d, quantity=%d', startAddress, quantity);

    // 逐个写入寄存器
    for (let i = 0; i < quantity; i++) {
      const regData = data.slice(i * 2, i * 2 + 2);
      const regAddress = startAddress + i;

      // 检查可写性
      const regInfo = this.dataStore.getRegisterInfo(regAddress);
      if (regInfo && regInfo.access === 'R') {
        return this.handleException(slaveId, functionCode, ModbusExceptionCode.ILLEGAL_DATA_ADDRESS);
      }

      const success = this.dataStore.writeRegister(regAddress, regData);
      if (!success) {
        return this.handleException(slaveId, functionCode, ModbusExceptionCode.SLAVE_DEVICE_FAILURE);
      }
    }

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
          return this.buildWriteMultipleResponse(slaveId, functionCode, startAddress, quantity);
        }

        // 打印配置信息用于调试
        for (let idx = 0; idx < system.rangeViewMap.length; idx++) {
          const item = system.rangeViewMap[idx];
          Logger.info('当前量程rangeViewMap[%d]: range=%d, view=%f',
            idx, item?.range, item?.view);
        }
        Logger.info('当前量程 measureParam.range: [%d, %d, %d]',
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
            Logger.info('当前量程激活量程[%d]: 索引=%d, 编号=%d, 显示值=%f',
              i, rangeIndex, rangeItem.range, rangeItem.view);
          }
        }
        Logger.info('当前量程激活量程编号: %s', JSON.stringify(rangeTable));
        Logger.info('当前量程激活量程显示值: %s', JSON.stringify(activeViewValues));

        let matched = false;
        // 第二步：遍历激活的量程显示值，查找匹配项
        for (let v = 0; v < activeViewValues.length; v++) {
          const targetViewValue = activeViewValues[v];
          const targetRangeNumber = rangeTable[v];
          if (inputValue === targetViewValue) {
            // 找到匹配的量程，更新当前量程索引
            measureParam.currentRange = v;
            Logger.info('当前量程✅ 设置量程成功: currentRange = %d (对应量程编号: %d, 显示值: %f)',
              measureParam.currentRange, targetRangeNumber, targetViewValue);

            await setting.setMeasureParamConfig(measureParam);
            matched = true;
            break;
          }
        }
        if (!matched) {
          Logger.info('当前量程⚠️ 未找到匹配的量程，输入值: %f', inputValue);
          Logger.info('当前量程可用的激活量程显示值: %s', JSON.stringify(activeViewValues));
        }
        return this.buildWriteMultipleResponse(slaveId, functionCode, startAddress, quantity);
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
      return this.buildWriteMultipleResponse(slaveId, functionCode, startAddress, quantity);
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
      return this.buildWriteMultipleResponse(slaveId, functionCode, startAddress, quantity);
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
      return this.buildWriteMultipleResponse(slaveId, functionCode, startAddress, quantity);
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
      return this.buildWriteMultipleResponse(slaveId, functionCode, startAddress, quantity);
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
      return this.buildWriteMultipleResponse(slaveId, functionCode, startAddress, quantity);
    }
    // 地址274: 设置系统时间 (TIME, 3个寄存器)
    else if (startAddress === REG_ADDR.SYSTEM_TIME && quantity === 3 && data && data.length >= 6) {
      this.handleTimeSet(data);
    }
    // 返回响应: 地址 + 功能码 + 起始地址 + 寄存器数量 + CRC
    return this.buildWriteMultipleResponse(slaveId, functionCode, startAddress, quantity);
  }

  // 处理时间设置
  private handleTimeSet(data: Uint8Array): void {
    if (data.length >= 6) {
      const yearOffset = data[0];
      const month = data[1];
      const day = data[2];
      const hour = data[3];
      const minute = data[4];
      const second = data[5];
      const year = 1970 + yearOffset;
      Logger.debug('ModbusRTU System time set to: %d-%d-%d %d:%d:%d',
        year, month, day, hour, minute, second);
    }
  }

  // ==================== 响应构建方法 ====================

  // 构建读响应 (地址 + 功能码 + 字节数 + 数据 + CRC)
  private buildReadResponse(slaveId: number, functionCode: number, data: Uint8Array): Uint8Array {
    const response = new Uint8Array(3 + data.length + 2);
    response[0] = slaveId;
    response[1] = functionCode;
    response[2] = data.length;
    response.set(data, 3);

    const crc = this.calculateCRC(response.slice(0, response.length - 2));
    response[response.length - 2] = crc & 0xFF;
    response[response.length - 1] = (crc >> 8) & 0xFF;

    return response;
  }

  // 构建UINT16响应数据
  private buildUint16ResponseData(value: number): Uint8Array {
    const data = new Uint8Array(2);
    data[0] = (value >> 8) & 0xFF;
    data[1] = value & 0xFF;
    return data;
  }

  // 构建UINT32响应数据 (大端序，用于固件版本等)
  private buildUint32ResponseData(value: number): Uint8Array {
    const data = new Uint8Array(4);
    data[0] = (value >> 24) & 0xFF;
    data[1] = (value >> 16) & 0xFF;
    data[2] = (value >> 8) & 0xFF;
    data[3] = value & 0xFF;
    return data;
  }

  // 构建FLOAT32响应数据
  private buildFloat32ResponseData(value: number): Uint8Array {
    const buffer = new ArrayBuffer(4);
    const view = new DataView(buffer);
    // 使用大端序存储
    view.setFloat32(0, value, false);
    const bytes = new Uint8Array(buffer);

    // 交换字节顺序以匹配设备期望
    // 原始大端序: [0] [1] [2] [3]
    // 设备期望:   [2] [3] [0] [1]
    const swapped = new Uint8Array(4);
    swapped[0] = bytes[2];
    swapped[1] = bytes[3];
    swapped[2] = bytes[0];
    swapped[3] = bytes[1];

    Logger.debug('ModbusRTU Float32 value: %f, original bytes: %s, swapped bytes: %s',
      value, this.bytesToHex(bytes), this.bytesToHex(swapped));

    return swapped;
  }

  // 构建FLOAT32数组响应数据
  private buildFloat32ArrayResponseData(values: number[], quantity: number): Uint8Array {
    const maxFloats = Math.min(Math.floor(quantity / 2), values.length);
    const byteCount = quantity * 2;
    const data = new Uint8Array(byteCount);

    let byteIndex = 0;
    for (let i = 0; i < maxFloats; i++) {
      const buffer = new ArrayBuffer(4);
      const view = new DataView(buffer);
      view.setFloat32(0, values[i], false);
      const bytes = new Uint8Array(buffer);
      data[byteIndex++] = bytes[0];
      data[byteIndex++] = bytes[1];
      data[byteIndex++] = bytes[2];
      data[byteIndex++] = bytes[3];
    }

    while (byteIndex < byteCount) {
      data[byteIndex++] = 0x00;
    }

    return data;
  }

  // 构建TIME响应数据 (6字节)
  private buildTimeResponseData(year: number, month: number, day: number, hour: number, minute: number, second: number): Uint8Array {
    const yearOffset = year - 1970;
    const data = new Uint8Array(6);
    data[0] = yearOffset & 0xFF;
    data[1] = month & 0xFF;
    data[2] = day & 0xFF;
    data[3] = hour & 0xFF;
    data[4] = minute & 0xFF;
    data[5] = second & 0xFF;
    return data;
  }

  // 构建STRING响应数据
  private buildStringResponseData(value: string, quantity: number): Uint8Array {
    const maxBytes = quantity * 2;
    const bytes = new Uint8Array(maxBytes);

    for (let i = 0; i < value.length && i < quantity; i++) {
      const code = value.charCodeAt(i);
      bytes[i * 2 + 1] = code & 0xFF;
      bytes[i * 2] = (code >> 8) & 0xFF;
    }
    return bytes;
  }

  // 构建回显响应（写单个寄存器）
  private buildEchoResponse(slaveId: number, functionCode: number, address: number, value: number): Uint8Array {
    const externalAddress = this.currentTable.toExternalAddress(address);
    const response = new Uint8Array(8);
    response[0] = slaveId;
    response[1] = functionCode;
    response[2] = (externalAddress >> 8) & 0xFF;
    response[3] = externalAddress & 0xFF;
    response[4] = (value >> 8) & 0xFF;
    response[5] = value & 0xFF;

    const crc = this.calculateCRC(response.slice(0, 6));
    response[6] = crc & 0xFF;
    response[7] = (crc >> 8) & 0xFF;

    return response;
  }

  // 构建写多个寄存器响应
  private buildWriteMultipleResponse(slaveId: number, functionCode: number, startAddress: number, quantity: number): Uint8Array {
    const externalAddress = this.currentTable.toExternalAddress(startAddress);
    const response = new Uint8Array(8);
    response[0] = slaveId;
    response[1] = functionCode;
    response[2] = (externalAddress >> 8) & 0xFF;
    response[3] = externalAddress & 0xFF;
    response[4] = (quantity >> 8) & 0xFF;
    response[5] = quantity & 0xFF;

    const crc = this.calculateCRC(response.slice(0, 6));
    response[6] = crc & 0xFF;
    response[7] = (crc >> 8) & 0xFF;

    return response;
  }

  // 处理异常响应
  private handleException(slaveId: number, functionCode: number, exceptionCode: ModbusExceptionCode): Uint8Array {
    Logger.warn('ModbusRTU Exception: FC=%d, Code=%d', functionCode, exceptionCode);

    const response = new Uint8Array(5);
    response[0] = slaveId;
    response[1] = functionCode | 0x80;
    response[2] = exceptionCode;

    const crc = this.calculateCRC(response.slice(0, 3));
    response[3] = crc & 0xFF;
    response[4] = (crc >> 8) & 0xFF;

    return response;
  }

  // 计算CRC16 (Modbus标准算法)
  private calculateCRC(buffer: Uint8Array): number {
    let crc = 0xFFFF;
    for (let i = 0; i < buffer.length; i++) {
      crc ^= buffer[i];
      for (let j = 0; j < 8; j++) {
        if ((crc & 0x0001) !== 0) {
          crc = (crc >> 1) ^ 0xA001;
        } else {
          crc = crc >> 1;
        }
      }
    }
    return crc;
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
}