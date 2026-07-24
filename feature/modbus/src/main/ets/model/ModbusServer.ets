// lhipstudio/modbus/src/main/ets/model/ModbusServer.ets

import { socket } from '@kit.NetworkKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { util } from '@kit.ArkTS';
import { ModbusRTUHandler } from './ModbusRTU';
import { ModbusTCPHandler } from './ModbusTCP';
import { DataStore } from './DataStore';
import { CommLogEntry } from './Types';
import { ProtocolTableRegistry } from './ProtocolTable';
import { openUart, writeUart, readUartBinary, closeUart, setSerialConfig, flushUart, getUartStatus } from 'libentry.so';
import { Logger } from 'logger';

// ==================== 配置接口定义 ====================
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

// ==================== 串口配置参数接口（用于 setSerialConfig 调用） ====================
interface SerialConfigParams {
  baudRate: number;
  dataBits: number;
  stopBits: number;
  parity: number;
}

// ==================== 连接信息接口 ====================
interface ConnectionInfo {
  client: socket.TCPSocketConnection;
  remoteAddress: string;
  remotePort: number;
}

interface RemoteAddressInfo {
  address: string;
  port: number;
  family: number;
}

// ==================== ModbusServer 类 ====================
export class ModbusServer {
  private rtuHandler: ModbusRTUHandler;
  private tcpHandler: ModbusTCPHandler;
  private dataStore: DataStore;
  private tcpServer: socket.TCPSocketServer | null = null;
  private tcpConnections: Map<string, ConnectionInfo> = new Map();
  private serialOpened: boolean = false;
  private serialReading: boolean = false;
  private serialReadTimer: number = -1;
  private receiveBuffer: Uint8Array = new Uint8Array(0);
  private lastReceiveTime: number = 0;
  private logCallback: ((log: CommLogEntry) => void) | null = null;
  private pendingLogs: CommLogEntry[] = [];
  private logFlushTimer: number = -1;
  private currentProtocol: string = 'LS4.0';

  // RTU帧间隔超时（毫秒）
  private readonly FRAME_TIMEOUT_MS: number = 50;

  // ==================== 可配置的 TCP 参数 ====================
  private tcpConfig: TcpConfig = {
    address: '0.0.0.0',
    port: 5020
  };

  // ==================== 可配置的串口参数 ====================
  private serialConfig: SerialConfig = {
    path: '/dev/ttyS0',
    baudRate: 9600,
    dataBits: 8,
    stopBits: 1,
    parity: 0
  };

  // ==================== 运行状态 ====================
  private isTcpServerRunning: boolean = false;

  constructor() {
    this.rtuHandler = new ModbusRTUHandler();
    this.tcpHandler = new ModbusTCPHandler();
    this.dataStore = DataStore.getInstance();

    // 设置日志回调链
    this.rtuHandler.setLogCallback((log: CommLogEntry) => {
      this.queueLog(log);
    });

    this.tcpHandler.setLogCallback((log: CommLogEntry) => {
      this.queueLog(log);
    });
    this.tcpHandler.setSendCallback((response: Uint8Array) => {
      this.sendToAllTcpClients(response);
    });

    this.startLogFlushTimer();
    // 默认使用 LS4.0 协议表，保证 DataStore 与 Handler 状态一致
    this.setProtocolTable('LS4.0');
  }

  // ==================== 日志方法 ====================

  private startLogFlushTimer(): void {
    this.logFlushTimer = setInterval(() => {
      this.flushPendingLogs();
    }, 100);
  }

  private queueLog(log: CommLogEntry): void {
    this.pendingLogs.push(log);
    if (this.pendingLogs.length >= 20) {
      this.flushPendingLogs();
    }
  }

  private flushPendingLogs(): void {
    if (this.pendingLogs.length === 0) return;
    if (!this.logCallback) return;

    const logs: CommLogEntry[] = this.pendingLogs.slice();
    this.pendingLogs = [];

    for (const log of logs) {
      try {
        this.logCallback(log);
      } catch (error) {
        Logger.error('Modbus Log callback error: %s', JSON.stringify(error));
      }
    }
  }

  setLogCallback(callback: (log: CommLogEntry) => void): void {
    this.logCallback = callback;
  }

  // ==================== 协议表切换方法 ====================

