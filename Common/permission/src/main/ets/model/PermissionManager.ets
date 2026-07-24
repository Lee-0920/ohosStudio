// lhipstudio/Common/permission/src/main/ets/model/PermissionManager.ets

import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { User, RoleType, RolePermissions, DefaultUsers, UserRole, mapUserRoleToRoleType } from '../model/User';
import { PermissionCode } from '../model/Permission';
import promptAction from '@ohos.promptAction';

const DOMAIN = 0x0003;
const TAG = 'PermissionManager';
const PREFERENCES_NAME = 'waterquality_user_auth';

const KEY_NORMAL_PASSWORD = 'normal_password';
const KEY_OPERATOR_PASSWORD = 'operator_password';
const KEY_ADMIN_PASSWORD = 'admin_password';

const DEFAULT_NORMAL_PASSWORD = '123456';
const DEFAULT_OPERATOR_PASSWORD = '123456';
const DEFAULT_ADMIN_PASSWORD = '123456';

export interface LoginResult {
  success: boolean;
  message: string;
  user?: User;
}

export interface PasswordChangeResult {
  success: boolean;
  message: string;
}

// 权限码到中文描述的映射
const PermissionDescriptions: Record<PermissionCode, string> = {
  [PermissionCode.MODIFY_SYSTEM_PARAMS]: '修改系统参数',
  [PermissionCode.VIEW_SYSTEM_CONFIG]: '查看系统配置',
  [PermissionCode.RESET_SYSTEM_CONFIG]: '重置系统配置',
  [PermissionCode.VIEW_SYSTEM_LOG]: '查看系统日志',
  [PermissionCode.EXPORT_SYSTEM_LOG]: '导出系统日志',
  [PermissionCode.VIEW_HISTORY_DATA]: '查询历史数据',
  [PermissionCode.EXPORT_HISTORY_DATA]: '导出历史数据',
  [PermissionCode.DELETE_HISTORY_DATA]: '删除历史数据',
  [PermissionCode.VIEW_RUN_LOG]: '查看运行日志',
  [PermissionCode.VIEW_FLOW_SCHEDULE]: '查看流程排期',
  [PermissionCode.START_MEASUREMENT]: '手动启动测量',
  [PermissionCode.STOP_MEASUREMENT]: '停止测量',
  [PermissionCode.CALIBRATE_DEVICE]: '设备校准',
  [PermissionCode.VIEW_MEASURE_STATUS]: '查看仪器状态',
  [PermissionCode.MODIFY_DEVICE_CONFIG]: '修改设备配置',
  [PermissionCode.VIEW_DEVICE_INFO]: '查看设备信息',
  [PermissionCode.VIEW_COMMUNICATION]: '查看通信状态',
  [PermissionCode.DEBUG_COMMUNICATION]: '通信调试',
  [PermissionCode.MODIFY_COMMUNICATION_PARAMS]: '修改通信参数',
  [PermissionCode.VIEW_DATABASE]: '查看数据库',
  [PermissionCode.MODIFY_DATABASE]: '修改数据库',
  [PermissionCode.EXPORT_DATABASE]: '导出数据库',
  [PermissionCode.MANAGE_USERS]: '管理用户',
  [PermissionCode.ASSIGN_ROLES]: '分配角色',
  [PermissionCode.VIEW_USER_LIST]: '查看用户列表',
  [PermissionCode.DELETE_USERS]: '删除用户',
  [PermissionCode.VIEW_LOGIN_LOG]: '查看登录日志'
};

export class PermissionManager {
  private static instance: PermissionManager;
  private currentUser: User | null = null;
  private userList: User[] = [];
  private isInitialized: boolean = false;

  // 单例模式
  static getInstance(): PermissionManager {
    if (!PermissionManager.instance) {
      PermissionManager.instance = new PermissionManager();
    }
    return PermissionManager.instance;
  }

  // 初始化用户列表（使用默认值）
  initialize(): void {
    if (this.isInitialized) return;

    this.userList = [...DefaultUsers];
    this.currentUser = null;
    this.isInitialized = true;
    console.info(`PermissionManager initialized with ${this.userList.length} users`);
  }

  // 用户登录（可选使用 context 读取持久化密码）
  login(username: string, password: string, context?: common.Context): LoginResult {
    if (!this.isInitialized) {
      this.initialize();
    }

    // 查找用户
    const user = this.userList.find(u => u.userName === username);
    if (!user) {
      const result: LoginResult = { success: false, message: '用户名不存在' };
      return result;
    }

    // 验证密码：优先从持久化读取，未提供 context 时使用内存密码
    const storedPassword = context ? this.readStoredPassword(context, user.role) : user.password;
    if (storedPassword !== password) {
      const result: LoginResult = { success: false, message: '密码错误' };
      return result;
    }

    // 登录成功
    this.currentUser = user;
    user.updateLastLogin();

    console.info(`User ${user.userName} (${user.role}) logged in successfully`);
    const result: LoginResult = { success: true, message: '登录成功', user: user };
    return result;
  }

  // 用户登出
  logout(): void {
    if (this.currentUser) {
      console.info(`User ${this.currentUser.userName} logged out`);
    }

    this.currentUser = null;
  }

  // 设置当前登录用户（兼容旧接口）
  setCurrentUser(user: User): void {
    this.currentUser = user;
  }

  // 根据 entry 模块的 UserRole 设置当前用户
  setCurrentUserByRole(role: UserRole): void {
    if (!this.isInitialized) {
      this.initialize();
    }
    const roleType = mapUserRoleToRoleType(role);
    const user = this.userList.find(u => u.role === roleType);
    if (user) {
      this.currentUser = user;
      user.updateLastLogin();
    } else {
      console.warn(`No default user found for role: ${role}`);
    }
  }

