import { hilog } from '@kit.PerformanceAnalysisKit';
import { ModbusTcpClient } from '../clients/ModbusTcpClient';
import { UartClient } from '../clients/UartClient';
import {
  PhotoTekAlarmCodes,
  PhotoTekCompositeDataFlags,
  PhotoTekCurrentActions,
  PhotoTekDataFlags,
  PhotoTekInputRegisters,
  PhotoTekMeasurementResultTypes,
  PhotoTekSystemStatuses,
  getPhotoTekCodeDescription,
  getPhotoTekMeasurementParameterByCode
} from '../protocol/PhotoTekInputRegisters';
import {
  PhotoTekAutoCalibrationModes,
  PhotoTekHoldRegisters,
  PhotoTekMeasurementControlCodes,
  PhotoTekMeasurementModes
} from '../protocol/PhotoTekHoldRegisters';
import { PhotoTekValueParser } from '../protocol/PhotoTekValueParser';
import {
  PhotoTekCodeDescription,
  PhotoTekDataFlag,
  PhotoTekFirmwareVersion,
  PhotoTekHoldRegisterDefinition,
  PhotoTekInputRegisterDefinition,
  PhotoTekMeasurementParameterInfo,
  PhotoTekTemperatureValue,
  PhotoTekTimeValue
} from '../protocol/PhotoTekTypes';
import {
  BoardFirmwareInfo,
  BoardInfo,
  DeviceRuntimeStatus,
  InstrumentInfo,
  MeasurementConfig,
  MeasurementSnapshot
} from '../../models/deviceTypes';
import { CommunicationMode, WaterQualityDevice } from './WaterQualityDevice';

const DOMAIN = 0x0003;
const TAG = 'PhotoTekDevice';

// PhotoTek 设备实现：负责设备能力和 PhotoTek 协议解析，底层传输可切换 TCP 或 UART/RTU。
export class PhotoTekDevice implements WaterQualityDevice {
  private readonly DEVICE_ADDR: number = 0x01;
  private communicationMode: CommunicationMode = 'uart';
  private uartBusinessOnline: boolean = false;

  /**
   * 获取当前设备通信模式。
   *
   * @returns 当前通信模式，取值为 tcp 或 uart。
   */
  getMode(): CommunicationMode {
    return this.communicationMode;
  }

  /**
   * 切换设备通信模式，并释放旧传输通道。
   *
   * @param mode 目标通信模式，取值为 tcp 或 uart。
   */
  setMode(mode: CommunicationMode): void {
    if (this.communicationMode === mode) {
      return;
    }

    this.disconnectCurrentTransport();
    this.communicationMode = mode;
    hilog.info(DOMAIN, TAG, 'Communication mode changed to: %{public}s', mode);
  }

