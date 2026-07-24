/**
 * 告警项接口
 */
export interface AlarmItem {
  level: "Error" | "Warning" | "Info";
  type: string;
  name: string;
}

/**
 * 告警配置类型
 */
export interface AlarmConfig {
  pumpFailed: AlarmItem;
  pumpStop: AlarmItem;
  meterFailed: AlarmItem;
  acquirerADStop: AlarmItem;
  acquirerADFailed: AlarmItem;
  meterStop: AlarmItem;
  reagentRemain: AlarmItem;
  materialGoBad: AlarmItem;
  thermostatStop: AlarmItem;
  thermostatFault: AlarmItem;
  dncpStackInit: AlarmItem;
  communication: AlarmItem;
  updateFault: AlarmItem;
  userStop: AlarmItem;
  deviceRunFault: AlarmItem;
  drainFromDigestionFault: AlarmItem;
  drainFromDigestionUnderLimit: AlarmItem;
  drainFromDigestionOverLimit: AlarmItem;
  calibratePumpFailed: AlarmItem;
  measureResultOutUpLimit: AlarmItem;
  measureResultOutLowLimit: AlarmItem;
  measureResultOutRange: AlarmItem;
  measureRangeWrong: AlarmItem;
  curveCheckWrong: AlarmItem;
  calibrateResultWrong: AlarmItem;
  checkResultWrong: AlarmItem;
  curveNotQualifiedWrong: AlarmItem;
  exception: AlarmItem;
  std_exception: AlarmItem;
  AddLiquidToDigestionFailed: AlarmItem;
  staticADControlStopped: AlarmItem;
  staticADControlFailed: AlarmItem;
  instrumentWeeping: AlarmItem;
  reagentAuthorizationError: AlarmItem;
}

/**
 * 告警配置
 */
export const alarm: AlarmConfig = {
  pumpFailed: {
    level: "Error",
    type: "仪器故障",
    name: "抽取失败",
  },
  pumpStop: {
    level: "Warning",
    type: "仪器故障",
    name: "抽取被停止",
  },
  meterFailed: {
    level: "Error",
    type: "仪器故障",
    name: "抽取失败",
  },
  acquirerADStop: {
    level: "Warning",
    type: "仪器故障",
    name: "光学采集被停止",
  },
  acquirerADFailed: {
    level: "Error",
    type: "仪器故障",
    name: "光学采集失败",
  },
  meterStop: {
    level: "Warning",
    type: "仪器故障",
    name: "抽取被停止",
  },
  reagentRemain: {
    level: "Error",
    type: "维护提示",
    name: "请更换试剂",
  },
  materialGoBad: {
    level: "Error",
    type: "维护提示",
    name: "耗材已过期",
  },
  thermostatStop: {
    level: "Warning",
    type: "仪器故障",
    name: "恒温被停止",
  },
  thermostatFault: {
    level: "Error",
    type: "仪器故障",
    name: "温控故障",
  },
  dncpStackInit: {
    level: "Info",
    type: "通信异常",
    name: "DncpStack失败",
  },
  communication: {
    level: "Error",
    type: "通信异常",
    name: "通信异常",
  },
  updateFault: {
    level: "Error",
    type: "升级异常",
    name: "升级失败",
  },
  userStop: {
    level: "Warning",
    type: "用户停止",
    name: "用户停止",
  },
  deviceRunFault: {
    level: "Error",
    type: "仪器故障",
    name: "仪器运行故障",
  },
  drainFromDigestionFault: {
    level: "Error",
    type: "仪器故障",
    name: "排消解液异常",
  },
  drainFromDigestionUnderLimit: {
    level: "Error",
    type: "仪器故障",
    name: "排液次数不足",
  },
  drainFromDigestionOverLimit: {
    level: "Error",
    type: "仪器故障",
    name: "排液次数过多",
  },
  calibratePumpFailed: {
    level: "Error",
    type: "仪器故障",
    name: "蠕动泵校准失败",
  },
  measureResultOutUpLimit: {
    level: "Error",
    type: "测量异常",
    name: "水样超上限",
  },
  measureResultOutLowLimit: {
    level: "Error",
    type: "测量异常",
    name: "水样超下限",
  },
  measureResultOutRange: {
    level: "Error",
    type: "测量异常",
    name: "水样超量程",
  },
  measureRangeWrong: {
    level: "Info",
    type: "测量异常",
    name: "量程切换",
  },
  curveCheckWrong: {
    level: "Error",
    type: "测量异常",
    name: "校准结果错误",
  },
  calibrateResultWrong: {
    level: "Error",
    type: "测量异常",
    name: "校准结果错误",
  },
  checkResultWrong: {
    level: "Error",
    type: "测量异常",
    name: "核查结果错误",
  },
  curveNotQualifiedWrong: {
    level: "Error",
    type: "校准异常",
    name: "校准不合格,沿用上条合格校准曲线",
  },
  exception: {
    level: "Info",
    type: "系统异常",
    name: "系统异常",
  },
  std_exception: {
    level: "Info",
    type: "系统异常",
    name: "std异常",
  },
  AddLiquidToDigestionFailed: {
    level: "Error",
    type: "仪器故障",
    name: "消解室加液异常",
  },
  staticADControlStopped: {
    level: "Warning",
    type: "仪器故障",
    name: "静态AD调节被停止",
  },
  staticADControlFailed: {
    level: "Error",
    type: "仪器故障",
    name: "静态AD调节失败",
  },
  instrumentWeeping: {
    level: "Error",
    type: "仪器故障",
    name: "仪器漏液",
  },
  reagentAuthorizationError: {
    level: "Error",
    type: "试剂异常",
    name: "试剂配置不正确，请联系服务人员",
  },
};

