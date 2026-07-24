import { common } from '@kit.AbilityKit';
import { GradientSideTabBar } from '../components/GradientSideTabBar';
import { OperationRecordService, OperationRecordValue } from '../services/OperationRecordService';
import { OperationSessionState, OperationSessionStore } from '../services/OperationSessionStore';
import { CombinationMaintenancePanel } from './operation/CombinationMaintenancePanel';
import { CombinationOperationPanel } from './operation/CombinationOperationPanel';
import { CommunicationCheckPanel } from './operation/CommunicationCheckPanel';
import { ConsumableManagementPanel } from './operation/ConsumableManagementPanel';
import { HardwareCalibrationPanel } from './operation/HardwareCalibrationPanel';
import { HardwareTestPanel } from './operation/HardwareTestPanel';
import { IntelligentDiagnosisPanel } from './operation/IntelligentDiagnosisPanel';
import { MaintenancePanel } from './operation/MaintenancePanel';
import { PipeOperationPanel } from './operation/PipeOperationPanel';
import { ReagentManagementPanel } from './operation/ReagentManagementPanel';
import { UpgradePanel } from './operation/UpgradePanel';
import { WqMaintenanceRow, WqOperationConfigRow } from './operation/OperationTypes';
import { MaintenceType, MeasureType, CleanType } from 'flow';

@Component
export struct OperationPage {
  @Prop viewportWidth: number = 1024;
  @Prop viewportHeight: number = 768;
  @Prop scaleFactor: number = 1.92;

