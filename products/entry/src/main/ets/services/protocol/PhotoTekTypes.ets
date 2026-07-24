export type PhotoTekRegisterValueType =
  'uint16' |
  'floatCdab' |
  'floatArrayCdab' |
  'time' |
  'utf16String' |
  'char' |
  'firmwareVersion';

export type PhotoTekRegisterAccess = 'read' | 'write' | 'readWrite';

export interface PhotoTekInputRegisterDefinition {
  key: string;
  address: number;
  name: string;
  dataType: string;
  registerCount: number;
  unit: string;
  valueType: PhotoTekRegisterValueType;
  description: string;
  codeTable?: string;
}

export interface PhotoTekHoldRegisterDefinition {
  key: string;
  address: number;
  name: string;
  dataType: string;
  registerCount: number;
  unit: string;
  valueType: PhotoTekRegisterValueType;
  access: PhotoTekRegisterAccess;
  description: string;
  codeTable?: string;
}

export interface PhotoTekMeasurementParameterInfo {
  code: number;
  legacyCode: string;
  name: string;
  unit: string;
}

export interface PhotoTekCodeDescription {
  code: number | string;
  label: string;
  description?: string;
}

export interface PhotoTekTimeValue {
  year: number;
  month: number;
  day: number;
  hour: number;
  minute: number;
  second: number;
  text: string;
}

export interface PhotoTekFirmwareVersion {
  major: number;
  minor: number;
  revision: number;
  build: number;
  text: string;
}

export interface PhotoTekTemperatureValue {
  digestionTemperature: number;
  ambientTemperature: number;
  unit: string;
}

export interface PhotoTekDataFlag {
  code: string;
  label: string;
}
