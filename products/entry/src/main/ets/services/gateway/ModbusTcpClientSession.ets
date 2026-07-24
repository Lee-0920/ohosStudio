import { BusinessError } from '@kit.BasicServicesKit';
import { socket } from '@kit.NetworkKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { ModbusRequestDispatcher } from './ModbusRequestDispatcher';
import { ModbusTcpFrameCodec } from './ModbusTcpFrameCodec';
import { ModbusTcpRequestFrame } from './ModbusGatewayTypes';

const DOMAIN = 0x0004;
const TAG = 'ModbusGatewaySession';

export class ModbusTcpClientSession {
  private readonly connection: socket.TCPSocketConnection;
  private readonly dispatcher: ModbusRequestDispatcher;
  private readonly onClosed: (clientId: number) => void;
  private readonly rxBuffer: number[] = [];
  private closed: boolean = false;
  private closeNotified: boolean = false;
  private sendTail: Promise<void> = Promise.resolve();

  constructor(
    connection: socket.TCPSocketConnection,
    dispatcher: ModbusRequestDispatcher,
    onClosed: (clientId: number) => void
  ) {
    this.connection = connection;
    this.dispatcher = dispatcher;
    this.onClosed = onClosed;
  }

  getClientId(): number {
    return this.connection.clientId;
  }

  start(): void {
    this.connection.on('message', (data: socket.SocketMessageInfo): void => {
      this.handleMessage(data);
    });
    this.connection.on('close', (): void => {
      this.markClosed();
    });
    this.connection.on('error', (error: BusinessError): void => {
      hilog.error(DOMAIN, TAG, 'Client %{public}d socket error: %{public}s',
        this.connection.clientId, JSON.stringify(error));
      void this.close();
    });
  }

  async close(): Promise<void> {
    if (this.closed) {
      this.notifyClosed();
      return;
    }
    this.closed = true;
    this.rxBuffer.length = 0;
    try {
      this.connection.off('message');
      this.connection.off('close');
      this.connection.off('error');
      await this.connection.close();
    } catch (error) {
      hilog.warn(DOMAIN, TAG, 'Close client %{public}d failed: %{public}s',
        this.connection.clientId, JSON.stringify(error));
    }
    this.notifyClosed();
  }

  private handleMessage(data: socket.SocketMessageInfo): void {
    if (this.closed) {
      return;
    }
    try {
      ModbusTcpFrameCodec.append(this.rxBuffer, new Uint8Array(data.message));
      const frames = ModbusTcpFrameCodec.extractFrames(this.rxBuffer);
      for (const frame of frames) {
        void this.processFrame(frame);
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'Client %{public}d invalid Modbus TCP stream: %{public}s',
        this.connection.clientId, JSON.stringify(error));
      void this.close();
    }
  }

  private async processFrame(frame: ModbusTcpRequestFrame): Promise<void> {
    const responsePdu = await this.dispatcher.dispatch(frame.unitId, frame.pdu);
    if (this.closed) {
      return;
    }
    const response = ModbusTcpFrameCodec.encodeResponse(
      frame.transactionId,
      frame.unitId,
      responsePdu
    );
    await this.enqueueSend(response);
  }

  private async enqueueSend(data: Uint8Array): Promise<void> {
    const previous = this.sendTail;
    let release: () => void = () => {};
    this.sendTail = new Promise<void>((resolve: () => void) => {
      release = resolve;
    });
    await previous;
    try {
      if (!this.closed) {
        await this.connection.send({ data: data.buffer });
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'Send response to client %{public}d failed: %{public}s',
        this.connection.clientId, JSON.stringify(error));
      void this.close();
    } finally {
      release();
    }
  }

  private markClosed(): void {
    this.closed = true;
    this.rxBuffer.length = 0;
    this.notifyClosed();
  }

  private notifyClosed(): void {
    if (this.closeNotified) {
      return;
    }
    this.closeNotified = true;
    this.onClosed(this.connection.clientId);
  }
}
