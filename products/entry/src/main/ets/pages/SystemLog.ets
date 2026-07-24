import { BusinessError } from '@kit.BasicServicesKit';
import { clearLogFile, deleteLogFile, getAllLogFilesInfo, LogFileInfo, getLogDir,Logger } from 'logger';
import fs from '@ohos.file.fs';
import picker from '@ohos.file.picker';
import { util } from '@kit.ArkTS';

@Entry
@Component
struct SystemLog {
  @State logText: string = '';

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

  private async exportSystemLog(): Promise<void> {
    try {
      const filesInfo = getAllLogFilesInfo();
      const logFile = filesInfo.find((f: LogFileInfo) => f.fileName === 'log.txt');

      if (!logFile) {
        this.logText = '未找到系统日志文件';
        return;
      }

      const sourcePath = getLogDir() + logFile.fileName;
      if (!fs.accessSync(sourcePath)) {
        this.logText = '日志文件不存在';
        return;
      }

      const content = this.readFileText(sourcePath);
      if (!content) {
        this.logText = '日志文件内容为空';
        return;
      }

      const timestamp = this.getTimestampForFolder();
      const fileName = `SystemLog_${timestamp}.txt`;

      const documentPicker = new picker.DocumentViewPicker();
      const saveOptions = new picker.DocumentSaveOptions();
      saveOptions.newFileNames = [fileName];

      const uri = await documentPicker.save(saveOptions);
      if (!uri) {
        this.logText = '已取消保存';
        return;
      }

      const targetUri = Array.isArray(uri) ? uri[0] : uri;
      Logger.info(`系统日志保存位置：${targetUri}`);
      const file = fs.openSync(targetUri, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY);
      fs.writeSync(file.fd, content);
      fs.closeSync(file.fd);

      this.logText = `系统日志导出成功，保存位置：${targetUri}`;
    } catch (err) {
      console.error(`导出异常: ${err}`);
      this.logText = `导出失败: ${err}`;
    }
  }

  private readFileText(path: string): string {
    const file = fs.openSync(path, fs.OpenMode.READ_ONLY);
    const stat = fs.statSync(path);
    const buffer = new ArrayBuffer(stat.size);
    fs.readSync(file.fd, buffer);
    fs.closeSync(file.fd);
    const decoder = new util.TextDecoder('utf-8');
    return decoder.decodeWithStream(new Uint8Array(buffer), { stream: false });
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

  private async clearSystemLog(): Promise<void> {
    try {
      // 显示确认对话框
      const confirmed = await this.showConfirmDialog('是否清除系统日志？');
      if (!confirmed) {
        this.logText = '已取消清除操作';
        return;
      }

      const filesInfo = getAllLogFilesInfo();
      const sysLogFiles = filesInfo.filter((f: LogFileInfo) => f.fileName.includes('log.txt'));

      if (sysLogFiles.length === 0) {
        this.logText = '未找到系统日志文件';
        return;
      }

      let allSuccess = true;
      let deletedCount = 0;

      for (const fileInfo of sysLogFiles) {
        // 主日志文件（log.txt）只清空内容，备份文件（log.txt.1等）直接删除
        if (fileInfo.fileName === 'log.txt') {
          const success = clearLogFile(fileInfo.fileName);
          if (!success) {
            allSuccess = false;
          }
        } else {
          const success = deleteLogFile(fileInfo.fileName);
          if (success) {
            deletedCount++;
          } else {
            allSuccess = false;
          }
        }
      }

      if (allSuccess) {
        this.logText = deletedCount > 0
          ? `系统日志已清空（已删除${deletedCount}个历史日志文件）`
          : '系统日志已清空';
      } else {
        this.logText = '清空系统日志失败';
      }
    } catch (err) {
      this.logText = `清空失败: ${err}`;
    }
  }

  private showConfirmDialog(message: string): Promise<boolean> {
    return new Promise((resolve) => {
      AlertDialog.show({
        title: '确认',
        message: message,
        autoCancel: true,
        alignment: DialogAlignment.Center,
        primaryButton: {
          value: '取消',
          action: () => { resolve(false); }
        },
        secondaryButton: {
          value: '确定',
          action: () => { resolve(true); }
        }
      });
    });
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Button('← 返回')
          .fontSize(14)
          .fontColor('#333')
          .backgroundColor('#F5F5F5')
          .width(80)
          .height(36)
          .onClick(() => { this.backToMain(); })

        Text('系统日志')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Blank().width(80)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor('#FFFFFF')
      .border({ width: { bottom: 1 }, color: '#E0E0E0' })

      // 操作按钮区域
      Column() {
        Row() {
          Button('导出系统日志')
            .fontSize(14)
            .fontColor('#FFFFFF')
            .backgroundColor('#007DFF')
            .height(40)
            .layoutWeight(1)
            .margin({ right: 12 })
            .onClick(() => { this.exportSystemLog(); })

          Button('清除系统日志')
            .fontSize(14)
            .fontColor('#FFFFFF')
            .backgroundColor('#F44336')
            .height(40)
            .layoutWeight(1)
            .margin({ left: 12 })
            .onClick(() => { this.clearSystemLog(); })
        }
        .width('100%')
        .margin({ bottom: 16 })

        Text(this.logText)
          .fontSize(14)
          .fontColor('#666')
          .textAlign(TextAlign.Center)
          .width('100%')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 16 })
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .margin({ left: 16, right: 16, top: 16 })
      .shadow({ radius: 4, color: '#10000000', offsetY: 2 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
