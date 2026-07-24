import { UiUtil } from 'base';
import { EdgeScrollBar } from './EdgeScrollBar';
import { GradientSideTabItem } from './GradientSideTabItem';

@Component
export struct GradientSideTabBar {
  @Prop tabs: string[] = [];
  @Prop selectedTab: string = '';
  @Prop viewportWidth: number = 1024;
  @Prop viewportHeight: number = 768;
  @Prop scaleFactor: number = 1.92;
  @State private scrollViewportHeight: number = 0;
  @State private scrollContentHeight: number = 0;
  @State private scrollOffset: number = 0;
  private tabScroller: Scroller = new Scroller();
  onTabChange: (tab: string) => void = (_tab: string) => {
  };

  private syncScrollOffset(): void {
    const offset = this.tabScroller.currentOffset();
    this.scrollOffset = UiUtil.lengthToNumber(offset.yOffset);
  }

  build() {
    Column() {
      Stack({ alignContent: Alignment.TopEnd }) {
        Scroll(this.tabScroller) {
          Column() {
            ForEach(this.tabs, (tab: string) => {
              GradientSideTabItem({
                label: tab,
                selected: this.selectedTab === tab,
                fontSizeValue: UiUtil.vh(2.2, 12, 18, this.viewportHeight, this.scaleFactor),
                itemBorderWidth: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor),
                itemBorderColor: '#DDDDDD',
                onAction: () => {
                  this.onTabChange(tab);
                }
              })
                .width('100%')
                .height(UiUtil.vh(6.2, 44, 58, this.viewportHeight, this.scaleFactor))
            }, (tab: string) => tab)
          }
          .width('100%')
          .constraintSize({ minHeight: '100%' })
          .justifyContent(FlexAlign.Start)
          .onAreaChange((_, value) => {
            this.scrollContentHeight = UiUtil.lengthToNumber(value.height);
            this.syncScrollOffset();
          })
        }
        .width('100%')
        .height('100%')
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Off)
        .onAreaChange((_, value) => {
          this.scrollViewportHeight = UiUtil.lengthToNumber(value.height);
          this.syncScrollOffset();
        })
        .onScroll((_xOffset: number, _yOffset: number) => {
          this.syncScrollOffset();
        })

        EdgeScrollBar({
          viewportLength: this.scrollViewportHeight,
          contentLength: this.scrollContentHeight,
          currentOffset: this.scrollOffset,
          widthValue: UiUtil.vw(0.16, 2, 3, this.viewportWidth, this.scaleFactor),
          minThumbLength: UiUtil.vh(3.2, 22, 36, this.viewportHeight, this.scaleFactor)
        })
      }
      .width('100%')
      .height('100%')
    }
    .width(UiUtil.vw(10.6, 82, 124, this.viewportWidth, this.scaleFactor))
    .height('100%')
    .backgroundColor('#FFFFFF')
    .padding({
      top: UiUtil.vh(0.8, 6, 10, this.viewportHeight, this.scaleFactor),
      bottom: UiUtil.vh(0.8, 6, 10, this.viewportHeight, this.scaleFactor)
    })
  }
}