  @State private selectedOperationTab: string = '维护';
  @State private maintenanceRows: WqMaintenanceRow[] = [
    { id: 'sample', project: '测量水样', count: '1', isRunning: false, status: '待执行', result: '', maintenceType: MaintenceType.AutoMeasure, params: MeasureType.Sample},
    { id: 'calibration', project: '校准', count: '1', isRunning: false, status: '待执行', result: '', maintenceType: MaintenceType.AutoCalibrate},
    { id: 'span-check', project: '标样(跨度)核查', count: '1', isRunning: false, status: '待执行', result: '', maintenceType: MaintenceType.AutoMeasure, params: MeasureType.RangeCheck},
    { id: 'zero-check', project: '零点核查', count: '1', isRunning: false, status: '待执行', result: '', maintenceType: MaintenceType.AutoMeasure, params: MeasureType.ZeroCheck},
    { id: 'range-calibration', project: '量程校准', count: '1', isRunning: false, status: '待执行', result: '', maintenceType: MaintenceType.AutoCalibrate, params: MeasureType.Standard},
    { id: 'zero-calibration', project: '零点校准', count: '1', isRunning: false, status: '待执行', result: '', maintenceType: MaintenceType.AutoCalibrate, params: MeasureType.Blank},
    { id: 'update-reagent', project: '一键更新试剂', count: '1', isRunning: false, status: '待执行', result: '', maintenceType: MaintenceType.AutoClean, params: CleanType.oneKeyRenew},
    { id: 'quality-control', project: '测质控样', count: '1', isRunning: false, status: '待执行', result: '', maintenceType: MaintenceType.AutoMeasure, params: MeasureType.QualityHandle},
    { id: 'measure-range-calibration-solution', project: '测量程校准液', count: '1', isRunning: false, status: '待执行', result: '', maintenceType: MaintenceType.AutoMeasure, params: MeasureType.Standard},
    { id: 'measure-zero-calibration-solution', project: '测量零点校准液', count: '1', isRunning: false, status: '待执行', result: '', maintenceType: MaintenceType.AutoMeasure, params: MeasureType.Blank},
    { id: 'clean-quantitative-tube', project: '清洗定量管', count: '1', isRunning: false, status: '待执行', result: '', maintenceType: MaintenceType.AutoClean, params: CleanType.cleanMeterPipe},
    { id: 'clean-digestion-chamber', project: '清洗消解室', count: '1', isRunning: false, status: '待执行', result: '', maintenceType: MaintenceType.AutoClean, params: CleanType.cleanDigestionRoom},
    { id: 'deep-cleaning', project: '深度清洗', count: '1', isRunning: false, status: '待执行', result: '', maintenceType: MaintenceType.AutoClean, params: CleanType.cleanDeeply},
    { id: 'clean-all-pipelines', project: '清洗所有管路', count: '1', isRunning: false, status: '待执行', result: '', maintenceType: MaintenceType.AutoClean, params: CleanType.cleanAll},
    { id: 'collect-water-sample', project: '采集水样', count: '1', isRunning: false, status: '待执行', result: '', maintenceType: MaintenceType.AutoCollectSample},
    { id: 'quantitative-pump-calibration', project: '定量泵自动校准', count: '1', isRunning: false, status: '待执行', result: '', maintenceType: MaintenceType.AutoPumpCalibrate},
    { id: 'quantitative-ad-adjust', project: '定量AD调节', count: '1', isRunning: false, status: '待执行', result: '', maintenceType: MaintenceType.AutoADAdjust, params: MeasureType.Blank},
    { id: 'measurement-ad-adjust', project: '测量AD调节', count: '1', isRunning: false, status: '待执行', result: '', maintenceType: MaintenceType.AutoADAdjust, params: MeasureType.Sample},
    { id: 'range-one-factor', project: '量程一因子', count: '1', isRunning: false, status: '待执行', result: '', maintenceType: MaintenceType.AutoMeasure, params: MeasureType.Standard},
    { id: 'range-two-factor', project: '量程二因子', count: '1', isRunning: false, status: '待执行', result: '', maintenceType: MaintenceType.AutoMeasure, params: MeasureType.Standard },
    { id: 'range-three-factor', project: '量程三因子', count: '1', isRunning: false, status: '待执行', result: '', maintenceType: MaintenceType.AutoMeasure, params: MeasureType.Standard}
  ];
  @State private selectedCombinationFlow: string = '测量水样';
  @State private combinationCount: string = '1';
  @State private combinationMode: string = '连续测试';
  @State private nextCombinationId: number = 1;
  @State private combinationRunning: boolean = false;
  @State private selectedPipeMode: string = '精确定量';
  @State private combinationTaskMessage: string = '';
  @State private pipeOperationMessage: string = '';
  @State private combinationRows: WqOperationConfigRow[] = [];
  @State private pipeRows: WqOperationConfigRow[] = [
    { id: 'pipe-zero-to-cell', category: '', name: '填充零点校准液', value: '1', value2: 'blank', value3: 'in', value4: '', unit: 'mL', status: '', result: '', selected: false, running: false },
    { id: 'pipe-drain-zero', category: '', name: '排至零点校准液', value: '1', value2: 'blank', value3: 'out', value4: '', unit: 'mL', status: '', result: '', selected: false, running: false },
    { id: 'pipe-water-sample', category: '', name: '填充水样', value: '1', value2: 'sample', value3: 'in', value4: '', unit: 'mL', status: '', result: '', selected: false, running: false },
    { id: 'pipe-range-liquid', category: '', name: '填充量程校准液', value: '1', value2: 'standard', value3: 'in', value4: '', unit: 'mL', status: '', result: '', selected: false, running: false },
    { id: 'pipe-zero-check', category: '', name: '填充零点核查液', value: '1', value2: 'zeroCheck', value3: 'in', value4: '', unit: 'mL', status: '', result: '', selected: false, running: false },
    { id: 'pipe-span-check', category: '', name: '填充标样(跨度)核查液', value: '1', value2: 'rangeCheck', value3: 'in', value4: '', unit: 'mL', status: '', result: '', selected: false, running: false }
  ];
  @State private hardwareRows: WqOperationConfigRow[] = [
    { id: 'hardware-metering-pump', category: '泵组', name: '定量泵', value: '', value2: '', value3: '', value4: '', unit: '', status: '关闭', result: '', selected: false, running: false },
    { id: 'hardware-water-valve', category: '旋切阀组', name: '水样阀', value: '', value2: '', value3: '', value4: '', unit: '', status: '关闭', result: '', selected: false, running: false },
    { id: 'hardware-reagent-one-valve', category: '', name: '试剂一阀', value: '', value2: '', value3: '', value4: '', unit: '', status: '关闭', result: '', selected: false, running: false },
    { id: 'hardware-reagent-two-valve', category: '', name: '试剂二阀', value: '', value2: '', value3: '', value4: '', unit: '', status: '关闭', result: '', selected: false, running: false },
    { id: 'hardware-blank-valve', category: '', name: '零点校准液阀', value: '', value2: '', value3: '', value4: '', unit: '', status: '关闭', result: '', selected: false, running: false },
    { id: 'hardware-range-valve', category: '', name: '量程校准液阀', value: '', value2: '', value3: '', value4: '', unit: '', status: '关闭', result: '', selected: false, running: false },
    { id: 'hardware-range-check-valve', category: '', name: '标样(跨度)核查液阀', value: '', value2: '', value3: '', value4: '', unit: '', status: '关闭', result: '', selected: false, running: false },
    { id: 'hardware-zero-check-valve', category: '', name: '零点核查液阀', value: '', value2: '', value3: '', value4: '', unit: '', status: '关闭', result: '', selected: false, running: false },
    { id: 'hardware-digestion-heater', category: '消解模块', name: '消解室加热', value: '', value2: '', value3: '', value4: '', unit: '', status: '关闭', result: '', selected: false, running: false },
    { id: 'hardware-meter-one-light', category: '定量模块', name: '定量1LED', value: '', value2: '', value3: '', value4: '', unit: '', status: '关闭', result: '', selected: false, running: false },
    { id: 'hardware-meter-two-light', category: '', name: '定量2LED', value: '', value2: '', value3: '', value4: '', unit: '', status: '关闭', result: '', selected: false, running: false },
    { id: 'hardware-measure-light', category: '测量模块', name: '测量光源', value: '', value2: '', value3: '', value4: '', unit: '', status: '关闭', result: '', selected: false, running: false },
    { id: 'hardware-sampling-relay', category: '采水继电器', name: '采水继电器', value: '', value2: '', value3: '', value4: '', unit: '', status: '关闭', result: '', selected: false, running: false },
    { id: 'hardware-current-output', category: '样品4-20mA', name: '模拟量输出', value: '', value2: '', value3: '', value4: '', unit: '', status: '关闭', result: '', selected: false, running: false }
  ];
  @State private reagentRows: WqOperationConfigRow[] = [
    { id: 'reagent-range-liquid', category: '', name: '量程校准液', value: '2024.10.10', value2: '250', value3: '250', value4: '3', unit: 'mL', status: '', result: '', selected: false, running: false },
    { id: 'reagent-zero-liquid', category: '', name: '零点校准液', value: '2024.10.10', value2: '5000', value3: '5000', value4: '3', unit: 'mL', status: '', result: '', selected: false, running: false },
    { id: 'reagent-zero-check', category: '', name: '零点核查液', value: '2024.10.10', value2: '250', value3: '250', value4: '3', unit: 'mL', status: '', result: '', selected: false, running: false },
    { id: 'reagent-span-check', category: '', name: '标样(跨度)核查液', value: '2024.10.10', value2: '250', value3: '250', value4: '3', unit: 'mL', status: '', result: '', selected: false, running: false },
    { id: 'reagent-waste-analysis', category: '', name: '分析废液桶', value: '2024.10.10', value2: '10000', value3: '10000', value4: '3', unit: 'mL', status: '', result: '', selected: false, running: false },
    { id: 'reagent-waste-clean', category: '', name: '清洗废水桶', value: '2024.10.10', value2: '10000', value3: '10000', value4: '3', unit: 'mL', status: '', result: '', selected: false, running: false }
  ];
  @State private hardwareCalibrationRows: WqOperationConfigRow[] = [
    { id: 'calibration-metering-pump', category: '泵校准', name: '定量泵', value: '0.00076', value2: '0.000680', value3: '', value4: '', unit: 'mL/步', status: '', result: '', selected: false, running: false },
    { id: 'calibration-metering-ad', category: 'AD调节', name: '定量AD', value: '2048', value2: '2048', value3: '', value4: '', unit: '', status: '', result: '', selected: false, running: false },
    { id: 'calibration-measure-ad', category: '', name: '测量AD', value: '2048', value2: '2048', value3: '', value4: '', unit: '', status: '', result: '', selected: false, running: false }
  ];
  @State private combinationOperationRows: WqOperationConfigRow[] = [
    { id: 'combo-operation-zero-to-cell', category: '', name: '吸零点校准液至消解室', value: '1.30', value2: '', value3: '', value4: '', unit: 'mL', status: '', result: '', selected: false, running: false },
    { id: 'combo-operation-drain-analysis', category: '', name: '排消解液至分析废液', value: '1.70', value2: '', value3: '', value4: '', unit: 'mL', status: '', result: '', selected: false, running: false },
    { id: 'combo-operation-drain-clean', category: '', name: '排消解液至清洗废水', value: '1.70', value2: '', value3: '', value4: '', unit: 'mL', status: '', result: '', selected: false, running: false }
  ];
  @State private combinationOperationMessage: string = '';
  @State private upgradeRows: WqOperationConfigRow[] = [
    { id: 'upgrade-main-board', category: '', name: '主控板', value: '1.1', value2: '-', value3: '', value4: '', unit: '', status: '', result: '', selected: false, running: false },
    { id: 'upgrade-drive-board', category: '', name: '驱动板', value: '1.1.1', value2: '-', value3: '', value4: '', unit: '', status: '', result: '', selected: false, running: false }
  ];
  @State private consumableRows: WqOperationConfigRow[] = [
    { id: 'consumable-pump-tube', category: '', name: '蠕动泵软管', value: '2023.07.12', value2: '2026.07.12', value3: '36', value4: '', unit: '月', status: '', result: '', selected: false, running: false },
    { id: 'consumable-filter', category: '', name: '采样过滤头', value: '2024.10.10', value2: '2025.10.10', value3: '12', value4: '', unit: '月', status: '', result: '', selected: false, running: false },
    { id: 'consumable-tube', category: '', name: '水样管路', value: '2024.10.10', value2: '2025.10.10', value3: '12', value4: '', unit: '月', status: '', result: '', selected: false, running: false }
  ];
  @State private communicationRows: WqOperationConfigRow[] = [
    { id: 'communication-drive-board', category: '板卡通信', name: '驱动板', value: '', value2: '', value3: '', value4: '', unit: '', status: '', result: '', selected: true, running: false },
    { id: 'communication-adapter-board', category: '', name: '转接板', value: '', value2: '', value3: '', value4: '', unit: '', status: '', result: '', selected: false, running: false }
  ];
  @State private diagnoseRows: WqOperationConfigRow[] = [
    { id: 'diagnose-zero-valve', category: '', name: '零点校准液阀', value: '', value2: '', value3: '', value4: '', unit: '', status: '', result: '', selected: false, running: false },
    { id: 'diagnose-water-valve', category: '', name: '水样阀', value: '', value2: '', value3: '', value4: '', unit: '', status: '', result: '', selected: false, running: false },
    { id: 'diagnose-range-valve', category: '', name: '量程校准液阀', value: '', value2: '', value3: '', value4: '', unit: '', status: '', result: '', selected: false, running: false },
    { id: 'diagnose-zero-check-valve', category: '', name: '零点核查阀', value: '', value2: '', value3: '', value4: '', unit: '', status: '', result: '', selected: false, running: false },
    { id: 'diagnose-span-check-valve', category: '', name: '标样(跨度)核查阀', value: '', value2: '', value3: '', value4: '', unit: '', status: '', result: '', selected: false, running: false },
    { id: 'diagnose-reagent-one', category: '', name: '试剂一阀', value: '', value2: '', value3: '', value4: '', unit: '', status: '', result: '', selected: false, running: false },
    { id: 'diagnose-reagent-two', category: '', name: '试剂二阀', value: '', value2: '', value3: '', value4: '', unit: '', status: '', result: '', selected: false, running: false },
    { id: 'diagnose-digestion-air', category: '', name: '消解室阀', value: '', value2: '', value3: '', value4: '', unit: '', status: '', result: '', selected: false, running: false }
  ];

