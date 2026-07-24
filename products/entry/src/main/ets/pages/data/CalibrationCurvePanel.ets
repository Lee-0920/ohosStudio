import { common } from '@kit.AbilityKit';
import { DataActionButton } from '../../components/DataActionButton';
import { CalendarPickerPanel } from '../../components/data/CalendarPickerPanel';
import { DataPager } from '../../components/data/DataPager';
import { CurrentCalibrationCurveSummary } from '../../models/dataRecordTypes';
import { ResultManager, CalibrateRecord, CalibrateQueryCondition, SettingsManager, MeasureStatusManager, MeasureParamConfig } from 'dataservice';
import { UiUtil } from 'base';

@Component
export struct CalibrationCurvePanel {
  // Current selected tab label, kept for compatibility.
  @Prop tab: string = '';
  @Prop viewportWidth: number = 1024;
  @Prop viewportHeight: number = 768;
  @Prop scaleFactor: number = 1.92;
  @Prop canSetCurrent: boolean = true;
  @State private records: CalibrateRecord[] = [];
  @State private currentPage: number = 1;
  @State private totalPages: number = 1;
  @State private totalCount: number = 0;
  @State private selectedRecordId: number = -1;
  @State private startDate: string = '';
  @State private endDate: string = '';
  @State private activePicker: string = '';
  @State private isLoading: boolean = false;
  @State private isSettingCurrent: boolean = false;
  @State private operationMessage: string = '';
  @State private currentCurve: CurrentCalibrationCurveSummary | null = null;
  @State private isInputDialogVisible: boolean = false;
  @State private inputKValue: string = '';
  @State private inputBValue: string = '';
  private readonly pageSize: number = 6;

  async aboutToAppear(): Promise<void> {
    this.ensureDefaultDates();
    // const context = this.getUIContext().getHostContext() as common.Context | undefined;
    // if (context) {
    //   const ready = await ResultManager.getInstance().init(context, { decimalNum: 3, settingUseNum: 3 });
    //   console.info(`CalibrationCurvePanel: ResultManager init result: ${ready}`);
    //   await SettingsManager.getInstance().init(context);
    //   await MeasureStatusManager.getInstance().init(context);
    // } else {
    //   console.warn('CalibrationCurvePanel: 无法获取 host context');
    // }
    void this.refreshRecords();
    void this.refreshCurrentCurve();
  }

