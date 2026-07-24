import { UiUtil } from 'base';
import {
  BoardInfo,
  DeviceRuntimeStatus,
  InstrumentInfo,
  MeasurementConfig,
  MeasurementSnapshot
} from '../../models/deviceTypes';
import { CommunicationMode, MonitorService } from '../../services/MonitorService';
import {
  PhotoTekCodeDescription,
  PhotoTekDataFlag,
  PhotoTekFirmwareVersion,
  PhotoTekMeasurementParameterInfo,
  PhotoTekTemperatureValue,
  PhotoTekTimeValue
} from '../../services/protocol/PhotoTekTypes';
import { SystemActionButton } from './SystemControls';

interface DebugAction {
  id: string;
  label: string;
  request: string;
  run: () => Promise<string>;
}

@Component
export struct DebugPanel {
  @Prop viewportWidth: number = 1024;
  @Prop viewportHeight: number = 768;
  @Prop scaleFactor: number = 1.92;
  @State private communicationMode: CommunicationMode = 'uart';
  @State private tcpIp: string = '192.168.0.110';
  @State private tcpPort: string = '502';
  @State private uartPath: string = '/dev/ttyS7';
  @State private uartBaudRate: string = '9600';
  @State private uartDataBits: string = '8';
  @State private uartStopBits: string = '1';
  @State private uartParity: string = 'N';
  @State private controlCode: string = '0';
  @State private waterCollectionEnabled: string = '0';
  @State private currentRange: string = '10';
  @State private calibrationSlope: string = '1';
  @State private calibrationIntercept: string = '0';
  @State private digestionTemperature: string = '165';
  @State private digestionSeconds: string = '900';
  @State private reactionTemperature: string = '60';
  @State private reactionSeconds: string = '300';
  @State private correctionFactor: string = '1';
  @State private systemYear: string = '2026';
  @State private systemMonth: string = '06';
  @State private systemDay: string = '04';
  @State private systemHour: string = '12';
  @State private systemMinute: string = '00';
  @State private systemSecond: string = '00';
  @State private measurementMode: string = '0';
  @State private autoMeasurementHours: string = '24';
  @State private autoCalibrationMode: string = '1';
  @State private autoCalibrationHours: string = '168';
  @State private logText: string = '';
  @State private runningAction: string = '';
  onSystemAction: () => void = () => {
  };
  private readonly communicationModeOptions: SelectOption[] = [
    { value: 'tcp' },
    { value: 'uart' }
  ];
  private readonly baudRateOptions: SelectOption[] = [
    { value: '2400' },
    { value: '4800' },
    { value: '9600' },
    { value: '19200' },
    { value: '38400' },
    { value: '57600' },
    { value: '115200' }
  ];
  private readonly dataBitsOptions: SelectOption[] = [
    { value: '7' },
    { value: '8' }
  ];
  private readonly stopBitsOptions: SelectOption[] = [
    { value: '1' },
    { value: '2' }
  ];
  private readonly parityOptions: SelectOption[] = [
    { value: 'N' },
    { value: 'E' },
    { value: 'O' }
  ];
  private readonly switchOptions: SelectOption[] = [
    { value: '0' },
    { value: '1' }
  ];
  private readonly measurementModeOptions: SelectOption[] = [
    { value: '0' },
    { value: '1' },
    { value: '2' },
    { value: '3' }
  ];
  private readonly autoCalibrationModeOptions: SelectOption[] = [
    { value: '0' },
    { value: '1' },
    { value: '2' }
  ];

  aboutToAppear(): void {
    this.communicationMode = MonitorService.getCommunicationMode();
  }

  private pad2(value: number): string {
    return value.toString().padStart(2, '0');
  }

  private nowText(): string {
    const now = new Date();
    return `${this.pad2(now.getHours())}:${this.pad2(now.getMinutes())}:${this.pad2(now.getSeconds())}`;
  }

  private addLog(message: string): void {
    const next = `[${this.nowText()}] ${message}`;
    const merged = this.logText.length > 0 ? `${this.logText}\n${next}` : next;
    this.logText = merged.length > 20000 ? merged.slice(merged.length - 20000) : merged;
  }

  private clearLog(): void {
    this.logText = '';
  }

  private formatError(err: Error): string {
    const text = String(err);
    const json = JSON.stringify(err);
    return json && json !== '{}' ? `${text}, json=${json}` : text;
  }

  private parseNumber(value: string): number | null {
    const parsed = Number.parseFloat(value.trim());
    if (Number.isNaN(parsed)) {
      return null;
    }
    return parsed;
  }

  private parseIntValue(value: string): number | null {
    const parsed = Number.parseInt(value.trim(), 10);
    if (Number.isNaN(parsed)) {
      return null;
    }
    return parsed;
  }

  private formatInputError(label: string, value: string): string {
    return `参数错误: ${label}=${value}`;
  }

  private formatNullableText(value: string | null, emptyText: string = '读取失败，Service 返回 null'): string {
    return value === null ? emptyText : value;
  }

  private formatNumberResult(label: string, value: number | null, unit: string = ''): string {
    if (value === null) {
      return `${label}: 读取失败，Service 返回 null`;
    }
    return `${label}: ${value}${unit.length > 0 ? ' ' + unit : ''}`;
  }

  private formatWriteResult(ok: boolean): string {
    return ok ? '写入成功' : '写入失败，Service 返回 false';
  }

  private formatCodeDescription(value: PhotoTekCodeDescription | null): string {
    if (!value) {
      return 'null';
    }
    return `${value.code} / ${value.label}`;
  }

  private formatDataFlag(value: PhotoTekDataFlag | null): string {
    if (!value) {
      return 'null';
    }
    return `${value.code} / ${value.label}`;
  }

  private formatTime(value: PhotoTekTimeValue | null): string {
    return value ? value.text : 'null';
  }

  private formatFirmware(value: PhotoTekFirmwareVersion | null): string {
    return value ? value.text : 'null';
  }

  private formatParameterInfo(value: PhotoTekMeasurementParameterInfo | null): string {
    if (!value) {
      return '读取失败，Service 返回 null';
    }
    return `参数: ${value.name}, code=${value.code}, legacy=${value.legacyCode}, unit=${value.unit}`;
  }

  private formatTemperatures(value: PhotoTekTemperatureValue | null): string {
    if (!value) {
      return 'null';
    }
    return `消解室=${value.digestionTemperature} ${value.unit}, 环境=${value.ambientTemperature} ${value.unit}`;
  }

  private formatRuntimeStatus(value: DeviceRuntimeStatus | null): string {
    if (!value) {
      return '读取失败，Service 返回 null';
    }
    const lines: string[] = [
      `连接状态: ${value.connected ? '已连接' : '未连接'}`,
      `系统状态: ${this.formatCodeDescription(value.systemStatus)}`,
      `当前动作: ${this.formatCodeDescription(value.currentAction)}`,
      `当前温度: ${this.formatTemperatures(value.temperatures)}`,
      `报警时间: ${this.formatTime(value.alarmTime)}`,
      `报警代码: ${this.formatCodeDescription(value.alarmCode)}`
    ];
    return lines.join('\n  ');
  }

  private formatSnapshot(value: MeasurementSnapshot | null): string {
    if (!value) {
      return '读取失败，Service 返回 null';
    }
    const lines: string[] = [
      this.formatParameterInfo(value.parameter),
      `测量结果: ${value.result} ${value.resultUnit}`,
      `结果类型: ${this.formatCodeDescription(value.resultType)}`,
      `测量时长: ${value.measurementDurationSeconds === null ? 'null' : value.measurementDurationSeconds + ' 秒'}`,
      `测量时间: ${this.formatTime(value.measurementTime)}`,
      `校准液结果: ${value.calibrationSolutionResult === null ? 'null' : value.calibrationSolutionResult}`,
      `校准液时间: ${this.formatTime(value.calibrationSolutionTime)}`,
      `校准时间: ${this.formatTime(value.calibrationTime)}`,
      `跨度核查结果: ${value.spanCheckResult === null ? 'null' : value.spanCheckResult}`,
      `跨度核查时间: ${this.formatTime(value.spanCheckTime)}`,
      `数据标识: ${this.formatDataFlag(value.dataFlag)}`
    ];
    return lines.join('\n  ');
  }

