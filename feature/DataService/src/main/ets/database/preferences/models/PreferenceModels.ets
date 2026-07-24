// database/preferences/models/PreferenceModels.ets
/**
 * 偏好型数据库数据模型定义
 * 包含所有配置项的类型定义和枚举
 */

// ==================== 枚举定义====================

export enum RelayOut {
  UpLimit = 0,                        // 上限
  LowLimit = 1,                       // 下限
  MeasureInstruct = 2,                // 测量指令
  CalibrateInstruct = 3,              // 校准指令
  CleanInstruct = 4,                  // 清洗指令
}

export enum ReportMode {
  OnLine = 0,                         // 在线
  OffLine = 1,                        // 离线
  Maintain = 2,                       // 保养
  Fault = 3,                          // 故障
  Calibrate = 4,                      // 校准
  Debugging = 5,                      // 调试
}

export enum SettingIpMode {
  Dhcp = 0,                           // DHCP
  Static = 1,                         // 静态IP
}

export enum Language {
  SimplifiedChinese = 0,              // 简体中文
  TraditionalChinese = 1,             // 传统体中文
  English = 2,                        // 英文
}

export enum ManufactureType {
  Ls = 0,
  Oem = 1,
  Diy = 2,
}

export enum MeasureMode {
  Trigger = 0,                        // 触发
  Periodic = 1,                       // 周期
  Timed = 2,                          // 定时
  Continuous = 3,                     // 连续
  Manual = 4,                         // 手动
}

export enum CompareType {
  Eq = 0,
  Ne = 1,
  Le = 2,
  Lt = 3,
  Ge = 4,
  Gt = 5,
}

export enum TargetParam {
  Cod = 1,
  Extend = 2,
}

// ==================== 嵌套对象类型定义（独立 interface） ====================

export interface DateStruct {
  year: number;                          // 年
  month: number;                         // 月
  day: number;                           // 日
}

export interface ReagentLicense {
  enable: boolean;                       // 是否启用
  expirationDate: number;                // 过期日期
}

export interface ReactionCamera {
  volume: number;                           // 反应池体积
}

export interface MeterPointItem {
  setVolume: number;                      // 设置体积
  realVolume: number;                     // 实际体积 
}

export interface MeterPoint {
  num: number;                            // 定量点数量
  point: MeterPointItem[];                // 定量点表
}

export interface PidParamItem {
  set: number;                           // 设置值
  real: number;                          // 实际值
}

export interface ThermostatParam {
  proportion: PidParamItem;             // 比例项
  integration: PidParamItem;            // 积分项
  differential: PidParamItem;           // 微分项
}

export interface PumpFactor {
  ref: number;                           // 参考值
  real: number;                          // 实际值
}

export interface TempCalibrate {
  negativeInput: number;                 // 负输入电压
  referenceVoltage: number;              // 参考电压
  calibrationVoltage: number;            // 校准电压
}

export interface MeterLedItem {
  set: number;                           // 设置值
  real: number;                          // 实际值
}

export interface MeterLed {
  num: number;                            // 定量点数量
  maxValue: number;                       // 最大值
  point: MeterLedItem[];                  // 定量点表
}

export interface MeasureLedInner {
  set: number;                           // 设置值
  real: number;                          // 实际值
}

export interface MeasureLed {
  maxValue: number;                       // 最大值
  reference: MeasureLedInner;             // 参考值
  measure: MeasureLedInner;                 // 测量值
  targetAD: MeasureLedInner;              // 目标AD值
  ledDAC: MeasureLedInner;                // LED DAC值
}

export interface MeasureLedAd {
  reference: number;                     // 参考值
  measure: number;                         // 测量值
}

export interface CurveParam {
  curveK: number;                       // 曲线斜率
  curveB: number;                       // 曲线截距
  zeroConsistency: number;              // 零点校准液浓度
  rangeConsistency: number;             // 量程校准液浓度
  timeStr: string;                      // 校准时间
}

export interface CalibrateCheck {
  zeroCheckErrorLimit: number;          // 零点允许偏差值
  standardCheckErrorLimit: number;      // 标点允许偏差值
}

