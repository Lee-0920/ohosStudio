import { BusinessError } from '@kit.BasicServicesKit';
import { socket } from '@kit.NetworkKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import {
  MODBUS_GATEWAY_INITIAL_RETRY_MS,
  MODBUS_GATEWAY_LISTEN_ADDRESS,
  MODBUS_GATEWAY_LISTEN_PORT,
  MODBUS_GATEWAY_MAX_RETRY_MS
} from './ModbusGatewayConfig';
import { ModbusGatewayState } from './ModbusGatewayTypes';
import { ModbusRequestDispatcher } from './ModbusRequestDispatcher';
import { ModbusTcpClientSession } from './ModbusTcpClientSession';

const DOMAIN = 0x0004;
const TAG = 'ModbusGatewayServer';

export class ModbusTcpGatewayServer {
  private readonly dispatcher: ModbusRequestDispatcher;
  private server: socket.TCPSocketServer | null = null;
  private readonly sessions: Map<number, ModbusTcpClientSession> = new Map();
  private state: ModbusGatewayState = 'stopped';
  private retryTimer: number = -1;
  private retryDelayMs: number = MODBUS_GATEWAY_INITIAL_RETRY_MS;
  private stopRequested: boolean = false;

  constructor(dispatcher: ModbusRequestDispatcher) {
    this.dispatcher = dispatcher;
  }

  getState(): ModbusGatewayState {
    return this.state;
  }

  async start(): Promise<boolean> {
    if (this.state === 'listening') {
      return true;
    }
    if (this.state === 'starting' || this.state === 'retryWait') {
      return false;
    }
    this.stopRequested = false;
    return this.startInternal();
  }

  async stop(): Promise<void> {
    if (this.state === 'stopped') {
      return;
    }
    this.stopRequested = true;
    this.state = 'stopping';
    if (this.retryTimer >= 0) {
      clearTimeout(this.retryTimer);
      this.retryTimer = -1;
    }

    const activeSessions: ModbusTcpClientSession[] = [];
    for (const session of this.sessions.values()) {
      activeSessions.push(session);
    }
    this.sessions.clear();
    for (const session of activeSessions) {
      await session.close();
    }

    const currentServer: socket.TCPSocketServer | null = this.server;
    this.server = null;
    if (currentServer) {
      try {
        currentServer.off('connect');
        currentServer.off('error');
        await currentServer.close();
      } catch (error) {
        hilog.warn(DOMAIN, TAG, 'Close gateway server failed: %{public}s', JSON.stringify(error));
      }
    }
    this.retryDelayMs = MODBUS_GATEWAY_INITIAL_RETRY_MS;
    this.state = 'stopped';
  }

  private async startInternal(): Promise<boolean> {
    if (this.stopRequested) {
      return false;
    }
    this.state = 'starting';
    const server: socket.TCPSocketServer = socket.constructTCPSocketServerInstance();
    this.server = server;
    server.on('connect', (connection: socket.TCPSocketConnection): void => {
      this.acceptConnection(connection);
    });
    server.on('error', (error: BusinessError): void => {
      hilog.error(DOMAIN, TAG, 'Gateway server error: %{public}s', JSON.stringify(error));
    });

    const address: socket.NetAddress = {
      address: MODBUS_GATEWAY_LISTEN_ADDRESS,
      port: MODBUS_GATEWAY_LISTEN_PORT,
      family: 1
    };
    try {
      await server.listen(address);
      if (this.stopRequested || this.server !== server) {
        try {
          await server.close();
        } catch (closeError) {
          hilog.warn(DOMAIN, TAG, 'Close obsolete gateway server failed: %{public}s',
            JSON.stringify(closeError));
        }
        return false;
      }
      this.state = 'listening';
      this.retryDelayMs = MODBUS_GATEWAY_INITIAL_RETRY_MS;
      hilog.info(DOMAIN, TAG, 'Gateway listening on %{public}s:%{public}d',
        MODBUS_GATEWAY_LISTEN_ADDRESS, MODBUS_GATEWAY_LISTEN_PORT);
      return true;
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'Gateway listen failed: %{public}s', JSON.stringify(error));
      try {
        server.off('connect');
        server.off('error');
        await server.close();
      } catch (closeError) {
        hilog.warn(DOMAIN, TAG, 'Cleanup failed gateway server failed: %{public}s',
          JSON.stringify(closeError));
      }
      if (this.server === server) {
        this.server = null;
      }
      this.scheduleRetry();
      return false;
    }
  }

  private acceptConnection(connection: socket.TCPSocketConnection): void {
    if (this.stopRequested || this.state !== 'listening') {
      void connection.close();
      return;
    }
    const clientId: number = connection.clientId;
    const previous = this.sessions.get(clientId);
    if (previous) {
      void previous.close();
    }
    const session = new ModbusTcpClientSession(
      connection,
      this.dispatcher,
      (closedClientId: number): void => {
        this.sessions.delete(closedClientId);
      }
    );
    this.sessions.set(clientId, session);
    session.start();
    hilog.info(DOMAIN, TAG, 'Dashboard client connected: %{public}d', clientId);
  }

  private scheduleRetry(): void {
    if (this.stopRequested) {
      this.state = 'stopped';
      return;
    }
    this.state = 'retryWait';
    const delayMs = this.retryDelayMs;
    this.retryDelayMs = Math.min(this.retryDelayMs * 2, MODBUS_GATEWAY_MAX_RETRY_MS);
    this.retryTimer = setTimeout((): void => {
      this.retryTimer = -1;
      void this.startInternal();
    }, delayMs);
  }
}
