import { BoardInfo, BoardFirmwareInfo, InstrumentInfo } from '../models/deviceTypes';
import { WqSystemInfoItem, WqSystemTableRow } from '../models/monitorTypes';
import { PhotoTekFirmwareVersion } from './protocol/PhotoTekTypes';

export type SystemInfoSessionListener = () => void;

// 会话级系统信息缓存。页面切换销毁后，当前会话内已读到的仪器/板卡信息仍保留。
export class SystemInfoSessionStore {
  private static readonly EMPTY_VALUE: string = '-';

  private static instrumentInfo: InstrumentInfo | null = null;
  private static boardInfo: BoardInfo | null = null;
  private static measurementProjectName: string | null = null;
  private static instrumentInfoRows: WqSystemInfoItem[] = SystemInfoSessionStore.buildInstrumentInfoRows(null);
  private static boardInfoRows: WqSystemTableRow[] = SystemInfoSessionStore.buildBoardInfoRows(null);
  private static listeners: SystemInfoSessionListener[] = [];

  static getInstrumentInfo(): InstrumentInfo | null {
    return SystemInfoSessionStore.instrumentInfo
      ? SystemInfoSessionStore.cloneInstrumentInfo(SystemInfoSessionStore.instrumentInfo)
      : null;
  }

  static getBoardInfo(): BoardInfo | null {
    return SystemInfoSessionStore.boardInfo
      ? SystemInfoSessionStore.cloneBoardInfo(SystemInfoSessionStore.boardInfo)
      : null;
  }

  static getInstrumentInfoRows(): WqSystemInfoItem[] {
    return SystemInfoSessionStore.cloneInstrumentInfoRows(SystemInfoSessionStore.instrumentInfoRows);
  }

  static getBoardInfoRows(): WqSystemTableRow[] {
    return SystemInfoSessionStore.cloneBoardInfoRows(SystemInfoSessionStore.boardInfoRows);
  }

  static updateInstrumentInfo(info: InstrumentInfo): void {
    SystemInfoSessionStore.instrumentInfo = SystemInfoSessionStore.cloneInstrumentInfo(info);
    SystemInfoSessionStore.instrumentInfoRows =
      SystemInfoSessionStore.buildInstrumentInfoRows(SystemInfoSessionStore.instrumentInfo);
    SystemInfoSessionStore.notifyListeners();
  }

  static updateMeasurementProject(name: string): void {
    SystemInfoSessionStore.measurementProjectName = name;
    SystemInfoSessionStore.instrumentInfoRows =
      SystemInfoSessionStore.buildInstrumentInfoRows(SystemInfoSessionStore.instrumentInfo);
    SystemInfoSessionStore.notifyListeners();
  }

  static updateBoardInfo(info: BoardInfo): void {
    SystemInfoSessionStore.boardInfo = SystemInfoSessionStore.cloneBoardInfo(info);
    SystemInfoSessionStore.boardInfoRows = SystemInfoSessionStore.buildBoardInfoRows(SystemInfoSessionStore.boardInfo);
    SystemInfoSessionStore.notifyListeners();
  }

  static addListener(listener: SystemInfoSessionListener): void {
    if (SystemInfoSessionStore.listeners.indexOf(listener) >= 0) {
      return;
    }
    SystemInfoSessionStore.listeners.push(listener);
  }

  static removeListener(listener: SystemInfoSessionListener): void {
    SystemInfoSessionStore.listeners = SystemInfoSessionStore.listeners.filter((item: SystemInfoSessionListener) => {
      return item !== listener;
    });
  }

  private static notifyListeners(): void {
    SystemInfoSessionStore.listeners.forEach((listener: SystemInfoSessionListener) => {
      listener();
    });
  }

  private static buildInstrumentInfoRows(info: InstrumentInfo | null): WqSystemInfoItem[] {
    const rows: WqSystemInfoItem[] = [
      SystemInfoSessionStore.createInfoItem('仪器型号', info ? info.productModel : null),
      SystemInfoSessionStore.createInfoItem('仪器名称', info ? info.productName : null),
      SystemInfoSessionStore.createInfoItem('测定项目', SystemInfoSessionStore.measurementProjectName),
      SystemInfoSessionStore.createInfoItem('仪器型码', null),
      SystemInfoSessionStore.createInfoItem('序列号', info ? info.serialNumber : null),
      SystemInfoSessionStore.createInfoItem('仪器版本', null),
      SystemInfoSessionStore.createInfoItem('平台版本', null),
      SystemInfoSessionStore.createInfoItem('生产厂商', info ? info.manufacturer : null)
    ];
    return rows;
  }