export interface TimedPointConfig {
  mode: MeasureMode;                      // 触发测量模式
  interval: number;                       // 自动测量间隔周期
  timedPoint: boolean[];                  // 整点测量配置
  oneTimedPoint?: number;                 // 整点测量时间
  timedPointInterval?: number;            // 整点测量间隔时间
  configChangeTime?: number;              // 参数修改时间
  timing?: string;                        // 定时时间
  timingTagTime?: number;                 // 定时时间
  enable?: boolean;                       // 是否开启
}

export interface RangeCheckZJ {
  lastMode: MeasureMode;                  // 浙江协议需求-上次模式
  nextStartTime: number;                  // 浙江协议需求-下次启动时间
}

export interface RangeCheckTimedConfig extends TimedPointConfig {
  ZJ?: RangeCheckZJ;                      // 浙江协议需要存储的信息
}

export interface CalibrateTimedConfig extends TimedPointConfig {
  enable: boolean;                        // 是否开启
}

export interface StandardTimedConfig extends TimedPointConfig {
  enable: boolean;                        // 是否开启
}

export interface CleanConfig {
  enable: boolean;                        // 是否开启
  interval: number;                       // 间隔周期
}

export interface SimpleIntervalConfig {
  enable: boolean;                        // 是否开启
  interval: number;                       // 间隔周期
}

export interface ScreenSaver {
  enable: boolean;                      // 是否开屏保
  darkTime: number;                     // 暗屏时间
  offTime: number;                      // 关屏时间
  loginKeepingTime: number;             // 用户退出时间
}

export interface AdcDetectItem {
  enable: boolean;                      // 漏液检测/测量触发
}

export interface TargetMapItem {
  enable: boolean;                      // 是否开启
  num: number;                          // 定量点数量
}

export interface RangeViewMapItem {
  range: number;                        // 量程
  view: number;                         // 界面显示量程
}

export interface PrinterConfig {
  enable: boolean;                      // 打印机使能
  address: string;                      // 打印机地址
  autoPrint: boolean;                   // 自动打印
}

export interface Hj212Platform {
  hj212DataType: number;
  status: boolean;                      // 连接平台
  address: string;                      // 212平台IP
  port: string;                         // 212平台端口
  mn: string;                           // 编码
  pw: string;                           // 密码
  st: string;                           // 编码
  respond: boolean;                     // 应答
  heartPackTime: number;                // 心跳间隔(单位分钟，<=0表示不发)
  overtime: number;                     // 超时时间(单位分钟)
  recount: number;                      // 重传次数
  hj212CommunicationMode: number;       // 0:232 1:485 2:TCP
  hj212Type: number;                    // 0:None 1: 2017DBS 2: 2017WRY
}

export interface ValveSetting {
  sample: number;                        // 样本阀
  standard: number;                      // 标准阀
  blank: number;                         // 空白阀
  digestionRoom: number[];               // 消化室阀
  wasteWater: number;                    // 废水阀
  waste: number;                         // 废料阀
  reagent1: number;                      // 标准液1
  reagent2: number;                      // 标准液2
  zeroCheck: number;                     // 零点校准液浓度
  rangeCheck: number;                    // 量程校准液浓度
}

export interface RemainItem {
  total: number;                         // 总剩余量
  cycle: number;                         // 每次剩余量
  lastTime: number;                      // 上次测量时间
}

export interface MeasureReportItem {
  dateTime: number;                       // 测量日期
  consistency: number;                    // 4-20输出浓度
  resultType?: number;                    // 测量类型
  measureTime?: number;                   // 测量时长
  absorbance?: number;                    // 吸光度
  deviceTypeNum?: number;                 // 设备参数类型号
  oldTypeNum?: number;                    // 旧设备参数类型号
  resultInfo?: string;                    // 数据标识
}

export interface RangeCheckReportItem extends MeasureReportItem {
  checkError: number;                     // 偏差值
}

export interface QualityHandleReportItem extends MeasureReportItem {
  checkError: number;                     // 偏差值
}

