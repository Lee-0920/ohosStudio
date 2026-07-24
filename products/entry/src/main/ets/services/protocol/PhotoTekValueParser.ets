import { PhotoTekFirmwareVersion, PhotoTekTimeValue } from './PhotoTekTypes';

export class PhotoTekValueParser {
  /**
   * 按 Modbus 大端顺序解析 1 个无符号 16 位寄存器。
   *
   * @param data 输入寄存器响应数据区，不包含功能码和字节数。
   * @param offset 数据区内起始字节偏移，默认从 0 开始。
   * @returns 成功返回 0~65535 的整数；数据长度不足时返回 null。
   */
  static parseUInt16(data: Uint8Array, offset: number = 0): number | null {
    if (data.length < offset + 2) {
      return null;
    }
    return (data[offset] << 8) | data[offset + 1];
  }

  /**
   * 解析 PhotoTek 协议 CDAB 字节序的 IEEE754 单精度浮点数。
   *
   * @param data 输入寄存器响应数据区，不包含功能码和字节数。
   * @param offset 数据区内起始字节偏移，默认从 0 开始。
   * @returns 成功返回浮点数；数据长度不足时返回 null。
   */
  static parseFloatCdab(data: Uint8Array, offset: number = 0): number | null {
    if (data.length < offset + 4) {
      return null;
    }
    const floatBytes = new Uint8Array([
      data[offset + 2],
      data[offset + 3],
      data[offset],
      data[offset + 1]
    ]);
    const view = new DataView(floatBytes.buffer);
    return view.getFloat32(0, false);
  }

  /**
   * 按 CDAB 字节序连续解析多个浮点数。
   *
   * @param data 输入寄存器响应数据区，不包含功能码和字节数。
   * @param count 需要解析的浮点数数量。
   * @returns 成功返回浮点数组；任一数据段长度不足时返回 null。
   */
  static parseFloatCdabArray(data: Uint8Array, count: number): number[] | null {
    const values: number[] = [];
    for (let i = 0; i < count; i++) {
      const value = PhotoTekValueParser.parseFloatCdab(data, i * 4);
      if (value === null) {
        return null;
      }
      values.push(value);
    }
    return values;
  }

  /**
   * 解析 PhotoTek 时间类型，3 个寄存器依次存储年偏移、月、日、时、分、秒。
   *
   * @param data 输入寄存器响应数据区，不包含功能码和字节数。
   * @returns 成功返回结构化时间；数据长度不足时返回 null。
   */
  static parseTime(data: Uint8Array): PhotoTekTimeValue | null {
    if (data.length < 6) {
      return null;
    }
    const year = 1970 + data[0];
    const month = data[1];
    const day = data[2];
    const hour = data[3];
    const minute = data[4];
    const second = data[5];
    const timeValue: PhotoTekTimeValue = {
      year,
      month,
      day,
      hour,
      minute,
      second,
      text: `${year}-${PhotoTekValueParser.pad2(month)}-${PhotoTekValueParser.pad2(day)} ` +
        `${PhotoTekValueParser.pad2(hour)}:${PhotoTekValueParser.pad2(minute)}:${PhotoTekValueParser.pad2(second)}`
    };
    return timeValue;
  }

  /**
   * 解析 UTF-16BE 字符串寄存器，遇到 0x0000 填充字符停止。
   *
   * @param data 输入寄存器响应数据区，不包含功能码和字节数。
   * @returns 返回去除尾部空白后的字符串。
   */
  static parseUtf16String(data: Uint8Array): string {
    let text = '';
    for (let i = 0; i + 1 < data.length; i += 2) {
      const codePoint = (data[i] << 8) | data[i + 1];
      if (codePoint === 0) {
        break;
      }
      text += String.fromCharCode(codePoint);
    }
    return text.trim();
  }

