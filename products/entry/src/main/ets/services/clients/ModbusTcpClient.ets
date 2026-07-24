import { BusinessError } from '@kit.BasicServicesKit';
import { socket } from '@kit.NetworkKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { PromiseFifoQueue } from './PromiseFifoQueue';

const DOMAIN = 0x0003;
const TAG = 'ModbusTcpClient';

const DEFAULT_MCU_IP = '192.168.1.110';
const DEFAULT_MCU_PORT = 502;

// 只负责 Modbus TCP 通道：连接 socket、组 MBAP 头、发送 PDU、按事务号等待响应。
export class ModbusTcpClient {
  private static socket: socket.TCPSocket | null = null;
  private static connected: boolean = false;
  private static connectingPromise: Promise<boolean> | null = null;
  private static mcuIp: string = DEFAULT_MCU_IP;
  private static mcuPort: number = DEFAULT_MCU_PORT;

  // key 是 Transaction ID，value 是等待该响应的 Promise resolver。
  private static pendingResponseResolvers: Map<number, (data: Uint8Array | null) => void> = new Map();

  // 接收帧重组缓冲区：TCP 是流协议，一个 message 事件可能包含多个响应帧（粘包），
  // 也可能一帧被拆成多次到达（分片）。因此将每次收到的字节累积到 rxBuffer，
  // 再按 MBAP Length 逐帧切割分发。
  private static rxBuffer: number[] = [];

  // 页面轮询、业务命令和 Dashboard 网关请求共用同一 FIFO。
  private static readonly requestQueue: PromiseFifoQueue = new PromiseFifoQueue();

  static setConfig(ip: string, port: number): void {
    ModbusTcpClient.mcuIp = ip;
    ModbusTcpClient.mcuPort = port;
    hilog.info(DOMAIN, TAG, 'MCU config updated: %{public}s:%{public}d', ip, port);
  }

  static async connect(): Promise<boolean> {
    if (ModbusTcpClient.connected) {
      hilog.info(DOMAIN, TAG, 'Already connected');
      return true;
    }
    if (ModbusTcpClient.connectingPromise) {
      hilog.info(DOMAIN, TAG, 'TCP connection is in progress, waiting...');
      return ModbusTcpClient.connectingPromise;
    }

    // 并发 connect 复用同一个 Promise，避免短时间内重复建 socket。
    ModbusTcpClient.connectingPromise = ModbusTcpClient.connectInternal();
    const connected = await ModbusTcpClient.connectingPromise;
    ModbusTcpClient.connectingPromise = null;
    return connected;
  }

  static disconnect(): void {
    if (ModbusTcpClient.socket) {
      try {
        ModbusTcpClient.socket.close();
        hilog.info(DOMAIN, TAG, 'TCP socket closed');
      } catch (err) {
        hilog.warn(DOMAIN, TAG, 'Close exception: %{public}s', JSON.stringify(err));
      }
    }
    ModbusTcpClient.socket = null;
    ModbusTcpClient.connected = false;
    ModbusTcpClient.resolveAllPendingResponses();
    ModbusTcpClient.rxBuffer = [];
  }

  static isConnected(): boolean {
    return ModbusTcpClient.connected;
  }

  static async readInputRegisters(
    deviceAddr: number,
    regAddr: number,
    regCount: number,
    actionName: string
  ): Promise<Uint8Array | null> {
    // 功能码 0x04：读输入寄存器。这里只构造 PDU，MBAP 在发送器里统一补。
    const pdu: number[] = [
      0x04,
      (regAddr >> 8) & 0xFF,
      regAddr & 0xFF,
      (regCount >> 8) & 0xFF,
      regCount & 0xFF
    ];
    const response = await ModbusTcpClient.executePdu(deviceAddr, new Uint8Array(pdu), actionName);
    return ModbusTcpClient.isSuccessfulPdu(response, 0x04) ? response : null;
  }

  static async readHoldRegisters(
    deviceAddr: number,
    regAddr: number,
    regCount: number,
    actionName: string
  ): Promise<Uint8Array | null> {
    // 功能码 0x03：读保持寄存器。这里只构造 PDU，MBAP 在发送器里统一补。
    const pdu: number[] = [
      0x03,
      (regAddr >> 8) & 0xFF,
      regAddr & 0xFF,
      (regCount >> 8) & 0xFF,
      regCount & 0xFF
    ];
    const response = await ModbusTcpClient.executePdu(deviceAddr, new Uint8Array(pdu), actionName);
    return ModbusTcpClient.isSuccessfulPdu(response, 0x03) ? response : null;
  }

