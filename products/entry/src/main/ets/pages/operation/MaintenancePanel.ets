import { OperationBlueButton, OperationSolidButton } from './OperationControls';
import { WqMaintenanceRow } from './OperationTypes';
import { OperationCommandResult, OperationTaskService } from '../../services/OperationTaskService';
import {
  MaintenanceRuntimeDisplayService,
  MaintenanceRuntimeInfoInput,
  MaintenanceRuntimeActionStep
} from '../../services/MaintenanceRuntimeDisplayService';
import { MaintenceType, WorkerManager, MaintainOperationParams, MeasureType, CleanType, setting } from 'flow';
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
    console.info(`buildPipeParams ${JSON.stringify(row)}`);
    if (isNaN(runTimes) || runTimes <= 0) return null;

    return {
      maintenceTypes: row.maintenceType,
      params: row.params??MeasureType.Sample,
      runTimes
    };
  }

  /**
   * 构造测量类流程（水样/标液/空白/核查/质控）的完整动作步骤序列。
   * 序列与 Measurer.ets 中实际执行步骤保持一致，供底部第二个进度条显示当前动作。
   */
  private getMeasureActionSteps(): MaintenanceRuntimeActionStep[] {
    const ra = setting.runAction.measure;
    return [
      { actionLabel: ra.drainBeforeMeasure.text, actionTotalSeconds: ra.drainBeforeMeasure.GetTime?.() ?? 0 },
      { actionLabel: ra.cleanBeforeMeasure.text, actionTotalSeconds: ra.cleanBeforeMeasure.GetTime?.() ?? 0 },
      { actionLabel: ra.rinse.text, actionTotalSeconds: ra.rinse.GetTime?.() ?? 0 },
      { actionLabel: ra.addSample.text, actionTotalSeconds: ra.addSample.GetTime?.() ?? 0 },
      { actionLabel: ra.addReagent1.text, actionTotalSeconds: ra.addReagent1.GetTime?.() ?? 0 },
      { actionLabel: ra.addReagent2.text, actionTotalSeconds: ra.addReagent2.GetTime?.() ?? 0 },
      { actionLabel: ra.digest.text, actionTotalSeconds: ra.digest.GetTime?.() ?? 0 },
      { actionLabel: ra.digestCooling.text, actionTotalSeconds: ra.digestCooling.GetTime?.() ?? 0 },
      { actionLabel: ra.readMeasureAD.text, actionTotalSeconds: ra.readMeasureAD.GetTime?.() ?? 0 },
      { actionLabel: ra.drainAfterMeasure.text, actionTotalSeconds: ra.drainAfterMeasure.GetTime?.() ?? 0 },
      { actionLabel: ra.cleanAfterMeasure.text, actionTotalSeconds: ra.cleanAfterMeasure.GetTime?.() ?? 0 },
      { actionLabel: ra.readInitialAD.text, actionTotalSeconds: ra.readInitialAD.GetTime?.() ?? 0 },
      { actionLabel: ra.drainAfterMeasure.text, actionTotalSeconds: ra.drainAfterMeasure.GetTime?.() ?? 0 }
    ];
  }

  /**
   * 构造清洗所有管路的动作步骤序列，与 RunAction.ets 中 cleanAll 定义保持一致。
   */
  private getCleanAllActionSteps(): MaintenanceRuntimeActionStep[] {
    const ca = setting.runAction.cleanAll;
    return [
      { actionLabel: ca.cleanDigestionRoom.text, actionTotalSeconds: ca.cleanDigestionRoom.GetTime?.() ?? 0 },
      { actionLabel: ca.cleanSamplePipe.text, actionTotalSeconds: ca.cleanSamplePipe.GetTime?.() ?? 0 },
      { actionLabel: ca.cleanStandardPipe.text, actionTotalSeconds: ca.cleanStandardPipe.GetTime?.() ?? 0 },
      { actionLabel: ca.cleanReagent1Pipe.text, actionTotalSeconds: ca.cleanReagent1Pipe.GetTime?.() ?? 0 },
      { actionLabel: ca.cleanReagent2Pipe.text, actionTotalSeconds: ca.cleanReagent2Pipe.GetTime?.() ?? 0 },
      { actionLabel: ca.cleanBlankPipe.text, actionTotalSeconds: ca.cleanBlankPipe.GetTime?.() ?? 0 },
      { actionLabel: ca.cleanZeroCheckPipe.text, actionTotalSeconds: ca.cleanZeroCheckPipe.GetTime?.() ?? 0 },
      { actionLabel: ca.cleanRangeCheckPipe.text, actionTotalSeconds: ca.cleanRangeCheckPipe.GetTime?.() ?? 0 },
      { actionLabel: ca.drainSamplePipe.text, actionTotalSeconds: ca.drainSamplePipe.GetTime?.() ?? 0 },
      { actionLabel: ca.drainStandardPipe.text, actionTotalSeconds: ca.drainStandardPipe.GetTime?.() ?? 0 },
      { actionLabel: ca.drainReagent1Pipe.text, actionTotalSeconds: ca.drainReagent1Pipe.GetTime?.() ?? 0 },
      { actionLabel: ca.drainReagent2Pipe.text, actionTotalSeconds: ca.drainReagent2Pipe.GetTime?.() ?? 0 },
      { actionLabel: ca.drainBlankPipe.text, actionTotalSeconds: ca.drainBlankPipe.GetTime?.() ?? 0 },
      { actionLabel: ca.drainZeroCheckPipe.text, actionTotalSeconds: ca.drainZeroCheckPipe.GetTime?.() ?? 0 },
      { actionLabel: ca.drainRangeCheckPipe.text, actionTotalSeconds: ca.drainRangeCheckPipe.GetTime?.() ?? 0 },
      { actionLabel: ca.drainWastePipe.text, actionTotalSeconds: ca.drainWastePipe.GetTime?.() ?? 0 },
      { actionLabel: ca.drainWasteWaterPipe.text, actionTotalSeconds: ca.drainWasteWaterPipe.GetTime?.() ?? 0 }
    ];
  }

  /**
   * 构造泵校准流程的动作步骤序列。
   */
  private getPumpCheckActionSteps(): MaintenanceRuntimeActionStep[] {
    const pc = setting.runAction.pumpCheck;
    return [
      { actionLabel: pc.drainMeterPipe.text, actionTotalSeconds: pc.drainMeterPipe.GetTime?.() ?? 0 },
      { actionLabel: pc.meterToMinMeterPoint.text, actionTotalSeconds: pc.meterToMinMeterPoint.GetTime?.() ?? 0 },
      { actionLabel: pc.meterToMaxMeterPoint.text, actionTotalSeconds: pc.meterToMaxMeterPoint.GetTime?.() ?? 0 }
    ];
  }

  /**
   * 构造定量 AD 调节流程的动作步骤序列。
   */
  private getMeterADAdjustActionSteps(): MaintenanceRuntimeActionStep[] {
    const ad = setting.runAction.meterADAdjustFlow;
    return [
      { actionLabel: ad.drainMeterPipe.text, actionTotalSeconds: ad.drainMeterPipe.GetTime?.() ?? 0 },
      { actionLabel: ad.adjustMeterPointOne.text, actionTotalSeconds: ad.adjustMeterPointOne.GetTime?.() ?? 0 },
      { actionLabel: ad.adjustMeterPointTwo.text, actionTotalSeconds: ad.adjustMeterPointTwo.GetTime?.() ?? 0 }
    ];
  }

  /**
   * 构造测量 AD 调节流程的动作步骤序列。
   */
  private getMeasureADAdjustActionSteps(): MaintenanceRuntimeActionStep[] {
    const ad = setting.runAction.measureADAdjustFlow;
    return [
      { actionLabel: ad.drainFromDigestionRoom.text, actionTotalSeconds: ad.drainFromDigestionRoom.GetTime?.() ?? 0 },
      { actionLabel: ad.pumpToDigestionRoom.text, actionTotalSeconds: ad.pumpToDigestionRoom.GetTime?.() ?? 0 },
      { actionLabel: ad.adjustReference.text, actionTotalSeconds: ad.adjustReference.GetTime?.() ?? 0 },
      { actionLabel: ad.adjustMeasure.text, actionTotalSeconds: ad.adjustMeasure.GetTime?.() ?? 0 }
    ];
  }

  /**
   * 构造采集水样流程的动作步骤序列。
   */
  private getCollectSampleActionSteps(): MaintenanceRuntimeActionStep[] {
    const cs = setting.runAction.collectSample;
    return [
      { actionLabel: cs.collect.text, actionTotalSeconds: cs.collect.GetTime?.() ?? 0 },
      { actionLabel: cs.silent.text, actionTotalSeconds: cs.silent.GetTime?.() ?? 0 }
    ];
  }

  /**
   * 把维护行映射到底部状态栏需要的状态码、文本、总时长和动作步骤序列。
   * 数据全部来自 RunStatus.ets / RunAction.ets，不经过 DeviceStateStore。
   */
  private getMaintenanceRuntimeInfo(row: WqMaintenanceRow): MaintenanceRuntimeInfoInput | null {
    const rs = setting.runStatus;
    const measureSteps = this.getMeasureActionSteps();
    switch (row.maintenceType) {
      case MaintenceType.AutoMeasure:
        switch (row.params) {
          case MeasureType.Sample:
            return { statusCode: 1, statusLabel: rs.measureSample.text, statusTotalSeconds: rs.measureSample.GetTime?.() ?? 0, actionSteps: measureSteps };
          case MeasureType.Standard:
            return { statusCode: 2, statusLabel: rs.measureStandard.text, statusTotalSeconds: rs.measureStandard.GetTime?.() ?? 0, actionSteps: measureSteps };
          case MeasureType.Blank:
            return { statusCode: 3, statusLabel: rs.measureBlank.text, statusTotalSeconds: rs.measureBlank.GetTime?.() ?? 0, actionSteps: measureSteps };
          case MeasureType.RangeCheck:
            return { statusCode: 41, statusLabel: rs.measureCheckStandard.text, statusTotalSeconds: rs.measureCheckStandard.GetTime?.() ?? 0, actionSteps: measureSteps };
          case MeasureType.ZeroCheck:
            return { statusCode: 29, statusLabel: rs.onlyCalibrateBlank.text, statusTotalSeconds: rs.onlyCalibrateBlank.GetTime?.() ?? 0, actionSteps: measureSteps };
          case MeasureType.QualityHandle:
            return { statusCode: 33, statusLabel: rs.measureQualityHandle.text, statusTotalSeconds: rs.measureQualityHandle.GetTime?.() ?? 0, actionSteps: measureSteps };
          default:
            return null;
        }
      case MaintenceType.AutoCalibrate:
        return { statusCode: 4, statusLabel: rs.calibrate.text, statusTotalSeconds: rs.calibrate.GetTime?.() ?? 0, actionSteps: measureSteps };
      case MaintenceType.AutoClean:
        switch (row.params) {
          case CleanType.cleanMeterPipe:
            return {
              statusCode: 6,
              statusLabel: rs.cleanMeterPipe.text,
              statusTotalSeconds: rs.cleanMeterPipe.GetTime?.() ?? 0,
              actionSteps: [{ actionLabel: setting.runAction.cleanMeterPipe.text, actionTotalSeconds: setting.runAction.cleanMeterPipe.GetTime?.() ?? 0 }]
            };
          case CleanType.cleanDigestionRoom:
            return {
              statusCode: 5,
              statusLabel: rs.cleanDigestionRoom.text,
              statusTotalSeconds: rs.cleanDigestionRoom.GetTime?.() ?? 0,
              actionSteps: [{ actionLabel: setting.runAction.cleanDigestionRoom.text, actionTotalSeconds: setting.runAction.cleanDigestionRoom.GetTime?.() ?? 0 }]
            };
          case CleanType.cleanDeeply:
            return {
              statusCode: 22,
              statusLabel: rs.cleanDeeply.text,
              statusTotalSeconds: rs.cleanDeeply.GetTime?.() ?? 0,
              actionSteps: [{ actionLabel: setting.runAction.cleanDeeply.text, actionTotalSeconds: setting.runAction.cleanDeeply.GetTime?.() ?? 0 }]
            };
          case CleanType.cleanAll:
            return { statusCode: 7, statusLabel: rs.cleanAll.text, statusTotalSeconds: rs.cleanAll.GetTime?.() ?? 0, actionSteps: this.getCleanAllActionSteps() };
          case CleanType.oneKeyRenew:
            return { statusCode: 46, statusLabel: rs.oneKeyRenew.text, statusTotalSeconds: rs.oneKeyRenew.GetTime?.() ?? 0 };
          default:
            return null;
        }
      case MaintenceType.AutoPumpCalibrate:
        return { statusCode: 11, statusLabel: rs.autoPumpCheck.text, statusTotalSeconds: rs.autoPumpCheck.GetTime?.() ?? 0, actionSteps: this.getPumpCheckActionSteps() };
      case MaintenceType.AutoADAdjust:
        if (row.params === MeasureType.Blank) {
          return { statusCode: 44, statusLabel: rs.meterADAdjust.text, statusTotalSeconds: rs.meterADAdjust.GetTime?.() ?? 0, actionSteps: this.getMeterADAdjustActionSteps() };
        }
        if (row.params === MeasureType.Standard) {
          return { statusCode: 45, statusLabel: rs.measureADAdjust.text, statusTotalSeconds: rs.measureADAdjust.GetTime?.() ?? 0, actionSteps: this.getMeasureADAdjustActionSteps() };
        }
        return null;
      case MaintenceType.AutoCollectSample:
        return { statusCode: 8, statusLabel: rs.collectSample.text, statusTotalSeconds: rs.collectSample.GetTime?.() ?? 0, actionSteps: this.getCollectSampleActionSteps() };
      default:
        return null;
    }
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
    const started: OperationCommandResult = { success: true, message: '指令已下发'};
    // const started: OperationCommandResult = await OperationTaskService.runMaintenanceCommand(row.id);
    if (!started.success) {
      const todoReason = OperationTaskService.getTodoReason(row.id);
      this.updateMaintenanceRow(row.id, false, todoReason.length > 0 ? '暂未接入' : '失败', started.message);
      return;
    }

    const runtimeInfo = this.getMaintenanceRuntimeInfo(row);
    console.info(`MaintenancePanel runtimeInfo=${JSON.stringify(runtimeInfo)}`);
    if (runtimeInfo !== null) {
      MaintenanceRuntimeDisplayService.start(
        runtimeInfo.statusCode,
        runtimeInfo.statusLabel,
        runtimeInfo.statusTotalSeconds,
        runtimeInfo.actionSteps
      );
    }

    this.updateMaintenanceRow(row.id, true, '运行中', started.message);
    try {
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
    } finally {
      MaintenanceRuntimeDisplayService.clear();
      this.resetStopRequest(row.id);
    }
  }

  private stopMaintenance(row: WqMaintenanceRow): void {
    void this.executeStop(row);
  }

  private async executeStop(row: WqMaintenanceRow): Promise<void> {
    this.markStopRequested(row.id);
    this.updateMaintenanceRow(row.id, true, '停止中', '');
    MaintenanceRuntimeDisplayService.clear();
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

                TextInput({ text: item.count.toString() })
                  .type(InputType.Number) // 限制只能输入数字
                  .fontSize(UiUtil.vh(1.8, 11, 15, this.viewportHeight, this.scaleFactor))
                  .layoutWeight(0.7)
                  .textAlign(TextAlign.Center)
                  .backgroundColor(Color.Transparent) // 保持与原文本一致的视觉风格
                  .borderWidth(0) // 去除默认边框，使其看起来像文本
                  .padding(0) // 去除默认内边距，确保对齐
                  .onChange((value: string) => {
                    this.onRowsChange
                    this.updateMaintenanceRow(item.id, item.isRunning, item.status, item.result, value);
                  })

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
