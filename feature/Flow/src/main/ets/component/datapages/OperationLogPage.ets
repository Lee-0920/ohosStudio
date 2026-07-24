@ComponentV2
export struct OperationLogPage {
  private columns: string[] = ['时间', '内容'];
  private data: string[][] = [
    ['2023-07-20 14:11', '测试内容1'],
    ['2023-07-21 14:11', '测试内容2'],
    ['2023-07-22 14:11', '测试内容3'],
    ['2023-07-23 14:11', '测试内容4'],
    ['2023-07-24 14:11', '测试内容5'],
    ['2023-07-25 14:11', '测试内容6'],
    ['2023-07-26 14:11', '测试内容7'],
    ['2023-07-27 14:11', '测试内容8'],
  ]

  @Local startDate: string = '2023-07-13'
  @Local endDate:   string = '2023-07-20'
  @Local selType:   string = '所有告警'

  build() {
    Row() {
      Column() {
        Grid() {
          ForEach(this.columns, (col: string) => {
            GridItem() {
              Row() {
                Text(col)
                  .fontSize(16)
                  .fontColor('#333333')
                  .fontWeight(FontWeight.Medium)
                  .textAlign(TextAlign.Center)
                  .layoutWeight(1)
              }
              .width('100%')
              .height('100%')
              .alignItems(VerticalAlign.Center) // ✅ 上下居中
              .justifyContent(FlexAlign.Center) // ✅ 左右居中
            }
          })
        }
        .width('100%')
        .height(44)
        .columnsTemplate('1fr 3fr')
        .backgroundColor('#F5F5F5')
        .border({ width: { bottom: 1 }, color: '#E0E0E0' })

        Grid() {
          ForEach(this.data, (row: string[], rowIdx: number) => {
            ForEach(row, (cell: string, colIdx: number) => {
              GridItem() {
                Row() {
                  Text(cell)
                    .fontSize(14)
                    .textAlign(TextAlign.Center)
                    .layoutWeight(1)
                }
                .width('100%')
                .height(42)
                .backgroundColor(rowIdx % 2 === 0 ? '#FAFAFA' : '#FFFFFF')
                .border({ width: { bottom: 1 }, color: '#EEEEEE' })
              }
            })
          })
        }
        .width('100%')
        .layoutWeight(1)
        .enabled(false)
        .columnsTemplate('1fr 3fr')

        // ==================== 底部筛选栏 ====================
        Row() {
          // 日期区间
          Row({ space: 6 }) {
            Text(this.startDate)
              .fontSize(14)
              .padding({ left: 8, right: 8, top: 6, bottom: 6 })
              .backgroundColor('#FFFFFF')
              .border({ width: 1, color: '#CCCCCC' })
              .borderRadius(4)

            Text('—')
              .fontSize(14)
              .fontColor('#999999')

            Text(this.endDate)
              .fontSize(14)
              .padding({ left: 8, right: 8, top: 6, bottom: 6 })
              .backgroundColor('#FFFFFF')
              .border({ width: 1, color: '#CCCCCC' })
              .borderRadius(4)
          }
          .margin({ right: 16 })

          // 标识下拉
          // this.FilterSelect('标识', this.selFlag)
          this.FilterSelect('类型', this.selType)

          // 检索按钮
          Button('检索')
            .width(80)
            .height(36)
            .fontSize(15)
            .fontColor(Color.White)
            .backgroundColor('#007DFF')
            .borderRadius(6)
            .margin({ left: 12 })
        }
        .width('100%')
        .height(60)
        .padding({ left: 16, right: 16 })
        .backgroundColor('#F0F0F0')
        .alignItems(VerticalAlign.Center)
      }
      .height('100%')
      .justifyContent(FlexAlign.Start)
      .layoutWeight(1)
      .borderWidth(1)
      .borderColor('black')

      Column() {
        Button('首页').width(80).height(40).margin(2).backgroundColor(Color.Blue).fontColor('#FFFFFF')
        Button('上一页').width(80).height(40).margin(2).backgroundColor(Color.Blue).fontColor('#FFFFFF')
        Button('下一页').width(80).height(40).margin(2).backgroundColor(Color.Blue).fontColor('#FFFFFF')
        Button('尾页').width(80).height(40).margin(2).backgroundColor(Color.Blue).fontColor('#FFFFFF')
      }
      .height('100%')
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  FilterSelect(label: string, value: string) {
    Row({ space: 4 }) {
      Text(label)
        .fontSize(14)
        .fontColor('#666666')

      Text(value + ' ▾')
        .fontSize(14)
        .fontColor('#333333')
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
        .backgroundColor('#FFFFFF')
        .border({ width: 1, color: '#CCCCCC' })
        .borderRadius(4)
    }
    .margin({ right: 12 })
  }
}