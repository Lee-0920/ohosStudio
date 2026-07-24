// lhipstudio/modbus/src/main/ets/types/libentry.d.ts
declare module 'libentry.so' {
  export interface SerialConfig {
    baudRate: number;
    dataBits: number;
    stopBits: number;
    parity: number;
  }

  export interface UartStatus {
    isOpened: boolean;
    fd: number;
  }

  export function openUart(devicePath?: string): boolean;
  export function closeUart(): void;
  export function writeUart(data: string | Uint8Array): boolean;
  export function readUart(): string;
  export function readUartBinary(): ArrayBuffer;
  export function setSerialConfig(config: SerialConfig): boolean;
  export function flushUart(): boolean;
  export function getUartStatus(): UartStatus;
}