  private readonly operationTabs: string[] = [
    '维护',
    '组合维护',
    '管道操作',
    '硬件测试',
    '试剂管理',
    '硬件校准',
    '组合操作',
    '升级',
    '耗材管理',
    '通信检测',
    '智能诊断'
  ];

  aboutToAppear(): void {
    this.applySessionState(OperationSessionStore.getState(this.buildSessionState()));
    void this.loadLocalOperationRecords();
  }

  aboutToDisappear(): void {
    this.saveSessionState();
  }

  private getHostContext(): common.Context | null {
    const context = this.getUIContext().getHostContext();
    if (!context) {
      return null;
    }
    return context as common.Context;
  }

  private buildSessionState(): OperationSessionState {
    const state: OperationSessionState = {
      selectedOperationTab: this.selectedOperationTab,
      maintenanceRows: this.maintenanceRows,
      selectedCombinationFlow: this.selectedCombinationFlow,
      combinationCount: this.combinationCount,
      combinationMode: this.combinationMode,
      nextCombinationId: this.nextCombinationId,
      combinationRunning: this.combinationRunning,
      selectedPipeMode: this.selectedPipeMode,
      combinationTaskMessage: this.combinationTaskMessage,
      pipeOperationMessage: this.pipeOperationMessage,
      combinationRows: this.combinationRows,
      pipeRows: this.pipeRows,
      hardwareRows: this.hardwareRows,
      reagentRows: this.reagentRows,
      hardwareCalibrationRows: this.hardwareCalibrationRows,
      combinationOperationMessage: this.combinationOperationMessage,
      combinationOperationRows: this.combinationOperationRows,
      upgradeRows: this.upgradeRows,
      consumableRows: this.consumableRows,
      communicationRows: this.communicationRows,
      diagnoseRows: this.diagnoseRows
    };
    return state;
  }

