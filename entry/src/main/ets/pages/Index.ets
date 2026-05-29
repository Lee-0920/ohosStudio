import { hilog }  from '@kit.PerformanceAnalysisKit'
import { FlowList, MeasureFlow, MeasureType, CalibrateFlow } from "flow";
import { core } from 'core';
import { communication  } from 'communication'; //导入模块
import {
  type MotionParam, type PumpResult,            //泵接口结构体导入
  PumpStatus, RollDirection, PumpOperateResult, //泵接口枚举体导入
  type Temperature, type ThermostatParam, type TempCalibrateFactor, type ThermostatResult, //温度接口结构体导入
  ThermostatMode, ThermostatOperateResult,                                                 //温度枚举体导入
  ValveMap,   //阀类导入
  MeterPoints,            //定量类导入
  type MeterPoint,        //定量结构体导入
  MeterMode, MeterResult, //定量枚举体导入
  type OpticalAD, type AcquiredResult, type LedParam, type RefADParam, //光学结构体导入
  AcquiredOperateResult, StaticADControlResult, AdjustResult,          //光学枚举体导入
} from 'libcommunication.so'; //导入类型->结构体，枚举(结构体前必须加type，枚举体不需要加type)

@Entry
@Component
struct Index {
  @State message: string = 'Hello World';
  aboutToAppear() {
    hilog.info(1, 'entry', 'TEST START');
    //DNCP初始化
    communication.dncp.createPlugin();
    communication.dncp.addSlaveNode(1);
    communication.dncp.initDncpStack("/dev/ttyS0",false,"");

    //泵控制控制示例
    // communication.pump.startPump(0, RollDirection.Suck, 1, 0.2);

    //阀控制示例
    // //构造参数对象
    // const param: MotionParam = {
    //   acceleration: 3.5, // ml/s²
    //   speed: 12.0        // ml/s
    // };
    // communication.pump.setMotionParam(0, param);
    // const map = new ValveMap(0x123);
    // map.setSpinValveCmd(1,2,3);
    // communication.valve.ctrlSpinValve(map);

    //温度控制示例
    // communication.temp.startThermostat(ThermostatMode.Auto, 25.0, 1.0, 600);
    // //构造参数对象
    // const param: TempCalibrateFactor = {
    //   negativeInput: 1.24,           ///<负输入分压
    //   referenceVoltage: 2.49,        ///<参考电压
    //   calibrationVoltage: 0     ///<校准电压
    // };
    // communication.temp.setCalibrateFactor(param);

    //定量接口示例
    // //构造参数对象
    // const param: MeterPoint = {
    //   setVolume: 0.5,
    //   realVolume: 0.5
    // };
    // const mp = new MeterPoints(2);
    // mp.setPoint(0, param);
    // communication.meter.turnOnLED(1);

    //光学接口示例
    // communication.optical.startAcquirer(60); setLEDControllerParam
    // //构造参数对象
    // const param: LedParam = {
    //   proportion: 1.2,
    //   integration: 80,
    //   differential: 91
    // }
    // communication.optical.setLEDControllerParam(param);

    //事件注册示例
    // const eventPack: EventPack = {
    //   code: 0
    // }
    console.log('Received PT63 setOnPT63EventCallback:');
    communication.event.setOnPT63EventCallback((eventPack) =>
    {
      console.log('Received PT63 event:');
      switch (eventPack.type) {
        case 'TEMPERATURE':
          // ✅ 在这个 case 分支内，编译器知道 'event' 是 TemperatureEvent 类型
          // 您可以安全地访问 currentTemp, targetTemp, status
          console.log(`TEMPERATURE : ${eventPack.environmentTemp}°C`);
          break;

        case 'OPTICAL':
          console.log(`OPTICAL: ${eventPack.reference}`);
          break;

        case 'METER':
          console.log(`METER ${eventPack.point1} `);
          break;

        default:
        // 可选：处理未知类型
        // 此时 'event' 的类型会被收窄为 'never'
          console.warn('Unhandled event type:');
      }
    });

  }
  build() {
    Row() {
      Column(){
        Text(this.message)
          .id('HelloWorld')
          .fontSize($r('app.float.page_text_font_size'))
          .fontWeight(FontWeight.Bold)
          .alignRules({
            center: { anchor: '__container__', align: VerticalAlign.Center },
            middle: { anchor: '__container__', align: HorizontalAlign.Center }
          })
          .onClick(() => {
            if (this.message === 'Welcome') {
              this.message = 'Hello World';
            } else {
              this.message = 'Welcome';
            }
            hilog.info(1, 'entry', 'Text.onClick: Add:%{public}d',  core.add(2,3));
            hilog.info(1, 'entry', 'Text.onClick:%{public}s', this.message);
          })
        Button() {
          Text("测量水样")
            .fontSize(30)
            .fontWeight(FontWeight.Bold)
        }
        .type(ButtonType.Capsule)
        .margin({
          top: 20
        })
        .backgroundColor('#0D9FFB')
        .width('40%')
        .height('5%')
        .onClick(() => {
            let flow = new MeasureFlow('sample', 'Sample');
            FlowList.AddFlow(flow);
            FlowList.RunAllFlow();
            //core.runFlow(1,2);
        })
        Button() {
          Text("校准")
            .fontSize(30)
            .fontWeight(FontWeight.Bold)
        }
        .type(ButtonType.Capsule)
        .margin({
          top: 40
        })
        .backgroundColor('#0D9FFB')
        .width('40%')
        .height('5%')
        .onClick(() => {
          let flow =  new CalibrateFlow('cali', 'calibrate');
          FlowList.AddFlow(flow);
          FlowList.RunAllFlow();
          //core.runFlow(1,2);
        })
      }
      .width('100%')
    }
    .height('100%')
    .width('100%')
  }
}