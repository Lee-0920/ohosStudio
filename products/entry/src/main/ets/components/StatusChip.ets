import { UiUtil } from "base";

@Component
export struct StatusChip {
  // Text displayed inside status chip, such as idle/running state.
  @Prop label: string = '';
  @Prop viewportWidth: number = 1024;
  @Prop viewportHeight: number = 768;
  @Prop scaleFactor: number = 1.92;

  build() {
    // Compact status badge used in home page runtime panel.
    Row() {
      Text(this.label)
        .fontSize(UiUtil.vh(1.4, 10, 16, this.viewportHeight, this.scaleFactor))
        .fontColor('#D8DEE4')
        .fontWeight(FontWeight.Regular)
        .fontFamily('HarmonyOS Sans')
    }
    .width(UiUtil.vw(11.6, 100, 176, this.viewportWidth, this.scaleFactor))
    .height(UiUtil.vh(2.8, 22, 34, this.viewportHeight, this.scaleFactor))
    .padding({
      left: UiUtil.vw(1.0, 8, 16, this.viewportWidth, this.scaleFactor),
      right: UiUtil.vw(1.0, 8, 16, this.viewportWidth, this.scaleFactor)
    })
    .borderRadius(UiUtil.vh(1.4, 10, 18, this.viewportHeight, this.scaleFactor))
    .border({ width: UiUtil.vh(0.1, 1, 1.8, this.viewportHeight, this.scaleFactor), color: '#777676' })
    .backgroundColor('#383737')
    .justifyContent(FlexAlign.Center)
  }
}