  private formatInstrumentInfo(value: InstrumentInfo | null): string {
    if (!value) {
      return '读取失败，Service 返回 null';
    }
    const lines: string[] = [
      `产品名称: ${value.productName}`,
      `产品型号: ${value.productModel}`,
      `生产厂商: ${value.manufacturer}`,
      `序列号: ${value.serialNumber}`
    ];
    return lines.join('\n  ');
  }

  private formatBoardInfo(value: BoardInfo | null): string {
    if (!value) {
      return '读取失败，Service 返回 null';
    }
    const lines: string[] = [
      `${value.liquidBoard.boardName}: ${this.formatFirmware(value.liquidBoard.firmwareVersion)}`,
      `${value.temperatureBoard.boardName}: ${this.formatFirmware(value.temperatureBoard.firmwareVersion)}`,
      `${value.signalBoard.boardName}: ${this.formatFirmware(value.signalBoard.firmwareVersion)}`,
      `${value.mainBoard.boardName}: ${this.formatFirmware(value.mainBoard.firmwareVersion)}`,
      `${value.driverBoard.boardName}: ${this.formatFirmware(value.driverBoard.firmwareVersion)}`,
      `${value.reactionBoard.boardName}: ${this.formatFirmware(value.reactionBoard.firmwareVersion)}`
    ];
    return lines.join('\n  ');
  }

  private formatMeasurementConfig(value: MeasurementConfig | null): string {
    if (!value) {
      return '读取失败，Service 返回 null';
    }
    const lines: string[] = [
      `当前量程: ${value.currentRange} mg/L`,
      `量程表: ${value.rangeTable ? value.rangeTable.join(', ') : 'null'}`,
      `测量模式: ${this.formatCodeDescription(value.measurementMode)}`,
      `自动测量间隔: ${value.autoMeasurementIntervalHours === null ? 'null' :
        value.autoMeasurementIntervalHours + ' 小时'}`,
      `自动校准模式: ${this.formatCodeDescription(value.autoCalibrationMode)}`,
      `自动校准间隔: ${value.autoCalibrationIntervalHours === null ? 'null' :
        value.autoCalibrationIntervalHours + ' 小时'}`,
      `校准曲线斜率: ${value.calibrationCurveSlope === null ? 'null' : value.calibrationCurveSlope}`,
      `校准曲线截距: ${value.calibrationCurveIntercept === null ? 'null' : value.calibrationCurveIntercept}`,
      `消解温度: ${value.digestionTemperature === null ? 'null' : value.digestionTemperature + ' ℃'}`,
      `消解时间: ${value.digestionTimeSeconds === null ? 'null' : value.digestionTimeSeconds + ' 秒'}`,
      `反应温度: ${value.reactionTemperature === null ? 'null' : value.reactionTemperature + ' ℃'}`,
      `反应时间: ${value.reactionTimeSeconds === null ? 'null' : value.reactionTimeSeconds + ' 秒'}`,
      `修正因子: ${value.correctionFactor === null ? 'null' : value.correctionFactor}`,
      `当前量程稀释倍数: ${value.currentRangeDilutionFactor === null ? 'null' : value.currentRangeDilutionFactor}`,
      `零点校准液浓度: ${value.zeroCalibrationSolutionConcentration === null ? 'null' :
        value.zeroCalibrationSolutionConcentration}`,
      `量程校准液浓度: ${value.spanCalibrationSolutionConcentration === null ? 'null' :
        value.spanCalibrationSolutionConcentration}`,
      `试剂体积: ${value.reagentOneVolume}, ${value.reagentTwoVolume}, ${value.reagentThreeVolume}, ${value.reagentFourVolume}, ${value.reagentFiveVolume}`,
      `当前量程校正因子: ${value.currentRangeCorrectionFactor === null ? 'null' : value.currentRangeCorrectionFactor}`,
      `核查允许偏差: ${value.spanCheckAllowedDeviation === null ? 'null' : value.spanCheckAllowedDeviation + '%'}`,
      `核查偏差: ${value.spanCheckDeviation === null ? 'null' : value.spanCheckDeviation + '%'}`
    ];
    return lines.join('\n  ');
  }

  private async runAction(action: DebugAction): Promise<void> {
    if (this.runningAction.length > 0) {
      this.addLog(`忙碌中: ${this.runningAction} 尚未完成`);
      return;
    }

    this.runningAction = action.label;
    this.addLog(`发送: ${action.label}\n  ${action.request}\n  通道: ${MonitorService.getCommunicationMode()}`);
    try {
      const result = await action.run();
      this.addLog(`接收: ${action.label}\n  ${result}`);
    } catch (err) {
      this.addLog(`异常: ${action.label}\n  ${this.formatError(err as Error)}`);
    } finally {
      this.runningAction = '';
      this.onSystemAction();
    }
  }

  private getConnectionActions(): DebugAction[] {
    return [
      {
        id: 'apply-mode',
        label: '应用通道',
        request: 'MonitorService.setMode / setMcuConfig / setUartConfig',
        run: async (): Promise<string> => {
          const port = this.parseIntValue(this.tcpPort);
          const baud = this.parseIntValue(this.uartBaudRate);
          const dataBits = this.parseIntValue(this.uartDataBits);
          const stopBits = this.parseIntValue(this.uartStopBits);
          if (port === null) {
            return this.formatInputError('TCP端口', this.tcpPort);
          }
          if (baud === null || dataBits === null || stopBits === null) {
            return '参数错误: UART 串口参数无效';
          }
          MonitorService.setMcuConfig(this.tcpIp.trim(), port);
          MonitorService.setUartConfig(this.uartPath.trim(), baud, dataBits, stopBits, this.uartParity);
          MonitorService.setMode(this.communicationMode);
          return `已应用通道=${this.communicationMode}, TCP=${this.tcpIp.trim()}:${port}, UART=${this.uartPath.trim()} ${baud} ${dataBits}${this.uartParity}${stopBits}`;
        }
      },
      {
        id: 'connect',
        label: '连接设备',
        request: 'MonitorService.connect()',
        run: async (): Promise<string> => {
          const ok = await MonitorService.connect();
          return ok ? '连接成功' : '连接失败';
        }
      },
      {
        id: 'disconnect',
        label: '断开设备',
        request: 'MonitorService.disconnect()',
        run: async (): Promise<string> => {
          MonitorService.disconnect();
          return '已断开当前设备通道';
        }
      },
      {
        id: 'status',
        label: '连接状态',
        request: 'MonitorService.isConnectedToMcu() / getCommunicationMode()',
        run: async (): Promise<string> => {
          return `通道=${MonitorService.getCommunicationMode()}, 连接=${MonitorService.isConnectedToMcu() ? '已连接' :
            '未连接'}, 测量=${MonitorService.isMeasurementRunning() ? '运行中' : '空闲'}`;
        }
      }
    ];
  }

