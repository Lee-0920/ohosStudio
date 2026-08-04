import { hilog } from '@kit.PerformanceAnalysisKit';
import { DeviceContext } from './devices/DeviceContext';
import { CommunicationMode as DeviceCommunicationMode } from './devices/WaterQualityDevice';
import { MeasurementService } from './MeasurementService';
import { OperationLogService } from './OperationLogService';
import { SystemInfoSessionStore } from './SystemInfoSessionStore';
import { dncp } from 'communication';
import { FooterBar } from '../components/FooterBar';
import {
  LOG_RESULT_SUCCESS,
  OPERATION_LOG_TYPE_COMMUNICATION,
  OPERATION_LOG_TYPE_MAINTENANCE
} from '../models/dataRecordTypes';
import {
  BoardInfo,
  DeviceRuntimeStatus,
  InstrumentInfo,
  MeasurementConfig,
  MeasurementSnapshot
} from '../models/deviceTypes';
import {
  PhotoTekAlarmCodes,
  PhotoTekCompositeDataFlags,
  PhotoTekCurrentActions,
  PhotoTekDataFlags,
  PhotoTekInputRegisters,
  PhotoTekMeasurementResultTypes,
  PhotoTekSystemStatuses
} from './protocol/PhotoTekInputRegisters';
import {
  PhotoTekAutoCalibrationModes,
  PhotoTekHoldRegisters,
  PhotoTekMeasurementControlCodes,
  PhotoTekMeasurementModes
} from './protocol/PhotoTekHoldRegisters';
import {
  PhotoTekCodeDescription,
  PhotoTekDataFlag,
  PhotoTekFirmwareVersion,
  PhotoTekHoldRegisterDefinition,
  PhotoTekInputRegisterDefinition,
  PhotoTekMeasurementParameterInfo,
  PhotoTekTemperatureValue,
  PhotoTekTimeValue
} from './protocol/PhotoTekTypes';

const DOMAIN = 0x0003;
const TAG = 'MonitorService';

export type CommunicationMode = DeviceCommunicationMode;
export type DeviceConnectionState = 'disconnected' | 'online';
export type ConnectionStateListener = (state: DeviceConnectionState) => void;

// 面向页面层的业务服务：页面只关心测量、校准、清洗和读数，不直接处理 TCP 或串口细节。
export class MonitorService {
  // 最近一次读到的参数和测量值缓存，用于同步 UI 展示。
  private static measurementParamCode: number = 1018;
  private static measurementParamName: string = '-';
  private static measurementParamInfo: PhotoTekMeasurementParameterInfo = {
    code: 1018,
    legacyCode: '011',
    name: 'TN',
    unit: 'mg/L'
  };
  private static measurementValue: number = 0;
  private static measurementCalibrationSolutionValue: number = 0;
  private static measuring: boolean = false;
  private static measurementStartedAt: number = 0;

  private static measurementParamListener: ((code: number, name: string) => void) | null = null;
  private static measurementValueListener: ((value: number) => void) | null = null;
  private static measurementCalibrationSolutionValueListener: ((value: number) => void) | null = null;
  private static measurementStateListener: ((isMeasuring: boolean) => void) | null = null;
  private static connectionState: DeviceConnectionState = 'disconnected';
  private static connectionStateListeners: ConnectionStateListener[] = [];
  private static measurementParamRefreshPromise: Promise<number | null> | null = null;
  private static systemInfoRefreshPromise: Promise<void> | null = null;

  /**
   * 判断当前业务通道是否使用以太网 TCP。
   *
   * @returns 当前通信模式是 tcp 时返回 true，否则返回 false。
   */
  static isUsingEthernet(): boolean {
    return DeviceContext.getDevice().getMode() === 'tcp';
  }

  /**
   * 获取当前通信模式。
   *
   * @returns 当前通信模式，取值为 tcp 或 uart。
   */
  static getCommunicationMode(): CommunicationMode {
    return DeviceContext.getDevice().getMode();
  }

  /**
   * 按旧 UI 布尔值接口切换通信模式。
   *
   * @param ethernetMode true 表示使用 Modbus TCP，false 表示使用 Modbus RTU/UART。
   */
  static setCommunicationMode(ethernetMode: boolean): void {
    MonitorService.setMode(ethernetMode ? 'tcp' : 'uart');
  }

  /**
   * 切换通信模式，实际通道管理由设备层负责。
   *
   * @param mode 目标通信模式，取值为 tcp 或 uart。
   */
  static setMode(mode: CommunicationMode): void {
    DeviceContext.getDevice().setMode(mode);
    MonitorService.setConnectionState('disconnected');
  }

  /**
   * 设置 MCU Modbus TCP 连接地址。
   *
   * @param ip MCU IP 地址。
   * @param port MCU TCP 端口，PhotoTek 默认端口为 502。
   */
  static setMcuConfig(ip: string, port: number): void {
    DeviceContext.getDevice().setMcuConfig(ip, port);
  }

  /**
   * 设置 UART/RTU 串口参数。
   *
   * @param path 串口设备路径。
   * @param baudRate 波特率。
   * @param dataBits 数据位，默认 8。
   * @param stopBits 停止位，默认 1。
   * @param parity 校验位，默认 N。
   * @param isRs485 是否启用 RS485 半双工方向控制，默认 false。
   */
  static setUartConfig(
    path: string,
    baudRate: number,
    dataBits: number = 8,
    stopBits: number = 1,
    parity: string = 'N',
    isRs485: boolean = false
  ): void {
    DeviceContext.getDevice().setUartConfig(path, baudRate, dataBits, stopBits, parity, isRs485);
    MonitorService.setConnectionState('disconnected');
  }

  /**
   * 获取当前业务连接状态。
   *
   * @returns online 表示设备业务协议已连通；disconnected 表示未连接或通道不可用。
   */
  static getConnectionState(): DeviceConnectionState {
    MonitorService.syncConnectionStateFromDevice();
    return MonitorService.connectionState;
  }

  /**
   * 注册业务连接状态变化监听器。
   *
   * @param listener 状态变化回调；同一个函数重复注册会被忽略。
   */
  static addConnectionStateListener(listener: ConnectionStateListener): void {
    if (MonitorService.connectionStateListeners.indexOf(listener) >= 0) {
      return;
    }
    MonitorService.connectionStateListeners.push(listener);
  }

  /**
   * 移除业务连接状态变化监听器。
   *
   * @param listener 之前注册的状态变化回调。
   */
  static removeConnectionStateListener(listener: ConnectionStateListener): void {
    MonitorService.connectionStateListeners = MonitorService.connectionStateListeners.filter(
      (item: ConnectionStateListener) => item !== listener
    );
  }

  /**
   * 注册测量参数变化监听器。
   *
   * @param listener 监听回调，参数为测量参数码和参数名称；传 null 表示取消监听。
   */
  static setMeasurementParamListener(listener: ((code: number, name: string) => void) | null): void {
    MonitorService.measurementParamListener = listener;
  }

  /**
   * 注册测量结果变化监听器。
   *
   * @param listener 监听回调，参数为测量结果数值；传 null 表示取消监听。
   */
  static setMeasurementValueListener(listener: ((value: number) => void) | null): void {
    MonitorService.measurementValueListener = listener;
  }

  /**
   * 注册测量校准液结果变化监听器。
   *
   * @param listener 监听回调，参数为测量校准液结果数值；传 null 表示取消监听。
   */
  static setMeasurementCalibrationSolutionValueListener(listener: ((value: number) => void) | null): void {
    MonitorService.measurementCalibrationSolutionValueListener = listener;
  }

  /**
   * 注册测量运行状态变化监听器。
   *
   * @param listener 监听回调，参数为是否正在测量；传 null 表示取消监听。
   */
  static setMeasurementStateListener(listener: ((isMeasuring: boolean) => void) | null): void {
    MonitorService.measurementStateListener = listener;
  }

  /**
   * 获取当前缓存的测量参数名称。
   *
   * @returns 当前测量参数名称，例如 COD、总氮。
   */
  static getCurrentMeasurementParamName(): string {
    return MonitorService.measurementParamName;
  }

  /**
   * 获取当前缓存的完整测量参数信息。
   *
   * @returns 当前测量参数码、旧码值、名称和单位。
   */
  static getCurrentMeasurementParameterInfo(): PhotoTekMeasurementParameterInfo {
    return MonitorService.measurementParamInfo;
  }

  /**
   * 获取当前缓存的测量结果。
   *
   * @returns 最近一次成功读取的测量结果。
   */
  static getCurrentMeasurementValue(): number {
    return MonitorService.measurementValue;
  }

  /**
   * 获取当前缓存的测量校准液结果。
   *
   * @returns 最近一次成功读取的测量校准液结果。
   */
  static getCurrentMeasurementCalibrationSolutionValue(): number {
    return MonitorService.measurementCalibrationSolutionValue;
  }

  /**
   * 获取测量运行状态。
   *
   * @returns 当前正在测量时返回 true，否则返回 false。
   */
  static isMeasurementRunning(): boolean {
    return MonitorService.measuring;
  }

  /**
   * 复位测量运行状态，每次状态切为空闲后，调用该接口复位运行状态。
   */
  static resetMeasurementRunning(): void {
    MonitorService.measuring = false;
  }

  /**
   * 获取当前测量已运行时长。
   *
   * 这是 UI 状态辅助值，不直接访问 Modbus 寄存器；测量未运行或开始时间未知时返回 0。
   *
   * @returns 当前测量已运行秒数。
   */
  static getMeasurementRunningSeconds(): number {
    if (!MonitorService.measuring || MonitorService.measurementStartedAt <= 0) {
      return 0;
    }
    return Math.max(0, Math.floor((Date.now() - MonitorService.measurementStartedAt) / 1000));
  }

  /**
   * 刷新并缓存当前测量参数码。
   *
   * Modbus: 功能码 0x04，输入寄存器 4，长度 1。
   *
   * @returns 成功返回测量参数新码值；连接失败或响应异常时返回 null。
   */
  static async refreshMeasurementParameter(): Promise<number | null> {
    if (MonitorService.measurementParamRefreshPromise) {
      return MonitorService.measurementParamRefreshPromise;
    }

    MonitorService.measurementParamRefreshPromise = MonitorService.readMeasurementParameter();
    try {
      return await MonitorService.measurementParamRefreshPromise;
    } finally {
      MonitorService.measurementParamRefreshPromise = null;
    }
  }

