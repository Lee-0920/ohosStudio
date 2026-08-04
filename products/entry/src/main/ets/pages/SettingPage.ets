import { common } from '@kit.AbilityKit';
import { DataActionButton } from '../components/DataActionButton';
import { GradientSideTabBar } from '../components/GradientSideTabBar';
import { UserSettingsService } from '../services/UserSettingsService';
import { getGlobalModbusServer } from 'modbus';
import { UiUtil } from 'base';
import { SetConfig, Type, Param } from 'flow/src/main/ets/Config/BaseInterface';
import { ParameterItem } from 'flow/src/main/ets/Config/BaseEnum';
import {
  ExternalInterfaceConfig,
  MeasurementParameterConfig,
  MeasurementScheduleConfig,
  SystemParametersConfig
} from 'flow/src/main/ets/Config/ScheduleMeasurementConfig';
import { preferences } from '@kit.ArkData';

@Component
export struct SettingPage {
  @Prop viewportWidth: number = 1024;
  @Prop viewportHeight: number = 768;
  @Prop scaleFactor: number = 1.92;
  private columns: string[] = ['类别', '参数项', '值', '单位'];
  @State config: SetConfig = MeasurementScheduleConfig;
  @State private selectedSettingTab: string = '测量排期';
  @State private appliedConfigVersion: number = 0;
  @State private configActionMessage: string = '';
  private readonly settingTabs: string[] = ['测量排期', '测量参数', '外联接口', '系统参数'];
  // 存储每个标签页的初始配置，用于恢复默认
  private initialConfigs: Map<string, SetConfig> = new Map();
  private timer: number = -1;

  private getHostContext(): common.Context | null {
    const context = this.getUIContext().getHostContext();
    if (!context) {
      return null;
    }
    return context as common.Context;
  }

  // Modbus 协议表持久化键，需与 EntryAbility 中恢复逻辑保持一致
  private readonly KEY_MODBUS_PROTOCOL_TABLE: string = 'system-modbus-table';

  aboutToAppear(): void {
    void this.restoreModbusProtocolSelection();
    // 初始化所有标签页的初始配置
    this.initInitialConfigs();
  }

  aboutToDisappear(): void {
    clearTimeout(this.timer);
  }

  /**
   * 初始化所有标签页的初始配置（深拷贝）
   */
  private initInitialConfigs(): void {
    this.initialConfigs.set(this.settingTabs[0], this.deepCopyConfig(MeasurementScheduleConfig));
    this.initialConfigs.set(this.settingTabs[1], this.deepCopyConfig(MeasurementParameterConfig));
    this.initialConfigs.set(this.settingTabs[2], this.deepCopyConfig(ExternalInterfaceConfig));
    this.initialConfigs.set(this.settingTabs[3], this.deepCopyConfig(SystemParametersConfig));
  }

  /**
   * 深拷贝配置对象
   */
  private deepCopyConfig(config: SetConfig): SetConfig {
    return JSON.parse(JSON.stringify(config)) as SetConfig;
  }

  /**
   * 从持久化存储恢复 Modbus 协议选择，并同步到系统参数配置中。
   */
  private async restoreModbusProtocolSelection(): Promise<void> {
    const context = this.getHostContext();
    if (!context) {
      return;
    }

    try {
      const persisted = await UserSettingsService.loadSettingValues(context, [
        { key: this.KEY_MODBUS_PROTOCOL_TABLE, value: 'LS4.0' }
      ]);
      const tableName = persisted.find(item => item.key === this.KEY_MODBUS_PROTOCOL_TABLE)?.value ?? 'LS4.0';
      const modeValue = this.protocolTableNameToModbusProtocolMode(tableName);
      this.applyModbusProtocolModeToConfig(modeValue);
    } catch (err) {
      console.error(`恢复 Modbus 协议选择失败: ${JSON.stringify(err)}`);
    }
  }

  /**
   * 将协议表名称映射到界面选项中的显示值。
   */
  private protocolTableNameToModbusProtocolMode(tableName: string): string {
    const map: Record<string, string> = {
      'LS4.0': 'LS4.0',
      'LS1.0': 'LS1.0',
      'LS2.0': 'LS2.0',
      'JS': 'JS',
      'SZBA': 'SZBA',
      '地表水1.0': '地表水1.0',
      'SC': 'SC',
      '西宁动态管控': '西宁动态管控',
      'GZ': 'GZ',
      'JX': 'JX',
      'XiAn': 'XiAn',
      'YC': 'YC'
    };
    return map[tableName] ?? 'LS4.0';
  }

