export interface LiquidType {
  name: string;
  pump: number;
  valve: number;
}

export enum Map {
  valve1 = 1,
  valve2 = 2,
  valve3 = 4,
  valve4 = 8,
  valve5 = 16,
  valve6 = 32,
  valve7 = 64,
  valve8 = 128,
  valve9 = 256,
  valve10 = 512,
  valve11 = 1024,
  valve12 = 2048,
  valve13 = 4096,
  valve14 = 8192,
  valve15 = 16384,
  valve16 = 32768,
}

export interface LiquidTypes {
  none:LiquidType;
  sample:LiquidType;
  standard:LiquidType;
  blank:LiquidType;
  rangeCheck:LiquidType;
  zeroCheck:LiquidType;
  digestionRoom:LiquidType;
  wasteWater:LiquidType;
  waste:LiquidType;
  reagent1:LiquidType;
  reagent2:LiquidType;
  gas:LiquidType;
}

export const liquidTypes: LiquidTypes = {
  // 无任何阀
  none: {
    name: "None",
    pump: 0,
    valve: 0,
  },

  // 水样
  sample: {
    name: "Sample",
    pump: 0,
    valve: Map.valve1,
  },

  // 量程校准液
  standard: {
    name: "Standard",
    pump: 0,
    valve: Map.valve2,
  },

  // 零点校准液
  blank: {
    name: "Blank",
    pump: 0,
    valve: Map.valve3,
  },

  // 标样(跨度)核查液
  rangeCheck: {
    name: "RangeCheck",
    pump: 0,
    valve: Map.valve15,
  },

  // 零点核查液
  zeroCheck: {
    name: "ZeroCheck",
    pump: 0,
    valve: Map.valve14,
  },

  // 消解室
  digestionRoom: {
    name: "DigestionRoom",
    pump: 0,
    valve: Map.valve4 + Map.valve5,
  },

  // 废水
  wasteWater: {
    name: "WasteWater",
    pump: 0,
    valve: Map.valve10,
  },

  // 分析废液
  waste: {
    name: "Waste",
    pump: 0,
    valve: Map.valve6,
  },

  // 试剂1
  reagent1: {
    name: "Reagent1",
    pump: 0,
    valve: Map.valve7,
  },

  // 试剂2
  reagent2: {
    name: "Reagent2",
    pump: 0,
    valve: Map.valve8,
  },

  // 气密性检查阀
  gas: {
    name: "Gas",
    pump: 0,
    valve: Map.valve2 + Map.valve3 + Map.valve7 + Map.valve8 + Map.valve14,
  },
};

export function getLiquidType(key: string): LiquidType | undefined {
  switch (key) {
    case 'none':         return liquidTypes.none;
    case 'sample':       return liquidTypes.sample;
    case 'standard':     return liquidTypes.standard;
    case 'blank':        return liquidTypes.blank;
    case 'rangeCheck':   return liquidTypes.rangeCheck;
    case 'zeroCheck':    return liquidTypes.zeroCheck;
    case 'digestionRoom':return liquidTypes.digestionRoom;
    case 'wasteWater':   return liquidTypes.wasteWater;
    case 'waste':        return liquidTypes.waste;
    case 'reagent1':     return liquidTypes.reagent1;
    case 'reagent2':     return liquidTypes.reagent2;
    case 'gas':          return liquidTypes.gas;
    default:             return undefined;
  }
}

export default LiquidTypes;
