// lhipstudio/Common/alarm/src/main/ets/components/AlarmListPage.ets

import { AlarmManager } from '../model/AlarmManager';
import { AlarmRecord, AlarmStatus } from '../model/AlarmRecord';
import { AlarmCode, getAlarmDescription } from '../model/AlarmCode';

@Entry
@Component
export struct AlarmListPage {
  @State activeRecords: AlarmRecord[] = [];
  @State clearedRecords: AlarmRecord[] = [];
  @State showCleared: boolean = false;
  @State selectedTab: number = 0; // 0: active, 1: cleared

  private alarmMgr: AlarmManager = AlarmManager.getInstance();

  aboutToAppear(): void {
    this.refreshRecords();
  }

  refreshRecords(): void {
    this.activeRecords = this.alarmMgr.getActiveRecords();
    this.clearedRecords = this.alarmMgr.getClearedRecords();
  }

  @Builder
  buildActiveTab() {
    Column() {
      if (this.activeRecords.length === 0) {
        Text('当前无活跃告警')
          .fontSize(16)
          .fontColor('#999')
          .margin({ top: 40 })
      } else {
        List({ space: 8 }) {
          ForEach(this.activeRecords, (record: AlarmRecord) => {
            ListItem() {
              this.buildAlarmCard(record)
            }
          }, (record: AlarmRecord) => record.id)
        }
        .width('100%')
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildClearedTab() {
    Column() {
      if (this.clearedRecords.length === 0) {
        Text('暂无已消除告警')
          .fontSize(16)
          .fontColor('#999')
          .margin({ top: 40 })
      } else {
        List({ space: 8 }) {
          ForEach(this.clearedRecords, (record: AlarmRecord) => {
            ListItem() {
              this.buildClearedCard(record)
            }
          }, (record: AlarmRecord) => record.id)
        }
        .width('100%')
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildAlarmCard(record: AlarmRecord) {
    Column() {
      Row() {
        Text(`[${record.alarmCode}] ${record.description}`)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')
          .layoutWeight(1)

        Text(record.status)
          .fontSize(12)
          .fontColor(record.status === AlarmStatus.ACTIVE ? '#FF4444' : '#FF9800')
          .padding({ left: 8, right: 8, top: 2, bottom: 2 })
          .borderRadius(4)
          .backgroundColor(record.status === AlarmStatus.ACTIVE ? '#FFEBEE' : '#FFF3E0')
      }
      .width('100%')
      .margin({ bottom: 8 })

      Row() {
        Text(`触发时间: ${AlarmRecord.formatTimestamp(record.triggeredAt)}`)
          .fontSize(12)
          .fontColor('#666')
          .layoutWeight(1)

        Text(`持续: ${record.getDurationFormatted()}`)
          .fontSize(12)
          .fontColor('#666')
      }
      .width('100%')
      .margin({ bottom: 8 })

      if (record.extraInfo) {
        Text(`详情: ${record.extraInfo}`)
          .fontSize(12)
          .fontColor('#888')
          .margin({ bottom: 8 })
      }

      Row() {
        Button('确认')
          .fontSize(12)
          .height(30)
          .backgroundColor('#FF9800')
          .onClick(() => {
            this.alarmMgr.acknowledgeAlarm(record.id, 'current_user');
            this.refreshRecords();
          })
          .margin({ right: 8 })

        Button('消除')
          .fontSize(12)
          .height(30)
          .backgroundColor('#4CAF50')
          .onClick(() => {
            this.alarmMgr.clearAlarm(record.id, 'current_user');
            this.refreshRecords();
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.End)
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .border({ width: 1, color: '#E0E0E0' })
  }

  @Builder
  buildClearedCard(record: AlarmRecord) {
    Column() {
      Row() {
        Text(`[${record.alarmCode}] ${record.description}`)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#999')
          .layoutWeight(1)

        Text('已消除')
          .fontSize(12)
          .fontColor('#4CAF50')
          .padding({ left: 8, right: 8, top: 2, bottom: 2 })
          .borderRadius(4)
          .backgroundColor('#E8F5E9')
      }
      .width('100%')
      .margin({ bottom: 8 })

      Row() {
        Text(`触发: ${AlarmRecord.formatTimestamp(record.triggeredAt)}`)
          .fontSize(12)
          .fontColor('#999')
          .layoutWeight(1)

        Text(`消除: ${AlarmRecord.formatTimestamp(record.clearedAt)}`)
          .fontSize(12)
          .fontColor('#999')
      }
      .width('100%')

      if (record.clearedBy) {
        Text(`消除人: ${record.clearedBy}`)
          .fontSize(12)
          .fontColor('#999')
          .margin({ top: 4 })
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FAFAFA')
    .borderRadius(8)
    .border({ width: 1, color: '#E0E0E0' })
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('告警管理')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')
          .layoutWeight(1)

        Text(`活跃: ${this.activeRecords.length}`)
          .fontSize(14)
          .fontColor('#FF4444')
      }
      .width('100%')
      .padding(15)
      .backgroundColor('#F5F5F5')

      // Tab切换
      Row() {
        Button('活跃告警')
          .fontSize(14)
          .height(36)
          .backgroundColor(this.selectedTab === 0 ? '#2196F3' : '#E0E0E0')
          .fontColor(this.selectedTab === 0 ? '#FFFFFF' : '#666')
          .layoutWeight(1)
          .onClick(() => {
            this.selectedTab = 0;
            this.refreshRecords();
          })

        Button('已消除')
          .fontSize(14)
          .height(36)
          .backgroundColor(this.selectedTab === 1 ? '#2196F3' : '#E0E0E0')
          .fontColor(this.selectedTab === 1 ? '#FFFFFF' : '#666')
          .layoutWeight(1)
          .margin({ left: 8 })
          .onClick(() => {
            this.selectedTab = 1;
            this.refreshRecords();
          })
      }
      .width('100%')
      .padding({ left: 15, right: 15, top: 10, bottom: 10 })

      // 内容区域
      if (this.selectedTab === 0) {
        this.buildActiveTab()
      } else {
        this.buildClearedTab()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
