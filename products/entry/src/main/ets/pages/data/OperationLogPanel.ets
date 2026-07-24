import { DataPager } from '../../components/data/DataPager';
import { DateRangeFilterBar } from '../../components/data/DateRangeFilterBar';
import { readAllLogs, clearLogFile, deleteLogFile, getAllLogFilesInfo, LogFileInfo, Logger } from 'logger';
import { UiUtil } from 'base';

interface LogEntry {
  dateTime: string;
  level: string;
  content: string;
}

@Component
export struct OperationLogPanel {
  // Current selected tab label, kept for compatibility.
  @Prop tab: string = '';
  @Prop viewportWidth: number = 1024;
  @Prop viewportHeight: number = 768;
  @Prop scaleFactor: number = 1.92;
  @State private records: LogEntry[] = [];
  @State private currentPage: number = 1;
  @State private totalPages: number = 1;
  @State private totalCount: number = 0;
  @State private startDate: string = '';
  @State private endDate: string = '';
  @State private selectedType: string = '';
  @State private isLoading: boolean = false;
  private readonly pageSize: number = 6;

  aboutToAppear(): void {
    this.ensureDefaultDates();
    void this.refreshRecords();
  }

  private timeColumnWidth(): number {
    return UiUtil.vw(9.4, 152, 190, this.viewportWidth, this.scaleFactor);
  }

  private ensureDefaultDates(): void {
    if (this.startDate.length > 0 && this.endDate.length > 0) {
      return;
    }
    const end = new Date();
    const start = new Date(end.getTime());
    start.setDate(end.getDate() - 30);
    this.startDate = this.formatDate(start);
    this.endDate = this.formatDate(end);
  }

  private padNumber(value: number): string {
    return value < 10 ? `0${value}` : value.toString();
  }

  private formatDate(date: Date): string {
    return `${date.getFullYear()}-${this.padNumber(date.getMonth() + 1)}-${this.padNumber(date.getDate())}`;
  }

  private async refreshRecords(): Promise<void> {
    if (this.isLoading) {
      return;
    }
    this.isLoading = true;
    try {
      const filesInfo = getAllLogFilesInfo();
      const runLogFile = filesInfo.find((f: LogFileInfo) => f.fileName === 'RunLog.txt');
      if (!runLogFile) {
        this.records = [];
        this.totalCount = 0;
        this.totalPages = 1;
        this.currentPage = 1;
        return;
      }

      const allLogs = readAllLogs(runLogFile.fileName);
      const lines = allLogs.split('\n');
      const startStr = this.startDate;
      const endStr = this.endDate;

      const filtered: LogEntry[] = [];
      for (const line of lines) {
        const trimmed = line.trim();
        if (trimmed.length === 0) {
          continue;
        }
        const entry = this.parseLogLine(trimmed);
        if (!entry) {
          continue;
        }
        const entryDate = entry.dateTime.substring(0, 10);
        if (entryDate >= startStr && entryDate <= endStr) {
          filtered.push(entry);
        }
      }

      filtered.sort((a, b) => b.dateTime.localeCompare(a.dateTime));

      this.totalCount = filtered.length;
      this.totalPages = Math.max(1, Math.ceil(this.totalCount / this.pageSize));
      this.currentPage = Math.min(Math.max(1, this.currentPage), this.totalPages);
      const start = (this.currentPage - 1) * this.pageSize;
      const end = start + this.pageSize;
      this.records = filtered.slice(start, end);
    } catch (err) {
      Logger.error(`读取运行日志失败: ${err}`);
      // this.getUIContext().showAlertDialog({
      //   title: '提示',
      //   message: `读取运行日志失败: ${err}`,
      //   confirm: { value: '确定', action: () => {} }
      // });
      this.records = [];
      this.totalCount = 0;
      this.totalPages = 1;
      this.currentPage = 1;
    } finally {
      this.isLoading = false;
    }
  }

