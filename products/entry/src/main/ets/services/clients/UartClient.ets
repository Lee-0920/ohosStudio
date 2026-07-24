import { hilog } from '@kit.PerformanceAnalysisKit';
import serial from 'libserial_port.so';
import { PromiseFifoQueue } from './PromiseFifoQueue';
import { SerialFailureCircuitBreaker } from './SerialFailureCircuitBreaker';

const DOMAIN = 0x0002;
const TAG = 'UartClient';

// 只负责 Modbus RTU/串口通道：打开串口、组 RTU 帧、追加 CRC、读取并校验二进制响应。
export class UartClient {
  private static portPath: string = '/dev/ttyS7';
  private static baudRate: number = 9600;
  private static dataBits: number = 8;
  private static stopBits: number = 1;
  private static parity: string = 'N';
  private static isRs485: boolean = false;
  private static readonly READ_SIZE: number = 1024;
  private static readonly MIN_RESPONSE_FRAME_LENGTH: number = 5;
  private static readonly RESPONSE_READ_RETRY_COUNT: number = 3;
  private static readonly MODBUS_RESPONSE_TIMEOUT_MS: number = 500;
  private static readonly FAILURE_BREAKER_THRESHOLD: number = 3;
  private static lastError: string = '';
  private static failureBreaker: SerialFailureCircuitBreaker =
    new SerialFailureCircuitBreaker(UartClient.FAILURE_BREAKER_THRESHOLD);
  private static readonly requestQueue: PromiseFifoQueue = new PromiseFifoQueue();

  private static formatError(err: Error): string {
    const text = String(err);
    const json = JSON.stringify(err);
    return json && json !== '{}' ? `${text}, json=${json}` : text;
  }

  private static readNativeLastError(): string {
    try {
      const reason = serial.getLastError() as string;
      return reason ? reason : '';
    } catch (_err) {
      return '';
    }
  }

  private static setLastError(message: string): void {
    UartClient.lastError = message;
  }

  static getLastError(): string {
    return UartClient.lastError;
  }

  static setConfig(
    path: string,
    baudRate: number,
    dataBits: number = 8,
    stopBits: number = 1,
    parity: string = 'N',
    isRs485: boolean = false
  ): void {
    if (UartClient.isOpen()) {
      UartClient.close();
    }
    UartClient.failureBreaker.reset();
    UartClient.portPath = path;
    UartClient.baudRate = baudRate;
    UartClient.dataBits = dataBits;
    UartClient.stopBits = stopBits;
    UartClient.parity = parity;
    UartClient.isRs485 = isRs485;
    hilog.info(DOMAIN, TAG, 'UART config updated: %{public}s/%{public}d/%{public}s',
      path, baudRate, isRs485 ? 'RS485' : 'RS232');
  }

  static async connect(): Promise<boolean> {
    // 串口已经打开时直接复用，避免重复 open 改动 fd 状态。
    if (UartClient.isOpen()) {
      return true;
    }
    return UartClient.open();
  }

  static disconnect(): void {
    UartClient.close();
    UartClient.failureBreaker.reset();
  }

  static isConnected(): boolean {
    return UartClient.isOpen();
  }

  static open(): boolean {
    try {
      UartClient.setLastError('');
      const ok: boolean = serial.open(
        UartClient.portPath,
        UartClient.baudRate,
        UartClient.dataBits,
        UartClient.stopBits,
        UartClient.parity,
        UartClient.isRs485
      ) as boolean;
      if (!ok) {
        const reason = UartClient.readNativeLastError();
        const message = reason.length > 0 ? `open failed: ${UartClient.portPath}, ${reason}` : `open failed: ${UartClient.portPath}`;
        UartClient.setLastError(message);
        hilog.error(DOMAIN, TAG, 'open failed: %{public}s reason=%{public}s', UartClient.portPath, reason.length > 0 ? reason : 'unknown');
      }
      return ok;
    } catch (err) {
      const reason = UartClient.formatError(err as Error);
      UartClient.setLastError(`open exception: ${reason}`);
      hilog.error(DOMAIN, TAG, 'open exception: %{public}s', reason);
      return false;
    }
  }

  static close(): void {
    try {
      serial.close();
      UartClient.failureBreaker.reset();
    } catch (err) {
      const reason = UartClient.formatError(err as Error);
      UartClient.setLastError(`close exception: ${reason}`);
      hilog.warn(DOMAIN, TAG, 'close exception: %{public}s', reason);
    }
  }

