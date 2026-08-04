// lhipstudio/modbus/src/main/ets/model/ProtocolTable.ets

import { RegisterInfo } from './Types';
import { REGISTERS } from './Registers';
import { Logger } from 'logger';

/**
 * 支持的 Modbus 协议类型。
 *
 * 与设置页 MODBUSPROTOCOLMODE 枚举保持一致。
 */
export type ModbusProtocolType =
  | 'LS4.0'
  | 'LS1.0'
  | 'LS2.0'
  | 'JS'
  | 'SZBA'
  | '地表水1.0'
  | 'SC'
  | '西宁动态管控'
  | 'GZ'
  | 'JX'
  | 'XiAn'
  | 'YC';

/**
 * 协议表接口。
 *
 * 每种协议实现该接口，提供：
 * 1. 寄存器元数据查询（用于 DataStore 校验与日志）
 * 2. 外部地址与内部 LS4.0 地址之间的双向映射（用于 Handler 收发）
 *
 * functionCode 为可选参数，用于区分输入寄存器（0x04）与保持寄存器（0x03/0x06/0x10）
 * 的映射上下文。对恒等映射协议可忽略该参数。
 */
export interface ProtocolTable {
  readonly name: ModbusProtocolType;

  /**
   * 根据外部地址查询寄存器元数据。
   */
  getRegisterInfo(externalAddress: number, functionCode?: number): RegisterInfo | undefined;

  /**
   * 将外部协议地址转换为内部 LS4.0 地址。
   * 内部地址用于现有业务逻辑与 DataStore 存储。
   */
  toInternalAddress(externalAddress: number, functionCode?: number): number;

  /**
   * 将内部 LS4.0 地址转换回外部协议地址。
   * 用于写响应中需要回显原始地址的场景。
   */
  toExternalAddress(internalAddress: number, functionCode?: number): number;
}

/**
 * LS4.0 协议表。
 *
 * 当前 feature/modbus 中已实现的完整寄存器映射即为 LS4.0。
 * 其内外地址映射为恒等映射，保证现有行为不变。
 */
export class Ls40ProtocolTable implements ProtocolTable {
  readonly name: ModbusProtocolType = 'LS4.0';

  getRegisterInfo(externalAddress: number, functionCode?: number): RegisterInfo | undefined {
    return REGISTERS.get(externalAddress);
  }

  toInternalAddress(externalAddress: number, functionCode?: number): number {
    return externalAddress;
  }

  toExternalAddress(internalAddress: number, functionCode?: number): number {
    return internalAddress;
  }
}

/**
 * 通用偏移协议表。
 *
 * 通过 inputBase / holdingBase 描述输入寄存器与保持寄存器的外部基址，
 * 将外部地址线性映射到内部 LS4.0 地址空间。
 */
export class OffsetProtocolTable implements ProtocolTable {
  readonly name: ModbusProtocolType;
  private readonly inputBase: number;
  private readonly holdingBase: number;

  constructor(name: ModbusProtocolType, inputBase: number, holdingBase: number) {
    this.name = name;
    this.inputBase = inputBase;
    this.holdingBase = holdingBase;
  }

  getRegisterInfo(externalAddress: number, functionCode?: number): RegisterInfo | undefined {
    return REGISTERS.get(this.toInternalAddress(externalAddress, functionCode));
  }

  toInternalAddress(externalAddress: number, functionCode?: number): number {
    const base = functionCode === 0x04 ? this.inputBase : this.holdingBase;
    return externalAddress - base;
  }

  toExternalAddress(internalAddress: number, functionCode?: number): number {
    const base = functionCode === 0x04 ? this.inputBase : this.holdingBase;
    return internalAddress + base;
  }
}

/**
 * LS1.0 协议表（Labsun10）。
 *
 * 输入寄存器 0-255，保持寄存器 256-511，均映射到内部 0-255。
 */
export class Ls10ProtocolTable extends OffsetProtocolTable {
  constructor() {
    super('LS1.0', 0, 256);
  }
}

/**
 * LS2.0 协议表（Labsun20）。
 *
 * 外部地址 0-255 与内部 LS4.0 地址一一对应。
 */
export class Ls20ProtocolTable extends Ls40ProtocolTable {
  readonly name: ModbusProtocolType = 'LS2.0';
}

/**
 * JS 协议表。
 *
 * 输入寄存器基址 30001，保持寄存器基址 40001。
 */
export class JsProtocolTable extends OffsetProtocolTable {
  constructor() {
    super('JS', 30001, 40001);
  }
}