  static async writeSingleRegister(
    deviceAddr: number,
    regAddr: number,
    regValue: number,
    actionName: string
  ): Promise<boolean> {
    // 功能码 0x06：写单个保持寄存器。
    const pdu: number[] = [
      0x06,
      (regAddr >> 8) & 0xFF,
      regAddr & 0xFF,
      (regValue >> 8) & 0xFF,
      regValue & 0xFF
    ];
    const response = await ModbusTcpClient.executePdu(deviceAddr, new Uint8Array(pdu), actionName);
    if (!ModbusTcpClient.isSuccessfulPdu(response, 0x06) || !response || response.length < 5) {
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
    // 功能码 0x10：写多个保持寄存器。
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
      if (value < 0 || value > 0xFFFF) {
        hilog.error(DOMAIN, TAG, '%{public}s: invalid register value %{public}d', actionName, value);
        return false;
      }
      pdu.push((value >> 8) & 0xFF);
      pdu.push(value & 0xFF);
    }
    const response = await ModbusTcpClient.executePdu(deviceAddr, new Uint8Array(pdu), actionName);
    if (!response || response.length < 5) {
      return false;
    }

    return response[0] === 0x10 &&
      response[1] === ((regAddr >> 8) & 0xFF) &&
      response[2] === (regAddr & 0xFF) &&
      response[3] === ((regCount >> 8) & 0xFF) &&
      response[4] === (regCount & 0xFF);
  }

