import { UiUtil } from 'base';
import {
  OperationBlueButton,
  OperationEmptyTableRow,
  OperationHeaderCell,
  OperationTextCell
} from './OperationControls';
import { copyOperationRow, getEmptyRowIndexes, WqOperationConfigRow } from './OperationTypes';

@Component
export struct ConsumableManagementPanel {
  @Link consumableRows: WqOperationConfigRow[];
  @Prop viewportWidth: number = 1024;
  @Prop viewportHeight: number = 768;
  @Prop scaleFactor: number = 1.92;
  onRowsChange: (rows: WqOperationConfigRow[]) => void = (_rows: WqOperationConfigRow[]) => {
  };

  private markConsumableChanged(rowId: string): void {
    const rows = this.consumableRows.map((row: WqOperationConfigRow) => {
      if (row.id !== rowId) {
        return row;
      }
      const today = this.formatToday();
      return copyOperationRow(row, today, this.addMonths(today, this.parseMonthCount(row.value3)), row.value3,
        row.value4);
    });
    this.consumableRows = rows;
    this.onRowsChange(rows);
  }

  private parseMonthCount(value: string): number {
    const parsed = Number(value);
    if (Number.isNaN(parsed) || parsed < 0) {
      return 0;
    }
    return Math.floor(parsed);
  }

  private addMonths(dateText: string, months: number): string {
    const parts = dateText.split('.');
    if (parts.length !== 3) {
      return dateText;
    }
    const year = Number(parts[0]);
    const month = Number(parts[1]) - 1;
    const day = Number(parts[2]);
    if (Number.isNaN(year) || Number.isNaN(month) || Number.isNaN(day)) {
      return dateText;
    }
    const date = new Date(year, month + months, day);
    return this.formatDate(date);
  }

  private formatToday(): string {
    return this.formatDate(new Date());
  }

  private formatDate(date: Date): string {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}.${month}.${day}`;
  }

  build() {
    Column() {
      Row() {
        OperationHeaderCell({
          label: '耗材',
          weight: 1.45,
          fontSizeValue: UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor)
        });
        OperationHeaderCell({
          label: '上次维护',
          weight: 1.15,
          fontSizeValue: UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor)
        });
        OperationHeaderCell({
          label: '到期时间',
          weight: 1.15,
          fontSizeValue: UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor)
        });
        OperationHeaderCell({
          label: '周期(月)',
          weight: 0.85,
          fontSizeValue: UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor)
        });
        OperationHeaderCell(
          { label: '操作', weight: 0.9, fontSizeValue: UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor) });
      }
      .height(UiUtil.vh(4.8, 36, 52, this.viewportHeight, this.scaleFactor))
      .backgroundColor('#F0F0F0')
      .border({ width: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor), color: '#DADADA' })

      ForEach(this.consumableRows, (row: WqOperationConfigRow) => {
        Row() {
          OperationTextCell({
            label: row.name,
            weight: 1.45,
            fontSizeValue: UiUtil.vh(1.8, 11, 15, this.viewportHeight, this.scaleFactor)
          });
          OperationTextCell({
            label: row.value,
            weight: 1.15,
            fontSizeValue: UiUtil.vh(1.8, 11, 15, this.viewportHeight, this.scaleFactor)
          });
          OperationTextCell({
            label: row.value2,
            weight: 1.15,
            fontSizeValue: UiUtil.vh(1.8, 11, 15, this.viewportHeight, this.scaleFactor)
          });
          OperationTextCell({
            label: row.value3,
            weight: 0.85,
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
                this.markConsumableChanged(row.id);
              }
            })
          }
          .layoutWeight(0.9)
          .justifyContent(FlexAlign.Center)
        }
        .height(UiUtil.vh(5.0, 38, 54, this.viewportHeight, this.scaleFactor))
        .border({ width: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor), color: '#E5E5E5' })
      }, (row: WqOperationConfigRow) => `${row.id}-${row.value}-${row.value2}-${row.value3}`)

      ForEach(getEmptyRowIndexes(this.consumableRows.length, 7), (index: number) => {
        OperationEmptyTableRow({
          weights: [1.45, 1.15, 1.15, 0.85, 0.9],
          rowHeight: UiUtil.vh(5.0, 38, 54, this.viewportHeight, this.scaleFactor),
          borderWidthValue: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor)
        });
      }, (index: number) => `consumable-empty-${index}`)
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