  static isOpen(): boolean {
    try {
      return serial.isOpen() as boolean;
    } catch (err) {
      const reason = UartClient.formatError(err as Error);
      UartClient.setLastError(`isOpen exception: ${reason}`);
      hilog.warn(DOMAIN, TAG, 'isOpen exception: %{public}s', reason);
      return false;
    }
  }

  static writeText(payload: string): number {
    const data = new Uint8Array(payload.length);
    for (let i = 0; i < payload.length; i++) {
      data[i] = payload.charCodeAt(i) & 0xff;
    }
    return UartClient.writeRaw(data);
  }

  static readText(maxLen: number = UartClient.READ_SIZE, timeoutMs: number = 1000): string {
    const data = UartClient.readRaw(maxLen, timeoutMs);
    if (!data) {
      return '';
    }

    let out = '';
    for (let i = 0; i < data.length; i++) {
      out += String.fromCharCode(data[i]);
    }
    return out;
  }

  static async readInputRegisters(
    deviceAddr: number,
    regAddr: number,
    regCount: number,
    actionName: string
  ): Promise<Uint8Array | null> {
    // Function 0x04: read input registers. RTU address and CRC are handled by the sender.
    const pdu: number[] = [
      0x04,
      (regAddr >> 8) & 0xFF,
      regAddr & 0xFF,
      (regCount >> 8) & 0xFF,
      regCount & 0xFF
    ];
    const response = await UartClient.executePdu(deviceAddr, new Uint8Array(pdu), actionName);
    return UartClient.isSuccessfulPdu(response, 0x04) ? response : null;
  }

  static async readHoldRegisters(
    deviceAddr: number,
    regAddr: number,
    regCount: number,
    actionName: string
  ): Promise<Uint8Array | null> {
    // Function 0x03: read holding registers. RTU address and CRC are handled by the sender.
    const pdu: number[] = [
      0x03,
      (regAddr >> 8) & 0xFF,
      regAddr & 0xFF,
      (regCount >> 8) & 0xFF,
      regCount & 0xFF
    ];
    const response = await UartClient.executePdu(deviceAddr, new Uint8Array(pdu), actionName);
    return UartClient.isSuccessfulPdu(response, 0x03) ? response : null;
  }

  static async writeSingleRegister(
    deviceAddr: number,
    regAddr: number,
    regValue: number,
    actionName: string
  ): Promise<boolean> {
    // Function 0x06: write a single holding register.
    const pdu: number[] = [
      0x06,
      (regAddr >> 8) & 0xFF,
      regAddr & 0xFF,
      (regValue >> 8) & 0xFF,
      regValue & 0xFF
    ];
    const response = await UartClient.executePdu(deviceAddr, new Uint8Array(pdu), actionName);
    if (!UartClient.isSuccessfulPdu(response, 0x06) || !response || response.length < 5) {
      return false;
    }
    return response[1] === ((regAddr >> 8) & 0xFF) &&
      response[2] === (regAddr & 0xFF) &&
      response[3] === ((regValue >> 8) & 0xFF) &&
      response[4] === (regValue & 0xFF);
  }

  static async writeMultiRegister(
    deviceAddr: number,
    regAddr: number,
    regValues: number[],
    actionName: string
  ): Promise<boolean> {
    // Function 0x10: write multiple holding registers.
    if (regValues.length === 0) {
      hilog.error(DOMAIN, TAG, '%{public}s: empty register values', actionName);
      return false;
    }

    const regCount = regValues.length;
    const byteCount = regCount * 2;
    const pdu: number[] = [
      0x10,
      (regAddr >> 8) & 0xFF,
      regAddr & 0xFF,
      (regCount >> 8) & 0xFF,
      regCount & 0xFF,
      byteCount
    ];

    for (const value of regValues) {
      if (value < 0 || value > 0xFFFF || Math.floor(value) !== value) {
        hilog.error(DOMAIN, TAG, '%{public}s: invalid register value %{public}d', actionName, value);
        return false;
      }
      pdu.push((value >> 8) & 0xFF);
      pdu.push(value & 0xFF);
    }

    const response = await UartClient.executePdu(deviceAddr, new Uint8Array(pdu), actionName);
    if (!response || response.length < 5) {
      return false;
    }

    return response[0] === 0x10 &&
      response[1] === ((regAddr >> 8) & 0xFF) &&
      response[2] === (regAddr & 0xFF) &&
      response[3] === ((regCount >> 8) & 0xFF) &&
      response[4] === (regCount & 0xFF);
  }

