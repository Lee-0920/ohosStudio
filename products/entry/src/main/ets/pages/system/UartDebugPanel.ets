import { UiUtil } from 'base';
import { UartClient } from '../../services/clients/UartClient';
import { DeviceConnectionSupervisor } from '../../services/DeviceConnectionSupervisor';
import { DeviceStateStore } from '../../services/DeviceStateStore';
import { MonitorService } from '../../services/MonitorService';
import { SystemActionButton } from './SystemControls';

@Component
export struct UartDebugPanel {
  @Prop viewportWidth: number = 1024;
  @Prop viewportHeight: number = 768;
  @Prop scaleFactor: number = 1.92;
  @State private portPath: string = '/dev/ttyS7';
  @State private baudRate: string = '9600';
  @State private dataBits: string = '8';
  @State private stopBits: string = '1';
  @State private parity: string = 'N';
  @State private driverMode: string = 'RS232';
  @State private readLength: string = '1024';
  @State private sendFormat: string = 'HEX';
  @State private sendPayload: string = '01 04 00 00 00 02 71 CB';
  @State private deviceAddr: string = '01';
  @State private readRegisterAddr: string = '0000';
  @State private readRegisterCount: string = '0002';
  @State private writeRegisterAddr: string = '0110';
  @State private writeRegisterValue: string = '0000';
  @State private logText: string = '';
  @State private isListening: boolean = false;
  onSystemAction: () => void = () => {
  };
  private listenTimer: number = -1;
  private isListenerReading: boolean = false;
  private receiveBuffer: number[] = [];
  private lastReceiveAt: number = 0;
  private readonly listenPollIntervalMs: number = 20;
  private readonly receiveSilenceMs: number = 50;
  private readonly baudRateOptions: SelectOption[] = [
    { value: '1200' },
    { value: '2400' },
    { value: '4800' },
    { value: '9600' },
    { value: '19200' },
    { value: '38400' },
    { value: '57600' },
    { value: '115200' },
    { value: '230400' },
    { value: '460800' },
    { value: '500000' },
    { value: '576000' },
    { value: '921600' },
    { value: '1000000' },
    { value: '1152000' },
    { value: '1500000' },
    { value: '2000000' },
    { value: '2500000' },
    { value: '3000000' },
    { value: '3500000' },
    { value: '4000000' }
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
  private readonly driverModeOptions: SelectOption[] = [
    { value: 'RS232' },
    { value: 'RS485' }
  ];
  private readonly formatOptions: SelectOption[] = [
    { value: 'HEX' },
    { value: 'TEXT' }
  ];

  private clamp(value: number, min: number, max: number): number {
    return Math.min(max, Math.max(min, value));
  }

  private pad2(value: number): string {
    return value.toString().padStart(2, '0');
  }

  private pad3(value: number): string {
    return value.toString().padStart(3, '0');
  }

  private nowText(): string {
    const now = new Date();
    return `${this.pad2(now.getHours())}:${this.pad2(now.getMinutes())}:${this.pad2(now.getSeconds())}.` +
      `${this.pad3(now.getMilliseconds())}`;
  }

  private addLog(message: string): void {
    const next = `[${this.nowText()}] ${message}`;
    const merged = this.logText.length > 0 ? `${this.logText}\n${next}` : next;
    this.logText = merged.length > 12000 ? merged.slice(merged.length - 12000) : merged;
  }

  private uartFailureText(prefix: string): string {
    const reason = UartClient.getLastError();
    return reason.length > 0 ? `${prefix}: ${reason}` : prefix;
  }

  private parseDecimal(value: string, fallbackValue: number): number {
    const parsed = Number.parseInt(value.trim(), 10);
    return Number.isNaN(parsed) ? fallbackValue : parsed;
  }

  private parseHexNumber(value: string): number | null {
    let normalized = value.trim();
    if (normalized.length === 0) {
      return null;
    }
    if (normalized.startsWith('0x') || normalized.startsWith('0X')) {
      normalized = normalized.slice(2);
    }
    if (!/^[0-9a-fA-F]+$/.test(normalized)) {
      return null;
    }
    const parsed = Number.parseInt(normalized, 16);
    return Number.isNaN(parsed) ? null : parsed;
  }

  private parseHexBytes(text: string): Uint8Array | null {
    let normalized = text.trim();
    if (normalized.length === 0) {
      return new Uint8Array(0);
    }
    normalized = normalized.replace(/0x/gi, '');
    normalized = normalized.replace(/[,，;；\r\n\t]+/g, ' ');
    const hasSpace = /\s/.test(normalized);
    let parts: string[] = [];

    if (hasSpace) {
      parts = normalized.split(/\s+/).filter((item: string) => item.length > 0);
    } else {
      if (normalized.length % 2 !== 0) {
        return null;
      }
      for (let i = 0; i < normalized.length; i += 2) {
        parts.push(normalized.slice(i, i + 2));
      }
    }

    const bytes = new Uint8Array(parts.length);
    for (let i = 0; i < parts.length; i++) {
      if (!/^[0-9a-fA-F]{1,2}$/.test(parts[i])) {
        return null;
      }
      const value = Number.parseInt(parts[i], 16);
      if (Number.isNaN(value) || value < 0 || value > 0xFF) {
        return null;
      }
      bytes[i] = value;
    }
    return bytes;
  }

  private bytesToWireText(bytes: Uint8Array): string {
    let text = '';
    for (let i = 0; i < bytes.length; i++) {
      text += String.fromCharCode(bytes[i]);
    }
    return text;
  }

  private wireTextToBytes(text: string): Uint8Array {
    const bytes = new Uint8Array(text.length);
    for (let i = 0; i < text.length; i++) {
      bytes[i] = text.charCodeAt(i) & 0xFF;
    }
    return bytes;
  }

  private bytesToHex(bytes: Uint8Array): string {
    let text = '';
    for (let i = 0; i < bytes.length; i++) {
      text += bytes[i].toString(16).padStart(2, '0').toUpperCase();
      if (i < bytes.length - 1) {
        text += ' ';
      }
    }
    return text;
  }

  private releaseBusinessUartIfNeeded(): void {
    if (MonitorService.getCommunicationMode() !== 'uart' || !MonitorService.isConnectedToMcu()) {
      return;
    }

    MonitorService.disconnect();
    DeviceConnectionSupervisor.markManualDisconnected();
    DeviceStateStore.resetRealtimeState('UART 调试占用业务通道');
    DeviceStateStore.updateConnection(
      DeviceConnectionSupervisor.createSnapshotInput('UART 调试占用业务通道'),
      'uart_debug_panel'
    );
    this.addLog('已断开业务 UART 通道，避免与调试串口竞争');
    this.onSystemAction();
  }

  private applyConfig(): boolean {
    const baud = this.parseDecimal(this.baudRate, 115200);
    const bits = this.parseDecimal(this.dataBits, 8);
    const stops = this.parseDecimal(this.stopBits, 1);
    const parity = this.parity.length > 0 ? this.parity.charAt(0) : 'N';

    if (this.portPath.trim().length === 0 || baud <= 0 || bits <= 0 || stops <= 0) {
      this.addLog('串口参数无效，请检查设备路径、波特率、数据位和停止位');
      return false;
    }

    this.releaseBusinessUartIfNeeded();
    const isRs485 = this.driverMode === 'RS485';
    const wasConnected = UartClient.isConnected();
    this.stopListening(false);
    if (wasConnected) {
      UartClient.disconnect();
    }
    UartClient.setConfig(this.portPath.trim(), baud, bits, stops, parity, isRs485);
    this.addLog(`配置串口: ${this.portPath.trim()} ${baud} ${bits}${parity}${stops} ${this.driverMode}`);
    if (wasConnected) {
      this.addLog('配置已更新，原串口连接已关闭');
    }
    return true;
  }

  private async openPort(): Promise<void> {
    if (!this.applyConfig()) {
      return;
    }
    const ok = await UartClient.connect();
    this.addLog(ok ? '打开串口成功' : this.uartFailureText('打开串口失败'));
  }

  private closePort(): void {
    this.stopListening(false);
    UartClient.disconnect();
    this.addLog('已关闭串口');
  }

  private checkStatus(): void {
    this.addLog(UartClient.isConnected() ? '串口状态: 已打开' : '串口状态: 未打开');
  }

  private clearLog(): void {
    this.logText = '';
  }

  private startListening(): void {
    if (this.isListening) {
      return;
    }

    if (!UartClient.isConnected()) {
      if (!this.applyConfig() || !UartClient.open()) {
        this.addLog(this.uartFailureText('启动监听失败: 串口未打开'));
        return;
      }
      this.addLog('打开串口成功');
    }

    this.receiveBuffer = [];
    this.lastReceiveAt = 0;
    this.isListening = true;
    this.listenTimer = setInterval(() => {
      this.pollListeningData();
    }, this.listenPollIntervalMs);
    this.addLog('已开始监听串口');
  }

  private stopListening(writeLog: boolean = true): void {
    if (this.listenTimer !== -1) {
      clearInterval(this.listenTimer);
      this.listenTimer = -1;
    }
    const wasListening = this.isListening;
    this.isListening = false;
    this.isListenerReading = false;
    this.flushReceiveBuffer();
    if (writeLog && wasListening) {
      this.addLog('已停止监听串口');
    }
  }

  private pollListeningData(): void {
    if (!this.isListening || this.isListenerReading) {
      return;
    }
    if (!UartClient.isConnected()) {
      this.stopListening(false);
      this.addLog('串口已关闭，监听已停止');
      return;
    }

    this.isListenerReading = true;
    try {
      const maxLen = this.clamp(this.parseDecimal(this.readLength, 1024), 1, 4096);
      const text = UartClient.readText(maxLen, 0);
      const now = Date.now();
      if (text.length > 0) {
        const bytes = this.wireTextToBytes(text);
        for (let i = 0; i < bytes.length; i++) {
          this.receiveBuffer.push(bytes[i]);
        }
        this.lastReceiveAt = now;
        if (this.receiveBuffer.length >= maxLen) {
          this.flushReceiveBuffer();
        }
      } else if (this.receiveBuffer.length > 0 && now - this.lastReceiveAt >= this.receiveSilenceMs) {
        this.flushReceiveBuffer();
      }
    } finally {
      this.isListenerReading = false;
    }
  }

  private flushReceiveBuffer(): void {
    if (this.receiveBuffer.length === 0) {
      return;
    }

    const bytes = new Uint8Array(this.receiveBuffer.length);
    for (let i = 0; i < this.receiveBuffer.length; i++) {
      bytes[i] = this.receiveBuffer[i];
    }
    this.receiveBuffer = [];
    this.lastReceiveAt = 0;
    this.addLog(`RX HEX (${bytes.length} bytes): ${this.bytesToHex(bytes)}`);
    if (this.sendFormat === 'TEXT') {
      this.addLog(`RX TEXT: ${this.bytesToWireText(bytes)}`);
    }
  }

  private sendRawPayload(): void {
    if (!UartClient.isConnected()) {
      if (!this.applyConfig() || !UartClient.open()) {
        this.addLog(this.uartFailureText('发送失败: 串口未打开'));
        return;
      }
    }

    if (this.sendFormat === 'HEX') {
      const bytes = this.parseHexBytes(this.sendPayload);
      if (bytes === null || bytes.length === 0) {
        this.addLog('HEX 输入无效，示例: 01 04 00 00 00 02 71 CB');
        return;
      }
      const written = UartClient.writeText(this.bytesToWireText(bytes));
      this.addLog(`TX HEX (${written} bytes): ${this.bytesToHex(bytes)}`);
      return;
    }

    const written = UartClient.writeText(this.sendPayload);
    this.addLog(`TX TEXT (${written} bytes): ${this.sendPayload}`);
  }

  private readRawPayload(): void {
    if (this.isListening) {
      this.addLog('监听中会自动接收数据，无需手动读取');
      return;
    }
    if (!UartClient.isConnected()) {
      if (!this.applyConfig() || !UartClient.open()) {
        this.addLog(this.uartFailureText('读取失败: 串口未打开'));
        return;
      }
    }

    const maxLen = this.clamp(this.parseDecimal(this.readLength, 1024), 1, 4096);
    const text = UartClient.readText(maxLen);
    if (text.length === 0) {
      this.addLog(`RX: 无响应或读取超时，maxLen=${maxLen}`);
      return;
    }

    const bytes = this.wireTextToBytes(text);
    this.addLog(`RX HEX (${bytes.length} bytes): ${this.bytesToHex(bytes)}`);
    if (this.sendFormat === 'TEXT') {
      this.addLog(`RX TEXT: ${text}`);
    }
  }

  private async readInputRegisters(): Promise<void> {
    if (this.isListening) {
      this.addLog('请先停止监听，再执行 Modbus 读取');
      return;
    }
    if (!UartClient.isConnected() && !this.applyConfig()) {
      return;
    }

    const addr = this.parseHexNumber(this.deviceAddr);
    const reg = this.parseHexNumber(this.readRegisterAddr);
    const count = this.parseHexNumber(this.readRegisterCount);
    if (addr === null || reg === null || count === null || addr > 0xFF || reg > 0xFFFF || count <= 0 || count > 0x7D) {
      this.addLog('04 参数无效，请检查设备地址、寄存器地址和数量，输入使用 HEX');
      return;
    }

    const response = await UartClient.readInputRegisters(addr, reg, count, '调试读取输入寄存器');
    if (!response) {
      this.addLog(this.uartFailureText('04 读取失败或无响应'));
      return;
    }
    this.addLog(`04 RX PDU: ${this.bytesToHex(response)}`);
  }

  private async writeSingleRegister(): Promise<void> {
    if (this.isListening) {
      this.addLog('请先停止监听，再执行 Modbus 写入');
      return;
    }
    if (!UartClient.isConnected() && !this.applyConfig()) {
      return;
    }

    const addr = this.parseHexNumber(this.deviceAddr);
    const reg = this.parseHexNumber(this.writeRegisterAddr);
    const value = this.parseHexNumber(this.writeRegisterValue);
    if (addr === null || reg === null || value === null || addr > 0xFF || reg > 0xFFFF || value > 0xFFFF) {
      this.addLog('06 参数无效，请检查设备地址、寄存器地址和写入值，输入使用 HEX');
      return;
    }

    const ok = await UartClient.writeSingleRegister(addr, reg, value, '调试写单保持寄存器');
    this.addLog(
      ok ? `06 写入成功: addr=${this.deviceAddr} reg=${this.writeRegisterAddr} value=${this.writeRegisterValue}` :
        this.uartFailureText('06 写入失败或无响应'));
  }

  private async quickWriteControl(value: number, label: string): Promise<void> {
    this.writeRegisterAddr = '0110';
    this.writeRegisterValue = value.toString(16).padStart(4, '0').toUpperCase();
    this.addLog(`快捷命令: ${label}`);
    await this.writeSingleRegister();
  }

  aboutToDisappear(): void {
    this.stopListening(false);
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
        UiUtil.vw(8.4, 72, 100, this.viewportWidth, this.scaleFactor),
      buttonHeight: UiUtil.vh(4.0, 30, 42, this.viewportHeight, this.scaleFactor),
      fontSizeValue: UiUtil.vh(1.65, 11, 15, this.viewportHeight, this.scaleFactor),
      borderRadiusValue: UiUtil.vh(0.65, 4, 8, this.viewportHeight, this.scaleFactor),
      onAction: () => {
        onAction();
      }
    })
  }

  @Builder
  private listenActionButton(widthValue: number) {
    Stack({ alignContent: Alignment.Center }) {
      Text(this.isListening ? '停止监听' : '开始监听')
        .width('100%')
        .fontSize(UiUtil.vh(1.65, 11, 15, this.viewportHeight, this.scaleFactor))
        .fontColor('#FFFFFF')
        .fontWeight(FontWeight.Bold)
        .fontFamily('HarmonyOS Sans')
        .textAlign(TextAlign.Center)
        .maxLines(1)
    }
    .width(widthValue)
    .height(UiUtil.vh(4.0, 30, 42, this.viewportHeight, this.scaleFactor))
    .borderRadius(UiUtil.vh(0.65, 4, 8, this.viewportHeight, this.scaleFactor))
    .backgroundColor('#0B9F9A')
    .linearGradient({
      angle: 135,
      colors: [
        ['#20D4CA', 0.0],
        ['#0FA6A0', 0.48],
        ['#087D82', 1.0]
      ]
    })
    .border({ width: 1, color: '#55DDF7F2' })
    .shadow({
      radius: 10,
      color: '#55008C8A',
      offsetX: 0,
      offsetY: 3
    })
    .onClick(() => {
      if (this.isListening) {
        this.stopListening();
      } else {
        this.startListening();
      }
    })
  }

  build() {
    Column() {
      Scroll() {
        Column() {
          this.sectionTitle('串口参数');

          Row() {
            this.labelText('设备路径');
            this.inputCell(this.portPath, UiUtil.vw(22.0, 170, 260, this.viewportWidth, this.scaleFactor),
              (value: string) => {
                this.portPath = value;
              });

            this.labelText('读取长度', UiUtil.vw(6.8, 56, 78, this.viewportWidth, this.scaleFactor));
            this.inputCell(this.readLength, UiUtil.vw(8.0, 66, 92, this.viewportWidth, this.scaleFactor),
              (value: string) => {
                this.readLength = value;
              });
          }
          .width('100%')
          .height(UiUtil.vh(4.4, 34, 46, this.viewportHeight, this.scaleFactor))
          .alignItems(VerticalAlign.Center)

          Row() {
            this.labelText('波特率');
            this.selectCell(this.baudRateOptions, this.baudRate,
              UiUtil.vw(13.0, 108, 150, this.viewportWidth, this.scaleFactor), (value: string) => {
                this.baudRate = value;
              });

            this.labelText('驱动模式', UiUtil.vw(7.0, 58, 82, this.viewportWidth, this.scaleFactor));
            this.selectCell(this.driverModeOptions, this.driverMode,
              UiUtil.vw(9.0, 74, 104, this.viewportWidth, this.scaleFactor), (value: string) => {
                this.driverMode = value;
              });

            this.labelText('数据位', UiUtil.vw(5.4, 44, 62, this.viewportWidth, this.scaleFactor));
            this.selectCell(this.dataBitsOptions, this.dataBits,
              UiUtil.vw(6.4, 52, 76, this.viewportWidth, this.scaleFactor), (value: string) => {
                this.dataBits = value;
              });
          }
          .width('100%')
          .height(UiUtil.vh(4.4, 34, 46, this.viewportHeight, this.scaleFactor))
          .alignItems(VerticalAlign.Center)

          Row() {
            this.labelText('停止位');
            this.selectCell(this.stopBitsOptions, this.stopBits,
              UiUtil.vw(6.4, 52, 76, this.viewportWidth, this.scaleFactor), (value: string) => {
                this.stopBits = value;
              });

            this.labelText('校验位', UiUtil.vw(5.4, 44, 62, this.viewportWidth, this.scaleFactor));
            this.selectCell(this.parityOptions, this.parity,
              UiUtil.vw(6.4, 52, 76, this.viewportWidth, this.scaleFactor), (value: string) => {
                this.parity = value;
              });
          }
          .width('100%')
          .height(UiUtil.vh(4.4, 34, 46, this.viewportHeight, this.scaleFactor))
          .alignItems(VerticalAlign.Center)

          Row({ space: UiUtil.vw(0.7, 6, 10, this.viewportWidth, this.scaleFactor) }) {
            this.actionButton('应用配置', () => {
              this.applyConfig();
            });
            this.actionButton('打开串口', () => {
              void this.openPort();
            });
            this.actionButton('关闭串口', () => this.closePort());
            this.actionButton('查询状态', () => this.checkStatus());
            this.actionButton('清空日志', () => this.clearLog());
          }
          .width('100%')
          .height(UiUtil.vh(5.2, 38, 54, this.viewportHeight, this.scaleFactor))
          .alignItems(VerticalAlign.Center)

          this.sectionTitle('原始数据发送');

          Row() {
            this.labelText('发送格式');
            this.selectCell(this.formatOptions, this.sendFormat,
              UiUtil.vw(8.0, 66, 92, this.viewportWidth, this.scaleFactor), (value: string) => {
                this.sendFormat = value;
              });
          }
          .width('100%')
          .height(UiUtil.vh(4.0, 30, 42, this.viewportHeight, this.scaleFactor))
          .alignItems(VerticalAlign.Center)

          Row() {
            this.labelText('发送内容');
            this.inputCell(this.sendPayload, UiUtil.vw(50.0, 380, 620, this.viewportWidth, this.scaleFactor),
              (value: string) => {
                this.sendPayload = value;
              });
          }
          .width('100%')
          .height(UiUtil.vh(4.4, 34, 46, this.viewportHeight, this.scaleFactor))
          .alignItems(VerticalAlign.Center)

          Row({ space: UiUtil.vw(0.7, 6, 10, this.viewportWidth, this.scaleFactor) }) {
            this.actionButton('发送一次', () => this.sendRawPayload());
            this.actionButton('读取一次', () => this.readRawPayload());
            this.listenActionButton(UiUtil.vw(10.0, 84, 118, this.viewportWidth, this.scaleFactor));
          }
          .width('100%')
          .height(UiUtil.vh(5.0, 36, 52, this.viewportHeight, this.scaleFactor))
          .alignItems(VerticalAlign.Center)

          // this.sectionTitle('Modbus RTU 快捷调试');
          //
          // Row() {
          //   this.labelText('设备地址');
          //   this.inputCell(this.deviceAddr, UiUtil.vw(6.4, 52, 76, this.viewportWidth, this.scaleFactor), (value: string) => {
          //     this.deviceAddr = value;
          //   });
          //
          //   this.labelText('04寄存器', UiUtil.vw(7.4, 58, 86, this.viewportWidth, this.scaleFactor));
          //   this.inputCell(this.readRegisterAddr, UiUtil.vw(8.0, 66, 92, this.viewportWidth, this.scaleFactor), (value: string) => {
          //     this.readRegisterAddr = value;
          //   });
          //
          //   this.labelText('数量', UiUtil.vw(4.6, 36, 52, this.viewportWidth, this.scaleFactor));
          //   this.inputCell(this.readRegisterCount, UiUtil.vw(7.0, 58, 82, this.viewportWidth, this.scaleFactor), (value: string) => {
          //     this.readRegisterCount = value;
          //   });
          //
          //   this.actionButton('读04', () => {
          //     void this.readInputRegisters();
          //   }, UiUtil.vw(6.8, 58, 82, this.viewportWidth, this.scaleFactor));
          // }
          // .width('100%')
          // .height(UiUtil.vh(4.6, 34, 48, this.viewportHeight, this.scaleFactor))
          // .alignItems(VerticalAlign.Center)
          //
          // Row() {
          //   this.labelText('06寄存器');
          //   this.inputCell(this.writeRegisterAddr, UiUtil.vw(8.0, 66, 92, this.viewportWidth, this.scaleFactor), (value: string) => {
          //     this.writeRegisterAddr = value;
          //   });
          //
          //   this.labelText('写入值', UiUtil.vw(5.8, 46, 66, this.viewportWidth, this.scaleFactor));
          //   this.inputCell(this.writeRegisterValue, UiUtil.vw(8.0, 66, 92, this.viewportWidth, this.scaleFactor), (value: string) => {
          //     this.writeRegisterValue = value;
          //   });
          //
          //   this.actionButton('写06', () => {
          //     void this.writeSingleRegister();
          //   }, UiUtil.vw(6.8, 58, 82, this.viewportWidth, this.scaleFactor));
          // }
          // .width('100%')
          // .height(UiUtil.vh(4.6, 34, 48, this.viewportHeight, this.scaleFactor))
          // .alignItems(VerticalAlign.Center)
          //
          // Row({ space: UiUtil.vw(0.7, 6, 10, this.viewportWidth, this.scaleFactor) }) {
          //   this.actionButton('启动测量', () => {
          //     void this.quickWriteControl(0, '启动测量');
          //   });
          //   this.actionButton('停止测量', () => {
          //     void this.quickWriteControl(2, '停止测量');
          //   });
          //   this.actionButton('启动校准', () => {
          //     void this.quickWriteControl(1, '启动校准');
          //   });
          //   this.actionButton('深度清洗', () => {
          //     void this.quickWriteControl(7, '深度清洗');
          //   });
          // }
          // .width('100%')
          // .height(UiUtil.vh(5.0, 36, 52, this.viewportHeight, this.scaleFactor))
          // .alignItems(VerticalAlign.Center)

          this.sectionTitle('日志 / 响应');

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
          .height(UiUtil.vh(22.0, 150, 260, this.viewportHeight, this.scaleFactor))
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
