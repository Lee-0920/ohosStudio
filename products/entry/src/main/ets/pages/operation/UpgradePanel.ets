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
export struct UpgradePanel {
  @Link upgradeRows: WqOperationConfigRow[];
  @Prop viewportWidth: number = 1024;
  @Prop viewportHeight: number = 768;
  @Prop scaleFactor: number = 1.92;
  onRowsChange: (rows: WqOperationConfigRow[]) => void = (_rows: WqOperationConfigRow[]) => {
  };

  private toggleUpgradeRow(rowId: string): void {
    const rows = this.upgradeRows.map((row: WqOperationConfigRow) => {
      if (row.id !== rowId) {
        return row;
      }
      return copyOperationRow(row, row.value, row.value2, row.value3, row.value4, row.status, row.result,
        !row.selected);
    });
    this.setUpgradeRows(rows);
  }

  private async refreshUpgradePackages(): Promise<void> {
    const connected = MonitorService.isConnectedToMcu() ? true : await MonitorService.connect();
    if (!connected) {
      const rows = this.upgradeRows.map((row: WqOperationConfigRow) => {
        return copyOperationRow(row, row.value, row.value2, row.value3, row.value4, '读取失败：未连接');
      });
      this.setUpgradeRows(rows);
      return;
    }

    const boardInfo: BoardInfo | null = await MonitorService.readBoardInfo();
    const rows = this.upgradeRows.map((row: WqOperationConfigRow) => {
      if (!boardInfo) {
        return copyOperationRow(row, row.value, row.value2, row.value3, row.value4, '读取失败');
      }
      if (row.id === 'upgrade-main-board') {
        return copyOperationRow(
          row,
          row.value,
          this.formatVersion(boardInfo.mainBoard.firmwareVersion ? boardInfo.mainBoard.firmwareVersion.text : null),
          row.value3,
          row.value4,
          '已刷新'
        );
      }
      if (row.id === 'upgrade-drive-board') {
        return copyOperationRow(
          row,
          row.value,
          this.formatVersion(boardInfo.driverBoard.firmwareVersion ? boardInfo.driverBoard.firmwareVersion.text : null),
          row.value3,
          row.value4,
          '已刷新'
        );
      }
      return row;
    });
    this.setUpgradeRows(rows);
  }

  private markUpgradeTodo(): void {
    // TODO: 当前缺少 U 盘升级包扫描、目标版本解析、升级下发和进度/失败恢复 API。
    const rows = this.upgradeRows.map((row: WqOperationConfigRow) => {
      if (!row.selected) {
        return row;
      }
      return copyOperationRow(row, row.value, row.value2, row.value3, row.value4, '暂未接入');
    });
    this.setUpgradeRows(rows);
  }

  private setUpgradeRows(rows: WqOperationConfigRow[]): void {
    this.upgradeRows = rows;
    this.onRowsChange(rows);
  }

  private formatVersion(version: string | null): string {
    if (version && version.length > 0) {
      return version;
    }
    return '-';
  }

