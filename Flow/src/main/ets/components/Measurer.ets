
import { hilog } from '@kit.PerformanceAnalysisKit'
import { Flow } from './Flow';

import { BaseController } from 'controllerplugin'
import { PT65DriveController } from "pt65drivecontrollerplugin";



export type MeasureType = 'Sample' | 'Blank' | 'Standard' | 'ZeroCheck' | 'RangeCheck' | 'QualityHandle' | 'Addstandard' | 'Parallel' | 'ExtAddstandard' | 'ExtParallel' | 'none';

// 建议单独定义类型
interface  MeasureResult {
  initReferenceAD: number;
  initMeasureAD: number;
  finalReferenceAD: number;
  finalMeasureAD: number;
  initThermostatTemp: number;
  initEnvironmentTemp: number;
  finalThermostatTemp: number;
  finalEnvironmentTemp: number;
};

// 先定义类型
interface ProcedureStep {
  action: string;
  execute: () => void;
}

export class Measurer {
  static instance: Measurer | null = null;
  flow: Flow | null;

  measureType: MeasureType = 'Sample';
  currentRange: number = 1;
  temperatureBeforeAddReagent2 = 0;
  NowVolume = 0;
  Rangent1AirVolume = 0;
  measureResult:MeasureResult = {
    initReferenceAD: 0,
    initMeasureAD: 0,
    finalReferenceAD: 0,
    finalMeasureAD: 0,
    initThermostatTemp: 0,
    initEnvironmentTemp: 0,
    finalThermostatTemp: 0,
    finalEnvironmentTemp: 0,
  };

  procedure: ProcedureStep[] = [];

  constructor() {
    this.flow = null;
    this.InitProcedure();

  }

  static getInstance(): Measurer {
    if (!Measurer.instance) {
      Measurer.instance = new Measurer();
    }
    return Measurer.instance;
  }

  InitProcedure(): void {
    this.procedure = [
      {
        action: 'a',
        execute: () => {
          const startTime = Date.now();
          /* ... 具体执行逻辑保持业务一致，这里略写为示意 ... */
          const controller = new BaseController();
          controller.GetIDeviceStatus();
          hilog.info(100,'Measurer', '测量前排液时间=%{public}d', Date.now() - startTime);
        }
      },
      {
        action: 'b',
        execute: () => {
          const startTime = Date.now();
          const DC = new PT65DriveController();
          DC.GetISolenoidValve().SetValveMap();
          DC.GetITemperatureControl().StartThermostat();
          DC.GetITemperatureControl().StopThermostat();
          hilog.info(100, 'Measurer', '测量前清洗时间=%{public}d', Date.now() - startTime);
        }
      },
      {
        action: 'c',
        execute: () => {
          const startTime = Date.now();
          hilog.info(100, 'Measurer', '润洗时间=%{public}d', Date.now() - startTime);
        }
      }
    ];
  }

  Reset(): void {
    this.flow = null;
    this.measureType = 'Sample';
    this.currentRange = 1;
    //this.addParam = {};
    this.NowVolume = 0;
  }

  GetRinseVol(): number {
    return 0;
  }

  Measure(): void {
    if (!this.flow) {
      hilog.info(100, 'Measurer', 'Measurer.Measure: flow is null');
    }
    for (const step of this.procedure) {
      hilog.info(100, 'Measurer','action: %{public}s', step.action);
      if (step.execute) {
        step.execute();
      }
    }
  }

  CheckExecuteTime(label: string, elapsedSec: number, force: boolean, value?: number): void {
    // placeholder
    // console.debug(`CheckExecuteTime ${label} ${elapsedSec}`);
  }
}