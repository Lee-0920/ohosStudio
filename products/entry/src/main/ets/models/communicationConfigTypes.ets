export type CommunicationConfigMode = 'tcp' | 'uart';
export type UartParity = 'N' | 'E' | 'O';

export interface CommunicationConfig {
  mode: CommunicationConfigMode;
  tcpIp: string;
  tcpPort: number;
  uartPath: string;
  uartBaudRate: number;
  uartDataBits: number;
  uartStopBits: number;
  uartParity: UartParity;
  uartIsRs485: boolean;
}

export interface CommunicationConfigLoadResult {
  config: CommunicationConfig;
  fromPersistence: boolean;
  fallbackToDefaults: boolean;
}

export interface CommunicationConfigApplyResult {
  success: boolean;
  changed: boolean;
  disconnectedPreviousConnection: boolean;
  config: CommunicationConfig;
  errorMessage: string;
}