  /**
   * 连接当前通信通道，并在连接成功后刷新测量参数。
   *
   * @returns 连接成功返回 true，失败返回 false。
   */
  static async connect(): Promise<boolean> {
    const mode = MonitorService.getCommunicationMode();
    return OperationLogService.runWithLog({
      logType: OPERATION_LOG_TYPE_COMMUNICATION,
      action: '连接设备',
      content: `连接${mode === 'tcp' ? 'TCP' : 'UART'}通信通道`,
      source: 'monitor_service'
    }, async (): Promise<boolean> => {
      const connected = await MonitorService.ensureConnected();
      MonitorService.setConnectionState(connected ? 'online' : 'disconnected');
      if (connected) {
        const paramCode = await MonitorService.refreshMeasurementParameter();
        if (paramCode !== null) {
          SystemInfoSessionStore.updateMeasurementProject(MonitorService.measurementParamName);
        }
        void MonitorService.refreshSystemInfoSessionStore();
      }
      return connected;
    });
  }

  /**
   * 探测当前业务通信通道是否协议可用。
   *
   * 业务作用：供后台连接监督器执行低频重连/心跳探测，不记录用户操作日志。
   * Modbus：实际探测由设备实现完成，当前 PhotoTek 设备使用功能码 0x04 读取输入寄存器 16（系统状态），长度 1。
   * 返回值：收到合法协议响应返回 true；通道无法打开、无响应或响应非法返回 false。
   * 失败语义：失败会把业务连接状态同步为 disconnected，但不弹窗、不写运行日志。
   */
  static async probeConnection(): Promise<boolean> {
    const connected = await MonitorService.ensureConnected();
    MonitorService.setConnectionState(connected ? 'online' : 'disconnected');
    return connected;
  }

  /**
   * 执行 Dashboard 网关转发的纯 Modbus 请求。
   *
   * 业务作用：由 Monitor 北向 Modbus TCP 网关调用，并通过当前 PhotoTekDevice 自动选择 TCP 或 UART 通道。
   * Modbus：支持功能码 0x03、0x04、0x06、0x10；寄存器地址、数量和值均由请求 PDU 携带。
   * 参数单位：PDU 为原始协议字节，不在本层换算业务单位。
   * 返回值：成功返回从功能码开始的纯响应 PDU，合法 Modbus 异常 PDU也会原样返回。
   * 失败语义：设备连接失败、无响应或传输校验失败时返回 null，并同步业务连接状态。
   *
   * @param unitId Modbus Unit ID，当前 PhotoTek 设备为 1。
   * @param requestPdu 从功能码开始的纯 Modbus 请求 PDU。
   * @returns 纯响应 PDU；传输失败返回 null。
   */
  static async executeGatewayModbusRequest(
    unitId: number,
    requestPdu: Uint8Array
  ): Promise<Uint8Array | null> {
    if (!MonitorService.isConnectedToMcu() && !(await MonitorService.probeConnection())) {
      return null;
    }
    const response = await DeviceContext.getDevice().executeRawModbusRequest(
      unitId,
      requestPdu,
      'Dashboard网关请求'
    );
    MonitorService.syncConnectionStateFromDevice();
    return response;
  }

  /**
   * 断开设备通信通道。
   */
  static disconnect(): void {
    const mode = MonitorService.getCommunicationMode();
    DeviceContext.getDevice().disconnect();
    MonitorService.setConnectionState('disconnected');
    void OperationLogService.record({
      logType: OPERATION_LOG_TYPE_COMMUNICATION,
      action: '断开设备',
      content: `断开${mode === 'tcp' ? 'TCP' : 'UART'}通信通道`,
      source: 'monitor_service'
    }, LOG_RESULT_SUCCESS);
  }

  /**
   * 判断当前业务通道是否已连接。
   *
   * @returns 当前通道已连接返回 true，否则返回 false。
   */
  static isConnectedToMcu(): boolean {
    return MonitorService.syncConnectionStateFromDevice();
  }

  /**
   * 读取当前测量参数完整信息。
   *
   * Modbus: 功能码 0x04，输入寄存器 4，长度 1。
   * 返回仪器当前测试的水质参数码，并根据 PhotoTek 参数码表解析参数名称、旧码值和单位。
   *
   * @returns 成功返回测量参数信息；连接失败或响应异常时返回 null。
   */
  static async readMeasurementParameterInfo(): Promise<PhotoTekMeasurementParameterInfo | null> {
    const paramInfo = await DeviceContext.getDevice().readMeasurementParameterInfo();
    if (!paramInfo) {
      return null;
    }
    MonitorService.cacheMeasurementParameterInfo(paramInfo);
    return paramInfo;
  }

  /**
   * 读取当前测量参数码。
   *
   * Modbus: 功能码 0x04，输入寄存器 4，长度 1。
   * 这是兼容旧页面逻辑的方法；需要名称、旧码值和单位时使用 readMeasurementParameterInfo。
   *
   * @returns 成功返回测量参数新码值；连接失败或响应异常时返回 null。
   */
  static async readMeasurementParameter(): Promise<number | null> {
    const paramInfo = await MonitorService.readMeasurementParameterInfo();
    return paramInfo ? paramInfo.code : null;
  }

  /**
   * 读取上一次测量结果。
   *
   * Modbus: 功能码 0x04，输入寄存器 0，长度 2。
   * 数据类型为 PhotoTek CDAB 字节序浮点数，单位由当前测量参数决定。
   *
   * @returns 成功返回测量结果；连接失败或响应异常时返回 null。
   */
  static async readMeasurementResult(): Promise<number | null> {
    const paramCode = await MonitorService.refreshMeasurementParameter();
    if (paramCode === null) {
      hilog.error(DOMAIN, TAG, '读取测量结果失败: 测量参数刷新失败');
      return null;
    }

    const value = await DeviceContext.getDevice().readMeasurementResult();
    if (value === null) {
      return null;
    }

    MonitorService.cacheMeasurementValue(value);
    return value;
  }

  /**
   * 读取上一次测量校准液结果。
   *
   * Modbus: 功能码 0x04，输入寄存器 2，长度 2。
   * 数据类型为 PhotoTek CDAB 字节序浮点数，单位通常为 mg/L。
   *
   * @returns 成功返回测量校准液结果；连接失败或响应异常时返回 null。
   */
  static async readMeasurementCalibrationSolutionResult(): Promise<number | null> {
    const value = await DeviceContext.getDevice().readMeasurementCalibrationSolutionResult();
    if (value === null) {
      return null;
    }

    MonitorService.cacheMeasurementCalibrationSolutionValue(value);
    return value;
  }

  /**
   * 读取测量快照，并同步 MonitorService 的参数、测量值和校准液结果缓存。
   *
   * Modbus: 聚合读取测量参数、测量结果、结果类型、测量时间、校准/核查相关输入寄存器。
   * 关键字段为测量参数和测量结果；关键字段失败时返回 null，可选字段在返回对象中为 null。
   *
   * @returns 成功返回测量快照；连接失败或关键字段响应异常时返回 null。
   */
  static async readMeasurementSnapshot(): Promise<MeasurementSnapshot | null> {
    const snapshot = await MeasurementService.readMeasurementSnapshot();
    if (!snapshot) {
      return null;
    }

    MonitorService.cacheMeasurementParameterInfo(snapshot.parameter);
    MonitorService.cacheMeasurementValue(snapshot.result);
    if (snapshot.calibrationSolutionResult !== null) {
      MonitorService.cacheMeasurementCalibrationSolutionValue(snapshot.calibrationSolutionResult);
    }
    return snapshot;
  }

  /**
   * 读取设备运行状态聚合信息。
   *
   * Modbus: 聚合读取系统状态、当前动作、当前温度、报警时间和报警代码。
   * 关键字段为系统状态和当前动作；关键字段失败时返回 null，可选字段在返回对象中为 null。
   *
   * @returns 成功返回运行状态；连接失败或关键字段响应异常时返回 null。
   */
  static async readRuntimeStatus(): Promise<DeviceRuntimeStatus | null> {
    return DeviceContext.getDevice().readRuntimeStatus();
  }

  /**
   * 读取测量配置聚合信息。
   *
   * Modbus: 聚合读取当前量程、测量模式、自动测量/校准间隔、温度时间和校准参数等保持寄存器。
   * 输入寄存器 26 的量程表不完整，不参与正常设置业务，只保留独立调试读取接口。
   * 关键字段为当前量程和测量模式；关键字段失败时返回 null，可选字段在返回对象中为 null。
   *
   * @returns 成功返回测量配置；连接失败或关键字段响应异常时返回 null。
   */
  static async readMeasurementConfig(): Promise<MeasurementConfig | null> {
    return DeviceContext.getDevice().readMeasurementConfig();
  }

  /**
   * 读取仪器基础信息。
   *
   * Modbus: 聚合读取产品名称、产品型号、生产厂商和生产序列号输入寄存器。
   * 这些字段都作为关键字段，任一字段失败时返回 null。
   *
   * @returns 成功返回仪器信息；连接失败或任一关键字段响应异常时返回 null。
   */
  static async readInstrumentInfo(): Promise<InstrumentInfo | null> {
    return DeviceContext.getDevice().readInstrumentInfo();
  }

  /**
   * 读取板卡固件信息。
   *
   * Modbus: 聚合读取液路板、温控板、信号板、主控板、驱动板和反应板固件版本输入寄存器。
   * 单个板卡读取失败时对应 firmwareVersion 为 null；全部失败时返回 null。
   *
   * @returns 成功返回板卡固件信息；连接失败或全部板卡读取失败时返回 null。
   */
  static async readBoardInfo(): Promise<BoardInfo | null> {
    return DeviceContext.getDevice().readBoardInfo();
  }

  /**
   * 读取测试结果类型。
   *
   * Modbus: 功能码 0x04，输入寄存器 5，长度 1。
   * 码值会解析为零点校准液、水样、量程校准液、跨度核查或质控样等含义。
   *
   * @returns 成功返回码值及含义；连接失败或响应异常时返回 null。
   */
  static async readMeasurementResultType(): Promise<PhotoTekCodeDescription | null> {
    return MonitorService.readCodeDescriptionInputRegister(
      PhotoTekInputRegisters.MEASUREMENT_RESULT_TYPE,
      PhotoTekMeasurementResultTypes,
      '未知测试结果类型',
      '读取测试结果类型'
    );
  }

  /**
   * 读取上一次测量时长。
   *
   * Modbus: 功能码 0x04，输入寄存器 6，长度 1，单位秒。
   *
   * @returns 成功返回测量时长秒数；连接失败或响应异常时返回 null。
   */
  static async readMeasurementDurationSeconds(): Promise<number | null> {
    return MonitorService.readUInt16InputRegister(
      PhotoTekInputRegisters.MEASUREMENT_DURATION,
      '读取测量时长'
    );
  }

  /**
   * 读取上一次测量时间。
   *
   * Modbus: 功能码 0x04，输入寄存器 7，长度 3。
   *
   * @returns 成功返回结构化时间；连接失败或响应异常时返回 null。
   */
  static async readMeasurementTime(): Promise<PhotoTekTimeValue | null> {
    return MonitorService.readTimeInputRegister(
      PhotoTekInputRegisters.MEASUREMENT_TIME,
      '读取测量时间'
    );
  }

