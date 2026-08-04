import { common } from '@kit.AbilityKit';
import { DataActionButton } from '../../components/DataActionButton';
import { DataPager } from '../../components/data/DataPager';
import { ALL_FILTER_OPTION } from '../../models/dataRecordTypes';
import { ResultManager, MeasureRecord, MeasureType, ResultMode, MeasureQueryCondition } from 'dataservice';
import { UiUtil } from 'base';

@Component
export struct MeasurementDataPanel {
  // Current selected tab label, kept for compatibility.
  @Prop tab: string = '';
  @Prop viewportWidth: number = 1024;
  @Prop viewportHeight: number = 768;
  @Prop scaleFactor: number = 1.92;
  @State private records: MeasureRecord[] = [];
  @State private currentPage: number = 1;
  @State private totalPages: number = 1;
  @State private totalCount: number = 0;
  @State private selectedType: string = ALL_FILTER_OPTION;
  @State private selectedFlag: string = ALL_FILTER_OPTION;
  @State private startDate: string = '';
  @State private endDate: string = '';
  @State private isLoading: boolean = false;
  private readonly pageSize: number = 6;
  private readonly typeOptions: SelectOption[] = [
    { value: ALL_FILTER_OPTION },
    { value: '水样' },
    { value: '零点校准液' },
    { value: '量程校准液' },
    { value: '跨度(标样)核查' },
    { value: '质控样' }
  ];
  private readonly flagOptions: SelectOption[] = [
    { value: ALL_FILTER_OPTION },
    { value: '正常' },
    { value: '超上限' },
    { value: '超下限' },
    { value: '电源故障' },
    { value: '仪器故障' },
    { value: '仪器通信故障' },
    { value: '仪器离线' },
    { value: '取水点无水样' },
    { value: '手工输入数据' },
    { value: '维护调试数据' },
    { value: '非水样结果' }
  ];
  private selectedStartDate: Date = new Date();
  private selectedEndDate: Date = new Date();

  async aboutToAppear(): Promise<void> {
    this.ensureDefaultDates();
    const context = this.getUIContext().getHostContext() as common.Context | undefined;
    if (context) {
      const ready = await ResultManager.getInstance().init(context, { decimalNum: 3, settingUseNum: 3 });
      console.info(`MeasurementDataPanel: ResultManager init result: ${ready}`);
    } else {
      console.warn('MeasurementDataPanel: 无法获取 host context');
    }
    void this.refreshRecords();
    this.selectedStartDate.setDate(this.selectedEndDate.getDate() - 30);
  }

  private timeColumnWidth(): number {
    return UiUtil.vw(8.8, 140, 176, this.viewportWidth, this.scaleFactor);
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
    return date ? Math.floor(date.getTime() / 1000) : 0;
  }

  private parseDateEnd(value: string): number {
    const date = UiUtil.parseDate(value, 23, 59, 59, 999);
    return date ? Math.floor(date.getTime() / 1000) : 0;
  }

  private async refreshRecords(): Promise<void> {
    if (this.isLoading) {
      return;
    }
    this.isLoading = true;
    try {
      const resultManager = ResultManager.getInstance();
      const ready = resultManager.isReady();
      const condition = this.buildMeasureQueryCondition();
      console.info(`MeasurementDataPanel: ResultManager ready=${ready}, condition=${JSON.stringify(condition)}`);
      this.totalCount = await resultManager.getMeasureRecordCount(condition);
      console.info(`MeasurementDataPanel: totalCount=${this.totalCount}`);
      this.totalPages = Math.max(1, Math.ceil(this.totalCount / this.pageSize));
      this.currentPage = Math.min(Math.max(1, this.currentPage), this.totalPages);
      condition.limit = this.pageSize;
      condition.offset = (this.currentPage - 1) * this.pageSize;
      this.records = await resultManager.getMeasureRecords(condition);
      console.info(`MeasurementDataPanel: records.length=${this.records.length}`);
    } finally {
      this.isLoading = false;
    }
  }

  private buildMeasureQueryCondition(): MeasureQueryCondition {
    const condition: MeasureQueryCondition = {
      startTime: this.parseDateStart(this.startDate),
      endTime: this.parseDateEnd(this.endDate),
      orderBy: 'desc'
    };
    const mode = this.flagLabelToMode(this.selectedFlag);
    if (mode !== undefined) {
      condition.mode = mode;
    }
    const resultType = this.typeLabelToMeasureType(this.selectedType);
    if (resultType !== undefined) {
      condition.resultType = resultType;
    }
    return condition;
  }

  private flagLabelToMode(label: string): number | undefined {
    switch (label) {
      case '正常':
        return ResultMode.Normal;
      case '超上限':
        return ResultMode.OverUpper;
      case '超下限':
        return ResultMode.OverRange;
      case '电源故障':
      case '仪器故障':
      case '仪器通信故障':
        return ResultMode.Fault;
      case '仪器离线':
        return ResultMode.Offline;
      case '取水点无水样':
        return ResultMode.Maintain;
      case '手工输入数据':
        return ResultMode.Normal;
      case '维护调试数据':
        return ResultMode.Debug;
      case '非水样结果':
        return ResultMode.Calibrate;
      default:
        return undefined;
    }
  }

