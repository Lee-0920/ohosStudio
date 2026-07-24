
import { MeasureRunning } from 'dataservice';

// export interface MeasureRunning {
//   isMeasuring: boolean;        // 是否正常测量，用于测量过程中断电或重启后重新测量
//   isCorrectStopFlow: boolean;  // 用于区分是否为掉电保护调用的停止流程
//   lastMeasureTime: number;     // 上次测量时间
// }

// 测量运行状态配置
export const measureRunning: MeasureRunning = {
  isMeasuring: false,
  isCorrectStopFlow: true,
  lastMeasureTime: 0,
};
