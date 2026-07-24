import { common } from '@kit.AbilityKit';
import { UiUtil } from 'base';
import { DataPager } from '../../components/data/DataPager';
import { DateRangeFilterBar } from '../../components/data/DateRangeFilterBar';
import {
  ALARM_TYPE_CALIBRATION_EXCEPTION,
  ALARM_TYPE_COMMUNICATION_EXCEPTION,
  ALARM_TYPE_INSTRUMENT_FAULT,
  ALARM_TYPE_MAINTENANCE_TIP,
  ALARM_TYPE_MEASUREMENT_EXCEPTION,
  ALARM_TYPE_REAGENT_EXCEPTION,
  ALARM_TYPE_SYSTEM_EXCEPTION,
  ALARM_TYPE_UPGRADE_EXCEPTION,
  ALL_FILTER_OPTION,
  AlarmRecord,
  DataPageQueryResult
} from '../../models/dataRecordTypes';
import { AlarmRecordService } from '../../services/AlarmRecordService';

@Component
export struct AlarmManagementPanel {
  @Prop viewportWidth: number = 1024;
  @Prop viewportHeight: number = 768;
  @Prop scaleFactor: number = 1.92;
  @State private records: AlarmRecord[] = [];
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
    const context = this.getHostContext();
    if (context) {
      void this.initAndRefresh(context);
    } else {
      void this.refreshRecords();
    }
  }

  private async initAndRefresh(context: common.Context): Promise<void> {
    await AlarmRecordService.init(context);
    await AlarmRecordService.captureCurrentAlarm();
    await this.refreshRecords();
  }

  private getHostContext(): common.Context | null {
    const context = this.getUIContext().getHostContext();
    if (!context) {
      return null;
    }
    return context as common.Context;
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

  private parseDateStart(value: string): number {
    const date = UiUtil.parseDate(value, 0, 0, 0, 0);
    return date ? date.getTime() : 0;
  }

  private parseDateEnd(value: string): number {
    const date = UiUtil.parseDate(value, 23, 59, 59, 999);
    return date ? date.getTime() : 0;
  }

  private async refreshRecords(): Promise<void> {
    if (this.isLoading) {
      return;
    }
    this.isLoading = true;
    try {
      const result = await AlarmRecordService.queryAlarmRecords({
        startTime: this.parseDateStart(this.startDate),
        endTime: this.parseDateEnd(this.endDate),
        alarmType: this.selectedType,
        page: this.currentPage,
        pageSize: this.pageSize
      });
      this.applyQueryResult(result);
    } finally {
      this.isLoading = false;
    }
  }

  private applyQueryResult(result: DataPageQueryResult<AlarmRecord>): void {
    this.records = result.records;
    this.currentPage = result.page;
    this.totalPages = result.totalPages;
    this.totalCount = result.total;
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

          ForEach(this.records, (item: AlarmRecord) => {
            Row() {
              Text(UiUtil.formatDateTimestamp(item.alarmTime))
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
          }, (item: AlarmRecord) => `${item.id}`)

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
          onLast: () => this.goLastPage()
        })
      }
      .layoutWeight(1)
      .alignItems(VerticalAlign.Top)

      DateRangeFilterBar({
        startDate: this.startDate,
        endDate: this.endDate,
        selectedType: this.selectedType,
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
