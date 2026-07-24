// src/main/ets/Index.ets
import logNative from 'liblog.so';

// 类型声明
interface LogNativeInterface {
  init(appName: string): void;
  debug(msg: string): void;
  info(msg: string): void;
  warn(msg: string): void;
  error(msg: string): void;
  getLogDir(): string;
  flush(): void;
  readRecentLogs(lines: number): string;
  readLogsFromFile(fileName: string, lines: number): string;
  readAllLogs(fileName: string): string;
  getAllLogFilesInfo(): LogFileInfo[];
  clearLogFile(fileName: string): boolean;
  deleteLogFile(fileName: string): boolean;
}

const logNativeTyped = logNative as LogNativeInterface;

// 模块级变量
let isInit: boolean = false;

export interface LogFileInfo {
  fileName: string;
  fileSize: number;
  lineCount: number;
  lastModified: string;
}

// ========== 辅助函数 ==========

// 判断字符串是否包含 C 风格格式化占位符
function hasCFormatPlaceholders(str: string): boolean {
  return /%[+\-#0 ]?[0-9]*(\.[0-9]+)?[cdioxXufFeEgGaApsn]/.test(str);
}

// C 风格格式化函数（修复类型问题）
function sprintf(format: string, args: ESObject[]): string {
  let result: string = format;
  let argIndex: number = 0;

  // 逐个替换占位符
  let match: RegExpExecArray | null;
  const regex = /%[+\-#0 ]?[0-9]*(\.[0-9]+)?[cdioxXufFeEgGaApsn]/g;

  while ((match = regex.exec(result)) !== null) {
    if (argIndex >= args.length) {
      break;
    }

    const placeholder: string = match[0];
    const value: ESObject = args[argIndex];
    let replacement: string = '';

    // 根据格式符类型转换
    const lastChar: string = placeholder.charAt(placeholder.length - 1);
    switch (lastChar) {
      case 's':
        replacement = String(value);
        break;
      case 'd':
      case 'i':
      case 'u':
        replacement = String(Number(value));
        break;
      case 'f':
      case 'F':
      case 'e':
      case 'E':
      case 'g':
      case 'G':
        // 保留浮点数格式，如 %.2f
        const numValue: number = Number(value);
        if (placeholder.includes('.')) {
          const precisionMatch: RegExpMatchArray | null = placeholder.match(/\.(\d+)/);
          if (precisionMatch) {
            const precision: number = parseInt(precisionMatch[1], 10);
            replacement = numValue.toFixed(precision);
            break;
          }
        }
        replacement = String(numValue);
        break;
      case 'x':
        replacement = Number(value).toString(16);
        break;
      case 'X':
        replacement = Number(value).toString(16).toUpperCase();
        break;
      case 'o':
        replacement = Number(value).toString(8);
        break;
      case 'c':
        replacement = String.fromCharCode(Number(value));
        break;
      default:
        replacement = String(value);
        break;
    }

    // 替换第一个出现的占位符
    result = result.replace(placeholder, replacement);
    argIndex++;

    // 重置正则的 lastIndex，因为我们修改了字符串
    regex.lastIndex = 0;
  }

  return result;
}

// ========== 基础功能 ==========

export function init(appName: string): void {
  if (!isInit) {
    logNativeTyped.init(appName);
    isInit = true;
  }
}

// debug 函数重载
export function debug(msg: string): void;
export function debug(format: string, ...args: ESObject[]): void;
export function debug(msgOrFormat: string, ...args: ESObject[]): void {
  if (args.length > 0 || hasCFormatPlaceholders(msgOrFormat)) {
    const formatted: string = sprintf(msgOrFormat, args);
    logNativeTyped.debug(formatted);
  } else {
    logNativeTyped.debug(msgOrFormat);
  }
}

// info 函数重载
export function info(msg: string): void;
export function info(format: string, ...args: ESObject[]): void;
export function info(msgOrFormat: string, ...args: ESObject[]): void {
  if (args.length > 0 || hasCFormatPlaceholders(msgOrFormat)) {
    const formatted: string = sprintf(msgOrFormat, args);
    logNativeTyped.info(formatted);
  } else {
    logNativeTyped.info(msgOrFormat);
  }
}

// warn 函数重载
export function warn(msg: string): void;
export function warn(format: string, ...args: ESObject[]): void;
export function warn(msgOrFormat: string, ...args: ESObject[]): void {
  if (args.length > 0 || hasCFormatPlaceholders(msgOrFormat)) {
    const formatted: string = sprintf(msgOrFormat, args);
    logNativeTyped.warn(formatted);
  } else {
    logNativeTyped.warn(msgOrFormat);
  }
}

// error 函数重载
export function error(msg: string): void;
export function error(format: string, ...args: ESObject[]): void;
export function error(msgOrFormat: string, ...args: ESObject[]): void {
  if (args.length > 0 || hasCFormatPlaceholders(msgOrFormat)) {
    const formatted: string = sprintf(msgOrFormat, args);
    logNativeTyped.error(formatted);
  } else {
    logNativeTyped.error(msgOrFormat);
  }
}

export function getLogDir(): string {
  return logNativeTyped.getLogDir();
}

export function flush(): void {
  logNativeTyped.flush();
}

// ========== 日志回读功能 ==========

export function readRecentLogs(lines: number = 100): string {
  return logNativeTyped.readRecentLogs(lines);
}

export function readLogsFromFile(fileName: string, lines: number = 100): string {
  return logNativeTyped.readLogsFromFile(fileName, lines);
}

export function readAllLogs(fileName: string): string {
  return logNativeTyped.readAllLogs(fileName);
}

export function getAllLogFilesInfo(): LogFileInfo[] {
  return logNativeTyped.getAllLogFilesInfo();
}

export function clearLogFile(fileName: string): boolean {
  return logNativeTyped.clearLogFile(fileName);
}

export function deleteLogFile(fileName: string): boolean {
  return logNativeTyped.deleteLogFile(fileName);
}

// ========== Logger 类 ==========

export class Logger {
  static init(appName: string): void {
    init(appName);
  }

  static debug(msg: string): void;
  static debug(format: string, ...args: ESObject[]): void;
  static debug(msgOrFormat: string, ...args: ESObject[]): void {
    debug(msgOrFormat, ...args);
  }

  static info(msg: string): void;
  static info(format: string, ...args: ESObject[]): void;
  static info(msgOrFormat: string, ...args: ESObject[]): void {
    info(msgOrFormat, ...args);
  }

  static warn(msg: string): void;
  static warn(format: string, ...args: ESObject[]): void;
  static warn(msgOrFormat: string, ...args: ESObject[]): void {
    warn(msgOrFormat, ...args);
  }

  static error(msg: string): void;
  static error(format: string, ...args: ESObject[]): void;
  static error(msgOrFormat: string, ...args: ESObject[]): void {
    error(msgOrFormat, ...args);
  }

  static getLogDir(): string {
    return getLogDir();
  }

  static flush(): void {
    flush();
  }

  static readRecentLogs(lines: number = 100): string {
    return readRecentLogs(lines);
  }

  static readLogsFromFile(fileName: string, lines: number = 100): string {
    return readLogsFromFile(fileName, lines);
  }

  static readAllLogs(fileName: string): string {
    return readAllLogs(fileName);
  }

  static getAllLogFilesInfo(): LogFileInfo[] {
    return getAllLogFilesInfo();
  }

  static clearLogFile(fileName: string): boolean {
    return clearLogFile(fileName);
  }
}

// 默认导出
export default Logger;