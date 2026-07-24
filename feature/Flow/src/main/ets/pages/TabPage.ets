import { ToolBarModel } from '../model/ToolBarModel';

@ComponentV2
export struct TabPage {
  private toolItem: ToolBarModel[] = [
    { name: '主界面', icon: $r('app.media.home'), page: '1' },
    { name: '数据', icon: $r('app.media.data'), page: '2' },
    { name: '信号', icon: $r('app.media.signal'), page: '3' },
    { name: '设置', icon: $r('app.media.setting'), page: '4' },
    { name: '运维', icon: $r('app.media.mainTain'), page: '5' },
    { name: '系统', icon: $r('app.media.information'), page: '6' }]

  @Param currentPage: number = 0;
  @Event changePage: (currentPage: number) => void = () => {}
  @Local fontColor: string = '#182431';
  @Local selectedFontColor: string = '#007DFF';

  aboutToAppear(): void {

  }

  build() {
    Row() {
      Row() {
        ForEach(this.toolItem, (item: ToolBarModel, index: number) => {
          Column() {
            Image(item.icon)
              .width(88)
              .height(88)

            Text(item.name)
              .fontColor(this.currentPage === index ? this.selectedFontColor : this.fontColor)
              .fontSize(32)
              .fontWeight(this.currentPage === index ? 500 : 400)
              .lineHeight(22)
              .margin({ top: 17, bottom: 7 })
          }
          .margin({
            left: 40,
            right: 40
          })
          .onClick(() => {
            this.changePage(index);
          })
        }, (item: ToolBarModel, index: number) => {
          return JSON.stringify(item);
        })
      }
      .height('100%')
      .borderWidth(1)
      .borderColor('red')

      Row() {
        Column() {
          Image($r('app.media.generalUser'))
            .width(88)
            .height(88)

          Text('用户')
            .fontColor(this.currentPage === this.toolItem.length ? this.selectedFontColor : this.fontColor)
            .fontSize(32)
            .fontWeight(this.currentPage === this.toolItem.length ? 500 : 400)
            .lineHeight(22)
            .margin({ top: 17, bottom: 7 })
        }

      }
      .height('100%')
      .borderWidth(1)
      .borderColor('red')
      .margin({
        left: 40,
        right: 40
      })
      .onClick(() => {
        this.changePage(this.toolItem.length);
      })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .borderWidth(1)
    .borderColor('red')
  }
}