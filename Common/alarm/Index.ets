// lhipstudio/Common/alarm/Index.ets

// 导出告警码和类型
export { AlarmCode, AlarmType, AlarmCodeDescriptions, AlarmTypeMap, getAlarmDescription, getAlarmType } from './src/main/ets/model/AlarmCode';

// 导出告警记录和状态
export { AlarmRecord, AlarmStatus } from './src/main/ets/model/AlarmRecord';

// 导出告警管理器
export { AlarmManager, AlarmCallback } from './src/main/ets/model/AlarmManager';

// 导出页面组件
export { AlarmListPage } from './src/main/ets/components/AlarmListPage';
