// src/main/types/libcommunicationlibrary/index.d.ts
declare module 'libcommunication.so'
{
  /**
   * Dncp >>>>>>>>>>>>>>>>>>>>>通信模块接口<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
   */
  interface DncpModule
  {
    createPlugin(): void;
    addSlaveNode(nodeId: number): void;
    initDncpStack(serialPort: string, bridgeMode: boolean, bridgeIP: string): void;
  }

  /**
   * >>>>>>>>>>>>>>>>>>>>>泵模块接口<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
   * 泵接口结构体声明
   */
  export interface MotionParam
  {
    acceleration: number;
    speed: number;
  }
  export interface PumpResult
  {
    index: number;        // 产生事件的泵索引，0号泵为光学定量泵。
    result: number;         // 泵操作结果码,赋值为PumpOperateResult。
  }
  /**
   * 泵接口枚举体声明
   */
  export const enum PumpStatus
  {
    Idle = 0,                   ///泵空闲
    Failed = 1,                 ///泵异常
    Busy = 2,                    ///泵忙碌
  }
  export const enum RollDirection
  {
    Suck = 0,                      ///泵抽操作
    Drain = 1,                     ///泵排操作
    Empty = 2,                    //排空
  }
  export const enum PumpOperateResult
  {
    Finished = 0,                   ///泵操作正常完成
    Failed = 1,                     ///泵操作中途出现故障，未能完成
    Stopped = 2,                    ///泵操作被停止
  }
  /**
   * Pump 泵模块接口
   */
  interface PumpModule
  {
    getTotalPumps(): number;
    getPumpFactor(index: number): boolean;
    setPumpFactor(index: number, factor: number): boolean;
    getPumpStatus(index: number): PumpStatus;
    getMotionParam(index: number): MotionParam;
    setMotionParam(index: number, param: MotionParam): boolean;
    startPump(index: number, dir: RollDirection, volume: number, seep: number): boolean;
    stopPump(index: number): boolean;
    getPumpVolume(index: number): number;
    expectPumpResult(timeout: number): PumpResult;
  }

  /**
   * valve >>>>>>>>>>>>>>>>>>>>>阀模块接口<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
   */
  /**
   * ValveMap 类声明
   */
  export class ValveMap {
    constructor(data?: number); // data 是可选的 Uint32 初始化值
    setData(data: number): void;
    getData(): number;
    setOn(index: number): void;
    setOff(index: number): void;
    isOn(index: number): boolean;
    clear(): void;
    setSpinValveCmd(cmd: number, Param1: number, Param2: number): void;
    getCmd(): number;      // uint8_t → number
    getParam1(): number;   // uint8_t → number
    getParam2(): number;   // uint8_t → number
    getIndex(): number;    // Uint32 → number
  }
  /**
   * 阀接口函数声明
   */
  interface ValveModule
  {
    getTotalValves(): number;
    getValveMap(): ValveMap;
    setValveMap(map: ValveMap): boolean;
    ctrlSpinValve(map: ValveMap): boolean;
    SetValve16(isOpen: boolean): boolean;
    setCheckLeakingPeriod(period: number): boolean;

    // ValveMap: typeof ValveMap; // 暴露构造函数，允许 new communication.valve.ValveMap()
  }