  private parseLogLine(line: string): LogEntry | null {
    const regex = /^(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2})\s+\[(\w+)\]:\s*(.*)$/;
    const match = line.match(regex);
    if (!match) {
      return null;
    }
    const dateTime = match[1];
    const level = match[2];
    const content = match[3];
    if (/^\*+$/.test(content.trim())) {
      return null;
    }
    return { dateTime, level, content };
  }

  private getEmptyRowIndexes(): number[] {
    const rows: number[] = [];
    for (let i = this.records.length; i < this.pageSize; i++) {
      rows.push(i);
    }
    return rows;
  }

  private queryFromFirstPage(): void {
    this.currentPage = 1;
    void this.refreshRecords();
  }

  private goFirstPage(): void {
    this.currentPage = 1;
    void this.refreshRecords();
  }

  private goPreviousPage(): void {
    this.currentPage = this.currentPage > 1 ? this.currentPage - 1 : 1;
    void this.refreshRecords();
  }

  private goNextPage(): void {
    this.currentPage = this.currentPage < this.totalPages ? this.currentPage + 1 : this.totalPages;
    void this.refreshRecords();
  }

  private goLastPage(): void {
    this.currentPage = this.totalPages;
    void this.refreshRecords();
  }

  private showConfirmDialog(message: string): Promise<boolean> {
    return new Promise((resolve) => {
      this.getUIContext().showAlertDialog({
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

  private async clearLogs(): Promise<void> {
    try {
      // 显示确认对话框
      const confirmed = await this.showConfirmDialog('是否清除运行日志？');
      if (!confirmed) {
        // this.logText = '已取消清除操作';
        return;
      }

      const filesInfo = getAllLogFilesInfo();
      const runLogFile = filesInfo.filter((f: LogFileInfo) => f.fileName.includes('RunLog.txt'));

      if (runLogFile.length === 0) {
        // this.logText = '未找到系统日志文件';
        return;
      }

      let allSuccess = true;
      let deletedCount = 0;

      for (const fileInfo of runLogFile) {
        // 主日志文件（RunLog.txt）只清空内容，备份文件（RunLog.txt.1等）直接删除
        if (fileInfo.fileName === 'RunLog.txt') {
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
        this.getUIContext().showAlertDialog({
          title: '提示',
          message: deletedCount > 0
            ? `运行日志已清空（已删除${deletedCount}个历史日志文件）`
            : '运行日志已清空',
          confirm: { value: '确定', action: () => {} }
        });
        this.refreshRecords();
      } else {
        this.getUIContext().showAlertDialog({
          title: '提示',
          message: '清空运行日志失败',
          confirm: { value: '确定', action: () => {} }
        });
      }
    } catch (err) {
      this.getUIContext().showAlertDialog({
        title: '提示',
        message: `清空失败\n ${err}`,
        confirm: { value: '确定', action: () => {} }
      });
    }
  }

  build() {
    Column() {
      Row() {
        Column() {
          Row() {
            Text('时间')
              .fontSize(UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor))
              .fontWeight(FontWeight.Bold)
              .width(this.timeColumnWidth())
              .textAlign(TextAlign.Center)
            Text('内容')
              .fontSize(UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor))
              .fontWeight(FontWeight.Bold)
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
          }
          .height(UiUtil.vh(4.8, 36, 52, this.viewportHeight, this.scaleFactor))
          .backgroundColor('#F0F0F0')
          .border({ width: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor), color: '#DADADA' })

          ForEach(this.records, (item: LogEntry) => {
            Row() {
              Text(item.dateTime)
                .fontSize(UiUtil.vh(1.7, 11, 14, this.viewportHeight, this.scaleFactor))
                .width(this.timeColumnWidth())
                .textAlign(TextAlign.Center)
                .maxLines(1)
              Text(item.content)
                .fontSize(UiUtil.vh(1.8, 11, 15, this.viewportHeight, this.scaleFactor))
                .layoutWeight(1)
                .textAlign(TextAlign.Center)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .height(UiUtil.vh(4.5, 34, 50, this.viewportHeight, this.scaleFactor))
            .border({ width: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor), color: '#E5E5E5' })
          }, (item: LogEntry) => `${item.dateTime}-${item.level}-${item.content}`)

          ForEach(this.getEmptyRowIndexes(), (idx: number) => {
            Row() {
              Text('').width(this.timeColumnWidth())
              Text('').layoutWeight(1)
            }
            .height(UiUtil.vh(4.5, 34, 50, this.viewportHeight, this.scaleFactor))
            .border({ width: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor), color: '#E5E5E5' })
          }, (idx: number) => `empty-${idx}`)
        }
        .layoutWeight(1)
        .height('100%')
        .clip(true)
        .border({ width: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor), color: '#CCCCCC' })

        DataPager({
          currentPage: this.currentPage,
          totalPages: this.totalPages,
          viewportWidth: this.viewportWidth,
          viewportHeight: this.viewportHeight,
          scaleFactor: this.scaleFactor,
          showExport: false,
          onFirst: () => this.goFirstPage(),
          onPrevious: () => this.goPreviousPage(),
          onNext: () => this.goNextPage(),
          onLast: () => this.goLastPage(),
          onClear: () => {
            void this.clearLogs();
          }
        })
      }
      .layoutWeight(1)
      .alignItems(VerticalAlign.Top)

      DateRangeFilterBar({
        startDate: $startDate,
        endDate: $endDate,
        selectedType: $selectedType,
        showTypeFilter: false,
        viewportWidth: this.viewportWidth,
        viewportHeight: this.viewportHeight,
        scaleFactor: this.scaleFactor,
        onQuery: () => this.queryFromFirstPage()
      })
        .margin({ top: UiUtil.vh(2.0, 12, 22, this.viewportHeight, this.scaleFactor) })

      Text(`共 ${this.totalCount} 条`)
        .fontSize(UiUtil.vh(1.45, 10, 13, this.viewportHeight, this.scaleFactor))
        .fontColor('#7A818A')
        .width('100%')
        .textAlign(TextAlign.End)
        .margin({
          top: UiUtil.vh(0.5, 3, 6, this.viewportHeight, this.scaleFactor),
          right: UiUtil.vw(7.6, 72, 104, this.viewportWidth, this.scaleFactor)
        })
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .padding({
      left: UiUtil.vw(0.8, 6, 10, this.viewportWidth, this.scaleFactor),
      right: UiUtil.vw(0.8, 6, 10, this.viewportWidth, this.scaleFactor),
      top: UiUtil.vh(0.8, 6, 10, this.viewportHeight, this.scaleFactor),
      bottom: UiUtil.vh(0.8, 6, 10, this.viewportHeight, this.scaleFactor)
    })
    .backgroundColor('#FFFFFF')
  }
}
