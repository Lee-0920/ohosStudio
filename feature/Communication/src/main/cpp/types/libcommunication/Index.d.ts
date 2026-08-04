/**
 * Pump >>>>>>>>>>>>>>>>>>>>>泵模块接口<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
 */
export interface MotionParam {
    acceleration: number;
    speed: number;
}

export interface PumpResult {
    index: number;
    result: number;
}

export const enum PumpStatus {
    Idle = 0,
    Failed = 1,
    Busy = 2,
}

export const enum RollDirection {
    Suck = 0,
    Drain = 1,
    Empty = 2,
}

export const enum PumpOperateResult {
    Finished = 0,
    Failed = 1,
    Stopped = 2,
}

/**
 * Valve >>>>>>>>>>>>>>>>>>>>>阀模块接口<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
 */
/**
 * ValveMap 类声明
 */
// Sendable 数据容器的形状（供 NAPI 函数参数类型检查）
@Sendable
export declare class ValveMap {
    data: number;
    cmd: number;
    param1: number;
    param2: number;
    index: number;
}

/**
 * Temp >>>>>>>>>>>>>>>>>>>>>温度模块接口<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
 */
export interface Temperature {
    thermostatTemp: number;
    environmentTemp: number;
}

export interface ThermostatParam {
    proportion: number;
    integration: number;
    differential: number;
}

export interface TempCalibrateFactor {
    negativeInput: number;
    referenceVoltage: number;
    calibrationVoltage: number;
}

export interface ThermostatResult {
    result: number;
    temp: number;
    index: number;
}

export const enum ThermostatMode {
    Auto = 0,
    Heater = 1,
    Refrigerate = 2,
    Natural = 3,
}

export const enum ThermostatOperateResult {
    Reached = 0,
    Failed = 1,
    Stopped = 2,
    Timeout = 3,
}

/**
 * Meter >>>>>>>>>>>>>>>>>>>>>定量模块接口<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
 */
export const enum MeterMode {
    Accurate = 0,
    Direct = 1,
    Smart = 2,
    Ropiness = 3,
    Layered = 4,
    Calibration = 5,
}

export const enum MeterResult {
    Finished = 0,
    Failed = 1,
    Stopped = 2,
    Overflow = 3,
    Unfinished = 4,
}

export interface MeterPoint {
    setVolume: number;
    realVolume: number;
}
/**
 * MeterPoints 类声明
 */
export class MeterPoints {
    constructor(data?: number); // data 是可选的 Uint32 初始化值
    setNum(data: number): void;
    getNum(): number;
    setPoint(index: number, point: MeterPoint): void;
    getPoint(): MeterPoint;
}

/**
 * Optical >>>>>>>>>>>>>>>>>>>>>光学模块接口<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
 */
export const enum AdjustResult {
    Finished = 0,
    Failed = 1,
    Stopped = 2,
    Timeout = 3,
}

export const enum StaticADControlResult {
    Unfinished = 0,
    Finished = 1,
}

export interface OpticalAD {
    reference: number;
    measure: number;
}

export const enum AcquiredOperateResult {
    Finished = 0,
    Failed = 1,
    Stopped = 2,
}

export interface AcquiredResult {
    ad: OpticalAD;
    result: number;
}

export interface LedParam {
    proportion: number;
    integration: number;
    differential: number;
}

export interface RefADParam {
    target: number;
    tolorance: number;
    timeout: number;
}

/**
 * Event >>>>>>>>>>>>>>>>>>>>>事件模块接口<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
 */
interface TemperatureEvent {
    type: 'TEMPERATURE';
    thermostatTemp: number;
    environmentTemp: number;
}

interface OpticalEvent {
    type: 'OPTICAL';
    reference: number;
    measure: number;
}

interface MeterEvent {
    type: 'METER';
    point1: number;
    point2: number;
}

interface LeakingEvent {
    type: 'LEAKING';
    value: number;
}

export type EventPack = TemperatureEvent | OpticalEvent | MeterEvent | LeakingEvent;

/**
 * ============================================================================
 *  原生 NAPI 平铺式函数声明
 *  【注意】命名空间名称必须与 .so 文件名一致 (libcommunication.so -> communication)
 * ============================================================================
 */
// 【关键】命名空间名称必须与 .so 文件名完全一致（去掉 lib 前缀和 .so 后缀）
// 即 libcommunication.so -> communication
declare namespace communication {
    // dncp 模块（对应 C++ 中的 dncp_xxx）
    function dncp_createPlugin(): void;
    function dncp_addSlaveNode(nodeId: number): void;
    function dncp_initDncpStack(serialPort: string, bridgeMode: boolean, bridgeIP: string,  onStatusChanged: (pollingAddr: number, status: boolean) => void): void;
    function dncp_doProxy(): void;
    function dncp_startSignalUpload(): void;
    function dncp_stopSignalUpload(): void;
    function dncp_isConnected(addr: number): boolean;

    // ==================== Pump 模块 ====================
    function pump_getTotalPumps(): number;
    function pump_getPumpFactor(index: number): number;
    function pump_setPumpFactor(index: number, factor: number): boolean;
    function pump_getPumpStatus(index: number): PumpStatus;
    function pump_getMotionParam(index: number): MotionParam;
    function pump_setMotionParam(index: number, param: MotionParam): boolean;
    function pump_startPump(index: number, dir: RollDirection, volume: number, seep: number): boolean;
    function pump_stopPump(index: number): boolean;
    function pump_getPumpVolume(index: number): number;
    function pump_expectPumpResult(timeout: number): PumpResult;

