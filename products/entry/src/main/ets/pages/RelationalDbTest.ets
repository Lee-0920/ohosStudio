import { ResultManager, MeasureRecord, CalibrateRecord, MeasureType, ResultMode, MeasureQueryCondition, CalibrateQueryCondition, SettingsManager, MeasureStatusManager, CalibrateItem } from 'dataservice';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Logger } from 'logger';

@Observed
class MeasureDisplayItem {
  id: number = 0;
  dateTime: string = '';
  consistency: string = '';
  absorbance: string = '';
  mode: string = '';
  resultType: string = '';
  netAbsorbance: string = '';
  measureRange: string = '';
}

@Observed
class CalibrateDisplayItem {
  id: number = 0;
  dateTime: string = '';
  curveK: string = '';
  curveB: string = '';
  R2: string = '';
  point0InitAbsorbance: number = 0;
  point0Absorbance: string = '';
  point1InitAbsorbance: number = 0;
  point1Absorbance: string = '';
  point0Consistency: number = 0;
  point1Consistency: number = 0;
  measureRange: number = 0;
  rangeIndex: number = 0;
}

@Entry
@Component
struct RelationalDbTest {
  @State isRelationalReady: boolean = false;
  @State logText: string = '正在初始化关系型数据库...';
  @State dbPath: string = '';

  // 测量数据
  @State measureRecords: MeasureDisplayItem[] = [];
  @State showMeasureDetailPanel: boolean = false;

  // 校准数据
  @State calibrateRecords: CalibrateDisplayItem[] = [];
  @State showCalibrateDetailPanel: boolean = false;
  @State selectedCalibrateId: number = -1;
  @State calibrateCacheRecords: CalibrateRecord[] = [];

  // 查询条件
  @State measureStartTime: number = 0;
  @State measureEndTime: number = 0;
  @State calibrateStartTime: number = 0;
  @State calibrateEndTime: number = 0;

  // 标识选项列表（对应 ResultMode）
  private modeOptions: string[] = ['全部', '正常', '离线', '维护', '故障', '校准', '超量程', '超上限', '质控', '调试'];
  private typeOptions: string[] = ['全部', '空白水', '水样', '质控'];

  @State selectedModeIndex: number = -1;
  @State selectedTypeIndex: number = -1;

