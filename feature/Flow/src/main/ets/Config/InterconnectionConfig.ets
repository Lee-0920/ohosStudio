import { InterconnectionConfig } from 'dataservice';

// export interface AdcDetectItem {
//   enable: boolean; // 是否启用
// }
//
// export interface InterconnectionConfig {
//   alarmValue: boolean;          // 报警使能
//   outputType: number;           // 输出参数类型(单参数默认0)
//   meaUpLimit: number;           // 测量上限
//   meaLowLimit: number;          // 测量下限
//   overProofResultMark: number;  // 超上限标识
//   rangeCheckResultMark: number; // 核查标识
//   overProofAutoCheck: boolean;  // 超标启动核查
//   connectAddress: number;       // 通信地址
//   RS485BaudRate: number;        // RS485传输速率
//   RS485Parity: number;          // RS485校验位
//   RS232BaudRate: number;        // RS232传输速率
//   RS232Parity: number;          // RS232校验位
//   sampleLowLimit: number;       // 水样4-20浓度下限
//   sampleUpLimit: number;        // 水样4-20浓度上限
//   currentFactor: number;        // 4-20校准系数
//   collectSampleMode: number;    // 采水模式
//   miningWaterTime: number;      // 采水时间
//   silentTime: number;           // 静默时间
//   relayOne: number;             // 继电器1
//   relayTwo: number;             // 继电器2
//   reportMode: number;           // 上报模式
//   settingIPMode: number;        // 设置IP模式
// }

// 联网配置
export const interconnectionConfig: InterconnectionConfig = {
  alarmValue: false,
  outputType: 0,
  meaUpLimit: 200,
  meaLowLimit: 0,
  overProofResultMark: 0,
  rangeCheckResultMark: 0,
  overProofAutoCheck: false,
  connectAddress: 1,
  rs485BaudRate: 0,
  rs485Parity: 0,
  rs232BaudRate: 0,
  rs232Parity: 0,
  sampleLowLimit: 0,
  sampleUpLimit: 200,
  currentFactor: 1,
  collectSampleMode: 0,
  miningWaterTime: 20,
  silentTime: 20,
  relayOne: 5,
  relayTwo: 0,
  reportMode: 0,
  settingIpMode: 0,
};
