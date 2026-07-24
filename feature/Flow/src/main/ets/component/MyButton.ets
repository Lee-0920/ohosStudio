@ComponentV2
export struct MyButton {
  // 接收一个字符串参数作为按钮文字
  @Param label: string = '';

  build() {
    Button() {
      Text(this.label)
        .fontSize(38)         // 大字体
        .fontColor(Color.White) // 白字
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin(5)
    }
      .width(100)           // 固定宽度，保持截图中的大小
      .height(100)          // 固定高度

      .backgroundColor('#007DFF') // 蓝色背景
      .borderRadius(16)     // 圆角
      .type(ButtonType.ROUNDED_RECTANGLE) // 胶囊形状（配合圆角更饱满）
      .shadow({ radius: 4, color: 'rgba(0, 0, 0, 0.2)' }) // 可选：加点阴影立体感
  }
}