import { UiUtil } from 'base';
import {
  OperationBlueButton,
  OperationEmptyTableRow,
  OperationHeaderCell,
  OperationInputCell,
  OperationSolidButton
} from './OperationControls';
import { getEmptyRowIndexes, updateOperationRowValue, WqOperationConfigRow } from './OperationTypes';

@Component
export struct CombinationOperationPanel {
  @Link combinationOperationRows: WqOperationConfigRow[];
  @Link operationMessage: string;
  @Prop viewportWidth: number = 1024;
  @Prop viewportHeight: number = 768;
  @Prop scaleFactor: number = 1.92;
  onRowsChange: (rows: WqOperationConfigRow[]) => void = (_rows: WqOperationConfigRow[]) => {
  };
  onMessageChange: (value: string) => void = (_value: string) => {
  };

  private updateCombinationOperationVolume(rowId: string, value: string): void {
    const rows = updateOperationRowValue(this.combinationOperationRows, rowId, 'value', value);
    this.combinationOperationRows = rows;
    this.onRowsChange(rows);
  }

  private markCombinationOperationTodo(rowName: string): void {
    // TODO: 当前缺少组合操作对应的可写控制码和体积参数寄存器，暂不能真实下发。
    const message = `${rowName} 暂未接入设备控制`;
    this.operationMessage = message;
    this.onMessageChange(message);
  }

  build() {
    Row() {
      Column() {
        Row() {
          OperationHeaderCell({
            label: '操作',
            weight: 2.4,
            fontSizeValue: UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor)
          });
          OperationHeaderCell({
            label: '体积(ml)',
            weight: 1.0,
            fontSizeValue: UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor)
          });
        }
        .height(UiUtil.vh(4.8, 36, 52, this.viewportHeight, this.scaleFactor))
        .backgroundColor('#F0F0F0')
        .border({ width: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor), color: '#DADADA' })

        ForEach(this.combinationOperationRows, (row: WqOperationConfigRow) => {
          Row() {
            Row() {
              OperationBlueButton({
                label: row.name,
                buttonWidth: UiUtil.vw(24.0, 182, 260, this.viewportWidth, this.scaleFactor),
                buttonHeight: UiUtil.vh(4.0, 30, 44, this.viewportHeight, this.scaleFactor),
                fontSizeValue: UiUtil.vh(1.85, 11, 15, this.viewportHeight, this.scaleFactor),
                borderRadiusValue: UiUtil.vh(0.7, 4, 8, this.viewportHeight, this.scaleFactor),
                onAction: () => {
                  this.markCombinationOperationTodo(row.name);
                }
              })
            }
            .layoutWeight(2.4)
            .justifyContent(FlexAlign.Center)

            OperationInputCell({
              textValue: row.value,
              weight: 1.0,
              inputHeight: UiUtil.vh(3.7, 28, 40, this.viewportHeight, this.scaleFactor),
              fontSizeValue: UiUtil.vh(1.75, 11, 15, this.viewportHeight, this.scaleFactor),
              borderRadiusValue: UiUtil.vh(0.35, 2, 4, this.viewportHeight, this.scaleFactor),
              onValueChange: (value: string) => {
                this.updateCombinationOperationVolume(row.id, value);
              }
            })
          }
          .height(UiUtil.vh(5.0, 38, 54, this.viewportHeight, this.scaleFactor))
          .border({ width: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor), color: '#E5E5E5' })
        }, (row: WqOperationConfigRow) => `${row.id}-${row.value}-${row.status}-${row.result}`)

        ForEach(getEmptyRowIndexes(this.combinationOperationRows.length, 6), (index: number) => {
          OperationEmptyTableRow({
            weights: [2.4, 1.0],
            rowHeight: UiUtil.vh(5.0, 38, 54, this.viewportHeight, this.scaleFactor),
            borderWidthValue: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor)
          });
        }, (index: number) => `combo-operation-empty-${index}`)
      }
      .layoutWeight(1)
      .height('100%')
      .clip(true)
      .border({ width: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor), color: '#CCCCCC' })

      Column() {
        Blank()
        OperationSolidButton({
          label: '停止',
          buttonWidth: UiUtil.vw(9.0, 80, 108, this.viewportWidth, this.scaleFactor),
          buttonHeight: UiUtil.vh(4.4, 34, 48, this.viewportHeight, this.scaleFactor),
          fontSizeValue: UiUtil.vh(1.85, 11, 15, this.viewportHeight, this.scaleFactor),
          borderRadiusValue: UiUtil.vh(0.7, 4, 8, this.viewportHeight, this.scaleFactor),
          onAction: () => {
            this.markCombinationOperationTodo('停止组合操作');
          }
        })
        Text(this.operationMessage)
          .fontSize(UiUtil.vh(1.55, 10, 13, this.viewportHeight, this.scaleFactor))
          .fontColor('#F01010')
          .textAlign(TextAlign.Center)
          .maxLines(4)
          .margin({ top: UiUtil.vh(1.4, 8, 14, this.viewportHeight, this.scaleFactor) })
        Blank()
      }
      .width(UiUtil.vw(16.0, 124, 180, this.viewportWidth, this.scaleFactor))
      .height('100%')
      .alignItems(HorizontalAlign.Center)
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
