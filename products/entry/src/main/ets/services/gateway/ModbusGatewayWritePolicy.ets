import { PhotoTekHoldRegisters } from '../protocol/PhotoTekHoldRegisters';
import { PhotoTekHoldRegisterDefinition } from '../protocol/PhotoTekTypes';

export class ModbusGatewayWritePolicy {
  private static readonly writableRegisters: PhotoTekHoldRegisterDefinition[] = [
    PhotoTekHoldRegisters.CURRENT_RANGE,
    PhotoTekHoldRegisters.CALIBRATION_CURVE_SLOPE,
    PhotoTekHoldRegisters.CALIBRATION_CURVE_INTERCEPT,
    PhotoTekHoldRegisters.DIGESTION_TEMPERATURE,
    PhotoTekHoldRegisters.DIGESTION_TIME,
    PhotoTekHoldRegisters.REACTION_TEMPERATURE,
    PhotoTekHoldRegisters.REACTION_TIME,
    PhotoTekHoldRegisters.CORRECTION_FACTOR,
    PhotoTekHoldRegisters.MEASUREMENT_CONTROL,
    PhotoTekHoldRegisters.WATER_COLLECTION_CONTROL,
    PhotoTekHoldRegisters.SYSTEM_TIME,
    PhotoTekHoldRegisters.MEASUREMENT_MODE,
    PhotoTekHoldRegisters.AUTO_MEASUREMENT_INTERVAL,
    PhotoTekHoldRegisters.AUTO_CALIBRATION_MODE,
    PhotoTekHoldRegisters.AUTO_CALIBRATION_INTERVAL
  ];

  static canWrite(address: number, registerCount: number): boolean {
    for (const register of ModbusGatewayWritePolicy.writableRegisters) {
      if (register.access !== 'read' &&
        register.address === address &&
        register.registerCount === registerCount) {
        return true;
      }
    }
    return false;
  }
}