  private getMeasurementReadActions(): DebugAction[] {
    return [
      {
        id: 'read-param-info',
        label: '读测量参数',
        request: '0x04 输入寄存器 4, count=1',
        run: async (): Promise<string> => this.formatParameterInfo(await MonitorService.readMeasurementParameterInfo())
      },
      {
        id: 'read-result',
        label: '读测量结果',
        request: '0x04 输入寄存器 0, count=2, CDAB float',
        run: async (): Promise<string> => this.formatNumberResult('测量结果',
          await MonitorService.readMeasurementResult(), 'mg/L')
      },
      {
        id: 'read-cal-result',
        label: '读校准液结果',
        request: '0x04 输入寄存器 2, count=2, CDAB float',
        run: async (): Promise<string> => this.formatNumberResult('测量校准液结果',
          await MonitorService.readMeasurementCalibrationSolutionResult(), 'mg/L')
      },
      {
        id: 'read-snapshot',
        label: '读测量快照',
        request: '聚合读取测量参数、结果、类型、时间、校准/核查字段',
        run: async (): Promise<string> => this.formatSnapshot(await MonitorService.readMeasurementSnapshot())
      },
      {
        id: 'read-result-type',
        label: '读结果类型',
        request: '0x04 输入寄存器 5, count=1',
        run: async (): Promise<string> => `测试结果类型: ${this.formatCodeDescription(
          await MonitorService.readMeasurementResultType())}`
      },
      {
        id: 'read-duration',
        label: '读测量时长',
        request: '0x04 输入寄存器 6, count=1',
        run: async (): Promise<string> => this.formatNumberResult('测量时长',
          await MonitorService.readMeasurementDurationSeconds(), '秒')
      },
      {
        id: 'read-measure-time',
        label: '读测量时间',
        request: '0x04 输入寄存器 7, count=3',
        run: async (): Promise<string> => `测量时间: ${this.formatTime(await MonitorService.readMeasurementTime())}`
      },
      {
        id: 'read-cal-solution-time',
        label: '读校准液时间',
        request: '0x04 输入寄存器 10, count=3',
        run: async (): Promise<string> => `校准液时间: ${this.formatTime(
          await MonitorService.readCalibrationSolutionTime())}`
      },
      {
        id: 'read-cal-time',
        label: '读校准时间',
        request: '0x04 输入寄存器 13, count=3',
        run: async (): Promise<string> => `校准时间: ${this.formatTime(await MonitorService.readCalibrationTime())}`
      },
      {
        id: 'read-span-result',
        label: '读跨度核查结果',
        request: '0x04 输入寄存器 165, count=2',
        run: async (): Promise<string> => this.formatNumberResult('跨度核查结果',
          await MonitorService.readSpanCheckResult(), 'mg/L')
      },
      {
        id: 'read-span-time',
        label: '读跨度核查时间',
        request: '0x04 输入寄存器 167, count=3',
        run: async (): Promise<string> => `跨度核查时间: ${this.formatTime(await MonitorService.readSpanCheckTime())}`
      }
    ];
  }

  private getStatusReadActions(): DebugAction[] {
    return [
      {
        id: 'read-runtime',
        label: '读运行状态',
        request: '聚合读取系统状态、当前动作、温度、报警',
        run: async (): Promise<string> => this.formatRuntimeStatus(await MonitorService.readRuntimeStatus())
      },
      {
        id: 'read-system-status',
        label: '读系统状态',
        request: '0x04 输入寄存器 16, count=1',
        run: async (): Promise<string> => `系统状态: ${this.formatCodeDescription(
          await MonitorService.readSystemStatus())}`
      },
      {
        id: 'read-current-action',
        label: '读当前动作',
        request: '0x04 输入寄存器 17, count=1',
        run: async (): Promise<string> => `当前动作: ${this.formatCodeDescription(
          await MonitorService.readCurrentAction())}`
      },
      {
        id: 'read-current-temp',
        label: '读当前温度',
        request: '0x04 输入寄存器 18, count=4',
        run: async (): Promise<string> => `当前温度: ${this.formatTemperatures(
          await MonitorService.readCurrentTemperatures())}`
      },
      {
        id: 'read-alarm-time',
        label: '读报警时间',
        request: '0x04 输入寄存器 22, count=3',
        run: async (): Promise<string> => `报警时间: ${this.formatTime(await MonitorService.readAlarmTime())}`
      },
      {
        id: 'read-alarm-code',
        label: '读报警代码',
        request: '0x04 输入寄存器 25, count=1',
        run: async (): Promise<string> => `报警代码: ${this.formatCodeDescription(
          await MonitorService.readAlarmCode())}`
      }
    ];
  }

  private getInstrumentReadActions(): DebugAction[] {
    return [
      {
        id: 'read-instrument-info',
        label: '读仪器信息',
        request: '聚合读取产品名称、型号、厂商、序列号',
        run: async (): Promise<string> => this.formatInstrumentInfo(await MonitorService.readInstrumentInfo())
      },
      {
        id: 'read-board-info',
        label: '读板卡版本',
        request: '聚合读取液路/温控/信号/主控/驱动/反应板固件版本',
        run: async (): Promise<string> => this.formatBoardInfo(await MonitorService.readBoardInfo())
      },
      {
        id: 'read-product-name',
        label: '读产品名称',
        request: '0x04 输入寄存器 36, count=32',
        run: async (): Promise<string> => `产品名称: ${this.formatNullableText(await MonitorService.readProductName())}`
      },
      {
        id: 'read-product-model',
        label: '读产品型号',
        request: '0x04 输入寄存器 68, count=32',
        run: async (): Promise<string> => `产品型号: ${this.formatNullableText(
          await MonitorService.readProductModel())}`
      },
      {
        id: 'read-manufacturer',
        label: '读生产厂商',
        request: '0x04 输入寄存器 100, count=32',
        run: async (): Promise<string> => `生产厂商: ${this.formatNullableText(
          await MonitorService.readManufacturer())}`
      },
      {
        id: 'read-serial',
        label: '读序列号',
        request: '0x04 输入寄存器 132, count=16',
        run: async (): Promise<string> => `序列号: ${this.formatNullableText(await MonitorService.readSerialNumber())}`
      },
      {
        id: 'read-liquid-fw',
        label: '读液路板版本',
        request: '0x04 输入寄存器 148, count=2',
        run: async (): Promise<string> => `液路板固件: ${this.formatFirmware(
          await MonitorService.readLiquidBoardFirmwareVersion())}`
      },
      {
        id: 'read-temp-fw',
        label: '读温控板版本',
        request: '0x04 输入寄存器 150, count=2',
        run: async (): Promise<string> => `温控板固件: ${this.formatFirmware(
          await MonitorService.readTemperatureBoardFirmwareVersion())}`
      },
      {
        id: 'read-signal-fw',
        label: '读信号板版本',
        request: '0x04 输入寄存器 152, count=2',
        run: async (): Promise<string> => `信号板固件: ${this.formatFirmware(
          await MonitorService.readSignalBoardFirmwareVersion())}`
      },
      {
        id: 'read-main-fw',
        label: '读主控板版本',
        request: '0x04 输入寄存器 154, count=2',
        run: async (): Promise<string> => `主控板固件: ${this.formatFirmware(
          await MonitorService.readMainBoardFirmwareVersion())}`
      },
      {
        id: 'read-driver-fw',
        label: '读驱动板版本',
        request: '0x04 输入寄存器 156, count=2',
        run: async (): Promise<string> => `驱动板固件: ${this.formatFirmware(
          await MonitorService.readDriverBoardFirmwareVersion())}`
      },
      {
        id: 'read-reaction-fw',
        label: '读反应板版本',
        request: '0x04 输入寄存器 158, count=2',
        run: async (): Promise<string> => `反应板固件: ${this.formatFirmware(
          await MonitorService.readReactionBoardFirmwareVersion())}`
      }
    ];
  }

