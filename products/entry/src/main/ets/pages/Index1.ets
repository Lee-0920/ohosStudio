import { MeasureType, FlowManager, FlowTask, CalibrateType, FlowType} from "flow";
import { BusinessError, emitter, Callback } from '@kit.BasicServicesKit';

import { common } from '@kit.AbilityKit';
// 1. 定义数据结构接口
interface EvenDataStatus {
  action: string;
  time: number;
}

interface StatusData {
  data: EvenDataStatus;
}

interface ButtonItem {
  text: string;
  action: () => void;
}

@Entry
@Component
struct Index1 {
  @State message: string = 'Hello World';
  @State measureStatus: string = '就绪';
  @State Mode:number = 0;

  @Builder
  buildSection(title: string, buttons: Array<ButtonItem>) {
    Column() {
      Text(title).fontSize(18).fontWeight(FontWeight.Medium).margin({ top: 16, bottom: 8 }).alignSelf(ItemAlign.Start)
      Column() {
        ForEach(buttons, (btn: ButtonItem, index: number) => {
          Button(btn.text).width('80%').margin({ bottom: 8 }).onClick(() => {
            btn.action();
          })
        }, (btn: ButtonItem, index: number) => index.toString())
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
  }

  private BackUI(): void {
    // 获取UIContext
    let uiContext: UIContext = this.getUIContext();
    let router = uiContext.getRouter();
    try {
      // 返回第一页
      router.back()
      console.info('Succeeded in returning to the first page.')
    } catch (err) {
      let code = (err as BusinessError).code;
      let message = (err as BusinessError).message;
      console.error(`Failed to return to the first page. Code is ${code}, message is ${message}`)
    }
  }

  private sampleMeasure(): void {
      FlowTask.GetInstance().runFlow('Sample', FlowType.Measure, MeasureType.Sample, this.getUIContext().getHostContext() as common.UIAbilityContext);
  }

  private cali(): void {
    // FlowManager.startCalibrateFlow('cali', CalibrateType.calibrate);
    FlowManager.startFlow('cali', FlowType.Calibrate, CalibrateType.calibrate);
  }

  private emitterOn(): void {
    // 定义一个事件的回调处理函数，当收到对应的事件后执行回调函数
    let callback: Callback<emitter.EventData> = (eventData: emitter.EventData) => {
      let str = JSON.stringify(eventData);
      let statusData:StatusData = JSON.parse(str) as StatusData;
      this.measureStatus = statusData.data.action + statusData.data.time.toString();
      //console.info(`eventData: ${JSON.stringify(eventData)}`);
    }
    // 收到eventId为"MeasureStatus"的事件后执行回调函数
    emitter.on("MeasureStatus", callback);
  }

  private stopFlow(): void {
    //FlowTask.GetInstance().stopFlow();
    FlowManager.stopFlow()
  }

  private schedule(): void {
    FlowManager.Scheduler();
  }

  private DBConfig(): void {
    FlowManager.DBConfig( this.getUIContext().getHostContext() as common.UIAbilityContext );
  }

  build() {
    Row() {
      Column() {
        Button("返回").fontSize(16)
          .margin({ top: 20, bottom: 10 }).width('30%')
          .alignSelf(ItemAlign.Start)
          .onClick(()=>{
            this.BackUI();
          })

        Text('流程类测试')
          .fontSize(24).fontWeight(FontWeight.Bold).margin({ top: 10, bottom: 10 })

        this.buildSection('流程和排期测试', [
          { text: '测量水样', action: () => { this.sampleMeasure(); } },
          { text: '校准', action: () => { this.cali(); } },
          { text: '排期', action: () => { this.schedule(); } },
          { text: '停止', action: () => { this.stopFlow(); } },
          { text: '订阅事件', action: () => { this.emitterOn(); } },
          { text: '初始化数据库', action: () => { this.DBConfig(); } },
        ])

        TextInput({placeholder:'校准模式'}).type(InputType.Number).margin({ bottom: 10 })
          .onChange((value:string)=>{
            this.Mode =  parseInt(value);
          })

        Text(`当前状态: ${this.measureStatus}`)
          .fontSize(20)
          .margin({ bottom: 10 })
          .fontColor('#FF6B6B')
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
    }
    .height('100%')
    .width('100%')
  }
}