  /**
   * 解析 1 个字符寄存器，通常用于数据标识，如 N/T/L/D。
   *
   * @param data 输入寄存器响应数据区，不包含功能码和字节数。
   * @returns 成功返回字符；数据长度不足或空字符时返回 null。
   */
  static parseRegisterChar(data: Uint8Array): string | null {
    const codePoint = PhotoTekValueParser.parseUInt16(data);
    if (codePoint === null || codePoint === 0) {
      return null;
    }
    return String.fromCharCode(codePoint);
  }

  /**
   * 解析 2 个寄存器组成的板卡固件版本号。
   *
   * @param data 输入寄存器响应数据区，不包含功能码和字节数。
   * @returns 成功返回版本结构；数据长度不足时返回 null。
   */
  static parseFirmwareVersion(data: Uint8Array): PhotoTekFirmwareVersion | null {
    if (data.length < 4) {
      return null;
    }
    const version: PhotoTekFirmwareVersion = {
      major: data[0],
      minor: data[1],
      revision: data[2],
      build: data[3],
      text: `${data[0]}.${data[1]}.${data[2]}.${data[3]}`
    };
    return version;
  }

  /**
   * 将 0~65535 整数编码为 1 个保持寄存器值。
   *
   * @param value 需要写入的无符号 16 位整数。
   * @returns 成功返回寄存器值；超出范围或非整数时返回 null。
   */
  static encodeUInt16(value: number): number | null {
    if (value < 0 || value > 0xFFFF || Math.floor(value) !== value) {
      return null;
    }
    return value;
  }

  /**
   * 将 IEEE754 单精度浮点数编码为 PhotoTek CDAB 字节序的 2 个保持寄存器值。
   *
   * @param value 需要写入的浮点数。
   * @returns 成功返回 2 个寄存器值；非法数值时返回 null。
   */
  static encodeFloatCdab(value: number): number[] | null {
    if (value !== value) {
      return null;
    }
    const buffer = new ArrayBuffer(4);
    const view = new DataView(buffer);
    view.setFloat32(0, value, false);
    const bytes = new Uint8Array(buffer);
    return [
      (bytes[2] << 8) | bytes[3],
      (bytes[0] << 8) | bytes[1]
    ];
  }

  /**
   * 将时间字段编码为 PhotoTek 时间类型的 3 个保持寄存器值。
   *
   * @param year 完整年份，协议按 year - 1970 写入。
   * @param month 月份，取值 1~12。
   * @param day 日期，取值 1~31。
   * @param hour 小时，取值 0~23。
   * @param minute 分钟，取值 0~59。
   * @param second 秒，取值 0~59。
   * @returns 成功返回 3 个寄存器值；字段越界时返回 null。
   */
  static encodeTimeRegisters(
    year: number,
    month: number,
    day: number,
    hour: number,
    minute: number,
    second: number
  ): number[] | null {
    const yearOffset = year - 1970;
    if (!PhotoTekValueParser.isByte(yearOffset) ||
      !PhotoTekValueParser.isByte(month) ||
      !PhotoTekValueParser.isByte(day) ||
      !PhotoTekValueParser.isByte(hour) ||
      !PhotoTekValueParser.isByte(minute) ||
      !PhotoTekValueParser.isByte(second) ||
      month < 1 ||
      month > 12 ||
      day < 1 ||
      day > 31 ||
      hour > 23 ||
      minute > 59 ||
      second > 59) {
      return null;
    }

    return [
      (yearOffset << 8) | month,
      (day << 8) | hour,
      (minute << 8) | second
    ];
  }

  /**
   * 将数值格式化为两位字符串。
   *
   * @param value 需要格式化的数值。
   * @returns 不足两位时左侧补 0 的字符串。
   */
  private static pad2(value: number): string {
    return value.toString().padStart(2, '0');
  }

  /**
   * 判断数值是否为 0~255 的整数字节。
   *
   * @param value 待检查数值。
   * @returns 是合法字节时返回 true，否则返回 false。
   */
  private static isByte(value: number): boolean {
    return value >= 0 && value <= 0xFF && Math.floor(value) === value;
  }
}
