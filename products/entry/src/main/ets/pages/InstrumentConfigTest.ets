import { SettingsManager, ManufactureType, Language, ReportMode, MeasureMode, InstrumentInfoConfig } from 'dataservice';
import { RoleType } from 'permission';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

interface ButtonItem {
  text: string;
  action: () => void;
}

@Entry
@Component
struct InstrumentConfigTest {
  @State isInstrumentReady: boolean = false;
  @State logText: string = '正在初始化仪器信息配置...';

  aboutToAppear() {
    this.initInstrumentDatabase();
  }

  private async initInstrumentDatabase(): Promise<void> {
    try {
      const settingsManager = SettingsManager.getInstance();
      const info = await settingsManager.getInstrumentInfo();
      if (info) {
        this.isInstrumentReady = true;
        const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
        const preferencesPath = `${context.filesDir}/preferences/instrument_config`;
        this.logText = `✅ 仪器信息配置已就绪\n📁 数据库路径: ${preferencesPath}`;
      } else {
        this.isInstrumentReady = false;
        this.logText = '⚠️ 仪器信息配置未就绪';
      }
    } catch (err) {
      this.isInstrumentReady = false;
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

  private async getInstrumentInfoTest(): Promise<void> {
    if (!this.isInstrumentReady) { this.logText = '数据库未就绪'; return; }
    try {
      const sm = SettingsManager.getInstance();
      const info = await sm.getInstrumentInfo();
      if (info) {
        this.logText = `✅ 仪器信息\n型号: ${info.model}\nSN: ${info.sn}\n厂商: ${info.manufacturer}\n类型: ${ManufactureType[info.manufactureType]}`;
      } else {
        this.logText = '⚠️ 仪器信息为空';
      }
    } catch (err) {
      this.logText = `❌ 异常: ${err}`;
    }
  }

  private async updateInstrumentInfoTest(): Promise<void> {
    if (!this.isInstrumentReady) { this.logText = '数据库未就绪'; return; }
    try {
      const sm = SettingsManager.getInstance();
      const current = await sm.getInstrumentInfo();
      if (!current) { this.logText = '无当前配置'; return; }
      const newInfo: InstrumentInfoConfig = {
        model: current.model,
        manuDate: { year: current.manuDate.year, month: current.manuDate.month, day: current.manuDate.day },
        type: current.type,
        manufacturer: current.manufacturer,
        MfrN: current.MfrN,
        uuid: current.uuid,
        sn: `UPD_${Date.now()}`,
        reagentLicense: { enable: current.reagentLicense.enable, expirationDate: current.reagentLicense.expirationDate },
        expirationDate: current.expirationDate,
        license: current.license,
        permanent: current.permanent,
        manufactureType: current.manufactureType,
        showModel: current.showModel,
        showName: current.showName
      };
      await sm.setInstrumentInfo(newInfo);
      this.logText = `✅ 仪器信息更新成功\n新SN: ${newInfo.sn}`;
    } catch (err) {
      this.logText = `❌ 异常: ${err}`;
    }
  }

  private async getMainBoardInfoTest(): Promise<void> {
    if (!this.isInstrumentReady) { this.logText = '数据库未就绪'; return; }
    try {
      const sm = SettingsManager.getInstance();
      const info = await sm.getMainBoardInfo();
      if (info) {
        this.logText = `✅ 主板信息\n型号: ${info.model}\nSN: ${info.sn}\n厂商: ${info.manufacturer}`;
      } else {
        this.logText = '⚠️ 主板信息为空';
      }
    } catch (err) {
      this.logText = `❌ 异常: ${err}`;
    }
  }

  private async getHardwareConfigTest(): Promise<void> {
    if (!this.isInstrumentReady) { this.logText = '数据库未就绪'; return; }
    try {
      const sm = SettingsManager.getInstance();
      const hw = await sm.getHardwareConfig();
      if (hw) {
        this.logText = `✅ 硬件配置\n反应池体积: ${hw.reactionCamera.volume} mL\n定量点数: ${hw.meterPoint.num}\n泵因子: ${hw.pumpFactor.ref}`;
      } else {
        this.logText = '⚠️ 硬件配置为空';
      }
    } catch (err) {
      this.logText = `❌ 异常: ${err}`;
    }
  }

  private async getMeasureParamTest(): Promise<void> {
    if (!this.isInstrumentReady) { this.logText = '数据库未就绪'; return; }
    try {
      const sm = SettingsManager.getInstance();
      const mp = await sm.getMeasureParamConfig();
      if (mp) {
        this.logText = `✅ 测量参数\n当前量程: ${mp.currentRangeIndex}\n消解温度: ${mp.digestTemperature}℃\n消解时间: ${mp.digestTime}s\nPID调光: ${mp.pidCtrl}`;
      } else {
        this.logText = '⚠️ 测量参数为空';
      }
    } catch (err) {
      this.logText = `❌ 异常: ${err}`;
    }
  }

  private async updateMeasureParamTest(): Promise<void> {
    if (!this.isInstrumentReady) { this.logText = '数据库未就绪'; return; }
    try {
      const sm = SettingsManager.getInstance();
      const mp = await sm.getMeasureParamConfig();
      if (!mp) { this.logText = '无配置'; return; }
      mp.digestTemperature = mp.digestTemperature === 165 ? 180 : 165;
      await sm.setMeasureParamConfig(mp);
      this.logText = `✅ 测量参数更新成功\n消解温度改为: ${mp.digestTemperature}`;
    } catch (err) {
      this.logText = `❌ 异常: ${err}`;
    }
  }

  private async getInterconnectionTest(): Promise<void> {
    if (!this.isInstrumentReady) { this.logText = '数据库未就绪'; return; }
    try {
      const sm = SettingsManager.getInstance();
      const ic = await sm.getInterconnectionConfig();
      if (ic) {
        this.logText = `✅ 对外接口配置\n通信地址: ${ic.connectAddress}\n上报模式: ${ReportMode[ic.reportMode]}\n测量上限: ${ic.meaUpLimit}`;
      } else {
        this.logText = '⚠️ 对外接口配置为空';
      }
    } catch (err) {
      this.logText = `❌ 异常: ${err}`;
    }
  }

  private async updateInterconnectionTest(): Promise<void> {
    if (!this.isInstrumentReady) { this.logText = '数据库未就绪'; return; }
    try {
      const sm = SettingsManager.getInstance();
      const ic = await sm.getInterconnectionConfig();
      if (!ic) { this.logText = '无配置'; return; }
      ic.connectAddress = ic.connectAddress === 1 ? 2 : 1;
      await sm.setInterconnectionConfig(ic);
      this.logText = `✅ 对外接口配置更新成功\n新通信地址: ${ic.connectAddress}`;
    } catch (err) {
      this.logText = `❌ 异常: ${err}`;
    }
  }

  private async getSchedulerTest(): Promise<void> {
    if (!this.isInstrumentReady) { this.logText = '数据库未就绪'; return; }
    try {
      const sm = SettingsManager.getInstance();
      const sc = await sm.getSchedulerConfig();
      if (sc) {
        this.logText = `✅ 排期配置\n测量模式: ${MeasureMode[sc.measure.mode]}\n测量间隔: ${sc.measure.interval}h\n零点核查间隔: ${sc.zeroCheck.interval}h`;
      } else {
        this.logText = '⚠️ 排期配置为空';
      }
    } catch (err) {
      this.logText = `❌ 异常: ${err}`;
    }
  }

  private async updateSchedulerTest(): Promise<void> {
    if (!this.isInstrumentReady) { this.logText = '数据库未就绪'; return; }
    try {
      const sm = SettingsManager.getInstance();
      const sc = await sm.getSchedulerConfig();
      if (!sc) { this.logText = '无配置'; return; }
      sc.measure.interval = sc.measure.interval === 2 ? 4 : 2;
      sc.measure.mode = sc.measure.mode === MeasureMode.Trigger ? MeasureMode.Periodic : MeasureMode.Trigger;
      await sm.setSchedulerConfig(sc);
      this.logText = `✅ 排期配置更新成功\n新测量间隔: ${sc.measure.interval}h`;
    } catch (err) {
      this.logText = `❌ 异常: ${err}`;
    }
  }

  private async updateTimedPointTest(): Promise<void> {
    if (!this.isInstrumentReady) { this.logText = '数据库未就绪'; return; }
    try {
      const sm = SettingsManager.getInstance();
      const points = await sm.getTimedPoint('config.scheduler.measure');
      const newPoints: boolean[] = [];
      for (let i = 0; i < points.length; i++) {
        newPoints.push(points[i]);
      }
      if (newPoints.length > 0) newPoints[0] = !newPoints[0];
      const success = await sm.setTimedPoint('config.scheduler.measure', newPoints);
      this.logText = success ? `✅ 定时点更新成功，第1点变为${newPoints[0]}` : '❌ 更新失败';
    } catch (err) {
      this.logText = `❌ 异常: ${err}`;
    }
  }

  private async getSystemConfigTest(): Promise<void> {
    if (!this.isInstrumentReady) { this.logText = '数据库未就绪'; return; }
    try {
      const sm = SettingsManager.getInstance();
      const sys = await sm.getSystemConfig();
      if (sys) {
        this.logText = `✅ 系统配置\n语言: ${Language[sys.language]}\n故障停机: ${sys.faultBlocking}\n调试模式: ${sys.debugMode}\n服务器IP: ${sys.serverIP}`;
      } else {
        this.logText = '⚠️ 系统配置为空';
      }
    } catch (err) {
      this.logText = `❌ 异常: ${err}`;
    }
  }

  private async updateSystemConfigTest(): Promise<void> {
    if (!this.isInstrumentReady) { this.logText = '数据库未就绪'; return; }
    try {
      const sm = SettingsManager.getInstance();
      const sys = await sm.getSystemConfig();
      if (!sys) { this.logText = '无配置'; return; }
      sys.faultBlocking = !sys.faultBlocking;
      await sm.setSystemConfig(sys);
      this.logText = `✅ 系统配置更新成功\n故障停机改为: ${sys.faultBlocking}`;
    } catch (err) {
      this.logText = `❌ 异常: ${err}`;
    }
  }

  private async verifyNormalUserPwdTest(): Promise<void> {
    if (!this.isInstrumentReady) { this.logText = '数据库未就绪'; return; }
    try {
      const sm = SettingsManager.getInstance();
      const valid = await sm.verifyPassword('000000', RoleType.OPERATOR);
      this.logText = valid ? '✅ 普通用户密码验证成功(000000)' : '❌ 验证失败';
    } catch (err) {
      this.logText = `❌ 异常: ${err}`;
    }
  }

  private async updateNormalUserPwdTest(): Promise<void> {
    if (!this.isInstrumentReady) { this.logText = '数据库未就绪'; return; }
    try {
      const sm = SettingsManager.getInstance();
      await sm.updatePassword(RoleType.OPERATOR, 'new123');
      const valid = await sm.verifyPassword('new123', RoleType.OPERATOR);
      this.logText = valid ? '✅ 修改密码成功，新密码new123验证通过' : '❌ 修改失败';
    } catch (err) {
      this.logText = `❌ 异常: ${err}`;
    }
  }

  private async getMeasureRunningTest(): Promise<void> {
    if (!this.isInstrumentReady) { this.logText = '数据库未就绪'; return; }
    try {
      const sm = SettingsManager.getInstance();
      const running = await sm.getMeasureRunning();
      if (running) {
        this.logText = `✅ 测量运行状态\n是否正在测量: ${running.isMeasuring}\n是否正常停止流程: ${running.isCorrectStopFlow}\n上次测量时间: ${running.lastMeasureTime === 0 ? '无' : this.formatDateTime(running.lastMeasureTime)}`;
      } else {
        this.logText = '⚠️ 测量运行状态为空';
      }
    } catch (err) {
      this.logText = `❌ 异常: ${err}`;
    }
  }

  private async updateMeasureRunningTest(): Promise<void> {
    if (!this.isInstrumentReady) { this.logText = '数据库未就绪'; return; }
    try {
      const sm = SettingsManager.getInstance();
      const running = await sm.getMeasureRunning();
      if (running) {
        running.isMeasuring = !running.isMeasuring;
        await sm.setMeasureRunning(running);
        this.logText = `✅ 测量运行状态更新\nisMeasuring = ${running.isMeasuring}`;
      } else {
        this.logText = '⚠️ 测量运行状态为空';
      }
    } catch (err) {
      this.logText = `❌ 异常: ${err}`;
    }
  }

  private async getRemainStatusTest(): Promise<void> {
    if (!this.isInstrumentReady) { this.logText = '数据库未就绪'; return; }
    try {
      const sm = SettingsManager.getInstance();
      const remain = await sm.getRemainStatus();
      if (remain) {
        this.logText = `✅ 试剂余量\n标准液: ${remain.standard} mL\n空白液: ${remain.blank} mL\n试剂1: ${remain.reagent1} mL\n试剂2: ${remain.reagent2} mL\n废液: ${remain.waste} mL`;
      } else {
        this.logText = '⚠️ 试剂余量状态为空';
      }
    } catch (err) {
      this.logText = `❌ 异常: ${err}`;
    }
  }

  private async updateReagentRemainTest(): Promise<void> {
    if (!this.isInstrumentReady) { this.logText = '数据库未就绪'; return; }
    try {
      const sm = SettingsManager.getInstance();
      await sm.updateReagentRemain('reagent1', 5);
      const remain = await sm.getRemainStatus();
      this.logText = `✅ 扣减试剂1 5mL成功\n试剂1剩余: ${remain?.reagent1 ?? 0} mL`;
    } catch (err) {
      this.logText = `❌ 异常: ${err}`;
    }
  }

  private async getConsumableTest(): Promise<void> {
    if (!this.isInstrumentReady) { this.logText = '数据库未就绪'; return; }
    try {
      const sm = SettingsManager.getInstance();
      const cons = await sm.getConsumableConfig();
      if (cons) {
        this.logText = `✅ 耗材配置\n泵管更换周期: ${cons.pumpPipe.cycle} 天\n上次更换时间: ${cons.pumpPipe.lastTime}`;
      } else {
        this.logText = '⚠️ 耗材配置为空';
      }
    } catch (err) {
      this.logText = `❌ 异常: ${err}`;
    }
  }

  private async updateConsumableTest(): Promise<void> {
    if (!this.isInstrumentReady) { this.logText = '数据库未就绪'; return; }
    try {
      const sm = SettingsManager.getInstance();
      const cons = await sm.getConsumableConfig();
      if (cons) {
        cons.pumpPipe.cycle = cons.pumpPipe.cycle === 36 ? 30 : 36;
        await sm.setConsumableConfig(cons);
        this.logText = `✅ 耗材配置更新成功\n泵管周期改为: ${cons.pumpPipe.cycle} 天`;
      } else {
        this.logText = '⚠️ 耗材配置为空';
      }
    } catch (err) {
      this.logText = `❌ 异常: ${err}`;
    }
  }

  private async resetRemainStatusTest(): Promise<void> {
    if (!this.isInstrumentReady) { this.logText = '数据库未就绪'; return; }
    try {
      const sm = SettingsManager.getInstance();
      await sm.resetRemainStatus();
      this.logText = '✅ 试剂余量已重置为默认值';
    } catch (err) {
      this.logText = `❌ 异常: ${err}`;
    }
  }

  private async printAllConfigs(): Promise<void> {
    if (!this.isInstrumentReady) {
      this.logText = '数据库未就绪，无法打印配置';
      return;
    }
    try {
      const sm = SettingsManager.getInstance();
      const summary = await sm.getAllSettingConfig();
      this.logText = `✅ 配置已打印到控制台\n\n${summary}`;
    } catch (err) {
      this.logText = `❌ 打印配置失败: ${err}`;
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

        Text('仪器信息配置')
          .fontSize(24).fontWeight(FontWeight.Bold).margin({ top: 10, bottom: 10 })

        Text(this.logText)
          .fontSize(14).fontColor('#333').margin({ bottom: 10 })
          .padding(12).backgroundColor('#F0F4F0').width('92%').borderRadius(8)

        this.buildSection('调试工具', [
          { text: '📄 打印所有配置到控制台', action: () => { this.printAllConfigs(); } }
        ])

        Divider().width('90%').margin(16)

        this.buildSection('仪器信息', [
          { text: '获取仪器信息', action: () => { this.getInstrumentInfoTest(); } },
          { text: '更新仪器信息(SN)', action: () => { this.updateInstrumentInfoTest(); } },
          { text: '获取主板信息', action: () => { this.getMainBoardInfoTest(); } },
          { text: '获取硬件配置', action: () => { this.getHardwareConfigTest(); } }
        ])

        this.buildSection('测量参数', [
          { text: '获取测量参数', action: () => { this.getMeasureParamTest(); } },
          { text: '切换消解温度', action: () => { this.updateMeasureParamTest(); } }
        ])

        this.buildSection('对外接口配置', [
          { text: '获取接口配置', action: () => { this.getInterconnectionTest(); } },
          { text: '切换通信地址', action: () => { this.updateInterconnectionTest(); } }
        ])

        this.buildSection('排期配置', [
          { text: '获取排期配置', action: () => { this.getSchedulerTest(); } },
          { text: '切换测量间隔', action: () => { this.updateSchedulerTest(); } },
          { text: '切换第1个定时点', action: () => { this.updateTimedPointTest(); } }
        ])

        this.buildSection('系统配置', [
          { text: '获取系统配置', action: () => { this.getSystemConfigTest(); } },
          { text: '切换故障停机标志', action: () => { this.updateSystemConfigTest(); } }
        ])

        this.buildSection('用户数据(密码)', [
          { text: '验证普通用户密码(000000)', action: () => { this.verifyNormalUserPwdTest(); } },
          { text: '修改普通用户密码为new123', action: () => { this.updateNormalUserPwdTest(); } }
        ])

        this.buildSection('测量运行状态', [
          { text: '获取测量运行状态', action: () => { this.getMeasureRunningTest(); } },
          { text: '切换测量运行标志', action: () => { this.updateMeasureRunningTest(); } }
        ])

        this.buildSection('试剂/耗材管理', [
          { text: '获取试剂余量', action: () => { this.getRemainStatusTest(); } },
          { text: '扣减试剂1(5mL)', action: () => { this.updateReagentRemainTest(); } },
          { text: '重置试剂余量(默认)', action: () => { this.resetRemainStatusTest(); } },
          { text: '获取耗材配置', action: () => { this.getConsumableTest(); } },
          { text: '切换泵管周期', action: () => { this.updateConsumableTest(); } }
        ])

        Blank().height(40)
      }
      .width('100%').padding(20)
    }
    .height('100%')
    .width('100%')
  }
}
