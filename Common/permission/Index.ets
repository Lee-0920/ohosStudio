// lhipstudio/Common/permission/Index.ets

// 导出权限管理器
export { PermissionManager, LoginResult, PasswordChangeResult } from './src/main/ets/model/PermissionManager';

// 导出权限装饰器
export { PermissionGuard } from './src/main/ets/model/PermissionDecorator';

// 导出权限码和权限组
export { PermissionCode, PermissionGroups } from './src/main/ets/model/Permission';

// 导出用户模型和角色类型
export { User, RoleType, RolePermissions, DefaultUsers, UserRole, mapUserRoleToRoleType, mapRoleTypeToUserRole } from './src/main/ets/model/User';
