import { MeasurementSnapshot } from '../models/deviceTypes';
import { DeviceContext } from './devices/DeviceContext';

export class MeasurementService {
  static async readMeasurementSnapshot(): Promise<MeasurementSnapshot | null> {
    return DeviceContext.getDevice().readMeasurementSnapshot();
  }

  static async startMeasurement(): Promise<boolean> {
    return DeviceContext.getDevice().startMeasurement();
  }

  static async stopMeasurement(): Promise<boolean> {
    return DeviceContext.getDevice().stopMeasurement();
  }

  static async startCalibration(): Promise<boolean> {
    return DeviceContext.getDevice().startCalibration();
  }

  static async startCleaning(): Promise<boolean> {
    return DeviceContext.getDevice().startCleaning();
  }

  static async measureRangeCalibrationSolution(): Promise<boolean> {
    return DeviceContext.getDevice().measureRangeCalibrationSolution();
  }

  static async measureZeroCalibrationSolution(): Promise<boolean> {
    return DeviceContext.getDevice().measureZeroCalibrationSolution();
  }

  static async cleanQuantitativeTube(): Promise<boolean> {
    return DeviceContext.getDevice().cleanQuantitativeTube();
  }

  static async cleanDigestionChamber(): Promise<boolean> {
    return DeviceContext.getDevice().cleanDigestionChamber();
  }

  static async cleanAllPipelines(): Promise<boolean> {
    return DeviceContext.getDevice().cleanAllPipelines();
  }

  static async collectWaterSample(): Promise<boolean> {
    return DeviceContext.getDevice().collectWaterSample();
  }

  static async startQuantitativePumpCalibration(): Promise<boolean> {
    return DeviceContext.getDevice().startQuantitativePumpCalibration();
  }

  static async startZeroCalibration(): Promise<boolean> {
    return DeviceContext.getDevice().startZeroCalibration();
  }

  static async startSpanCalibration(): Promise<boolean> {
    return DeviceContext.getDevice().startSpanCalibration();
  }

  static async startZeroCheck(): Promise<boolean> {
    return DeviceContext.getDevice().startZeroCheck();
  }

  static async startSpanCheck(): Promise<boolean> {
    return DeviceContext.getDevice().startSpanCheck();
  }
}
