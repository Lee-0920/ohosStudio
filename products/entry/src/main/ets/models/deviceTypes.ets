import {
  PhotoTekCodeDescription,
  PhotoTekDataFlag,
  PhotoTekFirmwareVersion,
  PhotoTekMeasurementParameterInfo,
  PhotoTekTemperatureValue,
  PhotoTekTimeValue
} from '../services/protocol/PhotoTekTypes';

export interface MeasurementSnapshot {
  parameter: PhotoTekMeasurementParameterInfo;
  result: number;
  resultUnit: string;
  resultType: PhotoTekCodeDescription | null;
  measurementDurationSeconds: number | null;
  measurementTime: PhotoTekTimeValue | null;
  calibrationSolutionResult: number | null;
  calibrationSolutionTime: PhotoTekTimeValue | null;
  calibrationTime: PhotoTekTimeValue | null;
  spanCheckResult: number | null;
  spanCheckTime: PhotoTekTimeValue | null;
  dataFlag: PhotoTekDataFlag | null;
}

export interface DeviceRuntimeStatus {
  connected: boolean;
  systemStatus: PhotoTekCodeDescription;
  currentAction: PhotoTekCodeDescription;
  temperatures: PhotoTekTemperatureValue | null;
  alarmTime: PhotoTekTimeValue | null;
  alarmCode: PhotoTekCodeDescription | null;
}

export interface MeasurementConfig {
  currentRange: number;
  rangeTable: number[] | null;
  measurementMode: PhotoTekCodeDescription;
  autoMeasurementIntervalHours: number | null;
  autoCalibrationMode: PhotoTekCodeDescription | null;
  autoCalibrationIntervalHours: number | null;
  calibrationCurveSlope: number | null;
  calibrationCurveIntercept: number | null;
  digestionTemperature: number | null;
  digestionTimeSeconds: number | null;
  reactionTemperature: number | null;
  reactionTimeSeconds: number | null;
  correctionFactor: number | null;
  currentRangeDilutionFactor: number | null;
  zeroCalibrationSolutionConcentration: number | null;
  spanCalibrationSolutionConcentration: number | null;
  reagentOneVolume: number | null;
  reagentTwoVolume: number | null;
  reagentThreeVolume: number | null;
  reagentFourVolume: number | null;
  reagentFiveVolume: number | null;
  currentRangeCorrectionFactor: number | null;
  spanCheckAllowedDeviation: number | null;
  spanCheckDeviation: number | null;
}

export interface InstrumentInfo {
  productName: string;
  productModel: string;
  manufacturer: string;
  serialNumber: string;
}

export interface BoardFirmwareInfo {
  boardKey: string;
  boardName: string;
  firmwareVersion: PhotoTekFirmwareVersion | null;
}

export interface BoardInfo {
  liquidBoard: BoardFirmwareInfo;
  temperatureBoard: BoardFirmwareInfo;
  signalBoard: BoardFirmwareInfo;
  mainBoard: BoardFirmwareInfo;
  driverBoard: BoardFirmwareInfo;
  reactionBoard: BoardFirmwareInfo;
}