export interface MeasureOfflineItem {
  dateTime: number;                       // 测量日期
  consistency: number;                    // 4-20输出浓度
  resultType?: number;                    // 测量类型
  measureTime?: number;                   // 测量时长
  absorbance?: number;                    // 吸光度
  deviceTypeNum?: number;                 // 设备参数类型号
  oldTypeNum?: number;                    // 旧设备参数类型号
  resultInfo: string;                     // 数据标识
}

export interface ProformaResultMeasure {
  dateTime: number;                       // 测量日期
  consistency: number;                    // 测量浓度
  absorbance: number;                     // 吸光度
  blankReference: number;                 // 空白参考AD值
  blankMeasure: number;                   // 空白测量AD值
  initReference: number;                  // 初始参考AD值
  initMeasure: number;                    // 初始测量AD值
  finalReference: number;                 // 显色参考AD值
  finalMeasure: number;                   // 显色测量AD值
}

export interface NewResultMain {
  dateTime: number;                       // 测量日期
  resultType: number;                     // 测量类型
  consistency: number;                    // 测量浓度
}

// 最新使用的测量结果
export interface NewResultMeasure {
  dateTime: number;                       // 测量日期
  endDateTime: number;                    // 测量结束时间
  errorDateTime: number;                  // 流程错误日期
  consistency: number;                    // 测量浓度
  resultType: number;                     // 测量类型
  absorbance: number;                     // 吸光度
  resultInfo: string;                     // 数据标识
  resultMark: string;                     // 数据标识(兼容初版地表水协议)
  isUseStart: boolean;                    // 是否为用户手动启动
  isFault: boolean;                       // 流程是否出错
  resultMarkC: number;                    // 结果标识(扩展核查和校准)
}

// 最新使用的校准结果
export interface NewResultCalibrate {
  dateTime: number;                       // 测量日期
  curveB: number;                         // 曲线截距
  curveK: number;                         // 曲线斜率
  point0Consistency: number;              // 零点浓度
  point1Consistency: number;              // 标点浓度
  point0Absorbance: number;               // 零点吸光度值
  point1Absorbance: number;               // 标点吸光度值
  zeroCalculateConsistency: number;       // 零点计算浓度
  standardCalculateConsistency: number;   // 标点计算浓度
  zeroCheckError: number;                 // 零点偏差
  standardCheckError: number;             // 标点偏差
  r2: number;
  zeroCalibrateDateTime: number;          // 零点校准时间
  standardCalibrateDateTime: number;      // 量程校准时间
}

export interface CalibrateItem {
  dateTime: number;                       // 测量日期
  curveB: number;                         // 曲线截距
  curveK: number;                         // 曲线斜率
  point0Consistency: number;              // 零点浓度
  point1Consistency: number;              // 标点浓度
  point0Absorbance: number;               // 零点吸光度值
  point1Absorbance: number;               // 标点吸光度值
  zeroCalculateConsistency: number;       // 零点计算浓度
  standardCalculateConsistency: number;   // 标点计算浓度
  zeroCheckError: number;                 // 零点偏差
  standardCheckError: number;             // 标点偏差
  r2: number;
  zeroCalibrateDateTime: number;          // 零点校准时间
  standardCalibrateDateTime: number;      // 标点校准时间
  userSettings: boolean;                  // 当前使用状态
}

// 流程名称，流程时间(三次累加/3)，异常是否停机，重要参数(参数变化则不检查)
export interface MeasurerSaveTimeItem {
  name: string;                           // 流程名称
  time1: number;                          // 流程时间1
  time2: number;                          // 流程时间2
  time3: number;                          // 流程时间3
  isBlocking: boolean;                    // 异常是否停机
  checkParam: number;                     // 重要参数(参数变化则不检查)
}

export interface MeasurerTimeItem {
  name: string;                           // 流程名称
  time1: number;                          // 流程时间1
  time2: number;                          // 流程时间2
}

// ==================== 测量状态中的 schedule 子项 ====================

export interface ScheduleAutoItem {
  dateTime: number;                       // 测量日期
}

export interface ScheduleZeroCheckItem {
  dateTime: number;                       // 核查日期
}

