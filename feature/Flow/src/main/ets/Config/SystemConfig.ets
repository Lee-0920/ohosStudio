import { SystemConfig } from 'dataservice';

// export interface ScreenSaver {
//   enable: boolean;           // 是否开屏保
//   darkTime: number;          // 暗屏时间
//   offTime: number;           // 关屏时间
//   loginKeepingTime: number;  // 用户退出时间
// }
//
// export interface AdcDetectItem {
//   enable: boolean; // 是否启用
// }
//
// export interface TargetItem {
//   enable: boolean; // 是否启用
//   num: number;     // 目标编号
// }
//
// export interface TargetMap {
//   Cod: TargetItem;    // COD参数
//   EXTEND: TargetItem; // 扩展参数
// }
//
// export interface RangeViewItem {
//   range: number; // 量程
//   view: number;  // 界面显示量程
// }
//
// export interface Printer {
//   enable: boolean;  // 打印机功能
//   address: string;  // 打印机地址
//   autoPrint: boolean; // 自动打印
// }
//
// export interface Hj212Platform {
//   hj212DataType: number;           // 数据类型
//   status: boolean;                  // 连接平台状态
//   address: string;                  // 212平台IP
//   port: string;                     // 212平台端口
//   mn: string;                       // 编码
//   pw: string;                       // 密码
//   st: string;                       // 状态编码
//   respond: boolean;                 // 应答
//   heartPackTime: number;            // 心跳间隔(单位分钟，<=0表示不发)
//   overtime: number;                 // 超时时间(单位分钟)
//   recount: number;                  // 重传次数
//   hj212CommunicationMode: number;   // 0:232 1:485 2:TCP
//   hj212Type: number;                // 0:None 1: 2017DBS 2: 2017WRY
// }
//
// export interface ValveSetting {
//   sample: number;          // 水样阀
//   standard: number;        // 标样阀
//   blank: number;           // 零点校准液阀
//   digestionRoom: number[]; // 消解室阀
//   wasteWater: number;      // 废水阀
//   waste: number;           // 废液阀
//   reagent1: number;        // 试剂1阀
//   reagent2: number;        // 试剂2阀
//   zeroCheck: number;       // 零点核查阀
//   rangeCheck: number;      // 量程核查阀
// }
//
// export interface SystemConfig {
//   screenSaver: ScreenSaver;       // 屏保配置
//   adcDetect: AdcDetectItem[];     // ADC检测配置
//   language: number;               // 语言
//   faultBlocking: boolean;          // 故障停机
//   displayProformaResult: boolean;  // 预估结果显示
//   faultRetry: boolean;             // 异常重测
//   reagentLackWarn: boolean;        // 缺试剂告警
//   dryFireProtection: boolean;      // 干烧保护
//   drainDigestRoomCheck: boolean;   // 排液检查
//   reagent2SpareValve: boolean;     // 试剂2不使用备用阀
//   curveXYChange: boolean;          // 曲线XY调换
//   debugMode: boolean;              // 开发调试模式
//   bridgeMode: boolean;             // 桥接模式
//   bridgeIP: string;                // 桥接IP
//   modbusTableType: number;         // Modbus表类型
//   CCEPMode: boolean;               // CCEP认证模式
//   solidifyMeaParamFromUI: boolean; // 不可通过UI修改测量参数
//   solidifyMeaParamFromModbus: boolean; // 不可通过Modbus修改测量参数
//   displayMeaParamInGeneral: boolean;   // 普通用户显示测量参数
//   changeParamLog: boolean;             // 记录参数更改日志
//   newDbsModbusLog: boolean;           // 地表水协议新日志
//   useQRcode: boolean;               // 二维码
//   serverIP: string;                   // 服务器IP
//   serverPort: number;                 // 服务器端口
//   serverMode: boolean;                // 服务器模式
//   targetMap: TargetMap;               // 目标参数映射
//   internationalSupported: boolean;    // 国际化支持
//   standardRegister: boolean;          // 水样核查值更新
//   rangeViewMap: RangeViewItem[];      // 量程显示映射
//   printer: Printer;                   // 打印机配置
//   nfsAddr: string;                    // NFS地址
//   nfsEnable: boolean;                 // NFS使能
//   hj212Platform: Hj212Platform;       // HJ212平台配置
//   valveSetting: ValveSetting;         // 阀号设置
//   decimalNum: number;                 // 小数位数
//   OEM: number;                        // OEM标识
//   weepingLimitValve: number;          // 漏液检测阀值
//   isLoadingReagentManager: boolean;   // 是否启用试剂管理界面
//   deviceStartupTime: number;          // 设备启动时间
// }

// 系统配置
export const systemConfig: SystemConfig = {
  screenSaver: {
    enable: true,
    darkTime: 300,
    offTime: 600,
    loginKeepingTime: 600,
  },
  adcDetect: [
    { enable: false },  // 漏液检测
    { enable: false },  // 测量触发
  ],
  language: 0,
  faultBlocking: false,
  displayProformaResult: true,
  faultRetry: true,
  reagentLackWarn: false,
  dryFireProtection: false,
  drainDigestRoomCheck: true,
  reagent2SpareValve: false,
  curveXYChange: false,
  debugMode: false,
  bridgeMode: false,
  bridgeIP: "192.168.2.1",
  modbusTableType: 0,
  cCepMode: false,
  solidifyMeaParamFromUI: false,
  solidifyMeaParamFromModbus: false,
  displayMeaParamInGeneral: false,
  changeParamLog: false,
  newDbsModbusLog: false,
  useQrEncode: false,
  serverIP: "ins.watertestcloud.com",
  serverPort: 8800,
  serverMode: true,
  targetMap: {
    Cod: {
      enable: true,
      num: 0,
    },
    EXTEND: {
      enable: false,
      num: 1,
    },
  },
  internationalSupported: false,
  standardRegister: false,
  rangeViewMap: [
    { range: 0, view: 0 },
    { range: 50, view: 50 },
    { range: 100, view: 100 },
    { range: 250, view: 250 },
    { range: 500, view: 500 },
    { range: 2500, view: 2500 },
    { range: 5000, view: 5000 },
    { range: 10000, view: 10000 },
  ],
  printer: {
    enable: false,
    address: "192.168.1.99",
    autoPrint: false,
  },
  nfsAddr: "192.168.0.218",
  nfsEnable: true,
  hj212Platform: {
    hj212DataType: 0,
    status: false,
    address: "127.0.0.1",
    port: "11110",
    mn: "A20800000_TCP30",
    pw: "123456",
    st: "21",
    respond: false,
    heartPackTime: 5,
    overtime: 3,
    recount: 3,
    hj212CommunicationMode: 0,
    hj212Type: 0,
  },
  valveSetting: {
    sample: 1,
    standard: 2,
    blank: 3,
    digestionRoom: [4, 5],
    wasteWater: 10,
    waste: 6,
    reagent1: 7,
    reagent2: 8,
    zeroCheck: 14,
    rangeCheck: 15,
  },
  decimalNum: 2,
  oem: 0,
  weepingLimitValve: 70,
  isLoadingReagentManager: true,
  rinseSolution:5,
  deviceStartupTime: 0,
};