  /**
   * temp >>>>>>>>>>>>>>>>>>>>>温度模块接口<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
   */
  /**
   * 温度接口结构体声明
   */
  export interface Temperature
  {
    thermostatTemp: number;     // 恒温室温度，单位为摄氏度
    environmentTemp: number;    // 环境温度，单位为摄氏度
  }
  export interface ThermostatParam
  {
    proportion: number;     // PID的比例系数
    integration: number;    // PID的积分系数
    differential: number;   // PID的微分系数
  }
  export interface TempCalibrateFactor
  {
    negativeInput: number;           ///<负输入分压
    referenceVoltage: number;        ///<参考电压
    calibrationVoltage: number;      ///<校准电压
  }
  export interface  ThermostatResult
  {
    result: number;     // 恒温操作结果。
    temp: number;       // 当前温度。
    index: number;      // 恒温器索引
  }
  /**
   * 温度接口枚举体声明
   */
  export const enum ThermostatMode
  {
    Auto = 0,           ///< 自动模式，根据需要及硬件能力综合使用加热器和制冷器。
    Heater = 1,         ///< 纯加热模式，不使用制冷器。
    Refrigerate= 2,     ///< 纯制冷模式，不使用加热器。
    Natural = 3         ///< 自然模式，加热器和制冷器都不参与，靠环境传递热量，自然升温或冷却。
  }
  export const enum ThermostatOperateResult
  {
    Reached = 0,    // 恒温目标达成，目标温度在规定时间内达成，后续将继续保持恒温，直到用户停止。
    Failed = 1,     // 恒温中途出现故障，未能完成。
    Stopped= 2,     // 恒温被停止。
    Timeout= 3      // 恒温超时，指定时间内仍未达到目标温度。
  }
  /**
   * 温度接口函数声明
   */
  interface TempModule
  {
    getCalibrateFactor(): TempCalibrateFactor;
    setCalibrateFactor(factor: TempCalibrateFactor): boolean;
    getTemperature(): Temperature;
    getThermostatParam(): ThermostatParam;
    setThermostatParam(param: ThermostatParam): boolean;
    getThermostatStatus(): number;
    startThermostat(mode: ThermostatMode, targetTemp: number, toleranceTemp: number, timeout: number): boolean;
    stopThermostat(): boolean;
    setTemperatureNotifyPeriod(period: number): boolean;
    expectThermostat(timeout: number): ThermostatResult;
    boxFanSetOutput(level: number): boolean;
    digestionFanSetOutput(level: number): boolean;
    getHeaterMaxDutyCycle(): number;
    setHeaterMaxDutyCycle(level: number): boolean;
    getCurrentThermostatParam(): ThermostatParam;
    setCurrentThermostatParam(param: ThermostatParam): boolean;
    turnOnRays(): boolean;
    turnOffRays(): boolean;
    boxFanSetMode(index: number, mode: number, temp: number): boolean;
  }

  /**
   * meter >>>>>>>>>>>>>>>>>>>>>定量模块接口<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
   */
  /**
   * @brief 光学定量模式。
   * @details
   */
  export const enum MeterMode
  {
    Accurate = 0,           ///精准定量模式，精准定量到指定体积的定量点。
    Direct = 1,             ///直接定量模式，泵只向一个方向启动一次便可完成定量
    Smart = 2,              ///智能定量模式，结合定量点和泵计步综合定量出任意体积。
    Ropiness = 3,           ///粘稠定量模式，精准定量到指定体积的定量点，用于浓硫酸定量。
    Layered = 4,            ///分层液体定量模式，基础为粘稠定量模式，但增加AD需高于一定值的结果判定条件。
    Calibration = 5,      ///泵系数校准，自动更新泵系数
  }
  /**
   * @brief 定量操作结果。
   * @details
   */
  export const enum MeterResult
  {
    Finished = 0,       ///定量正常完成。
    Failed = 1,         ///定量中途出现故障，未能完成。
    Stopped = 2,        ///定量被停止。
    Overflow = 3,       ///定量溢出。
    Unfinished = 4,     ///定量目标未达成。
  }

  /**
   * @brief 光学定量点体积。
   * @details
   */
  export interface  MeterPoint
  {
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
   * MeterModule 函数声明
   */
  interface MeterModule
  {
    turnOnLED(num: number): boolean;
    turnOffLED(num: number): boolean;
    getPumpFactor(): number;
    setPumpFactor(factor: number): boolean;
    getMeterPoints(): MeterPoints;
    setMeterPoints(param: MeterPoints): boolean;
    getMeterStatus(): number;
    startMeter(dir: RollDirection, mode: MeterMode, vol: number, litVol: number);
    stopMeter(): boolean;
    isAutoCloseValve(status: boolean): boolean;
    setOpticalADNotifyPeriod(perido: number);
    expectMeterResult(timeout: number): MeterResult;
    setMeteSpeed(speed: number): boolean;
    getMeteSpeed(): number;
    setMeterFinishValveMap(map: number): boolean;
    getSingleOpticalAD(): number;
    setRopinessMeterOverValue(cnt: number): boolean;
    getRopinessMeterOverValue(): number;
    getMeterEndPointOverCount(): number;
    setMeterEndPointOverCount(cnt: number): boolean;
  }

