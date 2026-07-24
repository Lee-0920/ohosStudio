import { common } from '@kit.AbilityKit';
import { UiUtil } from 'base';
import { PermissionManager, PasswordChangeResult } from 'permission';
import { DataActionButton } from '../components/DataActionButton';
import { WqUserInfo } from '../models/monitorTypes';

@Component
export struct UserPage {
  @Prop userInfo: WqUserInfo = {
    username: '',
    role: '',
    department: '',
    lastLoginTime: '',
    lastLoginIp: '',
    accountStatus: ''
  };
  @Prop viewportWidth: number = 1024;
  @Prop viewportHeight: number = 768;
  @Prop scaleFactor: number = 1.92;
  @Link clickLogin: boolean;
  @Prop isLoggedIn: boolean = true;
  onLogout: () => void = () => {
  };
  @State private showPasswordDialog: boolean = false;
  @State private oldPassword: string = '';
  @State private newPassword: string = '';
  @State private confirmPassword: string = '';
  @State private passwordMessage: string = '';
  @State private accountMessage: string = '';
  @State private isChangingPassword: boolean = false;

  private permissionMgr: PermissionManager = PermissionManager.getInstance();

  private getHostContext(): common.Context | null {
    const context = this.getUIContext().getHostContext();
    if (!context) {
      return null;
    }
    return context as common.Context;
  }

  private openPasswordDialog(): void {
    this.oldPassword = '';
    this.newPassword = '';
    this.confirmPassword = '';
    this.passwordMessage = '';
    this.showPasswordDialog = true;
  }

  private closePasswordDialog(): void {
    if (this.isChangingPassword) {
      return;
    }
    this.showPasswordDialog = false;
    this.passwordMessage = '';
  }

  private async changePassword(): Promise<void> {
    if (this.isChangingPassword) {
      return;
    }
    const context = this.getHostContext();
    if (!context) {
      this.passwordMessage = '无法获取应用上下文';
      return;
    }

    this.isChangingPassword = true;
    try {
      const result: PasswordChangeResult = await this.permissionMgr.changePassword(
        context,
        this.oldPassword,
        this.newPassword,
        this.confirmPassword
      );
      if (!result.success) {
        this.passwordMessage = result.message;
        return;
      }
      this.accountMessage = result.message;
      this.showPasswordDialog = false;
      this.oldPassword = '';
      this.newPassword = '';
      this.confirmPassword = '';
      this.passwordMessage = '';
    } finally {
      this.isChangingPassword = false;
    }
  }

  @Builder
  private detailRow(label: string, value: string, highlight: boolean = false) {
    Row() {
      Text(label)
        .fontSize(UiUtil.vh(1.5, 10, 16, this.viewportHeight, this.scaleFactor))
        .fontColor('#666666')
        .width(UiUtil.vw(10, 72, 110, this.viewportWidth, this.scaleFactor))
      Text(value)
        .fontSize(UiUtil.vh(1.5, 10, 16, this.viewportHeight, this.scaleFactor))
        .fontColor(highlight ? '#00A9B8' : '#333333')
        .fontWeight(highlight ? FontWeight.Medium : FontWeight.Normal)
        .layoutWeight(1)
    }
    .width('100%')
    .margin({ bottom: UiUtil.vh(1.0, 6, 12, this.viewportHeight, this.scaleFactor) })
  }

