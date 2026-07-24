// lhipstudio/Common/alarm/src/main/ets/model/AlarmCode.ets

export enum AlarmCode {
  NO_ALARM = 0,                    // 无报警
  ZERO_CALIBRATION_FAIL = 1,       // 零点校准液抽取失败
  RANGE_CALIBRATION_FAIL = 2,      // 量程校准液抽取失败
  SAMPLE_FAIL = 3,                 // 水样抽取失败
  DIGESTION_LIQUID_FAIL = 4,       // 消解液抽取失败
  REAGENT1_FAIL = 5,               // 试剂一抽取失败
  REAGENT2_FAIL = 6,               // 试剂二抽取失败
  REAGENT3_FAIL = 7,               // 试剂三抽取失败
  REAGENT4_FAIL = 8,               // 试剂四抽取失败
  REAGENT5_FAIL = 9,               // 试剂五抽取失败
  REAGENT6_FAIL = 10,              // 试剂六抽取失败
  REPLACE_ZERO_CALIBRATION = 11,   // 请更换零点校准液
  REPLACE_RANGE_CALIBRATION = 12,  // 请更换量程校准液
  REPLACE_REAGENT1 = 13,           // 请更换试剂一
  REPLACE_REAGENT2 = 14,           // 请更换试剂二
  REPLACE_REAGENT3 = 15,           // 请更换试剂三
  REPLACE_REAGENT4 = 16,           // 请更换试剂四
  REPLACE_REAGENT5 = 17,           // 请更换试剂五
  REPLACE_REAGENT6 = 18,           // 请更换试剂六
  TEMP_CONTROL_FAIL = 19,          // 温控故障
  FLUID_BOARD_COMM_FAIL = 20,      // 液路板通信异常
  TEMP_BOARD_COMM_FAIL = 21,       // 温控板通信异常
  SIGNAL_BOARD_COMM_FAIL = 22,     // 信号板通信异常
  FLUID_BOARD_UPGRADE_FAIL = 23,   // 液路板升级失败
  TEMP_BOARD_UPGRADE_FAIL = 24,    // 温控板升级失败
  SIGNAL_BOARD_UPGRADE_FAIL = 25,  // 信号板升级失败
  DEVICE_RUN_FAIL = 26,            // 仪器运行故障
  DRAIN_DIGESTION_FAIL = 27,       // 排消解液异常
  PUMP_CALIBRATION_FAIL = 28,      // 蠕动泵校准失败
  SAMPLE_EXCEED = 29,              // 水样超标
  CALIBRATION_RESULT_ERROR = 30,   // 校准结果错误
  PUMP_TUBE_EXPIRED = 31,          // 蠕动泵软管已过期
  PINCH_VALVE_TUBE_EXPIRED = 32,   // 夹断阀软管已过期
  METERING_TUBE_EXPIRED = 33,      // 计量管已过期
  METERING_O_RING_EXPIRED = 34,    // 计量O形圈已过期
  PTFE_TUBE_EXPIRED = 35,          // PTFE硬管已过期
  DRIVE_BOARD_COMM_FAIL = 36,      // 驱动板通信异常
  REACT_BOARD_COMM_FAIL = 37,      // 反应板通信异常
  DRIVE_BOARD_UPGRADE_FAIL = 38,   // 驱动板升级失败
  REACT_BOARD_UPGRADE_FAIL = 39,   // 反应板升级失败
  REPLACE_WASTE_LIQUID = 40,       // 请更换废液
  SAMPLE_EXCEED_RANGE = 41,        // 水样超量程
  RANGE_CALIBRATION_RESULT_ERROR = 42, // 量程校准结果错误
  REPLACE_WASTE_WATER = 43,        // 请更换废水
  STATIC_AD_FAIL = 44,             // 静态AD调节失败
  DIGESTION_ADD_LIQUID_FAIL = 45,  // 消解室加液异常
  VERIFICATION_RESULT_ERROR = 46,  // 核查结果错误
  DEVICE_LEAK = 47,                // 仪器漏液
  ZERO_VERIFICATION_FAIL = 50,     // 零点核查液抽取失败
  SPAN_VERIFICATION_FAIL = 51,     // 标样(跨度)核查液抽取失败
  REPLACE_ZERO_VERIFICATION = 52,  // 请更换零点核查液
  REPLACE_SPAN_VERIFICATION = 53,  // 请更换标样(跨度)核查液

