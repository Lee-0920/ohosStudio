import { OperationBlueButton, OperationSolidButton } from './OperationControls';
import { WqMaintenanceRow } from './OperationTypes';
import { OperationCommandResult, OperationTaskService } from '../../services/OperationTaskService';
import { MaintenceType, WorkerManager, MaintainOperationParams, MeasureType } from 'flow';
import { UiUtil } from 'base';

@Component
export struct MaintenancePanel {
  @Link maintenanceRows: WqMaintenanceRow[];
  @Prop viewportWidth: number = 1024;
  @Prop viewportHeight: number = 768;
  @Prop scaleFactor: number = 1.92;
  onRowsChange: (rows: WqMaintenanceRow[]) => void = (_rows: WqMaintenanceRow[]) => {
  };
  private stopRequestedRowIds: string[] = [];

  private updateMaintenanceRow(
    rowId: string,
    isRunning: boolean,
    status: string,
    result: string,
    count: string | null = null
  ): void {
    const rows = this.maintenanceRows.map((item: WqMaintenanceRow) => {
      if (item.id !== rowId) {
        return item;
      }
      return {
        id: item.id,
        project: item.project,
        count: count === null ? item.count : count,
        isRunning: isRunning,
        status: status,
        result: result,
        maintenceType: item.maintenceType,
        params: item.params
      };
    });
    this.maintenanceRows = rows;
    this.onRowsChange(rows);
  }

  private getActionLabel(item: WqMaintenanceRow): string {
    return item.isRunning ? '停止' : '执行';
  }

  private increaseCount(countText: string): string {
    const parsed = Number(countText);
    if (Number.isNaN(parsed)) {
      return '1';
    }
    return `${parsed + 1}`;
  }

  private resetStopRequest(rowId: string): void {
    this.stopRequestedRowIds = this.stopRequestedRowIds.filter((item: string) => {
      return item !== rowId;
    });
  }

  private markStopRequested(rowId: string): void {
    if (this.stopRequestedRowIds.indexOf(rowId) >= 0) {
      return;
    }
    this.stopRequestedRowIds = this.stopRequestedRowIds.concat([rowId]);
  }

  private isStopRequested(rowId: string): boolean {
    return this.stopRequestedRowIds.indexOf(rowId) >= 0;
  }

  private statusColor(row: WqMaintenanceRow): ResourceColor {
    if (row.isRunning) {
      return '#1D4ED8';
    }
    if (row.status === '失败' || row.status === '暂未接入' || row.status === '停止失败') {
      return '#F01010';
    }
    if (row.status === '完成' || row.status === '已停止') {
      return '#0FA85D';
    }
    return '#222222';
  }

  private runMaintenance(row: WqMaintenanceRow): void {
    if (row.isRunning) {
      return;
    }
    void this.executeMaintenance(row);
  }

  /**
   * 从行数据中安全提取维护操作参数
   */
  private buildMaintenanceParams(row: WqMaintenanceRow): MaintainOperationParams | null {
    const runTimes = parseFloat(row.count);
    console.info(`buildPipeParams ${row}`);
    if (isNaN(runTimes) || runTimes <= 0) return null;

    return {
      maintenceTypes: row.maintenceType,
      params: row.params??MeasureType.Sample,
      runTimes
    };
  }

  private async executeMaintenance(row: WqMaintenanceRow): Promise<void> {
    const maintainParams = this.buildMaintenanceParams(row);
    if(maintainParams == null)
    {
      console.error('executeMaintenance null');
      return;
    }
    let maintainOp: string = '';
    switch (maintainParams.maintenceTypes) {
      case MaintenceType.AutoMeasure:
        maintainOp = 'startMeasure';
        break;
      case MaintenceType.AutoCalibrate:
        maintainOp = 'startCalibrate';
        break;
      case MaintenceType.AutoClean:
        maintainOp = 'startClean';
        break;
      case MaintenceType.AutoPumpCalibrate:
        maintainOp = 'startPumpCalibrate';
        break;
      case MaintenceType.AutoADAdjust:
        maintainOp = 'startADAdjust';
        break;
      case MaintenceType.AutoCollectSample:
        maintainOp = 'startCollectSample';
        break;
      default:
        break;
    }
    this.resetStopRequest(row.id);
    this.updateMaintenanceRow(row.id, true, '下发中', '');
    console.info(`TLQQ, executeMaintenance postMessage `);
    WorkerManager.getInstance().postMessage({
      type: maintainOp,
      data: {
        maintenceTypes: maintainParams.maintenceTypes,
        params: maintainParams.params,
        runTimes: maintainParams.runTimes
      },
      timeStamp: Date.now()
    });
    const started: OperationCommandResult = await OperationTaskService.runMaintenanceCommand(row.id);
    if (!started.success) {
      const todoReason = OperationTaskService.getTodoReason(row.id);
      this.updateMaintenanceRow(row.id, false, todoReason.length > 0 ? '暂未接入' : '失败', started.message);
      return ;
    }

    this.updateMaintenanceRow(row.id, true, '运行中', started.message);
    const completed: OperationCommandResult = await OperationTaskService.waitForCommandComplete(
      30 * 60 * 1000,
      1000,
      () => this.isStopRequested(row.id)
    );
    if (completed.success) {
      this.updateMaintenanceRow(row.id, false, '完成', completed.message, this.increaseCount(row.count));
    } else {
      this.updateMaintenanceRow(
        row.id,
        false,
        this.isStopRequested(row.id) ? '已停止' : '失败',
        completed.message
      );
    }
    this.resetStopRequest(row.id);
  }

  private stopMaintenance(row: WqMaintenanceRow): void {
    void this.executeStop(row);
  }

