@Component
export struct GradientSideTabItem {
  @Prop label: string = '';
  @Prop selected: boolean = false;
  @Prop fontSizeValue: number = 14;
  @Prop itemBorderWidth: number = 1;
  @Prop itemBorderColor: ResourceColor = '#DDDDDD';
  @Prop borderRadiusValue: number = 0;
  @Prop selectedTextColor: ResourceColor = '#FFFFFF';
  @Prop normalTextColor: ResourceColor = '#000000';
  @Prop normalBackgroundColor: ResourceColor = '#FFFFFF';

  onAction: () => void = () => {};

  @Builder
  private labelContent() {
    Text(this.label)
      .width('100%')
      .fontSize(this.fontSizeValue)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.selected ? this.selectedTextColor : this.normalTextColor)
      .textAlign(TextAlign.Center)
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
  }

  build() {
    if (this.selected) {
      Stack({ alignContent: Alignment.Center }) {
        this.labelContent()
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#0FA6A0')
      .linearGradient({
        angle: 135,
        colors: [
          ['#20D4CA', 0.0],
          ['#0FA6A0', 0.48],
          ['#087D82', 1.0]
        ]
      })
      .borderRadius(this.borderRadiusValue)
      .border({ width: this.itemBorderWidth, color: this.itemBorderColor })
      .onClick(() => {
        this.onAction();
      })
    } else {
      Stack({ alignContent: Alignment.Center }) {
        this.labelContent()
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.normalBackgroundColor)
      .borderRadius(this.borderRadiusValue)
      .border({ width: this.itemBorderWidth, color: this.itemBorderColor })
      .onClick(() => {
        this.onAction();
      })
    }
  }
}