  private getOpticalReadActions(): DebugAction[] {
    return [
      {
        id: 'read-water-abs',
        label: '读水样吸光度',
        request: '0x04 输入寄存器 190, count=2',
        run: async (): Promise<string> => this.formatNumberResult('水样吸光度',
          await MonitorService.readWaterSampleAbsorbance())
      },
      {
        id: 'read-water-flag',
        label: '读水样标识',
        request: '0x04 输入寄存器 192, count=1',
        run: async (): Promise<string> => `水样数据标识: ${this.formatDataFlag(
          await MonitorService.readWaterSampleDataFlag())}`
      },
      {
        id: 'read-cal-abs',
        label: '读校准液吸光度',
        request: '0x04 输入寄存器 193, count=2',
        run: async (): Promise<string> => this.formatNumberResult('校准液吸光度',
          await MonitorService.readCalibrationSolutionAbsorbance())
      },
      {
        id: 'read-cal-flag',
        label: '读校准液标识',
        request: '0x04 输入寄存器 195, count=1',
        run: async (): Promise<string> => `校准液数据标识: ${this.formatDataFlag(
          await MonitorService.readCalibrationSolutionDataFlag())}`
      },
      {
        id: 'read-check-abs',
        label: '读核查液吸光度',
        request: '0x04 输入寄存器 199, count=2',
        run: async (): Promise<string> => this.formatNumberResult('核查液吸光度',
          await MonitorService.readCheckSolutionAbsorbance())
      },
      {
        id: 'read-check-flag',
        label: '读核查液标识',
        request: '0x04 输入寄存器 201, count=1',
        run: async (): Promise<string> => `核查液数据标识: ${this.formatDataFlag(
          await MonitorService.readCheckSolutionDataFlag())}`
      },
      {
        id: 'read-zero-conc',
        label: '读零点浓度',
        request: '0x04 输入寄存器 220, count=2',
        run: async (): Promise<string> => this.formatNumberResult('校准零点浓度',
          await MonitorService.readCalibrationZeroConcentration(), 'mg/L')
      },
      {
        id: 'read-zero-abs',
        label: '读零点吸光度',
        request: '0x04 输入寄存器 222, count=2',
        run: async (): Promise<string> => this.formatNumberResult('校准零点吸光度',
          await MonitorService.readCalibrationZeroAbsorbance())
      },
      {
        id: 'read-zero-drift',
        label: '读零点漂移',
        request: '0x04 输入寄存器 224, count=2',
        run: async (): Promise<string> => this.formatNumberResult('零点漂移', await MonitorService.readZeroDrift(), '%')
      },
      {
        id: 'read-span-conc',
        label: '读标点浓度',
        request: '0x04 输入寄存器 230, count=2',
        run: async (): Promise<string> => this.formatNumberResult('校准标点浓度',
          await MonitorService.readCalibrationSpanConcentration(), 'mg/L')
      },
      {
        id: 'read-span-abs',
        label: '读标点吸光度',
        request: '0x04 输入寄存器 232, count=2',
        run: async (): Promise<string> => this.formatNumberResult('校准标点吸光度',
          await MonitorService.readCalibrationSpanAbsorbance())
      },
      {
        id: 'read-span-drift',
        label: '读量程漂移',
        request: '0x04 输入寄存器 234, count=2',
        run: async (): Promise<string> => this.formatNumberResult('量程漂移', await MonitorService.readSpanDrift(), '%')
      },
      {
        id: 'read-composite-result',
        label: '读复合结果',
        request: '0x04 输入寄存器 236, count=2',
        run: async (): Promise<string> => this.formatNumberResult('复合测量结果',
          await MonitorService.readCompositeMeasurementResult(), 'mg/L')
      },
      {
        id: 'read-composite-time',
        label: '读复合时间',
        request: '0x04 输入寄存器 238, count=3',
        run: async (): Promise<string> => `复合结果时间: ${this.formatTime(
          await MonitorService.readCompositeResultTime())}`
      },
      {
        id: 'read-composite-flag',
        label: '读复合标识',
        request: '0x04 输入寄存器 241, count=1',
        run: async (): Promise<string> => `复合数据标识: ${this.formatDataFlag(
          await MonitorService.readCompositeDataFlag())}`
      },
      {
        id: 'read-toc-constant',
        label: '读TOC常数',
        request: '0x04 输入寄存器 242, count=2',
        run: async (): Promise<string> => this.formatNumberResult('TOC系数常数',
          await MonitorService.readTocFactorConstant())
      },
      {
        id: 'read-toc-ratio',
        label: '读TOC比例',
        request: '0x04 输入寄存器 244, count=2',
        run: async (): Promise<string> => this.formatNumberResult('TOC系数比例',
          await MonitorService.readTocFactorRatio())
      },
      {
        id: 'read-toc-flow',
        label: '读TOC流量',
        request: '0x04 输入寄存器 246, count=2',
        run: async (): Promise<string> => this.formatNumberResult('TOC流量控制',
          await MonitorService.readTocFlowControl(), 'ml/min')
      },
      {
        id: 'read-toc-result',
        label: '读TOC结果',
        request: '0x04 输入寄存器 248, count=2',
        run: async (): Promise<string> => this.formatNumberResult('TOC测量结果',
          await MonitorService.readTocMeasurementResult(), 'mg/L')
      }
    ];
  }

