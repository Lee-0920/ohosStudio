/**
 * 日期时间工具类
 */
export class DateTimeUtil {
  /**
   * 获取当前时间戳（秒）
   */
  static getTimestamp(): number {
    return Math.floor(Date.now() / 1000);
  }

  /**
   * 获取日期时间对象
   */
  static getDateTime(timestamp: number): Date {
    return new Date(timestamp * 1000);
  }

  /**
   * 时间戳转日期时间对象（包含时分秒）
   */
  static getDateTimeComponents(timestamp: number): [
    day: number,
    hour: number,
    minute: number,
    second: number,
  ] {
    const date = new Date(timestamp * 1000);
    let day = date.getDate();
    let hour = date.getHours();
    let minute = date.getMinutes();
    let second = date.getSeconds();
    return [day, hour, minute, second];
  }

  /**
   * 日期时间对象转时间戳
   */
  static toTimestamp(date: Date): number {
    return Math.floor(date.getTime() / 1000);
  }

  /**
   * 创建指定时间的时间戳
   */
  static createTimestamp(day: number, hour: number, minute: number = 0, second: number = 0): number {
    const date = new Date();
    date.setDate(day);
    date.setHours(hour);
    date.setMinutes(minute);
    date.setSeconds(second);
    return Math.floor(date.getTime() / 1000);
  }
}