  /**
   * 读取上一次测量校准液时间。
   *
   * Modbus: 功能码 0x04，输入寄存器 10，长度 3。
   *
   * @returns 成功返回结构化时间；连接失败或响应异常时返回 null。
   */
  static async readCalibrationSolutionTime(): Promise<PhotoTekTimeValue | null> {
    return MonitorService.readTimeInputRegister(
      PhotoTekInputRegisters.CALIBRATION_SOLUTION_TIME,
      '读取测量校准液时间'
    );
  }

  /**
   * 读取上一次校准时间。
   *
   * Modbus: 功能码 0x04，输入寄存器 13，长度 3。
   *
   * @returns 成功返回结构化时间；连接失败或响应异常时返回 null。
   */
  static async readCalibrationTime(): Promise<PhotoTekTimeValue | null> {
    return MonitorService.readTimeInputRegister(
      PhotoTekInputRegisters.CALIBRATION_TIME,
      '读取校准时间'
    );
  }

  /**
   * 读取系统状态。
   *
   * Modbus: 功能码 0x04，输入寄存器 16，长度 1。
   *
   * @returns 成功返回系统状态码及含义；连接失败或响应异常时返回 null。
   */
  static async readSystemStatus(): Promise<PhotoTekCodeDescription | null> {
    return MonitorService.readCodeDescriptionInputRegister(
      PhotoTekInputRegisters.SYSTEM_STATUS,
      PhotoTekSystemStatuses,
      '未知系统状态',
      '读取系统状态'
    );
  }

  /**
   * 读取当前动作。
   *
   * Modbus: 功能码 0x04，输入寄存器 17，长度 1。
   *
   * @returns 成功返回当前动作码及含义；连接失败或响应异常时返回 null。
   */
  static async readCurrentAction(): Promise<PhotoTekCodeDescription | null> {
    return MonitorService.readCodeDescriptionInputRegister(
      PhotoTekInputRegisters.CURRENT_ACTION,
      PhotoTekCurrentActions,
      '未知动作',
      '读取当前动作'
    );
  }

  /**
   * 读取当前温度。
   *
   * Modbus: 功能码 0x04，输入寄存器 18，长度 4。
   * 前 2 个寄存器为消解室温度，后 2 个寄存器为环境温度。
   *
   * @returns 成功返回消解室温度和环境温度；连接失败或响应异常时返回 null。
   */
  static async readCurrentTemperatures(): Promise<PhotoTekTemperatureValue | null> {
    const values = await MonitorService.readFloatArrayInputRegister(
      PhotoTekInputRegisters.CURRENT_TEMPERATURE,
      2,
      '读取当前温度'
    );
    if (!values || values.length < 2) {
      return null;
    }
    const temperatureValue: PhotoTekTemperatureValue = {
      digestionTemperature: values[0],
      ambientTemperature: values[1],
      unit: PhotoTekInputRegisters.CURRENT_TEMPERATURE.unit
    };
    return temperatureValue;
  }

  /**
   * 读取最近报警时间。
   *
   * Modbus: 功能码 0x04，输入寄存器 22，长度 3。
   *
   * @returns 成功返回结构化时间；连接失败或响应异常时返回 null。
   */
  static async readAlarmTime(): Promise<PhotoTekTimeValue | null> {
    return MonitorService.readTimeInputRegister(
      PhotoTekInputRegisters.ALARM_TIME,
      '读取报警时间'
    );
  }

  /**
   * 读取报警代码。
   *
   * Modbus: 功能码 0x04，输入寄存器 25，长度 1。
   *
   * @returns 成功返回报警码及含义；连接失败或响应异常时返回 null。
   */
  static async readAlarmCode(): Promise<PhotoTekCodeDescription | null> {
    return MonitorService.readCodeDescriptionInputRegister(
      PhotoTekInputRegisters.ALARM_CODE,
      PhotoTekAlarmCodes,
      '未知报警',
      '读取报警代码'
    );
  }

  /**
   * 读取系统支持的量程表。
   *
   * Modbus: 功能码 0x04，输入寄存器 26，长度 6。
   * 每 2 个寄存器为一个 CDAB 浮点数，遇到 0 表示结束。
   *
   * @returns 成功返回量程上限数组；连接失败或响应异常时返回 null。
   */
  static async readRangeTable(): Promise<number[] | null> {
    const values = await MonitorService.readFloatArrayInputRegister(
      PhotoTekInputRegisters.RANGE_TABLE,
      PhotoTekInputRegisters.RANGE_TABLE.registerCount / 2,
      '读取量程表'
    );
    if (!values) {
      return null;
    }

    const ranges: number[] = [];
    for (const value of values) {
      if (value === 0) {
        break;
      }
      ranges.push(value);
    }
    return ranges;
  }

  /**
   * 读取产品名称。
   *
   * Modbus: 功能码 0x04，输入寄存器 36，长度 32，UTF-16BE 字符串。
   *
   * @returns 成功返回产品名称；连接失败或响应异常时返回 null。
   */
  static async readProductName(): Promise<string | null> {
    return MonitorService.readStringInputRegister(
      PhotoTekInputRegisters.PRODUCT_NAME,
      '读取产品名称'
    );
  }

  /**
   * 读取产品型号。
   *
   * Modbus: 功能码 0x04，输入寄存器 68，长度 32，UTF-16BE 字符串。
   *
   * @returns 成功返回产品型号；连接失败或响应异常时返回 null。
   */
  static async readProductModel(): Promise<string | null> {
    return MonitorService.readStringInputRegister(
      PhotoTekInputRegisters.PRODUCT_MODEL,
      '读取产品型号'
    );
  }

  /**
   * 读取生产厂商。
   *
   * Modbus: 功能码 0x04，输入寄存器 100，长度 32，UTF-16BE 字符串。
   *
   * @returns 成功返回生产厂商；连接失败或响应异常时返回 null。
   */
  static async readManufacturer(): Promise<string | null> {
    return MonitorService.readStringInputRegister(
      PhotoTekInputRegisters.MANUFACTURER,
      '读取生产厂商'
    );
  }

  /**
   * 读取生产序列号。
   *
   * Modbus: 功能码 0x04，输入寄存器 132，长度 16，UTF-16BE 字符串。
   *
   * @returns 成功返回生产序列号；连接失败或响应异常时返回 null。
   */
  static async readSerialNumber(): Promise<string | null> {
    return MonitorService.readStringInputRegister(
      PhotoTekInputRegisters.SERIAL_NUMBER,
      '读取生产序列号'
    );
  }

  /**
   * 读取液路板固件版本。
   *
   * Modbus: 功能码 0x04，输入寄存器 148，长度 2。
   *
   * @returns 成功返回固件版本；连接失败或响应异常时返回 null。
   */
  static async readLiquidBoardFirmwareVersion(): Promise<PhotoTekFirmwareVersion | null> {
    return MonitorService.readFirmwareVersionInputRegister(
      PhotoTekInputRegisters.LIQUID_BOARD_FIRMWARE,
      '读取液路板固件版本'
    );
  }

  /**
   * 读取温控板固件版本。
   *
   * Modbus: 功能码 0x04，输入寄存器 150，长度 2。
   *
   * @returns 成功返回固件版本；连接失败或响应异常时返回 null。
   */
  static async readTemperatureBoardFirmwareVersion(): Promise<PhotoTekFirmwareVersion | null> {
    return MonitorService.readFirmwareVersionInputRegister(
      PhotoTekInputRegisters.TEMPERATURE_BOARD_FIRMWARE,
      '读取温控板固件版本'
    );
  }

  /**
   * 读取信号板固件版本。
   *
   * Modbus: 功能码 0x04，输入寄存器 152，长度 2。
   *
   * @returns 成功返回固件版本；连接失败或响应异常时返回 null。
   */
  static async readSignalBoardFirmwareVersion(): Promise<PhotoTekFirmwareVersion | null> {
    return MonitorService.readFirmwareVersionInputRegister(
      PhotoTekInputRegisters.SIGNAL_BOARD_FIRMWARE,
      '读取信号板固件版本'
    );
  }

  /**
   * 读取主控板固件版本。
   *
   * Modbus: 功能码 0x04，输入寄存器 154，长度 2。
   *
   * @returns 成功返回固件版本；连接失败或响应异常时返回 null。
   */
  static async readMainBoardFirmwareVersion(): Promise<PhotoTekFirmwareVersion | null> {
    return MonitorService.readFirmwareVersionInputRegister(
      PhotoTekInputRegisters.MAIN_BOARD_FIRMWARE,
      '读取主控板固件版本'
    );
  }

  /**
   * 读取驱动板固件版本。
   *
   * Modbus: 功能码 0x04，输入寄存器 156，长度 2。
   *
   * @returns 成功返回固件版本；连接失败或响应异常时返回 null。
   */
  static async readDriverBoardFirmwareVersion(): Promise<PhotoTekFirmwareVersion | null> {
    return MonitorService.readFirmwareVersionInputRegister(
      PhotoTekInputRegisters.DRIVER_BOARD_FIRMWARE,
      '读取驱动板固件版本'
    );
  }

  /**
   * 读取反应板固件版本。
   *
   * Modbus: 功能码 0x04，输入寄存器 158，长度 2。
   *
   * @returns 成功返回固件版本；连接失败或响应异常时返回 null。
   */
  static async readReactionBoardFirmwareVersion(): Promise<PhotoTekFirmwareVersion | null> {
    return MonitorService.readFirmwareVersionInputRegister(
      PhotoTekInputRegisters.REACTION_BOARD_FIRMWARE,
      '读取反应板固件版本'
    );
  }

  /**
   * 读取跨度或标样核查结果。
   *
   * Modbus: 功能码 0x04，输入寄存器 165，长度 2。
   *
   * @returns 成功返回核查结果浓度；连接失败或响应异常时返回 null。
   */
  static async readSpanCheckResult(): Promise<number | null> {
    return MonitorService.readFloatInputRegister(
      PhotoTekInputRegisters.SPAN_CHECK_RESULT,
      '读取跨度标样核查结果'
    );
  }

  /**
   * 读取跨度或标样核查时间。
   *
   * Modbus: 功能码 0x04，输入寄存器 167，长度 3。
   *
   * @returns 成功返回结构化时间；连接失败或响应异常时返回 null。
   */
  static async readSpanCheckTime(): Promise<PhotoTekTimeValue | null> {
    return MonitorService.readTimeInputRegister(
      PhotoTekInputRegisters.SPAN_CHECK_TIME,
      '读取跨度标样核查时间'
    );
  }

  /**
   * 读取水样吸光度。
   *
   * Modbus: 功能码 0x04，输入寄存器 190，长度 2。
   *
   * @returns 成功返回水样吸光度；连接失败或响应异常时返回 null。
   */
  static async readWaterSampleAbsorbance(): Promise<number | null> {
    return MonitorService.readFloatInputRegister(
      PhotoTekInputRegisters.WATER_SAMPLE_ABSORBANCE,
      '读取水样吸光度'
    );
  }

