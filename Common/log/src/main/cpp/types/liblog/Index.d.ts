// src/main/cpp/types/liblog/Index.d.ts
export interface LogFileInfo {
  fileName: string;
  fileSize: number;
  lineCount: number;
  lastModified: string;
}

export interface LogNative {
  // 基础功能
  init(appName: string): void;
  debug(msg: string): void;
  info(msg: string): void;
  warn(msg: string): void;
  error(msg: string): void;
  getLogDir(): string;
  flush(): void;

  // 日志回读功能
  readRecentLogs(lines: number): string;
  readLogsFromFile(fileName: string, lines: number): string;
  readAllLogs(fileName: string): string;
  getAllLogFilesInfo(): LogFileInfo[];
  clearLogFile(fileName: string): boolean;
  deleteLogFile(fileName: string): boolean;
}

declare const logNative: LogNative;
export default logNative;