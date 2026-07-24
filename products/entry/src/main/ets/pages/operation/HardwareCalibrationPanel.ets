import { UiUtil } from 'base';
import {
  OperationEmptyTableRow,
  OperationHeaderCell,
  OperationInputCell,
  OperationTextCell
} from './OperationControls';
import { getEmptyRowIndexes, updateOperationRowValue, WqOperationConfigRow } from './OperationTypes';

@Component
export struct HardwareCalibrationPanel {
  @Link hardwareCalibrationRows: WqOperationConfigRow[];
  @Prop viewportWidth: number = 1024;
  @Prop viewportHeight: number = 768;
  @Prop scaleFactor: number = 1.92;
  onRowsChange: (rows: WqOperationConfigRow[]) => void = (_rows: WqOperationConfigRow[]) => {
  };

  private updateHardwareCalibrationValue(rowId: string, value: string): void {
    // TODO: 当前 MonitorService 尚无定量泵参数、定量AD、测量AD写入 API，这里先保存本地配置值。
    const rows = updateOperationRowValue(this.hardwareCalibrationRows, rowId, 'value2', value);
    this.hardwareCalibrationRows = rows;
    this.onRowsChange(rows);
  }

  build() {
    Column() {
      Row() {
        OperationHeaderCell(
          { label: '类别', weight: 1.0, fontSizeValue: UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor) });
        OperationHeaderCell({
          label: '标准项',
          weight: 1.1,
          fontSizeValue: UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor)
        });
        OperationHeaderCell({
          label: '参考值',
          weight: 1.0,
          fontSizeValue: UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor)
        });
        OperationHeaderCell({
          label: '校准值',
          weight: 1.0,
          fontSizeValue: UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor)
        });
        OperationHeaderCell(
          { label: '单位', weight: 0.9, fontSizeValue: UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor) });
      }
      .height(UiUtil.vh(4.8, 36, 52, this.viewportHeight, this.scaleFactor))
      .backgroundColor('#F0F0F0')
      .border({ width: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor), color: '#DADADA' })

      ForEach(this.hardwareCalibrationRows, (row: WqOperationConfigRow) => {
        Row() {
          OperationTextCell({
            label: row.category,
            weight: 1.0,
            fontSizeValue: UiUtil.vh(1.8, 11, 15, this.viewportHeight, this.scaleFactor)
          });
          OperationTextCell({
            label: row.name,
            weight: 1.1,
            fontSizeValue: UiUtil.vh(1.8, 11, 15, this.viewportHeight, this.scaleFactor)
          });
          OperationTextCell({
            label: row.value,
            weight: 1.0,
            fontSizeValue: UiUtil.vh(1.8, 11, 15, this.viewportHeight, this.scaleFactor)
          });
          OperationInputCell({
            textValue: row.value2,
            weight: 1.0,
            inputHeight: UiUtil.vh(3.7, 28, 40, this.viewportHeight, this.scaleFactor),
            fontSizeValue: UiUtil.vh(1.75, 11, 15, this.viewportHeight, this.scaleFactor),
            borderRadiusValue: UiUtil.vh(0.35, 2, 4, this.viewportHeight, this.scaleFactor),
            onValueChange: (value: string) => {
              this.updateHardwareCalibrationValue(row.id, value);
            }
          });
          OperationTextCell({
            label: row.unit,
            weight: 0.9,
            fontSizeValue: UiUtil.vh(1.8, 11, 15, this.viewportHeight, this.scaleFactor)
          });
        }
        .height(UiUtil.vh(5.0, 38, 54, this.viewportHeight, this.scaleFactor))
        .border({ width: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor), color: '#E5E5E5' })
      }, (row: WqOperationConfigRow) => `${row.id}-${row.value}-${row.value2}-${row.value3}-${row.value4}`)

      ForEach(getEmptyRowIndexes(this.hardwareCalibrationRows.length, 6), (index: number) => {
        OperationEmptyTableRow({
          weights: [1.0, 1.1, 1.0, 1.0, 0.9],
          rowHeight: UiUtil.vh(5.0, 38, 54, this.viewportHeight, this.scaleFactor),
          borderWidthValue: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor)
        });
      }, (index: number) => `calibration-empty-${index}`)
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