  /**
   * 读取水样数据标识。
   *
   * Modbus: 功能码 0x04，输入寄存器 192，长度 1。
   *
   * @returns 成功返回数据标识及含义；连接失败或响应异常时返回 null。
   */
  static async readWaterSampleDataFlag(): Promise<PhotoTekDataFlag | null> {
    return MonitorService.readDataFlagInputRegister(
      PhotoTekInputRegisters.WATER_SAMPLE_DATA_FLAG,
      PhotoTekDataFlags,
      '读取水样数据标识'
    );
  }

  /**
   * 读取测量校准液吸光度。
   *
   * Modbus: 功能码 0x04，输入寄存器 193，长度 2。
   *
   * @returns 成功返回吸光度；连接失败或响应异常时返回 null。
   */
  static async readCalibrationSolutionAbsorbance(): Promise<number | null> {
    return MonitorService.readFloatInputRegister(
      PhotoTekInputRegisters.CALIBRATION_SOLUTION_ABSORBANCE,
      '读取测量校准液吸光度'
    );
  }

  /**
   * 读取测量校准液数据标识。
   *
   * Modbus: 功能码 0x04，输入寄存器 195，长度 1。
   *
   * @returns 成功返回数据标识及含义；连接失败或响应异常时返回 null。
   */
  static async readCalibrationSolutionDataFlag(): Promise<PhotoTekDataFlag | null> {
    return MonitorService.readDataFlagInputRegister(
      PhotoTekInputRegisters.CALIBRATION_SOLUTION_DATA_FLAG,
      PhotoTekDataFlags,
      '读取测量校准液数据标识'
    );
  }

  /**
   * 读取测核查液吸光度。
   *
   * Modbus: 功能码 0x04，输入寄存器 199，长度 2。
   *
   * @returns 成功返回吸光度；连接失败或响应异常时返回 null。
   */
  static async readCheckSolutionAbsorbance(): Promise<number | null> {
    return MonitorService.readFloatInputRegister(
      PhotoTekInputRegisters.CHECK_SOLUTION_ABSORBANCE,
      '读取测核查液吸光度'
    );
  }

  /**
   * 读取测核查液数据标识。
   *
   * Modbus: 功能码 0x04，输入寄存器 201，长度 1。
   *
   * @returns 成功返回数据标识及含义；连接失败或响应异常时返回 null。
   */
  static async readCheckSolutionDataFlag(): Promise<PhotoTekDataFlag | null> {
    return MonitorService.readDataFlagInputRegister(
      PhotoTekInputRegisters.CHECK_SOLUTION_DATA_FLAG,
      PhotoTekDataFlags,
      '读取测核查液数据标识'
    );
  }

  /**
   * 读取校准零点浓度。
   *
   * Modbus: 功能码 0x04，输入寄存器 220，长度 2。
   *
   * @returns 成功返回浓度；连接失败或响应异常时返回 null。
   */
  static async readCalibrationZeroConcentration(): Promise<number | null> {
    return MonitorService.readFloatInputRegister(
      PhotoTekInputRegisters.CALIBRATION_ZERO_CONCENTRATION,
      '读取校准零点浓度'
    );
  }

  /**
   * 读取校准零点吸光度。
   *
   * Modbus: 功能码 0x04，输入寄存器 222，长度 2。
   *
   * @returns 成功返回吸光度；连接失败或响应异常时返回 null。
   */
  static async readCalibrationZeroAbsorbance(): Promise<number | null> {
    return MonitorService.readFloatInputRegister(
      PhotoTekInputRegisters.CALIBRATION_ZERO_ABSORBANCE,
      '读取校准零点吸光度'
    );
  }

  /**
   * 读取零点漂移。
   *
   * Modbus: 功能码 0x04，输入寄存器 224，长度 2，单位 %。
   *
   * @returns 成功返回零点漂移；连接失败或响应异常时返回 null。
   */
  static async readZeroDrift(): Promise<number | null> {
    return MonitorService.readFloatInputRegister(
      PhotoTekInputRegisters.ZERO_DRIFT,
      '读取零点漂移'
    );
  }

  /**
   * 读取校准标点浓度。
   *
   * Modbus: 功能码 0x04，输入寄存器 230，长度 2。
   *
   * @returns 成功返回浓度；连接失败或响应异常时返回 null。
   */
  static async readCalibrationSpanConcentration(): Promise<number | null> {
    return MonitorService.readFloatInputRegister(
      PhotoTekInputRegisters.CALIBRATION_SPAN_CONCENTRATION,
      '读取校准标点浓度'
    );
  }

  /**
   * 读取校准标点吸光度。
   *
   * Modbus: 功能码 0x04，输入寄存器 232，长度 2。
   *
   * @returns 成功返回吸光度；连接失败或响应异常时返回 null。
   */
  static async readCalibrationSpanAbsorbance(): Promise<number | null> {
    return MonitorService.readFloatInputRegister(
      PhotoTekInputRegisters.CALIBRATION_SPAN_ABSORBANCE,
      '读取校准标点吸光度'
    );
  }

  /**
   * 读取量程漂移。
   *
   * Modbus: 功能码 0x04，输入寄存器 234，长度 2，单位 %。
   *
   * @returns 成功返回量程漂移；连接失败或响应异常时返回 null。
   */
  static async readSpanDrift(): Promise<number | null> {
    return MonitorService.readFloatInputRegister(
      PhotoTekInputRegisters.SPAN_DRIFT,
      '读取量程漂移'
    );
  }

  /**
   * 读取复合测量结果。
   *
   * Modbus: 功能码 0x04，输入寄存器 236，长度 2。
   *
   * @returns 成功返回复合测量结果；连接失败或响应异常时返回 null。
   */
  static async readCompositeMeasurementResult(): Promise<number | null> {
    return MonitorService.readFloatInputRegister(
      PhotoTekInputRegisters.COMPOSITE_MEASUREMENT_RESULT,
      '读取复合测量结果'
    );
  }

  /**
   * 读取复合结果时间。
   *
   * Modbus: 功能码 0x04，输入寄存器 238，长度 3。
   *
   * @returns 成功返回结构化时间；连接失败或响应异常时返回 null。
   */
  static async readCompositeResultTime(): Promise<PhotoTekTimeValue | null> {
    return MonitorService.readTimeInputRegister(
      PhotoTekInputRegisters.COMPOSITE_RESULT_TIME,
      '读取复合结果时间'
    );
  }

  /**
   * 读取复合测量数据标识。
   *
   * Modbus: 功能码 0x04，输入寄存器 241，长度 1。
   *
   * @returns 成功返回复合数据标识及含义；连接失败或响应异常时返回 null。
   */
  static async readCompositeDataFlag(): Promise<PhotoTekDataFlag | null> {
    return MonitorService.readDataFlagInputRegister(
      PhotoTekInputRegisters.COMPOSITE_DATA_FLAG,
      PhotoTekCompositeDataFlags,
      '读取复合测量数据标识'
    );
  }

  /**
   * 读取 TOC 因子转换系数常数。
   *
   * Modbus: 功能码 0x04，输入寄存器 242，长度 2。
   *
   * @returns 成功返回系数常数；连接失败或响应异常时返回 null。
   */
  static async readTocFactorConstant(): Promise<number | null> {
    return MonitorService.readFloatInputRegister(
      PhotoTekInputRegisters.TOC_FACTOR_CONSTANT,
      '读取TOC系数常数'
    );
  }

  /**
   * 读取 TOC 因子转换系数比例。
   *
   * Modbus: 功能码 0x04，输入寄存器 244，长度 2。
   *
   * @returns 成功返回系数比例；连接失败或响应异常时返回 null。
   */
  static async readTocFactorRatio(): Promise<number | null> {
    return MonitorService.readFloatInputRegister(
      PhotoTekInputRegisters.TOC_FACTOR_RATIO,
      '读取TOC系数比例'
    );
  }

  /**
   * 读取 TOC 因子流量。
   *
   * Modbus: 功能码 0x04，输入寄存器 246，长度 2，单位 ml/min。
   *
   * @returns 成功返回流量；连接失败或响应异常时返回 null。
   */
  static async readTocFlowControl(): Promise<number | null> {
    return MonitorService.readFloatInputRegister(
      PhotoTekInputRegisters.TOC_FLOW_CONTROL,
      '读取TOC流量控制'
    );
  }

  /**
   * 读取 TOC 测量结果。
   *
   * Modbus: 功能码 0x04，输入寄存器 248，长度 2。
   *
   * @returns 成功返回 TOC 测量结果；连接失败或响应异常时返回 null。
   */
  static async readTocMeasurementResult(): Promise<number | null> {
    return MonitorService.readFloatInputRegister(
      PhotoTekInputRegisters.TOC_MEASUREMENT_RESULT,
      '读取TOC测量结果'
    );
  }

  /**
   * 读取当前量程上限。
   *
   * Modbus: 功能码 0x03，保持寄存器 256，长度 2，PhotoTek CDAB 浮点数。
   *
   * @returns 成功返回当前量程上限；连接失败或响应异常时返回 null。
   */
  static async readCurrentRange(): Promise<number | null> {
    return DeviceContext.getDevice().readCurrentRange();
  }

  /**
   * 写入当前量程上限。
   *
   * Modbus: 功能码 0x10，保持寄存器 256，长度 2，PhotoTek CDAB 浮点数。
   * 仪器会自动匹配最接近的可用量程。
   *
   * @param rangeUpperLimit 当前量程上限，单位 mg/L。
   * @returns 写入成功返回 true，否则返回 false。
   */
  static async writeCurrentRange(rangeUpperLimit: number): Promise<boolean> {
    return DeviceContext.getDevice().writeCurrentRange(rangeUpperLimit);
  }

  /**
   * 读取校准曲线斜率。
   *
   * Modbus: 功能码 0x03，保持寄存器 258，长度 2，PhotoTek CDAB 浮点数。
   *
   * @returns 成功返回校准曲线斜率；连接失败或响应异常时返回 null。
   */
  static async readCalibrationCurveSlope(): Promise<number | null> {
    return MonitorService.readFloatHoldRegister(
      PhotoTekHoldRegisters.CALIBRATION_CURVE_SLOPE,
      '读取校准曲线斜率'
    );
  }

  /**
   * 写入校准曲线斜率。
   *
   * Modbus: 功能码 0x10，保持寄存器 258，长度 2，PhotoTek CDAB 浮点数。
   *
   * @param slope 校准曲线斜率。
   * @returns 写入成功返回 true，否则返回 false。
   */
  static async writeCalibrationCurveSlope(slope: number): Promise<boolean> {
    return MonitorService.writeFloatHoldRegister(
      PhotoTekHoldRegisters.CALIBRATION_CURVE_SLOPE,
      slope,
      '写入校准曲线斜率'
    );
  }

