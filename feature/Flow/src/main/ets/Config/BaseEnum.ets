import { DEFAULT } from "@ohos/hypium"

/**
 * 类别
 */
export enum TypeItem {
  // 测量排期
  WATERMEASURE = '水样测量',
  CALIBRATION = '校准',
  TIMECALIBRATION = '测零点校准液',
  RANGECALIBRATION = '测量程校准液',
  STANDARDMEASURE = '测标样(跨度)',
  ZEROPOINTVERIFICATIONSOLUTION = '测零点核查液',
  SPIKEDRECOVERY = '加标回收',
  PARALLELMEASUREMENT = '平行测量',
  DEEPCLEANING = '深度清洗',
  EXACTSTART = '整点启动',

  // 测量参数
  RANGESELECTION = '量程选择',
  CURRENTRANGEINFO = '当前量程信息',
  CALIBRATIONRANGEINFO = '校准量程信息',
  INTELLIGENTDETERMINATION = '智能判定',
  DISCHARGE = '消解',
  REACTION = '反应',
  VERIFICATION = '核查',
  CORRECTION = '修正',
  PREMEARSUREMENTCLEAN = '测量前清洗',
  CLEANMODE = '清洗模式',
  PIPELINE = '管路',
  REAGENT = '试剂',

  // 外联接口
  INSTRUMENTSTATUS = '仪器状态',
  WATERSAMPLEOVERSTANDARDSETTING = '水样超标设置',
  MODBUS = 'MODBUS',
  RS485 = 'RS485',
  RS232 = 'RS232',
  WATERSAMPLE420 = '水样4-20mA',
  WATERSAMPLINGSETUP = '采水设置',
  MULTIFUNCTIONALRELAY = '多功能继电器',

  // 系统参数
  INSTRUMENTPROTECTION = '仪器保护',
  SPECIALPARAMETERS = '特殊参数',
  DATAREPORTING = '数据上报',
  MODBUSCOMMUNICATION = 'MODBUS通信',
  DISPLAYSCREEN = '显示屏',
  RANGESETTING = '量程设置',
  REMOTEFILE = '远程文件',

  DEFAULT = '未知类别'
}

/**
 * 参数项
 */
export enum ParameterItem {
  // 测量排期
  MEASUREMENTMODE = '测量模式',
  INTERVALPERIOD = '间隔周期',
  TIMEPOINTSET = '整点设置',
  INTERVALTIME = '整点间隔时间',
  AUTOMATICVERIFICATION = '自动核查',
  AUTOMATICMARKUP = '自动加标',
  AUTOMATICPARALLELISM = '自动平行',
  AUTOMATICCLEANING = '自动清洗',
  DETERMINEEXTENTIONTIME = '判定延长时间',

  // 测量参数
  CURRENTRANGE = '当前量程',
  CALIBRATIONRANGE = '校准量程',
  ZEROPOINTVERIFICATIONRANGE = '零点核查量程',
  SPECIFICATIONVERIFICATIONRANGE = '标样(跨度)核查量程',
  RANGEONE = '量程一',
  RANGETWO = '量程二',
  RANGETHREE = '量程三',
  AUTOMATICRANGESWITCHING = '量程自动切换',
  EFFECTIVEMODEAFTERSWITCHING = '切换后生效模式',
  SLANTDISTANCE = '斜率',
  INTERCEPT = '截距',
  CALIBRATIONTIME = '校准时间',
  ZEROCALIBRATIONLIQUIDCONCENTRATION = '零点校准液浓度',
  SPANCALIBRATIONLIQUIDCONCENTRATION = '量程校准液浓度',
  CALIBRATIONQUALIFICATION = '校准合格判定',
  CALIBRATIONOUTPUTTWOPOINTRESULT = '校准输出两点结果',
  CALIBRATIONUPDATEALLSTANDARDCURVES = '校准更新所有标线',
  CALIBRATIONLABELOUTPUT = '校准标识输出',
  DECOMPOSITIONTEMPERATURE = '消解温度',
  REDUCTIONOFTIME = '消解时间',
  REACTIONTEMPERATURE = '反应温度',
  REACTIONTIME = '反应时间',
  CHECKCONCENTRATION = '核查浓度',
  CHECKDEVIATIONLIMIT = '核查偏差限值',
  CHECKREPORTING = '核查上报',
  AUTOCALIBRATIONONOVERFLOW = '超限值启动校准',
  NEGATIVECORRECTION = '负值修正',
  SLOPECORRECTION = '斜率修正',
  INTERCEPTCORRECTION = '截距修正',
  CLEANINGSWITCH = '清洗开关',
  CALIBRATIONINTERVAL = '间隔时间',
  REAGENTFOURUPDATEVOLUME = '试剂四更新体积',
  ZEROCALIBRATIONLIQUID = '零点校准液',
  ANTIFOULINGMODE = '抗污模式',
  TAPWATERMODE = '自来水模式',
  WATER_SAMPLE_TUBE_EXTENDED_VOLUME = '水样管延长体积',
  WATER_SAMPLE_UPDATEVOLUME = '水样更新体积',
  REAGENTUPDATE = '试剂更新',

  // 外联接口
  STATUS = '状态',
  ALARM = '报警',
  EXCEEDINGTHEUPPERLIMIT = '超标上限',
  EXCEEDINGTHELOWERLIMIT = '超标下限',
  STARTTHEVERIFICATION = '水样超标启动核查',
  POSTALADDRESS = '通信地址',
  TRANSMISSIONRATE = '传输速率',
  CHECKDIGIT = '校验位',
  CORRESPONDINGCONCENTRATION4 = '4mA对应浓度',
  CORRESPONDINGCONCENTRATION20 = '20mA对应浓度',
  CALIBRATIONCOEFFICIENT = '校准系数',
  WATERSAMPLINGMODE = '采水模式',
  PREWATERSAMPLINGTIME = '测量前采水时间',
  PRESILENCEPERIOD = '测量前静默时间',
  RELAY1 = '继电器1',
  RELAY2 = '继电器2',

