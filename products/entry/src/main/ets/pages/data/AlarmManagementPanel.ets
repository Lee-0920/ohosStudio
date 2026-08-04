import { common } from '@kit.AbilityKit';
import { UiUtil } from 'base';
import { DataPager } from '../../components/data/DataPager';
import { DateRangeFilterBar } from '../../components/data/DateRangeFilterBar';
import {
  ALL_FILTER_OPTION,
  ALARM_TYPE_CALIBRATION_EXCEPTION,
  ALARM_TYPE_COMMUNICATION_EXCEPTION,
  ALARM_TYPE_INSTRUMENT_FAULT,
  ALARM_TYPE_MAINTENANCE_TIP,
  ALARM_TYPE_MEASUREMENT_EXCEPTION,
  ALARM_TYPE_REAGENT_EXCEPTION,
  ALARM_TYPE_SYSTEM_EXCEPTION,
  ALARM_TYPE_UPGRADE_EXCEPTION
} from '../../models/dataRecordTypes';
import { AlarmRecordService } from '../../services/AlarmRecordService';
import { AlarmManager, AlarmRecord } from 'alarm';
import fs from '@ohos.file.fs';
import picker from '@ohos.file.picker';

// 界面展示用的告警记录结构（ArkTS 要求显式接口，不能内联对象字面量类型）
interface DisplayAlarmRecord {
  id: string;
  alarmTime: number;
  alarmType: string;
  content: string;
}

@Component
export struct AlarmManagementPanel {
  @Prop viewportWidth: number = 1024;
  @Prop viewportHeight: number = 768;
  @Prop scaleFactor: number = 1.92;
  @State private records: DisplayAlarmRecord[] = [];
  @State private currentPage: number = 1;
  @State private totalPages: number = 1;
  @State private totalCount: number = 0;
  @State private startDate: string = '';
  @State private endDate: string = '';
  @State private selectedType: string = ALL_FILTER_OPTION;
  @State private isLoading: boolean = false;
  private readonly pageSize: number = 6;
  private readonly alarmTypeOptions: SelectOption[] = [
    { value: ALL_FILTER_OPTION },
    { value: ALARM_TYPE_SYSTEM_EXCEPTION },
    { value: ALARM_TYPE_COMMUNICATION_EXCEPTION },
    { value: ALARM_TYPE_INSTRUMENT_FAULT },
    { value: ALARM_TYPE_MAINTENANCE_TIP },
    { value: ALARM_TYPE_UPGRADE_EXCEPTION },
    { value: ALARM_TYPE_MEASUREMENT_EXCEPTION },
    { value: ALARM_TYPE_REAGENT_EXCEPTION },
    { value: ALARM_TYPE_CALIBRATION_EXCEPTION }
  ];

  aboutToAppear(): void {
    this.ensureDefaultDates();
    void this.refreshRecords();
  }

  private ensureDefaultDates(): void {
    if (this.startDate.length > 0 && this.endDate.length > 0) {
      return;
    }
    const end = new Date();
    const start = new Date(end.getTime());
    start.setDate(end.getDate() - 30);
    this.startDate = UiUtil.formatDate(start);
    this.endDate = UiUtil.formatDate(end);
  }

  private buildDisplayRecord(record: AlarmRecord): DisplayAlarmRecord {
    const alarmType = AlarmRecordService.classifyAlarmCode(record.alarmCode);
    const content = record.cause.length > 0 ? `${record.name}(${record.cause})` : record.name;
    return {
      id: record.id,
      alarmTime: record.triggeredAt,
      alarmType: alarmType,
      content: content
    };
  }

  private formatTimestamp(ts: number): string {
    return AlarmRecord.formatTimestamp(ts);
  }

  private extractDate(ts: number): string {
    return this.formatTimestamp(ts).substring(0, 10);
  }