  /**
   * 设置 MCU Modbus TCP 连接地址。
   *
   * @param ip MCU IP 地址。
   * @param port MCU TCP 端口，PhotoTek 默认端口为 502。
   */
  setMcuConfig(ip: string, port: number): void {
    ModbusTcpClient.setConfig(ip, port);
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
  setUartConfig(
    path: string,
    baudRate: number,
    dataBits: number = 8,
    stopBits: number = 1,
    parity: string = 'N',
    isRs485: boolean = false
  ): void {
    this.uartBusinessOnline = false;
    UartClient.setConfig(path, baudRate, dataBits, stopBits, parity, isRs485);
  }

  /**
   * 连接当前选中的传输通道。
   *
   * @returns 连接成功返回 true，失败返回 false。
   */
  async connect(): Promise<boolean> {
    if (this.communicationMode === 'tcp') {
      return this.connectTcpDevice();
    }
    return this.connectUartDevice();
  }

  /**
   * 断开所有传输通道。
   */
  disconnect(): void {
    this.uartBusinessOnline = false;
    ModbusTcpClient.disconnect();
    UartClient.disconnect();
  }

  /**
   * 判断当前选中的传输通道是否已连接。
   *
   * @returns 已连接返回 true，否则返回 false。
   */
  isConnected(): boolean {
    return this.communicationMode === 'tcp' ?
      ModbusTcpClient.isConnected() :
      this.uartBusinessOnline && UartClient.isConnected();
  }

  /**
   * 通过当前通信模式发送纯 Modbus PDU。
   *
   * TCP 模式由客户端补充内部 MBAP 和 Transaction ID；UART 模式由客户端补充设备地址和 CRC。
   * 本方法不解析寄存器数据，也不复用北向 Dashboard 的 Transaction ID。
   *
   * @param unitId Modbus Unit ID，当前 PhotoTek 设备只接受 1。
   * @param requestPdu 从功能码开始的纯 Modbus 请求 PDU。
   * @param actionName 日志动作名称。
   * @returns 成功返回纯响应 PDU，包括合法异常 PDU；传输失败返回 null。
   */
  async executeRawModbusRequest(
    unitId: number,
    requestPdu: Uint8Array,
    actionName: string
  ): Promise<Uint8Array | null> {
    if (unitId !== this.DEVICE_ADDR) {
      hilog.error(DOMAIN, TAG, '%{public}s: unsupported unit id %{public}d', actionName, unitId);
      return null;
    }
    return this.communicationMode === 'tcp' ?
      ModbusTcpClient.executePdu(unitId, requestPdu, actionName) :
      UartClient.executePdu(unitId, requestPdu, actionName);
  }

  private disconnectCurrentTransport(): void {
    if (this.communicationMode === 'tcp') {
      ModbusTcpClient.disconnect();
      return;
    }
    this.uartBusinessOnline = false;
    UartClient.disconnect();
  }

  private async connectTcpDevice(): Promise<boolean> {
    const opened = await ModbusTcpClient.connect();
    if (!opened) {
      return false;
    }

    const online = await this.probeTcpDevice();
    if (!online) {
      hilog.warn(DOMAIN, TAG, 'TCP socket opened but device probe failed');
      ModbusTcpClient.disconnect();
      return false;
    }
    return true;
  }

  private async connectUartDevice(): Promise<boolean> {
    if (this.uartBusinessOnline && UartClient.isConnected()) {
      const online = await this.probeUartDevice();
      if (online) {
        return true;
      }
      this.uartBusinessOnline = false;
      UartClient.disconnect();
      return false;
    }

    this.uartBusinessOnline = false;
    const opened = await UartClient.connect();
    if (!opened) {
      return false;
    }

    const online = await this.probeUartDevice();
    if (!online) {
      hilog.warn(DOMAIN, TAG, 'UART port opened but device probe failed');
      UartClient.disconnect();
      return false;
    }

    this.uartBusinessOnline = true;
    return true;
  }

  private async probeTcpDevice(): Promise<boolean> {
    const responsePdu = await ModbusTcpClient.readInputRegisters(
      this.DEVICE_ADDR,
      PhotoTekInputRegisters.SYSTEM_STATUS.address,
      PhotoTekInputRegisters.SYSTEM_STATUS.registerCount,
      '探测TCP设备'
    );
    if (!responsePdu) {
      return false;
    }
    return this.getReadDataBytes(responsePdu, '探测TCP设备') !== null;
  }

  private async probeUartDevice(): Promise<boolean> {
    const responsePdu = await UartClient.readInputRegisters(
      this.DEVICE_ADDR,
      PhotoTekInputRegisters.SYSTEM_STATUS.address,
      PhotoTekInputRegisters.SYSTEM_STATUS.registerCount,
      '探测UART设备'
    );
    if (!responsePdu) {
      return false;
    }
    return this.getReadDataBytes(responsePdu, '探测UART设备') !== null;
  }

  async readMeasurementSnapshot(): Promise<MeasurementSnapshot | null> {
    const parameter = await this.readMeasurementParameterInfo();
    if (!parameter) {
      return null;
    }

    const result = await this.readMeasurementResult();
    if (result === null) {
      return null;
    }

    const resultType = await this.readMeasurementResultType();
    const measurementDurationSeconds = await this.readMeasurementDurationSeconds();
    const measurementTime = await this.readMeasurementTime();
    const calibrationSolutionResult = await this.readMeasurementCalibrationSolutionResult();
    const calibrationSolutionTime = await this.readCalibrationSolutionTime();
    const calibrationTime = await this.readCalibrationTime();
    const spanCheckResult = await this.readSpanCheckResult();
    const spanCheckTime = await this.readSpanCheckTime();
    const dataFlag = await this.readCompositeDataFlag();

    const snapshot: MeasurementSnapshot = {
      parameter,
      result,
      resultUnit: parameter.unit,
      resultType,
      measurementDurationSeconds,
      measurementTime,
      calibrationSolutionResult,
      calibrationSolutionTime,
      calibrationTime,
      spanCheckResult,
      spanCheckTime,
      dataFlag
    };
    return snapshot;
  }

  async readRuntimeStatus(): Promise<DeviceRuntimeStatus | null> {
    const systemStatus = await this.readSystemStatus();
    if (!systemStatus) {
      return null;
    }

    const currentAction = await this.readCurrentAction();
    if (!currentAction) {
      return null;
    }

    const temperatures = await this.readCurrentTemperatures();
    const alarmTime = await this.readAlarmTime();
    const alarmCode = await this.readAlarmCode();

    const runtimeStatus: DeviceRuntimeStatus = {
      connected: this.isConnected(),
      systemStatus,
      currentAction,
      temperatures,
      alarmTime,
      alarmCode
    };
    return runtimeStatus;
  }

  async readMeasurementConfig(): Promise<MeasurementConfig | null> {
    const currentRange = await this.readCurrentRange();
    if (currentRange === null) {
      return null;
    }

    const measurementMode = await this.readMeasurementMode();
    if (!measurementMode) {
      return null;
    }

    const autoMeasurementIntervalHours = await this.readAutoMeasurementIntervalHours();
    const autoCalibrationMode = await this.readAutoCalibrationMode();
    const autoCalibrationIntervalHours = await this.readAutoCalibrationIntervalHours();
    const calibrationCurveSlope = await this.readCalibrationCurveSlope();
    const calibrationCurveIntercept = await this.readCalibrationCurveIntercept();
    const digestionTemperature = await this.readDigestionTemperature();
    const digestionTimeSeconds = await this.readDigestionTimeSeconds();
    const reactionTemperature = await this.readReactionTemperature();
    const reactionTimeSeconds = await this.readReactionTimeSeconds();
    const correctionFactor = await this.readCorrectionFactor();
    const currentRangeDilutionFactor = await this.readCurrentRangeDilutionFactor();
    const zeroCalibrationSolutionConcentration = await this.readZeroCalibrationSolutionConcentration();
    const spanCalibrationSolutionConcentration = await this.readSpanCalibrationSolutionConcentration();
    const reagentOneVolume = await this.readReagentOneVolume();
    const reagentTwoVolume = await this.readReagentTwoVolume();
    const reagentThreeVolume = await this.readReagentThreeVolume();
    const reagentFourVolume = await this.readReagentFourVolume();
    const reagentFiveVolume = await this.readReagentFiveVolume();
    const currentRangeCorrectionFactor = await this.readCurrentRangeCorrectionFactor();
    const spanCheckAllowedDeviation = await this.readSpanCheckAllowedDeviation();
    const spanCheckDeviation = await this.readSpanCheckDeviation();

    const config: MeasurementConfig = {
      currentRange,
      // 输入寄存器 26 的量程表不完整，不参与正常设置业务；独立读取接口仅供调试页使用。
      rangeTable: null,
      measurementMode,
      autoMeasurementIntervalHours,
      autoCalibrationMode,
      autoCalibrationIntervalHours,
      calibrationCurveSlope,
      calibrationCurveIntercept,
      digestionTemperature,
      digestionTimeSeconds,
      reactionTemperature,
      reactionTimeSeconds,
      correctionFactor,
      currentRangeDilutionFactor,
      zeroCalibrationSolutionConcentration,
      spanCalibrationSolutionConcentration,
      reagentOneVolume,
      reagentTwoVolume,
      reagentThreeVolume,
      reagentFourVolume,
      reagentFiveVolume,
      currentRangeCorrectionFactor,
      spanCheckAllowedDeviation,
      spanCheckDeviation
    };
    return config;
  }

  async readInstrumentInfo(): Promise<InstrumentInfo | null> {
    const productName = await this.readProductName();
    if (productName === null) {
      return null;
    }

    const productModel = await this.readProductModel();
    if (productModel === null) {
      return null;
    }

    const manufacturer = await this.readManufacturer();
    if (manufacturer === null) {
      return null;
    }

    const serialNumber = await this.readSerialNumber();
    if (serialNumber === null) {
      return null;
    }

    const instrumentInfo: InstrumentInfo = {
      productName,
      productModel,
      manufacturer,
      serialNumber
    };
    return instrumentInfo;
  }

  async readBoardInfo(): Promise<BoardInfo | null> {
    const liquidBoardVersion = await this.readLiquidBoardFirmwareVersion();
    const temperatureBoardVersion = await this.readTemperatureBoardFirmwareVersion();
    const signalBoardVersion = await this.readSignalBoardFirmwareVersion();
    const mainBoardVersion = await this.readMainBoardFirmwareVersion();
    const driverBoardVersion = await this.readDriverBoardFirmwareVersion();
    const reactionBoardVersion = await this.readReactionBoardFirmwareVersion();

    if (!liquidBoardVersion &&
      !temperatureBoardVersion &&
      !signalBoardVersion &&
      !mainBoardVersion &&
      !driverBoardVersion &&
      !reactionBoardVersion) {
      return null;
    }

    const liquidBoard: BoardFirmwareInfo = {
      boardKey: 'liquid',
      boardName: '液路板',
      firmwareVersion: liquidBoardVersion
    };
    const temperatureBoard: BoardFirmwareInfo = {
      boardKey: 'temperature',
      boardName: '温控板',
      firmwareVersion: temperatureBoardVersion
    };
    const signalBoard: BoardFirmwareInfo = {
      boardKey: 'signal',
      boardName: '信号板',
      firmwareVersion: signalBoardVersion
    };
    const mainBoard: BoardFirmwareInfo = {
      boardKey: 'main',
      boardName: '主控板',
      firmwareVersion: mainBoardVersion
    };
    const driverBoard: BoardFirmwareInfo = {
      boardKey: 'driver',
      boardName: '驱动板',
      firmwareVersion: driverBoardVersion
    };
    const reactionBoard: BoardFirmwareInfo = {
      boardKey: 'reaction',
      boardName: '反应板',
      firmwareVersion: reactionBoardVersion
    };

    const boardInfo: BoardInfo = {
      liquidBoard,
      temperatureBoard,
      signalBoard,
      mainBoard,
      driverBoard,
      reactionBoard
    };
    return boardInfo;
  }

  /**
   * 读取当前测量参数完整信息。
   *
   * Modbus: 功能码 0x04，输入寄存器 4，长度 1。
   * 返回仪器当前测试的水质参数码，并根据 PhotoTek 参数码表解析参数名称、旧码值和单位。
   *
   * @returns 成功返回测量参数信息；连接失败或响应异常时返回 null。
   */
  async readMeasurementParameterInfo(): Promise<PhotoTekMeasurementParameterInfo | null> {
    const code = await this.readUInt16InputRegister(
      PhotoTekInputRegisters.MEASUREMENT_PARAMETER,
      '读取测量参数'
    );
    if (code === null) {
      return null;
    }

    const resolved = getPhotoTekMeasurementParameterByCode(code);
    const paramInfo: PhotoTekMeasurementParameterInfo = resolved ?? {
      code,
      legacyCode: '',
      name: `未知参数(${code})`,
      unit: ''
    };

    hilog.info(DOMAIN, TAG, '测量参数码值=%{public}d, 名称=%{public}s',
      paramInfo.code, paramInfo.name);
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
  async readMeasurementParameter(): Promise<number | null> {
    const paramInfo = await this.readMeasurementParameterInfo();
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
  async readMeasurementResult(): Promise<number | null> {
    const value = await this.readFloatInputRegister(
      PhotoTekInputRegisters.MEASUREMENT_RESULT,
      '读取测量结果'
    );
    if (value === null) {
      return null;
    }

    hilog.info(DOMAIN, TAG, '测量结果=%{public}s', value.toString());
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
  async readMeasurementCalibrationSolutionResult(): Promise<number | null> {
    const value = await this.readFloatInputRegister(
      PhotoTekInputRegisters.CALIBRATION_SOLUTION_RESULT,
      '读取测量校准液结果'
    );
    if (value === null) {
      return null;
    }

    hilog.info(DOMAIN, TAG, '测量校准液结果=%{public}s', value.toString());
    return value;
  }

  /**
   * 读取测试结果类型。
   *
   * Modbus: 功能码 0x04，输入寄存器 5，长度 1。
   * 码值会解析为零点校准液、水样、量程校准液、跨度核查或质控样等含义。
   *
   * @returns 成功返回码值及含义；连接失败或响应异常时返回 null。
   */
  async readMeasurementResultType(): Promise<PhotoTekCodeDescription | null> {
    return this.readCodeDescriptionInputRegister(
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
  async readMeasurementDurationSeconds(): Promise<number | null> {
    return this.readUInt16InputRegister(
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
  async readMeasurementTime(): Promise<PhotoTekTimeValue | null> {
    return this.readTimeInputRegister(
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
  async readCalibrationSolutionTime(): Promise<PhotoTekTimeValue | null> {
    return this.readTimeInputRegister(
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
  async readCalibrationTime(): Promise<PhotoTekTimeValue | null> {
    return this.readTimeInputRegister(
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
  async readSystemStatus(): Promise<PhotoTekCodeDescription | null> {
    return this.readCodeDescriptionInputRegister(
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
  async readCurrentAction(): Promise<PhotoTekCodeDescription | null> {
    return this.readCodeDescriptionInputRegister(
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
  async readCurrentTemperatures(): Promise<PhotoTekTemperatureValue | null> {
    const values = await this.readFloatArrayInputRegister(
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
  async readAlarmTime(): Promise<PhotoTekTimeValue | null> {
    return this.readTimeInputRegister(
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
  async readAlarmCode(): Promise<PhotoTekCodeDescription | null> {
    return this.readCodeDescriptionInputRegister(
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
  async readRangeTable(): Promise<number[] | null> {
    const values = await this.readFloatArrayInputRegister(
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
  async readProductName(): Promise<string | null> {
    return this.readStringInputRegister(
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
  async readProductModel(): Promise<string | null> {
    return this.readStringInputRegister(
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
  async readManufacturer(): Promise<string | null> {
    return this.readStringInputRegister(
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
  async readSerialNumber(): Promise<string | null> {
    return this.readStringInputRegister(
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
  async readLiquidBoardFirmwareVersion(): Promise<PhotoTekFirmwareVersion | null> {
    return this.readFirmwareVersionInputRegister(
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
  async readTemperatureBoardFirmwareVersion(): Promise<PhotoTekFirmwareVersion | null> {
    return this.readFirmwareVersionInputRegister(
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
  async readSignalBoardFirmwareVersion(): Promise<PhotoTekFirmwareVersion | null> {
    return this.readFirmwareVersionInputRegister(
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
  async readMainBoardFirmwareVersion(): Promise<PhotoTekFirmwareVersion | null> {
    return this.readFirmwareVersionInputRegister(
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
  async readDriverBoardFirmwareVersion(): Promise<PhotoTekFirmwareVersion | null> {
    return this.readFirmwareVersionInputRegister(
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
  async readReactionBoardFirmwareVersion(): Promise<PhotoTekFirmwareVersion | null> {
    return this.readFirmwareVersionInputRegister(
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
  async readSpanCheckResult(): Promise<number | null> {
    return this.readFloatInputRegister(
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
  async readSpanCheckTime(): Promise<PhotoTekTimeValue | null> {
    return this.readTimeInputRegister(
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
  async readWaterSampleAbsorbance(): Promise<number | null> {
    return this.readFloatInputRegister(
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
  async readWaterSampleDataFlag(): Promise<PhotoTekDataFlag | null> {
    return this.readDataFlagInputRegister(
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
  async readCalibrationSolutionAbsorbance(): Promise<number | null> {
    return this.readFloatInputRegister(
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
  async readCalibrationSolutionDataFlag(): Promise<PhotoTekDataFlag | null> {
    return this.readDataFlagInputRegister(
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
  async readCheckSolutionAbsorbance(): Promise<number | null> {
    return this.readFloatInputRegister(
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
  async readCheckSolutionDataFlag(): Promise<PhotoTekDataFlag | null> {
    return this.readDataFlagInputRegister(
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
  async readCalibrationZeroConcentration(): Promise<number | null> {
    return this.readFloatInputRegister(
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
  async readCalibrationZeroAbsorbance(): Promise<number | null> {
    return this.readFloatInputRegister(
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
  async readZeroDrift(): Promise<number | null> {
    return this.readFloatInputRegister(
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
  async readCalibrationSpanConcentration(): Promise<number | null> {
    return this.readFloatInputRegister(
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
  async readCalibrationSpanAbsorbance(): Promise<number | null> {
    return this.readFloatInputRegister(
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
  async readSpanDrift(): Promise<number | null> {
    return this.readFloatInputRegister(
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
  async readCompositeMeasurementResult(): Promise<number | null> {
    return this.readFloatInputRegister(
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
  async readCompositeResultTime(): Promise<PhotoTekTimeValue | null> {
    return this.readTimeInputRegister(
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
  async readCompositeDataFlag(): Promise<PhotoTekDataFlag | null> {
    return this.readDataFlagInputRegister(
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
  async readTocFactorConstant(): Promise<number | null> {
    return this.readFloatInputRegister(
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
  async readTocFactorRatio(): Promise<number | null> {
    return this.readFloatInputRegister(
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
  async readTocFlowControl(): Promise<number | null> {
    return this.readFloatInputRegister(
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
  async readTocMeasurementResult(): Promise<number | null> {
    return this.readFloatInputRegister(
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
  async readCurrentRange(): Promise<number | null> {
    return this.readFloatHoldRegister(PhotoTekHoldRegisters.CURRENT_RANGE, '读取当前量程');
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
  async writeCurrentRange(rangeUpperLimit: number): Promise<boolean> {
    return this.writeFloatHoldRegister(
      PhotoTekHoldRegisters.CURRENT_RANGE,
      rangeUpperLimit,
      '写入当前量程'
    );
  }

  /**
   * 读取校准曲线斜率。
   *
   * Modbus: 功能码 0x03，保持寄存器 258，长度 2，PhotoTek CDAB 浮点数。
   *
   * @returns 成功返回校准曲线斜率；连接失败或响应异常时返回 null。
   */
  async readCalibrationCurveSlope(): Promise<number | null> {
    return this.readFloatHoldRegister(
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
  async writeCalibrationCurveSlope(slope: number): Promise<boolean> {
    return this.writeFloatHoldRegister(
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
  async readCalibrationCurveIntercept(): Promise<number | null> {
    return this.readFloatHoldRegister(
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
  async writeCalibrationCurveIntercept(intercept: number): Promise<boolean> {
    return this.writeFloatHoldRegister(
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
  async readDigestionTemperature(): Promise<number | null> {
    return this.readFloatHoldRegister(
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
  async writeDigestionTemperature(temperature: number): Promise<boolean> {
    return this.writeFloatHoldRegister(
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
  async readDigestionTimeSeconds(): Promise<number | null> {
    return this.readUInt16HoldRegister(PhotoTekHoldRegisters.DIGESTION_TIME, '读取消解时间');
  }

  /**
   * 写入消解时间。
   *
   * Modbus: 功能码 0x06，保持寄存器 264，长度 1，无符号 16 位整数。
   *
   * @param seconds 消解时间，单位秒，取值 0~65535。
   * @returns 写入成功返回 true，否则返回 false。
   */
  async writeDigestionTimeSeconds(seconds: number): Promise<boolean> {
    return this.writeUInt16HoldRegister(
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
  async readReactionTemperature(): Promise<number | null> {
    return this.readFloatHoldRegister(
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
  async writeReactionTemperature(temperature: number): Promise<boolean> {
    return this.writeFloatHoldRegister(
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
  async readReactionTimeSeconds(): Promise<number | null> {
    return this.readUInt16HoldRegister(PhotoTekHoldRegisters.REACTION_TIME, '读取反应时间');
  }

  /**
   * 写入反应时间。
   *
   * Modbus: 功能码 0x06，保持寄存器 267，长度 1，无符号 16 位整数。
   *
   * @param seconds 反应时间，单位秒，取值 0~65535。
   * @returns 写入成功返回 true，否则返回 false。
   */
  async writeReactionTimeSeconds(seconds: number): Promise<boolean> {
    return this.writeUInt16HoldRegister(
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
  async readCorrectionFactor(): Promise<number | null> {
    return this.readFloatHoldRegister(PhotoTekHoldRegisters.CORRECTION_FACTOR, '读取修正因子');
  }

  /**
   * 写入修正因子。
   *
   * Modbus: 功能码 0x10，保持寄存器 268，长度 2，PhotoTek CDAB 浮点数。
   *
   * @param factor 修正因子。
   * @returns 写入成功返回 true，否则返回 false。
   */
  async writeCorrectionFactor(factor: number): Promise<boolean> {
    return this.writeFloatHoldRegister(
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
  async writeMeasurementControl(controlCode: number): Promise<boolean> {
    if (!this.isKnownCode(PhotoTekMeasurementControlCodes, controlCode)) {
      hilog.error(DOMAIN, TAG, '写入测量控制失败: 未知控制码 %{public}d', controlCode);
      return false;
    }
    return this.writeUInt16HoldRegister(
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
  async writeWaterCollectionControl(enabled: boolean): Promise<boolean> {
    return this.writeUInt16HoldRegister(
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
  async readSystemTime(): Promise<PhotoTekTimeValue | null> {
    return this.readTimeHoldRegister(PhotoTekHoldRegisters.SYSTEM_TIME, '读取系统时间');
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
  async writeSystemTime(
    year: number,
    month: number,
    day: number,
    hour: number,
    minute: number,
    second: number
  ): Promise<boolean> {
    return this.writeTimeHoldRegister(
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
  async readMeasurementMode(): Promise<PhotoTekCodeDescription | null> {
    return this.readCodeDescriptionHoldRegister(
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
  async writeMeasurementMode(mode: number): Promise<boolean> {
    if (!this.isKnownCode(PhotoTekMeasurementModes, mode)) {
      hilog.error(DOMAIN, TAG, '写入测量模式失败: 未知模式 %{public}d', mode);
      return false;
    }
    return this.writeUInt16HoldRegister(
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
  async readAutoMeasurementIntervalHours(): Promise<number | null> {
    return this.readUInt16HoldRegister(
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
  async writeAutoMeasurementIntervalHours(hours: number): Promise<boolean> {
    return this.writeUInt16HoldRegister(
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
  async readAutoCalibrationMode(): Promise<PhotoTekCodeDescription | null> {
    return this.readCodeDescriptionHoldRegister(
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
  async writeAutoCalibrationMode(mode: number): Promise<boolean> {
    if (!this.isKnownCode(PhotoTekAutoCalibrationModes, mode)) {
      hilog.error(DOMAIN, TAG, '写入自动校准模式失败: 未知模式 %{public}d', mode);
      return false;
    }
    return this.writeUInt16HoldRegister(
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
  async readAutoCalibrationIntervalHours(): Promise<number | null> {
    return this.readUInt16HoldRegister(
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
  async writeAutoCalibrationIntervalHours(hours: number): Promise<boolean> {
    return this.writeUInt16HoldRegister(
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
  async readCurrentRangeDilutionFactor(): Promise<number | null> {
    return this.readFloatHoldRegister(
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
  async readZeroCalibrationSolutionConcentration(): Promise<number | null> {
    return this.readFloatHoldRegister(
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
  async readSpanCalibrationSolutionConcentration(): Promise<number | null> {
    return this.readFloatHoldRegister(
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
  async readReagentOneVolume(): Promise<number | null> {
    return this.readFloatHoldRegister(PhotoTekHoldRegisters.REAGENT_ONE_VOLUME, '读取试剂一加液体积');
  }

  /**
   * 读取试剂二加液体积。
   *
   * Modbus: 功能码 0x03，保持寄存器 302，长度 2，PhotoTek CDAB 浮点数。
   *
   * @returns 成功返回试剂二加液体积，单位 mL；连接失败或响应异常时返回 null。
   */
  async readReagentTwoVolume(): Promise<number | null> {
    return this.readFloatHoldRegister(PhotoTekHoldRegisters.REAGENT_TWO_VOLUME, '读取试剂二加液体积');
  }

  /**
   * 读取试剂三加液体积。
   *
   * Modbus: 功能码 0x03，保持寄存器 304，长度 2，PhotoTek CDAB 浮点数。
   *
   * @returns 成功返回试剂三加液体积，单位 mL；连接失败或响应异常时返回 null。
   */
  async readReagentThreeVolume(): Promise<number | null> {
    return this.readFloatHoldRegister(PhotoTekHoldRegisters.REAGENT_THREE_VOLUME, '读取试剂三加液体积');
  }

  /**
   * 读取试剂四加液体积。
   *
   * Modbus: 功能码 0x03，保持寄存器 306，长度 2，PhotoTek CDAB 浮点数。
   *
   * @returns 成功返回试剂四加液体积，单位 mL；连接失败或响应异常时返回 null。
   */
  async readReagentFourVolume(): Promise<number | null> {
    return this.readFloatHoldRegister(PhotoTekHoldRegisters.REAGENT_FOUR_VOLUME, '读取试剂四加液体积');
  }

  /**
   * 读取试剂五加液体积。
   *
   * Modbus: 功能码 0x03，保持寄存器 308，长度 2，PhotoTek CDAB 浮点数。
   *
   * @returns 成功返回试剂五加液体积，单位 mL；连接失败或响应异常时返回 null。
   */
  async readReagentFiveVolume(): Promise<number | null> {
    return this.readFloatHoldRegister(PhotoTekHoldRegisters.REAGENT_FIVE_VOLUME, '读取试剂五加液体积');
  }

  /**
   * 读取当前量程校正因子。
   *
   * Modbus: 功能码 0x03，保持寄存器 310，长度 2，PhotoTek CDAB 浮点数。
   *
   * @returns 成功返回当前量程校正因子；连接失败或响应异常时返回 null。
   */
  async readCurrentRangeCorrectionFactor(): Promise<number | null> {
    return this.readFloatHoldRegister(
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
  async readSpanCheckAllowedDeviation(): Promise<number | null> {
    return this.readFloatHoldRegister(
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
  async readSpanCheckDeviation(): Promise<number | null> {
    return this.readFloatHoldRegister(
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
  async startMeasurement(): Promise<boolean> {
    return this.writeMeasurementControl(0);
  }

  /**
   * 启动校准。
   *
   * Modbus: 功能码 0x06，保持寄存器 0x0110，写入 0x0001。
   *
   * @returns 下发成功返回 true，失败返回 false。
   */
  async startCalibration(): Promise<boolean> {
    return this.writeMeasurementControl(1);
  }

  /**
   * 停止测量。
   *
   * Modbus: 功能码 0x06，保持寄存器 0x0110，写入 0x0002。
   *
   * @returns 下发成功返回 true，失败返回 false。
   */
  async stopMeasurement(): Promise<boolean> {
    return this.writeMeasurementControl(2);
  }

  /**
   * 启动深度清洗。
   *
   * Modbus: 功能码 0x06，保持寄存器 0x0110，写入 0x0007。
   *
   * @returns 下发成功返回 true，失败返回 false。
   */
  async startCleaning(): Promise<boolean> {
    return this.writeMeasurementControl(7);
  }

  /**
   * 测量量程校准液。
   *
   * Modbus: 功能码 0x06，保持寄存器 272，写入控制码 3。
   *
   * @returns 下发成功返回 true，失败返回 false。
   */
  async measureRangeCalibrationSolution(): Promise<boolean> {
    return this.writeMeasurementControl(3);
  }

  /**
   * 测量零点校准液。
   *
   * Modbus: 功能码 0x06，保持寄存器 272，写入控制码 4。
   *
   * @returns 下发成功返回 true，失败返回 false。
   */
  async measureZeroCalibrationSolution(): Promise<boolean> {
    return this.writeMeasurementControl(4);
  }

  /**
   * 清洗定量管。
   *
   * Modbus: 功能码 0x06，保持寄存器 272，写入控制码 5。
   *
   * @returns 下发成功返回 true，失败返回 false。
   */
  async cleanQuantitativeTube(): Promise<boolean> {
    return this.writeMeasurementControl(5);
  }

  /**
   * 清洗消解室。
   *
   * Modbus: 功能码 0x06，保持寄存器 272，写入控制码 6。
   *
   * @returns 下发成功返回 true，失败返回 false。
   */
  async cleanDigestionChamber(): Promise<boolean> {
    return this.writeMeasurementControl(6);
  }

  /**
   * 清洗所有管路。
   *
   * Modbus: 功能码 0x06，保持寄存器 272，写入控制码 8。
   *
   * @returns 下发成功返回 true，失败返回 false。
   */
  async cleanAllPipelines(): Promise<boolean> {
    return this.writeMeasurementControl(8);
  }

  /**
   * 采集水样。
   *
   * Modbus: 功能码 0x06，保持寄存器 272，写入控制码 9。
   *
   * @returns 下发成功返回 true，失败返回 false。
   */
  async collectWaterSample(): Promise<boolean> {
    return this.writeMeasurementControl(9);
  }

  /**
   * 启动定量泵自动校准。
   *
   * Modbus: 功能码 0x06，保持寄存器 272，写入控制码 10。
   *
   * @returns 下发成功返回 true，失败返回 false。
   */
  async startQuantitativePumpCalibration(): Promise<boolean> {
    return this.writeMeasurementControl(10);
  }

  /**
   * 启动零点校准。
   *
   * Modbus: 功能码 0x06，保持寄存器 272，写入控制码 13。
   *
   * @returns 下发成功返回 true，失败返回 false。
   */
  async startZeroCalibration(): Promise<boolean> {
    return this.writeMeasurementControl(13);
  }

  /**
   * 启动量程标点校准。
   *
   * Modbus: 功能码 0x06，保持寄存器 272，写入控制码 14。
   *
   * @returns 下发成功返回 true，失败返回 false。
   */
  async startSpanCalibration(): Promise<boolean> {
    return this.writeMeasurementControl(14);
  }

  /**
   * 启动零点核查。
   *
   * Modbus: 功能码 0x06，保持寄存器 272，写入控制码 20。
   *
   * @returns 下发成功返回 true，失败返回 false。
   */
  async startZeroCheck(): Promise<boolean> {
    return this.writeMeasurementControl(20);
  }

  /**
   * 启动跨度或标样核查液测量。
   *
   * Modbus: 功能码 0x06，保持寄存器 272，写入控制码 21。
   *
   * @returns 下发成功返回 true，失败返回 false。
   */
  async startSpanCheck(): Promise<boolean> {
    return this.writeMeasurementControl(21);
  }

  /**
   * 确保当前选中的传输通道已连接。
   *
   * @returns 当前通道连接成功返回 true，否则返回 false。
   */
  private async ensureConnected(): Promise<boolean> {
    return this.connect();
  }

  /**
   * 通过当前传输通道读取输入寄存器。
   *
   * @param regAddr 输入寄存器起始地址。
   * @param regCount 读取寄存器数量。
   * @param actionName 日志动作名称。
   * @returns 成功返回纯 PDU；连接或响应异常时返回 null。
   */
  async readInputRegisters(regAddr: number, regCount: number, actionName: string): Promise<Uint8Array | null> {
    return this.communicationMode === 'tcp' ?
      ModbusTcpClient.readInputRegisters(this.DEVICE_ADDR, regAddr, regCount, actionName) :
      UartClient.readInputRegisters(this.DEVICE_ADDR, regAddr, regCount, actionName);
  }

  /**
   * 通过当前传输通道读取保持寄存器。
   *
   * @param regAddr 保持寄存器起始地址。
   * @param regCount 读取寄存器数量。
   * @param actionName 日志动作名称。
   * @returns 成功返回纯 PDU；连接或响应异常时返回 null。
   */
  async readHoldRegisters(regAddr: number, regCount: number, actionName: string): Promise<Uint8Array | null> {
    return this.communicationMode === 'tcp' ?
      ModbusTcpClient.readHoldRegisters(this.DEVICE_ADDR, regAddr, regCount, actionName) :
      UartClient.readHoldRegisters(this.DEVICE_ADDR, regAddr, regCount, actionName);
  }

  /**
   * 根据协议定义读取输入寄存器数据区。
   *
   * @param register PhotoTek 输入寄存器定义。
   * @param actionName 日志动作名称。
   * @returns 成功返回响应数据区；连接失败、响应异常或功能码异常时返回 null。
   */
  async readInputRegisterData(
    register: PhotoTekInputRegisterDefinition,
    actionName: string
  ): Promise<Uint8Array | null> {
    if (!(await this.ensureConnected())) {
      hilog.error(DOMAIN, TAG, '%{public}s: communication channel is not connected', actionName);
      return null;
    }

    const responsePdu = await this.readInputRegisters(
      register.address,
      register.registerCount,
      actionName
    );
    if (!responsePdu) {
      return null;
    }
    return this.getReadDataBytes(responsePdu, actionName);
  }

  /**
   * 根据协议定义读取保持寄存器数据区。
   *
   * @param register PhotoTek 保持寄存器定义。
   * @param actionName 日志动作名称。
   * @returns 成功返回响应数据区；连接失败、响应异常、功能码异常或寄存器不可读时返回 null。
   */
  async readHoldRegisterData(
    register: PhotoTekHoldRegisterDefinition,
    actionName: string
  ): Promise<Uint8Array | null> {
    if (register.access === 'write') {
      hilog.error(DOMAIN, TAG, '%{public}s失败: 寄存器不可读 %{public}s', actionName, register.name);
      return null;
    }

    if (!(await this.ensureConnected())) {
      hilog.error(DOMAIN, TAG, '%{public}s: communication channel is not connected', actionName);
      return null;
    }

    const responsePdu = await this.readHoldRegisters(
      register.address,
      register.registerCount,
      actionName
    );
    if (!responsePdu) {
      return null;
    }
    return this.getReadDataBytes(responsePdu, actionName, 0x03);
  }

  /**
   * 根据协议定义读取并解析 1 个保持寄存器无符号整数。
   *
   * @param register PhotoTek 保持寄存器定义。
   * @param actionName 日志动作名称。
   * @returns 成功返回整数值；失败返回 null。
   */
  async readUInt16HoldRegister(
    register: PhotoTekHoldRegisterDefinition,
    actionName: string
  ): Promise<number | null> {
    const dataBytes = await this.readHoldRegisterData(register, actionName);
    if (!dataBytes) {
      return null;
    }
    return PhotoTekValueParser.parseUInt16(dataBytes);
  }

  /**
   * 根据协议定义读取并解析 1 个保持寄存器 CDAB 浮点数。
   *
   * @param register PhotoTek 保持寄存器定义。
   * @param actionName 日志动作名称。
   * @returns 成功返回浮点值；失败返回 null。
   */
  async readFloatHoldRegister(
    register: PhotoTekHoldRegisterDefinition,
    actionName: string
  ): Promise<number | null> {
    const dataBytes = await this.readHoldRegisterData(register, actionName);
    if (!dataBytes) {
      return null;
    }
    return PhotoTekValueParser.parseFloatCdab(dataBytes);
  }

  /**
   * 根据协议定义读取并解析保持寄存器 PhotoTek 时间类型。
   *
   * @param register PhotoTek 保持寄存器定义。
   * @param actionName 日志动作名称。
   * @returns 成功返回结构化时间；失败返回 null。
   */
  async readTimeHoldRegister(
    register: PhotoTekHoldRegisterDefinition,
    actionName: string
  ): Promise<PhotoTekTimeValue | null> {
    const dataBytes = await this.readHoldRegisterData(register, actionName);
    if (!dataBytes) {
      return null;
    }
    return PhotoTekValueParser.parseTime(dataBytes);
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
  async readCodeDescriptionHoldRegister(
    register: PhotoTekHoldRegisterDefinition,
    table: PhotoTekCodeDescription[],
    unknownLabel: string,
    actionName: string
  ): Promise<PhotoTekCodeDescription | null> {
    const code = await this.readUInt16HoldRegister(register, actionName);
    if (code === null) {
      return null;
    }

    const resolved = getPhotoTekCodeDescription(table, code);
    if (resolved) {
      return resolved;
    }
    const unknownDescription: PhotoTekCodeDescription = {
      code,
      label: `${unknownLabel}(${code})`
    };
    return unknownDescription;
  }

  /**
   * 根据保持寄存器定义写入 1 个无符号 16 位整数。
   *
   * @param register PhotoTek 保持寄存器定义。
   * @param value 需要写入的整数值。
   * @param actionName 日志动作名称。
   * @returns 写入成功返回 true，否则返回 false。
   */
  async writeUInt16HoldRegister(
    register: PhotoTekHoldRegisterDefinition,
    value: number,
    actionName: string
  ): Promise<boolean> {
    const regValue = PhotoTekValueParser.encodeUInt16(value);
    if (regValue === null) {
      hilog.error(DOMAIN, TAG, '%{public}s失败: 无效 uint16 值 %{public}d', actionName, value);
      return false;
    }
    return this.writeHoldRegisterValues(register, [regValue], actionName);
  }

  /**
   * 根据保持寄存器定义写入 1 个 CDAB 浮点数。
   *
   * @param register PhotoTek 保持寄存器定义。
   * @param value 需要写入的浮点值。
   * @param actionName 日志动作名称。
   * @returns 写入成功返回 true，否则返回 false。
   */
  async writeFloatHoldRegister(
    register: PhotoTekHoldRegisterDefinition,
    value: number,
    actionName: string
  ): Promise<boolean> {
    const regValues = PhotoTekValueParser.encodeFloatCdab(value);
    if (!regValues) {
      hilog.error(DOMAIN, TAG, '%{public}s失败: 无效浮点值', actionName);
      return false;
    }
    return this.writeHoldRegisterValues(register, regValues, actionName);
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
  async writeTimeHoldRegister(
    register: PhotoTekHoldRegisterDefinition,
    year: number,
    month: number,
    day: number,
    hour: number,
    minute: number,
    second: number,
    actionName: string
  ): Promise<boolean> {
    const regValues = PhotoTekValueParser.encodeTimeRegisters(year, month, day, hour, minute, second);
    if (!regValues) {
      hilog.error(DOMAIN, TAG, '%{public}s失败: 无效时间参数', actionName);
      return false;
    }
    return this.writeHoldRegisterValues(register, regValues, actionName);
  }

  /**
   * 根据保持寄存器定义写入连续寄存器值。
   *
   * @param register PhotoTek 保持寄存器定义。
   * @param regValues 已按 Modbus 大端寄存器顺序编码的寄存器值。
   * @param actionName 日志动作名称。
   * @returns 写入成功返回 true，否则返回 false。
   */
  async writeHoldRegisterValues(
    register: PhotoTekHoldRegisterDefinition,
    regValues: number[],
    actionName: string
  ): Promise<boolean> {
    if (register.access === 'read') {
      hilog.error(DOMAIN, TAG, '%{public}s失败: 寄存器不可写 %{public}s', actionName, register.name);
      return false;
    }

    if (regValues.length !== register.registerCount) {
      hilog.error(
        DOMAIN,
        TAG,
        '%{public}s失败: 寄存器数量异常 expected=%{public}d actual=%{public}d',
        actionName,
        register.registerCount,
        regValues.length
      );
      return false;
    }

    if (!(await this.ensureConnected())) {
      hilog.error(DOMAIN, TAG, '%{public}s: communication channel is not connected', actionName);
      return false;
    }

    hilog.info(DOMAIN, TAG, '%{public}s via %{public}s', actionName, this.communicationMode);
    if (regValues.length === 1) {
      return this.communicationMode === 'tcp' ?
        ModbusTcpClient.writeSingleRegister(this.DEVICE_ADDR, register.address, regValues[0], actionName) :
        UartClient.writeSingleRegister(this.DEVICE_ADDR, register.address, regValues[0], actionName);
    }

    return this.communicationMode === 'tcp' ?
      ModbusTcpClient.writeMultiRegister(
        this.DEVICE_ADDR,
        register.address,
        regValues,
        actionName
      ) :
      UartClient.writeMultiRegister(
        this.DEVICE_ADDR,
        register.address,
        regValues,
        actionName
      );
  }

  /**
   * 根据协议定义读取并解析 1 个无符号 16 位寄存器。
   *
   * @param register PhotoTek 输入寄存器定义。
   * @param actionName 日志动作名称。
   * @returns 成功返回整数值；失败返回 null。
   */
  async readUInt16InputRegister(
    register: PhotoTekInputRegisterDefinition,
    actionName: string
  ): Promise<number | null> {
    const dataBytes = await this.readInputRegisterData(register, actionName);
    if (!dataBytes) {
      return null;
    }
    return PhotoTekValueParser.parseUInt16(dataBytes);
  }

  /**
   * 根据协议定义读取并解析 1 个 CDAB 浮点数。
   *
   * @param register PhotoTek 输入寄存器定义。
   * @param actionName 日志动作名称。
   * @returns 成功返回浮点值；失败返回 null。
   */
  async readFloatInputRegister(
    register: PhotoTekInputRegisterDefinition,
    actionName: string
  ): Promise<number | null> {
    const dataBytes = await this.readInputRegisterData(register, actionName);
    if (!dataBytes) {
      return null;
    }
    return PhotoTekValueParser.parseFloatCdab(dataBytes);
  }

  /**
   * 根据协议定义读取并解析 CDAB 浮点数组。
   *
   * @param register PhotoTek 输入寄存器定义。
   * @param floatCount 需要解析的浮点数数量。
   * @param actionName 日志动作名称。
   * @returns 成功返回浮点数组；失败返回 null。
   */
  async readFloatArrayInputRegister(
    register: PhotoTekInputRegisterDefinition,
    floatCount: number,
    actionName: string
  ): Promise<number[] | null> {
    const dataBytes = await this.readInputRegisterData(register, actionName);
    if (!dataBytes) {
      return null;
    }
    return PhotoTekValueParser.parseFloatCdabArray(dataBytes, floatCount);
  }

  /**
   * 根据协议定义读取并解析 PhotoTek 时间类型。
   *
   * @param register PhotoTek 输入寄存器定义。
   * @param actionName 日志动作名称。
   * @returns 成功返回结构化时间；失败返回 null。
   */
  async readTimeInputRegister(
    register: PhotoTekInputRegisterDefinition,
    actionName: string
  ): Promise<PhotoTekTimeValue | null> {
    const dataBytes = await this.readInputRegisterData(register, actionName);
    if (!dataBytes) {
      return null;
    }
    return PhotoTekValueParser.parseTime(dataBytes);
  }

  /**
   * 根据协议定义读取并解析 UTF-16BE 字符串。
   *
   * @param register PhotoTek 输入寄存器定义。
   * @param actionName 日志动作名称。
   * @returns 成功返回字符串；失败返回 null。
   */
  async readStringInputRegister(
    register: PhotoTekInputRegisterDefinition,
    actionName: string
  ): Promise<string | null> {
    const dataBytes = await this.readInputRegisterData(register, actionName);
    if (!dataBytes) {
      return null;
    }
    return PhotoTekValueParser.parseUtf16String(dataBytes);
  }

  /**
   * 根据协议定义读取并解析板卡固件版本。
   *
   * @param register PhotoTek 输入寄存器定义。
   * @param actionName 日志动作名称。
   * @returns 成功返回固件版本；失败返回 null。
   */
  async readFirmwareVersionInputRegister(
    register: PhotoTekInputRegisterDefinition,
    actionName: string
  ): Promise<PhotoTekFirmwareVersion | null> {
    const dataBytes = await this.readInputRegisterData(register, actionName);
    if (!dataBytes) {
      return null;
    }
    return PhotoTekValueParser.parseFirmwareVersion(dataBytes);
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
  async readCodeDescriptionInputRegister(
    register: PhotoTekInputRegisterDefinition,
    table: PhotoTekCodeDescription[],
    unknownLabel: string,
    actionName: string
  ): Promise<PhotoTekCodeDescription | null> {
    const code = await this.readUInt16InputRegister(register, actionName);
    if (code === null) {
      return null;
    }

    const resolved = getPhotoTekCodeDescription(table, code);
    if (resolved) {
      return resolved;
    }
    const unknownDescription: PhotoTekCodeDescription = {
      code,
      label: `${unknownLabel}(${code})`
    };
    return unknownDescription;
  }

  /**
   * 根据协议定义读取字符型数据标识并解析含义。
   *
   * @param register PhotoTek 输入寄存器定义。
   * @param table 数据标识码表。
   * @param actionName 日志动作名称。
   * @returns 成功返回数据标识和含义；失败返回 null。
   */
  async readDataFlagInputRegister(
    register: PhotoTekInputRegisterDefinition,
    table: PhotoTekCodeDescription[],
    actionName: string
  ): Promise<PhotoTekDataFlag | null> {
    const dataBytes = await this.readInputRegisterData(register, actionName);
    if (!dataBytes) {
      return null;
    }

    const code = PhotoTekValueParser.parseRegisterChar(dataBytes);
    if (code === null) {
      return null;
    }

    const resolved = getPhotoTekCodeDescription(table, code);
    const dataFlag: PhotoTekDataFlag = {
      code,
      label: resolved ? resolved.label : `未知标识(${code})`
    };
    return dataFlag;
  }

  /**
   * 从读寄存器响应 PDU 中提取数据区。
   *
   * @param responsePdu Client 返回的纯 PDU。
   * @param actionName 日志动作名称。
   * @param expectedFuncCode 期望的读寄存器功能码，0x04 表示输入寄存器，0x03 表示保持寄存器。
   * @returns 成功返回数据区；功能码或字节数异常时返回 null。
   */
  getReadDataBytes(
    responsePdu: Uint8Array,
    actionName: string,
    expectedFuncCode: number = 0x04
  ): Uint8Array | null {
    // Client 返回的是 PDU，所以这里不再关心 TCP 的 MBAP 或 RTU 的地址/CRC。
    const funcCode = responsePdu[0];
    if (funcCode !== expectedFuncCode) {
      hilog.error(DOMAIN, TAG, '%{public}s失败: 功能码异常 %{public}d', actionName, funcCode);
      return null;
    }

    const byteCount = responsePdu[1];
    if (responsePdu.length < 2 + byteCount) {
      hilog.error(DOMAIN, TAG, '%{public}s失败: 字节数异常 %{public}d', actionName, byteCount);
      return null;
    }
    return responsePdu.slice(2, 2 + byteCount);
  }

  /**
   * 判断数值是否存在于指定码表。
   *
   * @param table 协议码表。
   * @param code 需要检查的数字码值。
   * @returns 码表中存在该码值时返回 true，否则返回 false。
   */
  isKnownCode(table: PhotoTekCodeDescription[], code: number): boolean {
    for (const item of table) {
      if (item.code === code) {
        return true;
      }
    }
    return false;
  }

}