  // 系统参数
  REMINDERREPLACEMENT = '更换试剂提醒',
  ABNORMALRETESTING = '异常重测',
  OPENVALUATION = '开放预估值',
  MARKINGS = '标线C=K*mAbs+B',
  LEAKAGEDETECTION = '漏液检测',
  DRYCONTACTTRIGGERMEASUREMENT = '干接点触发测量',
  DETAILEDRECORD = '参数更改详细记录',
  REAGENTMANAGEMENT = '试剂管理',
  TRANSMISSIONPROTOCOL = '传输协议',
  MODBUSPROTOCOL = 'Modbus协议',
  SCREENSAVER = '屏幕保护',
  AUTOMATICDARKSCREENTIME = '自动暗屏时间',
  AUTOMATICSCREENTURNINGOFFTIME = '自动关屏时间',
  ALTERNATIVEMEASUREMENTRANGE1 = '备选量程1',
  ALTERNATIVEMEASUREMENTRANGE2 = '备选量程2',
  ALTERNATIVEMEASUREMENTRANGE3 = '备选量程3',
  ALTERNATIVEMEASUREMENTRANGE4 = '备选量程4',
  ALTERNATIVEMEASUREMENTRANGE5 = '备选量程5',
  ALTERNATIVEMEASUREMENTRANGE6 = '备选量程6',
  ALTERNATIVEMEASUREMENTRANGE7 = '备选量程7',
  FUNCTIONSWITCH = '功能开关',
  IPADDRESS = 'IP地址',

  DEFAULT = '未知参数'
}

/**
 * 单位
 */
export enum Unit {
  SECOND = '秒',
  HOUR = '小时',
  DAY = '天',
  MG = 'mg/L',
  ML = 'mL',
  PERCENT = '%',
  num1 = '0.04~0.02',
  num2 = '0.8~2.0',
  num3 = '0.36~0.59',
  num4 = '-500~500',
  tem = '℃',
  BPS = 'bps',

  DEFAULT = '未知单位'
}

/**
 * 测量模式-值
 */
export enum MeasurementMode {
  EXTERNALTRIGGER = '外部触发',
  PERIODMEASUREMENT = '周期测量',
  PERIODICMEASUREMENT = '整点测量',
  CONTINUOUSMEASUREMENT = '连续测量',

  DEFAULT = '未知测量模式'
}

/**
 * 量程选择-值
 */
export enum RangeMode {
  RANGEONE = '量程一',
  RANGETWO = '量程二',
  RANGETHREE = '量程三',
}

/**
 * 量程大小-值
 */
export enum RangeOne {
  SELECTIONONE = '0-50',
  SELECTIONTWO = '0-100',
  SELECTIONTHREE = '0-250',
  SELECTIONFOUR = '0-500'
}

/**
 * 切换后生效模式-值
 */
export enum EffectiveMode {
  IMMEDIATELY = '立即生效',
  NEXT = '下次生效'
}

/**
 * 开关-值
 */
export enum Switch {
  OPEN = '开',
  CLOSE = '关',
  DEFAULT = '未知状态'
}

/**
 * 仪器状态-值
 */
export enum INSTRUMENTSTATUS {
  RUN = '运行',
  OFFLINE = '离线',
  MAINTENANCE = '维护',
  MALFUNCTION = '故障',
  CALIBRATION = '校准',
  DEBUGGING = '调试'
}

/**
 * 传输速率-值
 */
export enum TransmissionRate {
  RATE1 = '9600',
  RATE2 = '19200',
  RATE3 = '38400',
  RATE4 = '115200',
  RATE5 = '230400',
}

/**
 * 校验位-值
 */
export enum CheckDigit {
  EMPTY = '无',
  PARITYCHECK1 = '奇校验',
  PARITYCHECK2 = '偶校验',
}

/**
 * 采水模式-值
 */
export enum WaterSamplingMode {
  EXTERNALTRIGGER = '外部触发',
  PRECOLLECTINGWATER = '测量前采水',
  UNTILSAMPLING = '采至加样完',
  UNTILMEASUREMENT = '采至测量完'
}

/**
 * 继电器模式-值
 */
export enum RelayMode {
  UPPERLIMIT = '超标上限',
  LOWERLIMIT = '超标下限',
  MEASUREMENTINDICATION = '测量指示',
  CALIBRATIONINDICATION = '校准指示',
  CLEANINGINSTRUCTIONS = '清洗指示',
  WATERSAMPLINGINDICATION = '采水指示',
  STANDARDSAMPLEVERIFICATION = '标样核查',
  ALARMINDICATION = '告警指示'
}

/**
 * 传输协议-值
 */
export enum TRANSMISSIONPROTOCOLMode {
  MODBUS = 'Modbus',
  CCEP = 'CCEP认证协议',
  HJ2017 = 'HJ212-2017-Wry',
  HJ2005 = 'HJ212-2005-Wry',
  HJ2025 = 'HJ212-2025-Wry'
}

/**
 * Modbus协议-值
 */
export enum MODBUSPROTOCOLMODE {
  LS1 = 'LS1.0',
  JS = 'JS',
  SZBA = 'SZBA',
  DYNAMICCONTROL = '西宁动态管控',
  GZ = 'GZ',
  SC = 'SC',
  SURFACEWATER = '地表水1.0',
  LS2 = 'LS2.0',
  XIAN = 'XiAn',
  JX = 'JX',
  YC = 'YC',
  LS4 = 'LS4.0'
}