  static startMeasurement(): boolean {
    hilog.info(DOMAIN, TAG, 'RS485: 启动测量');
    return UartClient.writeSingleRegisterSync(0x01, 0x0110, 0x0000, '启动测量');
  }

  static startCalibration(): boolean {
    hilog.info(DOMAIN, TAG, 'RS485: 启动校准');
    return UartClient.writeSingleRegisterSync(0x01, 0x0110, 0x0001, '启动校准');
  }

  static stopMeasurement(): boolean {
    hilog.info(DOMAIN, TAG, 'RS485: 停止测量');
    return UartClient.writeSingleRegisterSync(0x01, 0x0110, 0x0002, '停止测量');
  }

  static startCleaning(): boolean {
    hilog.info(DOMAIN, TAG, 'RS485: 启动清洗');
    return UartClient.writeSingleRegisterSync(0x01, 0x0110, 0x0007, '启动清洗');
  }

  static sendTestCommand(actionName: string): void {
    if (!UartClient.isOpen() && !UartClient.open()) {
      return;
    }

    const payload = `[${actionName}] PING\r\n`;
    const data = new Uint8Array(payload.length);
    for (let i = 0; i < payload.length; i++) {
      data[i] = payload.charCodeAt(i) & 0xff;
    }
    const sent = UartClient.writeRaw(data);
    hilog.info(DOMAIN, TAG, 'RS485 tx bytes=%{public}d, port=%{public}s', sent, UartClient.portPath);

    const recv = UartClient.readRaw();
    if (recv && recv.length > 0) {
      hilog.info(DOMAIN, TAG, 'RS485 rx: %{public}s', UartClient.bytesToHex(recv));
    } else {
      hilog.info(DOMAIN, TAG, 'RS485 no response');
    }
  }

  private static writeSingleRegisterSync(
    deviceAddr: number,
    regAddr: number,
    regValue: number,
    actionName: string
  ): boolean {
    const pdu: number[] = [
      0x06,
      (regAddr >> 8) & 0xFF,
      regAddr & 0xFF,
      (regValue >> 8) & 0xFF,
      regValue & 0xFF
    ];
    const response = UartClient.sendModbusRequestAndReadSync(
      deviceAddr,
      pdu,
      actionName,
      UartClient.getWriteResponseFrameLength()
    );
    return UartClient.isSuccessfulPdu(response, 0x06);
  }

  /**
   * 发送纯 Modbus PDU，并返回去除设备地址和 CRC 的纯响应 PDU。
   * 合法 Modbus 异常响应会原样返回，由调用方决定业务失败或网关透传。
   */
  static async executePdu(
    deviceAddr: number,
    requestPdu: Uint8Array,
    actionName: string
  ): Promise<Uint8Array | null> {
    return UartClient.requestQueue.run(async (): Promise<Uint8Array | null> => {
      const pdu: number[] = [];
      for (let index = 0; index < requestPdu.length; index++) {
        pdu.push(requestPdu[index]);
      }
      return UartClient.sendModbusRequestAndReadSync(
        deviceAddr,
        pdu,
        actionName,
        UartClient.expectedResponseFrameLength(requestPdu)
      );
    });
  }