/**
 * SC版本告警配置（带错误码）
 */
export const alarm_sc: AlarmConfig = {
  pumpFailed: {
    level: "Error",
    type: "仪器故障D",
    name: "抽取失败-D04",
  },
  pumpStop: {
    level: "Warning",
    type: "仪器故障D",
    name: "抽取被停止-D05",
  },
  meterFailed: {
    level: "Error",
    type: "仪器故障D",
    name: "抽取失败-D06",
  },
  acquirerADStop: {
    level: "Warning",
    type: "仪器故障D",
    name: "光学采集被停止-D07",
  },
  acquirerADFailed: {
    level: "Error",
    type: "仪器故障D",
    name: "光学采集失败-D08",
  },
  meterStop: {
    level: "Warning",
    type: "仪器故障D",
    name: "抽取被停止-D09",
  },
  reagentRemain: {
    level: "Error",
    type: "维护提示M",
    name: "请更换试剂-M01",
  },
  materialGoBad: {
    level: "Error",
    type: "维护提示M",
    name: "耗材已过期-M02",
  },
  thermostatStop: {
    level: "Warning",
    type: "仪器故障D",
    name: "恒温被停止-D10",
  },
  thermostatFault: {
    level: "Error",
    type: "仪器故障D",
    name: "温控故障-D11",
  },
  dncpStackInit: {
    level: "Info",
    type: "通信异常W",
    name: "DncpStack失败-W02",
  },
  communication: {
    level: "Error",
    type: "通信异常W",
    name: "通信异常-W01",
  },
  updateFault: {
    level: "Error",
    type: "升级异常U",
    name: "升级失败-U01",
  },
  userStop: {
    level: "Warning",
    type: "用户停止G",
    name: "用户停止-G01",
  },
  deviceRunFault: {
    level: "Error",
    type: "仪器故障D",
    name: "仪器运行故障-D01",
  },
  drainFromDigestionFault: {
    level: "Error",
    type: "仪器故障D",
    name: "排消解液异常-D02",
  },
  calibratePumpFailed: {
    level: "Error",
    type: "仪器故障D",
    name: "蠕动泵校准失败-D03",
  },
  drainFromDigestionUnderLimit: {
    level: "Error",
    type: "仪器故障D",
    name: "排液次数过少-D04",
  },
  drainFromDigestionOverLimit: {
    level: "Error",
    type: "仪器故障D",
    name: "排液次数过多-D05",
  },
  measureResultOutUpLimit: {
    level: "Error",
    type: "测量异常E",
    name: "水样超上限-E01",
  },
  measureResultOutLowLimit: {
    level: "Error",
    type: "测量异常E",
    name: "水样超下限-E02",
  },
  measureResultOutRange: {
    level: "Error",
    type: "测量异常E",
    name: "水样超量程-E03",
  },
  measureRangeWrong: {
    level: "Info",
    type: "测量异常E",
    name: "量程切换-E04",
  },
  curveCheckWrong: {
    level: "Error",
    type: "测量异常E",
    name: "校准结果错误-E05",
  },
  calibrateResultWrong: {
    level: "Error",
    type: "测量异常E",
    name: "校准结果错误-E06",
  },
  checkResultWrong: {
    level: "Error",
    type: "测量异常E",
    name: "核查结果错误-E07",
  },
  curveNotQualifiedWrong: {
    level: "Error",
    type: "校准异常C",
    name: "校准不合格,沿用上条合格校准曲线-C01",
  },
  exception: {
    level: "Info",
    type: "系统异常S",
    name: "系统异常-S01",
  },
  std_exception: {
    level: "Info",
    type: "系统异常S",
    name: "std异常-S02",
  },
  AddLiquidToDigestionFailed: {
    level: "Error",
    type: "仪器故障D",
    name: "消解室加液异常-D12",
  },
  staticADControlStopped: {
    level: "Warning",
    type: "仪器故障D",
    name: "静态AD调节被停止-D13",
  },
  staticADControlFailed: {
    level: "Error",
    type: "仪器故障D",
    name: "静态AD调节失败-D14",
  },
  instrumentWeeping: {
    level: "Error",
    type: "仪器故障D",
    name: "仪器漏液-D15",
  },
  reagentAuthorizationError: {
    level: "Error",
    type: "试剂异常R",
    name: "试剂配置不正确，请联系服务人员-R01",
  },
};
