import { UiUtil } from 'base';
import { SystemActionButton, SystemRadioMark, SystemValueInput } from './SystemControls';

@Component
export struct NetworkSettingsPanel {
  @Link networkMode: string;
  @Link staticIp: string;
  @Link staticMask: string;
  @Link staticGateway: string;
  @Link staticDns1: string;
  @Link staticDns2: string;
  @Prop viewportWidth: number = 1024;
  @Prop viewportHeight: number = 768;
  @Prop scaleFactor: number = 1.92;
  @Prop dhcpIp: string = '-';
  @Prop dhcpMask: string = '-';
  @Prop dhcpGateway: string = '-';
  @Prop dhcpDns1: string = '-';
  @Prop dhcpDns2: string = '-';
  onSystemAction: () => void = () => {
  };

  @Builder
  private networkInfoText(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(UiUtil.vh(1.65, 11, 15, this.viewportHeight, this.scaleFactor))
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .width(UiUtil.vw(7.4, 58, 82, this.viewportWidth, this.scaleFactor))
      Text(value)
        .fontSize(UiUtil.vh(1.65, 11, 15, this.viewportHeight, this.scaleFactor))
        .fontColor('#333333')
    }
    .width('100%')
    .height(UiUtil.vh(3.0, 22, 30, this.viewportHeight, this.scaleFactor))
    .justifyContent(FlexAlign.Start)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  private valueInput(textValue: string, placeholderValue: string, inputWidth: number,
    onValueChange: (value: string) => void) {
    SystemValueInput({
      textValue: textValue,
      placeholderValue: placeholderValue,
      inputWidth: inputWidth,
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
      Row() {
        SystemRadioMark({
          selected: this.networkMode === 'dhcp',
          outerSize: UiUtil.vh(3.0, 22, 30, this.viewportHeight, this.scaleFactor),
          innerSize: UiUtil.vh(1.45, 10, 15, this.viewportHeight, this.scaleFactor),
          borderWidthValue: UiUtil.vh(0.32, 2, 3, this.viewportHeight, this.scaleFactor)
        });
        Text('DHCP自动分配')
          .fontSize(UiUtil.vh(1.85, 12, 16, this.viewportHeight, this.scaleFactor))
          .fontWeight(FontWeight.Bold)
          .fontColor('#222222')
          .margin({ left: UiUtil.vw(0.8, 6, 10, this.viewportWidth, this.scaleFactor) })
      }
      .width('100%')
      .height(UiUtil.vh(4.0, 30, 42, this.viewportHeight, this.scaleFactor))
      .justifyContent(FlexAlign.Start)
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.networkMode = 'dhcp';
      })

      Row() {
        Column() {
          this.networkInfoText('网络地址：', this.dhcpIp);
          this.networkInfoText('子网掩码：', this.dhcpMask);
          this.networkInfoText('默认网关：', this.dhcpGateway);
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .justifyContent(FlexAlign.Start)

        Column() {
          this.networkInfoText('DNS1：', this.dhcpDns1);
          this.networkInfoText('DNS2：', this.dhcpDns2);
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .justifyContent(FlexAlign.Start)
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
      .margin({
        left: UiUtil.vw(2.8, 20, 32, this.viewportWidth, this.scaleFactor),
        top: UiUtil.vh(0.4, 2, 6, this.viewportHeight, this.scaleFactor),
        bottom: UiUtil.vh(0.8, 4, 10, this.viewportHeight, this.scaleFactor)
      })

      Row() {
        SystemRadioMark({
          selected: this.networkMode === 'static',
          outerSize: UiUtil.vh(3.0, 22, 30, this.viewportHeight, this.scaleFactor),
          innerSize: UiUtil.vh(1.45, 10, 15, this.viewportHeight, this.scaleFactor),
          borderWidthValue: UiUtil.vh(0.32, 2, 3, this.viewportHeight, this.scaleFactor)
        });
        Text('静态指定')
          .fontSize(UiUtil.vh(1.85, 12, 16, this.viewportHeight, this.scaleFactor))
          .fontWeight(FontWeight.Bold)
          .fontColor('#222222')
          .margin({ left: UiUtil.vw(0.8, 6, 10, this.viewportWidth, this.scaleFactor) })
      }
      .width('100%')
      .height(UiUtil.vh(4.0, 30, 42, this.viewportHeight, this.scaleFactor))
      .justifyContent(FlexAlign.Start)
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.networkMode = 'static';
      })

      Row() {
        Column() {
          Row() {
            Text('网络地址')
              .fontSize(UiUtil.vh(1.65, 11, 15, this.viewportHeight, this.scaleFactor))
              .width(UiUtil.vw(7.4, 58, 82, this.viewportWidth, this.scaleFactor))
            this.valueInput(this.staticIp, '', UiUtil.vw(14.0, 110, 150, this.viewportWidth, this.scaleFactor),
              (value: string) => {
                this.staticIp = value;
              });
          }
          .width('100%')
          .height(UiUtil.vh(3.8, 28, 40, this.viewportHeight, this.scaleFactor))
          .justifyContent(FlexAlign.Start)
          .alignItems(VerticalAlign.Center)

          Row() {
            Text('子网掩码')
              .fontSize(UiUtil.vh(1.65, 11, 15, this.viewportHeight, this.scaleFactor))
              .width(UiUtil.vw(7.4, 58, 82, this.viewportWidth, this.scaleFactor))
            this.valueInput(this.staticMask, '', UiUtil.vw(14.0, 110, 150, this.viewportWidth, this.scaleFactor),
              (value: string) => {
                this.staticMask = value;
              });
          }
          .width('100%')
          .height(UiUtil.vh(3.8, 28, 40, this.viewportHeight, this.scaleFactor))
          .justifyContent(FlexAlign.Start)
          .alignItems(VerticalAlign.Center)

          Row() {
            Text('默认网关')
              .fontSize(UiUtil.vh(1.65, 11, 15, this.viewportHeight, this.scaleFactor))
              .width(UiUtil.vw(7.4, 58, 82, this.viewportWidth, this.scaleFactor))
            this.valueInput(this.staticGateway, '', UiUtil.vw(14.0, 110, 150, this.viewportWidth, this.scaleFactor),
              (value: string) => {
                this.staticGateway = value;
              });
          }
          .width('100%')
          .height(UiUtil.vh(3.8, 28, 40, this.viewportHeight, this.scaleFactor))
          .justifyContent(FlexAlign.Start)
          .alignItems(VerticalAlign.Center)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .justifyContent(FlexAlign.Start)

        Column() {
          Row() {
            Text('DNS1')
              .fontSize(UiUtil.vh(1.65, 11, 15, this.viewportHeight, this.scaleFactor))
              .width(UiUtil.vw(5.8, 44, 68, this.viewportWidth, this.scaleFactor))
            this.valueInput(this.staticDns1, '', UiUtil.vw(14.0, 110, 150, this.viewportWidth, this.scaleFactor),
              (value: string) => {
                this.staticDns1 = value;
              });
          }
          .width('100%')
          .height(UiUtil.vh(3.8, 28, 40, this.viewportHeight, this.scaleFactor))
          .justifyContent(FlexAlign.Start)
          .alignItems(VerticalAlign.Center)

          Row() {
            Text('DNS2')
              .fontSize(UiUtil.vh(1.65, 11, 15, this.viewportHeight, this.scaleFactor))
              .width(UiUtil.vw(5.8, 44, 68, this.viewportWidth, this.scaleFactor))
            this.valueInput(this.staticDns2, '', UiUtil.vw(14.0, 110, 150, this.viewportWidth, this.scaleFactor),
              (value: string) => {
                this.staticDns2 = value;
              });
          }
          .width('100%')
          .height(UiUtil.vh(3.8, 28, 40, this.viewportHeight, this.scaleFactor))
          .justifyContent(FlexAlign.Start)
          .alignItems(VerticalAlign.Center)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .justifyContent(FlexAlign.Start)
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
      .margin({ left: UiUtil.vw(2.8, 20, 32, this.viewportWidth, this.scaleFactor) })

      Row() {
        Blank()
        SystemActionButton({
          label: '保存',
          buttonWidth: UiUtil.vw(10.4, 86, 118, this.viewportWidth, this.scaleFactor),
          buttonHeight: UiUtil.vh(4.8, 34, 54, this.viewportHeight, this.scaleFactor),
          fontSizeValue: UiUtil.vh(1.85, 12, 16, this.viewportHeight, this.scaleFactor),
          borderRadiusValue: UiUtil.vh(0.8, 5, 10, this.viewportHeight, this.scaleFactor),
          onAction: () => {
            this.onSystemAction();
          }
        })
      }
      .width('100%')
      .height(UiUtil.vh(5.2, 38, 54, this.viewportHeight, this.scaleFactor))
      .alignItems(VerticalAlign.Center)
      .margin({ top: UiUtil.vh(0.8, 4, 10, this.viewportHeight, this.scaleFactor) })
    }
    .layoutWeight(1)
    .height('100%')
    .padding({
      left: UiUtil.vw(1.4, 10, 18, this.viewportWidth, this.scaleFactor),
      right: UiUtil.vw(1.4, 10, 18, this.viewportWidth, this.scaleFactor),
      top: UiUtil.vh(1.0, 6, 12, this.viewportHeight, this.scaleFactor),
      bottom: UiUtil.vh(0.8, 6, 10, this.viewportHeight, this.scaleFactor)
    })
    .backgroundColor('#FFFFFF')
  }
}
