import { MODBUS_GATEWAY_UNIT_ID } from './ModbusGatewayConfig';
import { ModbusTcpFrameCodec } from './ModbusTcpFrameCodec';
import { ModbusGatewayExecutor } from './ModbusGatewayTypes';
import { ModbusGatewayWritePolicy } from './ModbusGatewayWritePolicy';

const EXCEPTION_ILLEGAL_FUNCTION = 0x01;
const EXCEPTION_ILLEGAL_ADDRESS = 0x02;
const EXCEPTION_ILLEGAL_VALUE = 0x03;
const EXCEPTION_GATEWAY_TARGET_FAILED = 0x0B;

export class ModbusRequestDispatcher {
  private readonly executor: ModbusGatewayExecutor;

  constructor(executor: ModbusGatewayExecutor) {
    this.executor = executor;
  }

  async dispatch(unitId: number, requestPdu: Uint8Array): Promise<Uint8Array> {
    const functionCode = requestPdu.length > 0 ? requestPdu[0] : 0;
    if (unitId !== MODBUS_GATEWAY_UNIT_ID) {
      return ModbusTcpFrameCodec.exceptionPdu(functionCode, EXCEPTION_GATEWAY_TARGET_FAILED);
    }
    if (!this.isSupportedFunction(functionCode)) {
      return ModbusTcpFrameCodec.exceptionPdu(functionCode, EXCEPTION_ILLEGAL_FUNCTION);
    }
    if (!this.hasValidShape(requestPdu)) {
      return ModbusTcpFrameCodec.exceptionPdu(functionCode, EXCEPTION_ILLEGAL_VALUE);
    }
    if (!this.isWriteAllowed(requestPdu)) {
      return ModbusTcpFrameCodec.exceptionPdu(functionCode, EXCEPTION_ILLEGAL_ADDRESS);
    }

    const response = await this.executor.execute(unitId, requestPdu, this.describeRequest(requestPdu));
    if (!response) {
      return ModbusTcpFrameCodec.exceptionPdu(functionCode, EXCEPTION_GATEWAY_TARGET_FAILED);
    }
    return response;
  }

  private isSupportedFunction(functionCode: number): boolean {
    return functionCode === 0x03 || functionCode === 0x04 ||
      functionCode === 0x06 || functionCode === 0x10;
  }

  private hasValidShape(pdu: Uint8Array): boolean {
    const functionCode = pdu[0];
    if (functionCode === 0x03 || functionCode === 0x04) {
      if (pdu.length !== 5) {
        return false;
      }
      const count = this.uint16(pdu[3], pdu[4]);
      return count >= 1 && count <= 125;
    }
    if (functionCode === 0x06) {
      return pdu.length === 5;
    }
    if (functionCode === 0x10) {
      if (pdu.length < 6) {
        return false;
      }
      const count = this.uint16(pdu[3], pdu[4]);
      const byteCount = pdu[5];
      return count >= 1 && count <= 123 &&
        byteCount === count * 2 &&
        pdu.length === 6 + byteCount;
    }
    return false;
  }

  private isWriteAllowed(pdu: Uint8Array): boolean {
    if (pdu[0] === 0x03 || pdu[0] === 0x04) {
      return true;
    }
    const address = this.uint16(pdu[1], pdu[2]);
    const registerCount = pdu[0] === 0x06 ? 1 : this.uint16(pdu[3], pdu[4]);
    return ModbusGatewayWritePolicy.canWrite(address, registerCount);
  }

  private describeRequest(pdu: Uint8Array): string {
    const address = pdu.length >= 3 ? this.uint16(pdu[1], pdu[2]) : 0;
    return `Dashboard网关请求 func=${pdu[0]} address=${address}`;
  }

  private uint16(high: number, low: number): number {
    return ((high & 0xFF) << 8) | (low & 0xFF);
  }
}