  /**
   * optical >>>>>>>>>>>>>>>>>>>>>光学模块接口<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
   */
  /**
   * @brief LED调节结果。
   */
  export const enum AdjustResult
  {
    Finished = 0,     ///< LED调节正常完成。
    Failed = 1,       ///<LED调节中途出现故障，未能完成。
    Stopped = 2,      ///<LED调节被停止。
    Timeout = 3           ///< LED调节超时，指定时间内仍未达到目标AD。
  }

  /**
   * @brief 静态AD调节控制结果。
   */
  export const enum StaticADControlResult
  {
    Unfinished = 0,       ///<静态AD调节未完成。
    Finished = 1,     ///<  静态AD调节完成。
  }

  /**
   * @brief 光学信号采集的AD值。
   * @details
   */
  export interface OpticalAD
  {
    reference: number;                ///光学信号采集的参考AD值
    measure: number;                  ///光学信号采集的测量AD值
  }

  /**
   * @brief 光学信号采集结果码。
   * @details
   */
  export const enum AcquiredOperateResult
  {
    Finished = 0,                   ///采集正常完成。
    Failed = 1,                     ///采集中途出现故障，未能完成。
    Stopped = 2,                     ///采集被停止。
  }

  /**
   * @brief 光学信号采集的结果。
   * @details
   */
  export interface AcquiredResult
  {
    ad: OpticalAD;
    result: number;         // 泵操作结果码,赋值为AcquiredOperateResult
  }

  /**
   * @brief LED控制参数。
   * @details
   */
  export interface LedParam
  {
    proportion: number;     // PID的比例系数
    integration: number;    // PID的积分系数
    differential: number;   // PID的微分系数
  }

  /**
   * @brief 参考AD固定调节参数。
   * @details
   */
  export interface RefADParam
  {
    target: number;
    tolorance: number;
    timeout: number;
  }

  interface OpticalModule
  {
    turnOnLED(): boolean;
    setAcquireADNotifyPeriod(period: number): boolean;
    startAcquirer(time: number): boolean;
    stopAcquirer(): number;
    startLEDController(): number;
    turnOffLED(): number;
    getLEDControllerTarget(): number;
    setLEDControllerTarget(value: number): boolean;
    startLEDOnceAdjust(target: number, tolerance: number, timeout: number): boolean;
    stopLEDOnceAdjust(): boolean;
    getLEDControllerParam(): LedParam;
    setLEDControllerParam(param: LedParam): boolean;
    startStaticADControl(index: number, target: number);
    stopStaticADControl(): boolean;
    getStaticADControlParam(): number;
    setStaticADControlParam(index: number, value: number): boolean;
    isStaticADControlValid(): boolean;
    getLEDDefaultValue(): number;
    setLEDDefaultValue(value: number): boolean;
    setStaticADGain(gain: number): boolean;
    expectADAcquirer(timeout: number): AcquiredResult;
    expectLEDOnceAdjust(timeout: number): AdjustResult;
    expectStaticADControlResult(timeout: number): StaticADControlResult;
  }

  /**
   * @brief 事件包定义。
   * @details
   */
  // 首先，为每种事件定义其载荷接口
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

  // ... 其他事件类型 ...

  // 这就是新的 EventPack 类型！
  type EventPack = TemperatureEvent | OpticalEvent | MeterEvent | LeakingEvent/* | ... */;
  //事件注册接口
  interface EventModule {
    // ... 其他接口 ...
    setOnPT63EventCallback(callback: (event: EventPack) => void): void;
  }
    /**
   * 整个 native 模块的默认导出对象
   */
  const communication:
  {
    dncp: DncpModule;
    pump: PumpModule;
    valve: ValveModule;
    temp: TempModule;
    meter: MeterModule;
    optical: OpticalModule;
    event: EventModule;
  }
  export default communication;
}