  onPageShow(): void {
    // 从其他页面返回或配置被修改后，同步刷新当前标线显示
    void this.refreshCurrentCurve();
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
      const condition = this.buildCalibrateQueryCondition();
      this.totalCount = await resultManager.getCalibrateRecordCount(condition);
      this.totalPages = Math.max(1, Math.ceil(this.totalCount / this.pageSize));
      this.currentPage = Math.min(Math.max(1, this.currentPage), this.totalPages);
      condition.limit = this.pageSize;
      condition.offset = (this.currentPage - 1) * this.pageSize;
      this.records = await resultManager.getCalibrateRecords(condition);
    } finally {
      this.isLoading = false;
    }
  }

  private buildCalibrateQueryCondition(): CalibrateQueryCondition {
    return {
      startTime: this.parseDateStart(this.startDate),
      endTime: this.parseDateEnd(this.endDate),
      orderBy: 'desc'
    };
  }

  private hasRecordInCurrentPage(id: number): boolean {
    let exists = false;
    this.records.forEach((item: CalibrateRecord) => {
      if (item.id === id) {
        exists = true;
      }
    });
    return exists;
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
    this.operationMessage = '';
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

  // 对应原 CalibrateCurve.ls 中 checkCurveExist 逻辑
  private async checkCurveExist(rangeValve: number): Promise<boolean> {
    const settingsManager = SettingsManager.getInstance();
    const measureParamConfig = await settingsManager.getMeasureParamConfig();
    const systemConfig = await settingsManager.getSystemConfig();
    if (!measureParamConfig || !systemConfig) {
      return false;
    }
    const rangeViewMap = systemConfig.rangeViewMap ?? [];
    const rangeArray = measureParamConfig.range ?? [];
    for (let i = 0; i < rangeViewMap.length; i++) {
      if (rangeViewMap[i].view === rangeValve) {
        for (let j = 0; j < rangeArray.length; j++) {
          if (i === rangeArray[j]) {
            return true;
          }
        }
        break;
      }
    }
    return false;
  }

  // 对应原 setting.ui.profile.measureParam.updaterCurveParam 逻辑
  private updateCurveParam(measureParamConfig: MeasureParamConfig, rangeIndex: number, useMeasureParamConfig: boolean,
    isCalibrateIndex?: boolean): void {
    const rangeArray = measureParamConfig.range ?? [];
    let currentRange = 0;
    let calibrateRange = 0;

    if (!useMeasureParamConfig) {
      currentRange = rangeIndex;
      calibrateRange = rangeIndex;
    } else {
      currentRange = rangeArray[measureParamConfig.currentRange] ?? 0;
      calibrateRange = rangeArray[measureParamConfig.calibrateRangeIndex] ?? 0;
    }

    if (isCalibrateIndex) {
      measureParamConfig.zeroConsistency = measureParamConfig.curveParam[calibrateRange].zeroConsistency;
      measureParamConfig.rangeConsistency = measureParamConfig.curveParam[calibrateRange].rangeConsistency;
    } else if (useMeasureParamConfig) {
      measureParamConfig.curveK = measureParamConfig.curveParam[currentRange].curveK;
      measureParamConfig.curveB = measureParamConfig.curveParam[currentRange].curveB;
      measureParamConfig.timeStr = measureParamConfig.curveParam[currentRange].timeStr;
      measureParamConfig.zeroConsistency = measureParamConfig.curveParam[calibrateRange].zeroConsistency;
      measureParamConfig.rangeConsistency = measureParamConfig.curveParam[calibrateRange].rangeConsistency;
    } else {
      measureParamConfig.curveK = measureParamConfig.curveParam[currentRange].curveK;
      measureParamConfig.curveB = measureParamConfig.curveParam[currentRange].curveB;
      measureParamConfig.timeStr = measureParamConfig.curveParam[currentRange].timeStr;
    }
  }

  // 对应原 CalibrateCurve.ls 中 changeCurve 逻辑
  private async changeCurve(rangeValve: number, calibrateTime: string, curveK: number, curveB: number): Promise<void> {
    const settingsManager = SettingsManager.getInstance();
    const measureStatusManager = MeasureStatusManager.getInstance();
    const measureParamConfig = await settingsManager.getMeasureParamConfig();
    const measureStatus = await measureStatusManager.getMeasureStatus();
    const systemConfig = await settingsManager.getSystemConfig();
    if (!measureParamConfig || !measureStatus || !systemConfig) {
      throw new Error('配置或状态未初始化');
    }

    const rangeViewMap = systemConfig.rangeViewMap ?? [];
    const rangeArray = measureParamConfig.range ?? [];
    for (let i = 0; i < rangeViewMap.length; i++) {
      if (rangeViewMap[i].view === rangeValve) {
        measureParamConfig.curveParam[i].curveK = curveK;
        measureParamConfig.curveParam[i].curveB = curveB;
        measureParamConfig.curveParam[i].timeStr = calibrateTime;

        if (measureStatus.calibrate[i]) {
          measureStatus.calibrate[i].curveK = curveK;
          measureStatus.calibrate[i].curveB = curveB;
        }
        for (let j = 0; j < rangeArray.length; j++) {
          if (i === rangeArray[j]) {
            measureParamConfig.currentRange = j;
          }
        }
        break;
      }
    }

    // 对应 setting.ui.profile.measureParam.updaterCurveParam(0, true)
    this.updateCurveParam(measureParamConfig, 0, true);

    await settingsManager.setMeasureParamConfig(measureParamConfig);
    await measureStatusManager.setMeasureStatus(measureStatus);
  }

  private async onInputCurve(): Promise<void> {
    // 预填充当前 K/B，与 C++ 端 ToInput 行为一致
    this.inputKValue = '';
    this.inputBValue = '';
    this.isInputDialogVisible = true;
  }

  private async onConfirmInput(): Promise<void> {
    const kStr = this.inputKValue.trim();
    const bStr = this.inputBValue.trim();

    // 与 C++ 端 ToInput 一致的 K/B 格式校验：^[+-]?\d{1,6}(\.\d{1,6})?$
    const pattern = /^[+-]?\d{1,6}(\.\d{1,6})?$/;
    if (!pattern.test(kStr) || !pattern.test(bStr)) {
      this.operationMessage = 'K/B 值格式错误，请输入有效数字';
      return;
    }

    const curveK = parseFloat(kStr);
    const curveB = parseFloat(bStr);

    const resultManager = ResultManager.getInstance();
    if (!resultManager.isReady()) {
      this.operationMessage = '数据库未就绪';
      return;
    }

    try {
      const settingsManager = SettingsManager.getInstance();
      const measureParamConfig = await settingsManager.getMeasureParamConfig();
      const systemConfig = await settingsManager.getSystemConfig();
      if (!measureParamConfig || !systemConfig) {
        this.operationMessage = '配置未初始化';
        return;
      }

      // 对应原 CalibrateCurve.ls 中 saveFile：记录修改日志
      console.info('用户修改测量参数');

      const rangeArray = measureParamConfig.range ?? [];
      const currentRangeIndex = rangeArray[measureParamConfig.currentRange] ?? 0;
      const rangeViewMap = systemConfig.rangeViewMap ?? [];
      const measureRange = rangeViewMap[currentRangeIndex]?.view ?? 0;

      // 对应原 CalibrateCurve.ls 中 toInput：构造校准记录，除时间/K/B/量程外其余填 0
      const record = new CalibrateRecord();
      record.dateTime = Math.floor(Date.now() / 1000);
      record.curveK = curveK;
      record.curveB = curveB;
      record.measureRange = measureRange;

      await resultManager.addCalibrateRecord('calibrate', record);

      this.operationMessage = '校准记录已保存';
      this.isInputDialogVisible = false;
      this.inputKValue = '';
      this.inputBValue = '';

      // 对应原 OnCalibrateResultAdded -> UpdaterCalibrate：刷新列表和当前标线
      await this.refreshRecords();
      await this.refreshCurrentCurve();
    } catch (err) {
      console.error('保存输入校准记录失败:', err);
      this.operationMessage = `保存失败: ${err}`;
    }
  }

  private onCancelInput(): void {
    this.isInputDialogVisible = false;
  }

  @Builder
  private InputDialogContent() {
    Column() {
      Text('校准曲线模型: mAbs = K * C + B')
        .fontSize(UiUtil.vh(1.8, 13, 18, this.viewportHeight, this.scaleFactor))
        .fontColor('#333333')
        .margin({ bottom: UiUtil.vh(1.5, 10, 14, this.viewportHeight, this.scaleFactor) })

      Row() {
        Text('K值')
          .fontSize(UiUtil.vh(1.65, 11, 15, this.viewportHeight, this.scaleFactor))
          .fontColor('#333333')
          .width(UiUtil.vw(3.0, 24, 36, this.viewportWidth, this.scaleFactor))

        TextInput({ text: this.inputKValue })
          .height(UiUtil.vh(3.6, 28, 38, this.viewportHeight, this.scaleFactor))
          .width(UiUtil.vw(9.0, 78, 110, this.viewportWidth, this.scaleFactor))
          .fontSize(UiUtil.vh(1.65, 11, 15, this.viewportHeight, this.scaleFactor))
          .backgroundColor('#FFFFFF')
          .border({ width: UiUtil.vh(0.1, 1, 1, this.viewportHeight, this.scaleFactor), color: '#D8DDE3' })
          .borderRadius(UiUtil.vh(0.45, 3, 5, this.viewportHeight, this.scaleFactor))
          .type(InputType.Number)
          .onChange((value: string) => {
            this.inputKValue = value;
          })

        Text('B值')
          .fontSize(UiUtil.vh(1.65, 11, 15, this.viewportHeight, this.scaleFactor))
          .fontColor('#333333')
          .width(UiUtil.vw(3.0, 24, 36, this.viewportWidth, this.scaleFactor))
          .margin({ left: UiUtil.vw(1.0, 8, 14, this.viewportWidth, this.scaleFactor) })

        TextInput({ text: this.inputBValue })
          .height(UiUtil.vh(3.6, 28, 38, this.viewportHeight, this.scaleFactor))
          .width(UiUtil.vw(9.0, 78, 110, this.viewportWidth, this.scaleFactor))
          .fontSize(UiUtil.vh(1.65, 11, 15, this.viewportHeight, this.scaleFactor))
          .backgroundColor('#FFFFFF')
          .border({ width: UiUtil.vh(0.1, 1, 1, this.viewportHeight, this.scaleFactor), color: '#D8DDE3' })
          .borderRadius(UiUtil.vh(0.45, 3, 5, this.viewportHeight, this.scaleFactor))
          .type(InputType.Number)
          .onChange((value: string) => {
            this.inputBValue = value;
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .margin({ bottom: UiUtil.vh(1.8, 12, 18, this.viewportHeight, this.scaleFactor) })

      Row() {
        DataActionButton({
          label: '确定',
          buttonWidth: UiUtil.vw(5.4, 52, 76, this.viewportWidth, this.scaleFactor),
          buttonHeight: UiUtil.vh(3.6, 28, 38, this.viewportHeight, this.scaleFactor),
          fontSizeValue: UiUtil.vh(1.8, 12, 16, this.viewportHeight, this.scaleFactor),
          borderRadiusValue: UiUtil.vh(0.6, 4, 8, this.viewportHeight, this.scaleFactor),
          marginBottom: 0,
          onAction: () => {
            void this.onConfirmInput();
          }
        })

        DataActionButton({
          label: '取消',
          buttonWidth: UiUtil.vw(5.4, 52, 76, this.viewportWidth, this.scaleFactor),
          buttonHeight: UiUtil.vh(3.6, 28, 38, this.viewportHeight, this.scaleFactor),
          fontSizeValue: UiUtil.vh(1.8, 12, 16, this.viewportHeight, this.scaleFactor),
          borderRadiusValue: UiUtil.vh(0.6, 4, 8, this.viewportHeight, this.scaleFactor),
          marginBottom: 0,
          onAction: () => {
            this.onCancelInput();
          }
        })
          .margin({ left: UiUtil.vw(1.0, 8, 14, this.viewportWidth, this.scaleFactor) })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.Center)
    }
    .width(UiUtil.vw(32.0, 280, 380, this.viewportWidth, this.scaleFactor))
    .padding({
      left: UiUtil.vw(1.5, 12, 18, this.viewportWidth, this.scaleFactor),
      right: UiUtil.vw(1.5, 12, 18, this.viewportWidth, this.scaleFactor),
      top: UiUtil.vh(1.8, 12, 18, this.viewportHeight, this.scaleFactor),
      bottom: UiUtil.vh(1.8, 12, 18, this.viewportHeight, this.scaleFactor)
    })
    .backgroundColor('#FFFFFF')
    .borderRadius(UiUtil.vh(0.8, 5, 10, this.viewportHeight, this.scaleFactor))
  }

  private async setCurrentSelectedCurve(): Promise<void> {
    // if (!this.canSetCurrent) {
    //   this.operationMessage = '当前用户无权修改校准曲线';
    //   return;
    // }
    // if (this.isSettingCurrent) {
    //   return;
    // }
    if (this.selectedRecordId <= 0) {
      this.operationMessage = '请选择校准曲线';
      return;
    }

    const record = this.findSelectedRecord();
    if (!record) {
      this.operationMessage = '未找到选中的校准曲线';
      return;
    }

    this.isSettingCurrent = true;
    this.operationMessage = '正在设置当前标线';
    try {
      // 对应原 CalibrateCurve.cpp ToMap 中 checkCurveExist 校验
      const isCurveExist = await this.checkCurveExist(record.measureRange);
      if (!isCurveExist) {
        this.operationMessage = '请选择量程一、二、三对应的校准曲线';
        return;
      }

      // 对应原 CalibrateCurve.ls 中 saveFile 逻辑（记录修改日志并保存）
      console.info('用户修改测量参数');
      // config.modifyRecord.measureParam(true)
      // TODO: 待补充 config.modifyRecord.measureParam(true)

      // 对应原 CalibrateCurve.ls 中 changeCurve 逻辑（内部已调用 updaterCurveParam）
      const calibrateTime = UiUtil.formatDateTimestamp(record.dateTime);
      await this.changeCurve(record.measureRange, calibrateTime, record.curveK, record.curveB);

      // 对应原 CalibrateCurve.cpp ToMap 中 currentCurve->setText + DisplayExtraInfo
      const updatedConfig = await SettingsManager.getInstance().getMeasureParamConfig();
      if (updatedConfig) {
        const rangeArray = updatedConfig.range ?? [];
        const currentRangeIndex = rangeArray[updatedConfig.currentRange] ?? 0;
        const curveParam = updatedConfig.curveParam[currentRangeIndex];
        if (curveParam) {
          this.currentCurve = {
            slope: curveParam.curveK,
            intercept: curveParam.curveB,
            zeroConcentration: curveParam.zeroConsistency,
            spanConcentration: curveParam.rangeConsistency
          };
        }
      }

      // UpdateWidgetManager::Instance()->SlotUpdateWidget(UpdateEvent::ChangeMeasureParam, "CalibrateCurve")
      // TODO: 待补充 UpdateWidgetManager 通知

      // extraToMap 相关 setting.* 逻辑
      // TODO: 待补充 extraToMap 相关逻辑

      this.operationMessage = '当前标线已更新';
      // 当前 currentCurve 已直接更新为选中记录，不再从配置回读，避免被旧配置覆盖
    } catch (err) {
      this.operationMessage = `设为当前失败: ${err}`;
    } finally {
      this.isSettingCurrent = false;
    }
  }

  private findSelectedRecord(): CalibrateRecord | null {
    for (const record of this.records) {
      if (record.id === this.selectedRecordId) {
        return record;
      }
    }
    return null;
  }

  private formatCurve(slope: number, intercept: number): string {
    const sign = intercept < 0 ? '-' : '+';
    return `${UiUtil.formatNumber(slope)}*C${sign}${UiUtil.formatNumber(Math.abs(intercept))}`;
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

  private async exportCalibrateRecords(): Promise<void> {
    try {
      const resultManager = ResultManager.getInstance();
      const fileName = `calibrate_data_${this.formatFileName(Date.now())}`;
      const filePath = await resultManager.exportCalibrateRecordsToCsvWithPicker({
        fileName,
        includeFields: [],
        roleType: 0
      });
      this.showExportSuccessDialog(filePath);
    } catch (err) {
      console.error('导出校准记录失败:', err);
      this.getUIContext().showAlertDialog({
        title: '提示',
        message: `导出失败\n ${err}`,
        confirm: { value: '确定', action: () => {} }
      });
    }
  }

  private async clearCalibrateRecords(): Promise<void> {
    const confirmed = await this.showConfirmDialog('确定要清空所有校准记录吗？此操作不可恢复。');
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

      const deletedCount = await resultManager.clearCalibrateRecords();
      this.getUIContext().showAlertDialog({
        title: '提示',
        message: `已清空 ${deletedCount} 条校准记录`,
        confirm: {
          value: '确定',
          action: () => {
            this.currentPage = 1;
            this.selectedRecordId = -1;
            void this.refreshRecords();
          }
        }
      });
    } catch (err) {
      console.error('清空校准记录失败:', err);
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

  private formatConcentration(value: number | null): string {
    if (value === null || Number.isNaN(value)) {
      return '-';
    }
    const fixed = value.toFixed(3);
    const trimmed = fixed.replace(/0+$/, '').replace(/\.$/, '');
    return trimmed.indexOf('.') >= 0 ? trimmed : `${trimmed}.0`;
  }

  private formatConsistency(value: number): string {
    if (value === 0 || Number.isNaN(value)) {
      return '--';
    }
    return UiUtil.formatNumber(value);
  }

  private currentCurveText(): string {
    if (!this.currentCurve) {
      return '当前标线：-，校准浓度：-/-mg/L';
    }
    return `当前标线：mAbs=${this.formatCurve(this.currentCurve.slope, this.currentCurve.intercept)}，` +
      `校准浓度：${this.formatConcentration(this.currentCurve.zeroConcentration)}/` +
      `${this.formatConcentration(this.currentCurve.spanConcentration)}mg/L`;
  }

  // 对应原 CalibrateCurve.cpp 中 DisplayCurrentCurve + DisplayExtraInfo 逻辑
  private async refreshCurrentCurve(): Promise<void> {
    const settingsManager = SettingsManager.getInstance();
    const measureParamConfig = await settingsManager.getMeasureParamConfig();
    if (!measureParamConfig) {
      this.currentCurve = null;
      return;
    }
    const rangeArray = measureParamConfig.range ?? [];
    let currentRangeIndex = rangeArray[measureParamConfig.currentRange];
    // currentRange 或对应 range 无效时，默认选中第一个 CurveParam
    if (currentRangeIndex === undefined || currentRangeIndex < 0 ||
      currentRangeIndex >= measureParamConfig.curveParam.length) {
      currentRangeIndex = 0;
    }
    let curveParam = measureParamConfig.curveParam[currentRangeIndex];
    // 目标 CurveParam 不存在时，回退到第一个
    if (!curveParam && measureParamConfig.curveParam.length > 0) {
      currentRangeIndex = 0;
      curveParam = measureParamConfig.curveParam[0];
    }
    if (!curveParam) {
      this.currentCurve = null;
      return;
    }
    this.currentCurve = {
      slope: curveParam.curveK,
      intercept: curveParam.curveB,
      zeroConcentration: curveParam.zeroConsistency,
      spanConcentration: curveParam.rangeConsistency
    };
  }

  private rowBackgroundColor(item: CalibrateRecord): ResourceColor {
    if (item.id === this.selectedRecordId) {
      return '#EAF7FF';
    }
    return '#FFFFFF';
  }

  private togglePicker(name: string): void {
    this.activePicker = this.activePicker === name ? '' : name;
  }

  @Builder
  private dateField(name: string) {
    Text(name === 'start' ? this.startDate : this.endDate)
      .height(UiUtil.vh(4.1, 30, 42, this.viewportHeight, this.scaleFactor))
      .width(UiUtil.vw(11.2, 86, 126, this.viewportWidth, this.scaleFactor))
      .fontSize(UiUtil.vh(1.45, 11, 15, this.viewportHeight, this.scaleFactor))
      .fontColor('#222222')
      .textAlign(TextAlign.Center)
      .border({
        width: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor),
        color: this.activePicker === name ? '#0B9F9A' : '#0A6BFF'
      })
      .borderRadius(UiUtil.vh(0.55, 3, 6, this.viewportHeight, this.scaleFactor))
      .backgroundColor(this.activePicker === name ? '#F1FFFE' : '#FFFFFF')
      .onClick(() => {
        this.togglePicker(name);
      })
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
            Text('曲线')
              .fontSize(UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor))
              .fontWeight(FontWeight.Bold)
              .layoutWeight(1.7)
              .textAlign(TextAlign.Center)
            Text('零点')
              .fontSize(UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor))
              .fontWeight(FontWeight.Bold)
              .layoutWeight(0.85)
              .textAlign(TextAlign.Center)
            Text('标点')
              .fontSize(UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor))
              .fontWeight(FontWeight.Bold)
              .layoutWeight(0.85)
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

          ForEach(this.records, (item: CalibrateRecord) => {
            Row() {
              Text(UiUtil.formatDateTimestamp(item.dateTime))
                .fontSize(UiUtil.vh(1.65, 11, 14, this.viewportHeight, this.scaleFactor))
                .width(this.timeColumnWidth())
                .textAlign(TextAlign.Center)
                .maxLines(1)
              Text(this.formatCurve(item.curveK, item.curveB))
                .fontSize(UiUtil.vh(1.8, 11, 15, this.viewportHeight, this.scaleFactor))
                .layoutWeight(1.7)
                .textAlign(TextAlign.Center)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(this.formatConsistency(item.point0Consistency))
                .fontSize(UiUtil.vh(1.8, 11, 15, this.viewportHeight, this.scaleFactor))
                .layoutWeight(0.85)
                .textAlign(TextAlign.Center)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(this.formatConsistency(item.point1Consistency))
                .fontSize(UiUtil.vh(1.8, 11, 15, this.viewportHeight, this.scaleFactor))
                .layoutWeight(0.85)
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
            .backgroundColor(this.rowBackgroundColor(item))
            .border({
              width: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor),
              color: item.id === this.selectedRecordId ? '#0A6BFF' : '#E5E5E5'
            })
            .onClick(() => {
              this.selectedRecordId = item.id ?? -1;
              this.operationMessage = '';
            })
          }, (item: CalibrateRecord) => `${item.id}`)

          ForEach(this.getEmptyRowIndexes(), (idx: number) => {
            Row() {
              Text('').width(this.timeColumnWidth())
              Text('').layoutWeight(1.7)
              Text('').layoutWeight(0.85)
              Text('').layoutWeight(0.85)
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
            this.activePicker = '';
            void this.exportCalibrateRecords();
          },
          onClear: () => {
            this.activePicker = '';
            void this.clearCalibrateRecords();
          }
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

      Text(this.currentCurveText())
        .fontSize(UiUtil.vh(1.45, 10, 13, this.viewportHeight, this.scaleFactor))
        .fontColor('#687078')
        .width('100%')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: UiUtil.vh(0.6, 4, 8, this.viewportHeight, this.scaleFactor) })

      Column() {
        Row() {
          this.dateField('start');
          Text('-')
            .fontSize(UiUtil.vh(1.6, 12, 16, this.viewportHeight, this.scaleFactor))
            .margin({
              left: UiUtil.vw(0.35, 3, 6, this.viewportWidth, this.scaleFactor),
              right: UiUtil.vw(0.35, 3, 6, this.viewportWidth, this.scaleFactor)
            })
          this.dateField('end');

          Blank()

          DataActionButton({
            label: '查询',
            buttonWidth: UiUtil.vw(6.4, 62, 88, this.viewportWidth, this.scaleFactor),
            buttonHeight: UiUtil.vh(4.2, 32, 46, this.viewportHeight, this.scaleFactor),
            fontSizeValue: UiUtil.vh(2.0, 12, 16, this.viewportHeight, this.scaleFactor),
            borderRadiusValue: UiUtil.vh(0.8, 5, 10, this.viewportHeight, this.scaleFactor),
            marginBottom: 0,
            onAction: () => {
              this.activePicker = '';
              this.queryFromFirstPage();
            }
          })

          DataActionButton({
            label: '设为当前',
            buttonWidth: UiUtil.vw(8.2, 78, 112, this.viewportWidth, this.scaleFactor),
            buttonHeight: UiUtil.vh(4.2, 32, 46, this.viewportHeight, this.scaleFactor),
            fontSizeValue: UiUtil.vh(2.0, 12, 16, this.viewportHeight, this.scaleFactor),
            borderRadiusValue: UiUtil.vh(0.8, 5, 10, this.viewportHeight, this.scaleFactor),
            marginBottom: 0,
            onAction: () => {
              void this.setCurrentSelectedCurve();
            }
          })
            .margin({ left: UiUtil.vw(0.55, 4, 8, this.viewportWidth, this.scaleFactor) })
            .opacity(this.canSetCurrent ? 1 : 0.45)
            .enabled(this.canSetCurrent)

          DataActionButton({
            label: '输入',
            buttonWidth: UiUtil.vw(5.4, 52, 76, this.viewportWidth, this.scaleFactor),
            buttonHeight: UiUtil.vh(4.2, 32, 46, this.viewportHeight, this.scaleFactor),
            fontSizeValue: UiUtil.vh(2.0, 12, 16, this.viewportHeight, this.scaleFactor),
            borderRadiusValue: UiUtil.vh(0.8, 5, 10, this.viewportHeight, this.scaleFactor),
            marginBottom: 0,
            onAction: () => {
              void this.onInputCurve();
            }
          })
            .margin({ left: UiUtil.vw(0.55, 4, 8, this.viewportWidth, this.scaleFactor) })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .justifyContent(FlexAlign.Start)

        if (this.activePicker.length > 0) {
          Row() {
            CalendarPickerPanel({
              selectedDate: this.activePicker === 'start' ? this.startDate : this.endDate,
              viewportWidth: this.viewportWidth,
              viewportHeight: this.viewportHeight,
              scaleFactor: this.scaleFactor,
              onDateSelected: (value: string) => {
                if (this.activePicker === 'start') {
                  this.startDate = value;
                } else {
                  this.endDate = value;
                }
                this.activePicker = '';
              }
            })
          }
          .width('100%')
          .margin({ top: UiUtil.vh(0.8, 6, 10, this.viewportHeight, this.scaleFactor) })
          .justifyContent(FlexAlign.Start)
        }
      }
      .margin({ top: UiUtil.vh(2.0, 12, 22, this.viewportHeight, this.scaleFactor) })

      Row() {
        Text(this.operationMessage)
          .fontSize(UiUtil.vh(1.45, 10, 13, this.viewportHeight, this.scaleFactor))
          .fontColor(this.operationMessage.indexOf('失败') >= 0 ? '#E53935' : '#0B9F9A')
          .layoutWeight(1)
          .textAlign(TextAlign.Start)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(`共 ${this.totalCount} 条`)
          .fontSize(UiUtil.vh(1.45, 10, 13, this.viewportHeight, this.scaleFactor))
          .fontColor('#7A818A')
          .width(UiUtil.vw(7.6, 72, 104, this.viewportWidth, this.scaleFactor))
          .textAlign(TextAlign.End)
      }
      .width('100%')
      .margin({ top: UiUtil.vh(0.5, 3, 6, this.viewportHeight, this.scaleFactor) })

      if (this.isInputDialogVisible) {
        Column() {
          this.InputDialogContent()
        }
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.4)')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .position({ x: 0, y: 0 })
      }
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
