import { hilog } from "@kit.PerformanceAnalysisKit";
import { liquidTypes, LiquidType } from '../Setting/LiquidType';
import { remainConfig } from '../Config/RemainConfig';
import { RemainConfig, RemainItem } from 'dataservice';
import { remainStatus } from '../Config/RemainStatus';
import { systemConfig } from '../Config/SystemConfig';

interface ReagentStatus {
  isEnough: boolean;
  isBad: boolean;
}

interface CheckList {
  reagent: LiquidType;
  status: ReagentStatus;
}

interface RemainCheckList {
  name: string;
  reagent: LiquidType;
  status: ReagentStatus;
}

export class ReagentRemainManager {
  private static instance: ReagentRemainManager | null = null;

  private readonly REMAIN: number = 20.000000;
  private readonly PRECISE: number = 0.000001;

  // Reagent status flags
  private isBlankEnough: boolean = true;
  private isStandardEnough: boolean = true;
  private isZeroCheckEnough: boolean = true;
  private isRangeCheckEnough: boolean = true;
  private isWasteEnough: boolean = true;
  private isWasteWaterEnough: boolean = true;
  private isReagent1Enough: boolean = true;
  private isReagent2Enough: boolean = true;

  private isBlankBad: boolean = false;
  private isStandardBad: boolean = false;
  private isZeroCheckBad: boolean = false;
  private isRangeCheckBad: boolean = false;
  private isWasteBad: boolean = false;
  private isWasteWaterBad: boolean = false;
  private isReagent1Bad: boolean = false;
  private isReagent2Bad: boolean = false;

  private constructor() {}

  static getInstance(): ReagentRemainManager {
    if (!ReagentRemainManager.instance) {
      ReagentRemainManager.instance = new ReagentRemainManager();
    }
    return ReagentRemainManager.instance;
  }

  private updateReagentStatus(liquidType: string, isEnough: boolean, isBad: boolean): void {
    switch (liquidType) {
      case 'Blank':
      case 'blank':
        this.isBlankEnough = isEnough;
        this.isBlankBad = isBad;
        break;
      case 'Standard':
      case 'standard':
        this.isStandardEnough = isEnough;
        this.isStandardBad = isBad;
        break;
      case 'ZeroCheck':
      case 'zeroCheck':
        this.isZeroCheckEnough = isEnough;
        this.isZeroCheckBad = isBad;
        break;
      case 'RangeCheck':
      case 'rangeCheck':
        this.isRangeCheckEnough = isEnough;
        this.isRangeCheckBad = isBad;
        break;
      case 'Waste':
      case 'waste':
        this.isWasteEnough = isEnough;
        this.isWasteBad = isBad;
        break;
      case 'WasteWater':
      case 'wasteWater':
        this.isWasteWaterEnough = isEnough;
        this.isWasteWaterBad = isBad;
        break;
      case 'Reagent1':
      case 'reagent1':
        this.isReagent1Enough = isEnough;
        this.isReagent1Bad = isBad;
        break;
      case 'Reagent2':
      case 'reagent2':
        this.isReagent2Enough = isEnough;
        this.isReagent2Bad = isBad;
        break;
    }
  }

  private getReagentStatus(liquidType: string): ReagentStatus {
    switch (liquidType.toLowerCase()) {
      case 'blank':
        return { isEnough: this.isBlankEnough, isBad: this.isBlankBad };
      case 'standard':
        return { isEnough: this.isStandardEnough, isBad: this.isStandardBad };
      case 'zerocheck':
        return { isEnough: this.isZeroCheckEnough, isBad: this.isZeroCheckBad };
      case 'rangecheck':
        return { isEnough: this.isRangeCheckEnough, isBad: this.isRangeCheckBad };
      case 'waste':
        return { isEnough: this.isWasteEnough, isBad: this.isWasteBad };
      case 'wastewater':
        return { isEnough: this.isWasteWaterEnough, isBad: this.isWasteWaterBad };
      case 'reagent1':
        return { isEnough: this.isReagent1Enough, isBad: this.isReagent1Bad };
      case 'reagent2':
        return { isEnough: this.isReagent2Enough, isBad: this.isReagent2Bad };
      default:
        return { isEnough: true, isBad: false };
    }
  }