  private static async connectInternal(): Promise<boolean> {
    try {
      const tcpSocket: socket.TCPSocket = socket.constructTCPSocketInstance();
      ModbusTcpClient.socket = tcpSocket;
      let settled = false;

      const settleConnect = (ok: boolean, reason: string): void => {
        if (settled) {
          return;
        }
        settled = true;
        ModbusTcpClient.connected = ok;
        hilog.info(DOMAIN, TAG, 'TCP connect settle: %{public}s (%{public}s)', ok ? 'success' : 'failed', reason);
      };

      tcpSocket.on('message', (data: socket.SocketMessageInfo) => {
        const buffer = data.message as ArrayBuffer;
        const dataView = new Uint8Array(buffer);
        hilog.info(DOMAIN, TAG, 'TCP rx raw [%{public}d bytes]: %{public}s',
          dataView.length, ModbusTcpClient.bytesToHex(dataView));

        // 累积到接收缓冲区，然后按 MBAP Length 逐帧切割。
        for (let i = 0; i < dataView.length; i++) {
          ModbusTcpClient.rxBuffer.push(dataView[i]);
        }
        ModbusTcpClient.dispatchCompleteFrames();
      });

      tcpSocket.on('close', () => {
        hilog.info(DOMAIN, TAG, 'TCP connection closed');
        ModbusTcpClient.connected = false;
        ModbusTcpClient.resolveAllPendingResponses();
        ModbusTcpClient.rxBuffer = [];
      });

      return await new Promise<boolean>((resolve) => {
        const timeoutId = setTimeout(() => {
          settleConnect(false, 'timeout');
          resolve(false);
        }, 5000);

        tcpSocket.on('connect', () => {
          clearTimeout(timeoutId);
          settleConnect(true, 'connect event');
          resolve(true);
        });

        tcpSocket.on('error', (err: BusinessError) => {
          if (settled) {
            return;
          }
          clearTimeout(timeoutId);
          hilog.error(DOMAIN, TAG, 'TCP socket error: %{public}s', JSON.stringify(err));
          settleConnect(false, 'error event');
          resolve(false);
        });

        tcpSocket.connect({
          address: {
            address: ModbusTcpClient.mcuIp,
            port: ModbusTcpClient.mcuPort,
            family: 1
          },
          timeout: 5000
        }, (err: BusinessError) => {
          if (!err) {
            clearTimeout(timeoutId);
            hilog.info(DOMAIN, TAG, 'TCP connected to %{public}s:%{public}d',
              ModbusTcpClient.mcuIp, ModbusTcpClient.mcuPort);
            settleConnect(true, 'connect callback');
            resolve(true);
            return;
          }

          if (err.code === 2301115 || err.code === 115) {
            hilog.warn(DOMAIN, TAG, 'TCP connect in progress, waiting connect event...');
            return;
          }

          clearTimeout(timeoutId);
          hilog.error(DOMAIN, TAG, 'TCP connect failed: %{public}s', err.message);
          settleConnect(false, 'connect callback error');
          resolve(false);
        });
      });
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'TCP connect exception: %{public}s', JSON.stringify(err));
      ModbusTcpClient.connected = false;
      return false;
    }
  }

  /**
   * 发送纯 Modbus PDU，并返回设备的纯响应 PDU。
   * 合法 Modbus 异常响应会原样返回，由调用方决定业务失败或网关透传。
   */
  static async executePdu(
    deviceAddr: number,
    requestPdu: Uint8Array,
    actionName: string,
    timeoutMs: number = 3000
  ): Promise<Uint8Array | null> {
    return ModbusTcpClient.requestQueue.run(async (): Promise<Uint8Array | null> => {
      if (!ModbusTcpClient.connected && !(await ModbusTcpClient.connect())) {
        hilog.error(DOMAIN, TAG, '%{public}s: not connected', actionName);
        return null;
      }

      const txId = ModbusTcpClient.getNextTransactionId();
      const pdu: number[] = [];
      for (let index = 0; index < requestPdu.length; index++) {
        pdu.push(requestPdu[index]);
      }

      // MBAP = Transaction ID + Protocol ID + Length + Unit ID。
      const mbap: number[] = [
        (txId >> 8) & 0xFF,
        txId & 0xFF,
        0x00,
        0x00,
        ((pdu.length + 1) >> 8) & 0xFF,
        (pdu.length + 1) & 0xFF,
        deviceAddr
      ];
      const frame: number[] = [...mbap, ...pdu];
      const sendData = new Uint8Array(frame);
      hilog.info(DOMAIN, TAG, '%{public}s: TCP tx [%{public}s]', actionName, ModbusTcpClient.bytesToHex(sendData));

      try {
        if (!ModbusTcpClient.socket) {
          hilog.error(DOMAIN, TAG, '%{public}s: socket is null', actionName);
          return null;
        }

        const responsePromise = new Promise<Uint8Array | null>((resolve) => {
          ModbusTcpClient.pendingResponseResolvers.set(txId, (responseData: Uint8Array | null) => {
            resolve(responseData);
          });
          setTimeout(() => {
            if (ModbusTcpClient.pendingResponseResolvers.has(txId)) {
              ModbusTcpClient.pendingResponseResolvers.delete(txId);
              hilog.warn(DOMAIN, TAG, '%{public}s: wait response timeout', actionName);
              resolve(null);
            }
          }, timeoutMs);
        });

        await ModbusTcpClient.socket.send({ data: sendData.buffer });
        hilog.info(DOMAIN, TAG, '%{public}s: TCP send success', actionName);
        const response = await responsePromise;
        if (!response || response.length <= 7) {
          hilog.error(DOMAIN, TAG, '%{public}s: invalid TCP response length', actionName);
          ModbusTcpClient.markTransportFailed('invalid response');
          return null;
        }

        const unitId = response[6];
        if (unitId !== deviceAddr) {
          hilog.error(DOMAIN, TAG, '%{public}s: unit id mismatch expected=%{public}d actual=%{public}d',
            actionName, deviceAddr, unitId);
          ModbusTcpClient.markTransportFailed('unit id mismatch');
          return null;
        }

        const responsePdu = response.slice(7);
        if (responsePdu.length < 2) {
          hilog.error(DOMAIN, TAG, '%{public}s: invalid PDU length', actionName);
          ModbusTcpClient.markTransportFailed('invalid pdu');
          return null;
        }

        if (ModbusTcpClient.isExceptionResponse(responsePdu)) {
          const exceptionCode = responsePdu[1];
          hilog.error(DOMAIN, TAG, '%{public}s: Modbus exception func=%{public}d code=%{public}d %{public}s',
            actionName,
            responsePdu[0],
            exceptionCode,
            ModbusTcpClient.getExceptionMessage(exceptionCode));
        }

        // 向上层返回纯 PDU；异常 PDU 也保留，供网关原样返回。
        return responsePdu;
      } catch (err) {
        ModbusTcpClient.pendingResponseResolvers.delete(txId);
        hilog.error(DOMAIN, TAG, '%{public}s: TCP send exception: %{public}s', actionName, JSON.stringify(err));
        ModbusTcpClient.markTransportFailed('send exception');
        return null;
      }
    });
  }

  private static markTransportFailed(reason: string): void {
    if (ModbusTcpClient.socket) {
      try {
        ModbusTcpClient.socket.close();
      } catch (err) {
        hilog.warn(DOMAIN, TAG, 'Close failed transport exception: %{public}s', JSON.stringify(err));
      }
    }
    hilog.warn(DOMAIN, TAG, 'TCP transport marked disconnected: %{public}s', reason);
    ModbusTcpClient.socket = null;
    ModbusTcpClient.connected = false;
    ModbusTcpClient.resolveAllPendingResponses();
    ModbusTcpClient.rxBuffer = [];
  }

  /**
   * 从 rxBuffer 中尝试切割完整 Modbus TCP 帧，逐帧分发到对应的 Transaction ID resolver。
   * TCP 流可能粘包（多帧一次到达）或分片（一帧分多次到达），
   * 本方法被 message 事件触发后调用，循环解析直到 buffer 不足一帧。
   */
  private static dispatchCompleteFrames(): void {
    while (ModbusTcpClient.rxBuffer.length >= 7) {
      // MBAP 头前 6 字节: TransactionID(2) + ProtocolID(2) + Length(2)
      // Length 字段 = UnitID(1) + PDU(N)，即从 UnitID 开始的后续字节数
      const lengthField: number = (ModbusTcpClient.rxBuffer[4] << 8) | ModbusTcpClient.rxBuffer[5];
      const totalLen: number = 6 + lengthField;

      if (ModbusTcpClient.rxBuffer.length < totalLen) {
        // 帧不完整（数据被 TCP 分片），等待下一次 message 补齐。
        break;
      }

      const frame: number[] = ModbusTcpClient.rxBuffer.splice(0, totalLen);
      const frameData: Uint8Array = new Uint8Array(frame);
      hilog.info(DOMAIN, TAG, 'TCP frame extracted [%{public}d bytes]: %{public}s',
        frameData.length, ModbusTcpClient.bytesToHex(frameData));

      const txId: number = (frameData[0] << 8) | frameData[1];
      const resolver = ModbusTcpClient.pendingResponseResolvers.get(txId);
      if (resolver) {
        ModbusTcpClient.pendingResponseResolvers.delete(txId);
        resolver(frameData);
      } else {
        hilog.warn(DOMAIN, TAG, 'TCP orphan frame: no resolver for transactionId=%{public}d', txId);
      }
    }
  }

  private static nextTransactionId: number = 1;

  private static getNextTransactionId(): number {
    const txId = ModbusTcpClient.nextTransactionId;
    ModbusTcpClient.nextTransactionId++;
    if (ModbusTcpClient.nextTransactionId > 0xFFFF) {
      ModbusTcpClient.nextTransactionId = 1;
    }
    return txId;
  }

  private static bytesToHex(data: Uint8Array): string {
    let hexStr = '';
    for (let i = 0; i < data.length; i++) {
      hexStr += data[i].toString(16).padStart(2, '0').toUpperCase() + ' ';
    }
    return hexStr;
  }

  private static isExceptionResponse(pdu: Uint8Array): boolean {
    return pdu.length >= 2 && (pdu[0] & 0x80) !== 0;
  }

  private static resolveAllPendingResponses(): void {
    for (const resolver of ModbusTcpClient.pendingResponseResolvers.values()) {
      resolver(null);
    }
    ModbusTcpClient.pendingResponseResolvers.clear();
  }

  private static isSuccessfulPdu(pdu: Uint8Array | null, expectedFunction: number): boolean {
    return pdu !== null && pdu.length >= 2 &&
      !ModbusTcpClient.isExceptionResponse(pdu) &&
      pdu[0] === expectedFunction;
  }

  private static getExceptionMessage(code: number): string {
    switch (code) {
      case 0x01:
        return '非法功能码';
      case 0x02:
        return '非法寄存器地址';
      case 0x03:
        return '非法数据值';
      case 0x04:
        return '从站设备故障';
      default:
        return `未知异常(${code})`;
    }
  }
}