  private getHoldReadActions(): DebugAction[] {
    return [
      {
        id: 'read-measure-config',
        label: '读测量配置',
        request: '聚合读取保持寄存器 256~314 的配置项',
        run: async (): Promise<string> => this.formatMeasurementConfig(await MonitorService.readMeasurementConfig())
      },
      {
        id: 'read-range-table',
        label: '读量程表',
        request: '0x04 输入寄存器 26, count=6',
        run: async (): Promise<string> => {
          const value = await MonitorService.readRangeTable();
          return value ? `量程表: ${value.join(', ')} mg/L` : '读取失败，Service 返回 null';
        }
      },
      {
        id: 'read-current-range',
        label: '读当前量程',
        request: '0x03 保持寄存器 256, count=2',
        run: async (): Promise<string> => this.formatNumberResult('当前量程', await MonitorService.readCurrentRange(),
          'mg/L')
      },
      {
        id: 'read-slope',
        label: '读曲线斜率',
        request: '0x03 保持寄存器 258, count=2',
        run: async (): Promise<string> => this.formatNumberResult('校准曲线斜率',
          await MonitorService.readCalibrationCurveSlope())
      },
      {
        id: 'read-intercept',
        label: '读曲线截距',
        request: '0x03 保持寄存器 260, count=2',
        run: async (): Promise<string> => this.formatNumberResult('校准曲线截距',
          await MonitorService.readCalibrationCurveIntercept())
      },
      {
        id: 'read-dig-temp',
        label: '读消解温度',
        request: '0x03 保持寄存器 262, count=2',
        run: async (): Promise<string> => this.formatNumberResult('消解温度',
          await MonitorService.readDigestionTemperature(), '℃')
      },
      {
        id: 'read-dig-time',
        label: '读消解时间',
        request: '0x03 保持寄存器 264, count=1',
        run: async (): Promise<string> => this.formatNumberResult('消解时间',
          await MonitorService.readDigestionTimeSeconds(), '秒')
      },
      {
        id: 'read-react-temp',
        label: '读反应温度',
        request: '0x03 保持寄存器 265, count=2',
        run: async (): Promise<string> => this.formatNumberResult('反应温度',
          await MonitorService.readReactionTemperature(), '℃')
      },
      {
        id: 'read-react-time',
        label: '读反应时间',
        request: '0x03 保持寄存器 267, count=1',
        run: async (): Promise<string> => this.formatNumberResult('反应时间',
          await MonitorService.readReactionTimeSeconds(), '秒')
      },
      {
        id: 'read-correction',
        label: '读修正因子',
        request: '0x03 保持寄存器 268, count=2',
        run: async (): Promise<string> => this.formatNumberResult('修正因子',
          await MonitorService.readCorrectionFactor())
      },
      {
        id: 'read-system-time',
        label: '读系统时间',
        request: '0x03 保持寄存器 274, count=3',
        run: async (): Promise<string> => `系统时间: ${this.formatTime(await MonitorService.readSystemTime())}`
      },
      {
        id: 'read-measure-mode',
        label: '读测量模式',
        request: '0x03 保持寄存器 277, count=1',
        run: async (): Promise<string> => `测量模式: ${this.formatCodeDescription(
          await MonitorService.readMeasurementMode())}`
      },
      {
        id: 'read-auto-measure',
        label: '读自动测量间隔',
        request: '0x03 保持寄存器 278, count=1',
        run: async (): Promise<string> => this.formatNumberResult('自动测量间隔',
          await MonitorService.readAutoMeasurementIntervalHours(), '小时')
      },
      {
        id: 'read-auto-cal-mode',
        label: '读自动校准模式',
        request: '0x03 保持寄存器 279, count=1',
        run: async (): Promise<string> => `自动校准模式: ${this.formatCodeDescription(
          await MonitorService.readAutoCalibrationMode())}`
      },
      {
        id: 'read-auto-cal-hours',
        label: '读自动校准间隔',
        request: '0x03 保持寄存器 280, count=1',
        run: async (): Promise<string> => this.formatNumberResult('自动校准间隔',
          await MonitorService.readAutoCalibrationIntervalHours(), '小时')
      },
      {
        id: 'read-dilution',
        label: '读稀释倍数',
        request: '0x03 保持寄存器 283, count=2',
        run: async (): Promise<string> => this.formatNumberResult('当前量程稀释倍数',
          await MonitorService.readCurrentRangeDilutionFactor())
      },
      {
        id: 'read-zero-solution',
        label: '读零点液浓度',
        request: '0x03 保持寄存器 293, count=2',
        run: async (): Promise<string> => this.formatNumberResult('零点校准液浓度',
          await MonitorService.readZeroCalibrationSolutionConcentration(), 'mg/L')
      },
      {
        id: 'read-span-solution',
        label: '读量程液浓度',
        request: '0x03 保持寄存器 295, count=2',
        run: async (): Promise<string> => this.formatNumberResult('量程校准液浓度',
          await MonitorService.readSpanCalibrationSolutionConcentration(), 'mg/L')
      },
      {
        id: 'read-reagent-volume',
        label: '读试剂体积',
        request: '0x03 保持寄存器 300/302/304/306/308',
        run: async (): Promise<string> => {
          const one = await MonitorService.readReagentOneVolume();
          const two = await MonitorService.readReagentTwoVolume();
          const three = await MonitorService.readReagentThreeVolume();
          const four = await MonitorService.readReagentFourVolume();
          const five = await MonitorService.readReagentFiveVolume();
          return `试剂体积: 一=${one}, 二=${two}, 三=${three}, 四=${four}, 五=${five} mL`;
        }
      },
      {
        id: 'read-range-correction',
        label: '读量程校正因子',
        request: '0x03 保持寄存器 310, count=2',
        run: async (): Promise<string> => this.formatNumberResult('当前量程校正因子',
          await MonitorService.readCurrentRangeCorrectionFactor())
      },
      {
        id: 'read-check-allowed',
        label: '读核查允许偏差',
        request: '0x03 保持寄存器 312, count=2',
        run: async (): Promise<string> => this.formatNumberResult('跨度核查允许偏差',
          await MonitorService.readSpanCheckAllowedDeviation(), '%')
      },
      {
        id: 'read-check-deviation',
        label: '读核查偏差',
        request: '0x03 保持寄存器 314, count=2',
        run: async (): Promise<string> => this.formatNumberResult('跨度核查偏差',
          await MonitorService.readSpanCheckDeviation(), '%')
      }
    ];
  }

  private getControlWriteActions(): DebugAction[] {
    return [
      {
        id: 'start-measure',
        label: '启动测量',
        request: '0x06 保持寄存器 272/0x0110, 写入 0',
        run: async (): Promise<string> => this.formatWriteResult(await MonitorService.startMeasurement())
      },
      {
        id: 'stop-measure',
        label: '停止测量',
        request: '0x06 保持寄存器 272/0x0110, 写入 2',
        run: async (): Promise<string> => this.formatWriteResult(await MonitorService.stopMeasurement())
      },
      {
        id: 'start-calibration',
        label: '启动校准',
        request: '0x06 保持寄存器 272/0x0110, 写入 1',
        run: async (): Promise<string> => this.formatWriteResult(await MonitorService.startCalibration())
      },
      {
        id: 'start-cleaning',
        label: '深度清洗',
        request: '0x06 保持寄存器 272/0x0110, 写入 7',
        run: async (): Promise<string> => this.formatWriteResult(await MonitorService.startCleaning())
      },
      {
        id: 'measure-range-cal',
        label: '测量程校准液',
        request: '0x06 保持寄存器 272/0x0110, 写入 3',
        run: async (): Promise<string> => this.formatWriteResult(await MonitorService.measureRangeCalibrationSolution())
      },
      {
        id: 'measure-zero-cal',
        label: '测零点校准液',
        request: '0x06 保持寄存器 272/0x0110, 写入 4',
        run: async (): Promise<string> => this.formatWriteResult(await MonitorService.measureZeroCalibrationSolution())
      },
      {
        id: 'clean-tube',
        label: '清洗定量管',
        request: '0x06 保持寄存器 272/0x0110, 写入 5',
        run: async (): Promise<string> => this.formatWriteResult(await MonitorService.cleanQuantitativeTube())
      },
      {
        id: 'clean-chamber',
        label: '清洗消解室',
        request: '0x06 保持寄存器 272/0x0110, 写入 6',
        run: async (): Promise<string> => this.formatWriteResult(await MonitorService.cleanDigestionChamber())
      },
      {
        id: 'clean-all',
        label: '清洗所有管路',
        request: '0x06 保持寄存器 272/0x0110, 写入 8',
        run: async (): Promise<string> => this.formatWriteResult(await MonitorService.cleanAllPipelines())
      },
      {
        id: 'collect-water',
        label: '采集水样',
        request: '0x06 保持寄存器 272/0x0110, 写入 9',
        run: async (): Promise<string> => this.formatWriteResult(await MonitorService.collectWaterSample())
      },
      {
        id: 'pump-cal',
        label: '定量泵校准',
        request: '0x06 保持寄存器 272/0x0110, 写入 10',
        run: async (): Promise<string> => this.formatWriteResult(
          await MonitorService.startQuantitativePumpCalibration())
      },
      {
        id: 'zero-cal',
        label: '零点校准',
        request: '0x06 保持寄存器 272/0x0110, 写入 13',
        run: async (): Promise<string> => this.formatWriteResult(await MonitorService.startZeroCalibration())
      },
      {
        id: 'span-cal',
        label: '量程校准',
        request: '0x06 保持寄存器 272/0x0110, 写入 14',
        run: async (): Promise<string> => this.formatWriteResult(await MonitorService.startSpanCalibration())
      },
      {
        id: 'zero-check',
        label: '零点核查',
        request: '0x06 保持寄存器 272/0x0110, 写入 20',
        run: async (): Promise<string> => this.formatWriteResult(await MonitorService.startZeroCheck())
      },
      {
        id: 'span-check',
        label: '跨度核查',
        request: '0x06 保持寄存器 272/0x0110, 写入 21',
        run: async (): Promise<string> => this.formatWriteResult(await MonitorService.startSpanCheck())
      },
      {
        id: 'custom-control',
        label: '写控制码',
        request: `0x06 保持寄存器 272/0x0110, 写入控制码=${this.controlCode}`,
        run: async (): Promise<string> => {
          const value = this.parseIntValue(this.controlCode);
          if (value === null) {
            return this.formatInputError('控制码', this.controlCode);
          }
          return this.formatWriteResult(await MonitorService.writeMeasurementControl(value));
        }
      },
      {
        id: 'water-collection',
        label: '采水控制',
        request: `0x06 保持寄存器 273, 写入 ${this.waterCollectionEnabled}`,
        run: async (): Promise<string> => {
          return this.formatWriteResult(
            await MonitorService.writeWaterCollectionControl(this.waterCollectionEnabled === '1'));
        }
      }
    ];
  }

