import { UiUtil } from 'base';
import {
  OperationBlueButton,
  OperationCheckCell,
  OperationHeaderCell,
  OperationSolidButton,
  OperationTextCell
} from './OperationControls';
import { copyOperationRow, WqOperationConfigRow } from './OperationTypes';

@Component
export struct IntelligentDiagnosisPanel {
  @Link diagnoseRows: WqOperationConfigRow[];
  @Prop viewportWidth: number = 1024;
  @Prop viewportHeight: number = 768;
  @Prop scaleFactor: number = 1.92;
  onRowsChange: (rows: WqOperationConfigRow[]) => void = (_rows: WqOperationConfigRow[]) => {
  };

  private toggleDiagnoseRow(rowId: string): void {
    const rows = this.diagnoseRows.map((row: WqOperationConfigRow) => {
      if (row.id !== rowId) {
        return row;
      }
      return copyOperationRow(row, row.value, row.value2, row.value3, row.value4, row.status, row.result,
        !row.selected);
    });
    this.setDiagnoseRows(rows);
  }

  private selectAllDiagnoseRows(): void {
    const rows = this.diagnoseRows.map((row: WqOperationConfigRow) => {
      return copyOperationRow(row, row.value, row.value2, row.value3, row.value4, row.status, row.result, true);
    });
    this.setDiagnoseRows(rows);
  }

  private runDiagnoseRows(): void {
    // TODO: 当前缺少按诊断项启动阀/泵诊断的可写 API，不能真实执行智能诊断。
    const rows = this.diagnoseRows.map((row: WqOperationConfigRow) => {
      return copyOperationRow(
        row,
        row.value,
        row.value2,
        row.value3,
        row.value4,
        row.status,
        row.selected ? '未接入' : row.result,
        row.selected,
        false
      );
    });
    this.setDiagnoseRows(rows);
  }

  private stopDiagnoseRows(): void {
    const rows = this.diagnoseRows.map((row: WqOperationConfigRow) => {
      return copyOperationRow(
        row,
        row.value,
        row.value2,
        row.value3,
        row.value4,
        row.status,
        row.running ? '已停止' : row.result,
        row.selected,
        false
      );
    });
    this.setDiagnoseRows(rows);
  }

  private setDiagnoseRows(rows: WqOperationConfigRow[]): void {
    this.diagnoseRows = rows;
    this.onRowsChange(rows);
  }

