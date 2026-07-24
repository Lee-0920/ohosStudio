import { UiUtil } from 'base';
import { SystemHeaderCell, SystemTextCell } from './SystemControls';
import { WqSystemTableRow } from './SystemTypes';

@Component
export struct BoardInfoPanel {
  @Prop boardRows: WqSystemTableRow[] = [];
  @Prop viewportWidth: number = 1024;
  @Prop viewportHeight: number = 768;
  @Prop scaleFactor: number = 1.92;

  build() {
    Column() {
      Row() {
        SystemHeaderCell(
          { label: '板卡', weight: 1.0, fontSizeValue: UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor) });
        SystemHeaderCell(
          { label: '项目', weight: 1.4, fontSizeValue: UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor) });
        SystemHeaderCell(
          { label: '信息', weight: 1.6, fontSizeValue: UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor) });
      }
      .height(UiUtil.vh(4.8, 36, 52, this.viewportHeight, this.scaleFactor))
      .backgroundColor('#F0F0F0')
      .border({ width: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor), color: '#DADADA' })

      Scroll() {
        Column() {
          ForEach(this.boardRows, (row: WqSystemTableRow) => {
            Row() {
              SystemTextCell({
                label: row.category,
                weight: 1.0,
                bold: row.category !== '',
                fontSizeValue: UiUtil.vh(1.8, 11, 15, this.viewportHeight, this.scaleFactor)
              });
              SystemTextCell({
                label: row.item,
                weight: 1.4,
                bold: true,
                fontSizeValue: UiUtil.vh(1.8, 11, 15, this.viewportHeight, this.scaleFactor)
              });
              SystemTextCell({
                label: row.value,
                weight: 1.6,
                fontSizeValue: UiUtil.vh(1.8, 11, 15, this.viewportHeight, this.scaleFactor)
              });
            }
            .height(UiUtil.vh(4.8, 36, 52, this.viewportHeight, this.scaleFactor))
            .border({ width: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor), color: '#E5E5E5' })
          }, (row: WqSystemTableRow) => row.id)
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
