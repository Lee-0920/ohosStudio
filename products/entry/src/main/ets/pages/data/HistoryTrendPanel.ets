import { common } from '@kit.AbilityKit';
import { TimeTrendChart } from '../../components/chart/TimeTrendChart';
import { ChartPoint, ChartSeries } from '../../models/ChartTypes';
import { DataActionButton } from '../../components/DataActionButton';
import {
  MEASUREMENT_RESULT_TYPE_RANGE_CALIBRATION,
  MEASUREMENT_RESULT_TYPE_WATER_SAMPLE,
  MEASUREMENT_RESULT_TYPE_ZERO_CALIBRATION
} from '../../models/dataRecordTypes';
import { ResultManager, MeasureRecord, MeasureType, MeasureQueryCondition } from 'dataservice';
import { DeviceEventBus } from '../../services/DeviceEventBus';
import { DeviceEvent } from '../../models/deviceStateTypes';
import { UiUtil } from 'base';

const DAY_MS: number = 24 * 60 * 60 * 1000;
const TREND_PAGE_MS: number = 7 * DAY_MS;
const FUTURE_PAGE_TOLERANCE_MS: number = 1000;

interface AxisScale {
  min: number;
  max: number;
}

@Component
export struct HistoryTrendPanel {
  @Prop tab: string = '';
  @Prop viewportWidth: number = 1024;
  @Prop viewportHeight: number = 768;
  @Prop scaleFactor: number = 1.92;
  @State private xStartTime: number = Date.now() - TREND_PAGE_MS;
  @State private xEndTime: number = Date.now();
  @State private trendSeries: ChartSeries[] = [
    { name: MEASUREMENT_RESULT_TYPE_WATER_SAMPLE, color: '#52C41A', points: [] },
    { name: MEASUREMENT_RESULT_TYPE_RANGE_CALIBRATION, color: '#2F6BFF', points: [] },
    { name: MEASUREMENT_RESULT_TYPE_ZERO_CALIBRATION, color: '#FF4D4F', points: [] }
  ];
  @State private yMin: number = 0;
  @State private yMax: number = 1;
  @State private yStep: number = 0.2;
  @State private totalCount: number = 0;
  @State private isLoading: boolean = false;
  @State private panelWidth: number = 0;
  @State private panelHeight: number = 0;
  @State private mainAreaHeight: number = 0;
  private readonly MAX_RECORDS: number = 5000;
  private unsubscribeMeasurement: (() => void) | null = null;

  async aboutToAppear(): Promise<void> {
    const context = this.getHostContext();
    if (context) {
      await ResultManager.getInstance().init(context, { decimalNum: 3, settingUseNum: 3 });
    }
    ResultManager.getInstance().registerNotifiable(this);
    this.unsubscribeMeasurement = DeviceEventBus.subscribe('measurement', (event: DeviceEvent) => {
      this.onMeasurementEvent(event);
    });
    await this.resetToCurrentWindow();
    await this.refreshTrendRecords();
  }

  aboutToDisappear(): void {
    ResultManager.getInstance().unregisterNotifiable(this);
    if (this.unsubscribeMeasurement) {
      this.unsubscribeMeasurement();
      this.unsubscribeMeasurement = null;
    }
  }

  private getHostContext(): common.Context | null {
    const context = this.getUIContext().getHostContext();
    if (!context) {
      return null;
    }
    return context as common.Context;
  }

  private clamp(value: number, min: number, max: number): number {
    return Math.min(max, Math.max(min, value));
  }

  private alignToNextDay(timestamp: number): number {
    const date = new Date(timestamp);
    date.setHours(0, 0, 0, 0);
    return date.getTime() + DAY_MS;
  }

  private getLegendWidth(): number {
    return UiUtil.vw(5.2, 46, 74, this.viewportWidth, this.scaleFactor);
  }

  private getContentWidth(): number {
    if (this.panelWidth > 0) {
      const safeWidth = this.panelWidth - UiUtil.vw(0.4, 2, 6, this.viewportWidth, this.scaleFactor);
      return this.clamp(safeWidth, 440, 1020);
    }
    return UiUtil.vw(88, 780, 1040, this.viewportWidth, this.scaleFactor);
  }

  private getChartWidth(): number {
    const reserved = this.getLegendWidth() + UiUtil.vw(1.0, 8, 14, this.viewportWidth, this.scaleFactor);
    return Math.max(200, this.getContentWidth() - reserved);
  }