  private getConfigWriteActions(): DebugAction[] {
    return [
      {
        id: 'write-range',
        label: '写当前量程',
        request: `0x06/0x10 保持寄存器 256, 写入 ${this.currentRange} mg/L`,
        run: async (): Promise<string> => {
          const value = this.parseNumber(this.currentRange);
          return value === null ? this.formatInputError('当前量程', this.currentRange) :
            this.formatWriteResult(await MonitorService.writeCurrentRange(value));
        }
      },
      {
        id: 'write-slope',
        label: '写曲线斜率',
        request: `0x06/0x10 保持寄存器 258, 写入 ${this.calibrationSlope}`,
        run: async (): Promise<string> => {
          const value = this.parseNumber(this.calibrationSlope);
          return value === null ? this.formatInputError('曲线斜率', this.calibrationSlope) :
            this.formatWriteResult(await MonitorService.writeCalibrationCurveSlope(value));
        }
      },
      {
        id: 'write-intercept',
        label: '写曲线截距',
        request: `0x06/0x10 保持寄存器 260, 写入 ${this.calibrationIntercept}`,
        run: async (): Promise<string> => {
          const value = this.parseNumber(this.calibrationIntercept);
          return value === null ? this.formatInputError('曲线截距', this.calibrationIntercept) :
            this.formatWriteResult(await MonitorService.writeCalibrationCurveIntercept(value));
        }
      },
      {
        id: 'write-dig-temp',
        label: '写消解温度',
        request: `0x06/0x10 保持寄存器 262, 写入 ${this.digestionTemperature} ℃`,
        run: async (): Promise<string> => {
          const value = this.parseNumber(this.digestionTemperature);
          return value === null ? this.formatInputError('消解温度', this.digestionTemperature) :
            this.formatWriteResult(await MonitorService.writeDigestionTemperature(value));
        }
      },
      {
        id: 'write-dig-time',
        label: '写消解时间',
        request: `0x06 保持寄存器 264, 写入 ${this.digestionSeconds} 秒`,
        run: async (): Promise<string> => {
          const value = this.parseIntValue(this.digestionSeconds);
          return value === null ? this.formatInputError('消解时间', this.digestionSeconds) :
            this.formatWriteResult(await MonitorService.writeDigestionTimeSeconds(value));
        }
      },
      {
        id: 'write-react-temp',
        label: '写反应温度',
        request: `0x06/0x10 保持寄存器 265, 写入 ${this.reactionTemperature} ℃`,
        run: async (): Promise<string> => {
          const value = this.parseNumber(this.reactionTemperature);
          return value === null ? this.formatInputError('反应温度', this.reactionTemperature) :
            this.formatWriteResult(await MonitorService.writeReactionTemperature(value));
        }
      },
      {
        id: 'write-react-time',
        label: '写反应时间',
        request: `0x06 保持寄存器 267, 写入 ${this.reactionSeconds} 秒`,
        run: async (): Promise<string> => {
          const value = this.parseIntValue(this.reactionSeconds);
          return value === null ? this.formatInputError('反应时间', this.reactionSeconds) :
            this.formatWriteResult(await MonitorService.writeReactionTimeSeconds(value));
        }
      },
      {
        id: 'write-correction',
        label: '写修正因子',
        request: `0x06/0x10 保持寄存器 268, 写入 ${this.correctionFactor}`,
        run: async (): Promise<string> => {
          const value = this.parseNumber(this.correctionFactor);
          return value === null ? this.formatInputError('修正因子', this.correctionFactor) :
            this.formatWriteResult(await MonitorService.writeCorrectionFactor(value));
        }
      },
      {
        id: 'write-system-time',
        label: '写系统时间',
        request: `0x10 保持寄存器 274, 写入 ${this.systemYear}-${this.systemMonth}-${this.systemDay} ${this.systemHour}:${this.systemMinute}:${this.systemSecond}`,
        run: async (): Promise<string> => {
          const year = this.parseIntValue(this.systemYear);
          const month = this.parseIntValue(this.systemMonth);
          const day = this.parseIntValue(this.systemDay);
          const hour = this.parseIntValue(this.systemHour);
          const minute = this.parseIntValue(this.systemMinute);
          const second = this.parseIntValue(this.systemSecond);
          if (year === null || month === null || day === null || hour === null || minute === null || second === null) {
            return '参数错误: 系统时间字段无效';
          }
          return this.formatWriteResult(await MonitorService.writeSystemTime(year, month, day, hour, minute, second));
        }
      },
      {
        id: 'write-measure-mode',
        label: '写测量模式',
        request: `0x06 保持寄存器 277, 写入 ${this.measurementMode}`,
        run: async (): Promise<string> => {
          const value = this.parseIntValue(this.measurementMode);
          return value === null ? this.formatInputError('测量模式', this.measurementMode) :
            this.formatWriteResult(await MonitorService.writeMeasurementMode(value));
        }
      },
      {
        id: 'write-auto-measure',
        label: '写自动测量间隔',
        request: `0x06 保持寄存器 278, 写入 ${this.autoMeasurementHours} 小时`,
        run: async (): Promise<string> => {
          const value = this.parseIntValue(this.autoMeasurementHours);
          return value === null ? this.formatInputError('自动测量间隔', this.autoMeasurementHours) :
            this.formatWriteResult(await MonitorService.writeAutoMeasurementIntervalHours(value));
        }
      },
      {
        id: 'write-auto-cal-mode',
        label: '写自动校准模式',
        request: `0x06 保持寄存器 279, 写入 ${this.autoCalibrationMode}`,
        run: async (): Promise<string> => {
          const value = this.parseIntValue(this.autoCalibrationMode);
          return value === null ? this.formatInputError('自动校准模式', this.autoCalibrationMode) :
            this.formatWriteResult(await MonitorService.writeAutoCalibrationMode(value));
        }
      },
      {
        id: 'write-auto-cal-hours',
        label: '写自动校准间隔',
        request: `0x06 保持寄存器 280, 写入 ${this.autoCalibrationHours} 小时`,
        run: async (): Promise<string> => {
          const value = this.parseIntValue(this.autoCalibrationHours);
          return value === null ? this.formatInputError('自动校准间隔', this.autoCalibrationHours) :
            this.formatWriteResult(await MonitorService.writeAutoCalibrationIntervalHours(value));
        }
      }
    ];
  }

  @Builder
  private sectionTitle(label: string) {
    Text(label)
      .fontSize(UiUtil.vh(1.9, 12, 16, this.viewportHeight, this.scaleFactor))
      .fontWeight(FontWeight.Bold)
      .fontColor('#222222')
      .height(UiUtil.vh(3.2, 24, 34, this.viewportHeight, this.scaleFactor))
  }

  @Builder
  private labelText(label: string, widthValue?: number) {
    Text(label)
      .fontSize(UiUtil.vh(1.65, 11, 15, this.viewportHeight, this.scaleFactor))
      .fontColor('#333333')
      .width(widthValue !== undefined ? widthValue : UiUtil.vw(6.8, 52, 76, this.viewportWidth, this.scaleFactor))
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
  }