  private static sendModbusRequestAndReadSync(
    deviceAddr: number,
    pdu: number[],
    actionName: string,
    expectedResponseLength: number = UartClient.MIN_RESPONSE_FRAME_LENGTH
  ): Uint8Array | null {
    if (!UartClient.isOpen() && !UartClient.open()) {
      hilog.error(DOMAIN, TAG, '%{public}s: failed to open serial port', actionName);
      UartClient.registerRequestFailure(actionName, 'failed to open serial port');
      return null;
    }

    // RTU 完整帧 = 设备地址 + PDU + CRC16，CRC 发送时低字节在前。
    const frame: number[] = [deviceAddr, ...pdu];
    const crc = UartClient.calcCRC16(frame);
    frame.push(crc & 0xFF);
    frame.push((crc >> 8) & 0xFF);

    const sendData = new Uint8Array(frame);
    hilog.info(DOMAIN, TAG, '%{public}s: RS485 tx [%{public}s]', actionName, UartClient.bytesToHex(sendData));

    const written = UartClient.writeRaw(sendData);
    if (written <= 0) {
      hilog.error(DOMAIN, TAG, '%{public}s: RS485 write failed', actionName);
      UartClient.registerRequestFailure(actionName, 'RS485 write failed');
      return null;
    }

    const response = UartClient.readResponseFrame(expectedResponseLength, actionName);
    if (!response || response.length < UartClient.MIN_RESPONSE_FRAME_LENGTH) {
      hilog.warn(DOMAIN, TAG, '%{public}s: RS485 no valid response', actionName);
      UartClient.registerRequestFailure(actionName, 'RS485 no valid response');
      return null;
    }
    hilog.info(DOMAIN, TAG, '%{public}s: RS485 rx [%{public}s]', actionName, UartClient.bytesToHex(response));

    if (!UartClient.isExceptionResponseFrame(response) && response.length < expectedResponseLength) {
      hilog.warn(
        DOMAIN,
        TAG,
        '%{public}s: incomplete RS485 response expected=%{public}d actual=%{public}d',
        actionName,
        expectedResponseLength,
        response.length
      );
      UartClient.registerRequestFailure(actionName, 'incomplete RS485 response');
      return null;
    }

    if (!UartClient.validateTransportResponseFrame(response, deviceAddr, actionName)) {
      return null;
    }

    if (UartClient.isExceptionResponseFrame(response)) {
      UartClient.logModbusException(response, actionName);
    }

    UartClient.registerSuccessfulResponse();
    // 向上层返回纯 PDU；异常 PDU 也保留，供网关原样返回。
    return response.slice(1, response.length - 2);
  }

  private static readResponseFrame(expectedLength: number, actionName: string): Uint8Array | null {
    const targetLength = Math.min(
      UartClient.READ_SIZE,
      Math.max(expectedLength, UartClient.MIN_RESPONSE_FRAME_LENGTH)
    );
    const chunks: Uint8Array[] = [];
    let totalLength = 0;

    for (let i = 0; i < UartClient.RESPONSE_READ_RETRY_COUNT && totalLength < targetLength; i++) {
      const readLength = targetLength - totalLength;
      const chunk = UartClient.readRaw(readLength, UartClient.MODBUS_RESPONSE_TIMEOUT_MS);
      if (!chunk) {
        break;
      }

      chunks.push(chunk);
      totalLength += chunk.length;
      if (totalLength >= UartClient.MIN_RESPONSE_FRAME_LENGTH) {
        const currentFrame = UartClient.concatChunks(chunks, totalLength);
        if (UartClient.isExceptionResponseFrame(currentFrame)) {
          return currentFrame;
        }
      }
    }

    if (totalLength <= 0) {
      return null;
    }
    const response = UartClient.concatChunks(chunks, totalLength);
    if (response.length < targetLength) {
      hilog.warn(
        DOMAIN,
        TAG,
        '%{public}s: RS485 response shorter than expected expected=%{public}d actual=%{public}d',
        actionName,
        targetLength,
        response.length
      );
    }
    return response;
  }

  private static concatChunks(chunks: Uint8Array[], totalLength: number): Uint8Array {
    const result = new Uint8Array(totalLength);
    let offset = 0;
    for (const chunk of chunks) {
      for (let i = 0; i < chunk.length; i++) {
        result[offset + i] = chunk[i];
      }
      offset += chunk.length;
    }
    return result;
  }

  private static writeRaw(data: Uint8Array): number {
    try {
      const written = serial.write(data.buffer) as number;
      if (written < 0) {
        const reason = UartClient.readNativeLastError();
        UartClient.setLastError(reason.length > 0 ? `write failed: ${reason}` : 'write failed');
      }
      return written;
    } catch (err) {
      const reason = UartClient.formatError(err as Error);
      UartClient.setLastError(`write exception: ${reason}`);
      hilog.error(DOMAIN, TAG, 'write exception: %{public}s', reason);
      return -1;
    }
  }

  private static readRaw(maxLen: number = UartClient.READ_SIZE, timeoutMs: number = 1000): Uint8Array | null {
    try {
      const buf: ArrayBuffer = serial.read(maxLen, timeoutMs) as ArrayBuffer;
      if (buf.byteLength <= 0) {
        return null;
      }
      return new Uint8Array(buf);
    } catch (err) {
      const reason = UartClient.formatError(err as Error);
      UartClient.setLastError(`read exception: ${reason}`);
      hilog.warn(DOMAIN, TAG, 'read exception: %{public}s', reason);
      return null;
    }
  }