  /**
   * 将界面选项中的显示值映射到协议表名称。
   */
  private modbusProtocolModeToTableName(modeValue: string): string {
    const map: Record<string, string> = {
      'LS4.0': 'LS4.0',
      'LS1.0': 'LS1.0',
      'LS2.0': 'LS2.0',
      'JS': 'JS',
      'SZBA': 'SZBA',
      '地表水1.0': '地表水1.0',
      'SC': 'SC',
      '西宁动态管控': '西宁动态管控',
      'GZ': 'GZ',
      'JX': 'JX',
      'XiAn': 'XiAn',
      'YC': 'YC'
    };
    return map[modeValue] ?? 'LS4.0';
  }

  /**
   * 在系统参数配置中定位 Modbus 协议选项并设置选中索引。
   */
  private applyModbusProtocolModeToConfig(modeValue: string): void {
    const modbusType = this.config.type.find((type: Type) =>
    type.params.some((param: Param) => param.paramName === ParameterItem.MODBUSPROTOCOL)
    );
    if (!modbusType) {
      return;
    }

    const param = modbusType.params.find((p: Param) => p.paramName === ParameterItem.MODBUSPROTOCOL);
    if (!param || !Array.isArray(param.value)) {
      return;
    }

    const options = param.value as SelectOption[];
    const targetIndex = options.findIndex((option: SelectOption) => option.value === modeValue);
    if (targetIndex >= 0) {
      param.select = targetIndex;
    }
  }

  /**
   * 处理 Modbus 协议下拉选择变更：持久化并立即同步到 ModbusServer。
   */
  private handleModbusProtocolSelectChange(param: Param, selectedValue?: string): void {
    if (param.paramName !== ParameterItem.MODBUSPROTOCOL || !selectedValue) {
      return;
    }

    const tableName = this.modbusProtocolModeToTableName(selectedValue);
    this.persistModbusProtocolTable(tableName);
    this.applyModbusProtocolTableToServer(tableName);
  }

  /**
   * 将协议表名称持久化，供应用重启后恢复。
   */
  private persistModbusProtocolTable(tableName: string): void {
    const context = this.getHostContext();
    if (!context) {
      return;
    }

    void UserSettingsService.saveSettingValues(context, [
      { key: this.KEY_MODBUS_PROTOCOL_TABLE, value: tableName }
    ]);
  }

  /**
   * 将协议表名称同步到全局 ModbusServer。
   */
  private applyModbusProtocolTableToServer(tableName: string): void {
    const server = getGlobalModbusServer();
    if (server) {
      server.setProtocolTable(tableName);
    }
  }

  /**
   * 获取当前系统参数配置中已选中的 Modbus 协议显示值。
   */
  private getCurrentModbusProtocolModeFromConfig(): string {
    const modbusType = this.config.type.find((type: Type) =>
    type.params.some((param: Param) => param.paramName === ParameterItem.MODBUSPROTOCOL)
    );
    if (!modbusType) {
      return 'LS4.0';
    }

    const param = modbusType.params.find((p: Param) => p.paramName === ParameterItem.MODBUSPROTOCOL);
    if (!param || !Array.isArray(param.value)) {
      return 'LS4.0';
    }

    const options = param.value as SelectOption[];
    const selectedIndex = param.select ?? 0;
    const selectedOption = options[selectedIndex];
    return (selectedOption?.value as string) ?? 'LS4.0';
  }

  /**
   * 将 Modbus 协议设置为指定显示值：更新 UI、持久化并立即同步到 ModbusServer。
   */
  private setModbusProtocolMode(modeValue: string): void {
    const tableName = this.modbusProtocolModeToTableName(modeValue);
    this.applyModbusProtocolModeToConfig(modeValue);
    this.persistModbusProtocolTable(tableName);
    this.applyModbusProtocolTableToServer(tableName);
  }

  /**
   * 保存当前配置到持久化存储
   */
  private saveConfigToStorage(): void {
    try {
      let options: preferences.Options = { name: 'myStore' };
      let dataPreferences = preferences.getPreferencesSync(this.getUIContext().getHostContext(), options);

      let configKey: string = '';
      if (this.selectedSettingTab === this.settingTabs[0]) {
        configKey = 'config0';
      } else if (this.selectedSettingTab === this.settingTabs[1]) {
        configKey = 'config1';
      } else if (this.selectedSettingTab === this.settingTabs[2]) {
        configKey = 'config2';
      } else if (this.selectedSettingTab === this.settingTabs[3]) {
        configKey = 'config3';
      }

      if (configKey) {
        dataPreferences.putSync(configKey, JSON.stringify(this.config));
        console.info(`TLQQ, 写入config: ${configKey} = ${JSON.stringify(this.config)}`);
      }
    } catch (err) {
      console.error(`TLQQ, 保存配置失败: ${JSON.stringify(err)}`);
    }
  }

