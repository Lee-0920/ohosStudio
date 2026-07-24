import { HardwareConfig, } from 'dataservice';

// export interface MeterPointItem {
//   setVolume: number;  // 定量点设定的定量值
//   realVolume: number; // 定量点实际的定量值
// }
//
// export interface MeterPoint {
//   num: number;           // 定量点数量
//   point: MeterPointItem[];
// }
//
// export interface ThermostatParamValue {
//   set: number;  // 设置值
//   real: number; // 实际值
// }
//
// export interface ThermostatParam {
//   proportion: ThermostatParamValue;  // 比例参数
//   integration: ThermostatParamValue; // 积分参数
//   differential: ThermostatParamValue; // 微分参数
// }
//
// export interface MeterLedPoint {
//   set: number;  // 设置值
//   real: number; // 实际值
// }
//
// export interface MeterLed {
//   num: number;         // LED数量
//   maxValue: number;    // 最大值
//   point: MeterLedPoint[];
// }
//
// export interface MeasureLedValue {
//   set: number;  // 设置值
//   real: number; // 实际值
// }
//
// export interface MeasureLed {
//   maxValue: number;           // 最大值
//   reference: MeasureLedValue; // 参考通道
//   measure: MeasureLedValue;   // 测量通道
//   targetAD: MeasureLedValue;  // 目标AD值
//   ledDAC: MeasureLedValue;    // DAC值
// }
//
// export interface GainCalibrateValue {
//   set: number;  // 设置值
//   real: number; // 实际值
// }
//
// export interface Gain {
//   reference: GainCalibrateValue; // 参考通道增益
//   measure: GainCalibrateValue;   // 测量通道增益
// }
//
// export interface GainCalibrate {
//   maxValue: number; // 最大值
//   gain: Gain;       // 测量增益
// }
//
// export interface TempCalibrate {
//   negativeInput: number;      // 负温度系数
//   referenceVoltage: number;   // 参考电压
//   calibrationVoltage: number; // 校准电压
// };

// export interface HardwareConfig {
//   meterPoint: MeterPoint;         // 定量点配置
//   thermostatParam: ThermostatParam; // 恒温参数
//   pumpFactor: number[];           // 泵系数
//   tempCalibrate: TempCalibrate;
//   meterLed: MeterLed;             // 测光LED配置
//   measureLed: MeasureLed;         // 测量LED配置
//   gainCalibrate: GainCalibrate;   // 增益校准配置
// }

export const hardwareConfig: HardwareConfig = {
  reactionCamera: {
    volume:10,
  },
  meterPoint: {
    num: 2,
    point: [
      {
        setVolume: 1,
        realVolume: 1,
      },
      {
        setVolume: 2,
        realVolume: 2,
      },
    ],
  },
  thermostatParam: {
    proportion: {
      set: 90,
      real: 90,
    },
    integration: {
      set: 0.71,
      real: 0.71,
    },
    differential: {
      set: 80,
      real: 80,
    },
  },
  pumpFactor: {
    ref:0.0015,
    real:0.0015
  },
  tempCalibrate: {
    negativeInput: 1.2475,
    referenceVoltage: 2.495,
    calibrationVoltage: 0,
  },
  meterLed: {
    num: 2,
    maxValue: 256,
    point: [
      {
        set: 3,
        real: 3,
      },
      {
        set: 3,
        real: 3,
      },
    ],
  },
  measureLed: {
    maxValue: 256,
    reference: {
      set: 128,
      real: 128,
    },
    measure: {
      set: 128,
      real: 128,
    },
    targetAD: {
      set: 1100,
      real: 1100,
    },
    ledDAC: {
      set: 1,
      real: 1,
    },
  },
  gainCalibrate: {
    maxValue: 3,
    gain: {
      reference: {
        set: 1,
        real: 1,
      },
      measure: {
        set: 1,
        real: 1,
      },
    },
  },
};