  private static buildBoardInfoRows(info: BoardInfo | null): WqSystemTableRow[] {
    const rows: WqSystemTableRow[] = [
      SystemInfoSessionStore.createBoardRow('main-type', '主控板', '类型', null),
      SystemInfoSessionStore.createBoardRow('main-model', '', '型号', null),
      SystemInfoSessionStore.createBoardRow('main-serial', '', '序列号', null),
      SystemInfoSessionStore.createBoardRow('main-factory', '', '生产厂商', null),
      SystemInfoSessionStore.createBoardRow('main-date', '', '生产日期', null),
      SystemInfoSessionStore.createBoardRow(
        'main-software',
        '',
        '软件版本',
        info ? SystemInfoSessionStore.formatFirmware(info.mainBoard.firmwareVersion) : null
      ),
      SystemInfoSessionStore.createBoardRow('main-kernel', '', '内核版本', null),
      SystemInfoSessionStore.createBoardRow('main-file-system', '', '文件系统版本', null),
      SystemInfoSessionStore.createBoardRow('main-hardware', '', '硬件版本', null),
      SystemInfoSessionStore.createBoardRow('drive-type', '驱动板', '类型', null),
      SystemInfoSessionStore.createBoardRow('drive-model', '', '型号', null),
      SystemInfoSessionStore.createBoardRow(
        'drive-software',
        '',
        '软件版本',
        info ? SystemInfoSessionStore.formatFirmware(info.driverBoard.firmwareVersion) : null
      ),
      SystemInfoSessionStore.createBoardRow('drive-hardware', '', '硬件版本', null)
    ];
    return rows;
  }

  private static createInfoItem(label: string, value: string | null): WqSystemInfoItem {
    const item: WqSystemInfoItem = {
      label,
      value: SystemInfoSessionStore.formatText(value)
    };
    return item;
  }

  private static createBoardRow(
    id: string,
    category: string,
    item: string,
    value: string | null
  ): WqSystemTableRow {
    const row: WqSystemTableRow = {
      id,
      category,
      item,
      value: SystemInfoSessionStore.formatText(value)
    };
    return row;
  }

  private static formatText(value: string | null): string {
    if (value === null) {
      return SystemInfoSessionStore.EMPTY_VALUE;
    }
    const trimmed = value.trim();
    return trimmed.length > 0 ? trimmed : SystemInfoSessionStore.EMPTY_VALUE;
  }

  private static formatFirmware(value: PhotoTekFirmwareVersion | null): string {
    return value ? SystemInfoSessionStore.formatText(value.text) : SystemInfoSessionStore.EMPTY_VALUE;
  }

  private static cloneInstrumentInfo(info: InstrumentInfo): InstrumentInfo {
    const cloned: InstrumentInfo = {
      productName: info.productName,
      productModel: info.productModel,
      manufacturer: info.manufacturer,
      serialNumber: info.serialNumber
    };
    return cloned;
  }

  private static cloneBoardInfo(info: BoardInfo): BoardInfo {
    const cloned: BoardInfo = {
      liquidBoard: SystemInfoSessionStore.cloneBoardFirmwareInfo(info.liquidBoard),
      temperatureBoard: SystemInfoSessionStore.cloneBoardFirmwareInfo(info.temperatureBoard),
      signalBoard: SystemInfoSessionStore.cloneBoardFirmwareInfo(info.signalBoard),
      mainBoard: SystemInfoSessionStore.cloneBoardFirmwareInfo(info.mainBoard),
      driverBoard: SystemInfoSessionStore.cloneBoardFirmwareInfo(info.driverBoard),
      reactionBoard: SystemInfoSessionStore.cloneBoardFirmwareInfo(info.reactionBoard)
    };
    return cloned;
  }

  private static cloneBoardFirmwareInfo(info: BoardFirmwareInfo): BoardFirmwareInfo {
    const cloned: BoardFirmwareInfo = {
      boardKey: info.boardKey,
      boardName: info.boardName,
      firmwareVersion: info.firmwareVersion ? SystemInfoSessionStore.cloneFirmwareVersion(info.firmwareVersion) : null
    };
    return cloned;
  }

  private static cloneFirmwareVersion(info: PhotoTekFirmwareVersion): PhotoTekFirmwareVersion {
    const cloned: PhotoTekFirmwareVersion = {
      major: info.major,
      minor: info.minor,
      revision: info.revision,
      build: info.build,
      text: info.text
    };
    return cloned;
  }

  private static cloneInstrumentInfoRows(rows: WqSystemInfoItem[]): WqSystemInfoItem[] {
    const clonedRows: WqSystemInfoItem[] = [];
    rows.forEach((item: WqSystemInfoItem) => {
      const cloned: WqSystemInfoItem = {
        label: item.label,
        value: item.value
      };
      clonedRows.push(cloned);
    });
    return clonedRows;
  }

  private static cloneBoardInfoRows(rows: WqSystemTableRow[]): WqSystemTableRow[] {
    const clonedRows: WqSystemTableRow[] = [];
    rows.forEach((item: WqSystemTableRow) => {
      const cloned: WqSystemTableRow = {
        id: item.id,
        category: item.category,
        item: item.item,
        value: item.value
      };
      clonedRows.push(cloned);
    });
    return clonedRows;
  }
}