export interface ScheduleRangeCheckItem {
  dateTime: number;                       // 核查日期
}

export interface ScheduleAutoCalibrateItem {
  dateTime: number;                       // 校准日期
}

export interface ScheduleAutoCleanItem {
  dateTime: number;                       // 清洗日期
}

export interface ScheduleAutoBlankCheckItem {
  dateTime: number;                       // 测零点校准液日期
}

export interface ScheduleAutoCheckItem {
  dateTime: number;                       // 核查日期
}

export interface ScheduleAutoAddStandardItem {
  dateTime: number;                       // 核查日期
}

export interface ScheduleAutoParallelItem {
  dateTime: number;                       // 核查日期
}

export interface MeasureStatusSchedule {
  autoMeasure: ScheduleAutoItem;          // 自动测量
  zeroCheck: ScheduleZeroCheckItem;        // 零点校准
  rangeCheck: ScheduleRangeCheckItem;       // 量程校准
  autoCalibrate: ScheduleAutoCalibrateItem; // 自动校准
  autoClean: ScheduleAutoCleanItem;        // 自动清洗
  autoBlankCheck: ScheduleAutoBlankCheckItem; // 自动零点校准
  autoCheck: ScheduleAutoCheckItem;        // 自动核查
  autoAddStandard: ScheduleAutoAddStandardItem; // 自动添加标准液
  autoParallel: ScheduleAutoParallelItem;    // 自动并行核查
}

export interface MeasureStatusReport {
  measure: MeasureReportItem;              // 测量报告
  addStandard: MeasureReportItem;          // 添加标准液报告
  parallel: MeasureReportItem;             // 并行核查报告
  check: MeasureReportItem;                // 核查报告
  blankCheck: MeasureReportItem;           // 零点校准液报告
  zeroCheck: MeasureReportItem;            // 零点校准报告
  rangeCheck: RangeCheckReportItem;        // 量程校准报告
  qualityHandle: QualityHandleReportItem;  // 质量处理报告
  complexResult: MeasureReportItem;        // 复杂结果报告
}

export interface MeasureStatusOffline {
  measure: MeasureOfflineItem;             // 测量报告
  addStandard: MeasureOfflineItem;         // 添加标准液报告
  parallel: MeasureOfflineItem;            // 并行核查报告
  check: MeasureOfflineItem;               // 核查报告
  blankCheck: MeasureOfflineItem;          // 零点校准液报告
  zeroCheck: MeasureOfflineItem;           // 零点校准报告
  rangeCheck: MeasureOfflineItem;          // 量程校准报告
  qualityHandle: MeasureOfflineItem;       // 质量处理报告
}

export interface MeasureStatusProformaResult {
  measure: ProformaResultMeasure;            // 测量报告
}

export interface MeasureStatusNewResult {
  mainResult: NewResultMain;               // 主结果
  measure: NewResultMeasure;                 // 测量报告
  calibrate: NewResultCalibrate;           // 校准报告
}

// ==================== 顶层配置接口定义 ====================

export interface InstrumentInfoConfig {
  model: string;                          // 型号(产品确定后部可更改)
  manuDate: DateStruct;                   // 生产日期
  type: string;                           // 类型
  manufacturer: string;                   // 生产厂商
  MfrN: string;                           // 生产厂商编号
  uuid: string;                           // UUID
  sn: string;                             // 序列号
  reagentLicense: ReagentLicense;         // 试剂授权
  expirationDate: number;                 // 有效期截止时间
  license: boolean;                       // 是否有许可证
  permanent: boolean;                     // 是否永久授权   
  manufactureType: ManufactureType;       // 0-LS 1-OEM 2-DIY
  showModel: string;                      // 显示型号(可定制显示)
  showName: string;                       // 显示名称
}

export interface MainBoardInfoConfig {
  manufacturer: string;                   // 生产厂商
  sn: string;                             // 序列号
  type: string;                           // 类型
  manuDate: DateStruct;                   // 生产日期
  model: string;                          // 型号
}

export interface GainCalibrateValue {
  set: number;  // 设置值
  real: number; // 实际值
}

