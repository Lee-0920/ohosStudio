import { SetConfig, Type, Param } from '../../Config/BaseInterface';
import { MeasurementScheduleConfig } from '../../Config/ScheduleMeasurementConfig';
import { preferences } from '@kit.ArkData';


@Component
export struct SettingsPage {
  @State config: SetConfig = MeasurementScheduleConfig;
  private columns: string[] = ['类别', '参数项', '值', '单位'];

  aboutToAppear(): void {
  }

  build() {
    Column() {
      Row() {
        ForEach(this.columns, (col: string, index: number) => {
          Text(col)
            .fontSize(16)
            .fontColor('#333333')
            .fontWeight(FontWeight.Medium)
            .textAlign(TextAlign.Center)
            .layoutWeight(1)
        })
      }
      .width('100%')
      .height(44)
      .backgroundColor('#F5F5F5')
      .border({ width: { bottom: 1 }, color: '#E0E0E0' })
      .borderWidth(1)
      .borderColor('red')

      List() {
        ForEach(this.config.type, (type: Type, colIdx: number) => {
          ListItem() {
            Column() {
              ForEach(type.params, (param: Param, rowIdx: number) => {
                Row() {
                  Column() {
                    if (rowIdx === 0) {
                      Text(type.name)
                    } else {
                      // Text()
                    }
                  }
                  .layoutWeight(1)

                  Column() {
                    Text(param.paramName)
                  }
                  .layoutWeight(1)
                  Column() {
                    if (Array.isArray(param.value)) {
                      Select(param.value)
                        .selected(param.select)
                        .value(param.value[param.select ?? 0].value)
                        .onSelect((index, value) => {
                          param.select = index;
                          console.info(`TLQQ, 选中值: ${value}, index: ${index}`);
                        })
                    } else if (typeof param.value === 'number') {
                      TextInput({ text: String(param.value) })
                      // Text(String(param.value))
                    } else {
                      Text(param.value)
                    }

                  }
                  .layoutWeight(1)
                  Column() {
                    if (!param.unit || param.unit === '') {
                      // Text()
                    } else {
                      Text(param.unit)
                    }
                  }
                  .layoutWeight(1)
                }
                .width('100%')
                .height(50)
                .borderWidth(1)
                .borderColor('red')
              })
            }
          }
        })
      }
      .width('100%')
      .layoutWeight(1)
      .borderWidth(1)
      .borderColor('red')

      Row() {
        Button('存入首选项')
          .onClick(() => {
            let options: preferences.Options = { name: 'myStore' };
            let dataPreferences = preferences.getPreferencesSync(this.getUIContext().getHostContext(), options);
            if (dataPreferences.hasSync('config')) {
              console.info(`TLQQ, config已存在`);
              dataPreferences.putSync('config', JSON.stringify(this.config));
            } else {
              console.info(`TLQQ, config不存在`);
              dataPreferences.putSync('config', JSON.stringify(this.config));
            }
            console.info(`TLQQ, 写入config: ${JSON.stringify(this.config)}`);
          })
        Button('读取当前配置')
          .onClick(() => {
            let options: preferences.Options = { name: 'myStore' };
            let dataPreferences = preferences.getPreferencesSync(this.getUIContext().getHostContext(), options);
            if (dataPreferences.hasSync('config')) {
              console.info(`TLQQ, config已存在`);
              let config = dataPreferences.getSync('config', JSON.stringify(this.config)) as string;
              console.info(`TLQQ, 读取config: ${config}`);
              const newConfig: SetConfig = JSON.parse(config);
              this.config = newConfig;
            }
          })
      }
    }
    .width('100%')
    .height('100%')
  }
}