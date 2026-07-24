// lhipstudio/Common/permission/src/main/ets/model/PermissionDecorator.ets

import { PermissionManager } from './PermissionManager';
import { PermissionCode } from '../model/Permission';
import promptAction from '@ohos.promptAction';
import router from '@ohos.router';

export class PermissionGuard {
  /**
   * 检查权限，无权限时自动提示并返回 false
   */
  static async checkOrPrompt(permission: PermissionCode): Promise<boolean> {
    const permissionMgr: PermissionManager = PermissionManager.getInstance();
    const hasPermission: boolean = await permissionMgr.checkPermissionWithPrompt(permission);
    return hasPermission;
  }

  /**
   * 检查角色，角色不匹配时提示并返回上一页，返回 false
   */
  static checkRoleOrBack(allowedRoles: string[]): boolean {
    const permissionMgr: PermissionManager = PermissionManager.getInstance();
    const userRole: string | null = permissionMgr.getUserRole();

    if (!userRole || !allowedRoles.includes(userRole)) {
      promptAction.showToast({
        message: '您没有权限访问此页面',
        duration: 2000
      });
      router.back();
      return false;
    }
    return true;
  }
}