  private async refreshRecords(): Promise<void> {
    if (this.isLoading) {
      return;
    }
    this.isLoading = true;
    try {
      const allRecords = AlarmManager.getInstance().getAllRecords();
      const filtered: DisplayAlarmRecord[] = [];

      for (const record of allRecords) {
        const displayRecord = this.buildDisplayRecord(record);
        const recordDate = this.extractDate(displayRecord.alarmTime);
        if (recordDate < this.startDate || recordDate > this.endDate) {
          continue;
        }
        if (this.selectedType !== ALL_FILTER_OPTION && displayRecord.alarmType !== this.selectedType) {
          continue;
        }
        filtered.push(displayRecord);
      }

      filtered.sort((a: DisplayAlarmRecord, b: DisplayAlarmRecord) => {
        return b.alarmTime - a.alarmTime;
      });

      this.totalCount = filtered.length;
      this.totalPages = Math.max(1, Math.ceil(this.totalCount / this.pageSize));
      this.currentPage = Math.min(Math.max(1, this.currentPage), this.totalPages);
      const start = (this.currentPage - 1) * this.pageSize;
      const end = start + this.pageSize;
      this.records = filtered.slice(start, end);
    } catch (err) {
      console.error(`读取告警记录失败: ${(err as Error).message ?? err}`);
      this.records = [];
      this.totalCount = 0;
      this.totalPages = 1;
      this.currentPage = 1;
    } finally {
      this.isLoading = false;
    }
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

  private async exportAlarmLog(): Promise<void> {
    try {
      const text = AlarmManager.getInstance().readAlarmLogText();
      if (!text || text.trim().length === 0) {
        this.getUIContext().showAlertDialog({
          title: '提示',
          message: '暂无告警日志可导出',
          confirm: { value: '确定', action: () => {} }
        });
        return;
      }

      const now = new Date();
      const pad = (value: number): string => value < 10 ? `0${value}` : value.toString();
      const fileName = `AlarmLog_${now.getFullYear()}${pad(now.getMonth() + 1)}${pad(now.getDate())}_` +
        `${pad(now.getHours())}${pad(now.getMinutes())}${pad(now.getSeconds())}.txt`;

      const context = this.getUIContext().getHostContext() as common.Context;
      const documentPicker = new picker.DocumentViewPicker(context);
      const saveOptions = new picker.DocumentSaveOptions();
      saveOptions.newFileNames = [fileName];
      saveOptions.fileSuffixChoices = ['.txt'];
      const uri = await documentPicker.save(saveOptions);
      if (!uri) {
        return;
      }
      const targetUri = Array.isArray(uri) ? uri[0] : uri;
      const file = fs.openSync(targetUri, fs.OpenMode.CREATE | fs.OpenMode.TRUNC | fs.OpenMode.WRITE_ONLY);
      fs.writeSync(file.fd, text);
      fs.closeSync(file);
      this.getUIContext().showAlertDialog({
        title: '提示',
        message: '告警日志导出成功',
        confirm: { value: '确定', action: () => {} }
      });
    } catch (err) {
      this.getUIContext().showAlertDialog({
        title: '提示',
        message: `导出失败\n ${(err as Error).message ?? err}`,
        confirm: { value: '确定', action: () => {} }
      });
    }
  }

  private async clearAlarmRecords(): Promise<void> {
    try {
      const confirmed = await this.showConfirmDialog('是否清空所有告警记录？');
      if (!confirmed) {
        return;
      }
      const success = AlarmManager.getInstance().clearAllRecords();
      if (success) {
        this.getUIContext().showAlertDialog({
          title: '提示',
          message: '告警记录已清空',
          confirm: { value: '确定', action: () => {} }
        });
        this.currentPage = 1;
        void this.refreshRecords();
      } else {
        this.getUIContext().showAlertDialog({
          title: '提示',
          message: '清空告警记录失败',
          confirm: { value: '确定', action: () => {} }
        });
      }
    } catch (err) {
      this.getUIContext().showAlertDialog({
        title: '提示',
        message: `清空失败\n ${(err as Error).message ?? err}`,
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
              .layoutWeight(1.15)
              .textAlign(TextAlign.Center)
            Text('类别')
              .fontSize(UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor))
              .fontWeight(FontWeight.Bold)
              .layoutWeight(0.95)
              .textAlign(TextAlign.Center)
            Text('内容')
              .fontSize(UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor))
              .fontWeight(FontWeight.Bold)
              .layoutWeight(2.1)
              .textAlign(TextAlign.Center)
          }
          .height(UiUtil.vh(4.8, 36, 52, this.viewportHeight, this.scaleFactor))
          .backgroundColor('#F0F0F0')
          .border({ width: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor), color: '#DADADA' })

          ForEach(this.records, (item: DisplayAlarmRecord) => {
            Row() {
              Text(this.formatTimestamp(item.alarmTime))
                .fontSize(UiUtil.vh(1.8, 11, 15, this.viewportHeight, this.scaleFactor))
                .layoutWeight(1.15)
                .textAlign(TextAlign.Center)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(item.alarmType)
                .fontSize(UiUtil.vh(1.8, 11, 15, this.viewportHeight, this.scaleFactor))
                .layoutWeight(0.95)
                .textAlign(TextAlign.Center)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(item.content)
                .fontSize(UiUtil.vh(1.8, 11, 15, this.viewportHeight, this.scaleFactor))
                .layoutWeight(2.1)
                .textAlign(TextAlign.Center)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .height(UiUtil.vh(4.5, 34, 50, this.viewportHeight, this.scaleFactor))
            .border({ width: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor), color: '#E5E5E5' })
          }, (item: DisplayAlarmRecord) => item.id)

          ForEach(this.getEmptyRowIndexes(), (idx: number) => {
            Row() {
              Text('').layoutWeight(1.15)
              Text('').layoutWeight(0.95)
              Text('').layoutWeight(2.1)
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
          onFirst: () => this.goFirstPage(),
          onPrevious: () => this.goPreviousPage(),
          onNext: () => this.goNextPage(),
          onLast: () => this.goLastPage(),
          onExport: () => {
            void this.exportAlarmLog();
          },
          onClear: () => {
            void this.clearAlarmRecords();
          }
        })
      }
      .layoutWeight(1)
      .alignItems(VerticalAlign.Top)

      DateRangeFilterBar({
        startDate: $startDate,
        endDate: $endDate,
        selectedType: $selectedType,
        typeLabel: '类型',
        typeOptions: this.alarmTypeOptions,
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
