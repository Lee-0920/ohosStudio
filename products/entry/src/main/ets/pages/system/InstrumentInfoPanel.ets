import { UiUtil } from 'base';
import { WqSystemInfoItem } from '../../models/monitorTypes';

@Component
export struct InstrumentInfoPanel {
  @Prop systemInfoList: WqSystemInfoItem[] = [];
  @Prop viewportWidth: number = 1024;
  @Prop viewportHeight: number = 768;
  @Prop scaleFactor: number = 1.92;

  build() {
    Row() {
      Column() {
        ForEach(this.systemInfoList, (item: WqSystemInfoItem) => {
          Row() {
            Text(item.label + '：')
              .width(UiUtil.vw(8.0, 62, 100, this.viewportWidth, this.scaleFactor))
              .fontSize(UiUtil.vh(2.2, 11, 16, this.viewportHeight, this.scaleFactor))
              .fontWeight(FontWeight.Bold)
            Text(item.value)
              .fontSize(UiUtil.vh(2.2, 11, 16, this.viewportHeight, this.scaleFactor))
              .layoutWeight(1)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .margin({ bottom: UiUtil.vh(1.8, 12, 24, this.viewportHeight, this.scaleFactor) })
        })
      }
      .layoutWeight(1)
      .padding({
        left: UiUtil.vw(0.8, 6, 10, this.viewportWidth, this.scaleFactor),
        top: UiUtil.vh(1.1, 8, 12, this.viewportHeight, this.scaleFactor),
        right: UiUtil.vw(0.6, 4, 8, this.viewportWidth, this.scaleFactor),
        bottom: UiUtil.vh(1.0, 8, 12, this.viewportHeight, this.scaleFactor)
      })
      .alignItems(HorizontalAlign.Start)

      Column() {
        Image($r('app.media.logo_shuiwu'))
          .width(UiUtil.vw(16, 120, 200, this.viewportWidth, this.scaleFactor))
          .height(UiUtil.vh(10, 64, 110, this.viewportHeight, this.scaleFactor))
          .objectFit(ImageFit.Contain)
      }
      .width(UiUtil.vw(17.2, 130, 220, this.viewportWidth, this.scaleFactor))
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .layoutWeight(1)
    .alignItems(VerticalAlign.Top)
    .backgroundColor('#FFFFFF')
    .border({ width: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor), color: '#DDDDDD' })
    .margin({
      left: UiUtil.vw(0.8, 6, 10, this.viewportWidth, this.scaleFactor),
      right: UiUtil.vw(0.8, 6, 10, this.viewportWidth, this.scaleFactor),
      top: UiUtil.vh(0.8, 6, 10, this.viewportHeight, this.scaleFactor),
      bottom: UiUtil.vh(0.8, 6, 10, this.viewportHeight, this.scaleFactor)
    })
  }
}