  /**
   * 读取校准曲线截距。
   *
   * Modbus: 功能码 0x03，保持寄存器 260，长度 2，PhotoTek CDAB 浮点数。
   *
   * @returns 成功返回校准曲线截距；连接失败或响应异常时返回 null。
   */
  static async readCalibrationCurveIntercept(): Promise<number | null> {
    return MonitorService.readFloatHoldRegister(
      PhotoTekHoldRegisters.CALIBRATION_CURVE_INTERCEPT,
      '读取校准曲线截距'
    );
  }

  /**
   * 写入校准曲线截距。
   *
   * Modbus: 功能码 0x10，保持寄存器 260，长度 2，PhotoTek CDAB 浮点数。
   *
   * @param intercept 校准曲线截距。
   * @returns 写入成功返回 true，否则返回 false。
   */
  static async writeCalibrationCurveIntercept(intercept: number): Promise<boolean> {
    return MonitorService.writeFloatHoldRegister(
      PhotoTekHoldRegisters.CALIBRATION_CURVE_INTERCEPT,
      intercept,
      '写入校准曲线截距'
    );
  }

  /**
   * 读取消解温度。
   *
   * Modbus: 功能码 0x03，保持寄存器 262，长度 2，PhotoTek CDAB 浮点数。
   *
   * @returns 成功返回消解温度，单位 ℃；连接失败或响应异常时返回 null。
   */
  static async readDigestionTemperature(): Promise<number | null> {
    return MonitorService.readFloatHoldRegister(
      PhotoTekHoldRegisters.DIGESTION_TEMPERATURE,
      '读取消解温度'
    );
  }

  /**
   * 写入消解温度。
   *
   * Modbus: 功能码 0x10，保持寄存器 262，长度 2，PhotoTek CDAB 浮点数。
   *
   * @param temperature 消解温度，单位 ℃。
   * @returns 写入成功返回 true，否则返回 false。
   */
  static async writeDigestionTemperature(temperature: number): Promise<boolean> {
    return MonitorService.writeFloatHoldRegister(
      PhotoTekHoldRegisters.DIGESTION_TEMPERATURE,
      temperature,
      '写入消解温度'
    );
  }

  /**
   * 读取消解时间。
   *
   * Modbus: 功能码 0x03，保持寄存器 264，长度 1，无符号 16 位整数。
   *
   * @returns 成功返回消解时间，单位秒；连接失败或响应异常时返回 null。
   */
  static async readDigestionTimeSeconds(): Promise<number | null> {
    return MonitorService.readUInt16HoldRegister(PhotoTekHoldRegisters.DIGESTION_TIME, '读取消解时间');
  }

  /**
   * 写入消解时间。
   *
   * Modbus: 功能码 0x06，保持寄存器 264，长度 1，无符号 16 位整数。
   *
   * @param seconds 消解时间，单位秒，取值 0~65535。
   * @returns 写入成功返回 true，否则返回 false。
   */
  static async writeDigestionTimeSeconds(seconds: number): Promise<boolean> {
    return MonitorService.writeUInt16HoldRegister(
      PhotoTekHoldRegisters.DIGESTION_TIME,
      seconds,
      '写入消解时间'
    );
  }

  /**
   * 读取反应温度。
   *
   * Modbus: 功能码 0x03，保持寄存器 265，长度 2，PhotoTek CDAB 浮点数。
   *
   * @returns 成功返回反应温度，单位 ℃；连接失败或响应异常时返回 null。
   */
  static async readReactionTemperature(): Promise<number | null> {
    return MonitorService.readFloatHoldRegister(
      PhotoTekHoldRegisters.REACTION_TEMPERATURE,
      '读取反应温度'
    );
  }

  /**
   * 写入反应温度。
   *
   * Modbus: 功能码 0x10，保持寄存器 265，长度 2，PhotoTek CDAB 浮点数。
   *
   * @param temperature 反应温度，单位 ℃。
   * @returns 写入成功返回 true，否则返回 false。
   */
  static async writeReactionTemperature(temperature: number): Promise<boolean> {
    return MonitorService.writeFloatHoldRegister(
      PhotoTekHoldRegisters.REACTION_TEMPERATURE,
      temperature,
      '写入反应温度'
    );
  }

  /**
   * 读取反应时间。
   *
   * Modbus: 功能码 0x03，保持寄存器 267，长度 1，无符号 16 位整数。
   *
   * @returns 成功返回反应时间，单位秒；连接失败或响应异常时返回 null。
   */
  static async readReactionTimeSeconds(): Promise<number | null> {
    return MonitorService.readUInt16HoldRegister(PhotoTekHoldRegisters.REACTION_TIME, '读取反应时间');
  }

  /**
   * 写入反应时间。
   *
   * Modbus: 功能码 0x06，保持寄存器 267，长度 1，无符号 16 位整数。
   *
   * @param seconds 反应时间，单位秒，取值 0~65535。
   * @returns 写入成功返回 true，否则返回 false。
   */
  static async writeReactionTimeSeconds(seconds: number): Promise<boolean> {
    return MonitorService.writeUInt16HoldRegister(
      PhotoTekHoldRegisters.REACTION_TIME,
      seconds,
      '写入反应时间'
    );
  }

  /**
   * 读取修正因子。
   *
   * Modbus: 功能码 0x03，保持寄存器 268，长度 2，PhotoTek CDAB 浮点数。
   *
   * @returns 成功返回修正因子；连接失败或响应异常时返回 null。
   */
  static async readCorrectionFactor(): Promise<number | null> {
    return MonitorService.readFloatHoldRegister(PhotoTekHoldRegisters.CORRECTION_FACTOR, '读取修正因子');
  }

  /**
   * 写入修正因子。
   *
   * Modbus: 功能码 0x10，保持寄存器 268，长度 2，PhotoTek CDAB 浮点数。
   *
   * @param factor 修正因子。
   * @returns 写入成功返回 true，否则返回 false。
   */
  static async writeCorrectionFactor(factor: number): Promise<boolean> {
    return MonitorService.writeFloatHoldRegister(
      PhotoTekHoldRegisters.CORRECTION_FACTOR,
      factor,
      '写入修正因子'
    );
  }

  /**
   * 写入测量控制码。
   *
   * Modbus: 功能码 0x06，保持寄存器 272，长度 1，无符号 16 位整数。
   *
   * @param controlCode PhotoTek 测量控制码，见 PhotoTekMeasurementControlCodes。
   * @returns 下发成功返回 true，码值非法或写入失败时返回 false。
   */
  static async writeMeasurementControl(controlCode: number): Promise<boolean> {
    if (!MonitorService.isKnownCode(PhotoTekMeasurementControlCodes, controlCode)) {
      hilog.error(DOMAIN, TAG, '写入测量控制失败: 未知控制码 %{public}d', controlCode);
      return false;
    }
    return MonitorService.writeUInt16HoldRegister(
      PhotoTekHoldRegisters.MEASUREMENT_CONTROL,
      controlCode,
      '写入测量控制'
    );
  }

  /**
   * 写入采水控制状态。
   *
   * Modbus: 功能码 0x06，保持寄存器 273，长度 1，0 表示关闭采水，1 表示开启采水。
   *
   * @param enabled true 表示开启采水，false 表示关闭采水。
   * @returns 写入成功返回 true，否则返回 false。
   */
  static async writeWaterCollectionControl(enabled: boolean): Promise<boolean> {
    return MonitorService.writeUInt16HoldRegister(
      PhotoTekHoldRegisters.WATER_COLLECTION_CONTROL,
      enabled ? 1 : 0,
      enabled ? '开启采水' : '关闭采水'
    );
  }

  /**
   * 读取系统时间。
   *
   * Modbus: 功能码 0x03，保持寄存器 274，长度 3，PhotoTek 时间类型。
   *
   * @returns 成功返回结构化系统时间；连接失败或响应异常时返回 null。
   */
  static async readSystemTime(): Promise<PhotoTekTimeValue | null> {
    return MonitorService.readTimeHoldRegister(PhotoTekHoldRegisters.SYSTEM_TIME, '读取系统时间');
  }

  /**
   * 写入系统时间。
   *
   * Modbus: 功能码 0x10，保持寄存器 274，长度 3，PhotoTek 时间类型。
   *
   * @param year 完整年份，协议按 year - 1970 写入。
   * @param month 月份，取值 1~12。
   * @param day 日期，取值 1~31。
   * @param hour 小时，取值 0~23。
   * @param minute 分钟，取值 0~59。
   * @param second 秒，取值 0~59。
   * @returns 写入成功返回 true，否则返回 false。
   */
  static async writeSystemTime(
    year: number,
    month: number,
    day: number,
    hour: number,
    minute: number,
    second: number
  ): Promise<boolean> {
    return MonitorService.writeTimeHoldRegister(
      PhotoTekHoldRegisters.SYSTEM_TIME,
      year,
      month,
      day,
      hour,
      minute,
      second,
      '写入系统时间'
    );
  }

  /**
   * 读取测量模式。
   *
   * Modbus: 功能码 0x03，保持寄存器 277，长度 1。
   *
   * @returns 成功返回测量模式码和含义；连接失败或响应异常时返回 null。
   */
  static async readMeasurementMode(): Promise<PhotoTekCodeDescription | null> {
    return MonitorService.readCodeDescriptionHoldRegister(
      PhotoTekHoldRegisters.MEASUREMENT_MODE,
      PhotoTekMeasurementModes,
      '未知测量模式',
      '读取测量模式'
    );
  }

  /**
   * 写入测量模式。
   *
   * Modbus: 功能码 0x06，保持寄存器 277，长度 1。
   *
   * @param mode 测量模式码，0 触发、1 周期、2 整点、3 连续。
   * @returns 写入成功返回 true，否则返回 false。
   */
  static async writeMeasurementMode(mode: number): Promise<boolean> {
    if (!MonitorService.isKnownCode(PhotoTekMeasurementModes, mode)) {
      hilog.error(DOMAIN, TAG, '写入测量模式失败: 未知模式 %{public}d', mode);
      return false;
    }
    return MonitorService.writeUInt16HoldRegister(
      PhotoTekHoldRegisters.MEASUREMENT_MODE,
      mode,
      '写入测量模式'
    );
  }

  /**
   * 读取自动测量时间间隔。
   *
   * Modbus: 功能码 0x03，保持寄存器 278，长度 1，无符号 16 位整数。
   *
   * @returns 成功返回自动测量间隔，单位小时；连接失败或响应异常时返回 null。
   */
  static async readAutoMeasurementIntervalHours(): Promise<number | null> {
    return MonitorService.readUInt16HoldRegister(
      PhotoTekHoldRegisters.AUTO_MEASUREMENT_INTERVAL,
      '读取自动测量时间间隔'
    );
  }

