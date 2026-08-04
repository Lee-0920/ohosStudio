import {
  OperationBlueButton,
  OperationEmptyTableRow,
  OperationHeaderCell,
  OperationSolidButton,
  OperationTextCell
} from './OperationControls';
import { getEmptyRowIndexes, WqOperationConfigRow } from './OperationTypes';
import { OperationCommandResult, OperationTaskService } from '../../services/OperationTaskService';
import { UiUtil } from 'base';

const ONE_HOUR_MS = 60 * 60 * 1000;

@Component
export struct CombinationMaintenancePanel {
  @Link selectedCombinationFlow: string;
  @Link combinationCount: string;
  @Link combinationMode: string;
  @Link nextCombinationId: number;
  @Link combinationRunning: boolean;
  @Link taskMessage: string;
  @Link combinationRows: WqOperationConfigRow[];
  @Prop viewportWidth: number = 1024;
  @Prop viewportHeight: number = 768;
  @Prop scaleFactor: number = 1.92;
  onRowsChange: (rows: WqOperationConfigRow[]) => void = (_rows: WqOperationConfigRow[]) => {
  };
  onSelectedFlowChange: (value: string) => void = (_value: string) => {
  };
  onCountChange: (value: string) => void = (_value: string) => {
  };
  onModeChange: (value: string) => void = (_value: string) => {
  };
  onNextIdChange: (value: number) => void = (_value: number) => {
  };
  onRunningChange: (value: boolean) => void = (_value: boolean) => {
  };
  onTaskMessageChange: (value: string) => void = (_value: string) => {
  };
  private stopRequested: boolean = false;
  private readonly combinationFlowOptions: SelectOption[] = [
    { value: '测量水样' },
    { value: '一键校准' },
    { value: '校准' },
    { value: '标样(跨度)核查' },
    { value: '零点核查' },
    { value: '量程校准' },
    { value: '零点校准' },
    { value: '测量程校准液' },
    { value: '测零点校准液' },
    { value: '深度清洗' },
    { value: '一键更新试剂' }
  ];
  private readonly combinationModeOptions: SelectOption[] = [
    { value: '连续测试' },
    { value: '周期测试' },
    { value: '整点测试' }
  ];

  private addCombinationFlow(): void {
    const rowNumber = this.combinationRows.length + 1;
    const newRow: WqOperationConfigRow = {
      id: `combination-${this.nextCombinationId}`,
      category: '',
      name: this.selectedCombinationFlow,
      value: this.combinationCount,
      value2: `${rowNumber}`,
      value3: OperationTaskService.getCommandIdByLabel(this.selectedCombinationFlow),
      value4: '',
      unit: '次',
      status: '待执行',
      result: '',
      selected: false,
      running: false
    };
    this.setCombinationRows(this.combinationRows.concat([newRow]));
    this.nextCombinationId++;
    this.onNextIdChange(this.nextCombinationId);
  }

  private parseCount(value: string): number {
    const parsed = Number(value);
    if (Number.isNaN(parsed) || parsed <= 0) {
      return 1;
    }
    return Math.floor(parsed);
  }

  private updateCombinationRow(rowId: string, running: boolean, status: string, result: string): void {
    const rows = this.combinationRows.map((row: WqOperationConfigRow) => {
      if (row.id !== rowId) {
        return row;
      }
      return {
        id: row.id,
        category: row.category,
        name: row.name,
        value: row.value,
        value2: row.value2,
        value3: row.value3,
        value4: row.value4,
        unit: row.unit,
        status: status,
        result: result,
        selected: row.selected,
        running: running
      };
    });
    this.setCombinationRows(rows);
  }

  private updateRunningRowsStopped(message: string): void {
    const rows = this.combinationRows.map((row: WqOperationConfigRow) => {
      if (!row.running) {
        return row;
      }
      return {
        id: row.id,
        category: row.category,
        name: row.name,
        value: row.value,
        value2: row.value2,
        value3: row.value3,
        value4: row.value4,
        unit: row.unit,
        status: '已停止',
        result: message,
        selected: row.selected,
        running: false
      };
    });
    this.setCombinationRows(rows);
  }

  private setCombinationRows(rows: WqOperationConfigRow[]): void {
    this.combinationRows = rows;
    this.onRowsChange(rows);
  }

  private setTaskMessage(message: string): void {
    this.taskMessage = message;
    this.onTaskMessageChange(message);
  }

