import { UiUtil } from 'base';
import {
  OperationBlueButton,
  OperationHeaderCell,
  OperationInputCell,
  OperationTextCell
} from './OperationControls';
import { copyOperationRow, updateOperationRowValue, WqOperationConfigRow } from './OperationTypes';

@Component
export struct ReagentManagementPanel {
  @Link reagentRows: WqOperationConfigRow[];
  @Prop viewportWidth: number = 1024;
  @Prop viewportHeight: number = 768;
  @Prop scaleFactor: number = 1.92;
  onRowsChange: (rows: WqOperationConfigRow[]) => void = (_rows: WqOperationConfigRow[]) => {
  };

  private updateReagentTotal(rowId: string, value: string): void {
    const rows = updateOperationRowValue(this.reagentRows, rowId, 'value3', value);
    this.reagentRows = rows;
    this.onRowsChange(rows);
  }

  private markReagentChanged(rowId: string): void {
    const rows = this.reagentRows.map((row: WqOperationConfigRow) => {
      if (row.id !== rowId) {
        return row;
      }
      return copyOperationRow(row, this.formatToday(), row.value3, row.value3, row.value4);
    });
    this.reagentRows = rows;
    this.onRowsChange(rows);
  }

  private formatToday(): string {
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const day = String(now.getDate()).padStart(2, '0');
    return `${year}.${month}.${day}`;
  }

  build() {
    Column() {
      Row() {
        OperationHeaderCell({
          label: '耗材',
          weight: 1.25,
          fontSizeValue: UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor)
        });
        OperationHeaderCell({
          label: '上次维护',
          weight: 1.15,
          fontSizeValue: UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor)
        });
        OperationHeaderCell({
          label: '余量(mL)',
          weight: 0.9,
          fontSizeValue: UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor)
        });
        OperationHeaderCell({
          label: '总量(mL)',
          weight: 0.9,
          fontSizeValue: UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor)
        });
        OperationHeaderCell({
          label: '周期(月)',
          weight: 0.8,
          fontSizeValue: UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor)
        });
        OperationHeaderCell(
          { label: '操作', weight: 0.9, fontSizeValue: UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor) });
      }
      .height(UiUtil.vh(4.8, 36, 52, this.viewportHeight, this.scaleFactor))
      .backgroundColor('#F0F0F0')
      .border({ width: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor), color: '#DADADA' })

      ForEach(this.reagentRows, (row: WqOperationConfigRow) => {
        Row() {
          OperationTextCell({
            label: row.name,
            weight: 1.25,
            fontSizeValue: UiUtil.vh(1.8, 11, 15, this.viewportHeight, this.scaleFactor)
          });
          OperationTextCell({
            label: row.value,
            weight: 1.15,
            fontSizeValue: UiUtil.vh(1.8, 11, 15, this.viewportHeight, this.scaleFactor)
          });
          OperationTextCell({
            label: row.value2,
            weight: 0.9,
            fontSizeValue: UiUtil.vh(1.8, 11, 15, this.viewportHeight, this.scaleFactor)
          });
          OperationInputCell({
            textValue: row.value3,
            weight: 0.9,
            inputHeight: UiUtil.vh(3.7, 28, 40, this.viewportHeight, this.scaleFactor),
            fontSizeValue: UiUtil.vh(1.75, 11, 15, this.viewportHeight, this.scaleFactor),
            borderRadiusValue: UiUtil.vh(0.35, 2, 4, this.viewportHeight, this.scaleFactor),
            onValueChange: (value: string) => {
              this.updateReagentTotal(row.id, value);
            }
          });
          OperationTextCell({
            label: row.value4,
            weight: 0.8,
            fontSizeValue: UiUtil.vh(1.8, 11, 15, this.viewportHeight, this.scaleFactor)
          });
          Row() {
            OperationBlueButton({
              label: '更换',
              buttonWidth: UiUtil.vw(6.8, 60, 86, this.viewportWidth, this.scaleFactor),
              buttonHeight: UiUtil.vh(3.8, 28, 40, this.viewportHeight, this.scaleFactor),
              fontSizeValue: UiUtil.vh(1.85, 11, 15, this.viewportHeight, this.scaleFactor),
              borderRadiusValue: UiUtil.vh(0.7, 4, 8, this.viewportHeight, this.scaleFactor),
              onAction: () => {
                this.markReagentChanged(row.id);
              }
            })
          }
          .layoutWeight(0.9)
          .justifyContent(FlexAlign.Center)
        }
        .height(UiUtil.vh(5.0, 38, 54, this.viewportHeight, this.scaleFactor))
        .border({ width: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor), color: '#E5E5E5' })
      }, (row: WqOperationConfigRow) => `${row.id}-${row.value}-${row.value2}-${row.value3}-${row.value4}`)
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
