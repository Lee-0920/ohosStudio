@Component
export struct DataActionButton {
  @Prop label: string = '';
  @Prop buttonWidth: number = 80;
  @Prop buttonHeight: number = 40;
  @Prop fontSizeValue: number = 14;
  @Prop borderRadiusValue: number = 8;
  @Prop marginTop: number = 0;
  @Prop marginRight: number = 0;
  @Prop marginBottom: number = 0;
  @Prop marginLeft: number = 0;

  onAction: () => void = () => {};

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Text(this.label)
        .width('100%')
        .fontSize(this.fontSizeValue)
        .fontColor('#FFFFFF')
        .fontWeight(FontWeight.Bold)
        .fontFamily('HarmonyOS Sans')
        .textAlign(TextAlign.Center)
        .maxLines(1)
    }
    .width(this.buttonWidth)
    .height(this.buttonHeight)
    .borderRadius(this.borderRadiusValue)
    .backgroundColor('#0B9F9A')
    .linearGradient({
      angle: 135,
      colors: [
        ['#20D4CA', 0.0],
        ['#0FA6A0', 0.48],
        ['#087D82', 1.0]
      ]
    })
    .border({ width: 1, color: '#55DDF7F2' })
    .shadow({
      radius: 10,
      color: '#55008C8A',
      offsetX: 0,
      offsetY: 3
    })
    .margin({
      top: this.marginTop,
      right: this.marginRight,
      bottom: this.marginBottom,
      left: this.marginLeft
    })
    .onClick(() => {
      this.onAction();
    })
  }
}