  /**
   * 切换当前使用的 Modbus 协议表。
   * 未知协议会回退到 LS4.0，并记录警告日志。
   */
  setProtocolTable(name: string): void {
    const table = ProtocolTableRegistry.get(name);
    if (table.name === 'LS4.0' && name !== 'LS4.0') {
      Logger.warn('ModbusServer', 'Protocol table "%s" not registered, fallback to LS4.0', name);
    }
    this.currentProtocol = table.name;
    this.dataStore.setProtocolTable(table);
    this.rtuHandler.setProtocolTable(table);
    this.tcpHandler.setProtocolTable(table);
    Logger.info('ModbusServer', 'Protocol table switched to %s', this.currentProtocol);
  }

  /**
   * 获取当前使用的协议表名称。
   */
  getProtocolTable(): string {
    return this.currentProtocol;
  }

  // ==================== 配置设置方法 ====================

  /**
   * 设置 TCP 配置
   * @param config TCP 配置 { address, port }
   */
  setTcpConfig(config: TcpConfig): void {
    this.tcpConfig.address = config.address || '0.0.0.0';
    this.tcpConfig.port = config.port || 5020;
    Logger.info('ModbusServer TCP config updated: %s:%d', this.tcpConfig.address, this.tcpConfig.port);
  }

  /**
   * 获取当前 TCP 配置（返回新对象，防止外部修改内部状态）
   */
  getTcpConfig(): TcpConfig {
    const result: TcpConfig = {
      address: this.tcpConfig.address,
      port: this.tcpConfig.port
    };
    return result;
  }

  /**
   * 设置串口配置
   * @param config 串口配置 { path, baudRate, dataBits, stopBits, parity }
   */
  setSerialConfig(config: SerialConfig): void {
    this.serialConfig.path = config.path || '/dev/ttyS0';
    this.serialConfig.baudRate = config.baudRate || 9600;
    this.serialConfig.dataBits = config.dataBits || 8;
    this.serialConfig.stopBits = config.stopBits || 1;
    this.serialConfig.parity = config.parity ?? 0;
    Logger.info('ModbusServer Serial config updated: %s %d-%d-%d parity=%d',
      this.serialConfig.path, this.serialConfig.baudRate,
      this.serialConfig.dataBits, this.serialConfig.stopBits,
      this.serialConfig.parity);
  }

  /**
   * 获取当前串口配置（返回新对象，防止外部修改内部状态）
   */
  getSerialConfig(): SerialConfig {
    const result: SerialConfig = {
      path: this.serialConfig.path,
      baudRate: this.serialConfig.baudRate,
      dataBits: this.serialConfig.dataBits,
      stopBits: this.serialConfig.stopBits,
      parity: this.serialConfig.parity
    };
    return result;
  }

  /**
   * 应用 TCP 配置并重启服务器
   */
  async applyTcpConfig(): Promise<boolean> {
    // 如果 TCP 服务器正在运行，先关闭
    if (this.tcpServer !== null) {
      try {
        await this.tcpServer.close();
        this.tcpServer = null;
        this.isTcpServerRunning = false;
        Logger.info('ModbusServer TCP server closed for reconfiguration');
      } catch (e) {
        Logger.error('ModbusServer Failed to close TCP server: %s', JSON.stringify(e));
      }
    }

    // 清空连接
    this.tcpConnections.clear();

    // 使用新配置启动 TCP 服务器
    const result: boolean = await this.initTCPServer(this.tcpConfig.port);
    if (result) {
      this.isTcpServerRunning = true;
      Logger.info('ModbusServer TCP server restarted with config: %s:%d',
        this.tcpConfig.address, this.tcpConfig.port);
    } else {
      Logger.error('ModbusServer Failed to restart TCP server');
    }
    return result;
  }

  /**
   * 应用串口配置（关闭旧连接，打开新配置）
   */
  applySerialConfig(): boolean {
    // 如果串口已打开，先关闭
    if (this.serialOpened) {
      this.closeSerialPortInternal();
    }

    // 使用新配置打开串口
    const result: boolean = this.openSerialPortInternal(this.serialConfig.path);
    if (result) {
      Logger.info('ModbusServer Serial port reopened with config: %s %d-%d-%d parity=%d',
        this.serialConfig.path, this.serialConfig.baudRate,
        this.serialConfig.dataBits, this.serialConfig.stopBits,
        this.serialConfig.parity);
    } else {
      Logger.error('ModbusServer Failed to reopen serial port');
    }
    return result;
  }

  // ==================== TCP 服务器方法 ====================