  private applySessionState(state: OperationSessionState): void {
    this.selectedOperationTab = state.selectedOperationTab;
    this.maintenanceRows = state.maintenanceRows;
    this.selectedCombinationFlow = state.selectedCombinationFlow;
    this.combinationCount = state.combinationCount;
    this.combinationMode = state.combinationMode;
    this.nextCombinationId = state.nextCombinationId;
    this.combinationRunning = state.combinationRunning;
    this.selectedPipeMode = state.selectedPipeMode;
    this.combinationTaskMessage = state.combinationTaskMessage;
    this.pipeOperationMessage = state.pipeOperationMessage;
    this.combinationRows = state.combinationRows;
    this.pipeRows = state.pipeRows;
    this.hardwareRows = state.hardwareRows;
    this.reagentRows = state.reagentRows;
    this.hardwareCalibrationRows = state.hardwareCalibrationRows;
    this.combinationOperationMessage = state.combinationOperationMessage;
    this.combinationOperationRows = state.combinationOperationRows;
    this.upgradeRows = state.upgradeRows;
    this.consumableRows = state.consumableRows;
    this.communicationRows = state.communicationRows;
    this.diagnoseRows = state.diagnoseRows;
  }

  private saveSessionState(): void {
    OperationSessionStore.updateState(this.buildSessionState());
  }