  private getChartHeight(): number {
    if (this.mainAreaHeight > 0) {
      return this.clamp(this.mainAreaHeight, 230, 820);
    }
    if (this.panelHeight > 0) {
      const estimated = this.panelHeight - UiUtil.vh(7.0, 48, 84, this.viewportHeight, this.scaleFactor);
      return this.clamp(estimated, 230, this.panelHeight);
    }
    return UiUtil.vh(60, 380, 720, this.viewportHeight, this.scaleFactor);
  }

  private async queryLatestRecordTime(): Promise<number> {
    try {
      const records = await ResultManager.getInstance().getMeasureRecords({ limit: 1, orderBy: 'desc' });
      if (records.length > 0) {
        return records[0].dateTime;
      }
    } catch (err) {
      console.warn('HistoryTrendPanel: 获取最新记录时间失败', err);
    }
    return 0;
  }

  private async resetToCurrentWindow(): Promise<void> {
    const latestTimeSec = await this.queryLatestRecordTime();
    let endTime: number;
    if (latestTimeSec > 0) {
      const latestDate = new Date(latestTimeSec * 1000);
      latestDate.setHours(0, 0, 0, 0);
      endTime = latestDate.getTime() + DAY_MS;
    } else {
      endTime = this.alignToNextDay(Date.now());
    }
    this.xEndTime = endTime;
    this.xStartTime = endTime - TREND_PAGE_MS;
  }

  private async refreshTrendRecords(): Promise<void> {
    if (this.isLoading) {
      return;
    }
    this.isLoading = true;
    try {
      const condition: MeasureQueryCondition = {
        startTime: Math.floor(this.xStartTime / 1000),
        endTime: Math.ceil(this.xEndTime / 1000),
        orderBy: 'desc',
        limit: this.MAX_RECORDS
      };
      const records = await ResultManager.getInstance().getMeasureRecords(condition);
      this.applyTrendRecords(records);
    } finally {
      this.isLoading = false;
    }
  }

  private applyTrendRecords(records: MeasureRecord[]): void {
    const series = this.buildTrendSeries(records);
    this.trendSeries = series;
    this.totalCount = records.length;
    this.applyYAxis(series);
  }

  private buildTrendSeries(records: MeasureRecord[]): ChartSeries[] {
    return [
      {
        name: MEASUREMENT_RESULT_TYPE_WATER_SAMPLE,
        color: '#52C41A',
        points: this.pointsForType(records, MeasureType.Sample)
      },
      {
        name: MEASUREMENT_RESULT_TYPE_RANGE_CALIBRATION,
        color: '#2F6BFF',
        points: this.pointsForType(records, MeasureType.RangeCheck)
      },
      {
        name: MEASUREMENT_RESULT_TYPE_ZERO_CALIBRATION,
        color: '#FF4D4F',
        points: this.pointsForType(records, MeasureType.ZeroCheck)
      }
    ];
  }

  private pointsForType(records: MeasureRecord[], type: MeasureType): ChartPoint[] {
    const points: ChartPoint[] = [];
    records.forEach((item: MeasureRecord) => {
      if (item.resultType === type && !Number.isNaN(item.consistency)) {
        points.push({
          time: item.dateTime * 1000,
          value: item.consistency
        });
      }
    });
    return points;
  }

  private applyYAxis(series: ChartSeries[]): void {
    let maxValue = 0;
    let minValue = 0;
    let hasValue = false;
    series.forEach((line: ChartSeries) => {
      line.points.forEach((point: ChartPoint) => {
        if (!Number.isNaN(point.value)) {
          if (!hasValue) {
            maxValue = point.value;
            minValue = point.value;
            hasValue = true;
          } else {
            maxValue = Math.max(maxValue, point.value);
            minValue = Math.min(minValue, point.value);
          }
        }
      });
    });

    const axis = this.computeAxisScale(minValue, maxValue, hasValue);
    this.yMin = axis.min;
    this.yMax = axis.max;
    this.yStep = this.roundUpNice((axis.max - axis.min) / 5);
  }