export interface Gain {
  reference: GainCalibrateValue; // 参考通道增益
  measure: GainCalibrateValue;   // 测量通道增益
}

export interface GainCalibrate {
  maxValue: number; // 最大值
  gain: Gain;       // 测量增益
}

export interface HardwareConfig {
  reactionCamera: ReactionCamera;          // 反应容器
  meterPoint: MeterPoint;                  // 定量管位置
  thermostatParam: ThermostatParam;      // 温控参数
  pumpFactor: PumpFactor;                  // 泵系数
  tempCalibrate: TempCalibrate;            // 温度校准
  meterLed: MeterLed;                      // 定量管LED
  measureLed: MeasureLed;                  // 测量LED
  gainCalibrate: GainCalibrate;   // 增益校准配置
}

export interface InterconnectionConfig {
  alarmValue: boolean;                    // 报警
  outputType: number;                     // 输出参数类型(单参数默认0)
  meaUpLimit: number;                     // 测量上限
  meaLowLimit: number;                    // 测量下限
  overProofResultMark: number;            // 超上限标识
  rangeCheckResultMark: number;           // 核查标识
  overProofAutoCheck: boolean;            // 超标启动核查
  connectAddress: number;                 // 通信地址
  rs485BaudRate: number;                  // RS485传输速率
  rs485Parity: number;                    // RS485校验位
  rs232BaudRate: number;                  // RS232传输速率
  rs232Parity: number;                    // RS232校验位
  sampleLowLimit: number;                 // 水样4-20浓度下限
  sampleUpLimit: number;                  // 水样4-20浓度上限
  currentFactor: number;                  // 4-20校准系数
  collectSampleMode: number;              // 采水模式
  miningWaterTime: number;                // 采水时间
  silentTime: number;                     // 静默时间
  relayOne: number;                       // 继电器1
  relayTwo: number;                       // 继电器2
  reportMode: ReportMode;                 // 上报模式
  settingIpMode: SettingIpMode;           // 设置IP模式
}

export interface MeasureParamConfig {
  currentRange: number;                     // 当前量程（三量程）
  calibrateRangeIndex: number;              // 校准
  zeroCheckRangeIndex: number;              // 零点核查量程
  rangeCheckRangeIndex: number;             // 标样(跨度)核查量程
  range: number[];                          // 量程

  //当前量程数据
  timeStr: string;                  // 当前量程校准时间
  zeroConsistency: number;          // 当前量程零点校准液浓度
  rangeConsistency: number;         // 当前量程量程校准液浓度
  curveK: number;                   // 当前量程曲线斜率
  curveB: number;                   // 当前量程曲线截距
  currentRangeIndex: number;        // 当前量程索引

