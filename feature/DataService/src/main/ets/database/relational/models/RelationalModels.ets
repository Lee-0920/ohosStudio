// DataService/src/main/ets/database/models/DataModels.ets

/**
 * 字段类型枚举（对应原C++的FieldType）
 */
export enum FieldType {
  Bool = 0,
  Byte = 1,
  Int = 2,
  Float = 3,
  Double = 4,
  IntArray = 5,
  Time = 6,
  Enum = 7
}

/**
 * 测量类型枚举（对应原C++的MeasureType）
 */
export enum MeasureType {
  Blank = 0,           // 空白水
  Sample = 1,          // 水样
  Standard = 2,        // 标液
  Check = 3,           // 核查样
  AddStandard = 4,     // 加标样
  Parallel = 5,        // 平行样
  ZeroCheck = 6,       // 零点核查
  RangeCheck = 7,      // 量程核查
  ExtAddStandard = 8,  // 外部加标
  ExtParallel = 9,     // 外部平行
  QualityHandle = 10,  // 质控
  None = 255
}

/**
 * 结果标识枚举（对应原C++的mode字段）
 */
export enum ResultMode {
  Normal = 0,      // 正常N
  Offline = 1,     // 离线B
  Maintain = 2,    // 维护M
  Fault = 3,       // 故障D
  Calibrate = 4,   // 校准C
  OverRange = 5,   // 超量程T
  OverUpper = 6,   // 超上限
  Quality = 7,     // 质控K
  Debug = 8        // 调试A
}

/**
 * 校准类型枚举
 */
export enum CalibrateType {
  Zero = 0,        // 零点校准
  Span = 1,        // 量程校准
  Full = 2         // 满量程校准
}

/**
 * 校准记录数据模型（对应原C++的CalibrateRecordFile）
 * 基于 CalibrateFileFormat.ls 配置文件
 */
export class CalibrateRecord {
  id?: number;                    // 主键ID
  dateTime: number = 0;           // 校准时间戳

  // 曲线参数
  curveK: number = 0;             // 斜率（Double类型，8字节）
  curveB: number = 0;             // 截距（Double类型，8字节）

  // 0点数据
  point0InitAbsorbance: number = 0;  // 0点空白吸光度
  point0Absorbance: number = 0;      // 0点显色吸光度
  point0Consistency: number = 0;     // 0点浓度
  initReferenceAD0: number = 0;      // 0点空白参考AD
  initMeasureAD0: number = 0;        // 0点空白测量AD
  finalReferenceAD0: number = 0;     // 0点显色参考AD
  finalMeasureAD0: number = 0;       // 0点显色测量AD
  point0InitThermostatTemp: number = 0;   // 0点空白消解室温度
  point0InitEnvironmentTemp: number = 0;  // 0点空白环境温度
  point0FinalThermostatTemp: number = 0;  // 0点显色消解室温度
  point0FinalEnvironmentTemp: number = 0; // 0点显色环境温度

  // 1点数据
  point1InitAbsorbance: number = 0;  // 1点空白吸光度
  point1Absorbance: number = 0;      // 1点显色吸光度
  point1Consistency: number = 0;     // 1点浓度
  initReferenceAD1: number = 0;      // 1点空白参考AD
  initMeasureAD1: number = 0;        // 1点空白测量AD
  finalReferenceAD1: number = 0;     // 1点显色参考AD
  finalMeasureAD1: number = 0;       // 1点显色测量AD
  point1InitThermostatTemp: number = 0;   // 1点空白消解室温度
  point1InitEnvironmentTemp: number = 0;  // 1点空白环境温度
  point1FinalThermostatTemp: number = 0;  // 1点显色消解室温度
  point1FinalEnvironmentTemp: number = 0; // 1点显色环境温度

  R2: number = 0;                  // 曲线线性度
  calibrateTime: number = 0;       // 校准时长
  measureRange: number = 0;        // 量程
  rangeIndex: number = 0;           // 新增字段：量程索引
  versionString: string = "1.0.0.2";
}

/**
 * 测量记录数据模型（对应原C++的RecordData + MeasureRecordFile）
 */
export class MeasureRecord {
  id?: number;                    // 主键ID
  dateTime: number = 0;           // 测量时间戳
  consistency: number = 0;        // 浓度(mg/L)
  absorbance: number = 0;         // 吸光度(mAbs)
  mode: number = 0;               // 标识（对应ResultMode）
  resultType: number = 0;         // 类型（对应MeasureType）
  initReferenceAD: number = 0;    // 空白参考AD
  initMeasureAD: number = 0;      // 空白测量AD
  finalReferenceAD: number = 0;   // 显色参考AD
  finalMeasureAD: number = 0;     // 显色测量AD
  initThermostatTemp: number = 0; // 空白值消解室温度(℃)
  initEnvironmentTemp: number = 0;// 空白值环境温度(℃)
  finalThermostatTemp: number = 0;// 显色值消解室温度(℃)
  finalEnvironmentTemp: number = 0;// 显色值环境温度(℃)
  initConsistency: number = 0;    // 空白吸光度(mAbs)
  measureTime: number = 0;        // 测量时长(秒)
  addStandardConsistency: number = 0; // 加量程校准液浓度(mg/L)
  measureRange: number = 0;       // 量程
  versionString: string = "1.0.0.2";
}

/**
 * 字段配置（用于动态字段支持，对应原C++的RecordField）
 */
export interface FieldConfig {
  name: string;           // 字段名
  type: FieldType;        // 字段类型
  size: number;           // 字段大小(字节)
  text: string;           // 显示文本
  unit?: string;          // 单位
  privilege: number;      // 权限级别
  option?: string[];      // 枚举选项
  start?: number;         // 起始位置（用于二进制解析）
}

/**
 * 数据表版本配置（对应原C++的RecordFields）
 */
export interface TableVersionConfig {
  fields: FieldConfig[];      // 字段列表
  totalSize: number;          // 总字节大小
}

/**
 * 测量记录查询条件
 */
export interface MeasureQueryCondition {
  startTime?: number;         // 开始时间戳
  endTime?: number;           // 结束时间戳
  resultType?: number;        // 结果类型
  mode?: number;              // 标识类型
  startId?: number;           // 起始ID（用于分页）
  limit?: number;             // 每页数量
  offset?: number;            // 偏移量
  orderBy?: 'asc' | 'desc';   // 排序方式
}

/**
 * 校准记录查询条件
 */
export interface CalibrateQueryCondition {
  startTime?: number;
  endTime?: number;
  calibrateType?: number;
  minR2?: number;             // 最小R2值（筛选有效曲线）
  limit?: number;
  offset?: number;
  orderBy?: 'asc' | 'desc';
}

/**
 * 导出配置
 */
export interface ExportConfig {
  fileName: string;           // 导出文件名
  includeFields: string[];    // 包含的字段列表
  roleType: number;           // 角色类型（用于权限过滤）
  startTime?: number;         // 开始时间
  endTime?: number;           // 结束时间
}

/**
 * 记录比较结果（对应原C++的RecordCompare）
 */
export interface RecordCompareResult {
  isEqual: boolean;
  diffFields: string[];
}