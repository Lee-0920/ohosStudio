import { readAllLogs, clearLogFile, deleteLogFile, getAllLogFilesInfo, LogFileInfo } from 'logger';
import { BusinessError } from '@kit.BasicServicesKit';
import deviceInfo from '@ohos.deviceInfo';

interface LogEntry {
  date: string;
  level: string;
  content: string;
}

@Entry
@Component
struct RunLog {
  @State startTime: number = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).getTime();
  @State endTime: number = new Date(Date.now()).getTime();
  @State logEntries: LogEntry[] = [];
  @State logText: string = '';

  aboutToAppear() {
    this.searchLogs();
  }

  private backToMain(): void {
    let uiContext: UIContext = this.getUIContext();
    let router = uiContext.getRouter();
    try {
      router.back();
      console.info('Succeeded in returning to the main page.');
    } catch (err) {
      let code = (err as BusinessError).code;
      let message = (err as BusinessError).message;
      console.error(`Failed to return. Code is ${code}, message is ${message}`);
    }
  }

  private formatDate(timestamp: number): string {
    const date = new Date(timestamp);
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  private parseLogLine(line: string): LogEntry | null {
    // 匹配格式: YYYY-MM-DD HH:MM:SS [LEVEL]: content
    const regex = /^(\d{4}-\d{2}-\d{2})\s+\d{2}:\d{2}:\d{2}\s+\[(\w+)\]:\s*(.*)$/;
    const match = line.match(regex);
    if (!match) {
      return null;
    }
    const date = match[1];
    const level = match[2];
    const content = match[3];
    // 过滤掉全是星号的行
    if (/^\*+$/.test(content.trim())) {
      return null;
    }
    return { date, level, content };
  }

  private searchLogs(): void {
    try {
      // 检测是否在模拟器中运行
      const isEmulator = this.checkIsEmulator();
      if (isEmulator) {
        this.logText = '模拟器环境下无法读取日志文件\n请在真机上测试此功能';
        this.logEntries = [];
        return;
      }

      const filesInfo = getAllLogFilesInfo();
      const runLogFile = filesInfo.find((f: LogFileInfo) => f.fileName.includes('RunLog'));
      if (!runLogFile) {
        this.logText = '未找到运行日志文件';
        this.logEntries = [];
        return;
      }
      const allLogs = readAllLogs(runLogFile.fileName);
      const lines = allLogs.split('\n');
      const startStr = this.formatDate(this.startTime);
      const endStr = this.formatDate(this.endTime);

      const filtered: LogEntry[] = [];
      for (let i = 0; i < lines.length; i++) {
        const line = lines[i].trim();
        if (line.length === 0) continue;
        const entry = this.parseLogLine(line);
        if (entry && entry.date >= startStr && entry.date <= endStr) {
          filtered.push(entry);
        }
      }
      this.logEntries = filtered;
      this.logText = `共找到 ${filtered.length} 条日志`;
    } catch (err) {
      this.logText = `读取日志失败: ${err}`;
      this.logEntries = [];
    }
  }

  private async clearLogs(): Promise<void> {
    try {
      // 显示确认对话框
      const confirmed = await this.showConfirmDialog('是否清除系统日志？');
      if (!confirmed) {
        this.logText = '已取消清除操作';
        return;
      }

      const filesInfo = getAllLogFilesInfo();
      const runLogFile = filesInfo.filter((f: LogFileInfo) => f.fileName.includes('RunLog.txt'));

      if (runLogFile.length === 0) {
        this.logText = '未找到系统日志文件';
        return;
      }

      let allSuccess = true;
      let deletedCount = 0;

      for (const fileInfo of runLogFile) {
        // 主日志文件（RunLog.txt）只清空内容，备份文件（RunLog.txt.1等）直接删除
        if (fileInfo.fileName === 'log.txt') {
          const success = clearLogFile(fileInfo.fileName);
          if (!success) {
            allSuccess = false;
          }
        } else {
          const success = deleteLogFile(fileInfo.fileName);
          if (success) {
            deletedCount++;
          } else {
            allSuccess = false;
          }
        }
      }

      if (allSuccess) {
        this.logText = deletedCount > 0
          ? `系统日志已清空（已删除${deletedCount}个历史日志文件）`
          : '系统日志已清空';
        this.searchLogs();
      } else {
        this.logText = '清空系统日志失败';
      }
    } catch (err) {
      this.logText = `清空失败: ${err}`;
    }
  }

  private checkIsEmulator(): boolean {
    try {
      const deviceType = deviceInfo.deviceType;
      console.info('设备类型:', deviceType);

      if (deviceType.includes('tablet') || deviceType.includes('phone')) {
        return true;
      }

      return false;
    } catch (err) {
      console.error('检测设备信息失败:', err);
      return false;
    }
  }

  private showConfirmDialog(message: string): Promise<boolean> {
    return new Promise((resolve) => {
      AlertDialog.show({
        title: '确认',
        message: message,
        autoCancel: true,
        alignment: DialogAlignment.Center,
        primaryButton: {
          value: '取消',
          action: () => { resolve(false); }
        },
        secondaryButton: {
          value: '确定',
          action: () => { resolve(true); }
        }
      });
    });
  }

  @Builder
  buildLogRow(entry: LogEntry, index: number) {
    Row() {
      Text(entry.date)
        .fontSize(13)
        .fontColor('#666')
        .width('18%')
        .textAlign(TextAlign.Center)

      Text(entry.level)
        .fontSize(13)
        .fontColor(this.getLevelColor(entry.level))
        .width('14%')
        .textAlign(TextAlign.Center)
        .padding({ left: 4, right: 4 })
        .backgroundColor(this.getLevelBgColor(entry.level))
        .borderRadius(4)

      Text(entry.content)
        .fontSize(13)
        .fontColor('#333')
        .layoutWeight(1)
        .textAlign(TextAlign.Start)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor(index % 2 === 0 ? '#FFFFFF' : '#FAFAFA')
    .border({ width: { bottom: 1 }, color: '#F0F0F0' })
  }

  private getLevelColor(level: string): string {
    switch (level.toUpperCase()) {
      case 'ERROR':
        return '#F44336';
      case 'WARN':
        return '#FF9800';
      case 'INFO':
        return '#4CAF50';
      case 'DEBUG':
        return '#2196F3';
      default:
        return '#666';
    }
  }

  private getLevelBgColor(level: string): string {
    switch (level.toUpperCase()) {
      case 'ERROR':
        return '#FFEBEE';
      case 'WARN':
        return '#FFF3E0';
      case 'INFO':
        return '#E8F5E9';
      case 'DEBUG':
        return '#E3F2FD';
      default:
        return '#F5F5F5';
    }
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Button('← 返回')
          .fontSize(14)
          .fontColor('#333')
          .backgroundColor('#F5F5F5')
          .width(80)
          .height(36)
          .onClick(() => { this.backToMain(); })

        Text('运行日志')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Blank().width(80)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor('#FFFFFF')
      .border({ width: { bottom: 1 }, color: '#E0E0E0' })

      // 筛选区域
      Column() {
        Row() {
          DatePicker({
            start: new Date('2000-1-1'),
            end: new Date('2100-12-31'),
            selected: new Date(this.startTime)
          })
            .onChange((value: DatePickerResult) => {
              const y = value.year as number;
              const m = (value.month as number) + 1;
              const d = value.day as number;
              const startDate = new Date(`${y}-${m}-${d}`);
              this.startTime = startDate.getTime();
            })
            .height(40)
            .width('30%')
            .margin({ left: 30 })

          Text('~').fontSize(14).margin({ left: 8, right: 8 })

          DatePicker({
            start: new Date('2000-1-1'),
            end: new Date('2100-12-31'),
            selected: new Date(this.endTime)
          })
            .onChange((value: DatePickerResult) => {
              const y = value.year as number;
              const m = (value.month as number) + 1;
              const d = value.day as number;
              const endDate = new Date(`${y}-${m}-${d}`);
              this.endTime = endDate.getTime() + 24 * 60 * 60 * 1000 - 1;
            })
            .height(40)
            .width('30%')

          Button('检索')
            .fontSize(14)
            .fontColor('#FFFFFF')
            .backgroundColor('#007DFF')
            .height(36)
            .layoutWeight(1)
            .margin({ right: 5 })
            .onClick(() => { this.searchLogs(); })

          Button('清空')
            .fontSize(14)
            .fontColor('#FFFFFF')
            .backgroundColor('#F44336')
            .height(36)
            .layoutWeight(1)
            .margin({ right: 5 })
            .onClick(() => { this.clearLogs(); })
        }
        .width('100%')
        .margin({ bottom: 12 })

        Text(this.logText)
          .fontSize(12)
          .fontColor('#999')
          .margin({ bottom: 8 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 16 })
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .margin({ left: 16, right: 16, bottom: 12 })
      .shadow({ radius: 4, color: '#10000000', offsetY: 2 })

      // 日志表格
      Column() {
        // 表头
        Row() {
          Text('时间')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor('#666')
            .width('18%')
            .textAlign(TextAlign.Center)
          Text('等级')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor('#666')
            .width('14%')
            .textAlign(TextAlign.Center)
          Text('内容')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor('#666')
            .layoutWeight(1)
            .textAlign(TextAlign.Start)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .backgroundColor('#F5F5F5')
        .borderRadius({ topLeft: 12, topRight: 12 })

        // 数据列表
        Scroll() {
          Column() {
            if (this.logEntries.length === 0) {
              Text('暂无日志数据')
                .fontSize(14)
                .fontColor('#999')
                .width('100%')
                .textAlign(TextAlign.Center)
                .padding({ top: 40, bottom: 40 })
            } else {
              ForEach(this.logEntries, (entry: LogEntry, index: number) => {
                this.buildLogRow(entry, index)
              }, (entry: LogEntry, index: number) => `${entry.date}-${entry.level}-${index}`)
            }
          }
          .width('100%')
        }
        .layoutWeight(1)
        .width('100%')
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring)
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .margin({ left: 16, right: 16, bottom: 16 })
      .shadow({ radius: 4, color: '#10000000', offsetY: 2 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
