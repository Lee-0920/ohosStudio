import {
  OperationBlueButton,
  OperationCheckCell,
  OperationEmptyTableRow,
  OperationHeaderCell,
  OperationTextCell
} from './OperationControls';
import { copyOperationRow, getEmptyRowIndexes, WqOperationConfigRow } from './OperationTypes';
import { BoardInfo } from '../../models/deviceTypes';
import { MonitorService } from '../../services/MonitorService';
import { UiUtil } from 'base';

@Component
export struct CommunicationCheckPanel {
  @Link communicationRows: WqOperationConfigRow[];
  @Prop viewportWidth: number = 1024;
  @Prop viewportHeight: number = 768;
  @Prop scaleFactor: number = 1.92;
  onRowsChange: (rows: WqOperationConfigRow[]) => void = (_rows: WqOperationConfigRow[]) => {
  };

  private toggleCommunicationRow(rowId: string): void {
    const rows = this.communicationRows.map((row: WqOperationConfigRow) => {
      if (row.id !== rowId) {
        return row;
      }
      return copyOperationRow(row, row.value, row.value2, row.value3, row.value4, row.status, row.result,
        !row.selected);
    });
    this.setCommunicationRows(rows);
  }

  private async runCommunicationCheck(): Promise<void> {
    const connected = MonitorService.isConnectedToMcu() ? true : await MonitorService.connect();
    // const boardInfo = connected ? await MonitorService.readBoardInfo() : null;
    const rows = this.communicationRows.map((row: WqOperationConfigRow) => {
      if (!row.selected) {
        return row;
      }
      if (!connected) {
        return copyOperationRow(row, row.value, row.value2, row.value3, row.value4, row.status, '未连接', row.selected);
      }
      return copyOperationRow(
        row,
        row.value,
        row.value2,
        row.value3,
        row.value4,
        row.status,
        '正常',
        row.selected
      );
    });
    this.setCommunicationRows(rows);
  }

  private setCommunicationRows(rows: WqOperationConfigRow[]): void {
    this.communicationRows = rows;
    this.onRowsChange(rows);
  }

  private getCommunicationResult(row: WqOperationConfigRow, boardInfo: BoardInfo | null): string {
    if (row.id === 'communication-drive-board') {
      if (boardInfo && boardInfo.driverBoard.firmwareVersion) {
        return '正常';
      }
      return '异常';
    }
    // TODO: 当前缺少转接板独立通信检测 API，不能真实判断转接板状态。
    return '暂未接入';
  }

  build() {
    Column() {
      Column() {
        Row() {
          OperationHeaderCell({
            label: '类别',
            weight: 1.0,
            fontSizeValue: UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor)
          });
          OperationHeaderCell({
            label: '选择',
            weight: 0.7,
            fontSizeValue: UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor)
          });
          OperationHeaderCell({
            label: '检测项',
            weight: 1.8,
            fontSizeValue: UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor)
          });
          OperationHeaderCell({
            label: '结果',
            weight: 1.6,
            fontSizeValue: UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor)
          });
        }
        .height(UiUtil.vh(4.8, 36, 52, this.viewportHeight, this.scaleFactor))
        .backgroundColor('#F0F0F0')
        .border({ width: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor), color: '#DADADA' })

        ForEach(this.communicationRows, (row: WqOperationConfigRow) => {
          Row() {
            OperationTextCell({
              label: row.category,
              weight: 1.0,
              fontSizeValue: UiUtil.vh(1.8, 11, 15, this.viewportHeight, this.scaleFactor)
            });
            OperationCheckCell({
              selected: row.selected,
              weight: 0.7,
              boxSize: UiUtil.vh(3.6, 26, 36, this.viewportHeight, this.scaleFactor),
              markSize: UiUtil.vh(2.6, 16, 24, this.viewportHeight, this.scaleFactor),
              borderWidthValue: UiUtil.vh(0.28, 2, 3, this.viewportHeight, this.scaleFactor),
              borderRadiusValue: UiUtil.vh(0.45, 3, 5, this.viewportHeight, this.scaleFactor),
              onAction: () => {
                this.toggleCommunicationRow(row.id);
              }
            });
            OperationTextCell({
              label: row.name,
              weight: 1.8,
              fontSizeValue: UiUtil.vh(1.8, 11, 15, this.viewportHeight, this.scaleFactor)
            });
            OperationTextCell({
              label: row.result,
              weight: 1.6,
              fontSizeValue: UiUtil.vh(1.8, 11, 15, this.viewportHeight, this.scaleFactor),
              fontColorValue: row.result === '正常' ? '#0FA85D' : (row.result.length > 0 ? '#F01010' : '#222222')
            });
          }
          .height(UiUtil.vh(5.0, 38, 54, this.viewportHeight, this.scaleFactor))
          .border({ width: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor), color: '#E5E5E5' })
          .onClick(() => {
            this.toggleCommunicationRow(row.id);
          })
        }, (row: WqOperationConfigRow) => `${row.id}-${row.selected}-${row.result}`)

        ForEach(getEmptyRowIndexes(this.communicationRows.length, 6), (index: number) => {
          OperationEmptyTableRow({
            weights: [1.0, 0.7, 1.8, 1.6],
            rowHeight: UiUtil.vh(5.0, 38, 54, this.viewportHeight, this.scaleFactor),
            borderWidthValue: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor)
          });
        }, (index: number) => `communication-empty-${index}`)
      }
      .layoutWeight(1)
      .width('100%')
      .clip(true)
      .border({ width: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor), color: '#CCCCCC' })

      Row() {
        Blank()
        OperationBlueButton({
          label: '一键检测',
          buttonWidth: UiUtil.vw(10.4, 86, 118, this.viewportWidth, this.scaleFactor),
          buttonHeight: UiUtil.vh(4.4, 34, 48, this.viewportHeight, this.scaleFactor),
          fontSizeValue: UiUtil.vh(1.85, 11, 15, this.viewportHeight, this.scaleFactor),
          borderRadiusValue: UiUtil.vh(0.7, 4, 8, this.viewportHeight, this.scaleFactor),
          onAction: () => {
            void this.runCommunicationCheck();
          }
        })
      }
      .height(UiUtil.vh(6.2, 48, 66, this.viewportHeight, this.scaleFactor))
      .alignItems(VerticalAlign.Center)
      .margin({ top: UiUtil.vh(1.0, 6, 10, this.viewportHeight, this.scaleFactor) })
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
