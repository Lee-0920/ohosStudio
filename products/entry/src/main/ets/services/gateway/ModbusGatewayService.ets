import { MonitorService } from '../MonitorService';
import { ModbusGatewayExecutor, ModbusGatewayState } from './ModbusGatewayTypes';
import { ModbusRequestDispatcher } from './ModbusRequestDispatcher';
import { ModbusTcpGatewayServer } from './ModbusTcpGatewayServer';

class MonitorModbusGatewayExecutor implements ModbusGatewayExecutor {
  execute(
    unitId: number,
    requestPdu: Uint8Array,
    _actionName: string
  ): Promise<Uint8Array | null> {
    return MonitorService.executeGatewayModbusRequest(unitId, requestPdu);
  }
}

export class ModbusGatewayService {
  private static readonly executor: ModbusGatewayExecutor = new MonitorModbusGatewayExecutor();
  private static readonly dispatcher: ModbusRequestDispatcher =
    new ModbusRequestDispatcher(ModbusGatewayService.executor);
  private static readonly server: ModbusTcpGatewayServer =
    new ModbusTcpGatewayServer(ModbusGatewayService.dispatcher);

  static start(): Promise<boolean> {
    return ModbusGatewayService.server.start();
  }

  static stop(): Promise<void> {
    return ModbusGatewayService.server.stop();
  }

  static getState(): ModbusGatewayState {
    return ModbusGatewayService.server.getState();
  }
}