  private getRemainItem(reagent: LiquidType): RemainItem {
    switch (reagent) {
      case liquidTypes.blank:
        return remainConfig.blank;
      case liquidTypes.standard:
        return remainConfig.standard;
      case liquidTypes.zeroCheck:
        return remainConfig.zeroCheck;
      case liquidTypes.rangeCheck:
        return remainConfig.rangeCheck;
      case liquidTypes.waste:
        return remainConfig.waste;
      case liquidTypes.wasteWater:
        return remainConfig.wasteWater;
      case liquidTypes.reagent1:
        return remainConfig.reagent1;
      case liquidTypes.reagent2:
        return remainConfig.reagent2;
      default:
        return remainConfig.blank;
    }
  }

  private getRemainStatusItem(name: string): number {
    switch (name.toLowerCase()) {
      case 'blank':
        return remainStatus.blank;
      case 'standard':
        return remainStatus.standard;
      case 'zerocheck':
        return remainStatus.zeroCheck;
      case 'rangecheck':
        return remainStatus.rangeCheck;
      case 'waste':
        return remainStatus.waste;
      case 'wastewater':
        return remainStatus.wasteWater;
      case 'reagent1':
        return remainStatus.reagent1;
      case 'reagent2':
        return remainStatus.reagent2;
      default:
        return 0;
    }
  }

  private Check(reagent: LiquidType): void {
    const currentTime: number = Date.now();
    const reagentName = reagent.name;

    const configItem = this.getRemainItem(reagent);
    if (!configItem) {
      hilog.warn(122, 'ReagentRemainManager', `Check() => Unknown reagent type: ${reagentName}`);
      return;
    }

    try {
      const lastTimeDate = new Date(configItem.lastTime);
      lastTimeDate.setMonth(lastTimeDate.getMonth() + configItem.cycle);
      const reagentGoBadTime = lastTimeDate.getTime();

      if (reagentGoBadTime - currentTime < 0) {
        this.updateReagentStatus(reagentName, false, true);
        hilog.warn(122, 'ReagentRemainManager', `Reagent expired: ${reagentName}`);
      }
    } catch (err) {
      if (err instanceof Error) {
        hilog.warn(122, 'ReagentRemainManager', `Check() Error: ${err.message}`);
      } else {
        hilog.warn(122, 'ReagentRemainManager', 'Check(reagent) Error.');
      }
    }
  }

  private ReagentRemainCheck(): void {
    if (systemConfig.reagentLackWarn) {
      const checkList: RemainCheckList[] = [
        { name: 'Blank', reagent: liquidTypes.blank, status: this.getReagentStatus('Blank') },
        { name: 'Standard', reagent: liquidTypes.standard, status: this.getReagentStatus('Standard') },
        { name: 'ZeroCheck', reagent: liquidTypes.zeroCheck, status: this.getReagentStatus('ZeroCheck') },
        { name: 'RangeCheck', reagent: liquidTypes.rangeCheck, status: this.getReagentStatus('RangeCheck') },
        { name: 'Waste', reagent: liquidTypes.waste, status: this.getReagentStatus('Waste') },
        { name: 'WasteWater', reagent: liquidTypes.wasteWater, status: this.getReagentStatus('WasteWater') },
        { name: 'Reagent1', reagent: liquidTypes.reagent1, status: this.getReagentStatus('Reagent1') },
        { name: 'Reagent2', reagent: liquidTypes.reagent2, status: this.getReagentStatus('Reagent2') },
      ];

      checkList.forEach((item) => {
        const remain = this.getRemainStatusItem(item.name);
        if (this.REMAIN - remain >= this.PRECISE && item.status.isEnough && !item.status.isBad) {
          this.updateReagentStatus(item.name, false, false);
          hilog.warn(122, 'ReagentRemainManager', `Reagent low warning: ${item.name}`);
        }
      });
    }
  }

  private clampValue(value: number, min: number, max: number): number {
    return Math.max(min, Math.min(max, value));
  }

  // Public methods
  ChangeReagent(reagent: LiquidType, vol: number): void {
    switch (reagent) {
      case liquidTypes.blank:
        remainStatus.blank = vol;
        this.updateReagentStatus('blank', true, false);
        break;
      case liquidTypes.standard:
        remainStatus.standard = vol;
        this.updateReagentStatus('standard', true, false);
        break;
      case liquidTypes.zeroCheck:
        remainStatus.zeroCheck = vol;
        this.updateReagentStatus('zeroCheck', true, false);
        break;
      case liquidTypes.rangeCheck:
        remainStatus.rangeCheck = vol;
        this.updateReagentStatus('rangeCheck', true, false);
        break;
      case liquidTypes.waste:
        remainStatus.waste = vol;
        this.updateReagentStatus('waste', true, false);
        break;
      case liquidTypes.wasteWater:
        remainStatus.wasteWater = vol;
        this.updateReagentStatus('wasteWater', true, false);
        break;
      case liquidTypes.reagent1:
        remainStatus.reagent1 = vol;
        this.updateReagentStatus('reagent1', true, false);
        break;
      case liquidTypes.reagent2:
        remainStatus.reagent2 = vol;
        this.updateReagentStatus('reagent2', true, false);
        break;
    }
  }