  private async executeStop(row: WqMaintenanceRow): Promise<void> {
    console.info(`TLQQ, executeMaintenance postMessage `);
    WorkerManager.getInstance().postMessage({
      type: 'stop',
      data: {
        value: 1
      },
      timeStamp: Date.now()
    });
    this.markStopRequested(row.id);
    this.updateMaintenanceRow(row.id, true, '停止中', '');
    const result: OperationCommandResult = await OperationTaskService.stopCurrentOperation();
    this.updateMaintenanceRow(row.id, false, result.success ? '已停止' : '停止失败', result.message);
  }

  build() {
    Row() {
      Column() {
        Row() {
          Text('项目')
            .fontSize(UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor))
            .fontWeight(FontWeight.Bold)
            .layoutWeight(2.4)
            .textAlign(TextAlign.Center)
          Text('次数')
            .fontSize(UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor))
            .fontWeight(FontWeight.Bold)
            .layoutWeight(0.7)
            .textAlign(TextAlign.Center)
          Text('状态')
            .fontSize(UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor))
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1.2)
            .textAlign(TextAlign.Center)
          Text('操作')
            .fontSize(UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor))
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1.0)
            .textAlign(TextAlign.Center)
        }
        .height(UiUtil.vh(4.8, 36, 52, this.viewportHeight, this.scaleFactor))
        .backgroundColor('#F0F0F0')
        .border({ width: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor), color: '#DADADA' })

        Scroll() {
          Column() {
            ForEach(this.maintenanceRows, (item: WqMaintenanceRow) => {
              Row() {
                Row() {
                  OperationBlueButton({
                    label: item.project,
                    buttonWidth: UiUtil.vw(16.2, 118, 190, this.viewportWidth, this.scaleFactor),
                    buttonHeight: UiUtil.vh(4.0, 30, 44, this.viewportHeight, this.scaleFactor),
                    fontSizeValue: UiUtil.vh(1.75, 10, 14, this.viewportHeight, this.scaleFactor),
                    borderRadiusValue: UiUtil.vh(0.7, 4, 8, this.viewportHeight, this.scaleFactor),
                    recordAction: false,
                    onAction: () => {
                      this.runMaintenance(item);
                    }
                  })
                }
                .layoutWeight(2.4)
                .justifyContent(FlexAlign.Center)
                .padding({
                  left: UiUtil.vw(0.35, 3, 6, this.viewportWidth, this.scaleFactor),
                  right: UiUtil.vw(0.35, 3, 6, this.viewportWidth, this.scaleFactor)
                })

                Text(item.count)
                  .fontSize(UiUtil.vh(1.8, 11, 15, this.viewportHeight, this.scaleFactor))
                  .layoutWeight(0.7)
                  .textAlign(TextAlign.Center)

                Text(item.result.length > 0 ? `${item.status}：${item.result}` : item.status)
                  .fontSize(UiUtil.vh(1.55, 10, 13, this.viewportHeight, this.scaleFactor))
                  .fontColor(this.statusColor(item))
                  .layoutWeight(1.2)
                  .textAlign(TextAlign.Center)
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })

                Row() {
                  if (this.getActionLabel(item) === '停止') {
                    OperationSolidButton({
                      label: '停止',
                      buttonWidth: UiUtil.vw(6.8, 62, 88, this.viewportWidth, this.scaleFactor),
                      buttonHeight: UiUtil.vh(3.8, 28, 40, this.viewportHeight, this.scaleFactor),
                      fontSizeValue: UiUtil.vh(1.85, 11, 15, this.viewportHeight, this.scaleFactor),
                      borderRadiusValue: UiUtil.vh(0.7, 4, 8, this.viewportHeight, this.scaleFactor),
                      recordAction: false,
                      onAction: () => {
                        this.stopMaintenance(item);
                      }
                    })
                  } else {
                    OperationBlueButton({
                      label: '执行',
                      buttonWidth: UiUtil.vw(6.8, 62, 88, this.viewportWidth, this.scaleFactor),
                      buttonHeight: UiUtil.vh(3.8, 28, 40, this.viewportHeight, this.scaleFactor),
                      fontSizeValue: UiUtil.vh(1.85, 11, 15, this.viewportHeight, this.scaleFactor),
                      borderRadiusValue: UiUtil.vh(0.7, 4, 8, this.viewportHeight, this.scaleFactor),
                      recordAction: false,
                      onAction: () => {
                        this.runMaintenance(item);
                      }
                    })
                  }
                }
                .layoutWeight(1.0)
                .justifyContent(FlexAlign.Center)
              }
              .height(UiUtil.vh(5.2, 38, 56, this.viewportHeight, this.scaleFactor))
              .border({ width: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor), color: '#E5E5E5' })
            }, (item: WqMaintenanceRow) => `${item.id}-${item.isRunning}-${item.status}-${item.result}-${item.count}`)
          }
        }
        .layoutWeight(1)
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Auto)
      }
      .layoutWeight(1)
      .height('100%')
      .clip(true)
      .backgroundColor('#FFFFFF')
      .border({ width: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor), color: '#CCCCCC' })
    }
    .layoutWeight(1)
    .width('100%')
    .height('100%')
    .alignItems(VerticalAlign.Top)
    .padding({
      left: UiUtil.vw(0.8, 6, 10, this.viewportWidth, this.scaleFactor),
      right: UiUtil.vw(0.8, 6, 10, this.viewportWidth, this.scaleFactor),
      top: UiUtil.vh(0.8, 6, 10, this.viewportHeight, this.scaleFactor),
      bottom: UiUtil.vh(0.8, 6, 10, this.viewportHeight, this.scaleFactor)
    })
    .backgroundColor('#FFFFFF')
  }
}
