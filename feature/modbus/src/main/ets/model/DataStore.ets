// lhipstudio/modbus/src/main/ets/model/DataStore.ets

import { DataType, TimeData, DataFlag, SystemStatus, CurrentAction } from './Types';
import { ProtocolTable, ProtocolTableRegistry } from './ProtocolTable';
import { REGISTERS } from './Registers';
import { util } from '@kit.ArkTS';

// 数据存储单例
export class DataStore {
  private static instance: DataStore;
  private registerData: Map<number, Uint8Array> = new Map();
  private currentTable: ProtocolTable = ProtocolTableRegistry.getDefault();


  static getInstance(): DataStore {
    if (!DataStore.instance) {
      DataStore.instance = new DataStore();
    }
    return DataStore.instance;
  }

  /**
   * 切换当前使用的协议表。
   * 内部数据仍按 LS4.0 内部地址存储，因此切换表不会影响已有数据。
   */
  setProtocolTable(table: ProtocolTable): void {
    this.currentTable = table;
  }

  getProtocolTable(): ProtocolTable {
    return this.currentTable;
  }

  // 写入寄存器值（address 为内部 LS4.0 地址）
  writeRegister(address: number, data: Uint8Array): boolean {
    // 检查是否可写（内部地址空间始终是 LS4.0，直接查 REGISTERS）
    const regInfo = REGISTERS.get(address);
    if (regInfo && regInfo.access === 'R') {
      return false;
    }

    // 根据数据类型验证并存储
    if (regInfo) {
      for (let i = 0; i < data.length / 2; i++) {
          const offset = i * 2;
          this.registerData.set(address + i, data.slice(offset, offset + 2));
        }
    } else {
      // 未知寄存器，直接存储
      for (let i = 0; i < data.length / 2; i++) {
        const offset = i * 2;
        this.registerData.set(address + i, data.slice(offset, offset + 2));
      }
    }

    return true;
  }

  // 获取寄存器信息（address 为内部 LS4.0 地址）
  getRegisterInfo(address: number) {
    return REGISTERS.get(address);
  }
  // 设置FLOAT32值 (大端序)
  setFloat32(address: number, value: number): void {
    const buffer = new ArrayBuffer(4);
    const view = new DataView(buffer);
    view.setFloat32(0, value, false);
    const bytes = new Uint8Array(buffer);
    this.registerData.set(address, bytes.slice(0, 2));
    this.registerData.set(address + 1, bytes.slice(2, 4));
  }

  // 获取FLOAT32值
  getFloat32(address: number): number {
    const high = this.registerData.get(address);
    const low = this.registerData.get(address + 1);
    if (high && high.length >= 2 && low && low.length >= 2) {
      const buffer = new ArrayBuffer(4);
      const bytes = new Uint8Array(buffer);
      bytes.set(high, 0);
      bytes.set(low, 2);
      const view = new DataView(buffer);
      return view.getFloat32(0, false);
    }
    return 0;
  }

  // 设置 UINT16 值（内部使用，允许写入只读寄存器，如系统状态、当前动作）
  setUInt16(address: number, value: number): void {
    const buffer = new ArrayBuffer(2);
    const view = new DataView(buffer);
    view.setUint16(0, value, false);
    this.registerData.set(address, new Uint8Array(buffer));
  }

  // 获取 UINT16 值
  getUInt16(address: number): number {
    const data = this.registerData.get(address);
    if (data && data.length >= 2) {
      const view = new DataView(data.buffer);
      return view.getUint16(0, false);
    }
    return 0;
  }
}
