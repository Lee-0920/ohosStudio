import { MODBUS_GATEWAY_MAX_LENGTH } from './ModbusGatewayConfig';
import { ModbusTcpRequestFrame } from './ModbusGatewayTypes';

export class ModbusTcpFrameCodec {
  static append(target: number[], chunk: Uint8Array): void {
    for (let index = 0; index < chunk.length; index++) {
      target.push(chunk[index]);
    }
  }

  static extractFrames(buffer: number[]): ModbusTcpRequestFrame[] {
    const frames: ModbusTcpRequestFrame[] = [];
    while (buffer.length >= 7) {
      const protocolId = (buffer[2] << 8) | buffer[3];
      if (protocolId !== 0) {
        throw new Error(`Unsupported Modbus protocol id: ${protocolId}`);
      }

      const lengthField = (buffer[4] << 8) | buffer[5];
      if (lengthField < 2 || lengthField > MODBUS_GATEWAY_MAX_LENGTH) {
        throw new Error(`Invalid Modbus TCP length: ${lengthField}`);
      }

      const totalLength = 6 + lengthField;
      if (buffer.length < totalLength) {
        break;
      }

      const frameBytes = buffer.splice(0, totalLength);
      const transactionId = (frameBytes[0] << 8) | frameBytes[1];
      const unitId = frameBytes[6];
      const pdu = new Uint8Array(frameBytes.slice(7));
      frames.push({
        transactionId: transactionId,
        protocolId: protocolId,
        unitId: unitId,
        pdu: pdu
      });
    }
    return frames;
  }

  static encodeResponse(transactionId: number, unitId: number, pdu: Uint8Array): Uint8Array {
    const lengthField = pdu.length + 1;
    const response = new Uint8Array(7 + pdu.length);
    response[0] = (transactionId >> 8) & 0xFF;
    response[1] = transactionId & 0xFF;
    response[2] = 0;
    response[3] = 0;
    response[4] = (lengthField >> 8) & 0xFF;
    response[5] = lengthField & 0xFF;
    response[6] = unitId;
    response.set(pdu, 7);
    return response;
  }

  static exceptionPdu(requestFunction: number, exceptionCode: number): Uint8Array {
    return new Uint8Array([(requestFunction | 0x80) & 0xFF, exceptionCode & 0xFF]);
  }
}