  // TOC特殊告警码
  MAIN_VALVE_PRESSURE_LOW = 80,    // 总阀压力过低
  MAIN_VALVE_PRESSURE_HIGH = 81,   // 总阀压力过高
  CARRIER_PRESSURE_HIGH = 82,      // 载气压力过高
  CARRIER_PRESSURE_LOW = 83,       // 载气压力过低
  CARRIER_ADJUST_FAIL = 84,        // 载气调节失败
  SLIDER_NOT_ORIGIN = 85,          // 位置异常，滑块处于非原点
  SENSOR_FAIL = 86,                // 传感器故障，请检查传感器线路
  SLIDER_ZERO_CALIBRATION_FAIL = 87, // 滑块零点校准失败
  BASELINE_INVALID = 88            // 基线无效
}

// 告警码描述映射
export const AlarmCodeDescriptions: Map<AlarmCode, string> = new Map<AlarmCode, string>([
  [AlarmCode.NO_ALARM, '无报警'],
  [AlarmCode.ZERO_CALIBRATION_FAIL, '零点校准液抽取失败'],
  [AlarmCode.RANGE_CALIBRATION_FAIL, '量程校准液抽取失败'],
  [AlarmCode.SAMPLE_FAIL, '水样抽取失败'],
  [AlarmCode.DIGESTION_LIQUID_FAIL, '消解液抽取失败'],
  [AlarmCode.REAGENT1_FAIL, '试剂一抽取失败'],
  [AlarmCode.REAGENT2_FAIL, '试剂二抽取失败'],
  [AlarmCode.REAGENT3_FAIL, '试剂三抽取失败'],
  [AlarmCode.REAGENT4_FAIL, '试剂四抽取失败'],
  [AlarmCode.REAGENT5_FAIL, '试剂五抽取失败'],
  [AlarmCode.REAGENT6_FAIL, '试剂六抽取失败'],
  [AlarmCode.REPLACE_ZERO_CALIBRATION, '请更换零点校准液'],
  [AlarmCode.REPLACE_RANGE_CALIBRATION, '请更换量程校准液'],
  [AlarmCode.REPLACE_REAGENT1, '请更换试剂一'],
  [AlarmCode.REPLACE_REAGENT2, '请更换试剂二'],
  [AlarmCode.REPLACE_REAGENT3, '请更换试剂三'],
  [AlarmCode.REPLACE_REAGENT4, '请更换试剂四'],
  [AlarmCode.REPLACE_REAGENT5, '请更换试剂五'],
  [AlarmCode.REPLACE_REAGENT6, '请更换试剂六'],
  [AlarmCode.TEMP_CONTROL_FAIL, '温控故障'],
  [AlarmCode.FLUID_BOARD_COMM_FAIL, '液路板通信异常'],
  [AlarmCode.TEMP_BOARD_COMM_FAIL, '温控板通信异常'],
  [AlarmCode.SIGNAL_BOARD_COMM_FAIL, '信号板通信异常'],
  [AlarmCode.FLUID_BOARD_UPGRADE_FAIL, '液路板升级失败'],
  [AlarmCode.TEMP_BOARD_UPGRADE_FAIL, '温控板升级失败'],
  [AlarmCode.SIGNAL_BOARD_UPGRADE_FAIL, '信号板升级失败'],
  [AlarmCode.DEVICE_RUN_FAIL, '仪器运行故障'],
  [AlarmCode.DRAIN_DIGESTION_FAIL, '排消解液异常'],
  [AlarmCode.PUMP_CALIBRATION_FAIL, '蠕动泵校准失败'],
  [AlarmCode.SAMPLE_EXCEED, '水样超标'],
  [AlarmCode.CALIBRATION_RESULT_ERROR, '校准结果错误'],
  [AlarmCode.PUMP_TUBE_EXPIRED, '蠕动泵软管已过期'],
  [AlarmCode.PINCH_VALVE_TUBE_EXPIRED, '夹断阀软管已过期'],
  [AlarmCode.METERING_TUBE_EXPIRED, '计量管已过期'],
  [AlarmCode.METERING_O_RING_EXPIRED, '计量O形圈已过期'],
  [AlarmCode.PTFE_TUBE_EXPIRED, 'PTFE硬管已过期'],
  [AlarmCode.DRIVE_BOARD_COMM_FAIL, '驱动板通信异常'],
  [AlarmCode.REACT_BOARD_COMM_FAIL, '反应板通信异常'],
  [AlarmCode.DRIVE_BOARD_UPGRADE_FAIL, '驱动板升级失败'],
  [AlarmCode.REACT_BOARD_UPGRADE_FAIL, '反应板升级失败'],
  [AlarmCode.REPLACE_WASTE_LIQUID, '请更换废液'],
  [AlarmCode.SAMPLE_EXCEED_RANGE, '水样超量程'],
  [AlarmCode.RANGE_CALIBRATION_RESULT_ERROR, '量程校准结果错误'],
  [AlarmCode.REPLACE_WASTE_WATER, '请更换废水'],
  [AlarmCode.STATIC_AD_FAIL, '静态AD调节失败'],
  [AlarmCode.DIGESTION_ADD_LIQUID_FAIL, '消解室加液异常'],
  [AlarmCode.VERIFICATION_RESULT_ERROR, '核查结果错误'],
  [AlarmCode.DEVICE_LEAK, '仪器漏液'],
  [AlarmCode.ZERO_VERIFICATION_FAIL, '零点核查液抽取失败'],
  [AlarmCode.SPAN_VERIFICATION_FAIL, '标样(跨度)核查液抽取失败'],
  [AlarmCode.REPLACE_ZERO_VERIFICATION, '请更换零点核查液'],
  [AlarmCode.REPLACE_SPAN_VERIFICATION, '请更换标样(跨度)核查液'],
  [AlarmCode.MAIN_VALVE_PRESSURE_LOW, '总阀压力过低'],
  [AlarmCode.MAIN_VALVE_PRESSURE_HIGH, '总阀压力过高'],
  [AlarmCode.CARRIER_PRESSURE_HIGH, '载气压力过高'],
  [AlarmCode.CARRIER_PRESSURE_LOW, '载气压力过低'],
  [AlarmCode.CARRIER_ADJUST_FAIL, '载气调节失败'],
  [AlarmCode.SLIDER_NOT_ORIGIN, '位置异常，滑块处于非原点'],
  [AlarmCode.SENSOR_FAIL, '传感器故障，请检查传感器线路'],
  [AlarmCode.SLIDER_ZERO_CALIBRATION_FAIL, '滑块零点校准失败'],
  [AlarmCode.BASELINE_INVALID, '基线无效']
]);

