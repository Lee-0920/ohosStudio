import { UiUtil } from 'base';
import { DataActionButton } from '../DataActionButton';

@Component
export struct DataPager {
  @Prop currentPage: number = 1;
  @Prop totalPages: number = 1;
  @Prop viewportWidth: number = 1024;
  @Prop viewportHeight: number = 768;
  @Prop scaleFactor: number = 1.92;
  onFirst: () => void = () => {
  };
  onPrevious: () => void = () => {
  };
  onNext: () => void = () => {
  };
  onLast: () => void = () => {
  };
  onExport: () => void = () => {
  };
  onClear: () => void = () => {
  };
  @Prop showExport: boolean = true;

  build() {
    Column() {
      DataActionButton({
        label: '首页',
        buttonWidth: UiUtil.vw(6.4, 62, 88, this.viewportWidth, this.scaleFactor),
        buttonHeight: UiUtil.vh(4.2, 32, 46, this.viewportHeight, this.scaleFactor),
        fontSizeValue: UiUtil.vh(2.0, 12, 16, this.viewportHeight, this.scaleFactor),
        borderRadiusValue: UiUtil.vh(0.8, 5, 10, this.viewportHeight, this.scaleFactor),
        marginBottom: UiUtil.vh(0.9, 6, 12, this.viewportHeight, this.scaleFactor),
        onAction: () => this.onFirst()
      })
      DataActionButton({
        label: '上一页',
        buttonWidth: UiUtil.vw(6.4, 62, 88, this.viewportWidth, this.scaleFactor),
        buttonHeight: UiUtil.vh(4.2, 32, 46, this.viewportHeight, this.scaleFactor),
        fontSizeValue: UiUtil.vh(2.0, 12, 16, this.viewportHeight, this.scaleFactor),
        borderRadiusValue: UiUtil.vh(0.8, 5, 10, this.viewportHeight, this.scaleFactor),
        marginBottom: UiUtil.vh(0.9, 6, 12, this.viewportHeight, this.scaleFactor),
        onAction: () => this.onPrevious()
      })
      DataActionButton({
        label: '下一页',
        buttonWidth: UiUtil.vw(6.4, 62, 88, this.viewportWidth, this.scaleFactor),
        buttonHeight: UiUtil.vh(4.2, 32, 46, this.viewportHeight, this.scaleFactor),
        fontSizeValue: UiUtil.vh(2.0, 12, 16, this.viewportHeight, this.scaleFactor),
        borderRadiusValue: UiUtil.vh(0.8, 5, 10, this.viewportHeight, this.scaleFactor),
        marginBottom: UiUtil.vh(0.9, 6, 12, this.viewportHeight, this.scaleFactor),
        onAction: () => this.onNext()
      })
      DataActionButton({
        label: '尾页',
        buttonWidth: UiUtil.vw(6.4, 62, 88, this.viewportWidth, this.scaleFactor),
        buttonHeight: UiUtil.vh(4.2, 32, 46, this.viewportHeight, this.scaleFactor),
        fontSizeValue: UiUtil.vh(2.0, 12, 16, this.viewportHeight, this.scaleFactor),
        borderRadiusValue: UiUtil.vh(0.8, 5, 10, this.viewportHeight, this.scaleFactor),
        marginBottom: UiUtil.vh(0.9, 6, 12, this.viewportHeight, this.scaleFactor),
        onAction: () => this.onLast()
      })
      if (this.showExport) {
        DataActionButton({
          label: '导出',
          buttonWidth: UiUtil.vw(6.4, 62, 88, this.viewportWidth, this.scaleFactor),
          buttonHeight: UiUtil.vh(4.2, 32, 46, this.viewportHeight, this.scaleFactor),
          fontSizeValue: UiUtil.vh(2.0, 12, 16, this.viewportHeight, this.scaleFactor),
          borderRadiusValue: UiUtil.vh(0.8, 5, 10, this.viewportHeight, this.scaleFactor),
          marginBottom: UiUtil.vh(0.9, 6, 12, this.viewportHeight, this.scaleFactor),
          onAction: () => this.onExport()
        })
      }
      DataActionButton({
        label: '清空',
        buttonWidth: UiUtil.vw(6.4, 62, 88, this.viewportWidth, this.scaleFactor),
        buttonHeight: UiUtil.vh(4.2, 32, 46, this.viewportHeight, this.scaleFactor),
        fontSizeValue: UiUtil.vh(2.0, 12, 16, this.viewportHeight, this.scaleFactor),
        borderRadiusValue: UiUtil.vh(0.8, 5, 10, this.viewportHeight, this.scaleFactor),
        marginBottom: UiUtil.vh(0.9, 6, 12, this.viewportHeight, this.scaleFactor),
        onAction: () => this.onClear()
      })

      Text(`${this.currentPage}/${this.totalPages}`)
        .fontSize(UiUtil.vh(1.6, 11, 15, this.viewportHeight, this.scaleFactor))
        .fontColor('#666666')
        .margin({ top: UiUtil.vh(1.2, 8, 14, this.viewportHeight, this.scaleFactor) })
    }
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center)
    .width(UiUtil.vw(7.6, 72, 104, this.viewportWidth, this.scaleFactor))
    .padding({
      left: UiUtil.vw(0.4, 4, 8, this.viewportWidth, this.scaleFactor),
      right: UiUtil.vw(0.4, 4, 8, this.viewportWidth, this.scaleFactor)
    })
  }
}
