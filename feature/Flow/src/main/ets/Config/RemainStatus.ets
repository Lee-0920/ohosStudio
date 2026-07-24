
import { RemainStatus } from 'dataservice'

// export interface RemainStatus {
//   standard: number;    // 标样余量
//   blank: number;       // 零点校准液余量
//   zeroCheck: number;   // 零点核查液余量
//   rangeCheck: number;  // 量程核查液余量
//   waste: number;       // 废液桶余量
//   wasteWater: number;  // 废水桶余量
//   reagent1: number;    // 试剂1余量
//   reagent2: number;    // 试剂2余量
// }

// 余量状态配置
export const remainStatus: RemainStatus = {
  standard: 500,
  blank: 10000,
  zeroCheck: 500,
  rangeCheck: 500,
  waste: 25000,
  wasteWater: 25000,
  reagent1: 500,
  reagent2: 500,
  reagentClean: 500,
};
