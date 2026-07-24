// lhipstudio/Common/permission/src/main/ets/model/User.ets

import { PermissionCode, PermissionGroups } from './Permission';

export enum RoleType {
  NORMAL = '普通用户',        // 普通用户 - 仅可查看
  OPERATOR = '运维员',        // 运维人员 - 设备操作者
  ADMIN = '管理员'            // 管理员 - 拥有所有权限
}

// 与 entry 模块 UserRole 的映射
export type UserRole = 'normal' | 'operator' | 'admin';

export function mapUserRoleToRoleType(role: UserRole): RoleType {
  switch (role) {
    case 'admin':
      return RoleType.ADMIN;
    case 'operator':
      return RoleType.OPERATOR;
    case 'normal':
    default:
      return RoleType.NORMAL;
  }
}

export function mapRoleTypeToUserRole(role: RoleType): UserRole {
  switch (role) {
    case RoleType.ADMIN:
      return 'admin';
    case RoleType.OPERATOR:
      return 'operator';
    case RoleType.NORMAL:
    default:
      return 'normal';
  }
}

// 角色权限映射表
export const RolePermissions: Record<RoleType, PermissionCode[]> = {
  // 普通用户：仅可查看仪器状态、数据
  [RoleType.NORMAL]: [
    ...PermissionGroups.SYSTEM_VIEW,      // 系统查看权限
    ...PermissionGroups.DATA_VIEW,        // 数据查看权限
    ...PermissionGroups.DEVICE_VIEW,      // 设备查看权限
    ...PermissionGroups.COMM_VIEW,        // 通信查看
    ...PermissionGroups.DATABASE_VIEW     // 数据库查看
  ],

  // 运维员：可查看配置、查看数据、启动/停止测量、修改系统设置
  [RoleType.OPERATOR]: [
    ...PermissionGroups.SYSTEM_VIEW,      // 系统查看权限
    ...PermissionGroups.DATA_VIEW,        // 数据查看权限
    ...PermissionGroups.DEVICE_BASIC,     // 设备基础操作
    ...PermissionGroups.COMM_VIEW,        // 通信查看
    ...PermissionGroups.DATABASE_VIEW,    // 数据库查看
    PermissionCode.MODIFY_SYSTEM_PARAMS   // 修改系统参数
  ],

  // 管理员：拥有所有权限，包括用户管理
  [RoleType.ADMIN]: [
    ...PermissionGroups.SYSTEM_ALL,       // 系统配置全权限
    ...PermissionGroups.DATA_MANAGE,      // 数据管理权限（含删除）
    ...PermissionGroups.DEVICE_ALL,       // 设备全权限
    ...PermissionGroups.COMM_ALL,         // 通信全权限
    ...PermissionGroups.DATABASE_ALL,     // 数据库全权限
    ...PermissionGroups.USER_ALL          // 用户管理全权限
  ]
};

// 用户模型
export class User {
  userId: string;
  userName: string;
  role: RoleType;
  password: string;
  createdAt: number;
  lastLoginAt: number;

  constructor(id: string, name: string, role: RoleType, password: string = '') {
    this.userId = id;
    this.userName = name;
    this.role = role;
    this.password = password;
    this.createdAt = Date.now();
    this.lastLoginAt = 0;
  }

  // 检查是否拥有某权限
  hasPermission(permission: PermissionCode): boolean {
    const userPermissions = RolePermissions[this.role];
    return userPermissions.includes(permission);
  }

  // 获取权限数量
  getPermissionCount(): number {
    return RolePermissions[this.role].length;
  }

  // 更新最后登录时间
  updateLastLogin(): void {
    this.lastLoginAt = Date.now();
  }

  // 序列化用户信息（用于存储）
  serialize(): string {
    return JSON.stringify({
      userId: this.userId,
      userName: this.userName,
      role: this.role,
      createdAt: this.createdAt,
      lastLoginAt: this.lastLoginAt
    });
  }

  // 反序列化用户信息
  static deserialize(data: string): User {
    interface UserData {
      userId: string;
      userName: string;
      role: RoleType;
      createdAt: number;
      lastLoginAt: number;
    }
    const obj: UserData = JSON.parse(data) as UserData;
    const user = new User(obj.userId, obj.userName, obj.role);
    user.createdAt = obj.createdAt;
    user.lastLoginAt = obj.lastLoginAt;
    return user;
  }
}

// 预置用户列表（用于演示/测试）
export const DefaultUsers: User[] = [
  new User('admin_001', '管理员', RoleType.ADMIN, '123456'),
  new User('operator_001', '运维员', RoleType.OPERATOR, '123456'),
  new User('normal_001', '普通用户', RoleType.NORMAL, '123456')
];