  private typeLabelToMeasureType(label: string): number | undefined {
    switch (label) {
      case '水样':
        return MeasureType.Sample;
      case '零点校准液':
        return MeasureType.ZeroCheck;
      case '量程校准液':
        return MeasureType.RangeCheck;
      case '跨度(标样)核查':
        return MeasureType.Check;
      case '质控样':
        return MeasureType.QualityHandle;
      default:
        return undefined;
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

  private resultText(item: MeasureRecord): string {
    return `${UiUtil.formatNumber(item.consistency)} mg/L`;
  }

  private flagColor(mode: number): ResourceColor {
    return mode === ResultMode.Normal ? '#333333' : '#E53935';
  }

  private getModeText(mode: number): string {
    return ResultManager.getInstance().getModeText(mode);
  }

  private getResultTypeText(resultType: number): string {
    return ResultManager.getInstance().getResultTypeText(resultType);
  }

  private formatFileName(timestamp: number): string {
    const date = new Date(timestamp);
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    return `${year}-${month}-${day}_${hours}-${minutes}`;
  }

  private async exportMeasureRecords(): Promise<void> {
    try {
      const resultManager = ResultManager.getInstance();
      const fileName = `measure_data_${this.formatFileName(Date.now())}`;
      const filePath = await resultManager.exportMeasureRecordsToCsvWithPicker({
        fileName,
        includeFields: [],
        roleType: 0
      });
      this.showExportSuccessDialog(filePath);
    } catch (err) {
      console.error('导出记录失败:', err);
      this.getUIContext().showAlertDialog({
        title: '提示',
        message: `导出失败\n ${err}`,
        confirm: { value: '确定', action: () => {} }
      });
    }
  }

  private async clearMeasureRecords(): Promise<void> {
    const confirmed = await this.showConfirmDialog('确定要清空所有测量记录吗？此操作不可恢复。');
    if (!confirmed) {
      return;
    }

    try {
      const resultManager = ResultManager.getInstance();
      if (!resultManager.isReady()) {
        this.getUIContext().showAlertDialog({
          title: '提示',
          message: '数据库未就绪',
          confirm: { value: '确定', action: () => {} }
        });
        return;
      }

      const deletedCount = await resultManager.clearMeasureRecords();
      this.getUIContext().showAlertDialog({
        title: '提示',
        message: `已清空 ${deletedCount} 条测量记录`,
        confirm: {
          value: '确定',
          action: () => {
            this.currentPage = 1;
            void this.refreshRecords();
          }
        }
      });
    } catch (err) {
      console.error('清空测量记录失败:', err);
      this.getUIContext().showAlertDialog({
        title: '提示',
        message: `清空失败: ${err}`,
        confirm: { value: '确定', action: () => {} }
      });
    }
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

  private showExportSuccessDialog(filePath: string) {
    this.getUIContext().showAlertDialog({
      title: '导出成功',
      message: `文件已保存到:\n${filePath}`,
      confirm: { value: '确定', action: () => {} }
    });
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
            Text('结果')
              .fontSize(UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor))
              .fontWeight(FontWeight.Bold)
              .layoutWeight(1.15)
              .textAlign(TextAlign.Center)
            Text('吸光度')
              .fontSize(UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor))
              .fontWeight(FontWeight.Bold)
              .layoutWeight(1.05)
              .textAlign(TextAlign.Center)
            Text('标识')
              .fontSize(UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor))
              .fontWeight(FontWeight.Bold)
              .layoutWeight(1.0)
              .textAlign(TextAlign.Center)
            Text('类型')
              .fontSize(UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor))
              .fontWeight(FontWeight.Bold)
              .layoutWeight(1.15)
              .textAlign(TextAlign.Center)
            Text('量程')
              .fontSize(UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor))
              .fontWeight(FontWeight.Bold)
              .layoutWeight(0.75)
              .textAlign(TextAlign.Center)
          }
          .height(UiUtil.vh(4.8, 36, 52, this.viewportHeight, this.scaleFactor))
          .backgroundColor('#F0F0F0')
          .border({ width: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor), color: '#DADADA' })

          ForEach(this.records, (item: MeasureRecord) => {
            Row() {
              Text(UiUtil.formatDateTimestamp(item.dateTime))
                .fontSize(UiUtil.vh(1.65, 11, 14, this.viewportHeight, this.scaleFactor))
                .width(this.timeColumnWidth())
                .textAlign(TextAlign.Center)
                .maxLines(1)
              Text(this.resultText(item))
                .fontSize(UiUtil.vh(1.8, 11, 15, this.viewportHeight, this.scaleFactor))
                .layoutWeight(1.15)
                .textAlign(TextAlign.Center)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(UiUtil.formatNumber(item.absorbance))
                .fontSize(UiUtil.vh(1.8, 11, 15, this.viewportHeight, this.scaleFactor))
                .layoutWeight(1.05)
                .textAlign(TextAlign.Center)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(this.getModeText(item.mode))
                .fontSize(UiUtil.vh(1.8, 11, 15, this.viewportHeight, this.scaleFactor))
                .fontColor(this.flagColor(item.mode))
                .layoutWeight(1.0)
                .textAlign(TextAlign.Center)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(this.getResultTypeText(item.resultType))
                .fontSize(UiUtil.vh(1.8, 11, 15, this.viewportHeight, this.scaleFactor))
                .layoutWeight(1.15)
                .textAlign(TextAlign.Center)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(UiUtil.formatNumber(item.measureRange))
                .fontSize(UiUtil.vh(1.8, 11, 15, this.viewportHeight, this.scaleFactor))
                .layoutWeight(0.75)
                .textAlign(TextAlign.Center)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .height(UiUtil.vh(4.5, 34, 50, this.viewportHeight, this.scaleFactor))
            .border({ width: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor), color: '#E5E5E5' })
          }, (item: MeasureRecord) => `${item.id}`)

          ForEach(this.getEmptyRowIndexes(), (idx: number) => {
            Row() {
              Text('').width(this.timeColumnWidth())
              Text('').layoutWeight(1.15)
              Text('').layoutWeight(1.05)
              Text('').layoutWeight(1.0)
              Text('').layoutWeight(1.15)
              Text('').layoutWeight(0.75)
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
            void this.exportMeasureRecords();
          },
          onClear: () => {
            void this.clearMeasureRecords();
          }
        })
      }
      .layoutWeight(1)
      .alignItems(VerticalAlign.Top)

      Column() {
        Row() {
          CalendarPicker({ hintRadius: 10, selected: this.selectedStartDate })
            .edgeAlign(CalendarAlign.END)
            .textStyle({ color: '#ff182431', font: { size: 20, weight: FontWeight.Normal } })
            .margin(10)
            .onChange((value) => {
              this.selectedStartDate = value;
            })
          Text('-')
            .fontSize(UiUtil.vh(1.6, 12, 16, this.viewportHeight, this.scaleFactor))
            .margin({
              left: UiUtil.vw(0.35, 3, 6, this.viewportWidth, this.scaleFactor),
              right: UiUtil.vw(0.35, 3, 6, this.viewportWidth, this.scaleFactor)
            })
          CalendarPicker({ hintRadius: 10, selected: this.selectedEndDate })
            .edgeAlign(CalendarAlign.END)
            .textStyle({ color: '#ff182431', font: { size: 20, weight: FontWeight.Normal } })
            .margin(10)
            .onChange((value) => {
              this.selectedEndDate = value;
            })

          Text('类型')
            .fontSize(UiUtil.vh(1.55, 12, 17, this.viewportHeight, this.scaleFactor))
            .fontWeight(FontWeight.Bold)
            .margin({
              left: UiUtil.vw(0.6, 4, 8, this.viewportWidth, this.scaleFactor),
              right: UiUtil.vw(0.35, 3, 6, this.viewportWidth, this.scaleFactor)
            })
          Select(this.typeOptions)
            .value(this.selectedType)
            .height(UiUtil.vh(4.1, 30, 42, this.viewportHeight, this.scaleFactor))
            .width(UiUtil.vw(9.2, 74, 160, this.viewportWidth, this.scaleFactor))
            .onSelect((_index: number, value?: string) => {
              this.selectedType = value ? value : ALL_FILTER_OPTION;
              this.currentPage = 1;
            })

          Text('标识')
            .fontSize(UiUtil.vh(1.55, 12, 17, this.viewportHeight, this.scaleFactor))
            .fontWeight(FontWeight.Bold)
            .margin({
              left: UiUtil.vw(0.6, 4, 8, this.viewportWidth, this.scaleFactor),
              right: UiUtil.vw(0.35, 3, 6, this.viewportWidth, this.scaleFactor)
            })
          Select(this.flagOptions)
            .value(this.selectedFlag)
            .height(UiUtil.vh(4.1, 30, 42, this.viewportHeight, this.scaleFactor))
            .width(UiUtil.vw(9.2, 74, 160, this.viewportWidth, this.scaleFactor))
            .margin({
              left: UiUtil.vw(0.6, 4, 8, this.viewportWidth, this.scaleFactor),
              right: UiUtil.vw(0.35, 3, 6, this.viewportWidth, this.scaleFactor)
            })
            .onSelect((_index: number, value?: string) => {
              this.selectedFlag = value ? value : ALL_FILTER_OPTION;
              this.currentPage = 1;
            })

          DataActionButton({
            label: '查询',
            buttonWidth: UiUtil.vw(6.4, 62, 88, this.viewportWidth, this.scaleFactor),
            buttonHeight: UiUtil.vh(4.2, 32, 46, this.viewportHeight, this.scaleFactor),
            fontSizeValue: UiUtil.vh(2.0, 12, 16, this.viewportHeight, this.scaleFactor),
            borderRadiusValue: UiUtil.vh(0.8, 5, 10, this.viewportHeight, this.scaleFactor),
            marginBottom: 0,
            onAction: () => {
              this.queryFromFirstPage();
            }
          })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .justifyContent(FlexAlign.Start)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
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