  @Builder
  private passwordDialog() {
    Stack({ alignContent: Alignment.Center }) {
      Column() {
        Row() {
          Text('修改密码')
            .fontSize(UiUtil.vh(2.2, 16, 24, this.viewportHeight, this.scaleFactor))
            .fontWeight(FontWeight.Bold)
            .fontColor('#1F2937')
          Blank()
          Text('×')
            .width(UiUtil.vh(3.6, 28, 36, this.viewportHeight, this.scaleFactor))
            .height(UiUtil.vh(3.6, 28, 36, this.viewportHeight, this.scaleFactor))
            .fontSize(UiUtil.vh(2.6, 18, 26, this.viewportHeight, this.scaleFactor))
            .fontColor('#334155')
            .textAlign(TextAlign.Center)
            .backgroundColor('#EEF2F7')
            .borderRadius(UiUtil.vh(0.6, 4, 8, this.viewportHeight, this.scaleFactor))
            .opacity(this.isChangingPassword ? 0.45 : 1)
            .onClick(() => {
              this.closePasswordDialog();
            })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .margin({ bottom: UiUtil.vh(1.4, 10, 16, this.viewportHeight, this.scaleFactor) })

        TextInput({ text: this.oldPassword, placeholder: '请输入原密码' })
          .type(InputType.Password)
          .height(UiUtil.vh(5.0, 38, 52, this.viewportHeight, this.scaleFactor))
          .width('100%')
          .fontSize(UiUtil.vh(1.7, 12, 17, this.viewportHeight, this.scaleFactor))
          .backgroundColor('#F8FAFC')
          .border({ width: 1, color: '#D7DEE8' })
          .borderRadius(UiUtil.vh(0.7, 5, 8, this.viewportHeight, this.scaleFactor))
          .onChange((value: string) => {
            this.oldPassword = value;
          })

        TextInput({ text: this.newPassword, placeholder: '请输入新密码（6 至 20 位）' })
          .type(InputType.Password)
          .height(UiUtil.vh(5.0, 38, 52, this.viewportHeight, this.scaleFactor))
          .width('100%')
          .fontSize(UiUtil.vh(1.7, 12, 17, this.viewportHeight, this.scaleFactor))
          .backgroundColor('#F8FAFC')
          .border({ width: 1, color: '#D7DEE8' })
          .borderRadius(UiUtil.vh(0.7, 5, 8, this.viewportHeight, this.scaleFactor))
          .margin({ top: UiUtil.vh(1.0, 7, 12, this.viewportHeight, this.scaleFactor) })
          .onChange((value: string) => {
            this.newPassword = value;
          })

        TextInput({ text: this.confirmPassword, placeholder: '请再次输入新密码' })
          .type(InputType.Password)
          .height(UiUtil.vh(5.0, 38, 52, this.viewportHeight, this.scaleFactor))
          .width('100%')
          .fontSize(UiUtil.vh(1.7, 12, 17, this.viewportHeight, this.scaleFactor))
          .backgroundColor('#F8FAFC')
          .border({ width: 1, color: '#D7DEE8' })
          .borderRadius(UiUtil.vh(0.7, 5, 8, this.viewportHeight, this.scaleFactor))
          .margin({ top: UiUtil.vh(1.0, 7, 12, this.viewportHeight, this.scaleFactor) })
          .onChange((value: string) => {
            this.confirmPassword = value;
          })

        if (this.passwordMessage.length > 0) {
          Text(this.passwordMessage)
            .width('100%')
            .fontSize(UiUtil.vh(1.5, 11, 15, this.viewportHeight, this.scaleFactor))
            .fontColor('#E53935')
            .textAlign(TextAlign.Center)
            .margin({ top: UiUtil.vh(1.0, 7, 12, this.viewportHeight, this.scaleFactor) })
        }

        DataActionButton({
          label: this.isChangingPassword ? '保存中' : '确认修改',
          buttonWidth: UiUtil.vw(18, 150, 220, this.viewportWidth, this.scaleFactor),
          buttonHeight: UiUtil.vh(5.0, 38, 52, this.viewportHeight, this.scaleFactor),
          fontSizeValue: UiUtil.vh(1.7, 12, 17, this.viewportHeight, this.scaleFactor),
          borderRadiusValue: UiUtil.vh(0.8, 6, 9, this.viewportHeight, this.scaleFactor),
          marginTop: UiUtil.vh(1.5, 10, 16, this.viewportHeight, this.scaleFactor),
          onAction: () => {
            void this.changePassword();
          }
        })
          .opacity(this.isChangingPassword ? 0.6 : 1)
          .enabled(!this.isChangingPassword)
      }
      .width(UiUtil.vw(40, 340, 500, this.viewportWidth, this.scaleFactor))
      .padding({
        left: UiUtil.vw(2.0, 18, 28, this.viewportWidth, this.scaleFactor),
        right: UiUtil.vw(2.0, 18, 28, this.viewportWidth, this.scaleFactor),
        top: UiUtil.vh(1.8, 14, 22, this.viewportHeight, this.scaleFactor),
        bottom: UiUtil.vh(2.2, 16, 26, this.viewportHeight, this.scaleFactor)
      })
      .borderRadius(UiUtil.vh(0.9, 6, 10, this.viewportHeight, this.scaleFactor))
      .backgroundColor('#FFFFFF')
      .border({ width: 1, color: '#D7DEE8' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#99000000')
    .zIndex(20)
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column() {
        Row() {
          Column() {
            Image($r('app.media.user'))
              .width(UiUtil.vh(10, 64, 112, this.viewportHeight, this.scaleFactor))
              .height(UiUtil.vh(10, 64, 112, this.viewportHeight, this.scaleFactor))
              .borderRadius(UiUtil.vh(5, 32, 56, this.viewportHeight, this.scaleFactor))
              .border({ width: UiUtil.vh(0.2, 1.5, 3, this.viewportHeight, this.scaleFactor), color: '#00A9B8' })
            Text(this.userInfo.username)
              .fontSize(UiUtil.vh(2.4, 16, 28, this.viewportHeight, this.scaleFactor))
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
              .margin({ top: UiUtil.vh(1.2, 8, 14, this.viewportHeight, this.scaleFactor) })
          }
          .width(UiUtil.vw(28, 180, 300, this.viewportWidth, this.scaleFactor))
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)

          Column() {
            this.detailRow('角色：', this.userInfo.role, true);
            this.detailRow('所属系统：', this.userInfo.department);
            this.detailRow('本次登录：', this.userInfo.lastLoginTime);
            this.detailRow('登录方式：', this.userInfo.lastLoginIp);
            this.detailRow('账户状态：', this.userInfo.accountStatus, true);
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
          .padding({
            left: UiUtil.vw(2, 12, 24, this.viewportWidth, this.scaleFactor),
            right: UiUtil.vw(2, 12, 24, this.viewportWidth, this.scaleFactor)
          })
        }
        .width('90%')
        .height(UiUtil.vh(25, 170, 280, this.viewportHeight, this.scaleFactor))
        .backgroundColor('#FFFFFF')
        .borderRadius(UiUtil.vh(1.5, 10, 20, this.viewportHeight, this.scaleFactor))
        .border({ width: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor), color: '#E5E5E5' })
        .shadow({
          radius: UiUtil.vh(0.5, 3, 8, this.viewportHeight, this.scaleFactor),
          color: '#15000000',
          offsetX: 0,
          offsetY: UiUtil.vh(0.2, 1, 3, this.viewportHeight, this.scaleFactor)
        })
        .margin({ top: UiUtil.vh(1.5, 10, 20, this.viewportHeight, this.scaleFactor) })
        .alignItems(VerticalAlign.Center)

        Column() {
          Text('当前账户权限')
            .width('100%')
            .fontSize(UiUtil.vh(1.9, 13, 19, this.viewportHeight, this.scaleFactor))
            .fontWeight(FontWeight.Bold)
            .fontColor('#1F2937')
            .margin({ bottom: UiUtil.vh(1.0, 7, 12, this.viewportHeight, this.scaleFactor) })

          ForEach(this.permissionMgr.getPermissionDescriptions(), (item: string) => {
            Row() {
              Text('•')
                .fontSize(UiUtil.vh(1.8, 12, 18, this.viewportHeight, this.scaleFactor))
                .fontColor('#0B9F9A')
                .margin({ right: UiUtil.vw(0.6, 5, 9, this.viewportWidth, this.scaleFactor) })
              Text(item)
                .fontSize(UiUtil.vh(1.55, 11, 16, this.viewportHeight, this.scaleFactor))
                .fontColor('#374151')
            }
            .width('100%')
            .margin({ bottom: UiUtil.vh(0.55, 3, 7, this.viewportHeight, this.scaleFactor) })
          }, (item: string) => item)
        }
        .width('90%')
        .layoutWeight(1)
        .padding({
          left: UiUtil.vw(2.2, 18, 30, this.viewportWidth, this.scaleFactor),
          right: UiUtil.vw(2.2, 18, 30, this.viewportWidth, this.scaleFactor),
          top: UiUtil.vh(1.5, 10, 18, this.viewportHeight, this.scaleFactor),
          bottom: UiUtil.vh(1.0, 7, 12, this.viewportHeight, this.scaleFactor)
        })
        .margin({ top: UiUtil.vh(1.5, 10, 18, this.viewportHeight, this.scaleFactor) })
        .backgroundColor('#FFFFFF')
        .borderRadius(UiUtil.vh(1.0, 7, 12, this.viewportHeight, this.scaleFactor))
        .border({ width: 1, color: '#E5E7EB' })

        if (this.accountMessage.length > 0) {
          Text(this.accountMessage)
            .fontSize(UiUtil.vh(1.5, 11, 15, this.viewportHeight, this.scaleFactor))
            .fontColor('#0B9F9A')
            .margin({ top: UiUtil.vh(0.8, 5, 10, this.viewportHeight, this.scaleFactor) })
        }

        Row() {
          if (this.isLoggedIn) {
            DataActionButton({
              label: '修改密码',
              buttonWidth: UiUtil.vw(18, 120, 180, this.viewportWidth, this.scaleFactor),
              buttonHeight: UiUtil.vh(4.8, 34, 54, this.viewportHeight, this.scaleFactor),
              fontSizeValue: UiUtil.vh(1.7, 12, 18, this.viewportHeight, this.scaleFactor),
              borderRadiusValue: UiUtil.vh(0.8, 5, 10, this.viewportHeight, this.scaleFactor),
              onAction: () => {
                this.openPasswordDialog();
              }
            })

            Button('退出登录')
              .width(UiUtil.vw(18, 120, 180, this.viewportWidth, this.scaleFactor))
              .height(UiUtil.vh(4.8, 34, 54, this.viewportHeight, this.scaleFactor))
              .fontSize(UiUtil.vh(1.7, 12, 18, this.viewportHeight, this.scaleFactor))
              .backgroundColor('#FFFFFF')
              .fontColor('#FF4444')
              .borderRadius(UiUtil.vh(0.8, 5, 10, this.viewportHeight, this.scaleFactor))
              .border({ width: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor), color: '#FF4444' })
              .onClick(() => {
                this.onLogout();
              })
          } else {
            DataActionButton({
              label: '登录',
              buttonWidth: UiUtil.vw(18, 120, 180, this.viewportWidth, this.scaleFactor),
              buttonHeight: UiUtil.vh(4.8, 34, 54, this.viewportHeight, this.scaleFactor),
              fontSizeValue: UiUtil.vh(1.7, 12, 18, this.viewportHeight, this.scaleFactor),
              borderRadiusValue: UiUtil.vh(0.8, 5, 10, this.viewportHeight, this.scaleFactor),
              onAction: () => {
                this.clickLogin = true;
              }
            })
          }
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceEvenly)
        .margin({ top: UiUtil.vh(1.2, 8, 16, this.viewportHeight, this.scaleFactor) })
        .padding({ bottom: UiUtil.vh(1.5, 10, 20, this.viewportHeight, this.scaleFactor) })
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Center)
      .backgroundColor('#F7F7F7')

      if (this.showPasswordDialog) {
        this.passwordDialog();
      }
    }
    .width('100%')
    .height('100%')
  }
}