  /**
   * 写入自动测量时间间隔。
   *
   * Modbus: 功能码 0x06，保持寄存器 278，长度 1，无符号 16 位整数。
   *
   * @param hours 自动测量间隔，单位小时，取值 0~65535。
   * @returns 写入成功返回 true，否则返回 false。
   */
  static async writeAutoMeasurementIntervalHours(hours: number): Promise<boolean> {
    return MonitorService.writeUInt16HoldRegister(
      PhotoTekHoldRegisters.AUTO_MEASUREMENT_INTERVAL,
      hours,
      '写入自动测量时间间隔'
    );
  }

  /**
   * 读取自动校准模式。
   *
   * Modbus: 功能码 0x03，保持寄存器 279，长度 1。
   *
   * @returns 成功返回自动校准模式码和含义；连接失败或响应异常时返回 null。
   */
  static async readAutoCalibrationMode(): Promise<PhotoTekCodeDescription | null> {
    return MonitorService.readCodeDescriptionHoldRegister(
      PhotoTekHoldRegisters.AUTO_CALIBRATION_MODE,
      PhotoTekAutoCalibrationModes,
      '未知自动校准模式',
      '读取自动校准模式'
    );
  }

  /**
   * 写入自动校准模式。
   *
   * Modbus: 功能码 0x06，保持寄存器 279，长度 1。
   *
   * @param mode 自动校准模式码，0 触发、1 周期、2 整点。
   * @returns 写入成功返回 true，否则返回 false。
   */
  static async writeAutoCalibrationMode(mode: number): Promise<boolean> {
    if (!MonitorService.isKnownCode(PhotoTekAutoCalibrationModes, mode)) {
      hilog.error(DOMAIN, TAG, '写入自动校准模式失败: 未知模式 %{public}d', mode);
      return false;
    }
    return MonitorService.writeUInt16HoldRegister(
      PhotoTekHoldRegisters.AUTO_CALIBRATION_MODE,
      mode,
      '写入自动校准模式'
    );
  }

  /**
   * 读取自动校准时间间隔。
   *
   * Modbus: 功能码 0x03，保持寄存器 280，长度 1，无符号 16 位整数。
   *
   * @returns 成功返回自动校准间隔，单位小时；连接失败或响应异常时返回 null。
   */
  static async readAutoCalibrationIntervalHours(): Promise<number | null> {
    return MonitorService.readUInt16HoldRegister(
      PhotoTekHoldRegisters.AUTO_CALIBRATION_INTERVAL,
      '读取自动校准时间间隔'
    );
  }

  /**
   * 写入自动校准时间间隔。
   *
   * Modbus: 功能码 0x06，保持寄存器 280，长度 1，无符号 16 位整数。
   *
   * @param hours 自动校准间隔，单位小时，取值 0~65535。
   * @returns 写入成功返回 true，否则返回 false。
   */
  static async writeAutoCalibrationIntervalHours(hours: number): Promise<boolean> {
    return MonitorService.writeUInt16HoldRegister(
      PhotoTekHoldRegisters.AUTO_CALIBRATION_INTERVAL,
      hours,
      '写入自动校准时间间隔'
    );
  }

  /**
   * 读取当前量程稀释倍数。
   *
   * Modbus: 功能码 0x03，保持寄存器 283，长度 2，PhotoTek CDAB 浮点数。
   *
   * @returns 成功返回当前量程稀释倍数；连接失败或响应异常时返回 null。
   */
  static async readCurrentRangeDilutionFactor(): Promise<number | null> {
    return MonitorService.readFloatHoldRegister(
      PhotoTekHoldRegisters.CURRENT_RANGE_DILUTION_FACTOR,
      '读取当前量程稀释倍数'
    );
  }

  /**
   * 读取零点校准液浓度。
   *
   * Modbus: 功能码 0x03，保持寄存器 293，长度 2，PhotoTek CDAB 浮点数。
   *
   * @returns 成功返回零点校准液浓度，单位 mg/L；连接失败或响应异常时返回 null。
   */
  static async readZeroCalibrationSolutionConcentration(): Promise<number | null> {
    return MonitorService.readFloatHoldRegister(
      PhotoTekHoldRegisters.ZERO_CALIBRATION_SOLUTION_CONCENTRATION,
      '读取零点校准液浓度'
    );
  }

  /**
   * 读取量程校准液浓度。
   *
   * Modbus: 功能码 0x03，保持寄存器 295，长度 2，PhotoTek CDAB 浮点数。
   *
   * @returns 成功返回量程校准液浓度，单位 mg/L；连接失败或响应异常时返回 null。
   */
  static async readSpanCalibrationSolutionConcentration(): Promise<number | null> {
    return MonitorService.readFloatHoldRegister(
      PhotoTekHoldRegisters.SPAN_CALIBRATION_SOLUTION_CONCENTRATION,
      '读取量程校准液浓度'
    );
  }

  /**
   * 读取试剂一加液体积。
   *
   * Modbus: 功能码 0x03，保持寄存器 300，长度 2，PhotoTek CDAB 浮点数。
   *
   * @returns 成功返回试剂一加液体积，单位 mL；连接失败或响应异常时返回 null。
   */
  static async readReagentOneVolume(): Promise<number | null> {
    return MonitorService.readFloatHoldRegister(PhotoTekHoldRegisters.REAGENT_ONE_VOLUME, '读取试剂一加液体积');
  }

  /**
   * 读取试剂二加液体积。
   *
   * Modbus: 功能码 0x03，保持寄存器 302，长度 2，PhotoTek CDAB 浮点数。
   *
   * @returns 成功返回试剂二加液体积，单位 mL；连接失败或响应异常时返回 null。
   */
  static async readReagentTwoVolume(): Promise<number | null> {
    return MonitorService.readFloatHoldRegister(PhotoTekHoldRegisters.REAGENT_TWO_VOLUME, '读取试剂二加液体积');
  }

  /**
   * 读取试剂三加液体积。
   *
   * Modbus: 功能码 0x03，保持寄存器 304，长度 2，PhotoTek CDAB 浮点数。
   *
   * @returns 成功返回试剂三加液体积，单位 mL；连接失败或响应异常时返回 null。
   */
  static async readReagentThreeVolume(): Promise<number | null> {
    return MonitorService.readFloatHoldRegister(PhotoTekHoldRegisters.REAGENT_THREE_VOLUME, '读取试剂三加液体积');
  }

  /**
   * 读取试剂四加液体积。
   *
   * Modbus: 功能码 0x03，保持寄存器 306，长度 2，PhotoTek CDAB 浮点数。
   *
   * @returns 成功返回试剂四加液体积，单位 mL；连接失败或响应异常时返回 null。
   */
  static async readReagentFourVolume(): Promise<number | null> {
    return MonitorService.readFloatHoldRegister(PhotoTekHoldRegisters.REAGENT_FOUR_VOLUME, '读取试剂四加液体积');
  }

  /**
   * 读取试剂五加液体积。
   *
   * Modbus: 功能码 0x03，保持寄存器 308，长度 2，PhotoTek CDAB 浮点数。
   *
   * @returns 成功返回试剂五加液体积，单位 mL；连接失败或响应异常时返回 null。
   */
  static async readReagentFiveVolume(): Promise<number | null> {
    return MonitorService.readFloatHoldRegister(PhotoTekHoldRegisters.REAGENT_FIVE_VOLUME, '读取试剂五加液体积');
  }

  /**
   * 读取当前量程校正因子。
   *
   * Modbus: 功能码 0x03，保持寄存器 310，长度 2，PhotoTek CDAB 浮点数。
   *
   * @returns 成功返回当前量程校正因子；连接失败或响应异常时返回 null。
   */
  static async readCurrentRangeCorrectionFactor(): Promise<number | null> {
    return MonitorService.readFloatHoldRegister(
      PhotoTekHoldRegisters.CURRENT_RANGE_CORRECTION_FACTOR,
      '读取当前量程校正因子'
    );
  }

  /**
   * 读取跨度或标样核查允许偏差值。
   *
   * Modbus: 功能码 0x03，保持寄存器 312，长度 2，PhotoTek CDAB 浮点数。
   *
   * @returns 成功返回允许偏差百分比；连接失败或响应异常时返回 null。
   */
  static async readSpanCheckAllowedDeviation(): Promise<number | null> {
    return MonitorService.readFloatHoldRegister(
      PhotoTekHoldRegisters.SPAN_CHECK_ALLOWED_DEVIATION,
      '读取跨度标样核查允许偏差值'
    );
  }

  /**
   * 读取跨度或标样核查偏差值。
   *
   * Modbus: 功能码 0x03，保持寄存器 314，长度 2，PhotoTek CDAB 浮点数。
   *
   * @returns 成功返回最近一次偏差百分比；连接失败或响应异常时返回 null。
   */
  static async readSpanCheckDeviation(): Promise<number | null> {
    return MonitorService.readFloatHoldRegister(
      PhotoTekHoldRegisters.SPAN_CHECK_DEVIATION,
      '读取跨度标样核查偏差值'
    );
  }

  /**
   * 启动测量。
   *
   * Modbus: 功能码 0x06，保持寄存器 0x0110，写入 0x0000。
   *
   * @returns 下发成功返回 true，失败返回 false。
   */
  static async startMeasurement(): Promise<boolean> {
    if (MonitorService.measuring) {
      return true;
    }

    return MonitorService.runMaintenanceCommand('启动测量', async (): Promise<boolean> => {
      const started = await MeasurementService.startMeasurement();
      if (started) {
        MonitorService.setMeasurementRunning(true);
      }
      return started;
    });
  }

  /**
   * 启动校准。
   *
   * Modbus: 功能码 0x06，保持寄存器 0x0110，写入 0x0001。
   *
   * @returns 下发成功返回 true，失败返回 false。
   */
  static async startCalibration(): Promise<boolean> {
    return MonitorService.runMaintenanceCommand('启动校准', async (): Promise<boolean> => {
      return MeasurementService.startCalibration();
    });
  }

  /**
   * 停止测量。
   *
   * Modbus: 功能码 0x06，保持寄存器 0x0110，写入 0x0002。
   *
   * @returns 下发成功返回 true，失败返回 false。
   */
  static async stopMeasurement(): Promise<boolean> {
    return MonitorService.runMaintenanceCommand('停止测量', async (): Promise<boolean> => {
      const stopped = await MeasurementService.stopMeasurement();
      if (stopped) {
        MonitorService.setMeasurementRunning(false);
      }
      return stopped;
    });
  }

  /**
   * 停止仪器当前正在执行的任务，包括测量、校准、核查、清洗等运行过程。
   *
   * Modbus: 功能码 0x06，保持寄存器 0x0110，写入停止控制码 0x0002。
   * 该方法只负责下发停止码；调用方应先读取系统状态和当前动作，避免仪器空闲时无意义写入。
   *
   * @returns 停止命令下发成功返回 true，连接失败或写入失败返回 false。
   */
  static async stopCurrentOperation(): Promise<boolean> {
    return MonitorService.runMaintenanceCommand('停止当前任务', async (): Promise<boolean> => {
      const stopped = await MeasurementService.stopMeasurement();
      if (stopped) {
        MonitorService.setMeasurementRunning(false);
      }
      return stopped;
    });
  }