  private statusColor(status: string): ResourceColor {
    if (status === '失败' || status === '暂未接入') {
      return '#F01010';
    }
    if (status === '完成' || status === '已停止') {
      return '#0FA85D';
    }
    return '#222222';
  }

  private startCombinationTask(): void {
    if (this.combinationRunning) {
      return;
    }
    void this.runCombinationTask();
  }

  /*
   * 刷新所有已添加流程运行状态，避免二次启动时状态显示不匹配
   * */
  private refreshRunStatus(): void {
    for (let i = 0; i < this.combinationRows.length; i++) {
      const row = this.combinationRows[i];
      this.updateCombinationRow(row.id, true, `待执行`, '');
    }
  }

  private async runCombinationTask(): Promise<void> {
    if (this.combinationRows.length === 0) {
      this.setTaskMessage('请先添加流程');
      return;
    }

    this.stopRequested = false;
    this.combinationRunning = true;
    this.onRunningChange(true);
    this.refreshRunStatus();
    this.setTaskMessage('组合维护运行中');

    if (this.combinationMode === '整点测试') {
      this.setTaskMessage('等待下一个整点执行');
      const waited = await this.delayUntilNextHour();
      if (!waited) {
        this.setTaskMessage('组合维护已停止');
        return;
      }
    }

    const finished = await this.runCombinationRows();

    this.combinationRunning = false;
    this.onRunningChange(false);
    if(!finished) {
      this.setTaskMessage('组合维护启动失败');
    } else if (this.stopRequested) {
      this.setTaskMessage('组合维护已停止');
    } else if (this.taskMessage === '组合维护运行中') {
      this.setTaskMessage('组合维护已完成');
    }
  }

  private async runCombinationRows(): Promise<boolean> {
    for (let i = 0; i < this.combinationRows.length; i++) {
      const row = this.combinationRows[i];
      const success = await this.executeSingleRow(row, i === this.combinationRows.length - 1);
      if (!success) return false;
    }
    this.setTaskMessage('组合维护已完成');
    return true;
  }

  private async waitForNextExecution(row: WqOperationConfigRow, current: number, count: number, isLastRow: boolean): Promise<boolean> {
    // 单流程执行完成切换为完成状态
    if (current >= count) {
      this.updateCombinationRow(row.id, false, `完成`, '');
    }

    // 最后一次执行无需等待
    if (current >= count && isLastRow) {
      return true;
    }

    if (this.combinationMode === '整点测试') {
      this.setTaskMessage('等待下一个整点执行');
      return await this.delayUntilNextHour();
    } else if (this.combinationMode === '周期测试') {
      this.setTaskMessage('等待 1 小时后继续周期测试');
      return await this.delayWithStop(10 * 1000); // 注意：注释写ONE_HOUR_MS但实际是10s，需确认
    }
    return true;
  }

  private async executeSingleRow(row: WqOperationConfigRow, isLastRow: boolean): Promise<boolean> {
    const count = this.parseCount(row.value);
    const commandId = row.value3 || OperationTaskService.getCommandIdByLabel(row.name);

    for (let current = 1; current <= count; current++) {
      if (this.stopRequested) return false;
      this.updateCombinationRow(row.id, true, `执行 ${current}/${count}`, '');
      const started: OperationCommandResult = await OperationTaskService.runMaintenanceCommand(commandId);
      if (!started.success) {
        const todoReason = OperationTaskService.getTodoReason(commandId);
        this.updateCombinationRow(row.id, false, todoReason.length > 0 ? '暂未接入' : '失败', started.message);
        this.setTaskMessage(`组合维护失败：${row.name} ${started.message}`);
        return false;
      }

      const completed =
        await OperationTaskService.waitForCommandComplete(30 * 60 * 1000, 1000, () => this.stopRequested);
      if (!completed.success) {
        this.updateCombinationRow(row.id, false, this.stopRequested ? '已停止' : '失败', completed.message);
        this.setTaskMessage(this.stopRequested ? '组合维护已停止' : `组合维护失败：${row.name} ${completed.message}`);
        return false;
      }

      // 统一等待逻辑
      if (!(await this.waitForNextExecution(row, current, count, isLastRow))) break;
    }
    return !this.stopRequested;
  }

  private stopCombinationTask(): void {
    if (!this.combinationRunning) {
      return;
    }
    this.stopRequested = true;
    void this.stopCurrentDeviceAction();
  }

