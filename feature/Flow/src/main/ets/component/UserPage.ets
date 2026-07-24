import { SettingsPage } from './settingspages/SettingsPage';

@ComponentV2
export struct UserPage {

  build() {
    Column() {
      SettingsPage()
    }
    .width('100%')
    .height('100%')
  }
}