  /**
   * 启动深度清洗。
   *
   * Modbus: 功能码 0x06，保持寄存器 0x0110，写入 0x0007。
   *
   * @returns 下发成功返回 true，失败返回 false。
   */
  static async startCleaning(): Promise<boolean> {
    return MonitorService.runMaintenanceCommand('启动深度清洗', async (): Promise<boolean> => {
      return MeasurementService.startCleaning();
    });
  }

  /**
   * 测量量程校准液。
   *
   * Modbus: 功能码 0x06，保持寄存器 272，写入控制码 3。
   *
   * @returns 下发成功返回 true，失败返回 false。
   */
  static async measureRangeCalibrationSolution(): Promise<boolean> {
    return MonitorService.runMaintenanceCommand('测量量程校准液', async (): Promise<boolean> => {
      return MeasurementService.measureRangeCalibrationSolution();
    });
  }

  /**
   * 测量零点校准液。
   *
   * Modbus: 功能码 0x06，保持寄存器 272，写入控制码 4。
   *
   * @returns 下发成功返回 true，失败返回 false。
   */
  static async measureZeroCalibrationSolution(): Promise<boolean> {
    return MonitorService.runMaintenanceCommand('测量零点校准液', async (): Promise<boolean> => {
      return MeasurementService.measureZeroCalibrationSolution();
    });
  }

  /**
   * 清洗定量管。
   *
   * Modbus: 功能码 0x06，保持寄存器 272，写入控制码 5。
   *
   * @returns 下发成功返回 true，失败返回 false。
   */
  static async cleanQuantitativeTube(): Promise<boolean> {
    return MonitorService.runMaintenanceCommand('清洗定量管', async (): Promise<boolean> => {
      return MeasurementService.cleanQuantitativeTube();
    });
  }

  /**
   * 清洗消解室。
   *
   * Modbus: 功能码 0x06，保持寄存器 272，写入控制码 6。
   *
   * @returns 下发成功返回 true，失败返回 false。
   */
  static async cleanDigestionChamber(): Promise<boolean> {
    return MonitorService.runMaintenanceCommand('清洗消解室', async (): Promise<boolean> => {
      return MeasurementService.cleanDigestionChamber();
    });
  }

  /**
   * 清洗所有管路。
   *
   * Modbus: 功能码 0x06，保持寄存器 272，写入控制码 8。
   *
   * @returns 下发成功返回 true，失败返回 false。
   */
  static async cleanAllPipelines(): Promise<boolean> {
    return MonitorService.runMaintenanceCommand('清洗所有管路', async (): Promise<boolean> => {
      return MeasurementService.cleanAllPipelines();
    });
  }

  /**
   * 采集水样。
   *
   * Modbus: 功能码 0x06，保持寄存器 272，写入控制码 9。
   *
   * @returns 下发成功返回 true，失败返回 false。
   */
  static async collectWaterSample(): Promise<boolean> {
    return MonitorService.runMaintenanceCommand('采集水样', async (): Promise<boolean> => {
      return MeasurementService.collectWaterSample();
    });
  }

  /**
   * 启动定量泵自动校准。
   *
   * Modbus: 功能码 0x06，保持寄存器 272，写入控制码 10。
   *
   * @returns 下发成功返回 true，失败返回 false。
   */
  static async startQuantitativePumpCalibration(): Promise<boolean> {
    return MonitorService.runMaintenanceCommand('启动定量泵自动校准', async (): Promise<boolean> => {
      return MeasurementService.startQuantitativePumpCalibration();
    });
  }

  /**
   * 启动零点校准。
   *
   * Modbus: 功能码 0x06，保持寄存器 272，写入控制码 13。
   *
   * @returns 下发成功返回 true，失败返回 false。
   */
  static async startZeroCalibration(): Promise<boolean> {
    return MonitorService.runMaintenanceCommand('启动零点校准', async (): Promise<boolean> => {
      return MeasurementService.startZeroCalibration();
    });
  }

  /**
   * 启动量程标点校准。
   *
   * Modbus: 功能码 0x06，保持寄存器 272，写入控制码 14。
   *
   * @returns 下发成功返回 true，失败返回 false。
   */
  static async startSpanCalibration(): Promise<boolean> {
    return MonitorService.runMaintenanceCommand('启动量程标点校准', async (): Promise<boolean> => {
      return MeasurementService.startSpanCalibration();
    });
  }

  /**
   * 启动零点核查。
   *
   * Modbus: 功能码 0x06，保持寄存器 272，写入控制码 20。
   *
   * @returns 下发成功返回 true，失败返回 false。
   */
  static async startZeroCheck(): Promise<boolean> {
    return MonitorService.runMaintenanceCommand('启动零点核查', async (): Promise<boolean> => {
      return MeasurementService.startZeroCheck();
    });
  }

  /**
   * 启动跨度或标样核查液测量。
   *
   * Modbus: 功能码 0x06，保持寄存器 272，写入控制码 21。
   *
   * @returns 下发成功返回 true，失败返回 false。
   */
  static async startSpanCheck(): Promise<boolean> {
    return MonitorService.runMaintenanceCommand('启动跨度标样核查', async (): Promise<boolean> => {
      return MeasurementService.startSpanCheck();
    });
  }

  /**
   * 按当前测量状态切换启动或停止。
   *
   * @returns 下发成功返回 true，失败返回 false。
   */
  static async toggleMeasurement(): Promise<boolean> {
    return MonitorService.measuring ? MonitorService.stopMeasurement() : MonitorService.startMeasurement();
  }

  private static async runMaintenanceCommand(action: string, task: () => Promise<boolean>): Promise<boolean> {
    return OperationLogService.runWithLog({
      logType: OPERATION_LOG_TYPE_MAINTENANCE,
      action: action,
      content: action,
      source: 'monitor_service'
    }, task);
  }

  /**
   * 确保当前选中的通信通道已连接。
   *
   * @returns 当前通道连接成功返回 true，否则返回 false。
   */
  private static async ensureConnected(): Promise<boolean> {
    return DeviceContext.getDevice().connect();
  }

  private static syncConnectionStateFromDevice(): boolean {
    // const connected = DeviceContext.getDevice().isConnected();
    //默认设备地址1
    const connected = dncp.isConnected(1);
    MonitorService.setConnectionState(connected ? 'online' : 'disconnected');
    return connected;
  }

  private static setConnectionState(state: DeviceConnectionState): void {
    if (MonitorService.connectionState === state) {
      return;
    }
    MonitorService.connectionState = state;
    MonitorService.connectionStateListeners.forEach((listener: ConnectionStateListener) => {
      listener(state);
    });
  }

  private static async refreshSystemInfoSessionStore(): Promise<void> {
    if (MonitorService.systemInfoRefreshPromise) {
      return MonitorService.systemInfoRefreshPromise;
    }

    MonitorService.systemInfoRefreshPromise = MonitorService.refreshSystemInfoSessionStoreInternal();
    try {
      return await MonitorService.systemInfoRefreshPromise;
    } finally {
      MonitorService.systemInfoRefreshPromise = null;
    }
  }

  private static async refreshSystemInfoSessionStoreInternal(): Promise<void> {
    const device = DeviceContext.getDevice();

    try {
      const instrumentInfo = await device.readInstrumentInfo();
      if (instrumentInfo) {
        SystemInfoSessionStore.updateInstrumentInfo(instrumentInfo);
      }
    } catch (err) {
      hilog.error(DOMAIN, TAG, '刷新仪器信息失败: %{public}s', JSON.stringify(err));
    }

    try {
      const boardInfo = await device.readBoardInfo();
      if (boardInfo) {
        SystemInfoSessionStore.updateBoardInfo(boardInfo);
      }
    } catch (err) {
      hilog.error(DOMAIN, TAG, '刷新板卡信息失败: %{public}s', JSON.stringify(err));
    }
  }

  /**
   * 通过当前通信通道读取输入寄存器。
   *
   * @param regAddr 输入寄存器起始地址。
   * @param regCount 读取寄存器数量。
   * @param actionName 日志动作名称。
   * @returns 成功返回纯 PDU；连接或响应异常时返回 null。
   */
  private static async readInputRegisters(regAddr: number, regCount: number, actionName: string): Promise<Uint8Array | null> {
    return DeviceContext.getDevice().readInputRegisters(regAddr, regCount, actionName);
  }

  /**
   * 通过当前通信通道读取保持寄存器。
   *
   * @param regAddr 保持寄存器起始地址。
   * @param regCount 读取寄存器数量。
   * @param actionName 日志动作名称。
   * @returns 成功返回纯 PDU；连接或响应异常时返回 null。
   */
  private static async readHoldRegisters(regAddr: number, regCount: number, actionName: string): Promise<Uint8Array | null> {
    return DeviceContext.getDevice().readHoldRegisters(regAddr, regCount, actionName);
  }

  /**
   * 根据协议定义读取输入寄存器数据区。
   *
   * @param register PhotoTek 输入寄存器定义。
   * @param actionName 日志动作名称。
   * @returns 成功返回响应数据区；连接失败、响应异常或功能码异常时返回 null。
   */
  private static async readInputRegisterData(
    register: PhotoTekInputRegisterDefinition,
    actionName: string
  ): Promise<Uint8Array | null> {
    return DeviceContext.getDevice().readInputRegisterData(register, actionName);
  }

  /**
   * 根据协议定义读取保持寄存器数据区。
   *
   * @param register PhotoTek 保持寄存器定义。
   * @param actionName 日志动作名称。
   * @returns 成功返回响应数据区；连接失败、响应异常、功能码异常或寄存器不可读时返回 null。
   */
  private static async readHoldRegisterData(
    register: PhotoTekHoldRegisterDefinition,
    actionName: string
  ): Promise<Uint8Array | null> {
    return DeviceContext.getDevice().readHoldRegisterData(register, actionName);
  }

  /**
   * 根据协议定义读取并解析 1 个保持寄存器无符号整数。
   *
   * @param register PhotoTek 保持寄存器定义。
   * @param actionName 日志动作名称。
   * @returns 成功返回整数值；失败返回 null。
   */
  private static async readUInt16HoldRegister(
    register: PhotoTekHoldRegisterDefinition,
    actionName: string
  ): Promise<number | null> {
    return DeviceContext.getDevice().readUInt16HoldRegister(register, actionName);
  }

  /**
   * 根据协议定义读取并解析 1 个保持寄存器 CDAB 浮点数。
   *
   * @param register PhotoTek 保持寄存器定义。
   * @param actionName 日志动作名称。
   * @returns 成功返回浮点值；失败返回 null。
   */
  private static async readFloatHoldRegister(
    register: PhotoTekHoldRegisterDefinition,
    actionName: string
  ): Promise<number | null> {
    return DeviceContext.getDevice().readFloatHoldRegister(register, actionName);
  }

