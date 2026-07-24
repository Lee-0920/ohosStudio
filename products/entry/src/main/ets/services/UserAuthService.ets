import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0003;
const TAG = 'UserAuthService';
const PREFERENCES_NAME = 'waterquality_user_auth';

const KEY_NORMAL_PASSWORD = 'normal_password';
const KEY_OPERATOR_PASSWORD = 'operator_password';
const KEY_ADMIN_PASSWORD = 'admin_password';

const DEFAULT_NORMAL_PASSWORD = '123456';
const DEFAULT_OPERATOR_PASSWORD = '123456';
const DEFAULT_ADMIN_PASSWORD = '123456';

export type UserRole = 'normal' | 'operator' | 'admin';

export interface UserSession {
  role: UserRole;
  accountName: string;
  roleLabel: string;
  loginTime: number;
}

export interface UserLoginResult {
  success: boolean;
  message: string;
  session: UserSession | null;
}

export interface PasswordChangeResult {
  success: boolean;
  message: string;
}

export class UserAuthService {
  private static initialized: boolean = false;
  private static currentSession: UserSession | null = null;

  /**
   * 初始化本次应用会话。仪器启动后默认以普通用户身份进入主界面。
   * 退出登录后不会再次自动登录，直到用户选择账户并输入密码。
   */
  static initializeSession(): UserSession | null {
    if (!UserAuthService.initialized) {
      UserAuthService.initialized = true;
      UserAuthService.currentSession = UserAuthService.createSession('admin');
    }
    return UserAuthService.copySession(UserAuthService.currentSession);
  }

  static getCurrentSession(): UserSession | null {
    return UserAuthService.copySession(UserAuthService.currentSession);
  }

  static async login(context: common.Context, role: UserRole, password: string): Promise<UserLoginResult> {
    if (password.length <= 0) {
      return UserAuthService.loginFailure('请输入密码');
    }

    const storedPassword = UserAuthService.readPassword(context, role);
    if (storedPassword !== password) {
      return UserAuthService.loginFailure('密码错误');
    }

    const session = UserAuthService.createSession(role);
    UserAuthService.currentSession = session;
    return {
      success: true,
      message: '登录成功',
      session: UserAuthService.copySession(session)
    };
  }

  static logout(): void {
    UserAuthService.currentSession = null;
  }

  static async changePassword(
    context: common.Context,
    role: UserRole,
    oldPassword: string,
    newPassword: string,
    confirmPassword: string
  ): Promise<PasswordChangeResult> {
    if (oldPassword.length <= 0 || newPassword.length <= 0 || confirmPassword.length <= 0) {
      return UserAuthService.passwordFailure('请完整填写密码信息');
    }
    if (UserAuthService.readPassword(context, role) !== oldPassword) {
      return UserAuthService.passwordFailure('原密码错误');
    }
    if (newPassword.length < 6 || newPassword.length > 20) {
      return UserAuthService.passwordFailure('新密码长度应为 6 至 20 位');
    }
    if (newPassword !== confirmPassword) {
      return UserAuthService.passwordFailure('两次输入的新密码不一致');
    }
    if (newPassword === oldPassword) {
      return UserAuthService.passwordFailure('新密码不能与原密码相同');
    }

    try {
      const store = preferences.getPreferencesSync(context, { name: PREFERENCES_NAME });
      store.putSync(UserAuthService.passwordKey(role), newPassword);
      await store.flush();
      return {
        success: true,
        message: '密码修改成功'
      };
    } catch (err) {
      hilog.error(DOMAIN, TAG, '修改密码失败: %{public}s', JSON.stringify(err));
      return UserAuthService.passwordFailure('密码保存失败');
    }
  }

  static getAccountName(role: UserRole): string {
    if (role === 'operator') {
      return '运维员';
    }
    if (role === 'admin') {
      return '管理员';
    }
    return '普通用户';
  }

  static getRoleLabel(role: UserRole): string {
    return UserAuthService.getAccountName(role);
  }

  static canAccessMenu(role: UserRole, menuId: string): boolean {
    if (menuId === 'home' || menuId === 'data' || menuId === 'user') {
      return true;
    }
    if (menuId === 'signal') {
      return role === 'admin';
    }
    if (menuId === 'setting' || menuId === 'operation' || menuId === 'system') {
      return role === 'operator' || role === 'admin';
    }
    return false;
  }

  static canOperateInstrument(role: UserRole): boolean {
    return role === 'operator' || role === 'admin';
  }

  static getPermissionDescriptions(role: UserRole): string[] {
    if (role === 'admin') {
      return ['查看仪器状态和测试数据', '查询历史数据', '修改参数设置', '执行仪器与维护操作', '查看实时信号', '修改系统设置'];
    }
    if (role === 'operator') {
      return ['查看仪器状态和测试数据', '查询历史数据', '修改参数设置', '执行仪器与维护操作', '修改系统设置'];
    }
    return ['查看仪器状态', '查看和查询测试数据'];
  }

  private static createSession(role: UserRole): UserSession {
    return {
      role: role,
      accountName: UserAuthService.getAccountName(role),
      roleLabel: UserAuthService.getRoleLabel(role),
      loginTime: Date.now()
    };
  }

  private static copySession(session: UserSession | null): UserSession | null {
    if (!session) {
      return null;
    }
    return {
      role: session.role,
      accountName: session.accountName,
      roleLabel: session.roleLabel,
      loginTime: session.loginTime
    };
  }

  private static readPassword(context: common.Context, role: UserRole): string {
    const defaultPassword = UserAuthService.defaultPassword(role);
    try {
      const store = preferences.getPreferencesSync(context, { name: PREFERENCES_NAME });
      const value = store.getSync(UserAuthService.passwordKey(role), defaultPassword);
      return typeof value === 'string' ? value : defaultPassword;
    } catch (err) {
      hilog.warn(DOMAIN, TAG, '读取密码失败，使用默认密码: %{public}s', JSON.stringify(err));
      return defaultPassword;
    }
  }

  private static passwordKey(role: UserRole): string {
    if (role === 'operator') {
      return KEY_OPERATOR_PASSWORD;
    }
    if (role === 'admin') {
      return KEY_ADMIN_PASSWORD;
    }
    return KEY_NORMAL_PASSWORD;
  }

  private static defaultPassword(role: UserRole): string {
    if (role === 'operator') {
      return DEFAULT_OPERATOR_PASSWORD;
    }
    if (role === 'admin') {
      return DEFAULT_ADMIN_PASSWORD;
    }
    return DEFAULT_NORMAL_PASSWORD;
  }

  private static loginFailure(message: string): UserLoginResult {
    return {
      success: false,
      message: message,
      session: null
    };
  }

  private static passwordFailure(message: string): PasswordChangeResult {
    return {
      success: false,
      message: message
    };
  }
}