  @Builder
  private inputCell(textValue: string, widthValue: number, onValueChange: (value: string) => void) {
    TextInput({ text: textValue })
      .height(UiUtil.vh(3.6, 28, 38, this.viewportHeight, this.scaleFactor))
      .width(widthValue)
      .fontSize(UiUtil.vh(1.65, 11, 15, this.viewportHeight, this.scaleFactor))
      .backgroundColor('#FFFFFF')
      .border({ width: UiUtil.vh(0.1, 1, 1, this.viewportHeight, this.scaleFactor), color: '#D8DDE3' })
      .borderRadius(UiUtil.vh(0.45, 3, 5, this.viewportHeight, this.scaleFactor))
      .onChange((value: string) => {
        onValueChange(value);
      })
  }

  @Builder
  private selectCell(options: SelectOption[], value: string, widthValue: number,
    onValueChange: (value: string) => void) {
    Select(options)
      .value(value)
      .height(UiUtil.vh(3.6, 28, 38, this.viewportHeight, this.scaleFactor))
      .width(widthValue)
      .onSelect((_index: number, selectedValue?: string) => {
        onValueChange(selectedValue ? selectedValue : value);
      })
  }

  @Builder
  private actionButton(label: string, onAction: () => void, widthValue?: number) {
    SystemActionButton({
      label: label,
      buttonWidth: widthValue !== undefined ? widthValue :
        UiUtil.vw(8.9, 78, 112, this.viewportWidth, this.scaleFactor),
      buttonHeight: UiUtil.vh(4.0, 30, 42, this.viewportHeight, this.scaleFactor),
      fontSizeValue: UiUtil.vh(1.55, 10, 14, this.viewportHeight, this.scaleFactor),
      borderRadiusValue: UiUtil.vh(0.65, 4, 8, this.viewportHeight, this.scaleFactor),
      onAction: () => {
        onAction();
      }
    })
  }

  @Builder
  private actionSection(title: string, actions: DebugAction[]) {
    this.sectionTitle(title);
    Flex({ wrap: FlexWrap.Wrap }) {
      ForEach(actions, (action: DebugAction) => {
        Column() {
          this.actionButton(action.label, () => {
            void this.runAction(action);
          }, UiUtil.vw(9.8, 86, 124, this.viewportWidth, this.scaleFactor))
        }
        .margin({
          right: UiUtil.vw(0.7, 5, 8, this.viewportWidth, this.scaleFactor),
          bottom: UiUtil.vh(0.8, 5, 8, this.viewportHeight, this.scaleFactor)
        })
      }, (action: DebugAction) => action.id)
    }
    .width('100%')
    .padding({ bottom: UiUtil.vh(0.6, 4, 8, this.viewportHeight, this.scaleFactor) })
  }