  sendToAllTcpClients(data: Uint8Array): number {
    if (this.tcpConnections.size === 0) {
      Logger.warn('ModbusTCP No clients connected');
      return 0;
    }

    let successCount: number = 0;
    this.tcpConnections.forEach((conn: ConnectionInfo, key: string) => {
      try {
        conn.client.send({
          data: data.buffer,
          encoding: 'binary'
        }).then(() => {
          successCount++;
        }).catch((err: Error) => {
          Logger.error('ModbusTCP Send to %s failed: %s', key, err.message);
        });
      } catch (error) {
        Logger.error('ModbusTCP Send error to %s: %s', key, JSON.stringify(error));
      }
    });

    return successCount;
  }

  sendToTcpClient(clientKey: string, data: Uint8Array): boolean {
    const conn: ConnectionInfo | undefined = this.tcpConnections.get(clientKey);
    if (!conn) {
      Logger.warn('ModbusTCP Client %s not found', clientKey);
      return false;
    }

    try {
      conn.client.send({
        data: data.buffer,
        encoding: 'binary'
      });
      return true;
    } catch (error) {
      Logger.error('ModbusTCP Send to %s failed: %s', clientKey, JSON.stringify(error));
      return false;
    }
  }

  getTcpClientList(): string[] {
    const keys: string[] = [];
    this.tcpConnections.forEach((value: ConnectionInfo, key: string) => {
      keys.push(key);
    });
    return keys;
  }

  getTCPClientCount(): number {
    return this.tcpConnections.size;
  }

  async initTCPServer(port: number): Promise<boolean> {
    try {
      this.tcpServer = socket.constructTCPSocketServerInstance();

      const netAddress: socket.NetAddress = {
        address: this.tcpConfig.address,
        port: port
      };

      Logger.info('ModbusTCP Attempting to listen on %s:%d', this.tcpConfig.address, port);

      this.tcpServer.on('error', (err: Error) => {
        Logger.error('ModbusTCP Server error: %s', err.message);
        this.queueLog({
          id: Date.now(),
          timestamp: new Date().toLocaleTimeString(),
          direction: 'SEND',
          protocol: 'TCP',
          data: 'ERROR',
          description: `TCP服务器错误: ${err.message}`
        });
      });

      await this.tcpServer.listen(netAddress);
      Logger.info('ModbusTCP Server listening successfully on %s:%d', this.tcpConfig.address, port);
      this.isTcpServerRunning = true;
      this.queueLog({
        id: Date.now(),
        timestamp: new Date().toLocaleTimeString(),
        direction: 'SEND',
        protocol: 'TCP',
        data: 'INFO',
        description: `Modbus TCP服务器已启动，监听 ${this.tcpConfig.address}:${port}`
      });

      this.tcpServer.on('connect', (client: socket.TCPSocketConnection) => {
        Logger.info('ModbusTCP New client connected');
        this.handleTCPConnection(client);
      });

      return true;
    } catch (error) {
      Logger.error('ModbusTCP Failed to start server: %s', JSON.stringify(error));
      this.isTcpServerRunning = false;
      this.queueLog({
        id: Date.now(),
        timestamp: new Date().toLocaleTimeString(),
        direction: 'SEND',
        protocol: 'TCP',
        data: 'ERROR',
        description: `启动TCP服务器失败: ${JSON.stringify(error)}`
      });
      return false;
    }
  }

  private async handleTCPConnection(client: socket.TCPSocketConnection): Promise<void> {
    try {
      const remoteInfo: RemoteAddressInfo = await client.getRemoteAddress() as RemoteAddressInfo;
      let remoteAddress: string = '';
      let remotePort: number = 0;

      if (remoteInfo) {
        remoteAddress = remoteInfo.address || '';
        remotePort = remoteInfo.port || 0;
      }

      const key: string = `${remoteAddress}:${remotePort}`;

      const connectionInfo: ConnectionInfo = {
        client: client,
        remoteAddress: remoteAddress,
        remotePort: remotePort
      };
      this.tcpConnections.set(key, connectionInfo);
      Logger.info('ModbusTCP Client connected: %s', key);

      this.queueLog({
        id: Date.now(),
        timestamp: new Date().toLocaleTimeString(),
        direction: 'RECEIVE',
        protocol: 'TCP',
        data: 'CONNECT',
        description: `TCP客户端已连接: ${remoteAddress}:${remotePort}`
      });

      client.on('message', (data: socket.SocketMessageInfo) => {
        this.handleTCPData(client, data);
      });

      client.on('close', () => {
        Logger.info('ModbusTCP Client disconnected: %s', key);
        this.queueLog({
          id: Date.now(),
          timestamp: new Date().toLocaleTimeString(),
          direction: 'SEND',
          protocol: 'TCP',
          data: 'DISCONNECT',
          description: `TCP客户端已断开: ${remoteAddress}:${remotePort}`
        });
        this.tcpConnections.delete(key);
      });
    } catch (error) {
      Logger.error('ModbusTCP Error handling connection: %s', JSON.stringify(error));
    }
  }