  private async loadLocalOperationRecords(): Promise<void> {
    const context = this.getHostContext();
    if (!context) {
      return;
    }

    const reagentValues = await OperationRecordService.loadValues(
      context,
      'reagent',
      this.toRecordValues(this.reagentRows)
    );
    this.reagentRows = this.applyRecordValues(this.reagentRows, reagentValues);

    const consumableValues = await OperationRecordService.loadValues(
      context,
      'consumable',
      this.toRecordValues(this.consumableRows)
    );
    this.consumableRows = this.applyRecordValues(this.consumableRows, consumableValues);

    const hardwareCalibrationValues = await OperationRecordService.loadValues(
      context,
      'hardware_calibration',
      this.toRecordValues(this.hardwareCalibrationRows)
    );
    this.hardwareCalibrationRows = this.applyRecordValues(this.hardwareCalibrationRows, hardwareCalibrationValues);
    this.saveSessionState();
  }

  private toRecordValues(rows: WqOperationConfigRow[]): OperationRecordValue[] {
    const values: OperationRecordValue[] = [];
    rows.forEach((row: WqOperationConfigRow) => {
      values.push({
        id: row.id,
        value: row.value,
        value2: row.value2,
        value3: row.value3,
        value4: row.value4
      });
    });
    return values;
  }