  build() {
    Column() {
      Column() {
        Row() {
          OperationHeaderCell({
            label: '选择',
            weight: 0.7,
            fontSizeValue: UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor)
          });
          OperationHeaderCell({
            label: '板卡',
            weight: 1.0,
            fontSizeValue: UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor)
          });
          OperationHeaderCell({
            label: '地址',
            weight: 1.0,
            fontSizeValue: UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor)
          });
          OperationHeaderCell({
            label: '当前版本',
            weight: 1.1,
            fontSizeValue: UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor)
          });
          OperationHeaderCell({
            label: '升级版本',
            weight: 1.2,
            fontSizeValue: UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor)
          });
          OperationHeaderCell({
            label: '状态',
            weight: 1.1,
            fontSizeValue: UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor)
          });
        }
        .height(UiUtil.vh(4.8, 36, 52, this.viewportHeight, this.scaleFactor))
        .backgroundColor('#F0F0F0')
        .border({ width: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor), color: '#DADADA' })

        ForEach(this.upgradeRows, (row: WqOperationConfigRow) => {
          Row() {
            OperationCheckCell({
              selected: row.selected,
              weight: 0.7,
              boxSize: UiUtil.vh(3.6, 26, 36, this.viewportHeight, this.scaleFactor),
              markSize: UiUtil.vh(2.6, 16, 24, this.viewportHeight, this.scaleFactor),
              borderWidthValue: UiUtil.vh(0.28, 2, 3, this.viewportHeight, this.scaleFactor),
              borderRadiusValue: UiUtil.vh(0.45, 3, 5, this.viewportHeight, this.scaleFactor),
              onAction: () => {
                this.toggleUpgradeRow(row.id);
              }
            });
            OperationTextCell({
              label: row.name,
              weight: 1.0,
              fontSizeValue: UiUtil.vh(1.8, 11, 15, this.viewportHeight, this.scaleFactor)
            });
            OperationTextCell({
              label: row.value,
              weight: 1.0,
              fontSizeValue: UiUtil.vh(1.8, 11, 15, this.viewportHeight, this.scaleFactor)
            });
            OperationTextCell({
              label: row.value2,
              weight: 1.1,
              fontSizeValue: UiUtil.vh(1.8, 11, 15, this.viewportHeight, this.scaleFactor)
            });
            OperationTextCell({
              label: row.value3,
              weight: 1.2,
              fontSizeValue: UiUtil.vh(1.8, 11, 15, this.viewportHeight, this.scaleFactor)
            });
            OperationTextCell({
              label: row.status,
              weight: 1.1,
              fontSizeValue: UiUtil.vh(1.65, 10, 14, this.viewportHeight, this.scaleFactor),
              fontColorValue: row.status === '暂未接入' || row.status.indexOf('失败') >= 0 ? '#F01010' : '#222222'
            });
          }
          .height(UiUtil.vh(5.0, 38, 54, this.viewportHeight, this.scaleFactor))
          .border({ width: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor), color: '#E5E5E5' })
          .onClick(() => {
            this.toggleUpgradeRow(row.id);
          })
        }, (row: WqOperationConfigRow) => `${row.id}-${row.selected}-${row.status}-${row.value2}-${row.value3}`)

        ForEach(getEmptyRowIndexes(this.upgradeRows.length, 6), (index: number) => {
          OperationEmptyTableRow({
            weights: [0.7, 1.0, 1.0, 1.1, 1.2, 1.1],
            rowHeight: UiUtil.vh(5.0, 38, 54, this.viewportHeight, this.scaleFactor),
            borderWidthValue: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor)
          });
        }, (index: number) => `upgrade-empty-${index}`)
      }
      .layoutWeight(1)
      .width('100%')
      .clip(true)
      .border({ width: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor), color: '#CCCCCC' })

      Row() {
        OperationBlueButton({
          label: '刷新',
          buttonWidth: UiUtil.vw(8.8, 76, 104, this.viewportWidth, this.scaleFactor),
          buttonHeight: UiUtil.vh(4.4, 34, 48, this.viewportHeight, this.scaleFactor),
          fontSizeValue: UiUtil.vh(1.85, 11, 15, this.viewportHeight, this.scaleFactor),
          borderRadiusValue: UiUtil.vh(0.7, 4, 8, this.viewportHeight, this.scaleFactor),
          onAction: () => {
            void this.refreshUpgradePackages();
          }
        })

        Blank()

        Text('升级包来源： U盘')
          .fontSize(UiUtil.vh(1.8, 11, 15, this.viewportHeight, this.scaleFactor))
          .fontColor('#222222')

        Blank()

        OperationBlueButton({
          label: '一键升级',
          buttonWidth: UiUtil.vw(10.4, 86, 118, this.viewportWidth, this.scaleFactor),
          buttonHeight: UiUtil.vh(4.4, 34, 48, this.viewportHeight, this.scaleFactor),
          fontSizeValue: UiUtil.vh(1.85, 11, 15, this.viewportHeight, this.scaleFactor),
          borderRadiusValue: UiUtil.vh(0.7, 4, 8, this.viewportHeight, this.scaleFactor),
          onAction: () => {
            this.markUpgradeTodo();
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
