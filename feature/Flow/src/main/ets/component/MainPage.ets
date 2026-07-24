import { MyButton } from "./MyButton"

@ComponentV2
export struct MainPage {


  build() {
    Column() {

      Row() {
        Column() {
          // --- 顶部标题 ---
          Text('水样')
            .fontSize(28)
            .fontColor('#00FF00') // 绿色
            .alignSelf(ItemAlign.Start) // 靠左
            .margin({ bottom: 10 })

          // --- 中间大数字区域 ---
          Row() {
            // 左侧：时间
            Column() {
              Text('2023-07-20')
                .fontSize(22)
                .fontColor('#00FF00')
              Text('14:11:27')
                .fontSize(22)
                .fontColor('#00FF00')
            }
            .alignItems(HorizontalAlign.Start)

            // 中间：数值（核心）
            Text('45.5')
              .fontSize(100) // 巨大的字体
              .fontWeight(FontWeight.Bold)
              .fontColor('#00FF00')
              .flexGrow(1) // 占据中间所有空间，把左右顶开
              .textAlign(TextAlign.Center)

            // 右侧：单位
            Column() {
              Text('COD')
                .fontSize(22)
                .fontColor('#00FF00')
              Text('mg/L')
                .fontSize(22)
                .fontColor('#00FF00')
            }
            .alignItems(HorizontalAlign.End)
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween) // 上下分布

        }
        // .width('100%')
        .height(300)
        .backgroundColor('#111') // 深灰黑背景
        .borderRadius(20)        // 圆角
        .padding(30)
        .margin(50)
      }
      .width('100%')
      .layoutWeight(7)
      .borderWidth(1)
      .borderColor('Red')

      Row() {
        MyButton({ label: '停止测量' })
        MyButton({ label: '一键校准' })
        MyButton({ label: '标样核查' })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceAround)
      .alignItems(VerticalAlign.Center)
      .layoutWeight(3)
      .borderWidth(1)
      .borderColor('Blue')
      .margin({ left: 50, right: 50 })
    }
    .width('100%')
    .height('100%')
    .borderWidth(1)
    .borderColor('Blue')
  }
}