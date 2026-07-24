export type ModbusGatewayState = 'stopped' | 'starting' | 'listening' | 'retryWait' | 'stopping';

export interface ModbusTcpRequestFrame {
  transactionId: number;
  protocolId: number;
  unitId: number;
  pdu: Uint8Array;
}

export interface ModbusGatewayExecutor {
  execute(unitId: number, requestPdu: Uint8Array, actionName: string): Promise<Uint8Array | null>;
}
