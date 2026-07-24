import {
  PhotoTekCodeDescription,
  PhotoTekDataFlag,
  PhotoTekFirmwareVersion,
  PhotoTekHoldRegisterDefinition,
  PhotoTekInputRegisterDefinition,
  PhotoTekMeasurementParameterInfo,
  PhotoTekTemperatureValue,
  PhotoTekTimeValue
} from '../protocol/PhotoTekTypes';
import {
  BoardInfo,
  DeviceRuntimeStatus,
  InstrumentInfo,
  MeasurementConfig,
  MeasurementSnapshot
} from '../../models/deviceTypes';

export type CommunicationMode = 'tcp' | 'uart';

export interface WaterQualityDevice {
  getMode(): CommunicationMode;
  setMode(mode: CommunicationMode): void;
  connect(): Promise<boolean>;
  disconnect(): void;
  isConnected(): boolean;
  executeRawModbusRequest(
    unitId: number,
    requestPdu: Uint8Array,
    actionName: string
  ): Promise<Uint8Array | null>;
  setMcuConfig(ip: string, port: number): void;
  setUartConfig(
    path: string,
    baudRate: number,
    dataBits?: number,
    stopBits?: number,
    parity?: string,
    isRs485?: boolean
  ): void;

  readMeasurementSnapshot(): Promise<MeasurementSnapshot | null>;
  readRuntimeStatus(): Promise<DeviceRuntimeStatus | null>;
  readMeasurementConfig(): Promise<MeasurementConfig | null>;
  readInstrumentInfo(): Promise<InstrumentInfo | null>;
  readBoardInfo(): Promise<BoardInfo | null>;

  readMeasurementParameterInfo(): Promise<PhotoTekMeasurementParameterInfo | null>;
  readMeasurementResult(): Promise<number | null>;
  readMeasurementCalibrationSolutionResult(): Promise<number | null>;
  readMeasurementResultType(): Promise<PhotoTekCodeDescription | null>;
  readMeasurementDurationSeconds(): Promise<number | null>;
  readMeasurementTime(): Promise<PhotoTekTimeValue | null>;
  readCalibrationSolutionTime(): Promise<PhotoTekTimeValue | null>;
  readCalibrationTime(): Promise<PhotoTekTimeValue | null>;
  readSystemStatus(): Promise<PhotoTekCodeDescription | null>;
  readCurrentAction(): Promise<PhotoTekCodeDescription | null>;
  readCurrentTemperatures(): Promise<PhotoTekTemperatureValue | null>;
  readAlarmTime(): Promise<PhotoTekTimeValue | null>;
  readAlarmCode(): Promise<PhotoTekCodeDescription | null>;
  readRangeTable(): Promise<number[] | null>;
  readProductName(): Promise<string | null>;
  readProductModel(): Promise<string | null>;
  readManufacturer(): Promise<string | null>;
  readSerialNumber(): Promise<string | null>;
  readLiquidBoardFirmwareVersion(): Promise<PhotoTekFirmwareVersion | null>;
  readTemperatureBoardFirmwareVersion(): Promise<PhotoTekFirmwareVersion | null>;
  readSignalBoardFirmwareVersion(): Promise<PhotoTekFirmwareVersion | null>;
  readMainBoardFirmwareVersion(): Promise<PhotoTekFirmwareVersion | null>;
  readDriverBoardFirmwareVersion(): Promise<PhotoTekFirmwareVersion | null>;
  readReactionBoardFirmwareVersion(): Promise<PhotoTekFirmwareVersion | null>;
  readSpanCheckResult(): Promise<number | null>;
  readSpanCheckTime(): Promise<PhotoTekTimeValue | null>;
  readWaterSampleAbsorbance(): Promise<number | null>;
  readWaterSampleDataFlag(): Promise<PhotoTekDataFlag | null>;
  readCalibrationSolutionAbsorbance(): Promise<number | null>;
  readCalibrationSolutionDataFlag(): Promise<PhotoTekDataFlag | null>;
  readCheckSolutionAbsorbance(): Promise<number | null>;
  readCheckSolutionDataFlag(): Promise<PhotoTekDataFlag | null>;
  readCalibrationZeroConcentration(): Promise<number | null>;
  readCalibrationZeroAbsorbance(): Promise<number | null>;
  readZeroDrift(): Promise<number | null>;
  readCalibrationSpanConcentration(): Promise<number | null>;
  readCalibrationSpanAbsorbance(): Promise<number | null>;
  readSpanDrift(): Promise<number | null>;
  readCompositeMeasurementResult(): Promise<number | null>;
  readCompositeResultTime(): Promise<PhotoTekTimeValue | null>;
  readCompositeDataFlag(): Promise<PhotoTekDataFlag | null>;
  readTocFactorConstant(): Promise<number | null>;
  readTocFactorRatio(): Promise<number | null>;
  readTocFlowControl(): Promise<number | null>;
  readTocMeasurementResult(): Promise<number | null>;