  autoChangeRange: boolean;         // 量程自动切换
  activeRangeMode: number;          // 量程自动切换后生效模式
  highClMode: boolean;              // 高氯模式
  digestTemperature: number;        // 消解温度
  digestTime: number;               // 消解时间
  reactTemperature: number;         // 显色温度
  reactTime: number;                // 显色时间
  digestAirPumpingTemp: number;     // 鼓气温度
  temperatureIncrement: number;     // 温度增量
  negativeRevise: boolean;          // 负值修正
  reviseFactor: number;             // 修正因子
  shiftFactor: number;              // 平移因子
  meterLedAD: number[];             // 定量管LED AD
  measureLedAD: MeasureLedAd;       // 测量LED AD
  pidCtrl: boolean;                 // PID调光
  calibratePointConsistency: number[];  // 标定浓度
  range2StandardConsistency: number;    // 量程二校正液浓度
  range3StandardConsistency: number;    // 量程三校正液浓度
  range4StandardConsistency: number;    // 量程4校正液浓度
  range5StandardConsistency: number;    // 量程5校正液浓度
  range6StandardConsistency: number;    // 量程6校正液浓度
  range7StandardConsistency: number;    // 量程7校正液浓度
  cleanBefMeaBlankVol: number;          // 测量前清洗，零点校准液体积
  cleanAftMeaBlankVol: number;          // 测量后清洗，零点校准液体积
  sampleSoakExtendVol: number;          // 水样浸润延长体积
  deepCleanBefCalibrate: boolean;       // 校准前深度清洗
  wasteWaterEnvironment: boolean;       // 污水环境
  tapWaterEnvironment: boolean;         // 自来水环境
  ignoreSampleAssertion: boolean;       // 忽略水样检测
  cleanSampleVol: number;               // 加完水样后，零点校准液清洗水样管体积
  extendSamplePipeVolume: number;       // 水样管延长体积
  sampleRenewVolume: number;            // 样品更新体积
  zeroAccurateCalibrate: boolean;       // 零点精准校准
  standardAccurateCalibrate: boolean;   // 标点精准校准
  rangeAccurateCalibrate: boolean;      // 量程精准校正
  calibrateMarkOutput: boolean;
  curveQualifiedDetermination: boolean; // 标线合格判定
  rangeCalibrateDeviation: number;      // 量程精准校正偏差阈值
  checkConsistency: number;             // 标样核查浓度
  checkErrorLimit: number;              // 标样核查偏差限值
  checkReporting: boolean;
  failAutoRevise: boolean;              // 核查失败自动校准
  highlyOxidized: boolean;              // 强氧化模式
  readInitRilentTime: number;           // 读空白值前静置时间
  readFinalBubbling: boolean;           // 读显色值前鼓气
  heaterMaxDutyCycle: number;           // 加热丝最大占空比
  digestionFanLevel: number;            // 消解风扇功率等级
  addCalibrateRecord: boolean;          // 定标时是否输出零点与标点结果(使用旧标线计算结果)
  updateAllCalibrateKB: boolean;        // 定标更新所有曲线

  curveParam: CurveParam[];             // 曲线参数  
  reviseParameter: number[];            // 配置-内部校正参数  
  excursionSample: number[];            // 配置-水样偏差  
  diluteFactor: number[];               // 配置-稀释系数
  measureDataOffsetValve: number;       // 测量数据偏移阀
  calibrateCheck: CalibrateCheck;       // 校准核查
}

export interface SchedulerConfig {
  measure: TimedPointConfig;              // 测量排期
  zeroCheck: TimedPointConfig;            // 零点核查
  rangeCheck: TimedPointConfig;      // 标样(跨度)核查
  calibrate: TimedPointConfig;        // 校准排期
  clean: TimedPointConfig;                     // 清洗排期
  blankCheck: TimedPointConfig;       // 测零点校准液
  check: TimedPointConfig;            // 测量程校准液排期
  standard: TimedPointConfig;          // 测核查液排期
  addStandard: TimedPointConfig;      // 加标排期
  parallel: TimedPointConfig;         // 平行排期
  timedPointJudgeTime: number;            // 整点启动-延长时间
}

export interface SystemTargetMap {
  Cod: TargetMapItem;                     // COD
  EXTEND: TargetMapItem;                  // 扩展
}

export interface SystemConfig {
  screenSaver: ScreenSaver;             // 屏幕设置
  adcDetect: AdcDetectItem[];           // ADC检测
  language: Language;                   // 语言
  faultBlocking: boolean;               // 故障停机
  displayProformaResult: boolean;       // 预估结果显示
  faultRetry: boolean;                  // 异常重测
  reagentLackWarn: boolean;             // 缺试剂告警
  dryFireProtection: boolean;           // 干烧保护
  drainDigestRoomCheck: boolean;        // 排液检查
  reagent2SpareValve: boolean;          // 试剂2不使用备用阀
  curveXYChange: boolean;               // 曲线XY调换
  debugMode: boolean;                   // 开发调试模式
  bridgeMode: boolean;                  // 桥接模式
  bridgeIP: string;                     // 桥接IP
  modbusTableType: number;              // Modbus表类型
  cCepMode: boolean;                    // CCEP认证模式
  solidifyMeaParamFromUI: boolean;      // 不可通过UI修改测量参数
  solidifyMeaParamFromModbus: boolean;  // 不可通过Modbus修改测量参数
  displayMeaParamInGeneral: boolean;    // 普通用户显示测量参数
  changeParamLog: boolean;              // 记录参数更改日志
  newDbsModbusLog: boolean;             // 地表水协议新日志
  useQrEncode: boolean;                 // 二维码
  serverIP: string;                     // 服务器IP
  serverPort: number;                   // 服务器端口
  serverMode: boolean;                  // 服务器模式
  targetMap: SystemTargetMap;           // 系统映射
  internationalSupported: boolean;      // 国际化支持
  standardRegister: boolean;            // 水样核查值更新
  rangeViewMap: RangeViewMapItem[];     // 量程显示映射
  printer: PrinterConfig;               // 打印机配置
  nfsAddr: string;                      // NFS地址
  nfsEnable: boolean;                   // 是否启用NFS
  hj212Platform: Hj212Platform;         // HJ212平台
  valveSetting: ValveSetting;           // 阀设置
  decimalNum: number;                   // 小数位数
  oem: number;                          // OEM
  weepingLimitValve: number;            // 排液阀
  isLoadingReagentManager: boolean;     // 是否启用试剂管理界面
  rinseSolution: number;                // 润洗液 0:废液 1:废水
  deviceStartupTime: number;            // 设备启动时间
}