  private computeAxisScale(minValue: number, maxValue: number, hasValue: boolean): AxisScale  {
    const AXIS_DEFAULT_VALUE_MAX = 1;
    const AXIS_DEFAULT_VALUE_MIN = 0;
    let axisMax = AXIS_DEFAULT_VALUE_MAX;
    let axisMin = AXIS_DEFAULT_VALUE_MIN;

    if (hasValue) {
      if (maxValue > axisMax) {
        axisMax = 5.0 * (Math.floor(maxValue / 5) + 2);
      }

      if (minValue > axisMin && minValue > 5) {
        axisMin = 5.0 * (Math.floor(minValue / 5) - 1);
        if (axisMax <= axisMin || axisMin < 0) {
          axisMin = AXIS_DEFAULT_VALUE_MIN;
        }
      }

      if ((axisMax - axisMin) > 1000) {
        axisMax = axisMax + axisMax * 0.2;
      }
    }

    return { min: axisMin, max: axisMax };
  }

  private roundUpNice(value: number): number {
    if (value <= 0 || Number.isNaN(value)) {
      return 1;
    }
    const exponent = Math.floor(Math.log(value) / Math.log(10));
    const magnitude = Math.pow(10, exponent);
    const normalized = value / magnitude;
    let nice = 10;
    if (normalized <= 1) {
      nice = 1;
    } else if (normalized <= 2) {
      nice = 2;
    } else if (normalized <= 5) {
      nice = 5;
    }
    return nice * magnitude;
  }

  onMeasureResultAdded(_name: string, record: MeasureRecord): void {
    const recordTimeMs = record.dateTime * 1000;
    if (recordTimeMs > this.xEndTime) {
      let newEnd = this.xEndTime;
      let newStart = this.xStartTime;
      while (recordTimeMs > newEnd) {
        newEnd += TREND_PAGE_MS;
        newStart += TREND_PAGE_MS;
      }
      this.xEndTime = newEnd;
      this.xStartTime = newStart;
    }
    void this.refreshTrendRecords();
  }

  onMeasureResultDeleted(_name: string, count: number): void {
    if (count > 0) {
      void this.resetToCurrentWindow().then(() => this.refreshTrendRecords());
    }
  }

  private onMeasurementEvent(event: DeviceEvent): void {
    if (event.topic !== 'measurement') {
      return;
    }
    if (event.changedKeys.includes('parameter')) {
      this.applyYAxis(this.trendSeries);
    }
  }

  private prevPage(): void {
    if (this.isLoading) {
      return;
    }
    this.xStartTime -= TREND_PAGE_MS;
    this.xEndTime -= TREND_PAGE_MS;
    void this.refreshTrendRecords();
  }

  private nextPage(): void {
    if (this.isLoading) {
      return;
    }
    const latestEnd = this.alignToNextDay(Date.now());
    if (this.xEndTime >= latestEnd - FUTURE_PAGE_TOLERANCE_MS) {
      return;
    }

    let nextStart = this.xStartTime + TREND_PAGE_MS;
    let nextEnd = this.xEndTime + TREND_PAGE_MS;
    if (nextEnd > latestEnd) {
      nextEnd = latestEnd;
      nextStart = latestEnd - TREND_PAGE_MS;
    }
    this.xStartTime = nextStart;
    this.xEndTime = nextEnd;
    void this.refreshTrendRecords();
  }

  private padNumber(value: number): string {
    return value < 10 ? `0${value}` : value.toString();
  }

  private formatDateTime(timestamp: number): string {
    const date = new Date(timestamp);
    return `${this.padNumber(date.getMonth() + 1)}-${this.padNumber(date.getDate())} ` +
      `${this.padNumber(date.getHours())}:${this.padNumber(date.getMinutes())}`;
  }

  private rangeText(): string {
    return `${this.formatDateTime(this.xStartTime)} - ${this.formatDateTime(this.xEndTime)}`;
  }

