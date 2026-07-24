import { UiUtil } from 'base';
import { SystemActionButton, SystemValueInput } from './SystemControls';

@Component
export struct SystemTimePanel {
  @Link systemDate: string;
  @Link systemTime: string;
  @Prop currentSystemTimeText: string = '-';
  @Prop instrumentTimeText: string = '-';
  @Prop actionMessage: string = '';
  @Prop isActionRunning: boolean = false;
  @Prop viewportWidth: number = 1024;
  @Prop viewportHeight: number = 768;
  @Prop scaleFactor: number = 1.92;
  onSyncInstrumentTime: () => void = () => {
  };
  onSetUnifiedTime: () => void = () => {
  };

  private messageColor(): string {
    if (this.actionMessage.indexOf('失败') >= 0 || this.actionMessage.indexOf('无效') >= 0 ||
      this.actionMessage.indexOf('未连接') >= 0 || this.actionMessage.indexOf('范围') >= 0) {
      return '#E53935';
    }
    return '#0B9F9A';
  }

  @Builder
  private timeDisplayRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(UiUtil.vh(1.85, 12, 16, this.viewportHeight, this.scaleFactor))
        .fontWeight(FontWeight.Bold)
        .width(UiUtil.vw(11.0, 90, 132, this.viewportWidth, this.scaleFactor))
      Text(value)
        .fontSize(UiUtil.vh(1.85, 12, 16, this.viewportHeight, this.scaleFactor))
        .fontColor(value.indexOf('失败') >= 0 || value.indexOf('未连接') >= 0 ? '#E53935' : '#222222')
        .textAlign(TextAlign.Center)
        .width(UiUtil.vw(24.0, 190, 280, this.viewportWidth, this.scaleFactor))
    }
    .height(UiUtil.vh(5.0, 38, 54, this.viewportHeight, this.scaleFactor))
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  private valueInput(textValue: string, placeholderValue: string, onValueChange: (value: string) => void) {
    SystemValueInput({
      textValue: textValue,
      placeholderValue: placeholderValue,
      inputWidth: UiUtil.vw(20.0, 150, 220, this.viewportWidth, this.scaleFactor),
      inputHeight: UiUtil.vh(3.6, 28, 38, this.viewportHeight, this.scaleFactor),
      fontSizeValue: UiUtil.vh(1.75, 11, 15, this.viewportHeight, this.scaleFactor),
      borderRadiusValue: UiUtil.vh(0.45, 3, 5, this.viewportHeight, this.scaleFactor),
      onValueChange: (value: string) => {
        onValueChange(value);
      }
    })
  }

  build() {
    Column() {
      this.timeDisplayRow('系统当前时间', this.currentSystemTimeText);
      this.timeDisplayRow('仪器当前时间', this.instrumentTimeText);

      Text('系统时间作为校时基准，可直接同步到仪器；手动设置会同时修改系统和仪器时间。')
        .width(UiUtil.vw(48.0, 380, 560, this.viewportWidth, this.scaleFactor))
        .fontSize(UiUtil.vh(1.45, 10, 14, this.viewportHeight, this.scaleFactor))
        .fontColor('#666666')
        .margin({
          top: UiUtil.vh(0.5, 4, 8, this.viewportHeight, this.scaleFactor),
          bottom: UiUtil.vh(1.4, 10, 18, this.viewportHeight, this.scaleFactor)
        })

      Divider()
        .width(UiUtil.vw(48.0, 380, 560, this.viewportWidth, this.scaleFactor))
        .color('#DADADA')
        .margin({ bottom: UiUtil.vh(1.2, 8, 16, this.viewportHeight, this.scaleFactor) })

      Text('设置时间')
        .width(UiUtil.vw(48.0, 380, 560, this.viewportWidth, this.scaleFactor))
        .fontSize(UiUtil.vh(1.9, 12, 17, this.viewportHeight, this.scaleFactor))
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')

      Row() {
        Text('日期')
          .fontSize(UiUtil.vh(1.85, 12, 16, this.viewportHeight, this.scaleFactor))
          .fontWeight(FontWeight.Bold)
          .width(UiUtil.vw(6.0, 48, 70, this.viewportWidth, this.scaleFactor))
        this.valueInput(this.systemDate, '示例 2023-01-01', (value: string) => {
          this.systemDate = value;
        });
      }
      .height(UiUtil.vh(5.4, 42, 58, this.viewportHeight, this.scaleFactor))
      .alignItems(VerticalAlign.Center)

      Row() {
        Text('时间')
          .fontSize(UiUtil.vh(1.85, 12, 16, this.viewportHeight, this.scaleFactor))
          .fontWeight(FontWeight.Bold)
          .width(UiUtil.vw(6.0, 48, 70, this.viewportWidth, this.scaleFactor))
        this.valueInput(this.systemTime, '示例 08:00:00', (value: string) => {
          this.systemTime = value;
        });
      }
      .height(UiUtil.vh(5.4, 42, 58, this.viewportHeight, this.scaleFactor))
      .alignItems(VerticalAlign.Center)

      Blank()

      Row() {
        Blank()
        SystemActionButton({
          label: this.isActionRunning ? '处理中' : '同步系统时间到仪器',
          buttonWidth: UiUtil.vw(18.0, 150, 210, this.viewportWidth, this.scaleFactor),
          buttonHeight: UiUtil.vh(4.8, 34, 54, this.viewportHeight, this.scaleFactor),
          fontSizeValue: UiUtil.vh(1.85, 12, 16, this.viewportHeight, this.scaleFactor),
          borderRadiusValue: UiUtil.vh(0.8, 5, 10, this.viewportHeight, this.scaleFactor),
          onAction: () => {
            this.onSyncInstrumentTime();
          }
        })
          .opacity(this.isActionRunning ? 0.55 : 1)
          .enabled(!this.isActionRunning)
          .margin({ right: UiUtil.vw(1.2, 8, 16, this.viewportWidth, this.scaleFactor) })

        SystemActionButton({
          label: this.isActionRunning ? '处理中' : '设置时间',
          buttonWidth: UiUtil.vw(14.0, 120, 170, this.viewportWidth, this.scaleFactor),
          buttonHeight: UiUtil.vh(4.8, 34, 54, this.viewportHeight, this.scaleFactor),
          fontSizeValue: UiUtil.vh(1.85, 12, 16, this.viewportHeight, this.scaleFactor),
          borderRadiusValue: UiUtil.vh(0.8, 5, 10, this.viewportHeight, this.scaleFactor),
          onAction: () => {
            this.onSetUnifiedTime();
          }
        })
          .opacity(this.isActionRunning ? 0.55 : 1)
          .enabled(!this.isActionRunning)
      }
      .width('100%')
      .height(UiUtil.vh(6.0, 46, 64, this.viewportHeight, this.scaleFactor))
      .alignItems(VerticalAlign.Center)

      if (this.actionMessage.length > 0) {
        Text(this.actionMessage)
          .width(UiUtil.vw(48.0, 380, 560, this.viewportWidth, this.scaleFactor))
          .fontSize(UiUtil.vh(1.55, 11, 15, this.viewportHeight, this.scaleFactor))
          .fontColor(this.messageColor())
          .textAlign(TextAlign.End)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: UiUtil.vh(0.8, 6, 10, this.viewportHeight, this.scaleFactor) })
      }
    }
    .layoutWeight(1)
    .height('100%')
    .padding({
      left: UiUtil.vw(3.0, 24, 36, this.viewportWidth, this.scaleFactor),
      right: UiUtil.vw(2.2, 18, 28, this.viewportWidth, this.scaleFactor),
      top: UiUtil.vh(4.4, 34, 52, this.viewportHeight, this.scaleFactor),
      bottom: UiUtil.vh(1.0, 8, 12, this.viewportHeight, this.scaleFactor)
    })
    .backgroundColor('#FFFFFF')
  }
}
