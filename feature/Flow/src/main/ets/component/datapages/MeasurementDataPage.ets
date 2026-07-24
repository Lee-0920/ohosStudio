@ComponentV2
export struct MeasurementDataPage {
  private columns: string[] = ['时间', '结果', '吸光度', '标识', '类型', '量程'];
  @Local startDate: string = '2023-07-13'
  @Local endDate:   string = '2023-07-20'
  @Local selFlag:   string = '全部'
  @Local selType:   string = '全部'

  private data: Array<Array<string>> = [
    ['2023-07-20 14:11', '45.5',  '45.50',  '正常N', '水样', '100.0'],
    ['2023-07-20 11:56', '12.3',  '12.30',  '正常N', '水样', '100.0'],
    ['2023-07-20 11:56', '88.9',  '88.90',  '超量程T', '水样', '100.0'],
    ['2023-07-20 11:56', '33.1',  '33.10',  '正常N', '水样', '100.0'],
    ['2023-07-19 09:20', '67.4',  '67.40',  '正常N', '水样', '100.0'],
    ['2023-07-18 16:05', '91.0',  '91.00',  '超量程T', '水样', '100.0'],
    ['2023-07-15 10:30', '5.6',   '5.60',   '正常N', '水样', '100.0'],
    ['2023-07-13 08:15', '72.2',  '72.20',  '正常N', '水样', '100.0'],
  ]

  build() {
    Row() {
      Column() {
        // ==================== 表格区域 ====================
        // ---- 表头 ----
        Row() {
          ForEach(this.columns, (col: string) => {
            Text(col)
              .fontSize(16)
              .fontColor('#333333')
              .fontWeight(FontWeight.Medium)
              .textAlign(TextAlign.Center)
              .layoutWeight(1)
          }, (col: string) => col)
        }
        .width('100%')
        .height(44)
        .backgroundColor('#F5F5F5')
        .border({ width: { bottom: 1 }, color: '#E0E0E0' })

        // ---- 表体 ----
        List() {
          ForEach(this.data, (row: string[], rowIdx: number) => {
            ListItem() {
              Row() {
                ForEach(row, (cell: string, colIdx: number) => {
                  Text(cell)
                    .fontSize(14)
                    .fontColor(
                      colIdx === 3 && cell === '超量程T'
                        ? '#FF5722'    // 超量程标红
                        : '#333333'
                    )
                    .textAlign(TextAlign.Center)
                    .layoutWeight(1)
                }, (cell: string, idx: number) => idx.toString())
              }
              .width('100%')
              .height(42)
              .backgroundColor(rowIdx % 2 === 0 ? '#FAFAFA' : '#FFFFFF')
              .border({ width: { bottom: 1 }, color: '#EEEEEE' })
            }
          }, (row: string[], idx: number) => idx.toString())
        }
        .width('100%')
        // .layoutWeight(1)
        .enabled(false)

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
          this.FilterSelect('标识', this.selFlag)
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
      .layoutWeight(1)


      Column() {
        Button('首页').width(80).height(40).margin(2).backgroundColor(Color.Blue).fontColor('#FFFFFF')
        Button('上一页').width(80).height(40).margin(2).backgroundColor(Color.Blue).fontColor('#FFFFFF')
        Button('下一页').width(80).height(40).margin(2).backgroundColor(Color.Blue).fontColor('#FFFFFF')
        Button('尾页').width(80).height(40).margin(2).backgroundColor(Color.Blue).fontColor('#FFFFFF')
        Button('导出').width(80).height(40).margin(2).backgroundColor(Color.Blue).fontColor('#FFFFFF')
      }
      .height('100%')
      .borderWidth(1)
      .borderColor('black')
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.End)

    }
    .width('100%')
    .height('100%')
    .borderWidth(1)
    .borderColor('black')
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