  readCurrentRange(): Promise<number | null>;
  writeCurrentRange(rangeUpperLimit: number): Promise<boolean>;
  readCalibrationCurveSlope(): Promise<number | null>;
  writeCalibrationCurveSlope(slope: number): Promise<boolean>;
  readCalibrationCurveIntercept(): Promise<number | null>;
  writeCalibrationCurveIntercept(intercept: number): Promise<boolean>;
  readDigestionTemperature(): Promise<number | null>;
  writeDigestionTemperature(temperature: number): Promise<boolean>;
  readDigestionTimeSeconds(): Promise<number | null>;
  writeDigestionTimeSeconds(seconds: number): Promise<boolean>;
  readReactionTemperature(): Promise<number | null>;
  writeReactionTemperature(temperature: number): Promise<boolean>;
  readReactionTimeSeconds(): Promise<number | null>;
  writeReactionTimeSeconds(seconds: number): Promise<boolean>;
  readCorrectionFactor(): Promise<number | null>;
  writeCorrectionFactor(factor: number): Promise<boolean>;
  writeMeasurementControl(controlCode: number): Promise<boolean>;
  writeWaterCollectionControl(enabled: boolean): Promise<boolean>;
  readSystemTime(): Promise<PhotoTekTimeValue | null>;
  writeSystemTime(
    year: number,
    month: number,
    day: number,
    hour: number,
    minute: number,
    second: number
  ): Promise<boolean>;
  readMeasurementMode(): Promise<PhotoTekCodeDescription | null>;
  writeMeasurementMode(mode: number): Promise<boolean>;
  readAutoMeasurementIntervalHours(): Promise<number | null>;
  writeAutoMeasurementIntervalHours(hours: number): Promise<boolean>;
  readAutoCalibrationMode(): Promise<PhotoTekCodeDescription | null>;
  writeAutoCalibrationMode(mode: number): Promise<boolean>;
  readAutoCalibrationIntervalHours(): Promise<number | null>;
  writeAutoCalibrationIntervalHours(hours: number): Promise<boolean>;
  readCurrentRangeDilutionFactor(): Promise<number | null>;
  readZeroCalibrationSolutionConcentration(): Promise<number | null>;
  readSpanCalibrationSolutionConcentration(): Promise<number | null>;
  readReagentOneVolume(): Promise<number | null>;
  readReagentTwoVolume(): Promise<number | null>;
  readReagentThreeVolume(): Promise<number | null>;
  readReagentFourVolume(): Promise<number | null>;
  readReagentFiveVolume(): Promise<number | null>;
  readCurrentRangeCorrectionFactor(): Promise<number | null>;
  readSpanCheckAllowedDeviation(): Promise<number | null>;
  readSpanCheckDeviation(): Promise<number | null>;

