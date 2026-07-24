@ComponentV2
export struct BottomBar {
  private FirstTextTimerController = new TextTimerController();
  private SecondTextTimerController = new TextTimerController();

  @Local currentTime: string = '';
  @Local currentTemperature: string = '0';
  @Local isCloudConnected: boolean = false;
  private timer: number = -1

  aboutToAppear() {
    // 初始化时立即执行一次
    this.updateTime();

    // 开启定时器，每秒更新一次
    this.timer = setInterval(() => {
      this.updateTime();
    }, 1000);
  }

  aboutToDisappear(): void {
    clearInterval(this.timer) // 清理计时器防止内存泄露
  }

  updateTime() {
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const day = String(now.getDate()).padStart(2, '0');
    const hours = String(now.getHours()).padStart(2, '0');
    const minutes = String(now.getMinutes()).padStart(2, '0');
    const seconds = String(now.getSeconds()).padStart(2, '0');

    this.currentTime = `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`;
    // 持续获取温度并更新
  }

  build() {
    Row() {
      Row({ space: 20 }) {
        Row() {
          Text('空闲')
            .fontSize(32)
            .margin({ right: 100 })
          TextTimer({ isCountDown: false, controller: this.FirstTextTimerController })
        }
        .justifyContent(FlexAlign.SpaceBetween)
        .backgroundColor('gray')


        Row() {
          Text('空闲')
            .fontSize(32)
            .margin({ right: 100 })
          TextTimer({ isCountDown: false, controller: this.SecondTextTimerController })
        }
        .justifyContent(FlexAlign.SpaceBetween)
        .backgroundColor('gray')


        Text(this.currentTemperature)
      }
      .margin({ left: 40 })

      Row({ space: 20 }) {
        Image(this.isCloudConnected ? $r('app.media.cloudConnected') : $r('app.media.cloudDisconnected'))
          .width(40)
          .height(40)
        Row() {
          Text('运行')
        }
        Row() {
          Text(this.currentTime)
        }
      }
      .margin({ right: 40 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .borderWidth(1)
    .borderColor('yellow')
  }
}