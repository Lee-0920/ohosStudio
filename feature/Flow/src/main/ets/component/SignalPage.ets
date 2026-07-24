import { WorkerManager } from '../workers/WorkerManager';
import { MessageEvents } from '@kit.ArkTS';

@ComponentV2
export struct SignalPage {
  @Local message: string = 'click: 0';
  private time: number = 0;
  @Param currentIndex: number = 0;
  @Param page: string = '0';
  build() {
    Column() {
      Text(this.message)
        .onClick(() => {
          this.message = 'click: ' + ++this.time;
          WorkerManager.getInstance().onmessage('测试内容', (event: MessageEvents) => {
            console.info(`TLQQ, UI线程: 收到了worker线程发送的内容: ${JSON.stringify(event)}`);
          });
          console.info(`TLQQ, UI线程：发送消息启动worker线程`);
          // WorkerManager.getInstance().postMessage({
          //   type: 'schedule',
          //   data: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23],
          //   timeStamp: Date.now()
          // })

          WorkerManager.getInstance().postMessage({
            type: 'start',
            data: {
              times: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23]
            },
            timeStamp: Date.now()
          })
        })
    }
  }
}