  startMeasurement(): Promise<boolean>;
  stopMeasurement(): Promise<boolean>;
  startCalibration(): Promise<boolean>;
  startCleaning(): Promise<boolean>;
  measureRangeCalibrationSolution(): Promise<boolean>;
  measureZeroCalibrationSolution(): Promise<boolean>;
  cleanQuantitativeTube(): Promise<boolean>;
  cleanDigestionChamber(): Promise<boolean>;
  cleanAllPipelines(): Promise<boolean>;
  collectWaterSample(): Promise<boolean>;
  startQuantitativePumpCalibration(): Promise<boolean>;
  startZeroCalibration(): Promise<boolean>;
  startSpanCalibration(): Promise<boolean>;
  startZeroCheck(): Promise<boolean>;
  startSpanCheck(): Promise<boolean>;

  // Legacy MonitorService compatibility methods. Keep protocol details below the UI boundary.
  readInputRegisters(regAddr: number, regCount: number, actionName: string): Promise<Uint8Array | null>;
  readHoldRegisters(regAddr: number, regCount: number, actionName: string): Promise<Uint8Array | null>;
  readInputRegisterData(
    register: PhotoTekInputRegisterDefinition,
    actionName: string
  ): Promise<Uint8Array | null>;
  readHoldRegisterData(
    register: PhotoTekHoldRegisterDefinition,
    actionName: string
  ): Promise<Uint8Array | null>;
  readUInt16HoldRegister(
    register: PhotoTekHoldRegisterDefinition,
    actionName: string
  ): Promise<number | null>;
  readFloatHoldRegister(
    register: PhotoTekHoldRegisterDefinition,
    actionName: string
  ): Promise<number | null>;
  readTimeHoldRegister(
    register: PhotoTekHoldRegisterDefinition,
    actionName: string
  ): Promise<PhotoTekTimeValue | null>;
  readCodeDescriptionHoldRegister(
    register: PhotoTekHoldRegisterDefinition,
    table: PhotoTekCodeDescription[],
    unknownLabel: string,
    actionName: string
  ): Promise<PhotoTekCodeDescription | null>;
  writeUInt16HoldRegister(
    register: PhotoTekHoldRegisterDefinition,
    value: number,
    actionName: string
  ): Promise<boolean>;
  writeFloatHoldRegister(
    register: PhotoTekHoldRegisterDefinition,
    value: number,
    actionName: string
  ): Promise<boolean>;
  writeTimeHoldRegister(
    register: PhotoTekHoldRegisterDefinition,
    year: number,
    month: number,
    day: number,
    hour: number,
    minute: number,
    second: number,
    actionName: string
  ): Promise<boolean>;
  writeHoldRegisterValues(
    register: PhotoTekHoldRegisterDefinition,
    regValues: number[],
    actionName: string
  ): Promise<boolean>;
  readUInt16InputRegister(
    register: PhotoTekInputRegisterDefinition,
    actionName: string
  ): Promise<number | null>;
  readFloatInputRegister(
    register: PhotoTekInputRegisterDefinition,
    actionName: string
  ): Promise<number | null>;
  readFloatArrayInputRegister(
    register: PhotoTekInputRegisterDefinition,
    floatCount: number,
    actionName: string
  ): Promise<number[] | null>;
  readTimeInputRegister(
    register: PhotoTekInputRegisterDefinition,
    actionName: string
  ): Promise<PhotoTekTimeValue | null>;
  readStringInputRegister(
    register: PhotoTekInputRegisterDefinition,
    actionName: string
  ): Promise<string | null>;
  readFirmwareVersionInputRegister(
    register: PhotoTekInputRegisterDefinition,
    actionName: string
  ): Promise<PhotoTekFirmwareVersion | null>;
  readCodeDescriptionInputRegister(
    register: PhotoTekInputRegisterDefinition,
    table: PhotoTekCodeDescription[],
    unknownLabel: string,
    actionName: string
  ): Promise<PhotoTekCodeDescription | null>;
  readDataFlagInputRegister(
    register: PhotoTekInputRegisterDefinition,
    table: PhotoTekCodeDescription[],
    actionName: string
  ): Promise<PhotoTekDataFlag | null>;
  getReadDataBytes(
    responsePdu: Uint8Array,
    actionName: string,
    expectedFuncCode?: number
  ): Uint8Array | null;
  isKnownCode(table: PhotoTekCodeDescription[], code: number): boolean;
}