    // ==================== Valve 模块 ====================
    // /**
    //  * ValveMap 类声明
    //  */
    function valveMap_initValveMap(map: ValveMap, initData: number): void;
    function valveMap_setData(map: ValveMap, data: number): void;
    function valveMap_getData(map: ValveMap): number;
    function valveMap_setOn(map: ValveMap, index: number): void;
    function valveMap_setOff(map: ValveMap, index: number): void;
    function valveMap_isOn(map: ValveMap, index: number): boolean;
    function valveMap_clear(map: ValveMap): void;
    function valveMap_setSpinValveCmd(map: ValveMap, cmd: number, p1: number, p2: number): void;
    function valve_getTotalValves(): number;
    function valve_getValveMap(): ValveMap;
    function valve_setValveMap(map: ValveMap): boolean;
    function valve_ctrlSpinValve(map: ValveMap): boolean;
    function valve_setValve16(isOpen: boolean): boolean;
    function valve_setCheckLeakingPeriod(period: number): boolean;

    // ==================== Temp 模块 ====================
    function temp_getCalibrateFactor(): TempCalibrateFactor;
    function temp_setCalibrateFactor(factor: TempCalibrateFactor): boolean;
    function temp_getTemperature(): Temperature;
    function temp_getThermostatParam(): ThermostatParam;
    function temp_setThermostatParam(param: ThermostatParam): boolean;
    function temp_getThermostatStatus(): number;
    function temp_startThermostat(mode: ThermostatMode, targetTemp: number, toleranceTemp: number, timeout: number): boolean;
    function temp_stopThermostat(): boolean;
    function temp_setTemperatureNotifyPeriod(period: number): boolean;
    function temp_expectThermostat(timeout: number): ThermostatResult;
    function temp_boxFanSetOutput(level: number): boolean;
    function temp_digestionFanSetOutput(level: number): boolean;
    function temp_getHeaterMaxDutyCycle(): number;
    function temp_setHeaterMaxDutyCycle(level: number): boolean;
    function temp_getCurrentThermostatParam(): ThermostatParam;
    function temp_setCurrentThermostatParam(param: ThermostatParam): boolean;
    function temp_turnOnRays(): boolean;
    function temp_turnOffRays(): boolean;
    function temp_boxFanSetMode(index: number, mode: number, temp: number): boolean;

    // ==================== Meter 模块 ====================
    function meter_turnOnLED(num: number): boolean;
    function meter_turnOffLED(num: number): boolean;
    function meter_getPumpFactor(): number;
    function meter_setPumpFactor(factor: number): boolean;
    function meter_getMeterPoints(): MeterPoints;
    function meter_setMeterPoints(param: MeterPoints): boolean;
    function meter_getMeterStatus(): number;
    function meter_startMeter(dir: RollDirection, mode: MeterMode, vol: number, litVol: number): boolean;
    function meter_stopMeter(): boolean;
    function meter_isAutoCloseValve(status: boolean): boolean;
    function meter_setOpticalADNotifyPeriod(period: number): void;
    function meter_expectMeterResult(timeout: number): MeterResult;
    function meter_setMeteSpeed(speed: number): boolean;
    function meter_getMeteSpeed(): number;
    function meter_setMeterFinishValveMap(map: number): boolean;
    function meter_getSingleOpticalAD(num: number): number;
    function meter_setRopinessMeterOverValue(cnt: number): boolean;
    function meter_getRopinessMeterOverValue(): number;
    function meter_getMeterEndPointOverCount(): number;
    function meter_setMeterEndPointOverCount(cnt: number): boolean;

    // ==================== Optical 模块 ====================
    function optical_turnOnLED(): boolean;
    function optical_setAcquireADNotifyPeriod(period: number): boolean;
    function optical_startAcquirer(time: number): boolean;
    function optical_stopAcquirer(): number;
    function optical_startLEDController(): number;
    function optical_turnOffLED(): number;
    function optical_getLEDControllerTarget(): number;
    function optical_setLEDControllerTarget(value: number): boolean;
    function optical_startLEDOnceAdjust(target: number, tolerance: number, timeout: number): boolean;
    function optical_stopLEDOnceAdjust(): boolean;
    function optical_getLEDControllerParam(): LedParam;
    function optical_setLEDControllerParam(param: LedParam): boolean;
    function optical_startStaticADControl(index: number, target: number): void;
    function optical_stopStaticADControl(): boolean;
    function optical_getStaticADControlParam(): number;
    function optical_setStaticADControlParam(index: number, value: number): boolean;
    function optical_isStaticADControlValid(): boolean;
    function optical_getLEDDefaultValue(): number;
    function optical_setLEDDefaultValue(value: number): boolean;
    function optical_setStaticADGain(gain: number): boolean;
    function optical_expectADAcquirer(timeout: number): AcquiredResult;
    function optical_expectLEDOnceAdjust(timeout: number): AdjustResult;
    function optical_expectStaticADControlResult(timeout: number): StaticADControlResult;

    // ==================== Event 模块 ====================
    function event_setOnPT63EventCallback(callback: (event: EventPack) => void): void;
}

// 【关键】必须有 export 语句，否则 TS 不认为这是一个模块
export default communication;