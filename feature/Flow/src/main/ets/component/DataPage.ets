import { AlarmManagementPage } from "./datapages/AlarmManagementPage";
import { CalibrationCurvePage } from "./datapages/CalibrationCurvePage";
import { HistoricalTrendsPage } from "./datapages/HistoricalTrendsPage";
import { MeasurementDataPage } from "./datapages/MeasurementDataPage";
import { OperationLogPage } from "./datapages/OperationLogPage";

@ComponentV2
export struct DataPage {
  private leftMenus: string[] = ['测量数据', '历史趋势', '校准曲线', '告警管理', '运行日志'];
  private rightMenus: string[] = ['首页', '上一页', '下一页', '尾页', '导出'];
  @Local currentIndex: number = 0;

  build() {
    Row() {
      Column() {
        ForEach(this.leftMenus, (item: string, index) => {
          Text(item)
            .fontSize(16)
            .fontColor(Color.Black)
            .fontWeight(index === 0 ? FontWeight.Medium : FontWeight.Regular) // 第一个选中加粗
            .padding({ left: 20, right: 20, top: 12, bottom: 12 })
            .onClick(() => {
              this.currentIndex = index;
            })
          Divider()
        }, (item: string) => item)
      }
      .layoutWeight(1)
      .height('100%')
      .borderWidth(1)
      .borderColor('red')

      Column() {
        Tabs({ index: this.currentIndex}) {
          TabContent() { MeasurementDataPage() }.tabIndex(0)
          TabContent() { HistoricalTrendsPage() }.tabIndex(1)
          TabContent() { CalibrationCurvePage() }.tabIndex(2)
          TabContent() { AlarmManagementPage() }.tabIndex(3)
          TabContent() { OperationLogPage() }.tabIndex(4)
        }.barHeight(0).scrollable(false)
      }
      .layoutWeight(6)
      .height('100%')
      .borderWidth(1)
      .borderColor('red')
    }
    .width('100%')
    .height('100%')
    .padding({ top: 50, bottom: 50 })
    .borderWidth(1)
    .borderColor('red')
  }
}