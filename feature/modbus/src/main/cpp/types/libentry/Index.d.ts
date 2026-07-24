// lhipstudio/modbus/src/main/ets/types/libentry/Index.d.ts

export interface SerialConfig {
  baudRate: number;   // 波特率: 4800, 9600, 19200, 38400, 57600, 115200
  dataBits: number;   // 数据位: 5, 6, 7, 8
  stopBits: number;   // 停止位: 1, 2
  parity: number;     // 校验位: 0=无, 1=奇校验, 2=偶校验
}

export interface UartStatus {
  isOpened: boolean;
  fd: number;
}

// 打开串口，可指定设备路径（默认 /dev/ttyS0）
export function openUart(devicePath?: string): boolean;

// 关闭串口
export function closeUart(): void;

// 写入数据（支持 string 或 Uint8Array）
export function writeUart(data: string | Uint8Array): boolean;

// 读取数据（返回 Base64 编码字符串，兼容旧接口）
export function readUart(): string;

// 读取二进制数据（返回 ArrayBuffer，推荐使用）
export function readUartBinary(): ArrayBuffer;

// 设置串口参数
export function setSerialConfig(config: SerialConfig): boolean;

// 清除串口缓冲区
export function flushUart(): boolean;

// 获取串口状态
export function getUartStatus(): UartStatus;