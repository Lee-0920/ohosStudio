import { hilog } from '@kit.PerformanceAnalysisKit';
import { emitter, Callback } from '@kit.BasicServicesKit';
import { DataStore, REG_ADDR, SystemStatus, CurrentAction } from 'modbus';
import { DeviceEventBus } from './DeviceEventBus';
import { DeviceStateStore } from './DeviceStateStore';
import { DeviceEvent, RuntimeSnapshot } from '../models/deviceStateTypes';
import { WorkerMeasureStatusEvent, MeasureType } from 'flow';

const DOMAIN = 0x0000;
const TAG = 'ModbusRuntimeSyncService';

/**
 * 把应用层运行状态同步到 feature/modbus 的 DataStore，
 * 使 Modbus 地址 16（系统状态）和 17（当前动作）能返回实时值。
 *
 * 状态来源有两处：
 * 1. DeviceStateStore 的 runtime 快照（传统轮询路径）。
 * 2. Worker 线程通过 emitter 发送的 MeasureStatus 事件（测量流程直接驱动路径）。
 *
 * Worker 事件到达时，直接覆盖 DeviceStateStore 的缓存，确保 Modbus 读取能反映
 * 实际正在执行的测量状态。
 */
export class ModbusRuntimeSyncService {
  private static instance: ModbusRuntimeSyncService | null = null;
  private unsubscribeRuntime: (() => void) | null = null;
  private workerEmitterCallback: Callback<emitter.EventData> | null = null;
  /**
   * Worker 事件驱动期间，DeviceStateStore 的 runtime 快照不应覆盖 DataStore。
   * 否则 Modbus 读取到的系统状态/当前动作会被轮询到的旧/空值刷回“空闲”。
   */
  private workerEventActive: boolean = false;

  static getInstance(): ModbusRuntimeSyncService {
    if (!ModbusRuntimeSyncService.instance) {
      ModbusRuntimeSyncService.instance = new ModbusRuntimeSyncService();
    }
    return ModbusRuntimeSyncService.instance;
  }

  /**
   * 启动同步服务。应在 DeviceStateStore 初始化后调用。
   */
  start(): void {
    if (this.unsubscribeRuntime) {
      hilog.warn(DOMAIN, TAG, 'already started');
      return;
    }

    // 立即同步一次当前状态
    this.syncRuntimeToModbus(DeviceStateStore.getRuntimeSnapshot());

    // 订阅 runtime 事件，状态变化时实时同步
    this.unsubscribeRuntime = DeviceEventBus.subscribe('runtime', (event: DeviceEvent) => {
      this.syncRuntimeToModbus(event.current as RuntimeSnapshot);
    });

    // 订阅 Worker 线程发送的测量进度事件
    this.subscribeWorkerMeasureStatus();

    hilog.info(DOMAIN, TAG, 'started');
  }

  /**
   * 停止同步服务。
   */
  stop(): void {
    if (this.unsubscribeRuntime) {
      this.unsubscribeRuntime();
      this.unsubscribeRuntime = null;
    }
    if (this.workerEmitterCallback) {
      emitter.off('MeasureStatus', this.workerEmitterCallback);
      this.workerEmitterCallback = null;
    }
    // 服务停止时清理 Worker 活跃标记，防止重启后仍然阻塞 runtime 快照同步
    this.workerEventActive = false;
    hilog.info(DOMAIN, TAG, 'stopped');
  }

  /**
   * 订阅 Worker 线程的 MeasureStatus 事件。
   */
  private subscribeWorkerMeasureStatus(): void {
    const callback: Callback<emitter.EventData> = (eventData: emitter.EventData) => {
      const data = eventData.data as WorkerMeasureStatusEvent;
      if (!data || data.type !== 'measureProgress') {
        return;
      }
      this.applyWorkerMeasureStatus(data);
    };
    this.workerEmitterCallback = callback;
    emitter.on('MeasureStatus', callback);
  }

  /**
   * 处理 Worker 测量进度事件，直接写入 DataStore。
   */
  private applyWorkerMeasureStatus(data: WorkerMeasureStatusEvent): void {
    const dataStore = DataStore.getInstance();

    if (data.phase === 'end') {
      this.workerEventActive = false;
      dataStore.setUInt16(REG_ADDR.SYSTEM_STATUS, SystemStatus.IDLE);
      dataStore.setUInt16(REG_ADDR.CURRENT_ACTION, CurrentAction.IDLE);
      hilog.info(DOMAIN, TAG, 'worker measure end, sync idle');
      return;
    }

    // Worker 事件到达即认为进入 Worker 驱动周期，后续 runtime 快照不再覆盖 DataStore
    this.workerEventActive = true;

    const statusCode = data.systemStatusCode !== undefined
      ? data.systemStatusCode
      : this.mapMeasureTypeToSystemStatus(data.measureType);
    const actionCode = this.mapActionLabelToCurrentAction(data.actionLabel, statusCode);

    dataStore.setUInt16(REG_ADDR.SYSTEM_STATUS, statusCode);
    dataStore.setUInt16(REG_ADDR.CURRENT_ACTION, actionCode);

    hilog.debug(DOMAIN, TAG, 'worker sync status=%{public}d action=%{public}d', statusCode, actionCode);
  }

