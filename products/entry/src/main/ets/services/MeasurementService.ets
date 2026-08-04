import { MeasurementSnapshot } from '../models/deviceTypes';
import { DeviceContext } from './devices/DeviceContext';
import { MaintenceType, WorkerManager, MaintainOperationParams, MeasureType, CalibrateType, CleanType } from 'flow';

export class MeasurementService {
  static async readMeasurementSnapshot(): Promise<MeasurementSnapshot | null> {
    return DeviceContext.getDevice().readMeasurementSnapshot();
  }

  static async startMeasurement(): Promise<boolean> {
    //启动测零点校准液
    WorkerManager.getInstance().postMessage({
      type: 'startMeasure',
      data: {
        maintenceTypes: MaintenceType.AutoMeasure,
        params: MeasureType.Sample,
        runTimes: 1
      },
      timeStamp: Date.now()
    });
    return true;
    // return DeviceContext.getDevice().startMeasurement();
  }

  static async stopMeasurement(): Promise<boolean> {
    // return DeviceContext.getDevice().stopMeasurement();
    WorkerManager.getInstance().postMessage({
      type: 'stop',
      data: 0,
      timeStamp: Date.now()
    });
    return true;
  }

  static async startCalibration(): Promise<boolean> {
    WorkerManager.getInstance().postMessage({
      type: 'startCalibrate',
      data: {
        maintenceTypes: MaintenceType.AutoCalibrate,
        params: CalibrateType.calibrate,
        runTimes: 1
      },
      timeStamp: Date.now()
    });
    return true;
    // return DeviceContext.getDevice().startCalibration();
  }

  static async startCleaning(): Promise<boolean> {
    //启动深度清洗
    WorkerManager.getInstance().postMessage({
      type: 'startClean',
      data: {
        maintenceTypes: MaintenceType.AutoClean,
        params: CleanType.cleanDeeply,
        runTimes: 1
      },
      timeStamp: Date.now()
    });
    return true;
    // return DeviceContext.getDevice().startCleaning();
  }

  static async measureRangeCalibrationSolution(): Promise<boolean> {
    //启动测量程校准液
    WorkerManager.getInstance().postMessage({
      type: 'startMeasure',
      data: {
        maintenceTypes: MaintenceType.AutoMeasure,
        params: MeasureType.Standard,
        runTimes: 1
      },
      timeStamp: Date.now()
    });
    return true;
    // return DeviceContext.getDevice().measureRangeCalibrationSolution();
  }

  static async measureZeroCalibrationSolution(): Promise<boolean> {
    //启动测零点校准液
    WorkerManager.getInstance().postMessage({
      type: 'startMeasure',
      data: {
        maintenceTypes: MaintenceType.AutoMeasure,
        params: MeasureType.Blank,
        runTimes: 1
      },
      timeStamp: Date.now()
    });
    return true;
    // return DeviceContext.getDevice().measureZeroCalibrationSolution();
  }

  static async cleanQuantitativeTube(): Promise<boolean> {
    //启动清洗定量管
    WorkerManager.getInstance().postMessage({
      type: 'startClean',
      data: {
        maintenceTypes: MaintenceType.AutoClean,
        params: CleanType.cleanMeterPipe,
        runTimes: 1
      },
      timeStamp: Date.now()
    });
    return true;
    // return DeviceContext.getDevice().cleanQuantitativeTube();
  }

  static async cleanDigestionChamber(): Promise<boolean> {
    //启动清洗消解室
    WorkerManager.getInstance().postMessage({
      type: 'startClean',
      data: {
        maintenceTypes: MaintenceType.AutoClean,
        params: CleanType.cleanDigestionRoom,
        runTimes: 1
      },
      timeStamp: Date.now()
    });
    return true;
    // return DeviceContext.getDevice().cleanDigestionChamber();
  }

  static async cleanAllPipelines(): Promise<boolean> {
    //启动清洗所有管路
    WorkerManager.getInstance().postMessage({
      type: 'startClean',
      data: {
        maintenceTypes: MaintenceType.AutoClean,
        params: CleanType.cleanAll,
        runTimes: 1
      },
      timeStamp: Date.now()
    });
    return true;
    // return DeviceContext.getDevice().cleanAllPipelines();
  }

  static async collectWaterSample(): Promise<boolean> {
    //启动采集水样
    WorkerManager.getInstance().postMessage({
      type: 'startCollectSample',
      data: 0,
      timeStamp: Date.now()
    });
    return true;
    // return DeviceContext.getDevice().collectWaterSample();
  }

  static async startQuantitativePumpCalibration(): Promise<boolean> {
    //启动定量泵自动校准
    WorkerManager.getInstance().postMessage({
      type: 'startPumpCalibrate',
      data: 0,
      timeStamp: Date.now()
    });
    return true;
    // return DeviceContext.getDevice().startQuantitativePumpCalibration();
  }

  static async startZeroCalibration(): Promise<boolean> {
    //启动零点校准
    WorkerManager.getInstance().postMessage({
      type: 'startCalibrate',
      data: {
        maintenceTypes: MaintenceType.AutoCalibrate,
        params: CalibrateType.onlyCalibrateBlank,
        runTimes: 1
      },
      timeStamp: Date.now()
    });
    return true;
    // return DeviceContext.getDevice().startZeroCalibration();
  }

  static async startSpanCalibration(): Promise<boolean> {
    //启动量程校准
    WorkerManager.getInstance().postMessage({
      type: 'startCalibrate',
      data: {
        maintenceTypes: MaintenceType.AutoCalibrate,
        params: CalibrateType.onlyCalibrateStandard,
        runTimes: 1
      },
      timeStamp: Date.now()
    });
    return true;
    // return DeviceContext.getDevice().startSpanCalibration();
  }

  static async startZeroCheck(): Promise<boolean> {
    //启动测零点核查液
    WorkerManager.getInstance().postMessage({
      type: 'startMeasure',
      data: {
        maintenceTypes: MaintenceType.AutoMeasure,
        params: MeasureType.ZeroCheck,
        runTimes: 1
      },
      timeStamp: Date.now()
    });
    return true;
    // return DeviceContext.getDevice().startZeroCheck();
  }

  static async startSpanCheck(): Promise<boolean> {
    //启动测标样(跨度)核查
    WorkerManager.getInstance().postMessage({
      type: 'startMeasure',
      data: {
        maintenceTypes: MaintenceType.AutoMeasure,
        params: MeasureType.RangeCheck,
        runTimes: 1
      },
      timeStamp: Date.now()
    });
    return true;
    // return DeviceContext.getDevice().startSpanCheck();
  }
}