  CheckAllReagentDate(): void {
    if (systemConfig.reagentLackWarn) {
      const checkList: CheckList[] = [
        { reagent: liquidTypes.blank, status: this.getReagentStatus('Blank') },
        { reagent: liquidTypes.standard, status: this.getReagentStatus('Standard') },
        { reagent: liquidTypes.zeroCheck, status: this.getReagentStatus('ZeroCheck') },
        { reagent: liquidTypes.rangeCheck, status: this.getReagentStatus('RangeCheck') },
        { reagent: liquidTypes.waste, status: this.getReagentStatus('Waste') },
        { reagent: liquidTypes.wasteWater, status: this.getReagentStatus('WasteWater') },
        { reagent: liquidTypes.reagent1, status: this.getReagentStatus('Reagent1') },
        { reagent: liquidTypes.reagent2, status: this.getReagentStatus('Reagent2') },
      ];

      checkList.forEach((item) => {
        if (!item.status.isBad && item.status.isEnough) {
          this.Check(item.reagent);
        }
      });
    }
  }

  ReduceReagent(reagent: LiquidType, vol: number): void {
    const multipleValvePipeVolume: number = 0;

    switch (reagent) {
      case liquidTypes.blank:
        remainStatus.blank = this.clampValue(
          remainStatus.blank - (vol + multipleValvePipeVolume),
          0,
          remainConfig.blank.total
        );
        remainStatus.waste = this.clampValue(
          remainStatus.waste - (vol + multipleValvePipeVolume) / 2,
          0,
          remainConfig.waste.total
        );
        remainStatus.wasteWater = this.clampValue(
          remainStatus.wasteWater - (vol + multipleValvePipeVolume) / 2,
          0,
          remainConfig.wasteWater.total
        );
        break;
      case liquidTypes.standard:
        remainStatus.standard = this.clampValue(
          remainStatus.standard - (vol + multipleValvePipeVolume),
          0,
          remainConfig.standard.total
        );
        remainStatus.waste = this.clampValue(
          remainStatus.waste - (vol + multipleValvePipeVolume),
          0,
          remainConfig.waste.total
        );
        break;
      case liquidTypes.zeroCheck:
        remainStatus.zeroCheck = this.clampValue(
          remainStatus.zeroCheck - (vol + multipleValvePipeVolume),
          0,
          remainConfig.zeroCheck.total
        );
        remainStatus.waste = this.clampValue(
          remainStatus.waste - (vol + multipleValvePipeVolume),
          0,
          remainConfig.waste.total
        );
        break;
      case liquidTypes.rangeCheck:
        remainStatus.rangeCheck = this.clampValue(
          remainStatus.rangeCheck - (vol + multipleValvePipeVolume),
          0,
          remainConfig.rangeCheck.total
        );
        remainStatus.waste = this.clampValue(
          remainStatus.waste - (vol + multipleValvePipeVolume),
          0,
          remainConfig.waste.total
        );
        break;
      case liquidTypes.sample:
        remainStatus.waste = this.clampValue(
          remainStatus.waste - (vol + multipleValvePipeVolume),
          0,
          remainConfig.waste.total
        );
        break;
      case liquidTypes.reagent1:
        remainStatus.reagent1 = this.clampValue(
          remainStatus.reagent1 - (vol + multipleValvePipeVolume),
          0,
          remainConfig.reagent1.total
        );
        remainStatus.waste = this.clampValue(
          remainStatus.waste - (vol + multipleValvePipeVolume),
          0,
          remainConfig.waste.total
        );
        break;
      case liquidTypes.reagent2:
        remainStatus.reagent2 = this.clampValue(
          remainStatus.reagent2 - (vol + multipleValvePipeVolume),
          0,
          remainConfig.reagent2.total
        );
        remainStatus.waste = this.clampValue(
          remainStatus.waste - (vol + multipleValvePipeVolume),
          0,
          remainConfig.waste.total
        );
        break;
    }

    remainStatus.waste = this.clampValue(remainStatus.waste, 0, remainConfig.waste.total);
    remainStatus.wasteWater = this.clampValue(remainStatus.wasteWater, 0, remainConfig.wasteWater.total);

    this.ReagentRemainCheck();
  }