  build() {
    Column() {
      Row({ space: UiUtil.vw(0.4, 2, 6, this.viewportWidth, this.scaleFactor) }) {
        TimeTrendChart({
          chartWidth: this.getChartWidth(),
          chartHeight: this.getChartHeight(),
          xStartTime: this.xStartTime,
          xEndTime: this.xEndTime,
          yMin: this.yMin,
          yMax: this.yMax,
          yStep: this.yStep,
          series: this.trendSeries,
          xTickIntervalMs: DAY_MS,
          xTickCount: 7,
          xTickFontSize: UiUtil.vh(2.0, 12, 17, this.viewportHeight, this.scaleFactor),
          yTickFontSize: UiUtil.vh(2.0, 12, 20, this.viewportHeight, this.scaleFactor),
          emptyTextFontSize: UiUtil.vh(1.9, 14, 22, this.viewportHeight, this.scaleFactor),
          showEmptyText: true,
          emptyText: this.isLoading ? '正在加载' : '暂无数据'
        });

        Column({ space: UiUtil.vh(0.35, 2, 5, this.viewportHeight, this.scaleFactor) }) {
          ForEach(this.trendSeries, (item: ChartSeries) => {
            Row() {
              Row()
                .width(UiUtil.vw(0.9, 7, 10, this.viewportWidth, this.scaleFactor))
                .height(UiUtil.vh(0.14, 1, 2, this.viewportHeight, this.scaleFactor))
                .backgroundColor(item.color)
                .margin({ right: UiUtil.vw(0.16, 1, 3, this.viewportWidth, this.scaleFactor) });

              Text(item.name)
                .fontSize(UiUtil.vh(0.9, 8, 10, this.viewportHeight, this.scaleFactor))
                .fontColor('#394150')
                .maxLines(1);
            }
            .alignItems(VerticalAlign.Center)
            .width('100%');
          }, (item: ChartSeries) => item.name)
        }
        .width(this.getLegendWidth())
        .padding({
          top: UiUtil.vh(0.5, 3, 6, this.viewportHeight, this.scaleFactor),
          bottom: UiUtil.vh(0.5, 3, 6, this.viewportHeight, this.scaleFactor),
          left: UiUtil.vw(0.35, 2, 5, this.viewportWidth, this.scaleFactor),
          right: UiUtil.vw(0.35, 2, 5, this.viewportWidth, this.scaleFactor)
        })
        .backgroundColor('#F7FAFFCC')
        .borderRadius(UiUtil.vh(0.7, 5, 8, this.viewportHeight, this.scaleFactor))
        .margin({
          top: UiUtil.vh(0.6, 4, 8, this.viewportHeight, this.scaleFactor)
        })
        .alignItems(HorizontalAlign.Start);
      }
      .width(this.getContentWidth())
      .layoutWeight(1)
      .alignItems(VerticalAlign.Top)
      .onAreaChange((_, value) => {
        this.mainAreaHeight = UiUtil.lengthToNumber(value.height);
      });

      Row({ space: UiUtil.vw(0.8, 8, 14, this.viewportWidth, this.scaleFactor) }) {
        Text(`${this.rangeText()}  共 ${this.totalCount} 条`)
          .fontSize(UiUtil.vh(1.45, 10, 13, this.viewportHeight, this.scaleFactor))
          .fontColor('#7A818A')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Blank()

        DataActionButton({
          label: '上一页',
          buttonWidth: UiUtil.vw(8.8, 84, 118, this.viewportWidth, this.scaleFactor),
          buttonHeight: UiUtil.vh(4.1, 30, 40, this.viewportHeight, this.scaleFactor),
          fontSizeValue: UiUtil.vh(1.5, 11, 14, this.viewportHeight, this.scaleFactor),
          borderRadiusValue: UiUtil.vh(0.8, 5, 10, this.viewportHeight, this.scaleFactor),
          onAction: () => this.prevPage()
        })

        DataActionButton({
          label: '下一页',
          buttonWidth: UiUtil.vw(8.8, 84, 118, this.viewportWidth, this.scaleFactor),
          buttonHeight: UiUtil.vh(4.1, 30, 40, this.viewportHeight, this.scaleFactor),
          fontSizeValue: UiUtil.vh(1.5, 11, 14, this.viewportHeight, this.scaleFactor),
          borderRadiusValue: UiUtil.vh(0.8, 5, 10, this.viewportHeight, this.scaleFactor),
          onAction: () => this.nextPage()
        })
      }
      .width(this.getContentWidth())
      .margin({ bottom: UiUtil.vh(0.6, 4, 8, this.viewportHeight, this.scaleFactor) })
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.End);
    }
    .layoutWeight(1)
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Start)
    .padding({
      left: 0,
      right: UiUtil.vw(0.2, 0, 3, this.viewportWidth, this.scaleFactor),
      top: UiUtil.vh(0.8, 6, 10, this.viewportHeight, this.scaleFactor),
      bottom: 0
    })
    .onAreaChange((_, value) => {
      this.panelWidth = UiUtil.lengthToNumber(value.width);
      this.panelHeight = UiUtil.lengthToNumber(value.height);
    })
    .backgroundColor('#FFFFFF');
  }
}
