import {
  InstrumentInfoConfig,
} from 'dataservice';


// export interface ManuDate {
//   month: number;  // 月份
//   year: number;   // 年份
//   day: number;    // 日期
// }
//
// export interface ReagentLicense {
//   enable: boolean;       // 功能开关
//   expirationDate: number; // 授权截止时间
// }
//
// export interface InstrumentInformation {
//   model: string;           // 型号(产品确定后不可更改)
//   manuDate: ManuDate;      // 生产日期
//   type: string;            // 类型
//   manufacturer: string;    // 生产厂商
//   MfrN: string;            // 制造商编号
//   uuid: string;            // UUID
//   sn: string;              // 序列号
//   reagentLicense: ReagentLicense; // 试剂授权
//   expirationDate: number;  // 有效期截止时间
//   license: boolean;        // 是否有许可证
//   permanent: boolean;      // 是否永久授权
//   manufactureType: number; // 0-LS 1-OEM 2-DIY
//   showModel: string;       // 显示型号(可定制显示)
//   showName: string;        // 显示名称
// }

// 仪器信息配置
export const instrumentInformation: InstrumentInfoConfig = {
  model: "PhotoTek 6000 COD",
  manuDate: {
    year: 2026,
    month: 7,
    day: 15,
  },
  type: "PT70-CODC",
  manufacturer: "深圳市朗石科学仪器有限公司",
  MfrN: "683776325001W",
  uuid: "",
  sn: "B00000000",
  reagentLicense: {
    enable: false,
    expirationDate: 0,
  },
  expirationDate: 2145888000,
  license: true,
  permanent: true,
  manufactureType: 0,
  showModel: "PhotoTek 6000 COD",
  showName: "化学需氧量水质自动在线监测仪",
};