  // 获取当前用户
  getCurrentUser(): User | null {
    return this.currentUser;
  }

  // 检查是否已登录
  isLoggedIn(): boolean {
    return this.currentUser !== null;
  }

  // 核心：权限校验方法
  checkPermission(permission: PermissionCode): boolean {
    if (!this.currentUser) {
      console.warn('No user logged in');
      return false;
    }

    const hasPermission = this.currentUser.hasPermission(permission);

    if (!hasPermission) {
      console.warn(
        `User ${this.currentUser.userName} (${this.currentUser.role}) ` +
          `denied for permission: ${permission}`
      );
    }

    return hasPermission;
  }

  // 带提示的权限校验
  async checkPermissionWithPrompt(permission: PermissionCode): Promise<boolean> {
    if (this.checkPermission(permission)) {
      return true;
    }

    await promptAction.showToast({
      message: '您没有权限执行此操作',
      duration: 2000
    });

    return false;
  }

  // 批量权限校验
  checkPermissions(permissions: PermissionCode[]): boolean {
    if (!this.currentUser) return false;

    return permissions.every(perm =>
      this.currentUser!.hasPermission(perm)
    );
  }

  // 获取用户角色
  getUserRole(): RoleType | null {
    return this.currentUser?.role || null;
  }

  // 获取当前用户权限描述列表（用于用户权限界面）
  getPermissionDescriptions(): string[] {
    const role = this.getUserRole();
    if (!role) {
      return [];
    }

    const permissions = RolePermissions[role];
    return permissions.map(perm => PermissionDescriptions[perm] ?? perm);
  }

  // 获取用户列表
  getUserList(): User[] {
    return [...this.userList];
  }

  // 添加用户
  addUser(user: User): boolean {
    // 检查用户名是否已存在
    if (this.userList.some(u => u.userName === user.userName)) {
      return false;
    }

    this.userList.push(user);
    return true;
  }

  // 删除用户
  deleteUser(userId: string): boolean {
    const index = this.userList.findIndex(u => u.userId === userId);
    if (index === -1) {
      return false;
    }

    // 不允许删除自己
    if (this.currentUser && this.currentUser.userId === userId) {
      return false;
    }

    this.userList.splice(index, 1);
    return true;
  }

  // 修改用户角色
  updateUserRole(userId: string, newRole: RoleType): boolean {
    const user = this.userList.find(u => u.userId === userId);
    if (!user) {
      return false;
    }

    user.role = newRole;
    return true;
  }

  // 修改用户密码（内部更新，不验证原密码）
  updateUserPassword(userId: string, newPassword: string): boolean {
    const user = this.userList.find(u => u.userId === userId);
    if (!user) {
      return false;
    }

    user.password = newPassword;
    return true;
  }

  // 修改当前登录用户密码（带验证并持久化）
  async changePassword(
    context: common.Context,
    oldPassword: string,
    newPassword: string,
    confirmPassword: string
  ): Promise<PasswordChangeResult> {
    if (!this.currentUser) {
      return { success: false, message: '未登录，无法修改密码' };
    }

    if (oldPassword.length <= 0 || newPassword.length <= 0 || confirmPassword.length <= 0) {
      return { success: false, message: '请完整填写密码信息' };
    }

    const role = this.currentUser.role;
    if (this.readStoredPassword(context, role) !== oldPassword) {
      return { success: false, message: '原密码错误' };
    }
    if (newPassword.length < 6 || newPassword.length > 20) {
      return { success: false, message: '新密码长度应为 6 至 20 位' };
    }
    if (newPassword !== confirmPassword) {
      return { success: false, message: '两次输入的新密码不一致' };
    }
    if (newPassword === oldPassword) {
      return { success: false, message: '新密码不能与原密码相同' };
    }

    try {
      await this.savePassword(context, role, newPassword);
      this.currentUser.password = newPassword;
      return { success: true, message: '密码修改成功' };
    } catch (err) {
      hilog.error(DOMAIN, TAG, '修改密码失败: %{public}s', JSON.stringify(err));
      return { success: false, message: '密码保存失败' };
    }
  }

  private readStoredPassword(context: common.Context, role: RoleType): string {
    const defaultPassword = this.defaultPassword(role);
    try {
      const store = preferences.getPreferencesSync(context, { name: PREFERENCES_NAME });
      const value = store.getSync(this.passwordKey(role), defaultPassword);
      return typeof value === 'string' ? value : defaultPassword;
    } catch (err) {
      hilog.warn(DOMAIN, TAG, '读取密码失败，使用默认密码: %{public}s', JSON.stringify(err));
      return defaultPassword;
    }
  }

  private async savePassword(context: common.Context, role: RoleType, password: string): Promise<void> {
    const store = preferences.getPreferencesSync(context, { name: PREFERENCES_NAME });
    store.putSync(this.passwordKey(role), password);
    await store.flush();
  }

  private passwordKey(role: RoleType): string {
    switch (role) {
      case RoleType.OPERATOR:
        return KEY_OPERATOR_PASSWORD;
      case RoleType.ADMIN:
        return KEY_ADMIN_PASSWORD;
      case RoleType.NORMAL:
      default:
        return KEY_NORMAL_PASSWORD;
    }
  }

  private defaultPassword(role: RoleType): string {
    switch (role) {
      case RoleType.OPERATOR:
        return DEFAULT_OPERATOR_PASSWORD;
      case RoleType.ADMIN:
        return DEFAULT_ADMIN_PASSWORD;
      case RoleType.NORMAL:
      default:
        return DEFAULT_NORMAL_PASSWORD;
    }
  }
}