/**
 * 地表水 1.0 协议表（DBS）。
 *
 * 保持寄存器基址 0x1000。
 */
export class SurfaceWaterProtocolTable extends OffsetProtocolTable {
  constructor() {
    super('地表水1.0', 0, 0x1000);
  }
}

/**
 * SZBA 协议表。
 *
 * 外部地址 0-255 与内部 LS4.0 地址一一对应。
 */
export class SzbaProtocolTable extends Ls40ProtocolTable {
  readonly name: ModbusProtocolType = 'SZBA';
}

/**
 * SC（四川）协议表。
 *
 * 外部地址 0-1023 与内部 LS4.0 地址一一对应。
 */
export class ScProtocolTable extends Ls40ProtocolTable {
  readonly name: ModbusProtocolType = 'SC';
}

/**
 * 西宁动态管控协议表（XN）。
 *
 * 外部地址 0-255 与内部 LS4.0 地址一一对应。
 */
export class XnProtocolTable extends Ls40ProtocolTable {
  readonly name: ModbusProtocolType = '西宁动态管控';
}

/**
 * GZ（贵州）协议表。
 *
 * 输入寄存器基址 30001，保持寄存器基址 40001。
 */
export class GzProtocolTable extends OffsetProtocolTable {
  constructor() {
    super('GZ', 30001, 40001);
  }
}

/**
 * JX（江西）协议表。
 *
 * 输入寄存器基址 30001，保持寄存器基址 40001。
 */
export class JxProtocolTable extends OffsetProtocolTable {
  constructor() {
    super('JX', 30001, 40001);
  }
}

/**
 * XiAn（西安）协议表。
 *
 * 输入寄存器基址 30200，保持寄存器基址 40100。
 */
export class XianProtocolTable extends OffsetProtocolTable {
  constructor() {
    super('XiAn', 30200, 40100);
  }
}

/**
 * YC（银川）协议表。
 *
 * 外部地址 0-255 与内部 LS4.0 地址一一对应。
 */
export class YcProtocolTable extends Ls40ProtocolTable {
  readonly name: ModbusProtocolType = 'YC';
}

/**
 * 协议表注册中心。
 *
 * 统一管理所有协议表，并提供默认表兜底。
 */
export class ProtocolTableRegistry {
  private static tables: Map<string, ProtocolTable> = new Map();
  private static defaultTable: ProtocolTable = new Ls40ProtocolTable();
  private static initialized: boolean = false;

  private static initialize(): void {
    if (ProtocolTableRegistry.initialized) {
      return;
    }
    ProtocolTableRegistry.register(ProtocolTableRegistry.defaultTable);
    ProtocolTableRegistry.register(new Ls10ProtocolTable());
    ProtocolTableRegistry.register(new Ls20ProtocolTable());
    ProtocolTableRegistry.register(new JsProtocolTable());
    ProtocolTableRegistry.register(new SzbaProtocolTable());
    ProtocolTableRegistry.register(new SurfaceWaterProtocolTable());
    ProtocolTableRegistry.register(new ScProtocolTable());
    ProtocolTableRegistry.register(new XnProtocolTable());
    ProtocolTableRegistry.register(new GzProtocolTable());
    ProtocolTableRegistry.register(new JxProtocolTable());
    ProtocolTableRegistry.register(new XianProtocolTable());
    ProtocolTableRegistry.register(new YcProtocolTable());
    ProtocolTableRegistry.initialized = true;
  }

  static register(table: ProtocolTable): void {
    ProtocolTableRegistry.tables.set(table.name, table);
    Logger.info('ProtocolTableRegistry', 'Registered protocol table: %s', table.name);
  }

  static get(name: string): ProtocolTable {
    ProtocolTableRegistry.initialize();
    const table = ProtocolTableRegistry.tables.get(name);
    if (!table) {
      Logger.warn('ProtocolTableRegistry', 'Unknown protocol table "%s", fallback to LS4.0', name);
      return ProtocolTableRegistry.defaultTable;
    }
    return table;
  }

  static getDefault(): ProtocolTable {
    ProtocolTableRegistry.initialize();
    return ProtocolTableRegistry.defaultTable;
  }

  static getAllNames(): string[] {
    ProtocolTableRegistry.initialize();
    const names: string[] = [];
    ProtocolTableRegistry.tables.forEach((_, key) => {
      names.push(key);
    });
    return names;
  }

  static isRegistered(name: string): boolean {
    ProtocolTableRegistry.initialize();
    return ProtocolTableRegistry.tables.has(name);
  }
}