export interface AuthorizationConfig {
  normalUserPassword: string;           // 普通用户密码
  maintenancePassword: string;          // 维护密码
  administratorPassword: string;        // 管理员密码
  superPassword: string;                // 管理员密码（兼容旧版超级管理员）
  usedPasswords: string[];              // 已使用密码
  usedReagentPasswords: string[];       // 已使用试剂密码
}

export interface RemainStatus {
  standard: number;                     // 标准核查值
  blank: number;                        // 空白值
  zeroCheck: number;                    // 零点核查值
  rangeCheck: number;                   // 标样(跨度)核查值
  waste: number;                        // 废液值
  wasteWater: number;                   // 100%废水值
  reagent1: number;                     // 试剂1值
  reagent2: number;                     // 试剂2值
  reagentClean: number;                 // 试剂清洗值 
}

export interface RemainConfig {
  standard: RemainItem;                 // 标准核查值
  blank: RemainItem;                    // 空白值
  zeroCheck: RemainItem;                // 零点核查值
  rangeCheck: RemainItem;               // 标样(跨度)核查值
  waste: RemainItem;                    // 废液值
  wasteWater: RemainItem;               // 100%废水值
  reagent1: RemainItem;                 // 试剂1值
  reagent2: RemainItem;                 // 试剂2值
  reagentClean: RemainItem;             // 试剂清洗值 
}

export interface PumpPipeConfig {
  cycle: number;                        // 循环时间
  lastTime: number;                     // 上一次循环时间
}

export interface ConsumableConfig {
  pumpPipe: PumpPipeConfig;             // 泵配置
}

export interface MeasureRunning {
  isMeasuring: boolean;                // 是否正常测量，用于测量过程中断电或重启后重新测量
  isCorrectStopFlow: boolean;          // 用于区分是否为掉电保护调用的停止流程
  lastMeasureTime: number;             // 上一次测量时间
}

export interface MeasureStatus {
  schedule: MeasureStatusSchedule;      // 测量计划
  report: MeasureStatusReport;            // 测量报告
  offline: MeasureStatusOffline;          // 离线状态
  proformaResult: MeasureStatusProformaResult; // 预测结果
  newResult: MeasureStatusNewResult;        // 新结果
  calibrate: CalibrateItem[];           // 校准数据-量程数据
  standardCurve: number;                // 基准曲线（最新一次完整定标的量程）
  lastMeasureEndTime: number;           // 上一次测量流程结束日期
  isDeviceFault: boolean;               // 是否设备故障
  isFatalError: boolean;                // 是否致命错误
  isUseStart: boolean;                  // 是否为用户手动启动 正在进行的流程
  digestionRoomIsBlank: boolean;        // 消解室当前液体是否为空白水
  lastMeasureFail: number;              // 上次测量是否失败 2: 排液+清洗 1:排液 0:成功
  measurerSaveTime: MeasurerSaveTimeItem[]; // 测量员保存时间
  measurerTime: MeasurerTimeItem[];       // 测量员时间
}