  build() {
    Row() {
      Column() {
        Row() {
          OperationHeaderCell({
            label: '选择',
            weight: 0.7,
            fontSizeValue: UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor)
          });
          OperationHeaderCell({
            label: '诊断项',
            weight: 2.2,
            fontSizeValue: UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor)
          });
          OperationHeaderCell({
            label: '结果',
            weight: 1.2,
            fontSizeValue: UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor)
          });
        }
        .height(UiUtil.vh(4.8, 36, 52, this.viewportHeight, this.scaleFactor))
        .backgroundColor('#F0F0F0')
        .border({ width: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor), color: '#DADADA' })

        Scroll() {
          Column() {
            ForEach(this.diagnoseRows, (row: WqOperationConfigRow) => {
              Row() {
                OperationCheckCell({
                  selected: row.selected,
                  weight: 0.7,
                  boxSize: UiUtil.vh(3.6, 26, 36, this.viewportHeight, this.scaleFactor),
                  markSize: UiUtil.vh(2.6, 16, 24, this.viewportHeight, this.scaleFactor),
                  borderWidthValue: UiUtil.vh(0.28, 2, 3, this.viewportHeight, this.scaleFactor),
                  borderRadiusValue: UiUtil.vh(0.45, 3, 5, this.viewportHeight, this.scaleFactor),
                  onAction: () => {
                    this.toggleDiagnoseRow(row.id);
                  }
                });
                OperationTextCell({
                  label: row.name,
                  weight: 2.2,
                  fontSizeValue: UiUtil.vh(1.8, 11, 15, this.viewportHeight, this.scaleFactor)
                });
                OperationTextCell({
                  label: row.result,
                  weight: 1.2,
                  fontSizeValue: UiUtil.vh(1.8, 11, 15, this.viewportHeight, this.scaleFactor),
                  fontColorValue: row.result === '已停止' || row.result === '未接入' ? '#F01010' : '#222222'
                });
              }
              .height(UiUtil.vh(5.0, 38, 54, this.viewportHeight, this.scaleFactor))
              .border({ width: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor), color: '#E5E5E5' })
              .onClick(() => {
                this.toggleDiagnoseRow(row.id);
              })
            }, (row: WqOperationConfigRow) => `${row.id}-${row.selected}-${row.result}-${row.running}`)
          }
        }
        .layoutWeight(1)
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Auto)
      }
      .layoutWeight(1)
      .height('100%')
      .clip(true)
      .border({ width: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor), color: '#CCCCCC' })

      Column() {
        OperationBlueButton({
          label: '全选',
          buttonWidth: UiUtil.vw(9.0, 80, 108, this.viewportWidth, this.scaleFactor),
          buttonHeight: UiUtil.vh(4.4, 34, 48, this.viewportHeight, this.scaleFactor),
          fontSizeValue: UiUtil.vh(1.85, 11, 15, this.viewportHeight, this.scaleFactor),
          borderRadiusValue: UiUtil.vh(0.7, 4, 8, this.viewportHeight, this.scaleFactor),
          onAction: () => {
            this.selectAllDiagnoseRows();
          }
        })
        Blank()
          .height(UiUtil.vh(2.0, 14, 22, this.viewportHeight, this.scaleFactor))
        OperationBlueButton({
          label: '一键检测',
          buttonWidth: UiUtil.vw(9.0, 80, 108, this.viewportWidth, this.scaleFactor),
          buttonHeight: UiUtil.vh(4.4, 34, 48, this.viewportHeight, this.scaleFactor),
          fontSizeValue: UiUtil.vh(1.85, 11, 15, this.viewportHeight, this.scaleFactor),
          borderRadiusValue: UiUtil.vh(0.7, 4, 8, this.viewportHeight, this.scaleFactor),
          onAction: () => {
            this.runDiagnoseRows();
          }
        })
        Blank()
          .height(UiUtil.vh(2.0, 14, 22, this.viewportHeight, this.scaleFactor))
        OperationBlueButton({
          label: '一键停止',
          buttonWidth: UiUtil.vw(9.0, 80, 108, this.viewportWidth, this.scaleFactor),
          buttonHeight: UiUtil.vh(4.4, 34, 48, this.viewportHeight, this.scaleFactor),
          fontSizeValue: UiUtil.vh(1.85, 11, 15, this.viewportHeight, this.scaleFactor),
          borderRadiusValue: UiUtil.vh(0.7, 4, 8, this.viewportHeight, this.scaleFactor),
          onAction: () => {
            this.stopDiagnoseRows();
          }
        })
        Blank()
          .height(UiUtil.vh(2.0, 14, 22, this.viewportHeight, this.scaleFactor))
        OperationSolidButton({
          label: '停止',
          buttonWidth: UiUtil.vw(9.0, 80, 108, this.viewportWidth, this.scaleFactor),
          buttonHeight: UiUtil.vh(4.4, 34, 48, this.viewportHeight, this.scaleFactor),
          fontSizeValue: UiUtil.vh(1.85, 11, 15, this.viewportHeight, this.scaleFactor),
          borderRadiusValue: UiUtil.vh(0.7, 4, 8, this.viewportHeight, this.scaleFactor),
          onAction: () => {
            this.stopDiagnoseRows();
          }
        })
      }
      .width(UiUtil.vw(15.0, 118, 168, this.viewportWidth, this.scaleFactor))
      .height('100%')
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .padding({ left: UiUtil.vw(1.2, 10, 16, this.viewportWidth, this.scaleFactor) })
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
