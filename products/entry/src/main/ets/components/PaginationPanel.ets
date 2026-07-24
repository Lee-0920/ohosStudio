import { UiUtil } from 'base';
import { DataActionButton } from './DataActionButton';

@Component
export struct PaginationPanel {
  // true: vertical pagination (right side), false: horizontal pagination (bottom).
  @Prop vertical: boolean = true;
  @Prop viewportWidth: number = 1024;
  @Prop viewportHeight: number = 768;
  @Prop scaleFactor: number = 1.92;

  build() {
    if (this.vertical) {
      // Pagination buttons for table right side layout.
      Column() {
        DataActionButton({
          label: '首页',
          buttonWidth: UiUtil.vw(6.4, 62, 88, this.viewportWidth, this.scaleFactor),
          buttonHeight: UiUtil.vh(4.2, 32, 46, this.viewportHeight, this.scaleFactor),
          fontSizeValue: UiUtil.vh(2.0, 12, 16, this.viewportHeight, this.scaleFactor),
          borderRadiusValue: UiUtil.vh(0.8, 5, 10, this.viewportHeight, this.scaleFactor),
          marginBottom: UiUtil.vh(0.9, 6, 12, this.viewportHeight, this.scaleFactor)
        })
        DataActionButton({
          label: '上一页',
          buttonWidth: UiUtil.vw(6.4, 62, 88, this.viewportWidth, this.scaleFactor),
          buttonHeight: UiUtil.vh(4.2, 32, 46, this.viewportHeight, this.scaleFactor),
          fontSizeValue: UiUtil.vh(2.0, 12, 16, this.viewportHeight, this.scaleFactor),
          borderRadiusValue: UiUtil.vh(0.8, 5, 10, this.viewportHeight, this.scaleFactor),
          marginBottom: UiUtil.vh(0.9, 6, 12, this.viewportHeight, this.scaleFactor)
        })
        DataActionButton({
          label: '下一页',
          buttonWidth: UiUtil.vw(6.4, 62, 88, this.viewportWidth, this.scaleFactor),
          buttonHeight: UiUtil.vh(4.2, 32, 46, this.viewportHeight, this.scaleFactor),
          fontSizeValue: UiUtil.vh(2.0, 12, 16, this.viewportHeight, this.scaleFactor),
          borderRadiusValue: UiUtil.vh(0.8, 5, 10, this.viewportHeight, this.scaleFactor),
          marginBottom: UiUtil.vh(0.9, 6, 12, this.viewportHeight, this.scaleFactor)
        })
        DataActionButton({
          label: '尾页',
          buttonWidth: UiUtil.vw(6.4, 62, 88, this.viewportWidth, this.scaleFactor),
          buttonHeight: UiUtil.vh(4.2, 32, 46, this.viewportHeight, this.scaleFactor),
          fontSizeValue: UiUtil.vh(2.0, 12, 16, this.viewportHeight, this.scaleFactor),
          borderRadiusValue: UiUtil.vh(0.8, 5, 10, this.viewportHeight, this.scaleFactor)
        })
      }
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Center)
      .width(UiUtil.vw(7.6, 72, 104, this.viewportWidth, this.scaleFactor))
      .padding({
        // top: UiUtil.vh(0.25, 2, 4),
        left: UiUtil.vw(0.4, 4, 8, this.viewportWidth, this.scaleFactor),
        right: UiUtil.vw(0.4, 4, 8, this.viewportWidth, this.scaleFactor)
      })
    } else {
      // Pagination buttons for bottom bar layout.
      Row() {
        DataActionButton({
          label: '首页',
          buttonWidth: UiUtil.vw(12.5, 84, 126, this.viewportWidth, this.scaleFactor),
          buttonHeight: UiUtil.vh(3.8, 30, 42, this.viewportHeight, this.scaleFactor),
          fontSizeValue: UiUtil.vh(1.3, 10, 14, this.viewportHeight, this.scaleFactor),
          borderRadiusValue: UiUtil.vh(0.8, 5, 10, this.viewportHeight, this.scaleFactor)
        })
        DataActionButton({
          label: '上一页',
          buttonWidth: UiUtil.vw(12.5, 84, 126, this.viewportWidth, this.scaleFactor),
          buttonHeight: UiUtil.vh(3.8, 30, 42, this.viewportHeight, this.scaleFactor),
          fontSizeValue: UiUtil.vh(1.3, 10, 14, this.viewportHeight, this.scaleFactor),
          borderRadiusValue: UiUtil.vh(0.8, 5, 10, this.viewportHeight, this.scaleFactor)
        })
        DataActionButton({
          label: '下一页',
          buttonWidth: UiUtil.vw(12.5, 84, 126, this.viewportWidth, this.scaleFactor),
          buttonHeight: UiUtil.vh(3.8, 30, 42, this.viewportHeight, this.scaleFactor),
          fontSizeValue: UiUtil.vh(1.3, 10, 14, this.viewportHeight, this.scaleFactor),
          borderRadiusValue: UiUtil.vh(0.8, 5, 10, this.viewportHeight, this.scaleFactor)
        })
        DataActionButton({
          label: '尾页',
          buttonWidth: UiUtil.vw(12.5, 84, 126, this.viewportWidth, this.scaleFactor),
          buttonHeight: UiUtil.vh(3.8, 30, 42, this.viewportHeight, this.scaleFactor),
          fontSizeValue: UiUtil.vh(1.3, 10, 14, this.viewportHeight, this.scaleFactor),
          borderRadiusValue: UiUtil.vh(0.8, 5, 10, this.viewportHeight, this.scaleFactor)
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly)
      .margin({
        top: UiUtil.vh(0.8, 6, 10, this.viewportHeight, this.scaleFactor),
        bottom: UiUtil.vh(0.6, 4, 8, this.viewportHeight, this.scaleFactor)
      })
    }
  }
}