  /**
   * 从存储加载配置
   */
  private loadConfigFromStorage(configKey: string): SetConfig | null {
    try {
      let options: preferences.Options = { name: 'myStore' };
      let dataPreferences = preferences.getPreferencesSync(this.getUIContext().getHostContext(), options);
      const savedConfig = dataPreferences.getSync(configKey, '') as string;
      if (savedConfig) {
        return JSON.parse(savedConfig) as SetConfig;
      }
    } catch (err) {
      console.error(`TLQQ, 加载配置失败: ${JSON.stringify(err)}`);
    }
    return null;
  }

  /**
   * 恢复默认配置
   */
  private resetToDefault(): void {
    try {
      // 获取当前标签页的初始配置
      const initialConfig = this.initialConfigs.get(this.selectedSettingTab);
      if (!initialConfig) {
        console.error(`TLQQ, 未找到标签页 ${this.selectedSettingTab} 的初始配置`);
        this.configActionMessage = `${this.selectedSettingTab}恢复默认失败`;
        return;
      }

      // 深拷贝初始配置并赋值，这会触发 @State 更新
      this.config = this.deepCopyConfig(initialConfig);

      // 保存恢复后的配置到存储
      this.saveConfigToStorage();

      // 如果是系统参数标签页，同步 Modbus 协议
      if (this.selectedSettingTab === this.settingTabs[3]) {
        this.setModbusProtocolMode(this.getCurrentModbusProtocolModeFromConfig());
      }

      this.configActionMessage = `${this.selectedSettingTab}已恢复默认`;

      // 触发版本号更新，用于其他可能的刷新逻辑
      this.appliedConfigVersion++;

      console.info(`TLQQ, 恢复默认配置成功: ${this.selectedSettingTab}`);
    } catch (err) {
      console.error(`TLQQ, 恢复默认配置失败: ${JSON.stringify(err)}`);
      this.configActionMessage = `${this.selectedSettingTab}恢复默认失败`;
    } finally {
      this.timer = setTimeout(() => {
        this.configActionMessage = '';
      }, 3000)
    }
  }

  /**
   * 应用配置
   */
  private applyConfig(): void {
    try {
      // 保存当前配置到存储
      this.saveConfigToStorage();

      // 如果是系统参数标签页，同步 Modbus 协议
      if (this.selectedSettingTab === this.settingTabs[3]) {
        this.setModbusProtocolMode(this.getCurrentModbusProtocolModeFromConfig());
      }

      this.configActionMessage = `${this.selectedSettingTab}应用成功`;
      this.appliedConfigVersion++;

      console.info(`TLQQ, 应用配置成功: ${this.selectedSettingTab}`);
    } catch (err) {
      console.error(`TLQQ, 应用配置失败: ${JSON.stringify(err)}`);
      this.configActionMessage = `${this.selectedSettingTab}应用失败`;
    } finally {
      this.timer = setTimeout(() => {
        this.configActionMessage = '';
      }, 3000)
    }
  }