  private bytesToHex(bytes: Uint8Array): string {
    let hex: string = '';
    for (let i: number = 0; i < bytes.length; i++) {
      hex += bytes[i].toString(16).padStart(2, '0').toUpperCase();
      if (i < bytes.length - 1) hex += ' ';
    }
    return hex;
  }

  private async handleTCPData(client: socket.TCPSocketConnection, data: socket.SocketMessageInfo): Promise<void> {
    try {
      const buffer: Uint8Array = new Uint8Array(data.message);
      const hexStr: string = this.bytesToHex(buffer);
      Logger.info('ModbusTCP Received %d bytes: %s', buffer.length, hexStr);
      this.queueLog({
        id: Date.now(),
        timestamp: new Date().toLocaleTimeString(),
        direction: 'RECEIVE',
        protocol: 'TCP',
        data: hexStr,
        description: `TCP原始数据 ${buffer.length}字节`
      });

      const parseResult = this.tcpHandler.parseRequest(buffer);
      const request = parseResult.request;
      const transactionId = parseResult.transactionId;
      const protocolId = parseResult.protocolId;
      const unitId = parseResult.unitId;

      if (request !== null) {
        await this.tcpHandler.processRequest(request, transactionId, protocolId, unitId);
      } else {
        Logger.warn('ModbusTCP Failed to parse request, hex: %s', hexStr);
        const exceptionPdu: Uint8Array = new Uint8Array(2);
        exceptionPdu[0] = 0x83;
        exceptionPdu[1] = 0x02;
        const exceptionResponse: Uint8Array = this.buildTCPResponse(transactionId, protocolId, unitId, exceptionPdu);
        this.sendToAllTcpClients(exceptionResponse);
      }
    } catch (error) {
      Logger.error('ModbusTCP Error handling data: %s', JSON.stringify(error));
    }
  }

