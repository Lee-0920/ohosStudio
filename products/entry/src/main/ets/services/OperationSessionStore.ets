import { MaintenceType } from 'flow';
import { WqMaintenanceRow, WqOperationConfigRow } from '../pages/operation/OperationTypes';

export interface OperationSessionState {
  selectedOperationTab: string;
  maintenanceRows: WqMaintenanceRow[];
  selectedCombinationFlow: string;
  combinationCount: string;
  combinationMode: string;
  nextCombinationId: number;
  combinationRunning: boolean;
  selectedPipeMode: string;
  combinationTaskMessage: string;
  pipeOperationMessage: string;
  combinationRows: WqOperationConfigRow[];
  pipeRows: WqOperationConfigRow[];
  hardwareRows: WqOperationConfigRow[];
  reagentRows: WqOperationConfigRow[];
  hardwareCalibrationRows: WqOperationConfigRow[];
  combinationOperationMessage: string;
  combinationOperationRows: WqOperationConfigRow[];
  upgradeRows: WqOperationConfigRow[];
  consumableRows: WqOperationConfigRow[];
  communicationRows: WqOperationConfigRow[];
  diagnoseRows: WqOperationConfigRow[];
}

// 运维页会话级缓存。顶部菜单切换会销毁 OperationPage，本 store 保留当前会话内的表格状态和选择状态。
export class OperationSessionStore {
  private static state: OperationSessionState | null = null;

  static getState(defaultState: OperationSessionState): OperationSessionState {
    if (!OperationSessionStore.state) {
      OperationSessionStore.state = OperationSessionStore.cloneState(defaultState);
    }
    return OperationSessionStore.cloneState(OperationSessionStore.state);
  }

  static updateState(state: OperationSessionState): void {
    OperationSessionStore.state = OperationSessionStore.cloneState(state);
  }

  private static cloneState(state: OperationSessionState): OperationSessionState {
    return {
      selectedOperationTab: state.selectedOperationTab,
      maintenanceRows: OperationSessionStore.cloneMaintenanceRows(state.maintenanceRows),
      selectedCombinationFlow: state.selectedCombinationFlow,
      combinationCount: state.combinationCount,
      combinationMode: state.combinationMode,
      nextCombinationId: state.nextCombinationId,
      combinationRunning: state.combinationRunning,
      selectedPipeMode: state.selectedPipeMode,
      combinationTaskMessage: state.combinationTaskMessage,
      pipeOperationMessage: state.pipeOperationMessage,
      combinationRows: OperationSessionStore.cloneConfigRows(state.combinationRows),
      pipeRows: OperationSessionStore.cloneConfigRows(state.pipeRows),
      hardwareRows: OperationSessionStore.cloneConfigRows(state.hardwareRows),
      reagentRows: OperationSessionStore.cloneConfigRows(state.reagentRows),
      hardwareCalibrationRows: OperationSessionStore.cloneConfigRows(state.hardwareCalibrationRows),
      combinationOperationMessage: state.combinationOperationMessage,
      combinationOperationRows: OperationSessionStore.cloneConfigRows(state.combinationOperationRows),
      upgradeRows: OperationSessionStore.cloneConfigRows(state.upgradeRows),
      consumableRows: OperationSessionStore.cloneConfigRows(state.consumableRows),
      communicationRows: OperationSessionStore.cloneConfigRows(state.communicationRows),
      diagnoseRows: OperationSessionStore.cloneConfigRows(state.diagnoseRows)
    };
  }

  private static cloneMaintenanceRows(rows: WqMaintenanceRow[]): WqMaintenanceRow[] {
    const clonedRows: WqMaintenanceRow[] = [];
    rows.forEach((row: WqMaintenanceRow) => {
      clonedRows.push({
        id: row.id,
        project: row.project,
        count: row.count,
        isRunning: row.isRunning,
        status: row.status,
        result: row.result,
        maintenceType: row.maintenceType,
        params: row.params,
      });
    });
    return clonedRows;
  }

  private static cloneConfigRows(rows: WqOperationConfigRow[]): WqOperationConfigRow[] {
    const clonedRows: WqOperationConfigRow[] = [];
    rows.forEach((row: WqOperationConfigRow) => {
      clonedRows.push({
        id: row.id,
        category: row.category,
        name: row.name,
        value: row.value,
        value2: row.value2,
        value3: row.value3,
        value4: row.value4,
        unit: row.unit,
        status: row.status,
        result: row.result,
        selected: row.selected,
        running: row.running
      });
    });
    return clonedRows;
  }
}
