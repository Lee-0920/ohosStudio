
import { MainBoardInfoConfig } from 'dataservice';

// export interface ManuDate {
//   day: number;   // 日期
//   year: number;  // 年份
//   month: number; // 月份
// }
//
// export interface MainBoardInformation {
//   manufacturer: string; // 生产厂商
//   sn: string;           // 序列号
//   type: string;         // 类型
//   manuDate: ManuDate;   // 生产日期
//   model: string;        // 型号
// }

// 主板信息配置
export const mainBoardInformation: MainBoardInfoConfig = {
  manufacturer: "LABSUN",
  sn: "00000000",
  type: "LUMC-S",
  manuDate: {
    day: 15,
    year: 2021,
    month: 11,
  },
  model: "LUMC8101",
};