  /**
   * 将 runtime 快照中的系统状态和当前动作写入 modbus DataStore。
   */
  private syncRuntimeToModbus(snapshot: RuntimeSnapshot): void {
    if (!snapshot || !snapshot.valid) {
      return;
    }

    // Worker 事件驱动期间，跳过 DeviceStateStore 的 runtime 快照同步，
    // 避免把“空闲”等旧状态覆盖到 Modbus 地址 16/17。
    if (this.workerEventActive) {
      hilog.debug(DOMAIN, TAG, 'ignore runtime snapshot while worker event is active');
      return;
    }

    const dataStore = DataStore.getInstance();
    const systemStatus = snapshot.systemStatusCode ?? 0;
    const currentAction = snapshot.currentActionCode ?? 0;

    dataStore.setUInt16(REG_ADDR.SYSTEM_STATUS, systemStatus);
    dataStore.setUInt16(REG_ADDR.CURRENT_ACTION, currentAction);

    hilog.debug(DOMAIN, TAG, 'store sync status=%{public}d action=%{public}d', systemStatus, currentAction);
  }

  /**
   * 把测量类型映射为 Modbus 系统状态码。
   */
  private mapMeasureTypeToSystemStatus(measureType: MeasureType): number {
    switch (measureType) {
      case MeasureType.Sample:
      case MeasureType.AddStandard:
      case MeasureType.Parallel:
      case MeasureType.ExtAddStandard:
      case MeasureType.ExtParallel:
        return SystemStatus.MEASURING_WATER;
      case MeasureType.Standard:
        return SystemStatus.MEASURING_RANGE_CAL;
      case MeasureType.Blank:
        return SystemStatus.MEASURING_ZERO_CAL;
      case MeasureType.Check:
      case MeasureType.RangeCheck:
        return SystemStatus.CHECK_SOLUTION;
      case MeasureType.ZeroCheck:
        return SystemStatus.CHECK_SOLUTION;
      case MeasureType.QualityHandle:
        return SystemStatus.QUALITY_CONTROL;
      default:
        return SystemStatus.IDLE;
    }
  }

  /**
   * 把动作中文标签映射为 Modbus 当前动作码。
   * @param statusCode 当前系统状态码，用于区分同名动作（如“清洗”在清洗定量管和清洗消解室中含义不同）。
   */
  private mapActionLabelToCurrentAction(actionLabel: string, statusCode?: number): number {
    switch (actionLabel) {
      case '测量前排液':
      case '测量前清洗':
        return CurrentAction.PRE_MEASURE_CLEAN;
      case '读空白值':
        return CurrentAction.READ_INITIAL;
      case '润洗':
        return CurrentAction.RINSING;
      case '加待测样':
        return CurrentAction.ADD_SAMPLE;
      case '加试剂一':
        return CurrentAction.ADD_REAGENT_1;
      case '加试剂二':
        return CurrentAction.ADD_REAGENT_2;
      case '清洗定量管':
        return CurrentAction.CLEAN_QUANT_TUBE;
      case '清洗消解室':
        return CurrentAction.CLEANING;
      case '清洗':
        // 根据系统状态区分清洗定量管和普通清洗/深度清洗
        if (statusCode === SystemStatus.CLEANING_QUANT_TUBE) {
          return CurrentAction.CLEAN_QUANT_TUBE;
        }
        return CurrentAction.CLEANING;
      case '清洗水样管':
      case '排空水样管':
        return CurrentAction.DRAIN_SAMPLE;
      case '清洗量程校准液管':
      case '排空量程校准液管':
        return CurrentAction.DRAIN_STANDARD;
      case '清洗试剂一管':
      case '排空试剂一管':
        return CurrentAction.DRAIN_REAGENT_1;
      case '清洗试剂二管':
      case '排空试剂二管':
        return CurrentAction.DRAIN_REAGENT_2;
      case '清洗零点校准液管':
      case '填充零点校准液':
        return CurrentAction.FILL_BLANK;
      case '消解液预热':
        return CurrentAction.DIGESTION_PREHEAT;
      case '消解加热':
        return CurrentAction.HEAT_DIGESTION;
      case '消解冷却':
        return CurrentAction.DIGESTION_COOLING;
      case '读反应值':
        return CurrentAction.READ_REACTION;
      case '测量后排液':
      case '测量后清洗':
        return CurrentAction.CLEANING;
      case '冷却':
        return CurrentAction.COOLING;
      case '采集':
        return CurrentAction.COLLECTING;
      case '静置':
        return CurrentAction.STANDING;
      case '排空定量管':
        // 定量泵校准期间该动作属于校准；清洗/深度清洗期间属于清洗
        return statusCode === SystemStatus.QUANT_PUMP_CAL
          ? CurrentAction.CALIBRATING
          : CurrentAction.CLEANING;
      case '定量至最小定量点':
      case '定量至最大定量点':
        return CurrentAction.CALIBRATING;
      case '空闲':
      default:
        return CurrentAction.IDLE;
    }
  }
}