  build() {
    Column() {
      Scroll() {
        Column() {
          this.sectionTitle('通信通道');

          Row() {
            this.labelText('通道');
            this.selectCell(this.communicationModeOptions, this.communicationMode,
              UiUtil.vw(8.0, 66, 92, this.viewportWidth, this.scaleFactor), (value: string) => {
                this.communicationMode = value === 'uart' ? 'uart' : 'tcp';
              });

            this.labelText('TCP IP', UiUtil.vw(5.2, 42, 60, this.viewportWidth, this.scaleFactor));
            this.inputCell(this.tcpIp, UiUtil.vw(16.0, 132, 190, this.viewportWidth, this.scaleFactor),
              (value: string) => {
                this.tcpIp = value;
              });

            this.labelText('端口', UiUtil.vw(4.6, 36, 52, this.viewportWidth, this.scaleFactor));
            this.inputCell(this.tcpPort, UiUtil.vw(7.0, 58, 82, this.viewportWidth, this.scaleFactor),
              (value: string) => {
                this.tcpPort = value;
              });
          }
          .width('100%')
          .height(UiUtil.vh(4.4, 34, 46, this.viewportHeight, this.scaleFactor))
          .alignItems(VerticalAlign.Center)

          Row() {
            this.labelText('串口');
            this.inputCell(this.uartPath, UiUtil.vw(16.0, 132, 190, this.viewportWidth, this.scaleFactor),
              (value: string) => {
                this.uartPath = value;
              });

            this.labelText('波特率', UiUtil.vw(5.6, 44, 64, this.viewportWidth, this.scaleFactor));
            this.selectCell(this.baudRateOptions, this.uartBaudRate,
              UiUtil.vw(9.0, 74, 102, this.viewportWidth, this.scaleFactor), (value: string) => {
                this.uartBaudRate = value;
              });

            this.labelText('数据位', UiUtil.vw(5.2, 42, 60, this.viewportWidth, this.scaleFactor));
            this.selectCell(this.dataBitsOptions, this.uartDataBits,
              UiUtil.vw(6.0, 50, 70, this.viewportWidth, this.scaleFactor), (value: string) => {
                this.uartDataBits = value;
              });

            this.labelText('停止位', UiUtil.vw(5.2, 42, 60, this.viewportWidth, this.scaleFactor));
            this.selectCell(this.stopBitsOptions, this.uartStopBits,
              UiUtil.vw(6.0, 50, 70, this.viewportWidth, this.scaleFactor), (value: string) => {
                this.uartStopBits = value;
              });

            this.labelText('校验', UiUtil.vw(4.6, 36, 52, this.viewportWidth, this.scaleFactor));
            this.selectCell(this.parityOptions, this.uartParity,
              UiUtil.vw(6.0, 50, 70, this.viewportWidth, this.scaleFactor), (value: string) => {
                this.uartParity = value;
              });
          }
          .width('100%')
          .height(UiUtil.vh(4.4, 34, 46, this.viewportHeight, this.scaleFactor))
          .alignItems(VerticalAlign.Center)

          this.actionSection('连接操作', this.getConnectionActions());

          this.actionSection('测量读请求', this.getMeasurementReadActions());
          this.actionSection('状态与报警读请求', this.getStatusReadActions());
          this.actionSection('仪器与板卡读请求', this.getInstrumentReadActions());
          this.actionSection('吸光度 / 标识 / 复合读请求', this.getOpticalReadActions());
          this.actionSection('保持寄存器配置读请求', this.getHoldReadActions());

          this.sectionTitle('控制写请求参数');

          Row() {
            this.labelText('控制码');
            this.inputCell(this.controlCode, UiUtil.vw(7.2, 58, 84, this.viewportWidth, this.scaleFactor),
              (value: string) => {
                this.controlCode = value;
              });

            this.labelText('采水', UiUtil.vw(4.6, 36, 52, this.viewportWidth, this.scaleFactor));
            this.selectCell(this.switchOptions, this.waterCollectionEnabled,
              UiUtil.vw(6.0, 50, 70, this.viewportWidth, this.scaleFactor), (value: string) => {
                this.waterCollectionEnabled = value;
              });
          }
          .width('100%')
          .height(UiUtil.vh(4.4, 34, 46, this.viewportHeight, this.scaleFactor))
          .alignItems(VerticalAlign.Center)

          this.actionSection('控制写请求', this.getControlWriteActions());

          this.sectionTitle('配置写请求参数');

          Row() {
            this.labelText('量程');
            this.inputCell(this.currentRange, UiUtil.vw(7.2, 58, 84, this.viewportWidth, this.scaleFactor),
              (value: string) => {
                this.currentRange = value;
              });
            this.labelText('斜率', UiUtil.vw(4.6, 36, 52, this.viewportWidth, this.scaleFactor));
            this.inputCell(this.calibrationSlope, UiUtil.vw(7.2, 58, 84, this.viewportWidth, this.scaleFactor),
              (value: string) => {
                this.calibrationSlope = value;
              });
            this.labelText('截距', UiUtil.vw(4.6, 36, 52, this.viewportWidth, this.scaleFactor));
            this.inputCell(this.calibrationIntercept, UiUtil.vw(7.2, 58, 84, this.viewportWidth, this.scaleFactor),
              (value: string) => {
                this.calibrationIntercept = value;
              });
            this.labelText('修正因子', UiUtil.vw(6.2, 50, 72, this.viewportWidth, this.scaleFactor));
            this.inputCell(this.correctionFactor, UiUtil.vw(7.2, 58, 84, this.viewportWidth, this.scaleFactor),
              (value: string) => {
                this.correctionFactor = value;
              });
          }
          .width('100%')
          .height(UiUtil.vh(4.4, 34, 46, this.viewportHeight, this.scaleFactor))
          .alignItems(VerticalAlign.Center)

          Row() {
            this.labelText('消解温度');
            this.inputCell(this.digestionTemperature, UiUtil.vw(7.2, 58, 84, this.viewportWidth, this.scaleFactor),
              (value: string) => {
                this.digestionTemperature = value;
              });
            this.labelText('消解秒', UiUtil.vw(5.2, 42, 60, this.viewportWidth, this.scaleFactor));
            this.inputCell(this.digestionSeconds, UiUtil.vw(7.2, 58, 84, this.viewportWidth, this.scaleFactor),
              (value: string) => {
                this.digestionSeconds = value;
              });
            this.labelText('反应温度', UiUtil.vw(6.2, 50, 72, this.viewportWidth, this.scaleFactor));
            this.inputCell(this.reactionTemperature, UiUtil.vw(7.2, 58, 84, this.viewportWidth, this.scaleFactor),
              (value: string) => {
                this.reactionTemperature = value;
              });
            this.labelText('反应秒', UiUtil.vw(5.2, 42, 60, this.viewportWidth, this.scaleFactor));
            this.inputCell(this.reactionSeconds, UiUtil.vw(7.2, 58, 84, this.viewportWidth, this.scaleFactor),
              (value: string) => {
                this.reactionSeconds = value;
              });
          }
          .width('100%')
          .height(UiUtil.vh(4.4, 34, 46, this.viewportHeight, this.scaleFactor))
          .alignItems(VerticalAlign.Center)

          Row() {
            this.labelText('时间');
            this.inputCell(this.systemYear, UiUtil.vw(6.2, 50, 72, this.viewportWidth, this.scaleFactor),
              (value: string) => {
                this.systemYear = value;
              });
            this.inputCell(this.systemMonth, UiUtil.vw(4.8, 38, 56, this.viewportWidth, this.scaleFactor),
              (value: string) => {
                this.systemMonth = value;
              });
            this.inputCell(this.systemDay, UiUtil.vw(4.8, 38, 56, this.viewportWidth, this.scaleFactor),
              (value: string) => {
                this.systemDay = value;
              });
            this.inputCell(this.systemHour, UiUtil.vw(4.8, 38, 56, this.viewportWidth, this.scaleFactor),
              (value: string) => {
                this.systemHour = value;
              });
            this.inputCell(this.systemMinute, UiUtil.vw(4.8, 38, 56, this.viewportWidth, this.scaleFactor),
              (value: string) => {
                this.systemMinute = value;
              });
            this.inputCell(this.systemSecond, UiUtil.vw(4.8, 38, 56, this.viewportWidth, this.scaleFactor),
              (value: string) => {
                this.systemSecond = value;
              });
            this.labelText('测量模式', UiUtil.vw(6.8, 54, 78, this.viewportWidth, this.scaleFactor));
            this.selectCell(this.measurementModeOptions, this.measurementMode,
              UiUtil.vw(6.0, 50, 70, this.viewportWidth, this.scaleFactor), (value: string) => {
                this.measurementMode = value;
              });
          }
          .width('100%')
          .height(UiUtil.vh(4.4, 34, 46, this.viewportHeight, this.scaleFactor))
          .alignItems(VerticalAlign.Center)

          Row() {
            this.labelText('自动测量h');
            this.inputCell(this.autoMeasurementHours, UiUtil.vw(7.2, 58, 84, this.viewportWidth, this.scaleFactor),
              (value: string) => {
                this.autoMeasurementHours = value;
              });
            this.labelText('校准模式', UiUtil.vw(6.2, 50, 72, this.viewportWidth, this.scaleFactor));
            this.selectCell(this.autoCalibrationModeOptions, this.autoCalibrationMode,
              UiUtil.vw(6.0, 50, 70, this.viewportWidth, this.scaleFactor), (value: string) => {
                this.autoCalibrationMode = value;
              });
            this.labelText('自动校准h', UiUtil.vw(7.0, 56, 82, this.viewportWidth, this.scaleFactor));
            this.inputCell(this.autoCalibrationHours, UiUtil.vw(7.2, 58, 84, this.viewportWidth, this.scaleFactor),
              (value: string) => {
                this.autoCalibrationHours = value;
              });
          }
          .width('100%')
          .height(UiUtil.vh(4.4, 34, 46, this.viewportHeight, this.scaleFactor))
          .alignItems(VerticalAlign.Center)

          this.actionSection('配置写请求', this.getConfigWriteActions());

          this.sectionTitle('日志 / 解析响应');

          Row({ space: UiUtil.vw(0.7, 6, 10, this.viewportWidth, this.scaleFactor) }) {
            this.actionButton('清空日志', () => this.clearLog(),
              UiUtil.vw(8.4, 72, 100, this.viewportWidth, this.scaleFactor));
          }
          .width('100%')
          .height(UiUtil.vh(4.6, 34, 48, this.viewportHeight, this.scaleFactor))
          .alignItems(VerticalAlign.Center)

          Scroll() {
            Text(this.logText.length > 0 ? this.logText : '暂无日志')
              .width('100%')
              .fontSize(UiUtil.vh(1.45, 10, 13, this.viewportHeight, this.scaleFactor))
              .fontColor(this.logText.length > 0 ? '#1F2933' : '#8A8F99')
              .fontFamily('monospace')
              .lineHeight(UiUtil.vh(2.2, 16, 22, this.viewportHeight, this.scaleFactor))
              .padding({
                left: UiUtil.vw(0.8, 6, 10, this.viewportWidth, this.scaleFactor),
                right: UiUtil.vw(0.8, 6, 10, this.viewportWidth, this.scaleFactor),
                top: UiUtil.vh(0.8, 6, 10, this.viewportHeight, this.scaleFactor),
                bottom: UiUtil.vh(0.8, 6, 10, this.viewportHeight, this.scaleFactor)
              })
          }
          .width('100%')
          .height(UiUtil.vh(24.0, 170, 290, this.viewportHeight, this.scaleFactor))
          .scrollable(ScrollDirection.Vertical)
          .backgroundColor('#F6F8FA')
          .border({ width: UiUtil.vh(0.1, 1, 1, this.viewportHeight, this.scaleFactor), color: '#D8DDE3' })
          .borderRadius(UiUtil.vh(0.45, 3, 5, this.viewportHeight, this.scaleFactor))
        }
        .width('100%')
        .padding({
          left: UiUtil.vw(0.2, 0, 4, this.viewportWidth, this.scaleFactor),
          right: UiUtil.vw(0.2, 0, 4, this.viewportWidth, this.scaleFactor),
          bottom: UiUtil.vh(1.0, 6, 12, this.viewportHeight, this.scaleFactor)
        })
      }
      .width('100%')
      .height('100%')
      .scrollable(ScrollDirection.Vertical)
    }
    .layoutWeight(1)
    .height('100%')
    .padding({
      left: UiUtil.vw(1.4, 10, 18, this.viewportWidth, this.scaleFactor),
      right: UiUtil.vw(1.4, 10, 18, this.viewportWidth, this.scaleFactor),
      top: UiUtil.vh(1.0, 6, 12, this.viewportHeight, this.scaleFactor),
      bottom: UiUtil.vh(0.8, 6, 10, this.viewportHeight, this.scaleFactor)
    })
    .backgroundColor('#FFFFFF')
  }
}
