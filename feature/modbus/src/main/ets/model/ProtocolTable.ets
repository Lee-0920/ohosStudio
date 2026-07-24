// lhipstudio/modbus/src/main/ets/model/ProtocolTable.ets

import { RegisterInfo } from './Types';
import { REGISTERS } from './Registers';
import { Logger } from 'logger';

/**
 * 支持的 Modbus 协议类型。
 *
 * 当前已实现：LS4.0
 * 预留扩展：JS / SZBA / 地表水1.0
 */
export type ModbusProtocolType = 'LS4.0' | 'JS' | 'SZBA' | '地表水1.0';

/**
 * 协议表接口。
 *
 * 每种协议实现该接口，提供：
 * 1. 寄存器元数据查询（用于 DataStore 校验与日志）
 * 2. 外部地址与内部 LS4.0 地址之间的双向映射（用于 Handler 收发）
 */
export interface ProtocolTable {
  readonly name: ModbusProtocolType;

  /**
   * 根据外部地址查询寄存器元数据。
   */
  getRegisterInfo(externalAddress: number): RegisterInfo | undefined;

  /**
   * 将外部协议地址转换为内部 LS4.0 地址。
   * 内部地址用于现有业务逻辑与 DataStore 存储。
   */
  toInternalAddress(externalAddress: number): number;

  /**
   * 将内部 LS4.0 地址转换回外部协议地址。
   * 用于写响应中需要回显原始地址的场景。
   */
  toExternalAddress(internalAddress: number): number;
}

/**
 * LS4.0 协议表。
 *
 * 当前 feature/modbus 中已实现的完整寄存器映射即为 LS4.0。
 * 其内外地址映射为恒等映射，保证现有行为不变。
 */
export class Ls40ProtocolTable implements ProtocolTable {
  readonly name: ModbusProtocolType = 'LS4.0';

  getRegisterInfo(externalAddress: number): RegisterInfo | undefined {
    return REGISTERS.get(externalAddress);
  }

  toInternalAddress(externalAddress: number): number {
    return externalAddress;
  }

  toExternalAddress(internalAddress: number): number {
    return internalAddress;
  }
}

/**
 * JS 协议表（占位实现）。
 *
 * 当前复用 LS4.0 寄存器映射，后续根据 JS 协议规范覆盖地址映射即可。
 */
export class JsProtocolTable extends Ls40ProtocolTable {
  readonly name: ModbusProtocolType = 'JS';
}

/**
 * SZBA 协议表（占位实现）。
 *
 * 当前复用 LS4.0 寄存器映射，后续根据 SZBA 协议规范覆盖地址映射即可。
 */
export class SzbaProtocolTable extends Ls40ProtocolTable {
  readonly name: ModbusProtocolType = 'SZBA';
}

/**
 * 地表水 1.0 协议表（占位实现）。
 *
 * 当前复用 LS4.0 寄存器映射，后续根据地表水 1.0 协议规范覆盖地址映射即可。
 */
export class SurfaceWaterProtocolTable extends Ls40ProtocolTable {
  readonly name: ModbusProtocolType = '地表水1.0';
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
    ProtocolTableRegistry.register(new JsProtocolTable());
    ProtocolTableRegistry.register(new SzbaProtocolTable());
    ProtocolTableRegistry.register(new SurfaceWaterProtocolTable());
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
