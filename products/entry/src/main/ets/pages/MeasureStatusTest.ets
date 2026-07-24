import { MeasureStatusManager } from 'dataservice';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

interface ButtonItem {
  text: string;
  action: () => void;
}

@Entry
@Component
struct MeasureStatusTest {
  @State isMeasureStatusReady: boolean = false;
  @State logText: string = '正在初始化测量状态配置...';

  aboutToAppear() {
    this.initMeasureStatusDatabase();
  }

  private async initMeasureStatusDatabase(): Promise<void> {
    try {
      const measureStatusManager = MeasureStatusManager.getInstance();
      const status = await measureStatusManager.getMeasureStatus();
      if (status) {
        this.isMeasureStatusReady = true;
        const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
        const preferencesPath = `${context.filesDir}/preferences/measure_status_config`;
        this.logText = `✅ 测量状态配置已就绪\n📁 数据库路径: ${preferencesPath}`;
      } else {
        this.isMeasureStatusReady = false;
        this.logText = '⚠️ 测量状态配置未就绪';
      }
    } catch (err) {
      this.isMeasureStatusReady = false;
      this.logText = `❌ 初始化失败: ${err}`;
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

  @Builder
  buildSection(title: string, buttons: Array<ButtonItem>) {
    Column() {
      Text(title).fontSize(18).fontWeight(FontWeight.Medium).margin({ top: 16, bottom: 8 }).alignSelf(ItemAlign.Start)
      Column() {
        ForEach(buttons, (btn: ButtonItem, index: number) => {
          Button(btn.text).width('80%').margin({ bottom: 8 }).onClick(() => {
            btn.action();
          })
        }, (btn: ButtonItem, index: number) => index.toString())
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
  }

  private async getMeasureStatusTest(): Promise<void> {
    if (!this.isMeasureStatusReady) { this.logText = '数据库未就绪'; return; }
    try {
      const msm = MeasureStatusManager.getInstance();
      const status = await msm.getMeasureStatus();
      if (status) {
        this.logText = `✅ 测量状态\n设备故障: ${status.isDeviceFault}\n上次测量失败: ${status.lastMeasureFail}`;
      } else {
        this.logText = '⚠️ 测量状态为空';
      }
    } catch (err) {
      this.logText = `❌ 异常: ${err}`;
    }
  }

  private async getMeasureStatusScheduleTest(): Promise<void> {
    if (!this.isMeasureStatusReady) { this.logText = '数据库未就绪'; return; }
    try {
      const msm = MeasureStatusManager.getInstance();
      const status = await msm.getMeasureStatus();
      if (status) {
        this.logText = `✅ 排程时间\n` +
          `自动测量: ${this.formatDateTime(status.schedule.autoMeasure.dateTime)}\n` +
          `零点核查: ${this.formatDateTime(status.schedule.zeroCheck.dateTime)}\n` +
          `量程核查: ${this.formatDateTime(status.schedule.rangeCheck.dateTime)}\n` +
          `自动校准: ${this.formatDateTime(status.schedule.autoCalibrate.dateTime)}\n` +
          `自动清洗: ${this.formatDateTime(status.schedule.autoClean.dateTime)}\n` +
          `自动空白检查: ${this.formatDateTime(status.schedule.autoBlankCheck.dateTime)}\n` +
          `自动检查: ${this.formatDateTime(status.schedule.autoCheck.dateTime)}\n` +
          `自动加标: ${this.formatDateTime(status.schedule.autoAddStandard.dateTime)}\n` +
          `自动平行: ${this.formatDateTime(status.schedule.autoParallel.dateTime)}`;
      } else {
        this.logText = '⚠️ 测量状态为空';
      }
    } catch (err) {
      this.logText = `❌ 异常: ${err}`;
    }
  }

  private async getMeasureReportTest(): Promise<void> {
    if (!this.isMeasureStatusReady) { this.logText = '数据库未就绪'; return; }
    try {
      const msm = MeasureStatusManager.getInstance();
      const status = await msm.getMeasureStatus();
      if (status) {
        const report = status.report;
        this.logText = `✅ 测量结果上报\n` +
          `测量结果 - 时间: ${this.formatDateTime(report.measure.dateTime)}\n` +
          `浓度: ${report.measure.consistency} mg/L\n` +
          `吸光度: ${report.measure.absorbance}\n` +
          `结果类型: ${report.measure.resultType}, 标识: ${report.measure.resultInfo}\n` +
          `加标结果 - 时间: ${this.formatDateTime(report.addStandard.dateTime)}\n` +
          `浓度: ${report.addStandard.consistency} mg/L\n` +
          `平行样结果 - 时间: ${this.formatDateTime(report.parallel.dateTime)}\n` +
          `浓度: ${report.parallel.consistency} mg/L\n` +
          `核查结果 - 时间: ${this.formatDateTime(report.check.dateTime)}\n` +
          `浓度: ${report.check.consistency} mg/L\n` +
          `零点核查 - 浓度: ${report.zeroCheck.consistency} mg/L\n` +
          `量程核查 - 浓度: ${report.rangeCheck.consistency}, 偏差: ${report.rangeCheck.checkError}%\n` +
          `质控样 - 浓度: ${report.qualityHandle.consistency}, 偏差: ${report.qualityHandle.checkError}%`;
      } else {
        this.logText = '⚠️ 测量状态为空';
      }
    } catch (err) {
      this.logText = `❌ 异常: ${err}`;
    }
  }

  private async getOfflineDataTest(): Promise<void> {
    if (!this.isMeasureStatusReady) { this.logText = '数据库未就绪'; return; }
    try {
      const msm = MeasureStatusManager.getInstance();
      const status = await msm.getMeasureStatus();
      if (status) {
        const offline = status.offline;
        this.logText = `✅ 离线数据缓存\n` +
          `测量结果 - 时间: ${this.formatDateTime(offline.measure.dateTime)}\n` +
          `浓度: ${offline.measure.consistency} mg/L, 标识: ${offline.measure.resultInfo}\n` +
          `加标结果 - 时间: ${this.formatDateTime(offline.addStandard.dateTime)}\n` +
          `浓度: ${offline.addStandard.consistency} mg/L\n` +
          `平行样结果 - 时间: ${this.formatDateTime(offline.parallel.dateTime)}\n` +
          `浓度: ${offline.parallel.consistency} mg/L\n` +
          `核查结果 - 时间: ${this.formatDateTime(offline.check.dateTime)}\n` +
          `浓度: ${offline.check.consistency} mg/L`;
      } else {
        this.logText = '⚠️ 测量状态为空';
      }
    } catch (err) {
      this.logText = `❌ 异常: ${err}`;
    }
  }

  private async getProformaResultTest(): Promise<void> {
    if (!this.isMeasureStatusReady) { this.logText = '数据库未就绪'; return; }
    try {
      const msm = MeasureStatusManager.getInstance();
      const status = await msm.getMeasureStatus();
      if (status) {
        const proforma = status.proformaResult.measure;
        this.logText = `✅ 预估结果\n` +
          `时间: ${this.formatDateTime(proforma.dateTime)}\n` +
          `浓度: ${proforma.consistency} mg/L\n` +
          `吸光度: ${proforma.absorbance}\n` +
          `空白参考AD: ${proforma.blankReference}, 空白测量AD: ${proforma.blankMeasure}\n` +
          `初始参考AD: ${proforma.initReference}, 初始测量AD: ${proforma.initMeasure}\n` +
          `显色参考AD: ${proforma.finalReference}, 显色测量AD: ${proforma.finalMeasure}`;
      } else {
        this.logText = '⚠️ 测量状态为空';
      }
    } catch (err) {
      this.logText = `❌ 异常: ${err}`;
    }
  }

  private async getNewResultTest(): Promise<void> {
    if (!this.isMeasureStatusReady) { this.logText = '数据库未就绪'; return; }
    try {
      const msm = MeasureStatusManager.getInstance();
      const status = await msm.getMeasureStatus();
      if (status) {
        const newResult = status.newResult;
        this.logText = `✅ 最新测量结果\n` +
          `主界面结果 - 时间: ${this.formatDateTime(newResult.mainResult.dateTime)}\n` +
          `类型: ${newResult.mainResult.resultType}, 浓度: ${newResult.mainResult.consistency} mg/L\n` +
          `测量结果 - 浓度: ${newResult.measure.consistency} mg/L, 吸光度: ${newResult.measure.absorbance}\n` +
          `测量类型: ${newResult.measure.resultType}, 数据标识: ${newResult.measure.resultInfo}\n` +
          `是否用户启动: ${newResult.measure.isUseStart}, 是否故障: ${newResult.measure.isFault}\n` +
          `校准结果 - K: ${newResult.calibrate.curveK}, B: ${newResult.calibrate.curveB}, R²: ${newResult.calibrate.r2}\n` +
          `零点浓度: ${newResult.calibrate.point0Consistency}, 零点吸光度: ${newResult.calibrate.point0Absorbance}\n` +
          `标点浓度: ${newResult.calibrate.point1Consistency}, 标点吸光度: ${newResult.calibrate.point1Absorbance}`;
      } else {
        this.logText = '⚠️ 测量状态为空';
      }
    } catch (err) {
      this.logText = `❌ 异常: ${err}`;
    }
  }

  private async getCalibrateListTest(): Promise<void> {
    if (!this.isMeasureStatusReady) { this.logText = '数据库未就绪'; return; }
    try {
      const msm = MeasureStatusManager.getInstance();
      const status = await msm.getMeasureStatus();
      if (status && status.calibrate.length > 0) {
        let msg = `✅ 校准曲线列表 (共${status.calibrate.length}条)\n`;
        for (let i = 0; i < Math.min(5, status.calibrate.length); i++) {
          const c = status.calibrate[i];
          msg += `${i + 1}. ${this.formatDateTime(c.dateTime)} - K=${c.curveK.toFixed(4)}, B=${c.curveB.toFixed(4)}, R²=${c.r2.toFixed(4)}\n`;
          msg += `   零点浓度:${c.point0Consistency}, 标点浓度:${c.point1Consistency}\n`;
        }
        if (status.calibrate.length > 5) {
          msg += `... 共${status.calibrate.length}条，仅显示最近5条`;
        }
        this.logText = msg;
      } else {
        this.logText = '⚠️ 校准曲线列表为空';
      }
    } catch (err) {
      this.logText = `❌ 异常: ${err}`;
    }
  }

  private async getMeasurerSaveTimeTest(): Promise<void> {
    if (!this.isMeasureStatusReady) { this.logText = '数据库未就绪'; return; }
    try {
      const msm = MeasureStatusManager.getInstance();
      const status = await msm.getMeasureStatus();
      if (status && status.measurerSaveTime.length > 0) {
        let msg = `✅ 测量流程保存时间 (共${status.measurerSaveTime.length}条)\n`;
        let count = 0;
        for (let i = 0; i < status.measurerSaveTime.length && count < 5; i++) {
          const item = status.measurerSaveTime[i];
          if (item.name !== '') {
            msg += `${count + 1}. ${item.name}: t1=${item.time1}s, t2=${item.time2}s, t3=${item.time3}s\n`;
            count++;
          }
        }
        if (count === 0) {
          msg = '⚠️ 无测量流程保存数据';
        }
        this.logText = msg;
      } else {
        this.logText = '⚠️ 测量流程保存时间为空';
      }
    } catch (err) {
      this.logText = `❌ 异常: ${err}`;
    }
  }

  private async getMeasurerTimeTest(): Promise<void> {
    if (!this.isMeasureStatusReady) { this.logText = '数据库未就绪'; return; }
    try {
      const msm = MeasureStatusManager.getInstance();
      const status = await msm.getMeasureStatus();
      if (status && status.measurerTime.length > 0) {
        let msg = `✅ 测量流程时间 (共${status.measurerTime.length}条)\n`;
        let count = 0;
        for (let i = 0; i < status.measurerTime.length && count < 5; i++) {
          const item = status.measurerTime[i];
          if (item.name !== '') {
            msg += `${count + 1}. ${item.name}: t1=${item.time1}s, t2=${item.time2}s\n`;
            count++;
          }
        }
        if (count === 0) {
          msg = '⚠️ 无测量流程时间数据';
        }
        this.logText = msg;
      } else {
        this.logText = '⚠️ 测量流程时间为空';
      }
    } catch (err) {
      this.logText = `❌ 异常: ${err}`;
    }
  }

  private async updateDeviceFaultTest(): Promise<void> {
    if (!this.isMeasureStatusReady) { this.logText = '数据库未就绪'; return; }
    try {
      const msm = MeasureStatusManager.getInstance();
      const status = await msm.getMeasureStatus();
      if (status) {
        const newValue = !status.isDeviceFault;
        await msm.setDeviceFault(newValue);
        this.logText = `✅ 设备故障标志已更新\n新值: ${newValue}`;
      } else {
        this.logText = '⚠️ 测量状态为空';
      }
    } catch (err) {
      this.logText = `❌ 异常: ${err}`;
    }
  }

  private async updateLastMeasureFailTest(): Promise<void> {
    if (!this.isMeasureStatusReady) { this.logText = '数据库未就绪'; return; }
    try {
      const msm = MeasureStatusManager.getInstance();
      const newValue = Math.floor(Math.random() * 3);
      await msm.setLastMeasureFail(newValue);
      this.logText = `✅ 上次测量失败标志已更新\n新值: ${newValue} (0=成功, 1=排液, 2=排液+清洗)`;
    } catch (err) {
      this.logText = `❌ 异常: ${err}`;
    }
  }

  private async resetMeasureStatusTest(): Promise<void> {
    if (!this.isMeasureStatusReady) { this.logText = '数据库未就绪'; return; }
    try {
      const msm = MeasureStatusManager.getInstance();
      await msm.resetMeasureStatus();
      this.logText = '✅ 测量状态已重置为默认值';
    } catch (err) {
      this.logText = `❌ 异常: ${err}`;
    }
  }

  build() {
    Scroll() {
      Column() {
        Button('← 返回主菜单')
          .fontSize(16).margin({ top: 20, bottom: 10 })
          .width('30%')
          .alignSelf(ItemAlign.Start)
          .onClick(() => { this.backToMain(); })

        Text('测量状态配置')
          .fontSize(24).fontWeight(FontWeight.Bold).margin({ top: 10, bottom: 10 })

        Text(this.logText)
          .fontSize(14).fontColor('#333').margin({ bottom: 10 })
          .padding(12).backgroundColor('#F0F4F0').width('92%').borderRadius(8)

        this.buildSection('测量状态获取', [
          { text: '获取测量状态', action: () => { this.getMeasureStatusTest(); } },
          { text: '获取排程时间', action: () => { this.getMeasureStatusScheduleTest(); } },
          { text: '获取测量结果上报', action: () => { this.getMeasureReportTest(); } },
          { text: '获取离线数据缓存', action: () => { this.getOfflineDataTest(); } },
          { text: '获取预估结果', action: () => { this.getProformaResultTest(); } },
          { text: '获取最新测量结果', action: () => { this.getNewResultTest(); } },
          { text: '获取校准曲线列表', action: () => { this.getCalibrateListTest(); } },
          { text: '获取测量流程保存时间', action: () => { this.getMeasurerSaveTimeTest(); } },
          { text: '获取测量流程时间', action: () => { this.getMeasurerTimeTest(); } }
        ])

        this.buildSection('测量状态设置', [
          { text: '切换设备故障标志', action: () => { this.updateDeviceFaultTest(); } },
          { text: '随机设置上次测量失败标志', action: () => { this.updateLastMeasureFailTest(); } },
          { text: '重置测量状态为默认', action: () => { this.resetMeasureStatusTest(); } }
        ])

        Blank().height(40)
      }
      .width('100%').padding(20)
    }
    .height('100%')
    .width('100%')
  }
}