// 告警类型分类
export enum AlarmType {
  REAGENT = '试剂类',              // 试剂相关（抽取失败、更换提示）
  FLUID_PATH = '液路类',           // 液路相关（通信、升级、异常）
  HARDWARE = '硬件类',             // 硬件相关（温控、通信、升级）
  CALIBRATION = '校准类',          // 校准相关（校准失败、结果错误）
  CONSUMABLE = '耗材类',           // 耗材过期
  SAMPLE = '水样类',               // 水样相关（超标、超量程、抽取失败）
  TOC_SPECIAL = 'TOC特殊类',       // TOC特殊告警（压力、传感器、滑块等）
  GENERAL = '通用类'               // 其他通用告警
}

// 告警码到告警类型的映射
export const AlarmTypeMap: Map<AlarmCode, AlarmType> = new Map<AlarmCode, AlarmType>([
  [AlarmCode.ZERO_CALIBRATION_FAIL, AlarmType.CALIBRATION],
  [AlarmCode.RANGE_CALIBRATION_FAIL, AlarmType.CALIBRATION],
  [AlarmCode.SAMPLE_FAIL, AlarmType.SAMPLE],
  [AlarmCode.DIGESTION_LIQUID_FAIL, AlarmType.REAGENT],
  [AlarmCode.REAGENT1_FAIL, AlarmType.REAGENT],
  [AlarmCode.REAGENT2_FAIL, AlarmType.REAGENT],
  [AlarmCode.REAGENT3_FAIL, AlarmType.REAGENT],
  [AlarmCode.REAGENT4_FAIL, AlarmType.REAGENT],
  [AlarmCode.REAGENT5_FAIL, AlarmType.REAGENT],
  [AlarmCode.REAGENT6_FAIL, AlarmType.REAGENT],
  [AlarmCode.REPLACE_ZERO_CALIBRATION, AlarmType.CALIBRATION],
  [AlarmCode.REPLACE_RANGE_CALIBRATION, AlarmType.CALIBRATION],
  [AlarmCode.REPLACE_REAGENT1, AlarmType.REAGENT],
  [AlarmCode.REPLACE_REAGENT2, AlarmType.REAGENT],
  [AlarmCode.REPLACE_REAGENT3, AlarmType.REAGENT],
  [AlarmCode.REPLACE_REAGENT4, AlarmType.REAGENT],
  [AlarmCode.REPLACE_REAGENT5, AlarmType.REAGENT],
  [AlarmCode.REPLACE_REAGENT6, AlarmType.REAGENT],
  [AlarmCode.TEMP_CONTROL_FAIL, AlarmType.HARDWARE],
  [AlarmCode.FLUID_BOARD_COMM_FAIL, AlarmType.FLUID_PATH],
  [AlarmCode.TEMP_BOARD_COMM_FAIL, AlarmType.HARDWARE],
  [AlarmCode.SIGNAL_BOARD_COMM_FAIL, AlarmType.HARDWARE],
  [AlarmCode.FLUID_BOARD_UPGRADE_FAIL, AlarmType.FLUID_PATH],
  [AlarmCode.TEMP_BOARD_UPGRADE_FAIL, AlarmType.HARDWARE],
  [AlarmCode.SIGNAL_BOARD_UPGRADE_FAIL, AlarmType.HARDWARE],
  [AlarmCode.DEVICE_RUN_FAIL, AlarmType.GENERAL],
  [AlarmCode.DRAIN_DIGESTION_FAIL, AlarmType.FLUID_PATH],
  [AlarmCode.PUMP_CALIBRATION_FAIL, AlarmType.CALIBRATION],
  [AlarmCode.SAMPLE_EXCEED, AlarmType.SAMPLE],
  [AlarmCode.CALIBRATION_RESULT_ERROR, AlarmType.CALIBRATION],
  [AlarmCode.PUMP_TUBE_EXPIRED, AlarmType.CONSUMABLE],
  [AlarmCode.PINCH_VALVE_TUBE_EXPIRED, AlarmType.CONSUMABLE],
  [AlarmCode.METERING_TUBE_EXPIRED, AlarmType.CONSUMABLE],
  [AlarmCode.METERING_O_RING_EXPIRED, AlarmType.CONSUMABLE],
  [AlarmCode.PTFE_TUBE_EXPIRED, AlarmType.CONSUMABLE],
  [AlarmCode.DRIVE_BOARD_COMM_FAIL, AlarmType.HARDWARE],
  [AlarmCode.REACT_BOARD_COMM_FAIL, AlarmType.HARDWARE],
  [AlarmCode.DRIVE_BOARD_UPGRADE_FAIL, AlarmType.HARDWARE],
  [AlarmCode.REACT_BOARD_UPGRADE_FAIL, AlarmType.HARDWARE],
  [AlarmCode.REPLACE_WASTE_LIQUID, AlarmType.REAGENT],
  [AlarmCode.SAMPLE_EXCEED_RANGE, AlarmType.SAMPLE],
  [AlarmCode.RANGE_CALIBRATION_RESULT_ERROR, AlarmType.CALIBRATION],
  [AlarmCode.REPLACE_WASTE_WATER, AlarmType.REAGENT],
  [AlarmCode.STATIC_AD_FAIL, AlarmType.HARDWARE],
  [AlarmCode.DIGESTION_ADD_LIQUID_FAIL, AlarmType.FLUID_PATH],
  [AlarmCode.VERIFICATION_RESULT_ERROR, AlarmType.CALIBRATION],
  [AlarmCode.DEVICE_LEAK, AlarmType.FLUID_PATH],
  [AlarmCode.ZERO_VERIFICATION_FAIL, AlarmType.CALIBRATION],
  [AlarmCode.SPAN_VERIFICATION_FAIL, AlarmType.CALIBRATION],
  [AlarmCode.REPLACE_ZERO_VERIFICATION, AlarmType.CALIBRATION],
  [AlarmCode.REPLACE_SPAN_VERIFICATION, AlarmType.CALIBRATION],
  [AlarmCode.MAIN_VALVE_PRESSURE_LOW, AlarmType.TOC_SPECIAL],
  [AlarmCode.MAIN_VALVE_PRESSURE_HIGH, AlarmType.TOC_SPECIAL],
  [AlarmCode.CARRIER_PRESSURE_HIGH, AlarmType.TOC_SPECIAL],
  [AlarmCode.CARRIER_PRESSURE_LOW, AlarmType.TOC_SPECIAL],
  [AlarmCode.CARRIER_ADJUST_FAIL, AlarmType.TOC_SPECIAL],
  [AlarmCode.SLIDER_NOT_ORIGIN, AlarmType.TOC_SPECIAL],
  [AlarmCode.SENSOR_FAIL, AlarmType.TOC_SPECIAL],
  [AlarmCode.SLIDER_ZERO_CALIBRATION_FAIL, AlarmType.TOC_SPECIAL],
  [AlarmCode.BASELINE_INVALID, AlarmType.TOC_SPECIAL]
]);

// 根据告警码获取描述
export function getAlarmDescription(code: AlarmCode): string {
  return AlarmCodeDescriptions.get(code) ?? `未知告警(${code})`;
}

// 根据告警码获取告警类型
export function getAlarmType(code: AlarmCode): AlarmType {
  return AlarmTypeMap.get(code) ?? AlarmType.GENERAL;
}
