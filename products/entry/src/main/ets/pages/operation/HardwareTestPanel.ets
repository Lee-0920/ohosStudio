import {
  OperationBlueButton,
  OperationHeaderCell,
  OperationSolidButton,
  OperationTextCell
} from './OperationControls';
import { copyOperationRow, WqOperationConfigRow } from './OperationTypes';
import { WorkerManager } from 'flow';
import { UiUtil } from 'base';

@Component
export struct HardwareTestPanel {
  @Link hardwareRows: WqOperationConfigRow[];
  @Prop viewportWidth: number = 1024;
  @Prop viewportHeight: number = 768;
  @Prop scaleFactor: number = 1.92;
  onRowsChange: (rows: WqOperationConfigRow[]) => void = (_rows: WqOperationConfigRow[]) => {
  };

  private getHardwareOperation(rowId: string): string {
    // 2. 根据硬件类型动态下发对应指令
    const commandMap: Record<string, string> = {
      'hardware-metering-pump': 'meterPump',
      'hardware-water-valve': 'sampleValve',
      'hardware-reagent-one-valve': 'reagent1Valve',
      'hardware-reagent-two-valve': 'reagent2Valve',
      'hardware-range-valve': 'standardValve',
      'hardware-blank-valve': 'blankValve',
      'hardware-range-check-valve': 'rangeCheckValve',
      'hardware-zero-check-valve': 'zeroCheckValve',
      'hardware-digestion-heater': 'digestionHeater',
      'hardware-meter-one-light': 'meterLED1',
      'hardware-meter-two-light': 'meterLED2',
      'hardware-measure-light': 'measureLED',
      'hardware-sampling-relay': 'sampleRelay',
      'hardware-current-output': 'currentOutput',
    };
    return commandMap[rowId];
  }

  private toggleHardwareRow(rowId: string): void {
    // TODO: 当前缺少泵、阀、继电器、4-20mA 等硬件测试的可写 API，不能真实切换硬件状态。
    // ✅ 1. 提前找到目标行并计算取反值
    const targetRow = this.hardwareRows.find((row) => row.id === rowId);
    if (!targetRow) {
      console.warn(`TLQQ, 未找到硬件行: ${rowId}`);
      return;
    }

    const isCurrentlyOn = targetRow.status === '开启';
    const newValue = isCurrentlyOn ? '关闭' : '开启';
    const newCmdValue = isCurrentlyOn ? 0 : 1;

    console.info(`TLQQ, toggleHardwareRow ${rowId}: ${targetRow.value} -> ${newValue}`);
    const rows = this.hardwareRows.map((row: WqOperationConfigRow) => {
      if (row.id !== rowId) {
        return row;
      }
      return copyOperationRow(
        row,
        row.value,
        row.value2,
        row.value3,
        row.value4,
        newValue,
        '缺少硬件测试API',
        row.selected,
        false
      );
    });
    this.hardwareRows = rows;
    this.onRowsChange(rows);
    console.info(`TLQQ, toggleHardwareRow postMessage`, `${rowId}`);

    const cmdType = this.getHardwareOperation(rowId);
    if (cmdType) {
      WorkerManager.getInstance().postMessage({
        type: 'hardwareOperation',
        data: { operationName: cmdType, status: newCmdValue },
        timeStamp: Date.now()
      });
    } else {
      console.warn(`TLQQ, 未知硬件ID: ${rowId}，无对应指令映射`);
    }
  }

  build() {
    Column() {
      Row() {
        OperationHeaderCell(
          { label: '类别', weight: 1.0, fontSizeValue: UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor) });
        OperationHeaderCell({
          label: '测试项',
          weight: 1.9,
          fontSizeValue: UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor)
        });
        OperationHeaderCell(
          { label: '状态', weight: 0.9, fontSizeValue: UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor) });
        OperationHeaderCell(
          { label: '操作', weight: 0.9, fontSizeValue: UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor) });
      }
      .height(UiUtil.vh(4.8, 36, 52, this.viewportHeight, this.scaleFactor))
      .backgroundColor('#F0F0F0')
      .border({ width: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor), color: '#DADADA' })

      Scroll() {
        Column() {
          ForEach(this.hardwareRows, (row: WqOperationConfigRow) => {
            Row() {
              OperationTextCell({
                label: row.category,
                weight: 1.0,
                fontSizeValue: UiUtil.vh(1.8, 11, 15, this.viewportHeight, this.scaleFactor)
              });
              Row() {
                OperationBlueButton({
                  label: row.name,
                  buttonWidth: UiUtil.vw(16.0, 124, 180, this.viewportWidth, this.scaleFactor),
                  buttonHeight: UiUtil.vh(4.0, 30, 44, this.viewportHeight, this.scaleFactor),
                  fontSizeValue: UiUtil.vh(1.85, 11, 15, this.viewportHeight, this.scaleFactor),
                  borderRadiusValue: UiUtil.vh(0.7, 4, 8, this.viewportHeight, this.scaleFactor),
                  onAction: () => {
                    this.toggleHardwareRow(row.id);
                  }
                })
              }
              .layoutWeight(1.9)
              .justifyContent(FlexAlign.Center)

              OperationTextCell({
                label: row.status,
                weight: 0.9,
                fontSizeValue: UiUtil.vh(1.8, 11, 15, this.viewportHeight, this.scaleFactor),
                fontColorValue: row.status === '未接入' ? '#F01010' : '#222222'
              });
              Row() {
                OperationSolidButton({
                  label: '测试',
                  buttonWidth: UiUtil.vw(6.8, 60, 86, this.viewportWidth, this.scaleFactor),
                  buttonHeight: UiUtil.vh(3.8, 28, 40, this.viewportHeight, this.scaleFactor),
                  fontSizeValue: UiUtil.vh(1.85, 11, 15, this.viewportHeight, this.scaleFactor),
                  borderRadiusValue: UiUtil.vh(0.7, 4, 8, this.viewportHeight, this.scaleFactor),
                  onAction: () => {
                    this.toggleHardwareRow(row.id);
                  }
                })
              }
              .layoutWeight(0.9)
              .justifyContent(FlexAlign.Center)
            }
            .height(UiUtil.vh(5.0, 38, 54, this.viewportHeight, this.scaleFactor))
            .border({ width: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor), color: '#E5E5E5' })
          }, (row: WqOperationConfigRow) => `${row.id}-${row.status}-${row.result}-${row.running}`)
        }
      }
      .layoutWeight(1)
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Auto)
    }
    .layoutWeight(1)
    .height('100%')
    .margin({
      left: UiUtil.vw(0.8, 6, 10, this.viewportWidth, this.scaleFactor),
      right: UiUtil.vw(0.8, 6, 10, this.viewportWidth, this.scaleFactor),
      top: UiUtil.vh(0.8, 6, 10, this.viewportHeight, this.scaleFactor),
      bottom: UiUtil.vh(0.8, 6, 10, this.viewportHeight, this.scaleFactor)
    })
    .clip(true)
    .backgroundColor('#FFFFFF')
    .border({ width: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor), color: '#CCCCCC' })
  }
}