  private static validateTransportResponseFrame(response: Uint8Array, deviceAddr: number, actionName: string): boolean {
    // 基础校验：设备地址、CRC。Modbus 异常响应说明链路可达，不计入通信失败。
    if (response[0] !== deviceAddr) {
      hilog.error(DOMAIN, TAG, '%{public}s: device address mismatch %{public}d', actionName, response[0]);
      UartClient.registerRequestFailure(actionName, 'device address mismatch');
      return false;
    }

    const dataWithoutCrc: number[] = [];
    for (let i = 0; i < response.length - 2; i++) {
      dataWithoutCrc.push(response[i]);
    }
    const expectedCrc = UartClient.calcCRC16(dataWithoutCrc);
    const actualCrc = response[response.length - 2] | (response[response.length - 1] << 8);
    if (expectedCrc !== actualCrc) {
      hilog.error(DOMAIN, TAG, '%{public}s: CRC mismatch expected=%{public}d actual=%{public}d',
        actionName, expectedCrc, actualCrc);
      UartClient.registerRequestFailure(actionName, 'CRC mismatch');
      return false;
    }

    return true;
  }

  private static logModbusException(response: Uint8Array, actionName: string): void {
    const funcCode = response[1];
    const exceptionCode = response.length > 2 ? response[2] : -1;
    hilog.error(DOMAIN, TAG, '%{public}s: Modbus exception func=%{public}d code=%{public}d',
      actionName, funcCode, exceptionCode);
  }

  private static registerSuccessfulResponse(): void {
    UartClient.failureBreaker.recordSuccess();
  }

  private static registerRequestFailure(actionName: string, reason: string): void {
    const shouldClose = UartClient.failureBreaker.recordFailure();
    UartClient.setLastError(reason);
    if (!shouldClose) {
      return;
    }

    hilog.warn(
      DOMAIN,
      TAG,
      '%{public}s: UART failure threshold reached, closing serial port. reason=%{public}s',
      actionName,
      reason
    );
    UartClient.close();
  }

  private static isExceptionResponseFrame(response: Uint8Array): boolean {
    return response.length >= UartClient.MIN_RESPONSE_FRAME_LENGTH && (response[1] & 0x80) !== 0;
  }

  private static isExceptionResponsePdu(response: Uint8Array): boolean {
    return response.length >= 2 && (response[0] & 0x80) !== 0;
  }

  private static isSuccessfulPdu(response: Uint8Array | null, expectedFunction: number): boolean {
    return response !== null && response.length >= 2 &&
      !UartClient.isExceptionResponsePdu(response) &&
      response[0] === expectedFunction;
  }

  private static expectedResponseFrameLength(requestPdu: Uint8Array): number {
    if (requestPdu.length === 0) {
      return UartClient.MIN_RESPONSE_FRAME_LENGTH;
    }
    const functionCode = requestPdu[0];
    if ((functionCode === 0x03 || functionCode === 0x04) && requestPdu.length === 5) {
      const count = (requestPdu[3] << 8) | requestPdu[4];
      return UartClient.getReadResponseFrameLength(count);
    }
    if (functionCode === 0x06 || functionCode === 0x10) {
      return UartClient.getWriteResponseFrameLength();
    }
    return UartClient.MIN_RESPONSE_FRAME_LENGTH;
  }

  private static getReadResponseFrameLength(regCount: number): number {
    return 1 + 1 + 1 + regCount * 2 + 2;
  }

  private static getWriteResponseFrameLength(): number {
    return 1 + 1 + 2 + 2 + 2;
  }

  private static calcCRC16(data: number[]): number {
    // Modbus RTU 标准 CRC16，多项式 0xA001。
    let crc = 0xFFFF;
    for (let i = 0; i < data.length; i++) {
      crc ^= data[i];
      for (let j = 0; j < 8; j++) {
        if ((crc & 0x0001) !== 0) {
          crc = (crc >> 1) ^ 0xA001;
        } else {
          crc >>= 1;
        }
      }
    }
    return crc;
  }

  private static bytesToHex(data: Uint8Array): string {
    let hexStr = '';
    for (let i = 0; i < data.length; i++) {
      hexStr += data[i].toString(16).padStart(2, '0').toUpperCase() + ' ';
    }
    return hexStr;
  }
}
