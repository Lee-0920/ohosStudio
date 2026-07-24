import { DataPage } from '../component/DataPage';
import { MainPage } from '../component/MainPage';
import { OperationPage } from '../component/OperationPage';
import { SetPage } from '../component/SetPage';
import { SignalPage } from '../component/SignalPage';
import { SystemPage } from '../component/SystemPage';
import { UserPage } from '../component/UserPage';

@ComponentV2
export struct FlowPage {
  @Param currentPage: number = 0;
  build() {
    Column() {
      Tabs({ index: this.currentPage }) {
        TabContent() { MainPage() }.tabIndex(0)
        TabContent() { DataPage() }.tabIndex(1)
        TabContent() { SignalPage() }.tabIndex(2)
        TabContent() { SetPage() }.tabIndex(3)
        TabContent() { OperationPage() }.tabIndex(4)
        TabContent() { SystemPage() }.tabIndex(5)
        TabContent() { UserPage() }.tabIndex(6)
      }
      .barHeight(0)      // ← 关键：把系统 TabBar 高度设为 0
      .scrollable(false)
    }
    .width('100%')
    .height('100%')
    .borderWidth(1)
    .borderColor('red')
  }
}