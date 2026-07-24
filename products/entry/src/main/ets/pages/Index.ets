// entry/src/main/ets/pages/Index.ets
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { dncp, pump, valve, temp, meter, optical } from 'communication'; //导入模块
import type { Meter, Valve, Pump, Temp, Optical } from 'communication'; // 或分别从各文件 import type
import {
  type MotionParam, type PumpResult,            //泵接口结构体导入
  PumpStatus, RollDirection, PumpOperateResult, //泵接口枚举体导入
  type Temperature, type ThermostatParam, type TempCalibrateFactor, type ThermostatResult, //温度接口结构体导入
  ThermostatMode, ThermostatOperateResult,                                                 //温度枚举体导入
  // ValveMap,   //阀类导入
  MeterPoints,            //定量类导入
  type MeterPoint,        //定量结构体导入
  MeterMode, MeterResult, //定量枚举体导入
  type OpticalAD, type AcquiredResult, type LedParam, type RefADParam, //光学结构体导入
  AcquiredOperateResult, StaticADControlResult, AdjustResult,          //光学枚举体导入
} from 'communication'; //导入类型->结构体，枚举(结构体前必须加type，枚举体不需要加type)
import { Logger } from 'logger';
import { PermissionManager, User, RoleType } from 'permission';

// 数据库类型枚举
enum DbType {
  None = 'none',
  Relational = 'relational',
  flow = 'flow', //流程类
}

interface ButtonItem {
  text: string;
  action: () => void;
}

@Entry
@Component
struct Index {
  @State message: string = '欢迎使用数据服务测试工具';
  @State logText: string = '请选择要测试的数据/配置类型';
  @State currentUser: User | null = null;
  private permissionMgr: PermissionManager = PermissionManager.getInstance();

  async aboutToAppear() {
    this.keepScreenOn();
    this.loadUserState();
  }

  onPageShow() {
    // 从登录页返回时刷新用户状态
    this.loadUserState();
  }

  // 加载当前用户状态
  private loadUserState(): void {
    this.permissionMgr.initialize();
    this.currentUser = this.permissionMgr.getCurrentUser();
  }

  aboutToDisappear() {
    this.keepScreenOff();
  }

  private keepScreenOn(): void {
    try {
      const context = this.getUIContext().getHostContext();
      if (!context) return;
      window.getLastWindow(context).then((windowObj: window.Window) => {
        windowObj.setWindowKeepScreenOn(true, (err: BusinessError<void>) => {
          if (err.code) console.error(`Failed to set screen keep on: ${err.message}`);
        });
      }).catch((err: BusinessError<void>) => console.error(`Failed to get window: ${err.message}`));
    } catch (err) {
      console.error(`Keep screen on error: ${err}`);
    }
  }

  private keepScreenOff(): void {
    try {
      const context = this.getUIContext().getHostContext();
      if (!context) return;
      window.getLastWindow(context).then((windowObj: window.Window) => {
        windowObj.setWindowKeepScreenOn(false, (err: BusinessError<void>) => {
          if (err.code) console.error(`Failed to set screen keep on: ${err.message}`);
        });
      }).catch((err: BusinessError<void>) => console.error(`Failed to get window: ${err.message}`));
    } catch (err) {
      console.error(`Keep screen off error: ${err}`);
    }
  }

  // 获取当前用户
  getCurrentUser(): User | null {
    return this.permissionMgr.getCurrentUser();
  }

  // 跳转到登录页面
  private navigateToLoginPage(): void {
    let uiContext: UIContext = this.getUIContext();
    let router = uiContext.getRouter();
    router.pushUrl({ url: 'pages/permission/LoginPage' }).catch((err: BusinessError) => {
      console.error(`Failed to jump to LoginPage. Code is ${err.code}, message is ${err.message}`);
    });
  }

  private navigateToSettingPage(): void {
    let uiContext: UIContext = this.getUIContext();
    let router = uiContext.getRouter();
    router.pushUrl({ url: 'pages/SettingPage' }).catch((err: BusinessError) => {
      console.error(`Failed to jump to SettingPage. Code is ${err.code}, message is ${err.message}`);
    });
  }

  // 获取角色名称
  private getRoleName(role: RoleType): string {
    switch(role) {
      case RoleType.ADMIN: return '管理员';
      case RoleType.OPERATOR: return '运维员';
      case RoleType.NORMAL: return '普通用户';
      default: return '未登录';
    }
  }

  // ==================== 主界面导航 ====================
  private selectRelationalDb(): void {
    let uiContext: UIContext = this.getUIContext();
    let router = uiContext.getRouter();
    router.pushUrl({ url: 'pages/RelationalDbTest' }).catch((err: BusinessError) => {
      console.error(`Failed to jump to RelationalDbTest. Code is ${err.code}, message is ${err.message}`);
    });
  }

  private selectInstrumentDb(): void {
    let uiContext: UIContext = this.getUIContext();
    let router = uiContext.getRouter();
    router.pushUrl({ url: 'pages/InstrumentConfigTest' }).catch((err: BusinessError) => {
      console.error(`Failed to jump to InstrumentConfigTest. Code is ${err.code}, message is ${err.message}`);
    });
  }

  private selectMeasureStatusDb(): void {
    let uiContext: UIContext = this.getUIContext();
    let router = uiContext.getRouter();
    router.pushUrl({ url: 'pages/MeasureStatusTest' }).catch((err: BusinessError) => {
      console.error(`Failed to jump to MeasureStatusTest. Code is ${err.code}, message is ${err.message}`);
    });
  }

