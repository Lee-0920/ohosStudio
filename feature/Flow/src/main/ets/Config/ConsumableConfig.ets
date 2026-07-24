import { ConsumableConfig } from 'dataservice';
import { DateTimeUtil } from 'base';

// export interface PumpPipe {
//   cycle: number;   // 更换周期
//   lastTime: number; // 上次更换时间
// }
//
// export interface ConsumableConfig {
//   pumpPipe: PumpPipe; // 蠕动泵管配置
// }

export const consumableConfig: ConsumableConfig = {
  pumpPipe: {
    cycle: 36,
    lastTime: DateTimeUtil.getTimestamp(),
  },
};