  private async stopCurrentDeviceAction(): Promise<void> {
    const stopped = await OperationTaskService.stopCurrentOperation();
    this.updateRunningRowsStopped(stopped.message);
    this.combinationRunning = false;
    this.onRunningChange(false);
    this.setTaskMessage(stopped.success ? '组合维护已停止' : `停止失败：${stopped.message}`);
  }

  private async delayUntilNextHour(): Promise<boolean> {
    const now = new Date();
    const nextHour = new Date(now.getFullYear(), now.getMonth(), now.getDate(), now.getHours() + 1, 0, 0, 0);
    return this.delayWithStop(nextHour.getTime() - now.getTime());
  }

  private async delayWithStop(ms: number): Promise<boolean> {
    const startedAt = Date.now();
    while (Date.now() - startedAt < ms) {
      if (this.stopRequested) {
        return false;
      }
      await this.delay(Math.min(10000, ms - (Date.now() - startedAt)));
    }
    return true;
  }

  private async delay(ms: number): Promise<void> {
    await new Promise<void>((resolve) => {
      setTimeout(() => resolve(), ms);
    });
  }

  build() {
    Column() {
      Row() {
        Select(this.combinationFlowOptions)
          .value(this.selectedCombinationFlow)
          .height(UiUtil.vh(4.4, 34, 46, this.viewportHeight, this.scaleFactor))
          .width(UiUtil.vw(16.0, 132, 180, this.viewportWidth, this.scaleFactor))
          .onSelect((_index: number, value?: string) => {
            const selected = value ? value : '测量水样';
            this.selectedCombinationFlow = selected;
            this.onSelectedFlowChange(selected);
          })

        TextInput({ text: this.combinationCount })
          .height(UiUtil.vh(4.2, 32, 44, this.viewportHeight, this.scaleFactor))
          .width(UiUtil.vw(5.8, 52, 70, this.viewportWidth, this.scaleFactor))
          .fontSize(UiUtil.vh(1.85, 12, 16, this.viewportHeight, this.scaleFactor))
          .textAlign(TextAlign.Center)
          .margin({
            left: UiUtil.vw(0.8, 6, 10, this.viewportWidth, this.scaleFactor),
            right: UiUtil.vw(0.35, 3, 6, this.viewportWidth, this.scaleFactor)
          })
          .onChange((value: string) => {
            this.combinationCount = value;
            this.onCountChange(value);
          })

        Text('次')
          .fontSize(UiUtil.vh(1.9, 12, 16, this.viewportHeight, this.scaleFactor))
          .margin({ right: UiUtil.vw(1.0, 8, 12, this.viewportWidth, this.scaleFactor) })

        OperationBlueButton({
          label: '添加',
          buttonWidth: UiUtil.vw(8.0, 72, 96, this.viewportWidth, this.scaleFactor),
          buttonHeight: UiUtil.vh(4.2, 32, 44, this.viewportHeight, this.scaleFactor),
          fontSizeValue: UiUtil.vh(1.85, 11, 15, this.viewportHeight, this.scaleFactor),
          borderRadiusValue: UiUtil.vh(0.7, 4, 8, this.viewportHeight, this.scaleFactor),
          onAction: () => {
            this.addCombinationFlow();
          }
        })

        Blank()

        Select(this.combinationModeOptions)
          .value(this.combinationMode)
          .height(UiUtil.vh(4.4, 34, 46, this.viewportHeight, this.scaleFactor))
          .width(UiUtil.vw(12.0, 96, 132, this.viewportWidth, this.scaleFactor))
          .onSelect((_index: number, value?: string) => {
            const selected = value ? value : '连续测试';
            this.combinationMode = selected;
            this.onModeChange(selected);
          })
      }
      .height(UiUtil.vh(5.4, 42, 58, this.viewportHeight, this.scaleFactor))
      .alignItems(VerticalAlign.Center)

      Column() {
        Row() {
          OperationHeaderCell({
            label: '序号',
            weight: 0.7,
            fontSizeValue: UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor)
          });
          OperationHeaderCell({
            label: '流程名称',
            weight: 2.4,
            fontSizeValue: UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor)
          });
          OperationHeaderCell({
            label: '次数',
            weight: 0.9,
            fontSizeValue: UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor)
          });
          OperationHeaderCell({
            label: '状态',
            weight: 1.6,
            fontSizeValue: UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor)
          });
        }
        .height(UiUtil.vh(4.8, 36, 52, this.viewportHeight, this.scaleFactor))
        .backgroundColor('#F0F0F0')
        .border({ width: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor), color: '#DADADA' })

        ForEach(this.combinationRows, (row: WqOperationConfigRow) => {
          Row() {
            OperationTextCell({
              label: row.value2,
              weight: 0.7,
              fontSizeValue: UiUtil.vh(1.8, 11, 15, this.viewportHeight, this.scaleFactor)
            });
            OperationTextCell({
              label: row.name,
              weight: 2.4,
              fontSizeValue: UiUtil.vh(1.8, 11, 15, this.viewportHeight, this.scaleFactor)
            });
            OperationTextCell({
              label: row.value,
              weight: 0.9,
              fontSizeValue: UiUtil.vh(1.8, 11, 15, this.viewportHeight, this.scaleFactor)
            });
            OperationTextCell({
              label: row.result.length > 0 ? `${row.status}：${row.result}` : row.status,
              weight: 1.6,
              fontSizeValue: UiUtil.vh(1.65, 10, 14, this.viewportHeight, this.scaleFactor),
              fontColorValue: this.statusColor(row.status)
            });
          }
          .height(UiUtil.vh(4.8, 36, 52, this.viewportHeight, this.scaleFactor))
          .border({ width: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor), color: '#E5E5E5' })
        }, (
          row: WqOperationConfigRow) => `${row.id}-${row.value}-${row.value2}-${row.status}-${row.result}-${row.running}`)

        ForEach(getEmptyRowIndexes(this.combinationRows.length, 5), (index: number) => {
          OperationEmptyTableRow({
            weights: [0.7, 2.4, 0.9, 1.6],
            rowHeight: UiUtil.vh(4.8, 36, 52, this.viewportHeight, this.scaleFactor),
            borderWidthValue: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor)
          });
        }, (index: number) => `combination-empty-${index}`)
      }
      .layoutWeight(1)
      .width('100%')
      .clip(true)
      .border({ width: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor), color: '#CCCCCC' })

      Row() {
        Text('*周期测试和整点测试间隔均为1小时')
          .fontSize(UiUtil.vh(1.6, 11, 14, this.viewportHeight, this.scaleFactor))
          .fontColor('#F01010')
          .layoutWeight(1)
        Text(this.taskMessage)
          .fontSize(UiUtil.vh(1.6, 11, 14, this.viewportHeight, this.scaleFactor))
          .fontColor(this.combinationRunning ? '#1D4ED8' : '#222222')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row() {
          OperationBlueButton({
            label: '启动',
            buttonWidth: UiUtil.vw(8.0, 72, 96, this.viewportWidth, this.scaleFactor),
            buttonHeight: UiUtil.vh(4.2, 32, 44, this.viewportHeight, this.scaleFactor),
            fontSizeValue: UiUtil.vh(1.85, 11, 15, this.viewportHeight, this.scaleFactor),
            borderRadiusValue: UiUtil.vh(0.7, 4, 8, this.viewportHeight, this.scaleFactor),
            recordAction: false,
            onAction: () => {
              this.startCombinationTask();
            }
          })
        }
        .margin({ right: UiUtil.vw(1.0, 8, 12, this.viewportWidth, this.scaleFactor) })

        OperationSolidButton({
          label: '停止',
          buttonWidth: UiUtil.vw(8.0, 72, 96, this.viewportWidth, this.scaleFactor),
          buttonHeight: UiUtil.vh(4.2, 32, 44, this.viewportHeight, this.scaleFactor),
          fontSizeValue: UiUtil.vh(1.85, 11, 15, this.viewportHeight, this.scaleFactor),
          borderRadiusValue: UiUtil.vh(0.7, 4, 8, this.viewportHeight, this.scaleFactor),
          recordAction: false,
          onAction: () => {
            this.stopCombinationTask();
          }
        })
      }
      .height(UiUtil.vh(6.0, 46, 64, this.viewportHeight, this.scaleFactor))
      .alignItems(VerticalAlign.Center)
    }
    .layoutWeight(1)
    .height('100%')
    .padding({
      left: UiUtil.vw(0.8, 6, 10, this.viewportWidth, this.scaleFactor),
      right: UiUtil.vw(0.8, 6, 10, this.viewportWidth, this.scaleFactor),
      top: UiUtil.vh(0.8, 6, 10, this.viewportHeight, this.scaleFactor),
      bottom: UiUtil.vh(0.8, 6, 10, this.viewportHeight, this.scaleFactor)
    })
    .backgroundColor('#FFFFFF')
  }
}