  private selectFlow(): void{
    // 获取UIContext
    let uiContext: UIContext = this.getUIContext();
    let router = uiContext.getRouter();
    // 跳转到第二页
    router.pushUrl({ url: 'pages/Index1' }).then(() => {
      console.info('Succeeded in jumping to the second page.')

    }).catch((err: BusinessError) => {
      console.error(`Failed to jump to the second page. Code is ${err.code}, message is ${err.message}`)
    })
  }

  private selectRunLog(): void {
    let uiContext: UIContext = this.getUIContext();
    let router = uiContext.getRouter();
    router.pushUrl({ url: 'pages/RunLog' }).catch((err: BusinessError) => {
      console.error(`Failed to jump to RunLog. Code is ${err.code}, message is ${err.message}`);
    });
  }

  private selectSystemLog(): void {
    let uiContext: UIContext = this.getUIContext();
    let router = uiContext.getRouter();
    router.pushUrl({ url: 'pages/SystemLog' }).catch((err: BusinessError) => {
      console.error(`Failed to jump to SystemLog. Code is ${err.code}, message is ${err.message}`);
    });
  }
  private navigateToModbusPage(): void {
    try {
      // 获取 UIContext
      let uiContext: UIContext = this.getUIContext();
      let routerObj = uiContext.getRouter();

      // 跳转到 Modbus 调试页面
      routerObj.pushUrl({
        url: 'pages/ModbusDebugPage'  // 确保这个页面文件存在
      }).then(() => {
        console.info('跳转到 Modbus 调试页面成功');
      }).catch((err: BusinessError) => {
        console.error(`跳转失败: ${err.code}, ${err.message}`);
        // 如果跳转失败，尝试使用绝对路径
        routerObj.pushUrl({
          url: '@ohos/modbus/pages/ModbusDebugPage'
        }).catch((e: BusinessError) => {
          console.error(`跳转失败(绝对路径): ${e.code}, ${e.message}`);
        });
      });
    } catch (err) {
      console.error(`导航错误: ${err}`);
    }
  }
  // ==================== 主界面 ====================
  @Builder
  buildMainMenu() {
    Column() {
      Text('数据服务测试页')
        .fontSize(28).fontWeight(FontWeight.Bold).margin({ top: 40, bottom: 20 })

      Text(this.message)
        .fontSize(18).margin({ bottom: 10 })

      Text(this.logText)
        .fontSize(14).fontColor('#666').margin({ bottom: 30 })
        .padding(12).backgroundColor('#F5F5F5').width('90%').borderRadius(8)

      Button('关系型数据库测试')
        .width('60%').height(50).fontSize(18).margin({ bottom: 20 })
        .onClick(() => { this.selectRelationalDb(); })

      Button('仪器信息配置测试')
        .width('60%').height(50).fontSize(18).margin({ bottom: 20 })
        .onClick(() => { this.selectInstrumentDb(); })

      Button('测量状态配置测试')
        .width('60%').height(50).fontSize(18).margin({ bottom: 20 })
        .onClick(() => { this.selectMeasureStatusDb(); })

      Button('流程和排期')
        .width('60%').height(50).fontSize(18).margin({ bottom: 20 })
        .onClick(() =>  { this.selectFlow(); })

      Button('运行日志')
        .width('60%').height(50).fontSize(18).margin({ bottom: 20 })
        .onClick(() =>  { this.selectRunLog(); })

      Button('系统日志')
        .width('60%').height(50).fontSize(18).margin({ bottom: 20 })
        .onClick(() =>  { this.selectSystemLog(); })
    }
    .width('100%').height('100%').justifyContent(FlexAlign.Center)
    // 右上角按钮区域
    Row() {
      // 通信图标按钮
      Button() {
        Row() {
          Text('📡').fontSize(24)
          Text('通信').fontSize(14).margin({ left: 4 })
        }
      }
      .height(40)
      .backgroundColor('#007bff')
      .borderRadius(20)
      .padding({ left: 16, right: 16 })
      .margin({ right: 10 })
      .onClick(() => {
        this.navigateToModbusPage();
      })

      // 用户图标按钮
      Button() {
        Row() {
          Text('👤').fontSize(24)
          if (this.currentUser) {
            Text(this.currentUser.userName).fontSize(14).margin({ left: 4 })
          } else {
            Text('登录').fontSize(14).margin({ left: 4 })
          }
        }
      }
      .height(40)
      .backgroundColor(this.currentUser ? '#28a745' : '#6c757d')
      .borderRadius(20)
      .padding({ left: 16, right: 16 })
      .margin({ right: 10 })
      .onClick(() => {
        this.navigateToLoginPage();
      })

      // 设置图标按钮
      Button() {
        Row() {
          Text('⚙️').fontSize(24)
          Text('设置').fontSize(14).margin({ left: 4 })
        }
      }
      .height(40)
      .backgroundColor('#ffffa407')
      .borderRadius(20)
      .padding({ left: 16, right: 16 })
      .onClick(() => {
        this.navigateToSettingPage();
      })
    }
    .width('100%')
    .justifyContent(FlexAlign.End)
    .padding({ right: 16, top: 16 })
    .position({ x: 0, y: 0 })

    // 显示当前登录状态
    if (this.currentUser) {
      Row() {
        Text(`当前用户: ${this.currentUser.userName} | 角色: ${this.getRoleName(this.currentUser.role)}`)
          .fontSize(12)
          .fontColor('#666')
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .padding({ bottom: 10 })
      .position({ x: 0, y: 50 })
    }
  }

  build() {
    Column() {
      this.buildMainMenu();
    }
    .width('100%')
    .height('100%')
  }
}