  private buildTCPResponse(transactionId: number, protocolId: number, unitId: number, pdu: Uint8Array): Uint8Array {
    const response: Uint8Array = new Uint8Array(7 + pdu.length);
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

  // ==================== 串口内部方法 ====================

  /**
   * 打开串口（内部使用当前配置）
   */
  private openSerialPortInternal(devicePath: string): boolean {
    try {
      Logger.info('ModbusRTU Opening serial port: %s', devicePath);

      const result: boolean = openUart(devicePath);

      if (!result) {
        Logger.error('ModbusRTU Failed to open serial port: %s', devicePath);
        this.queueLog({
          id: Date.now(),
          timestamp: new Date().toLocaleTimeString(),
          direction: 'SEND',
          protocol: 'RTU',
          data: 'ERROR',
          description: `打开串口失败: ${devicePath}`
        });
        return false;
      }

      const configResult: boolean = this.configureSerialPortInternal();
      if (!configResult) {
        Logger.warn('ModbusRTU Failed to configure serial port, using defaults');
      }

      this.serialOpened = true;
      Logger.info('ModbusRTU Serial port opened successfully');

      let parityLabel: string = 'N';
      if (this.serialConfig.parity === 1) {
        parityLabel = 'O';
      } else if (this.serialConfig.parity === 2) {
        parityLabel = 'E';
      }
      this.queueLog({
        id: Date.now(),
        timestamp: new Date().toLocaleTimeString(),
        direction: 'SEND',
        protocol: 'RTU',
        data: 'INFO',
        description: `串口已打开: ${devicePath}, ${this.serialConfig.baudRate}-${this.serialConfig.dataBits}-${parityLabel}${this.serialConfig.stopBits}`
      });

      this.startSerialReadingInternal();

      return true;
    } catch (error) {
      Logger.error('ModbusRTU Failed to open serial port: %s', JSON.stringify(error));
      return false;
    }
  }

  /**
   * 关闭串口（内部）
   */
  private closeSerialPortInternal(): void {
    this.serialReading = false;

    if (this.serialReadTimer !== -1) {
      clearInterval(this.serialReadTimer);
      this.serialReadTimer = -1;
    }

    if (this.serialOpened) {
      try {
        closeUart();
        Logger.info('ModbusRTU Serial port closed');
      } catch (e) {
        Logger.error('ModbusRTU Failed to close serial port: %s', JSON.stringify(e));
      }
      this.serialOpened = false;
    }

    this.receiveBuffer = new Uint8Array(0);
  }

  /**
   * 配置串口参数（内部使用当前配置）
   */
  private configureSerialPortInternal(): boolean {
    try {
      const config: SerialConfigParams = {
        baudRate: this.serialConfig.baudRate,
        dataBits: this.serialConfig.dataBits,
        stopBits: this.serialConfig.stopBits,
        parity: this.serialConfig.parity
      };
      return setSerialConfig(config);
    } catch (error) {
      Logger.error('ModbusRTU Failed to configure serial port: %s', JSON.stringify(error));
      return false;
    }
  }

  // ==================== 串口对外方法 ====================

  /**
   * 初始化串口（对外接口，兼容原有调用）
   */
  async initSerialPort(devicePath: string): Promise<boolean> {
    // 更新配置中的路径
    this.serialConfig.path = devicePath;
    return this.openSerialPortInternal(devicePath);
  }

  /**
   * 获取串口状态
   */
  isSerialOpened(): boolean {
    return this.serialOpened;
  }

  /**
   * 获取串口状态详情
   */
  getSerialStatus(): boolean {
    try {
      const status = getUartStatus();
      return status.isOpened;
    } catch (error) {
      return false;
    }
  }

  /**
   * 刷新串口缓冲区
   */
  flushSerialBuffer(): boolean {
    try {
      return flushUart();
    } catch (error) {
      Logger.error('ModbusRTU Flush error: %s', JSON.stringify(error));
      return false;
    }
  }

  /**
   * 发送串口数据
   */
  sendSerialData(data: Uint8Array): boolean {
    if (!this.serialOpened) {
      Logger.error('ModbusRTU Serial port not opened');
      return false;
    }

    try {
      const result: boolean = writeUart(data);
      return result;
    } catch (error) {
      Logger.error('ModbusRTU Send error: %s', JSON.stringify(error));
      return false;
    }
  }

  // ==================== 串口读取循环 ====================

  private startSerialReadingInternal(): void {
    this.serialReading = true;
    this.lastReceiveTime = Date.now();

    this.serialReadTimer = setInterval(() => {
      if (this.serialReading && this.serialOpened) {
        this.readSerialDataInternal();
        this.checkFrameTimeoutInternal();
      }
    }, 30);
  }

  private checkFrameTimeoutInternal(): void {
    const now: number = Date.now();
    if (this.receiveBuffer.length > 0 && (now - this.lastReceiveTime) >= this.FRAME_TIMEOUT_MS) {
      Logger.info('ModbusRTU Frame timeout, processing %d bytes', this.receiveBuffer.length);
      this.processCompleteFrameInternal();
    }
  }

  private async readSerialDataInternal(): Promise<void> {
    try {
      const arrayBuffer: ArrayBuffer = readUartBinary();
      if (arrayBuffer && arrayBuffer.byteLength > 0) {
        const dataBytes: Uint8Array = new Uint8Array(arrayBuffer);
        this.receiveBuffer = this.appendBufferInternal(this.receiveBuffer, dataBytes);
        Logger.info('ModbusRTU Read %d bytes from serial', this.receiveBuffer.length);
        this.lastReceiveTime = Date.now();
        await this.tryProcessFramesInternal();
      }
    } catch (error) {
      Logger.error('ModbusRTU Read error: %s', JSON.stringify(error));
    }
  }

  private appendBufferInternal(buffer: Uint8Array, newData: Uint8Array): Uint8Array {
    const newBuffer: Uint8Array = new Uint8Array(buffer.length + newData.length);
    newBuffer.set(buffer);
    newBuffer.set(newData, buffer.length);
    return newBuffer;
  }

  private async tryProcessFramesInternal(): Promise<void> {
    let processed: boolean = true;
    let maxLoops: number = 10;

    while (processed && maxLoops-- > 0) {
      processed = false;

      for (let i: number = 0; i <= this.receiveBuffer.length - 8; i++) {
        const candidate: Uint8Array = this.receiveBuffer.slice(i);
        const request = await this.rtuHandler.parseRequest(candidate);

        if (request !== null) {
          const frameLength: number = this.getFrameLengthInternal(candidate);
          if (frameLength > 0 && frameLength <= candidate.length) {
            const completeFrame: Uint8Array = candidate.slice(0, frameLength);
            Logger.info('ModbusServer Found complete frame (%d bytes)', frameLength);

            const response = await this.rtuHandler.processRequest(request);

            if (response !== null && response.length > 0 && this.serialOpened) {
              Logger.info('ModbusServer Sending response');
              const writeResult: boolean = writeUart(response);
              if (!writeResult) {
                Logger.error('ModbusRTU Failed to write response');
              }
            }

            this.receiveBuffer = this.receiveBuffer.slice(i + frameLength);
            processed = true;
            break;
          }
        }
      }
    }

    if (this.receiveBuffer.length > 512) {
      Logger.warn('ModbusRTU Buffer too large (%d bytes), clearing', this.receiveBuffer.length);
      this.receiveBuffer = new Uint8Array(0);
    }
  }

  private async processCompleteFrameInternal(): Promise<void> {
    if (this.receiveBuffer.length === 0) return;

    const request = await this.rtuHandler.parseRequest(this.receiveBuffer);

    if (request !== null) {
      const response = await this.rtuHandler.processRequest(request);

      if (response !== null && response.length > 0 && this.serialOpened) {
        Logger.info('ModbusRTU Sending response');
        const writeResult: boolean = writeUart(response);
        if (!writeResult) {
          Logger.error('ModbusRTU Failed to write response');
        } else {
          flushUart();
        }
      }
    } else {
      Logger.warn('ModbusRTU Failed to parse frame');
    }

    this.receiveBuffer = new Uint8Array(0);
  }

  private getFrameLengthInternal(buffer: Uint8Array): number {
    if (buffer.length < 8) return 0;

    const functionCode: number = buffer[1];
    let dataLength: number = 0;

    switch (functionCode) {
      case 0x01:
      case 0x02:
      case 0x03:
      case 0x04:
        dataLength = 8;
        break;
      case 0x05:
      case 0x06:
        dataLength = 8;
        break;
      case 0x0F:
      case 0x10:
        if (buffer.length >= 9) {
          const byteCount: number = buffer[6];
          dataLength = 7 + byteCount + 2;
        }
        break;
      default:
        dataLength = 8;
    }

    if (dataLength > 0 && dataLength <= buffer.length) {
      return dataLength;
    }
    return 0;
  }

  // ==================== 通用方法 ====================

  getDataStore(): DataStore {
    return this.dataStore;
  }

  getTCPConnectionCount(): number {
    return this.tcpConnections.size;
  }

  getTCPConnections(): string[] {
    const keys: string[] = [];
    this.tcpConnections.forEach((value: ConnectionInfo, key: string) => {
      keys.push(key);
    });
    return keys;
  }

  getTcpServerRunning(): boolean {
    return this.isTcpServerRunning;
  }

  // ==================== 关闭服务器 ====================

  async shutdown(): Promise<void> {
    Logger.info('Modbus Shutting down server...');

    if (this.logFlushTimer !== -1) {
      clearInterval(this.logFlushTimer);
      this.logFlushTimer = -1;
    }

    this.flushPendingLogs();

    // 关闭串口
    this.closeSerialPortInternal();

    // 关闭 TCP 服务器
    if (this.tcpServer !== null) {
      try {
        await this.tcpServer.close();
        Logger.info('ModbusTCP TCP server closed');
      } catch (e) {
        Logger.error('ModbusTCP Failed to close TCP server: %s', JSON.stringify(e));
      }
      this.tcpServer = null;
      this.isTcpServerRunning = false;
    }

    // 关闭所有 TCP 连接
    const connectionKeys: string[] = [];
    this.tcpConnections.forEach((value: ConnectionInfo, key: string) => {
      connectionKeys.push(key);
    });

    for (let i: number = 0; i < connectionKeys.length; i++) {
      const key: string = connectionKeys[i];
      const conn: ConnectionInfo | undefined = this.tcpConnections.get(key);
      if (conn !== undefined) {
        try {
          conn.client.close();
        } catch (e) {
          Logger.error('ModbusRTU Failed to close connection %s: %s', key, JSON.stringify(e));
        }
      }
    }
    this.tcpConnections.clear();

    this.receiveBuffer = new Uint8Array(0);

    Logger.info('Modbus Server shutdown complete');
  }
}