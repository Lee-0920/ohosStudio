// 从工具模块导入具体函数
export { add, sub } from './src/main/ets/utils/Calc';
// 1. 导出所有默认单例实例（业务代码最常用的方式）
export { default as dncp } from './src/main/ets/Communication/DncpManager';
export { default as pump } from './src/main/ets/Communication/PumpManager';
export { default as valve } from './src/main/ets/Communication/ValveManager';
export { default as temp } from './src/main/ets/Communication/TempManager';
export { default as meter } from './src/main/ets/Communication/MeterManager';
export { default as optical } from './src/main/ets/Communication/OpticalManager';
export { default as event } from './src/main/ets/Communication/EventManager';
//export { default as updater } from './src/main/ets/Communication/UpdaterManager'; //未完成，下位机升级接口，等业务层移植升级功能更(U盘读取、MD5校验、Hex写入下位机)

// 2. 导出需要独立使用的包装类（仅 Valve 和 Meter 有）,以及Valve类
export type { Valve } from './src/main/ets/Communication/ValveManager';
export { ValveMap } from './src/main/ets/Communication/ValveMap';
export { MeterPoints } from './src/main/ets/Communication/MeterManager';

// 3. 【可选】如果后续定义了公共类型/枚举，在此统一导出
//导出结构体EventPack
export type { EventPack } from './src/main/ets/Communication/EventManager';
//导出温度类声明、结构体、枚举体,必须分开导出
export type { Temp, TempCalibrateFactor, Temperature, ThermostatParam } from './src/main/ets/Communication/TempManager';
export { ThermostatMode, ThermostatResult, ThermostatOperateResult } from './src/main/ets/Communication/TempManager';
//导出泵控制类声明、结构体、枚举体,必须分开导出
export type { Pump, MotionParam, PumpResult } from './src/main/ets/Communication/PumpManager';
export { PumpStatus, RollDirection, PumpOperateResult } from './src/main/ets/Communication/PumpManager';
//导出定量类声明、结构体、枚举体,必须分开导出
export type { Meter, MeterPoint } from './src/main/ets/Communication/MeterManager';
export { MeterMode, MeterResult } from './src/main/ets/Communication/MeterManager';
//导出光学类声明、结构体、枚举体,必须分开导出
export type { Optical, OpticalAD, LedParam, RefADParam, AcquiredResult } from './src/main/ets/Communication/OpticalManager';
export { AdjustResult, StaticADControlResult, AcquiredOperateResult } from './src/main/ets/Communication/OpticalManager';