  RecoverReagent(reagent: LiquidType, vol: number): void {
    const multipleValvePipeVolume: number = 0;

    switch (reagent) {
      case liquidTypes.blank:
        remainStatus.blank = this.clampValue(
          remainStatus.blank + (vol + multipleValvePipeVolume),
          0,
          remainConfig.blank.total
        );
        remainStatus.waste = this.clampValue(
          remainStatus.waste + (vol + multipleValvePipeVolume),
          0,
          remainConfig.waste.total
        );
        break;
      case liquidTypes.standard:
        remainStatus.standard = this.clampValue(
          remainStatus.standard + (vol + multipleValvePipeVolume),
          0,
          remainConfig.standard.total
        );
        remainStatus.waste = this.clampValue(
          remainStatus.waste + (vol + multipleValvePipeVolume),
          0,
          remainConfig.waste.total
        );
        break;
      case liquidTypes.zeroCheck:
        remainStatus.zeroCheck = this.clampValue(
          remainStatus.zeroCheck + (vol + multipleValvePipeVolume),
          0,
          remainConfig.zeroCheck.total
        );
        remainStatus.waste = this.clampValue(
          remainStatus.waste + (vol + multipleValvePipeVolume),
          0,
          remainConfig.waste.total
        );
        break;
      case liquidTypes.rangeCheck:
        remainStatus.rangeCheck = this.clampValue(
          remainStatus.rangeCheck + (vol + multipleValvePipeVolume),
          0,
          remainConfig.rangeCheck.total
        );
        remainStatus.waste = this.clampValue(
          remainStatus.waste + (vol + multipleValvePipeVolume),
          0,
          remainConfig.waste.total
        );
        break;
      case liquidTypes.sample:
        remainStatus.waste = this.clampValue(
          remainStatus.waste + (vol + multipleValvePipeVolume),
          0,
          remainConfig.waste.total
        );
        break;
      case liquidTypes.reagent1:
        remainStatus.reagent1 = this.clampValue(
          remainStatus.reagent1 + (vol + multipleValvePipeVolume),
          0,
          remainConfig.reagent1.total
        );
        remainStatus.waste = this.clampValue(
          remainStatus.waste + (vol + multipleValvePipeVolume),
          0,
          remainConfig.waste.total
        );
        break;
      case liquidTypes.reagent2:
        remainStatus.reagent2 = this.clampValue(
          remainStatus.reagent2 + (vol + multipleValvePipeVolume),
          0,
          remainConfig.reagent2.total
        );
        remainStatus.waste = this.clampValue(
          remainStatus.waste + (vol + multipleValvePipeVolume),
          0,
          remainConfig.waste.total
        );
        break;
    }

    remainStatus.waste = this.clampValue(remainStatus.waste, 0, remainConfig.waste.total);
    remainStatus.wasteWater = this.clampValue(remainStatus.wasteWater, 0, remainConfig.wasteWater.total);

    this.ReagentRemainCheck();
  }

  RecoverRemainCheckStatus(): void {
    this.isBlankEnough = true;
    this.isStandardEnough = true;
    this.isWasteEnough = true;
    this.isWasteWaterEnough = true;
    this.isZeroCheckEnough = true;
    this.isRangeCheckEnough = true;
    this.isReagent1Enough = true;
    this.isReagent2Enough = true;

    this.isBlankBad = false;
    this.isStandardBad = false;
    this.isWasteBad = false;
    this.isWasteWaterBad = false;
    this.isZeroCheckBad = false;
    this.isRangeCheckBad = false;
    this.isReagent1Bad = false;
    this.isReagent2Bad = false;
  }

  SaveRemainStatus(): void {
    hilog.info(122, 'ReagentRemainManager', 'SaveRemainStatus()');
  }
}

// 为了保持向后兼容性，导出原有的函数接口
const manager = ReagentRemainManager.getInstance();

export function ChangeReagent(reagent: LiquidType, vol: number): void {
  manager.ChangeReagent(reagent, vol);
}

export function CheckAllReagentDate(): void {
  manager.CheckAllReagentDate();
}

export function ReduceReagent(reagent: LiquidType, vol: number): void {
  manager.ReduceReagent(reagent, vol);
}

export function RecoverReagent(reagent: LiquidType, vol: number): void {
  manager.RecoverReagent(reagent, vol);
}

export function RecoverRemainCheckStatus(): void {
  manager.RecoverRemainCheckStatus();
}

export function SaveRemainStatus(): void {
  manager.SaveRemainStatus();
}