  /**
   * 根据协议定义读取并解析保持寄存器 PhotoTek 时间类型。
   *
   * @param register PhotoTek 保持寄存器定义。
   * @param actionName 日志动作名称。
   * @returns 成功返回结构化时间；失败返回 null。
   */
  private static async readTimeHoldRegister(
    register: PhotoTekHoldRegisterDefinition,
    actionName: string
  ): Promise<PhotoTekTimeValue | null> {
    return DeviceContext.getDevice().readTimeHoldRegister(register, actionName);
  }

  /**
   * 根据保持寄存器定义读取枚举码值并解析含义。
   *
   * @param register PhotoTek 保持寄存器定义。
   * @param table 码值含义表。
   * @param unknownLabel 未知码值的标签前缀。
   * @param actionName 日志动作名称。
   * @returns 成功返回码值和含义；失败返回 null。
   */
  private static async readCodeDescriptionHoldRegister(
    register: PhotoTekHoldRegisterDefinition,
    table: PhotoTekCodeDescription[],
    unknownLabel: string,
    actionName: string
  ): Promise<PhotoTekCodeDescription | null> {
    return DeviceContext.getDevice().readCodeDescriptionHoldRegister(register, table, unknownLabel, actionName);
  }

  /**
   * 根据保持寄存器定义写入 1 个无符号 16 位整数。
   *
   * @param register PhotoTek 保持寄存器定义。
   * @param value 需要写入的整数值。
   * @param actionName 日志动作名称。
   * @returns 写入成功返回 true，否则返回 false。
   */
  private static async writeUInt16HoldRegister(
    register: PhotoTekHoldRegisterDefinition,
    value: number,
    actionName: string
  ): Promise<boolean> {
    return DeviceContext.getDevice().writeUInt16HoldRegister(register, value, actionName);
  }

  /**
   * 根据保持寄存器定义写入 1 个 CDAB 浮点数。
   *
   * @param register PhotoTek 保持寄存器定义。
   * @param value 需要写入的浮点值。
   * @param actionName 日志动作名称。
   * @returns 写入成功返回 true，否则返回 false。
   */
  private static async writeFloatHoldRegister(
    register: PhotoTekHoldRegisterDefinition,
    value: number,
    actionName: string
  ): Promise<boolean> {
    return DeviceContext.getDevice().writeFloatHoldRegister(register, value, actionName);
  }

  /**
   * 根据保持寄存器定义写入 PhotoTek 时间类型。
   *
   * @param register PhotoTek 保持寄存器定义。
   * @param year 完整年份。
   * @param month 月份。
   * @param day 日期。
   * @param hour 小时。
   * @param minute 分钟。
   * @param second 秒。
   * @param actionName 日志动作名称。
   * @returns 写入成功返回 true，否则返回 false。
   */
  private static async writeTimeHoldRegister(
    register: PhotoTekHoldRegisterDefinition,
    year: number,
    month: number,
    day: number,
    hour: number,
    minute: number,
    second: number,
    actionName: string
  ): Promise<boolean> {
    return DeviceContext.getDevice().writeTimeHoldRegister(
      register,
      year,
      month,
      day,
      hour,
      minute,
      second,
      actionName
    );
  }

  /**
   * 根据保持寄存器定义写入连续寄存器值。
   *
   * @param register PhotoTek 保持寄存器定义。
   * @param regValues 已按 Modbus 大端寄存器顺序编码的寄存器值。
   * @param actionName 日志动作名称。
   * @returns 写入成功返回 true，否则返回 false。
   */
  private static async writeHoldRegisterValues(
    register: PhotoTekHoldRegisterDefinition,
    regValues: number[],
    actionName: string
  ): Promise<boolean> {
    return DeviceContext.getDevice().writeHoldRegisterValues(register, regValues, actionName);
  }

  /**
   * 根据协议定义读取并解析 1 个无符号 16 位寄存器。
   *
   * @param register PhotoTek 输入寄存器定义。
   * @param actionName 日志动作名称。
   * @returns 成功返回整数值；失败返回 null。
   */
  private static async readUInt16InputRegister(
    register: PhotoTekInputRegisterDefinition,
    actionName: string
  ): Promise<number | null> {
    return DeviceContext.getDevice().readUInt16InputRegister(register, actionName);
  }

  /**
   * 根据协议定义读取并解析 1 个 CDAB 浮点数。
   *
   * @param register PhotoTek 输入寄存器定义。
   * @param actionName 日志动作名称。
   * @returns 成功返回浮点值；失败返回 null。
   */
  private static async readFloatInputRegister(
    register: PhotoTekInputRegisterDefinition,
    actionName: string
  ): Promise<number | null> {
    return DeviceContext.getDevice().readFloatInputRegister(register, actionName);
  }

  /**
   * 根据协议定义读取并解析 CDAB 浮点数组。
   *
   * @param register PhotoTek 输入寄存器定义。
   * @param floatCount 需要解析的浮点数数量。
   * @param actionName 日志动作名称。
   * @returns 成功返回浮点数组；失败返回 null。
   */
  private static async readFloatArrayInputRegister(
    register: PhotoTekInputRegisterDefinition,
    floatCount: number,
    actionName: string
  ): Promise<number[] | null> {
    return DeviceContext.getDevice().readFloatArrayInputRegister(register, floatCount, actionName);
  }

  /**
   * 根据协议定义读取并解析 PhotoTek 时间类型。
   *
   * @param register PhotoTek 输入寄存器定义。
   * @param actionName 日志动作名称。
   * @returns 成功返回结构化时间；失败返回 null。
   */
  private static async readTimeInputRegister(
    register: PhotoTekInputRegisterDefinition,
    actionName: string
  ): Promise<PhotoTekTimeValue | null> {
    return DeviceContext.getDevice().readTimeInputRegister(register, actionName);
  }

  /**
   * 根据协议定义读取并解析 UTF-16BE 字符串。
   *
   * @param register PhotoTek 输入寄存器定义。
   * @param actionName 日志动作名称。
   * @returns 成功返回字符串；失败返回 null。
   */
  private static async readStringInputRegister(
    register: PhotoTekInputRegisterDefinition,
    actionName: string
  ): Promise<string | null> {
    return DeviceContext.getDevice().readStringInputRegister(register, actionName);
  }

  /**
   * 根据协议定义读取并解析板卡固件版本。
   *
   * @param register PhotoTek 输入寄存器定义。
   * @param actionName 日志动作名称。
   * @returns 成功返回固件版本；失败返回 null。
   */
  private static async readFirmwareVersionInputRegister(
    register: PhotoTekInputRegisterDefinition,
    actionName: string
  ): Promise<PhotoTekFirmwareVersion | null> {
    return DeviceContext.getDevice().readFirmwareVersionInputRegister(register, actionName);
  }

  /**
   * 根据协议定义读取枚举码值并解析含义。
   *
   * @param register PhotoTek 输入寄存器定义。
   * @param table 码值含义表。
   * @param unknownLabel 未知码值的标签前缀。
   * @param actionName 日志动作名称。
   * @returns 成功返回码值和含义；失败返回 null。
   */
  private static async readCodeDescriptionInputRegister(
    register: PhotoTekInputRegisterDefinition,
    table: PhotoTekCodeDescription[],
    unknownLabel: string,
    actionName: string
  ): Promise<PhotoTekCodeDescription | null> {
    return {code: 1, label: '繁忙', description: '运行中'};
    // return DeviceContext.getDevice().readCodeDescriptionInputRegister(register, table, unknownLabel, actionName);
  }

  /**
   * 根据协议定义读取字符型数据标识并解析含义。
   *
   * @param register PhotoTek 输入寄存器定义。
   * @param table 数据标识码表。
   * @param actionName 日志动作名称。
   * @returns 成功返回数据标识和含义；失败返回 null。
   */
  private static async readDataFlagInputRegister(
    register: PhotoTekInputRegisterDefinition,
    table: PhotoTekCodeDescription[],
    actionName: string
  ): Promise<PhotoTekDataFlag | null> {
    return DeviceContext.getDevice().readDataFlagInputRegister(register, table, actionName);
  }

  /**
   * 从读寄存器响应 PDU 中提取数据区。
   *
   * @param responsePdu Client 返回的纯 PDU。
   * @param actionName 日志动作名称。
   * @param expectedFuncCode 期望的读寄存器功能码，0x04 表示输入寄存器，0x03 表示保持寄存器。
   * @returns 成功返回数据区；功能码或字节数异常时返回 null。
   */
  private static getReadDataBytes(
    responsePdu: Uint8Array,
    actionName: string,
    expectedFuncCode: number = 0x04
  ): Uint8Array | null {
    return DeviceContext.getDevice().getReadDataBytes(responsePdu, actionName, expectedFuncCode);
  }

  /**
   * 判断数值是否存在于指定码表。
   *
   * @param table 协议码表。
   * @param code 需要检查的数字码值。
   * @returns 码表中存在该码值时返回 true，否则返回 false。
   */
  private static isKnownCode(table: PhotoTekCodeDescription[], code: number): boolean {
    return DeviceContext.getDevice().isKnownCode(table, code);
  }

  private static cacheMeasurementParameterInfo(paramInfo: PhotoTekMeasurementParameterInfo): void {
    MonitorService.measurementParamCode = paramInfo.code;
    MonitorService.measurementParamName = paramInfo.name;
    MonitorService.measurementParamInfo = paramInfo;
    hilog.info(DOMAIN, TAG, '测量参数码值=%{public}d, 名称=%{public}s',
      paramInfo.code, paramInfo.name);

    if (MonitorService.measurementParamListener) {
      MonitorService.measurementParamListener(paramInfo.code, paramInfo.name);
    }
  }

  private static cacheMeasurementValue(value: number): void {
    MonitorService.measurementValue = value;
    hilog.info(DOMAIN, TAG, '测量结果=%{public}s', value.toString());
    if (MonitorService.measurementValueListener) {
      MonitorService.measurementValueListener(value);
    }
  }

  private static cacheMeasurementCalibrationSolutionValue(value: number): void {
    MonitorService.measurementCalibrationSolutionValue = value;
    hilog.info(DOMAIN, TAG, '测量校准液结果=%{public}s', value.toString());
    if (MonitorService.measurementCalibrationSolutionValueListener) {
      MonitorService.measurementCalibrationSolutionValueListener(value);
    }
  }

  /**
   * 更新测量运行状态并通知监听器。
   *
   * @param isMeasuring 当前是否处于测量中。
   */
  private static setMeasurementRunning(isMeasuring: boolean): void {
    if (MonitorService.measuring === isMeasuring) {
      return;
    }

    MonitorService.measuring = isMeasuring;
    MonitorService.measurementStartedAt = isMeasuring ? Date.now() : 0;
    if (MonitorService.measurementStateListener) {
      MonitorService.measurementStateListener(isMeasuring);
    }
  }
}
