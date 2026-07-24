import { UiUtil } from 'base';
import { SystemActionButton } from './SystemControls';
import { getAllLogFilesInfo, LogFileInfo, getLogDir, Logger } from 'logger';
import fs from '@ohos.file.fs';
import picker from '@ohos.file.picker';
import { util } from '@kit.ArkTS';
import { SettingsManager, MeasureStatusManager } from 'dataservice';
import { RoleType, PermissionManager, User } from 'permission';

@Component
export struct SystemSettingsPanel {
  @Prop viewportWidth: number = 1024;
  @Prop viewportHeight: number = 768;
  @Prop scaleFactor: number = 1.92;
  onSystemAction: () => void = () => {
  };

  @State currentUserName: string = '未登录';
  @State currentUserRole: RoleType = RoleType.OPERATOR;
  @State isUserLoaded: boolean = false;

  async aboutToAppear() {
    await this.loadUserState();
  }

  private async loadUserState(): Promise<void> {
    try {
      const user: User | null = PermissionManager.getInstance().getCurrentUser();
      if (user) {
        this.currentUserName = user.userName;
        this.currentUserRole = user.role;
        this.isUserLoaded = true;
      }
    } catch (err) {
      console.error(`Load user state error: ${err}`);
      this.isUserLoaded = true;
    }
  }

  private showResultDialog(message: string): void {
    this.getUIContext().showAlertDialog({
      title: '系统日志导出',
      message: message,
      autoCancel: true,
      alignment: DialogAlignment.Center,
      confirm: {
        value: '确定',
        action: () => {
        }
      }
    });
  }

  private async restoreFactorySettings(): Promise<void> {
    if (!this.isUserLoaded) {
      this.showResultDialog('⚠️ 用户信息未加载完成，请稍后再试');
      return;
    }
    try {
      const settingsManager = SettingsManager.getInstance();
      await settingsManager.restoreFactorySettings(this.currentUserRole);

      const measureStatusManager = MeasureStatusManager.getInstance();
      await measureStatusManager.restoreFactorySettings(this.currentUserRole);

      this.showResultDialog(`✅ 恢复出厂设置成功\n角色: ${this.currentUserRole}`);
    } catch (err) {
      this.showResultDialog(`❌ 恢复出厂设置失败: ${err}`);
    }
  }

  private async exportSystemLog(): Promise<void> {
    try {
      const filesInfo = getAllLogFilesInfo();
      const logFile = filesInfo.find((f: LogFileInfo) => f.fileName === 'log.txt');

      if (!logFile) {
        this.showResultDialog('未找到系统日志文件');
        return;
      }

      const sourcePath = getLogDir() + logFile.fileName;
      if (!fs.accessSync(sourcePath)) {
        this.showResultDialog('日志文件不存在');
        return;
      }

      const content = this.readFileText(sourcePath);
      if (!content) {
        this.showResultDialog('日志文件内容为空');
        return;
      }

      const timestamp = this.getTimestampForFolder();
      const fileName = `SystemLog_${timestamp}.txt`;

      const documentPicker = new picker.DocumentViewPicker();
      const saveOptions = new picker.DocumentSaveOptions();
      saveOptions.newFileNames = [fileName];

      const uri = await documentPicker.save(saveOptions);
      if (!uri) {
        this.showResultDialog('已取消保存');
        return;
      }

      const targetUri = Array.isArray(uri) ? uri[0] : uri;
      Logger.info(`系统日志保存位置：${targetUri}`);
      const file = fs.openSync(targetUri, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY);
      fs.writeSync(file.fd, content);
      fs.closeSync(file.fd);

      this.showResultDialog(`系统日志导出成功，保存位置：${targetUri}`);
    } catch (err) {
      console.error(`导出异常: ${err}`);
      this.showResultDialog('已取消保存');
    }
  }

  private readFileText(path: string): string {
    const file = fs.openSync(path, fs.OpenMode.READ_ONLY);
    const stat = fs.statSync(path);
    const buffer = new ArrayBuffer(stat.size);
    fs.readSync(file.fd, buffer);
    fs.closeSync(file.fd);
    const decoder = util.TextDecoder.create('utf-8');
    return decoder.decodeToString(new Uint8Array(buffer), { stream: false });
  }

  private getTimestampForFolder(): string {
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const day = String(now.getDate()).padStart(2, '0');
    const hours = String(now.getHours()).padStart(2, '0');
    const minutes = String(now.getMinutes()).padStart(2, '0');
    const seconds = String(now.getSeconds()).padStart(2, '0');
    return `${year}${month}${day}_${hours}${minutes}${seconds}`;
  }

  @Builder
  private actionButton(label: string) {
    SystemActionButton({
      label: label,
      buttonWidth: UiUtil.vw(24.0, 180, 260, this.viewportWidth, this.scaleFactor),
      buttonHeight: UiUtil.vh(4.8, 34, 54, this.viewportHeight, this.scaleFactor),
      fontSizeValue: UiUtil.vh(1.85, 12, 16, this.viewportHeight, this.scaleFactor),
      borderRadiusValue: UiUtil.vh(0.8, 5, 10, this.viewportHeight, this.scaleFactor),
      onAction: () => {
        this.onSystemAction();
      }
    })
  }

  build() {
    Column() {
      SystemActionButton({
        label: '一键恢复出厂设置',
        buttonWidth: UiUtil.vw(24.0, 180, 260, this.viewportWidth, this.scaleFactor),
        buttonHeight: UiUtil.vh(4.8, 34, 54, this.viewportHeight, this.scaleFactor),
        fontSizeValue: UiUtil.vh(1.85, 12, 16, this.viewportHeight, this.scaleFactor),
        borderRadiusValue: UiUtil.vh(0.8, 5, 10, this.viewportHeight, this.scaleFactor),
        onAction: () => {
          void this.restoreFactorySettings();
        }
      });
      Blank()
        .height(UiUtil.vh(1.8, 12, 20, this.viewportHeight, this.scaleFactor))
      this.actionButton('触摸屏校准');
      Blank()
        .height(UiUtil.vh(1.8, 12, 20, this.viewportHeight, this.scaleFactor))
      this.actionButton('故障清除');
      Blank()
        .height(UiUtil.vh(1.8, 12, 20, this.viewportHeight, this.scaleFactor))
      SystemActionButton({
        label: '系统日志导出',
        buttonWidth: UiUtil.vw(24.0, 180, 260, this.viewportWidth, this.scaleFactor),
        buttonHeight: UiUtil.vh(4.8, 34, 54, this.viewportHeight, this.scaleFactor),
        fontSizeValue: UiUtil.vh(1.85, 12, 16, this.viewportHeight, this.scaleFactor),
        borderRadiusValue: UiUtil.vh(0.8, 5, 10, this.viewportHeight, this.scaleFactor),
        onAction: () => {
          void this.exportSystemLog();
        }
      });

      Blank()
    }
    .layoutWeight(1)
    .height('100%')
    .padding({
      left: UiUtil.vw(4.2, 32, 52, this.viewportWidth, this.scaleFactor),
      top: UiUtil.vh(2.2, 16, 26, this.viewportHeight, this.scaleFactor)
    })
    .alignItems(HorizontalAlign.Start)
    .backgroundColor('#FFFFFF')
  }
}
