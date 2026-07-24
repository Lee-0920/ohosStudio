// 执行方法类，所有方法定义在此
import { taskpool } from '@kit.ArkTS';
import { Operator } from '../../../Flow/Operator';
import { liquidTypes } from '../../../Setting/LiquidType';
import { hilog } from "@kit.PerformanceAnalysisKit";
import { HardwareOperationParams } from "../../../Setting/Setting";
import {
  RollDirection, //泵接口枚举体导入
  ValveMap,   //阀类导入
} from 'communication'; //导入类型->结构体，枚举(结构体前必须加type，枚举体不需要加type)
import json from '@ohos.util.json';

@Concurrent
export async function hardwareOperation(params: HardwareOperationParams): Promise<void> {
  console.info(`${JSON.stringify(params)}`);
  const op = Operator.getInstance();
  switch (params.operationName) {
    case 'meterPump':
      if(params.status){
        op.IPeristalticPump.startPump(0, RollDirection.Drain, 999, 0.2);
        console.info('HardwareTestFunc', "启动泵");
      }else{
        op.IPeristalticPump.stopPump(0);
        console.info('HardwareTestFunc', "停止泵");
      }
      break;
    case 'sampleValve':
      if(params.status){
        const map = new ValveMap(liquidTypes.sample.valve);
        op.ISolenoidValve.setValveMap(map);
        console.info('HardwareTestFunc', "开启水样阀");
      }else{
        const map = new ValveMap(0);
        op.ISolenoidValve.setValveMap(map);
        console.info('HardwareTestFunc', "关闭水样阀");
      }
      break;
    case 'reagent1Valve':
      if(params.status){
        const map = new ValveMap(liquidTypes.reagent1.valve);
        op.ISolenoidValve.setValveMap(map);
        console.info('HardwareTestFunc', "开启试剂一阀");
      }else{
        const map = new ValveMap(0);
        op.ISolenoidValve.setValveMap(map);
        console.info('HardwareTestFunc', "关闭试剂一阀");
      }
      break;
    case 'reagent2Valve':
      if(params.status){
        const map = new ValveMap(liquidTypes.reagent2.valve);
        op.ISolenoidValve.setValveMap(map);
        console.info('HardwareTestFunc', "开启试剂二阀");
      }else{
        const map = new ValveMap(0);
        op.ISolenoidValve.setValveMap(map);
        console.info('HardwareTestFunc', "关闭试剂二阀");
      }
      break;
    case 'reagent3Valve':
      if(params.status){
        const map = new ValveMap(liquidTypes.reagent2.valve);
        op.ISolenoidValve.setValveMap(map);
        console.info('HardwareTestFunc', "开启试剂二阀");
      }else{
        const map = new ValveMap(0);
        op.ISolenoidValve.setValveMap(map);
        console.info('HardwareTestFunc', "关闭试剂二阀");
      }
      break;
    case 'standardValve':
      if(params.status){
        const map = new ValveMap(liquidTypes.standard.valve);
        op.ISolenoidValve.setValveMap(map);
        console.info('HardwareTestFunc', "开启量程校准液阀");
      }else{
        const map = new ValveMap(0);
        op.ISolenoidValve.setValveMap(map);
        console.info('HardwareTestFunc', "关闭量程校准液阀");
      }
      break;
    case 'blankValve':
      if(params.status){
        const map = new ValveMap(liquidTypes.blank.valve);
        op.ISolenoidValve.setValveMap(map);
        console.info('HardwareTestFunc', "开启零点校准液阀");
      }else{
        const map = new ValveMap(0);
        op.ISolenoidValve.setValveMap(map);
        console.info('HardwareTestFunc', "关闭零点校准液阀");
      }
      break;
    case 'rangeCheckValve':
      if(params.status){
        const map = new ValveMap(liquidTypes.rangeCheck.valve);
        op.ISolenoidValve.setValveMap(map);
        console.info('HardwareTestFunc', "开启跨度核查阀");
      }else{
        const map = new ValveMap(0);
        op.ISolenoidValve.setValveMap(map);
        console.info('HardwareTestFunc', "关闭跨度核查阀");
      }
      break;
    case 'zeroCheckValve':
      if(params.status){
        const map = new ValveMap(liquidTypes.zeroCheck.valve);
        op.ISolenoidValve.setValveMap(map);
        console.info('HardwareTestFunc', "开启零点核查阀");
      }else{
        const map = new ValveMap(0);
        op.ISolenoidValve.setValveMap(map);
        console.info('HardwareTestFunc', "关闭零点核查阀");
      }
      break;
    case 'digestionHeater':
      if(params.status){
        op.ITemperatureControl.startThermostat(0, 60, 1, 600);
        console.info('HardwareTestFunc', "开启消解-60℃");
      }else{
        op.ITemperatureControl.stopThermostat();
        console.info('HardwareTestFunc', "关闭消解");
      }
      break;
    case 'digestionFan':
      if(params.status){
        op.ITemperatureControl.digestionFanSetOutput(1);
        console.info('HardwareTestFunc', "开启消解风扇");
      }else{
        op.ITemperatureControl.digestionFanSetOutput(0);
        console.info('HardwareTestFunc', "关闭消解风扇");
      }
      break;
    case 'boxFan':
      if(params.status){
        op.ITemperatureControl.boxFanSetOutput(1);
        console.info('HardwareTestFunc', "开启机箱风扇");
      }else{
        op.ITemperatureControl.boxFanSetOutput(0);
        console.info('HardwareTestFunc', "关闭机箱风扇");
      }
      break;
    case 'meterLED1':
      if(params.status){
        op.IOpticalMeter.turnOnLED(0);
        console.info('HardwareTestFunc', "开启定量点1LED");
      }else{
        op.IOpticalMeter.turnOffLED(0);
        console.info('HardwareTestFunc', "关闭定量点1LED");
      }
      break;
    case 'meterLED2':
      if(params.status){
        op.IOpticalMeter.turnOnLED(1);
        console.info('HardwareTestFunc', "开启定量点2LED");
      }else{
        op.IOpticalMeter.turnOffLED(1);
        console.info('HardwareTestFunc', "关闭定量点2LED");
      }
      break;
    case 'measureLED':
      if(params.status){
        op.IOpticalAcquire.turnOnLED();
        console.info('HardwareTestFunc', "开启测量LED");
      }else{
        op.IOpticalAcquire.turnOffLED();
        console.info('HardwareTestFunc', "关闭测量LED");
      }
      break;
    default:
      console.info('HardwareTestFunc', "未知事件");
      break;
  }

}