  aboutToAppear() {
    this.measureStartTime = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).getTime();
    this.measureEndTime = new Date(Date.now()).getTime();
    this.calibrateStartTime = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).getTime();
    this.calibrateEndTime = new Date(Date.now()).getTime();
    this.initRelationalDatabase();
  }

  private async initRelationalDatabase(): Promise<void> {
    try {
      const resultManager = ResultManager.getInstance();
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      await resultManager.init(context, { decimalNum: 3, settingUseNum: 3 });
      this.isRelationalReady = true;
      await this.getRelationalDbPath();
      this.logText = `✅ 关系型数据库已就绪\n📁 数据库路径: ${this.dbPath}`;
    } catch (err) {
      this.isRelationalReady = false;
      this.logText = `❌ 初始化失败: ${err}`;
    }
  }

  private async getRelationalDbPath(): Promise<void> {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      if (context) {
        this.dbPath = `${context.databaseDir}/ResultData.db`;
      } else {
        this.dbPath = '无法获取上下文';
      }
    } catch (err) {
      this.dbPath = '获取路径失败';
    }
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

  private formatDateTime(timestamp: number): string {
    const date = new Date(timestamp);
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    const seconds = String(date.getSeconds()).padStart(2, '0');
    return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`;
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

  private updateRelationalDisplay(): void {
    // logText is updated by individual operations
  }

  private async addTestMeasureRecord(): Promise<void> {
    if (!this.isRelationalReady) { this.logText = '数据库未就绪'; return; }
    try {
      const resultManager = ResultManager.getInstance();
      const record = new MeasureRecord();
      record.dateTime = Date.now();
      record.consistency = 12.345;
      record.absorbance = 0.123;
      record.mode = ResultMode.Normal;
      record.resultType = MeasureType.Sample;
      record.versionString = '1, 0, 0, 2';

      const id = await resultManager.addMeasureRecord('test', record, false);
      if (id > 0) {
        this.logText = `✅ 添加成功！\nID: ${id}\n浓度: ${record.consistency} mg/L\n时间: ${this.formatDateTime(record.dateTime)}`;
      } else {
        this.logText = '❌ 添加失败';
      }
    } catch (err) {
      this.logText = `❌ 异常: ${err}`;
    }
  }

  private async addTestCalibrateRecord(): Promise<void> {
    if (!this.isRelationalReady) { this.logText = '数据库未就绪'; return; }
    try {
      const resultManager = ResultManager.getInstance();
      const record = new CalibrateRecord();
      record.dateTime = Date.now();

      const timestamp = Date.now();
      record.curveK = 0.7 + (Math.random() * timestamp % 10) * 0.01;
      record.curveB = 0.2 + (Math.random() * timestamp % 9) * 0.02;
      record.R2 = 0.9 + (Math.random() * timestamp % 8) * 0.03;
      record.calibrateTime = 180;
      record.measureRange = 50.0;
      record.rangeIndex = Math.random() * timestamp % 7;

      record.point0InitAbsorbance = 0.1 + (Math.random() * timestamp % 9) * 0.01;
      record.point0Absorbance = 0.5 + (Math.random() * timestamp % 8) * 0.02;
      record.point0Consistency = 0.6 + (Math.random() * timestamp % 7) * 0.03;
      record.initReferenceAD0 = 1000;
      record.initMeasureAD0 = 1100;
      record.finalReferenceAD0 = 2000;
      record.finalMeasureAD0 = 2100;
      record.point0InitThermostatTemp = 25.0;
      record.point0InitEnvironmentTemp = 26.0;
      record.point0FinalThermostatTemp = 25.2;
      record.point0FinalEnvironmentTemp = 26.1;

      record.point1InitAbsorbance = 0.3 + (Math.random() * timestamp % 10) * 0.03;
      record.point1Absorbance = 0.9 + (Math.random() * timestamp % 9) * 0.02;
      record.point1Consistency = 1.1 + (Math.random() * timestamp % 8) * 0.01;
      record.initReferenceAD1 = 1000;
      record.initMeasureAD1 = 1050;
      record.finalReferenceAD1 = 2000;
      record.finalMeasureAD1 = 2500;
      record.point1InitThermostatTemp = 25.1;
      record.point1InitEnvironmentTemp = 26.0;
      record.point1FinalThermostatTemp = 25.3;
      record.point1FinalEnvironmentTemp = 26.1;

      record.versionString = '1.0.0.2';

      const id = await resultManager.addCalibrateRecord('test', record);
      if (id > 0) {
        this.logText = `✅ 校准记录添加成功！\nID: ${id}\nK: ${record.curveK}, B: ${record.curveB}, R²: ${record.R2}`;
        Logger.debug(this.logText.toString());
      } else {
        this.logText = '❌ 添加失败';
      }
    } catch (err) {
      this.logText = `❌ 异常: ${err}`;
      console.info('校准记录添加失败:', err);
    }
  }

  private async exportMeasureToCsv(): Promise<void> {
    if (!this.isRelationalReady) { this.logText = '数据库未就绪'; return; }
    try {
      const resultManager = ResultManager.getInstance();
      const fileName = `measure_data_${this.formatFileName(Date.now())}`;
      const filePath = await resultManager.exportMeasureRecordsToCsvWithPicker({ fileName, includeFields: [], roleType: 0 });
      this.logText = `✅ CSV导出成功\n${filePath}`;
      this.showExportSuccessDialog(filePath);
    } catch (err) {
      this.logText = `❌ 异常: ${err}`;
    }
  }

  private async exportCalibrateToCsv(): Promise<void> {
    if (!this.isRelationalReady) { this.logText = '数据库未就绪'; return; }
    try {
      const resultManager = ResultManager.getInstance();
      const fileName = `calibrate_data_${this.formatFileName(Date.now())}`;
      const filePath = await resultManager.exportCalibrateRecordsToCsvWithPicker({ fileName, includeFields: [], roleType: 0 });
      this.logText = `✅ CSV导出成功\n${filePath}`;
      this.showExportSuccessDialog(filePath);
    } catch (err) {
      this.logText = `❌ 异常: ${err}`;
    }
  }

  private async clearAllMeasureRecords(): Promise<void> {
    if (!this.isRelationalReady) { this.logText = '数据库未就绪'; return; }
    try {
      const resultManager = ResultManager.getInstance();
      const deletedCount = await resultManager.clearMeasureRecords();
      this.logText = `✅ 已清空 ${deletedCount} 条测量记录`;
    } catch (err) {
      this.logText = `❌ 异常: ${err}`;
    }
  }

  private async clearAllCalibrateRecords(): Promise<void> {
    if (!this.isRelationalReady) { this.logText = '数据库未就绪'; return; }
    try {
      const resultManager = ResultManager.getInstance();
      const deletedCount = await resultManager.clearCalibrateRecords();
      this.logText = `✅ 已清空 ${deletedCount} 条校准记录`;
    } catch (err) {
      this.logText = `❌ 异常: ${err}`;
    }
  }

  private showExportSuccessDialog(filePath: string) {
    AlertDialog.show({
      title: '导出成功',
      message: `文件已保存到:\n${filePath}`,
      confirm: { value: '确定', action: () => {} }
    });
  }

  private async queryMeasureRecordsForDisplay(): Promise<void> {
    if (!this.isRelationalReady) { this.logText = '数据库未就绪'; return; }
    try {
      const resultManager = ResultManager.getInstance();
      const records = await resultManager.getLatestMeasureRecords(20);

      this.measureRecords = [];
      for (const r of records) {
        const item: MeasureDisplayItem = {
          id: r.id || 0,
          dateTime: this.formatDateTime(r.dateTime),
          consistency: resultManager.displayResult(r.consistency),
          absorbance: r.absorbance.toFixed(3),
          mode: resultManager.getModeText(r.mode),
          resultType: resultManager.getResultTypeText(r.resultType),
          netAbsorbance: (r.absorbance - r.initConsistency).toFixed(3),
          measureRange: r.measureRange.toFixed(1)
        };
        this.measureRecords.push(item);
      }

      const totalCount = await resultManager.getMeasureRecordCount();
      this.logText = `共 ${totalCount} 条测量记录，已加载 ${this.measureRecords.length} 条`;
    } catch (err) {
      this.logText = `❌ 查询失败: ${err}`;
    }
  }

  private async queryCalibrateRecordsForDisplay(): Promise<void> {
    if (!this.isRelationalReady) { this.logText = '数据库未就绪'; return; }
    try {
      const resultManager = ResultManager.getInstance();
      const records = await resultManager.getCalibrateRecords({ orderBy: 'desc', limit: 20 });

      this.calibrateRecords = [];
      for (const r of records) {
        const item: CalibrateDisplayItem = {
          id: r.id || 0,
          dateTime: this.formatDateTime(r.dateTime),
          curveK: r.curveK.toFixed(4),
          curveB: r.curveB.toFixed(4),
          R2: r.R2.toFixed(4),
          point0Consistency: r.point0Consistency,
          measureRange: r.measureRange,
          rangeIndex: r.rangeIndex,
          point0InitAbsorbance: r.point0InitAbsorbance,
          point0Absorbance: r.point0Absorbance.toFixed(4),
          point1InitAbsorbance: r.point1InitAbsorbance,
          point1Absorbance: r.point1Absorbance.toFixed(4),
          point1Consistency: r.point1Consistency,
        };
        this.calibrateRecords.push(item);
      }
      this.calibrateCacheRecords = records;
      this.logText = `共 ${records.length} 条校准记录`;
    } catch (err) {
      this.logText = `❌ 查询失败: ${err}`;
    }
  }

  private buildMeasureQueryCondition(): MeasureQueryCondition {
    const condition: MeasureQueryCondition = {};
    if (this.measureStartTime > 0 && this.measureEndTime > 0) {
      condition.startTime = this.measureStartTime;
      condition.endTime = this.measureEndTime;
    } else if (this.measureStartTime > 0) {
      condition.startTime = this.measureStartTime;
    } else if (this.measureEndTime > 0) {
      condition.endTime = this.measureEndTime;
    }
    if (this.selectedModeIndex !== -1) {
      condition.mode = this.selectedModeIndex;
    }
    if (this.selectedTypeIndex !== -1) {
      condition.resultType = this.selectedTypeIndex;
    }
    condition.orderBy = 'desc';
    condition.limit = 100;
    return condition;
  }

  private async queryMeasureRecordsWithCondition(): Promise<void> {
    if (!this.isRelationalReady) { this.logText = '数据库未就绪'; return; }
    try {
      const resultManager = ResultManager.getInstance();
      const condition = this.buildMeasureQueryCondition();
      const records = await resultManager.getMeasureRecords(condition);

      this.measureRecords = [];
      for (const r of records) {
        const item: MeasureDisplayItem = {
          id: r.id || 0,
          dateTime: this.formatDateTime(r.dateTime),
          consistency: resultManager.displayResult(r.consistency),
          absorbance: r.absorbance.toFixed(3),
          mode: resultManager.getModeText(r.mode),
          resultType: resultManager.getResultTypeText(r.resultType),
          netAbsorbance: (r.absorbance - r.initConsistency).toFixed(3),
          measureRange: r.measureRange.toFixed(1)
        };
        this.measureRecords.push(item);
      }

      const totalCount = await resultManager.getMeasureRecordCount();
      this.logText = `共 ${totalCount} 条测量记录，当前查询结果 ${this.measureRecords.length} 条`;
    } catch (err) {
      this.logText = `❌ 查询失败: ${err}`;
    }
  }

  private buildCalibrateQueryCondition(): CalibrateQueryCondition {
    const condition: CalibrateQueryCondition = {};
    if (this.calibrateStartTime > 0 && this.calibrateEndTime > 0) {
      condition.startTime = this.calibrateStartTime;
      condition.endTime = this.calibrateEndTime;
    } else if (this.calibrateStartTime > 0) {
      condition.startTime = this.calibrateStartTime;
    } else if (this.calibrateEndTime > 0) {
      condition.endTime = this.calibrateEndTime;
    }
    condition.orderBy = 'desc';
    condition.limit = 100;
    return condition;
  }

  private async queryCalibrateRecordsWithCondition(): Promise<void> {
    if (!this.isRelationalReady) { this.logText = '数据库未就绪'; return; }
    try {
      const resultManager = ResultManager.getInstance();
      const condition = this.buildCalibrateQueryCondition();
      const records = await resultManager.getCalibrateRecords(condition);

      this.calibrateRecords = [];
      for (const r of records) {
        const item: CalibrateDisplayItem = {
          id: r.id || 0,
          dateTime: this.formatDateTime(r.dateTime),
          curveK: r.curveK.toFixed(4),
          curveB: r.curveB.toFixed(4),
          R2: r.R2.toFixed(4),
          point0InitAbsorbance: r.point0InitAbsorbance,
          point0Absorbance: r.point0Absorbance.toFixed(4),
          point1InitAbsorbance: r.point1InitAbsorbance,
          point1Absorbance: r.point1Absorbance.toFixed(4),
          point0Consistency: r.point0Consistency,
          point1Consistency: r.point1Consistency,
          measureRange: r.measureRange,
          rangeIndex: r.rangeIndex,
        };
        this.calibrateRecords.push(item);
      }
      this.logText = `当前查询结果 ${this.calibrateRecords.length} 条校准记录`;
    } catch (err) {
      this.logText = `❌ 查询失败: ${err}`;
    }
  }

  async updateCalibrateRangeData(record: CalibrateRecord): Promise<void> {
    try {
      const sm = SettingsManager.getInstance();
      const measureParamConfig = await sm.getMeasureParamConfig();
      const systemConfig = await sm.getSystemConfig();
      if (measureParamConfig && systemConfig) {
        sm.modifyMeasureParamConfigRangeData(measureParamConfig, record);

        const msm = MeasureStatusManager.getInstance();
        const measureStatus = await msm.getMeasureStatus();
        if (measureStatus) {
          let item: CalibrateItem = {
            dateTime: 0,
            curveB: 0,
            curveK: 1,
            point0Consistency: 0,
            point1Consistency: 0,
            point0Absorbance: 0,
            point1Absorbance: 0,
            zeroCalculateConsistency: 0,
            standardCalculateConsistency: 0,
            zeroCheckError: 0,
            standardCheckError: 0,
            r2: 1,
            zeroCalibrateDateTime: 0,
            standardCalibrateDateTime: 0,
            userSettings: false,
          };

          item.zeroCalculateConsistency = (record.point0Absorbance - measureParamConfig?.curveB) / measureParamConfig?.curveK;
          item.zeroCheckError = Math.abs(item.zeroCalculateConsistency - measureStatus.newResult.calibrate.zeroCalculateConsistency) / systemConfig.rangeViewMap[record.rangeIndex].view;
          item.zeroCalibrateDateTime = record.dateTime;
          item.standardCalculateConsistency = (record.point1Absorbance - measureParamConfig?.curveB) / measureParamConfig?.curveK;
          item.standardCheckError = Math.abs(item.standardCalculateConsistency - measureStatus.newResult.calibrate.standardCalculateConsistency) / systemConfig.rangeViewMap[record.rangeIndex].view;
          item.standardCalibrateDateTime = record.dateTime;
          item.curveB = record.curveB;
          item.curveK = record.curveK;
          item.point0Consistency = record.point0Consistency;
          item.point1Consistency = record.point1Consistency;
          item.point0Absorbance = record.point0Absorbance;
          item.point1Absorbance = record.point1Absorbance;

          msm.saveCalibrateConsistencyAdded(measureStatus, item, record.rangeIndex);
          msm.calibrateResultAdded(measureStatus, item, record.rangeIndex);
        }
      }
      this.logText = `当前id为${record.id}的校准记录成功设为当前校准参数!`;
    } catch (err) {
      this.logText = `❌ 设为当前参数失败: ${err}`;
    }
  }

  @Builder
  buildMeasureDataPanel() {
    Column() {
      Row() {
        Button('添加测试记录').fontSize(14).backgroundColor('#4CAF50').onClick(() => { this.addTestMeasureRecord(); })
        Button('刷新列表').fontSize(14).backgroundColor('#2196F3').onClick(() => { this.queryMeasureRecordsForDisplay(); })
        Button('导出CSV').fontSize(14).backgroundColor('#FF9800').onClick(() => { this.exportMeasureToCsv(); })
        Button('清空全部').fontSize(14).backgroundColor('#F44336').onClick(() => { this.clearAllMeasureRecords(); })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly)
      .margin({ bottom: 15 })

      Row() {
        DatePicker({
          start: new Date('2000-1-1'),
          end: new Date('2100-12-31'),
          selected: new Date(this.measureStartTime)
        })
          .onChange((value: DatePickerResult) => {
            const y = value.year as number;
            const m = (value.month as number) + 1;
            const d = value.day as number;
            const measureStartDate = new Date(`${y}-${m}-${d}`);
            this.measureStartTime = measureStartDate.getTime();
          })
          .height(40)
          .layoutWeight(1)
          .margin({ left: 30 })

        Text('~').fontSize(14).margin({ left: 8, right: 8 })

        DatePicker({
          start: new Date('2000-1-1'),
          end: new Date('2100-12-31'),
          selected: new Date(this.measureEndTime)
        })
          .onChange((value: DatePickerResult) => {
            const y = value.year as number;
            const m = (value.month as number) + 1;
            const d = value.day as number;
            const measureEndDate = new Date(`${y}-${m}-${d}`);
            this.measureEndTime = measureEndDate.getTime() + 24 * 60 * 60 * 1000 - 1;
          })
          .height(40)
          .layoutWeight(1)

        Text('标识:').fontSize(14).width(70)

        Select(this.modeOptions.map((opt: string): SelectOption => ({ value: opt })))
          .selected(1)
          .onSelect((index: number) => {
            if (index === 0) {
              this.selectedModeIndex = -1;
            } else {
              this.selectedModeIndex = index - 1;
            }
          })
          .height(36)
          .layoutWeight(1)

        Text('类型:').fontSize(14).width(70)

        Select(this.typeOptions.map((opt: string): SelectOption => ({ value: opt })))
          .selected(1)
          .onSelect((index: number) => {
            if (index === 0) {
              this.selectedTypeIndex = -1;
            } else {
              this.selectedTypeIndex = index - 1;
            }
          })
          .height(36)
          .layoutWeight(1)

        Button('检索').fontSize(14).backgroundColor('#007DFF').height(36).layoutWeight(1).margin({ right: 8 })
          .onClick(() => { this.queryMeasureRecordsWithCondition(); })
      }
      .width('100%')
      .margin({ bottom: 12 })

      if (this.measureRecords.length > 0) {
        Scroll() {
          Column() {
            Row() {
              Text('时间').width('18%').fontSize(12).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center)
              Text('浓度(mg/L)').width('12%').fontSize(12).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center)
              Text('吸光度(mAbs)').width('12%').fontSize(12).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center)
              Text('标识').width('10%').fontSize(12).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center)
              Text('类型').width('18%').fontSize(12).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center)
              Text('净吸光度').width('12%').fontSize(12).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center)
              Text('量程').width('10%').fontSize(12).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center)
            }
            .width('100%')
            .padding(10)
            .backgroundColor('#E0E0E0')
            .borderRadius(4)

            ForEach(this.measureRecords, (item: MeasureDisplayItem, index: number) => {
              Row() {
                Text(item.dateTime).width('18%').fontSize(12).textAlign(TextAlign.Center)
                Text(item.consistency).width('12%').fontSize(12).textAlign(TextAlign.Center)
                Text(item.absorbance).width('12%').fontSize(12).textAlign(TextAlign.Center)
                Text(item.mode).width('10%').fontSize(12).textAlign(TextAlign.Center)
                Text(item.resultType).width('18%').fontSize(12).textAlign(TextAlign.Center)
                Text(item.netAbsorbance).width('12%').fontSize(12).textAlign(TextAlign.Center)
                Text(item.measureRange).width('10%').fontSize(12).textAlign(TextAlign.Center)
              }
              .width('100%')
              .padding(8)
              .backgroundColor(index % 2 === 0 ? '#FAFAFA' : '#F5F5F5')
            }, (item: MeasureDisplayItem, index: number) => index.toString())
          }
          .width('100%')
        }
        .height(300)
        .width('100%')
      } else {
        Text('暂无测量数据，点击"添加测试记录"添加')
          .fontSize(14)
          .fontColor('#999')
          .margin({ top: 30 })
      }
    }
    .width('100%')
    .padding({ left: 10, right: 10 })
  }

  @Builder
  buildCalibrateDataPanel() {
    Column() {
      Row() {
        Button('添加测试记录').fontSize(14).backgroundColor('#4CAF50').onClick(() => { this.addTestCalibrateRecord(); })
        Button('刷新列表').fontSize(14).backgroundColor('#2196F3').onClick(() => { this.queryCalibrateRecordsForDisplay(); })
        Button('导出CSV').fontSize(14).backgroundColor('#FF9800').onClick(() => { this.exportCalibrateToCsv(); })
        Button('清空全部').fontSize(14).backgroundColor('#F44336').onClick(() => { this.clearAllCalibrateRecords(); })
        Button('设为当前校准参数').fontSize(14).backgroundColor('#907D36').onClick(() => {
          if (this.selectedCalibrateId === -1) {
            AlertDialog.show({
              title: '提示',
              message: `当前无选中行`,
              confirm: { value: '确定', action: () => {} }
            });
          } else {
            for (const r of this.calibrateCacheRecords) {
              if (r.id === this.selectedCalibrateId) {
                console.info("Selected id:", `${r.id}`);
                this.updateCalibrateRangeData(r);
              }
            }
            this.selectedCalibrateId = -1;
          }
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly)
      .margin({ bottom: 15 })

      Row() {
        DatePicker({
          start: new Date('2000-1-1'),
          end: new Date('2100-12-31'),
          selected: new Date(this.calibrateStartTime)
        })
          .onChange((value: DatePickerResult) => {
            const y = value.year as number;
            const m = (value.month as number) + 1;
            const d = value.day as number;
            const calibrateStartDate = new Date(`${y}-${m}-${d}`);
            this.calibrateStartTime = calibrateStartDate.getTime();
          })
          .height(40)
          .layoutWeight(1)
          .margin({ left: 30 })

        Text('~').fontSize(14).margin({ left: 8, right: 8 })

        DatePicker({
          start: new Date('2000-1-1'),
          end: new Date('2100-12-31'),
          selected: new Date(this.calibrateEndTime)
        })
          .onChange((value: DatePickerResult) => {
            const y = value.year as number;
            const m = (value.month as number) + 1;
            const d = value.day as number;
            const calibrateEndDate = new Date(`${y}-${m}-${d}`);
            this.calibrateEndTime = calibrateEndDate.getTime() + 24 * 60 * 60 * 1000 - 1;
          })
          .height(40)
          .layoutWeight(1)

        Button('检索').fontSize(14).backgroundColor('#007DFF').height(36).layoutWeight(1).margin({ right: 38 })
          .onClick(() => { this.queryCalibrateRecordsWithCondition(); })
      }
      .width('100%')
      .margin({ bottom: 12 })

      if (this.calibrateRecords.length > 0) {
        Column() {
          Row() {
            Text('选择').width('8%').fontSize(12).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center)
            Text('时间').width('18%').fontSize(12).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center)
            Text('斜率K').width('16%').fontSize(12).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center)
            Text('截距B').width('16%').fontSize(12).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center)
            Text('R²').width('16%').fontSize(12).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center)
            Text('量程').width('16%').fontSize(12).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center)
            Text('量程索引').width('10%').fontSize(12).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center)
          }
          .width('100%')
          .padding(10)
          .backgroundColor('#E0E0E0')
          .borderRadius(4)

          Scroll() {
            Column() {
              ForEach(this.calibrateRecords, (item: CalibrateDisplayItem, index: number) => {
                Row() {
                  Row() {
                    Radio({ value: item.id.toString(), group: 'calibrateGroup' })
                      .checked(this.selectedCalibrateId === item.id)
                  }
                  .width('8%')
                  .justifyContent(FlexAlign.Center)

                  Text(item.dateTime).width('18%').fontSize(12).textAlign(TextAlign.Center)
                  Text(item.curveK).width('16%').fontSize(12).textAlign(TextAlign.Center)
                  Text(item.curveB).width('16%').fontSize(12).textAlign(TextAlign.Center)
                  Text(item.R2).width('16%').fontSize(12).textAlign(TextAlign.Center)
                  Text(item.measureRange.toString()).width('16%').fontSize(12).textAlign(TextAlign.Center)
                  Text(item.rangeIndex.toString()).width('10%').fontSize(12).textAlign(TextAlign.Center)
                }
                .width('100%')
                .padding(8)
                .backgroundColor(index % 2 === 0 ? '#FAFAFA' : '#F5F5F5')
                .onClick(() => {
                  if (this.selectedCalibrateId === item.id)
                    this.selectedCalibrateId = -1;
                  else
                    this.selectedCalibrateId = item.id;
                })
              }, (item: CalibrateDisplayItem, index: number) => index.toString())
            }
            .width('100%')
          }
          .height('auto')
          .constraintSize({ maxHeight: 400 })
        }
        .width('100%')
        .layoutWeight(1)
      } else {
        Text('暂无校准数据，点击"添加测试记录"添加')
          .fontSize(14)
          .fontColor('#999')
          .margin({ top: 30 })
      }
    }
    .width('100%')
    .padding({ left: 10, right: 10 })
    .layoutWeight(1)
  }

  build() {
    Column() {
      Row() {
        Button('← 返回主菜单')
          .fontSize(16)
          .backgroundColor('#607D8B')
          .onClick(() => { this.backToMain(); })

        Blank().width(20)

        Button('测量数据管理')
          .fontSize(16)
          .backgroundColor(this.showMeasureDetailPanel ? '#4CAF50' : '#9E9E9E')
          .onClick(() => {
            this.showMeasureDetailPanel = true;
            this.showCalibrateDetailPanel = false;
            this.queryMeasureRecordsForDisplay();
          })

        Blank().width(20)

        Button('校准数据管理')
          .fontSize(16)
          .backgroundColor(this.showCalibrateDetailPanel ? '#2196F3' : '#9E9E9E')
          .onClick(() => {
            this.showCalibrateDetailPanel = true;
            this.showMeasureDetailPanel = false;
            this.queryCalibrateRecordsForDisplay();
          })
      }
      .width('90%')
      .margin({ top: 20, bottom: 20 })
      .justifyContent(FlexAlign.Center)

      Text(this.logText)
        .fontSize(14)
        .fontColor('#666')
        .padding(12)
        .backgroundColor('#F5F5F5')
        .width('95%')
        .borderRadius(8)
        .margin({ bottom: 15 })

      if (this.showMeasureDetailPanel) {
        this.buildMeasureDataPanel();
      }

      if (this.showCalibrateDetailPanel) {
        this.buildCalibrateDataPanel();
      }
    }
    .width('100%')
    .height('100%')
  }
}