  private applyRecordValues(
    rows: WqOperationConfigRow[],
    values: OperationRecordValue[]
  ): WqOperationConfigRow[] {
    return rows.map((row: WqOperationConfigRow) => {
      for (let i = 0; i < values.length; i++) {
        if (values[i].id === row.id) {
          return {
            id: row.id,
            category: row.category,
            name: row.name,
            value: values[i].value,
            value2: values[i].value2,
            value3: values[i].value3,
            value4: values[i].value4,
            unit: row.unit,
            status: row.status,
            result: row.result,
            selected: row.selected,
            running: row.running
          };
        }
      }
      return row;
    });
  }

  private saveOperationRows(group: string, rows: WqOperationConfigRow[]): void {
    const context = this.getHostContext();
    if (!context) {
      return;
    }
    void OperationRecordService.saveValues(context, group, this.toRecordValues(rows));
  }

  private handleReagentRowsChange(rows: WqOperationConfigRow[]): void {
    this.reagentRows = rows;
    this.saveOperationRows('reagent', rows);
    this.saveSessionState();
  }

  private handleMaintenanceRowsChange(rows: WqMaintenanceRow[]): void {
    this.maintenanceRows = rows;
    this.saveSessionState();
  }

  private handleCombinationRowsChange(rows: WqOperationConfigRow[]): void {
    this.combinationRows = rows;
    this.saveSessionState();
  }

  private handleSelectedCombinationFlowChange(value: string): void {
    this.selectedCombinationFlow = value;
    this.saveSessionState();
  }

  private handleCombinationCountChange(value: string): void {
    this.combinationCount = value;
    this.saveSessionState();
  }

  private handleCombinationModeChange(value: string): void {
    this.combinationMode = value;
    this.saveSessionState();
  }

  private handleNextCombinationIdChange(value: number): void {
    this.nextCombinationId = value;
    this.saveSessionState();
  }

  private handleCombinationRunningChange(value: boolean): void {
    this.combinationRunning = value;
    this.saveSessionState();
  }

  private handlePipeRowsChange(rows: WqOperationConfigRow[]): void {
    this.pipeRows = rows;
    this.saveSessionState();
  }

  private handleSelectedPipeModeChange(value: string): void {
    this.selectedPipeMode = value;
    this.saveSessionState();
  }

  private handleCombinationTaskMessageChange(value: string): void {
    this.combinationTaskMessage = value;
    this.saveSessionState();
  }

  private handlePipeOperationMessageChange(value: string): void {
    this.pipeOperationMessage = value;
    this.saveSessionState();
  }

  private handleHardwareRowsChange(rows: WqOperationConfigRow[]): void {
    this.hardwareRows = rows;
    this.saveSessionState();
  }

