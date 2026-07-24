export class UiUtil {
  public static vh(percent: number, min: number = 0, max: number = Number.MAX_VALUE,
    viewportHeight: number, scaleFactor: number): number {
    const raw = (viewportHeight * percent * scaleFactor) / 100;
    return Math.min(max, Math.max(min, raw));
  }

  public static vw(percent: number, min: number = 0, max: number = Number.MAX_VALUE,
    viewportWidth: number, scaleFactor: number): number {
    const raw = (viewportWidth * percent * scaleFactor) / 100;
    return Math.min(max, Math.max(min, raw));
  }

  /**
   * 日期转
   * @param date
   * @returns
   */
  public static formatDateTime(date: Date): string {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    const seconds = String(date.getSeconds()).padStart(2, '0');
    return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`;
  }

  /**
   * 时间戳转
   * @param timestamp
   * @returns
   */
  public static formatDateTimestamp(timestamp: number | null | undefined): string {
    if (timestamp === null || timestamp === undefined || timestamp <= 0) {
      return '-';
    }
    const date = new Date(timestamp * 1000);
    return UiUtil.formatDateTime(date);
  }

  /**
   * 只转年月日
   * @param date
   * @returns
   */
  public static formatDate(date: Date): string {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  public static formatDuration(totalSeconds: number): string {
    const hours = Math.floor(totalSeconds / 3600);
    const minutes = Math.floor((totalSeconds % 3600) / 60);
    const seconds = totalSeconds % 60;
    return `${hours}:${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`;
  }

  public static parseDate(value: string, hour: number, minute: number, second: number,
    millisecond: number): Date | null {
    const parts = value.trim().split('-');
    if (parts.length !== 3) {
      return null;
    }
    const year = Number(parts[0]);
    const month = Number(parts[1]);
    const day = Number(parts[2]);
    if (!Number.isInteger(year) || !Number.isInteger(month) || !Number.isInteger(day)) {
      return null;
    }
    const date = new Date(year, month - 1, day, hour, minute, second, millisecond);
    if (date.getFullYear() !== year || date.getMonth() !== month - 1 || date.getDate() !== day) {
      return null;
    }
    return date;
  }

  public static codeToNumber(code: number | string): number | null {
    if (typeof code === 'number') {
      return code;
    }
    const parsed = Number(code);
    return Number.isNaN(parsed) ? null : parsed;
  }

  public static lengthToNumber(value: Length): number {
    if (typeof value === 'number') {
      return value;
    }
    const parsed = Number.parseFloat(String(value));
    return Number.isNaN(parsed) ? 0 : parsed;
  }

  public static formatNumber(value: number | null): string {
    if (value === null || Number.isNaN(value)) {
      return '-';
    }
    return value.toFixed(3);
  }
}