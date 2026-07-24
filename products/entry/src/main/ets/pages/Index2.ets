import { FlowPage } from 'flow';
import { BottomBar } from 'flow/src/main/ets/pages/BottomPage';
import { TabPage } from 'flow/src/main/ets/pages/TabPage';

// import { dncp, pump, valve, temp, meter, optical } from 'communication'; //导入模块
// import type { Meter, Valve, Pump, Temp, Optical } from 'communication'; // 或分别从各文件 import type
// import {
//   type MotionParam, type PumpResult,            //泵接口结构体导入
//   PumpStatus, RollDirection, PumpOperateResult, //泵接口枚举体导入
//   type Temperature, type ThermostatParam, type TempCalibrateFactor, type ThermostatResult, //温度接口结构体导入
//   ThermostatMode, ThermostatOperateResult,                                                 //温度枚举体导入
//   ValveMap,   //阀类导入
//   MeterPoints,            //定量类导入
//   type MeterPoint,        //定量结构体导入
//   MeterMode, MeterResult, //定量枚举体导入
//   type OpticalAD, type AcquiredResult, type LedParam, type RefADParam, //光学结构体导入
//   AcquiredOperateResult, StaticADControlResult, AdjustResult,          //光学枚举体导入
// } from 'communication'; //导入类型->结构体，枚举(结构体前必须加type，枚举体不需要加type)

@Entry
@ComponentV2
struct index2 {
  @Local currentPage: number = 0;

  aboutToAppear() {
    // console.info('entry', 'TEST START');
    // //DNCP初始化
    // dncp.createPlugin();
    // dncp.addSlaveNode(1);
    // dncp.initDncpStack("/dev/ttyS0",false,"");
    //
    // // //事件注册示例
    // // console.log('Received PT63 setOnPT63EventCallback:');
    // // event.setOnPT63EventCallback((eventPack) =>
    // // {
    // //   switch (eventPack.type) {
    // //     case 'TEMPERATURE':
    // //       // ✅ 在这个 case 分支内，编译器知道 'event' 是 TemperatureEvent 类型
    // //       console.log(`TEMPERATURE : ${eventPack.thermostatTemp}°C, ${eventPack.environmentTemp}°C`);
    // //       break;
    // //
    // //     case 'OPTICAL':
    // //       console.log(`OPTICAL: ${eventPack.reference}, ${eventPack.measure}`);
    // //       break;
    // //
    // //     case 'METER':
    // //       console.log(`METER ${eventPack.point1}, ${eventPack.point2}`);
    // //       break;
    // //
    // //     default:
    // //     // 可选：处理未知类型
    // //     // 此时 'event' 的类型会被收窄为 'never'
    // //       console.warn('Unhandled event type:');
    // //   }
    // // });
    //
    // //泵控制控制示例
    // console.log(`pump start`);
    // dncp.doProxy();
    // pump.startPump(0, RollDirection.Suck, 0.5, 0.2);
    // // console.log(`pump end`);
    // // communication.dncp.doProxy();
    // // let num: number = pump.getTotalPumps();
    // // console.log(`pump getTotalPumps ${num}`);
    // // pump.setPumpFactor(0, 0.00058);
    // // dncp.doProxy();
    // // let pumpStatus: PumpStatus = pump.getPumpStatus(0);
    // // console.log(`pump getPumpStatus ${pumpStatus}`);
    // // let factor: number = pump.getPumpFactor(0);
    // // console.log(`pump getPumpFactor ${factor}`);
    // // const param: MotionParam = {
    // //   acceleration: 0.2,
    // //   speed: 0.5
    // // }
    // // communication.pump.setMotionParam(0, param);
    // // communication.dncp.doProxy();
    // // let motionParam: MotionParam = communication.pump.getMotionParam(0);
    // // console.log(`pump getMotionParam ${motionParam.acceleration} ${motionParam.speed}`);
    // console.log(`pump expect`);
    // let pumpResult: PumpResult = pump.expectPumpResult(3000);
    // console.log(`pump expectPumpResult ${pumpResult.result}`);
    // if(pumpResult.result == PumpOperateResult.Finished)
    // {
    //   console.log(`pumpResult##: ${pumpResult.index}, ${pumpResult.result}`);
    // }
    // else {
    //   console.log(`pumpResult@@: ${pumpResult.index}, ${pumpResult.result}`);
    // }



    // //阀控制示例
    // // //构造参数对象
    // const map = new ValveMap(1);
    // communication.valve.setValveMap(map);
    // communication.dncp.doProxy();
    // //1号阀顺时针转到2号阀
    // map.setData(2);
    // map.setSpinValveCmd(0xA4, 2, 3);
    // communication.valve.ctrlSpinValve(map);


    //温度控制示例
    // communication.temp.startThermostat(ThermostatMode.Heater, 25.0, 1.0, 600);
    // let result:ThermostatResult = communication.temp.expectThermostat(3000);
    // console.log(`temp expectThermostat ${result.temp} ${result.result}`);
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
    // communication.optical.startAcquirer(2);
    // let result: AcquiredResult = communication.optical.expectADAcquirer(3000);
    // console.log(`optical expectADAcquirer ${result.ad.reference} ${result.ad.measure}`);
    // //构造参数对象
    // const param: LedParam = {
    //   proportion: 1.2,
    //   integration: 80,
    //   differential: 91
    // }
    // communication.optical.setLEDControllerParam(param);

  }

  build() {
    Column() {
      TabPage({
        currentPage: this.currentPage,
        changePage: (currentPage: number) => {
          this.currentPage = currentPage;
        }
      })
        .height('25%')

      FlowPage({ currentPage: this.currentPage })
        .height('60%')

      Divider()

      BottomBar()
        .height('15%')
    }
    .width('100%')
    .height('100%')
  }
}