  private handleConsumableRowsChange(rows: WqOperationConfigRow[]): void {
    this.consumableRows = rows;
    this.saveOperationRows('consumable', rows);
    this.saveSessionState();
  }

  private handleHardwareCalibrationRowsChange(rows: WqOperationConfigRow[]): void {
    this.hardwareCalibrationRows = rows;
    this.saveOperationRows('hardware_calibration', rows);
    this.saveSessionState();
  }

  private handleCombinationOperationRowsChange(rows: WqOperationConfigRow[]): void {
    this.combinationOperationRows = rows;
    this.saveSessionState();
  }

  private handleCombinationOperationMessageChange(value: string): void {
    this.combinationOperationMessage = value;
    this.saveSessionState();
  }

  private handleUpgradeRowsChange(rows: WqOperationConfigRow[]): void {
    this.upgradeRows = rows;
    this.saveSessionState();
  }

  private handleCommunicationRowsChange(rows: WqOperationConfigRow[]): void {
    this.communicationRows = rows;
    this.saveSessionState();
  }

  private handleDiagnoseRowsChange(rows: WqOperationConfigRow[]): void {
    this.diagnoseRows = rows;
    this.saveSessionState();
  }

  @Builder
  private emptyPanel() {
    Column() {
      Blank()
    }
    .layoutWeight(1)
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  @Builder
  private operationContent() {
    if (this.selectedOperationTab === '维护') {
      MaintenancePanel({
        maintenanceRows: this.maintenanceRows,
        viewportWidth: this.viewportWidth,
        viewportHeight: this.viewportHeight,
        scaleFactor: this.scaleFactor,
        onRowsChange: (rows: WqMaintenanceRow[]) => {
          this.handleMaintenanceRowsChange(rows);
        }
      });
    } else if (this.selectedOperationTab === '组合维护') {
      CombinationMaintenancePanel({
        selectedCombinationFlow: this.selectedCombinationFlow,
        combinationCount: this.combinationCount,
        combinationMode: this.combinationMode,
        nextCombinationId: this.nextCombinationId,
        combinationRunning: this.combinationRunning,
        taskMessage: this.combinationTaskMessage,
        combinationRows: this.combinationRows,
        viewportWidth: this.viewportWidth,
        viewportHeight: this.viewportHeight,
        scaleFactor: this.scaleFactor,
        onRowsChange: (rows: WqOperationConfigRow[]) => {
          this.handleCombinationRowsChange(rows);
        },
        onSelectedFlowChange: (value: string) => {
          this.handleSelectedCombinationFlowChange(value);
        },
        onCountChange: (value: string) => {
          this.handleCombinationCountChange(value);
        },
        onModeChange: (value: string) => {
          this.handleCombinationModeChange(value);
        },
        onNextIdChange: (value: number) => {
          this.handleNextCombinationIdChange(value);
        },
        onRunningChange: (value: boolean) => {
          this.handleCombinationRunningChange(value);
        },
        onTaskMessageChange: (value: string) => {
          this.handleCombinationTaskMessageChange(value);
        }
      });
    } else if (this.selectedOperationTab === '管道操作') {
      PipeOperationPanel({
        selectedPipeMode: this.selectedPipeMode,
        pipeRows: this.pipeRows,
        operationMessage: this.pipeOperationMessage,
        viewportWidth: this.viewportWidth,
        viewportHeight: this.viewportHeight,
        scaleFactor: this.scaleFactor,
        onRowsChange: (rows: WqOperationConfigRow[]) => {
          this.handlePipeRowsChange(rows);
        },
        onModeChange: (value: string) => {
          this.handleSelectedPipeModeChange(value);
        },
        onMessageChange: (value: string) => {
          this.handlePipeOperationMessageChange(value);
        }
      });
    } else if (this.selectedOperationTab === '硬件测试') {
      HardwareTestPanel({
        hardwareRows: this.hardwareRows,
        viewportWidth: this.viewportWidth,
        viewportHeight: this.viewportHeight,
        scaleFactor: this.scaleFactor,
        onRowsChange: (rows: WqOperationConfigRow[]) => {
          this.handleHardwareRowsChange(rows);
        }
      });
    } else if (this.selectedOperationTab === '试剂管理') {
      ReagentManagementPanel({
        reagentRows: this.reagentRows,
        viewportWidth: this.viewportWidth,
        viewportHeight: this.viewportHeight,
        scaleFactor: this.scaleFactor,
        onRowsChange: (rows: WqOperationConfigRow[]) => {
          this.handleReagentRowsChange(rows);
        }
      });
    } else if (this.selectedOperationTab === '硬件校准') {
      HardwareCalibrationPanel({
        hardwareCalibrationRows: this.hardwareCalibrationRows,
        viewportWidth: this.viewportWidth,
        viewportHeight: this.viewportHeight,
        scaleFactor: this.scaleFactor,
        onRowsChange: (rows: WqOperationConfigRow[]) => {
          this.handleHardwareCalibrationRowsChange(rows);
        }
      });
    } else if (this.selectedOperationTab === '组合操作') {
      CombinationOperationPanel({
        combinationOperationRows: this.combinationOperationRows,
        operationMessage: this.combinationOperationMessage,
        viewportWidth: this.viewportWidth,
        viewportHeight: this.viewportHeight,
        scaleFactor: this.scaleFactor,
        onRowsChange: (rows: WqOperationConfigRow[]) => {
          this.handleCombinationOperationRowsChange(rows);
        },
        onMessageChange: (value: string) => {
          this.handleCombinationOperationMessageChange(value);
        }
      });
    } else if (this.selectedOperationTab === '升级') {
      UpgradePanel({
        upgradeRows: this.upgradeRows,
        viewportWidth: this.viewportWidth,
        viewportHeight: this.viewportHeight,
        scaleFactor: this.scaleFactor,
        onRowsChange: (rows: WqOperationConfigRow[]) => {
          this.handleUpgradeRowsChange(rows);
        }
      });
    } else if (this.selectedOperationTab === '耗材管理') {
      ConsumableManagementPanel({
        consumableRows: this.consumableRows,
        viewportWidth: this.viewportWidth,
        viewportHeight: this.viewportHeight,
        scaleFactor: this.scaleFactor,
        onRowsChange: (rows: WqOperationConfigRow[]) => {
          this.handleConsumableRowsChange(rows);
        }
      });
    } else if (this.selectedOperationTab === '通信检测') {
      CommunicationCheckPanel({
        communicationRows: this.communicationRows,
        viewportWidth: this.viewportWidth,
        viewportHeight: this.viewportHeight,
        scaleFactor: this.scaleFactor,
        onRowsChange: (rows: WqOperationConfigRow[]) => {
          this.handleCommunicationRowsChange(rows);
        }
      });
    } else if (this.selectedOperationTab === '智能诊断') {
      IntelligentDiagnosisPanel({
        diagnoseRows: this.diagnoseRows,
        viewportWidth: this.viewportWidth,
        viewportHeight: this.viewportHeight,
        scaleFactor: this.scaleFactor,
        onRowsChange: (rows: WqOperationConfigRow[]) => {
          this.handleDiagnoseRowsChange(rows);
        }
      });
    } else {
      this.emptyPanel();
    }
  }

  build() {
    Row() {
      GradientSideTabBar({
        tabs: this.operationTabs,
        selectedTab: this.selectedOperationTab,
        viewportWidth: this.viewportWidth,
        viewportHeight: this.viewportHeight,
        scaleFactor: this.scaleFactor,
        onTabChange: (tab: string) => {
          this.selectedOperationTab = tab;
          this.saveSessionState();
        }
      })

      this.operationContent();
    }
    .layoutWeight(1)
    .width('100%')
    .height('100%')
    .alignItems(VerticalAlign.Top)
    .backgroundColor('#F7F7F7')
  }
}