  // 最上方类值定义
  @Builder
  private headerCell(label: string, weight: number) {
    Text(label)
      .height('100%')
      .fontSize(UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor))
      .fontWeight(FontWeight.Bold)
      .fontColor('#222222')
      .textAlign(TextAlign.Center)
      .layoutWeight(weight)
  }

  // 类别值定义
  @Builder
  private categoryCell(label: string) {
    Text(label)
      .height('100%')
      .fontSize(UiUtil.vh(1.8, 11, 15, this.viewportHeight, this.scaleFactor))
      .fontWeight(FontWeight.Bold)
      .fontColor('#222222')
      .textAlign(TextAlign.Center)
      .maxLines(2)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .layoutWeight(0.95)
      .backgroundColor(label === '' ? '#FFFFFF' : '#F8FBFB')
  }

  // 参数项值定义
  @Builder
  private configTextCell(label: string, weight: number) {
    Text(label)
      .height('100%')
      .fontSize(UiUtil.vh(1.75, 11, 15, this.viewportHeight, this.scaleFactor))
      .fontColor('#222222')
      .textAlign(TextAlign.Center)
      .maxLines(2)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .layoutWeight(weight)
  }

  // unit值定义
  @Builder
  private configUnitCell(label: string) {
    Text(label)
      .height('100%')
      .fontSize(UiUtil.vh(1.65, 10, 14, this.viewportHeight, this.scaleFactor))
      .fontColor('#333333')
      .textAlign(TextAlign.Center)
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .layoutWeight(0.65)
  }

  // value只读值定义
  @Builder
  private configReadonlyCell(row: string) {
    Row() {
      Text(row)
        .height(UiUtil.vh(3.6, 28, 38, this.viewportHeight, this.scaleFactor))
        .width('92%')
        .fontSize(UiUtil.vh(1.75, 11, 15, this.viewportHeight, this.scaleFactor))
        .fontColor('#555555')
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .backgroundColor('#F7F9FA')
        .border({ width: UiUtil.vh(0.1, 1, 1, this.viewportHeight, this.scaleFactor), color: '#E4E7E8' })
        .borderRadius(UiUtil.vh(0.35, 2, 4, this.viewportHeight, this.scaleFactor))
    }
    .height('100%')
    .layoutWeight(1.25)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  private settingConfigPanel() {
    Column() {
      Column() {
        Row() {
          ForEach(this.columns, (col: string, index: number) => {
            this.headerCell(col, 1);
          })
        }
        .width('100%')
        .height(44)
        .backgroundColor('#F5F5F5')
        .border({ width: { bottom: 1 }, color: '#E0E0E0' })

        // 使用 config 的 type 数组作为 ForEach 的数据源
        // 当 config 变化时，ForEach 会自动重新渲染
        List() {
          ForEach(this.config.type, (type: Type, typeIndex: number) => {
            ListItem() {
              Column() {
                ForEach(type.params, (param: Param, paramIndex: number) => {
                  Row() {
                    Column() {
                      if (paramIndex === 0) {
                        this.categoryCell(type.name);
                      }
                    }
                    .layoutWeight(1)

                    Column() {
                      this.configTextCell(param.paramName, 1);
                    }
                    .layoutWeight(1)

                    Column() {
                      if (Array.isArray(param.value)) {
                        Row() {
                          Select(param.value as SelectOption[])
                            .value(param.value[param.select ?? 0].value)
                            .height(UiUtil.vh(3.8, 28, 40, this.viewportHeight, this.scaleFactor))
                            .width('92%')
                            .onSelect((index: number, selectedValue?: string) => {
                              param.select = index;
                              this.handleModbusProtocolSelectChange(param, selectedValue);
                              // 选择后保存配置
                              this.saveConfigToStorage();
                            })
                        }
                        .height('100%')
                        .layoutWeight(1.25)
                        .justifyContent(FlexAlign.Center)
                        .alignItems(VerticalAlign.Center)

                      } else if (typeof param.value === 'number') {
                        Row() {
                          TextInput({ text: String(param.value) })
                            .height(UiUtil.vh(3.6, 28, 38, this.viewportHeight, this.scaleFactor))
                            .width('92%')
                            .fontSize(UiUtil.vh(1.75, 11, 15, this.viewportHeight, this.scaleFactor))
                            .textAlign(TextAlign.Center)
                            .backgroundColor('#FFFFFF')
                            .border(
                              { width: UiUtil.vh(0.1, 1, 1, this.viewportHeight, this.scaleFactor), color: '#E2E2E2' })
                            .borderRadius(UiUtil.vh(0.35, 2, 4, this.viewportHeight, this.scaleFactor))
                            .onChange((value: string) => {
                              const n: number = Number(value);
                              if (!Number.isNaN(n)) {
                                param.value = n;
                                console.info(`TLQQ, number: ${param.value}, n: ${n}`);
                              }
                            })
                            .onBlur(() => {
                              // 输入完成后保存配置
                              this.saveConfigToStorage();
                            })
                        }
                        .height('100%')
                        .layoutWeight(1.25)
                        .justifyContent(FlexAlign.Center)
                        .alignItems(VerticalAlign.Center)
                      } else {
                        this.configReadonlyCell(param.value as string);
                      }

                    }
                    .layoutWeight(1)

                    Column() {
                      if (param.unit && param.unit !== '') {
                        this.configUnitCell(param.unit);
                      }
                    }
                    .layoutWeight(1)
                  }
                  .width('100%')
                  .height(50)
                  .border({ width: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor), color: '#E5E5E5' })
                })
              }
            }
          }, (type: Type, index: number) => {
            // 生成稳定的 key，使用 type 名称和索引
            return `${type.name}_${index}`;
          })
        }
        .width('100%')
        .layoutWeight(1)
      }
      .layoutWeight(1)
      .width('100%')
      .clip(true)
      .border({ width: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor), color: '#CCCCCC' })

      Row() {
        DataActionButton({
          label: '恢复默认',
          buttonWidth: UiUtil.vw(10.4, 86, 118, this.viewportWidth, this.scaleFactor),
          buttonHeight: UiUtil.vh(4.4, 34, 48, this.viewportHeight, this.scaleFactor),
          fontSizeValue: UiUtil.vh(1.9, 12, 16, this.viewportHeight, this.scaleFactor),
          borderRadiusValue: UiUtil.vh(0.8, 5, 10, this.viewportHeight, this.scaleFactor),
          onAction: () => {
            this.resetToDefault();
          }
        })

        Text(this.configActionMessage)
          .fontSize(UiUtil.vh(1.55, 10, 13, this.viewportHeight, this.scaleFactor))
          .fontColor(this.configActionMessage.includes('失败') ? '#D93025' : '#2E7D32')
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
          .maxLines(2)

        DataActionButton({
          label: '应用',
          buttonWidth: UiUtil.vw(10.4, 86, 118, this.viewportWidth, this.scaleFactor),
          buttonHeight: UiUtil.vh(4.4, 34, 48, this.viewportHeight, this.scaleFactor),
          fontSizeValue: UiUtil.vh(1.9, 12, 16, this.viewportHeight, this.scaleFactor),
          borderRadiusValue: UiUtil.vh(0.8, 5, 10, this.viewportHeight, this.scaleFactor),
          onAction: () => {
            this.applyConfig();
          }
        })
      }
      .width('100%')
      .height(UiUtil.vh(6.0, 46, 64, this.viewportHeight, this.scaleFactor))
      .margin({ top: UiUtil.vh(1.0, 6, 10, this.viewportHeight, this.scaleFactor) })
      .alignItems(VerticalAlign.Center)
    }
    .layoutWeight(1)
    .height('100%')
    .padding({
      left: UiUtil.vw(0.8, 6, 10, this.viewportWidth, this.scaleFactor),
      right: UiUtil.vw(0.8, 6, 10, this.viewportWidth, this.scaleFactor),
      top: UiUtil.vh(0.8, 6, 10, this.viewportHeight, this.scaleFactor),
      bottom: UiUtil.vh(0.8, 6, 10, this.viewportHeight, this.scaleFactor)
    })
    .backgroundColor('#FFFFFF')
  }

  build() {
    Row() {
      GradientSideTabBar({
        tabs: this.settingTabs,
        selectedTab: this.selectedSettingTab,
        viewportWidth: this.viewportWidth,
        viewportHeight: this.viewportHeight,
        scaleFactor: this.scaleFactor,
        onTabChange: (tab: string) => {
          this.selectedSettingTab = tab;
          // 切换标签页时加载对应的配置
          let configKey: string = '';
          let defaultConfig: SetConfig = MeasurementScheduleConfig;

          if (this.selectedSettingTab === this.settingTabs[0]) {
            configKey = 'config0';
            defaultConfig = MeasurementScheduleConfig;
          } else if (this.selectedSettingTab === this.settingTabs[1]) {
            configKey = 'config1';
            defaultConfig = MeasurementParameterConfig;
          } else if (this.selectedSettingTab === this.settingTabs[2]) {
            configKey = 'config2';
            defaultConfig = ExternalInterfaceConfig;
          } else if (this.selectedSettingTab === this.settingTabs[3]) {
            configKey = 'config3';
            defaultConfig = SystemParametersConfig;
          }

          // 尝试从存储加载配置
          const savedConfig = this.loadConfigFromStorage(configKey);
          if (savedConfig) {
            this.config = savedConfig;
          } else {
            // 使用深拷贝的初始配置
            this.config = this.deepCopyConfig(defaultConfig);
          }

          // 如果是系统参数标签页，恢复 Modbus 协议选择
          if (this.selectedSettingTab === this.settingTabs[3]) {
            void this.restoreModbusProtocolSelection();
          }

          // 清除消息
          this.configActionMessage = '';
        }
      })

      this.settingConfigPanel();
    }
    .layoutWeight(1)
    .width('100%')
    .height('100%')
    .alignItems(VerticalAlign.Top)
    .backgroundColor('#F7F7F7')
  }
}