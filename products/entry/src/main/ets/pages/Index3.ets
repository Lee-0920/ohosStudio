import { hilog } from '@kit.PerformanceAnalysisKit';
import { window, componentSnapshot, promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { image } from '@kit.ImageKit';
import { fileIo } from '@kit.CoreFileKit';
import { TopMenuBar, UserMenuAction } from '../components/TopMenuBar';
import { DataPage } from './DataPage';
import { HomePage } from './HomePage';
import { OperationPage } from './OperationPage';
import { SettingPage } from './SettingPage';
import { SignalPage } from './SignalPage';
import { SystemPage } from './SystemPage';
import { UserPage } from './UserPage';
import { WqMenuItem, WqUserInfo } from '../models/monitorTypes';
import { FooterBar } from '../components/FooterBar';
import { DataRecordLifecycleService } from '../services/DataRecordLifecycleService';
import { UserAuthService, UserLoginResult, UserRole, UserSession } from '../services/UserAuthService';
import { PermissionManager } from 'permission';
import { UiUtil } from 'base';

const DOMAIN = 0x0001;
const TAG = 'IndexPage';
const RIGHT_MOUSE_BUTTON = 2;
const FULLSCREEN_TOGGLE_DEBOUNCE_MS = 800;

// Root container page:
// 1) Holds shared UI state
// 2) Owns global shell behavior such as navigation and fullscreen
// 3) Dispatches menu to concrete page components
@Entry
@Preview
@Component
struct Index {
  // Current top-level menu id.
  @State currentMenu: string = 'home';
  // Viewport dimensions used for responsive scaling in child pages/components.
  @State viewportWidth: number = 1024;
  @State viewportHeight: number = 768;
  // Fullscreen state for ESC/right-click exit behavior.
  @State isFullscreen: boolean = true;
  // Data page currently selected left tab.
  @State selectedDataTab: string = '测量数据';
  @State private isLoggedIn: boolean = true;
  @State private currentRole: UserRole = 'normal';
  @State private loginTime: number = Date.now();
  @State private selectedLoginRole: UserRole = 'normal';
  @State private loginPassword: string = '';
  @State private loginMessage: string = '';
  @State private isLoginSubmitting: boolean = false;
  @State private clickLogin: boolean = false;
  // Global scale coefficient for vh/vw conversion.
  private scaleFactor: number = 1.92;
  // Prevent one physical right-click from toggling twice on press/release.
  private lastFullscreenToggleAt: number = 0;
  private isFullscreenSwitching: boolean = false;
  private readonly visibleSystemBars: Array<'status' | 'navigation'> = ['status', 'navigation'];
  private readonly hiddenSystemBars: Array<'status' | 'navigation'> = [];
  private readonly loginRoles: UserRole[] = ['normal', 'operator', 'admin'];
  // Top menu definitions for left navigation area.
  private readonly leftMenus: WqMenuItem[] = [
    { id: 'home', name: '主界面', icon: $r('app.media.home') },
    { id: 'data', name: '数据', icon: $r('app.media.data') },
    { id: 'signal', name: '信号', icon: $r('app.media.signal') },
    { id: 'setting', name: '设置', icon: $r('app.media.setting') },
    { id: 'operation', name: '运维', icon: $r('app.media.operation') },
    { id: 'system', name: '系统', icon: $r('app.media.system') }
  ];
  // Right-side user menu entry.
  private readonly rightMenu: WqMenuItem = { id: 'user', name: '用户', icon: $r('app.media.user') };
  // Data page tabs.
  private readonly dataLeftTabs: string[] = ['测量数据', '历史趋势', '校准曲线', '量程信息', '告警管理', '运行日志'];

  aboutToAppear(): void {
    PermissionManager.getInstance().initialize();
    const session = UserAuthService.initializeSession();
    this.applyUserSession(session);
    const context = this.getHostContext();
    if (context) {
      void DataRecordLifecycleService.start(context, session ? session.accountName : '普通用户');
    }
  }

  aboutToDisappear(): void {
    DataRecordLifecycleService.stop();
  }

  // Sync viewport values from root onAreaChange callback.
  private updateCompactMode(width: number, height: number): void {
    this.viewportWidth = width > 0 ? width : this.viewportWidth;
    this.viewportHeight = height > 0 ? height : this.viewportHeight;
  }

  private getHostContext(): common.Context | null {
    const context = this.getUIContext().getHostContext();
    if (!context) {
      return null;
    }
    return context as common.Context;
  }

  private applyUserSession(session: UserSession | null): void {
    this.isLoggedIn = session !== null;
    if (!session) {
      PermissionManager.getInstance().logout();
      return;
    }
    this.currentRole = session.role;
    this.loginTime = session.loginTime;
    PermissionManager.getInstance().setCurrentUserByRole(session.role);
  }

  private visibleLeftMenus(): WqMenuItem[] {
    return this.leftMenus.filter((item: WqMenuItem) => {
      return UserAuthService.canAccessMenu(this.currentRole, item.id);
    });
  }

  private currentUserInfo(): WqUserInfo {
    return {
      username: UserAuthService.getAccountName(this.currentRole),
      role: UserAuthService.getRoleLabel(this.currentRole),
      department: '水质监测系统',
      lastLoginTime: UiUtil.formatDateTimestamp(this.loginTime),
      lastLoginIp: '本机账户',
      accountStatus: this.isLoggedIn ? '已登录' : '未登录'
    };
  }

  private handleMenuClick(menuId: string): void {
    if (!UserAuthService.canAccessMenu(this.currentRole, menuId)) {
      return;
    }
    this.currentMenu = menuId;
  }

  private handleLogout(): void {
    UserAuthService.logout();
    PermissionManager.getInstance().logout();
    this.isLoggedIn = false;
    this.currentMenu = 'home';
    this.selectedLoginRole = 'normal';
    this.currentRole = 'normal';
    this.loginPassword = '';
    this.loginMessage = '请选择账户并输入密码';
  }

  private handleUserMenuAction(action: UserMenuAction): void {
    switch (action) {
      case 'switch':
        this.handleMenuClick('user');
        break;
      case 'logout':
        this.handleLogout();
        break;
      case 'screenshot':
        void this.handleScreenshot();
        break;
      default:
        break;
    }
  }

  private async handleScreenshot(): Promise<void> {
    const context = this.getHostContext();
    if (!context) {
      promptAction.showToast({ message: '无法获取应用上下文' });
      return;
    }

    try {
      const pixelMap: image.PixelMap = await componentSnapshot.get('indexRoot');
      const imagePacker = image.createImagePacker();
      const packOpts: image.PackingOption = { format: 'image/png', quality: 100 };
      const buffer: ArrayBuffer = await imagePacker.packing(pixelMap, packOpts);

      const uiAbilityContext = context as common.UIAbilityContext;
      const screenshotDir = uiAbilityContext.filesDir + '/screenshots';
      if (!fileIo.accessSync(screenshotDir)) {
        fileIo.mkdirSync(screenshotDir);
      }

      const fileName = `screenshot_${this.formatScreenshotTime()}_${Date.now()}.png`;
      const filePath = screenshotDir + '/' + fileName;
      const file = fileIo.openSync(filePath,
        fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE);
      fileIo.writeSync(file.fd, buffer);
      fileIo.closeSync(file.fd);

      promptAction.showToast({ message: `截图已保存：${filePath}`, duration: 2000 });
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'screenshot failed: %{public}s', JSON.stringify(err));
      promptAction.showToast({ message: '截图失败，请重试' });
    }
  }

  private formatScreenshotTime(): string {
    const now = new Date();
    const pad = (value: number): string => value < 10 ? '0' + value : '' + value;
    return `${now.getFullYear()}${pad(now.getMonth() + 1)}${pad(now.getDate())}_` +
      `${pad(now.getHours())}${pad(now.getMinutes())}${pad(now.getSeconds())}`;
  }

  private async handleLogin(): Promise<void> {
    if (this.isLoginSubmitting) {
      return;
    }
    const context = this.getHostContext();
    if (!context) {
      this.loginMessage = '无法获取应用上下文';
      return;
    }

    this.isLoginSubmitting = true;
    try {
      const result: UserLoginResult = await UserAuthService.login(
        context,
        this.selectedLoginRole,
        this.loginPassword
      );
      if (!result.success || !result.session) {
        this.loginMessage = result.message;
        return;
      }
      this.applyUserSession(result.session);
      this.currentMenu = 'home';
      this.loginPassword = '';
      this.loginMessage = '';
      this.clickLogin = false;
    } finally {
      this.isLoginSubmitting = false;
    }
  }

  // Toggle each system bar first; keep setWindowSystemBarEnable as a compatibility fallback.
  private async setSystemBarsVisible(win: window.Window, visible: boolean): Promise<void> {
    try {
      await win.setSpecificSystemBarEnabled('status', visible, false);
      await win.setSpecificSystemBarEnabled('navigation', visible, false);
    } catch (specificErr) {
      hilog.warn(DOMAIN, TAG, 'set specific system bars failed: %{public}s', JSON.stringify(specificErr));
    }
    await win.setWindowSystemBarEnable(visible ? this.visibleSystemBars : this.hiddenSystemBars);
  }

  // Apply fullscreen layout and system bar visibility together.
  private setFullscreen(isFullscreen: boolean, trigger: string): void {
    if (this.isFullscreenSwitching) {
      return;
    }
    this.isFullscreenSwitching = true;

    // getContext(component) is deprecated; use UIContext host context instead.
    const context = this.getHostContext();
    if (!context) {
      hilog.error(DOMAIN, TAG, 'getHostContext failed: context is undefined');
      this.isFullscreenSwitching = false;
      return;
    }

    window.getLastWindow(context, (err, win) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 'getLastWindow failed: %{public}s', JSON.stringify(err));
        this.isFullscreenSwitching = false;
        return;
      }
      void (async () => {
        try {
          hilog.info(DOMAIN, TAG, 'Try %{public}s fullscreen by %{public}s, current layout fullscreen: %{public}s',
            isFullscreen ? 'enter' : 'exit', trigger, String(win.getWindowProperties().isLayoutFullScreen));

          if (isFullscreen) {
            // Enter fullscreen: layout first, then hide status/navigation bars.
            await win.setWindowLayoutFullScreen(true);
            await this.setSystemBarsVisible(win, false);
          } else {
            // Exit fullscreen: leave fullscreen layout first, then restore system bars.
            await win.setWindowLayoutFullScreen(false);
            await this.setSystemBarsVisible(win, true);
          }

          this.isFullscreen = isFullscreen;
          hilog.info(DOMAIN, TAG, '%{public}s fullscreen by %{public}s, current layout fullscreen: %{public}s',
            isFullscreen ? 'Enter' : 'Exit', trigger, String(win.getWindowProperties().isLayoutFullScreen));
        } catch (setErr) {
          hilog.error(DOMAIN, TAG, 'set fullscreen failed: %{public}s', JSON.stringify(setErr));
        } finally {
          this.isFullscreenSwitching = false;
        }
      })();
    });
  }

  // Exit fullscreen and restore system bars.
  private exitFullscreen(trigger: string): void {
    this.setFullscreen(false, trigger);
  }

  // Enter fullscreen and hide system bars.
  private enterFullscreen(trigger: string): void {
    this.setFullscreen(true, trigger);
  }

  // Toggle fullscreen state from right-click.
  private toggleFullscreen(trigger: string): void {
    const now = Date.now();
    if (now - this.lastFullscreenToggleAt < FULLSCREEN_TOGGLE_DEBOUNCE_MS) {
      return;
    }
    this.lastFullscreenToggleAt = now;

    if (this.isFullscreen) {
      this.exitFullscreen(trigger);
    } else {
      this.enterFullscreen(trigger);
    }
  }

  @Builder
  private pageContent() {
    Stack() {
      HomePage({
        viewportWidth: this.viewportWidth,
        viewportHeight: this.viewportHeight,
        scaleFactor: this.scaleFactor,
        isActivate: this.isLoggedIn && this.currentMenu === 'home',
        canOperateInstrument: this.isLoggedIn && UserAuthService.canOperateInstrument(this.currentRole)
      })
        .visibility(this.currentMenu === 'home' ? Visibility.Visible : Visibility.Hidden)
        .zIndex(this.currentMenu === 'home' ? 1 : 0)

      if (this.currentMenu === 'data') {
        // Data: tab + alarm table + query panel.
        DataPage({
          dataLeftTabs: this.dataLeftTabs,
          selectedDataTab: this.selectedDataTab,
          canSetCalibrationCurve: this.isLoggedIn && UserAuthService.canOperateInstrument(this.currentRole),
          viewportWidth: this.viewportWidth,
          viewportHeight: this.viewportHeight,
          scaleFactor: this.scaleFactor
        });
      } else if (this.currentMenu === 'system') {
        // System: instrument metadata.
        SystemPage({
          viewportWidth: this.viewportWidth,
          viewportHeight: this.viewportHeight,
          scaleFactor: this.scaleFactor
        });
      } else if (this.currentMenu === 'signal') {
        // Signal: placeholder page.
        SignalPage({
          viewportWidth: this.viewportWidth,
          viewportHeight: this.viewportHeight,
          scaleFactor: this.scaleFactor
        });
      } else if (this.currentMenu === 'setting') {
        // Setting: placeholder page.
        SettingPage({
          viewportWidth: this.viewportWidth,
          viewportHeight: this.viewportHeight,
          scaleFactor: this.scaleFactor
        });
      } else if (this.currentMenu === 'operation') {
        // Operation: placeholder page.
        OperationPage({
          viewportWidth: this.viewportWidth,
          viewportHeight: this.viewportHeight,
          scaleFactor: this.scaleFactor
        });
      } else if (this.currentMenu === 'user') {
        // User: account profile page.
        UserPage({
          userInfo: this.currentUserInfo(),
          viewportWidth: this.viewportWidth,
          viewportHeight: this.viewportHeight,
          scaleFactor: this.scaleFactor,
          onLogout: () => {
            this.handleLogout();
          },
          clickLogin: this.clickLogin,
          isLoggedIn: this.isLoggedIn,
        });
      }
    }
    .layoutWeight(1)
    .width('100%')
    .backgroundColor('#F7F7F7')
  }

  @Builder
  private loginOverlay() {
    Stack({ alignContent: Alignment.Center }) {
      Column() {
        Image($r('app.media.user'))
          .width(UiUtil.vh(8.0, 58, 86, this.viewportHeight, this.scaleFactor))
          .height(UiUtil.vh(8.0, 58, 86, this.viewportHeight, this.scaleFactor))
          .borderRadius(UiUtil.vh(4.0, 29, 43, this.viewportHeight, this.scaleFactor))
          .border({ width: 2, color: '#0B9F9A' })

        Text('用户登录')
          .fontSize(UiUtil.vh(2.8, 20, 30, this.viewportHeight, this.scaleFactor))
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F2937')
          .margin({ top: UiUtil.vh(1.0, 7, 12, this.viewportHeight, this.scaleFactor) })

        Text('退出登录后必须重新验证账户才能操作仪器')
          .fontSize(UiUtil.vh(1.45, 11, 15, this.viewportHeight, this.scaleFactor))
          .fontColor('#64748B')
          .margin({
            top: UiUtil.vh(0.5, 4, 7, this.viewportHeight, this.scaleFactor),
            bottom: UiUtil.vh(1.5, 10, 16, this.viewportHeight, this.scaleFactor)
          })

        Row() {
          ForEach(this.loginRoles, (role: UserRole) => {
            Column() {
              Text(UserAuthService.getRoleLabel(role))
                .fontSize(UiUtil.vh(1.65, 12, 17, this.viewportHeight, this.scaleFactor))
                .fontWeight(this.selectedLoginRole === role ? FontWeight.Bold : FontWeight.Normal)
                .fontColor(this.selectedLoginRole === role ? '#FFFFFF' : '#334155')
            }
            .width(UiUtil.vw(9.5, 86, 116, this.viewportWidth, this.scaleFactor))
            .height(UiUtil.vh(5.0, 38, 52, this.viewportHeight, this.scaleFactor))
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .backgroundColor(this.selectedLoginRole === role ? '#0B9F9A' : '#F1F5F9')
            .border({ width: 1, color: this.selectedLoginRole === role ? '#0B9F9A' : '#CBD5E1' })
            .borderRadius(UiUtil.vh(0.7, 5, 8, this.viewportHeight, this.scaleFactor))
            .margin({
              left: UiUtil.vw(0.35, 3, 5, this.viewportWidth, this.scaleFactor),
              right: UiUtil.vw(0.35, 3, 5, this.viewportWidth, this.scaleFactor)
            })
            .onClick(() => {
              this.selectedLoginRole = role;
              this.loginPassword = '';
              this.loginMessage = '';
            })
          }, (role: UserRole) => role)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)

        TextInput({ text: this.loginPassword, placeholder: '请输入账户密码' })
          .type(InputType.Password)
          .width(UiUtil.vw(30, 280, 380, this.viewportWidth, this.scaleFactor))
          .height(UiUtil.vh(5.2, 40, 54, this.viewportHeight, this.scaleFactor))
          .fontSize(UiUtil.vh(1.7, 12, 17, this.viewportHeight, this.scaleFactor))
          .backgroundColor('#F8FAFC')
          .border({ width: 1, color: '#CBD5E1' })
          .borderRadius(UiUtil.vh(0.7, 5, 8, this.viewportHeight, this.scaleFactor))
          .margin({ top: UiUtil.vh(1.5, 10, 16, this.viewportHeight, this.scaleFactor) })
          .onChange((value: string) => {
            this.loginPassword = value;
            this.loginMessage = '';
          })

        Text(this.loginMessage)
          .height(UiUtil.vh(3.2, 24, 34, this.viewportHeight, this.scaleFactor))
          .fontSize(UiUtil.vh(1.45, 11, 15, this.viewportHeight, this.scaleFactor))
          .fontColor(
            this.loginMessage.indexOf('错误') >= 0 || this.loginMessage.indexOf('无法') >= 0 ? '#E53935' : '#64748B')
          .textAlign(TextAlign.Center)
          .margin({ top: UiUtil.vh(0.5, 3, 6, this.viewportHeight, this.scaleFactor) })

        Row() {
          Button(this.isLoginSubmitting ? '登录中' : '登录')
            .width(UiUtil.vw(18, 160, 220, this.viewportWidth, this.scaleFactor))
            .height(UiUtil.vh(5.0, 38, 52, this.viewportHeight, this.scaleFactor))
            .fontSize(UiUtil.vh(1.8, 13, 18, this.viewportHeight, this.scaleFactor))
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .backgroundColor('#0B9F9A')
            .borderRadius(UiUtil.vh(0.8, 6, 9, this.viewportHeight, this.scaleFactor))
            .opacity(this.isLoginSubmitting ? 0.6 : 1)
            .enabled(!this.isLoginSubmitting)
            .onClick(() => {
              void this.handleLogin();
            })

          Button('取消')
            .width(UiUtil.vw(18, 160, 220, this.viewportWidth, this.scaleFactor))
            .height(UiUtil.vh(5.0, 38, 52, this.viewportHeight, this.scaleFactor))
            .fontSize(UiUtil.vh(1.8, 13, 18, this.viewportHeight, this.scaleFactor))
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .backgroundColor('#0B9F9A')
            .borderRadius(UiUtil.vh(0.8, 6, 9, this.viewportHeight, this.scaleFactor))
            .opacity(this.isLoginSubmitting ? 0.6 : 1)
            .enabled(!this.isLoginSubmitting)
            .onClick(() => {
              this.clickLogin = false;
              this.loginPassword = '';
            })
        }
      }
      .width(UiUtil.vw(45, 390, 560, this.viewportWidth, this.scaleFactor))
      .padding({
        left: UiUtil.vw(2.2, 20, 32, this.viewportWidth, this.scaleFactor),
        right: UiUtil.vw(2.2, 20, 32, this.viewportWidth, this.scaleFactor),
        top: UiUtil.vh(2.2, 16, 26, this.viewportHeight, this.scaleFactor),
        bottom: UiUtil.vh(2.5, 18, 30, this.viewportHeight, this.scaleFactor)
      })
      .alignItems(HorizontalAlign.Center)
      .backgroundColor('#FFFFFF')
      .borderRadius(UiUtil.vh(1.2, 8, 14, this.viewportHeight, this.scaleFactor))
      .border({ width: 1, color: '#D7DEE8' })
      .shadow({
        radius: 18,
        color: '#40000000',
        offsetX: 0,
        offsetY: 8
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#B3000000')
    .zIndex(100)
  }

  build() {
    Stack() {
      Column() {
        // Global top navigation bar.
        TopMenuBar({
          currentMenu: this.currentMenu,
          leftMenus: this.visibleLeftMenus(),
          rightMenu: this.rightMenu,
          viewportWidth: this.viewportWidth,
          viewportHeight: this.viewportHeight,
          scaleFactor: this.scaleFactor,
          onMenuClick: (menuId: string) => {
            this.handleMenuClick(menuId);
          },
          onUserMenuAction: (action: UserMenuAction) => {
            this.handleUserMenuAction(action);
          }
        });
        this.pageContent();
        FooterBar({
          viewportWidth: this.viewportWidth,
          viewportHeight: this.viewportHeight,
          scaleFactor: this.scaleFactor,
        });
      }
      .width('100%')
      .height('100%')
      .enabled(!this.clickLogin)
      .opacity(!this.clickLogin ? 1 : 0.55)

      if (this.clickLogin) {
        this.loginOverlay();
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F7F7')
    .focusable(true)
    .defaultFocus(true)
    .onAreaChange((_, value) => {
      // Keep viewport-based scaling up to date.
      this.updateCompactMode(UiUtil.lengthToNumber(value.width), UiUtil.lengthToNumber(value.height));
    })
    .onKeyEvent((event) => {
      if (!this.isLoggedIn) {
        return false;
      }
      // ESC exits fullscreen mode.
      if (event.keyCode === 111 && this.isFullscreen) {
        this.exitFullscreen('ESC');
        return true;
      }
      return false;
    })
    .onMouse((event) => {
      if (!this.isLoggedIn) {
        return;
      }
      // Right-click toggles fullscreen mode. Debounce handles press/release repeats.
      if (event.button === RIGHT_MOUSE_BUTTON) {
        this.toggleFullscreen('鼠标右键');
      }
    })
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .id('indexRoot')
  }
}
