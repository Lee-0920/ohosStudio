// lhipstudio/Common/permission/src/main/ets/model/Permission.ets

export enum PermissionCode {
  // 系统配置类权限
  MODIFY_SYSTEM_PARAMS = 'sys:modify_params',        // 修改系统参数
  VIEW_SYSTEM_CONFIG = 'sys:view_config',            // 查看系统配置
  RESET_SYSTEM_CONFIG = 'sys:reset_config',          // 重置系统配置
  VIEW_SYSTEM_LOG = 'sys:view_log',                  // 查看系统日志
  EXPORT_SYSTEM_LOG = 'sys:export_log',              // 导出系统日志

  // 数据操作类权限
  VIEW_HISTORY_DATA = 'data:view_history',           // 查看历史数据
  EXPORT_HISTORY_DATA = 'data:export_history',       // 导出历史数据
  DELETE_HISTORY_DATA = 'data:delete_history',       // 删除历史数据
  VIEW_RUN_LOG = 'data:view_run_log',                // 查看运行日志
  VIEW_FLOW_SCHEDULE = 'data:view_flow',             // 查看流程排期

  // 设备控制类权限
  START_MEASUREMENT = 'device:start_measure',        // 手动启动测量
  STOP_MEASUREMENT = 'device:stop_measure',          // 停止测量
  CALIBRATE_DEVICE = 'device:calibrate',             // 设备校准
  VIEW_MEASURE_STATUS = 'device:view_status',        // 查看测量状态
  MODIFY_DEVICE_CONFIG = 'device:modify_config',     // 修改设备配置
  VIEW_DEVICE_INFO = 'device:view_info',             // 查看设备信息

  // 通信调试类权限
  VIEW_COMMUNICATION = 'comm:view',                  // 查看通信状态
  DEBUG_COMMUNICATION = 'comm:debug',                // 通信调试
  MODIFY_COMMUNICATION_PARAMS = 'comm:modify_params',// 修改通信参数

  // 数据库管理类权限
  VIEW_DATABASE = 'db:view',                         // 查看数据库
  MODIFY_DATABASE = 'db:modify',                     // 修改数据库
  EXPORT_DATABASE = 'db:export',                     // 导出数据库

  // 用户管理类权限
  MANAGE_USERS = 'user:manage',                      // 管理用户
  ASSIGN_ROLES = 'user:assign_role',                 // 分配角色
  VIEW_USER_LIST = 'user:view_list',                 // 查看用户列表
  DELETE_USERS = 'user:delete',                      // 删除用户
  VIEW_LOGIN_LOG = 'user:view_login_log'             // 查看登录日志
}

// 权限组（便于批量授权）
export const PermissionGroups: Record<string, PermissionCode[]> = {
  // 系统配置全权限
  "SYSTEM_ALL": [
    PermissionCode.MODIFY_SYSTEM_PARAMS,
    PermissionCode.VIEW_SYSTEM_CONFIG,
    PermissionCode.RESET_SYSTEM_CONFIG,
    PermissionCode.VIEW_SYSTEM_LOG,
    PermissionCode.EXPORT_SYSTEM_LOG
  ],
  // 系统查看权限
  "SYSTEM_VIEW": [
    PermissionCode.VIEW_SYSTEM_CONFIG,
    PermissionCode.VIEW_SYSTEM_LOG
  ],

  // 数据全权限（含删除）
  "DATA_ALL": [
    PermissionCode.VIEW_HISTORY_DATA,
    PermissionCode.EXPORT_HISTORY_DATA,
    PermissionCode.VIEW_RUN_LOG,
    PermissionCode.VIEW_FLOW_SCHEDULE
  ],
  // 数据管理权限（含删除）
  "DATA_MANAGE": [
    PermissionCode.VIEW_HISTORY_DATA,
    PermissionCode.EXPORT_HISTORY_DATA,
    PermissionCode.DELETE_HISTORY_DATA,
    PermissionCode.VIEW_RUN_LOG,
    PermissionCode.VIEW_FLOW_SCHEDULE
  ],
  // 数据查看权限
  "DATA_VIEW": [
    PermissionCode.VIEW_HISTORY_DATA,
    PermissionCode.VIEW_RUN_LOG,
    PermissionCode.VIEW_FLOW_SCHEDULE
  ],

  // 设备全权限
  "DEVICE_ALL": [
    PermissionCode.START_MEASUREMENT,
    PermissionCode.STOP_MEASUREMENT,
    PermissionCode.CALIBRATE_DEVICE,
    PermissionCode.VIEW_MEASURE_STATUS,
    PermissionCode.MODIFY_DEVICE_CONFIG,
    PermissionCode.VIEW_DEVICE_INFO
  ],
  // 设备基础权限
  "DEVICE_BASIC": [
    PermissionCode.START_MEASUREMENT,
    PermissionCode.STOP_MEASUREMENT,
    PermissionCode.VIEW_MEASURE_STATUS,
    PermissionCode.VIEW_DEVICE_INFO
  ],
  // 设备查看权限
  "DEVICE_VIEW": [
    PermissionCode.VIEW_MEASURE_STATUS,
    PermissionCode.VIEW_DEVICE_INFO
  ],

  // 通信全权限
  "COMM_ALL": [
    PermissionCode.VIEW_COMMUNICATION,
    PermissionCode.DEBUG_COMMUNICATION,
    PermissionCode.MODIFY_COMMUNICATION_PARAMS
  ],
  // 通信查看权限
  "COMM_VIEW": [
    PermissionCode.VIEW_COMMUNICATION
  ],

  // 数据库全权限
  "DATABASE_ALL": [
    PermissionCode.VIEW_DATABASE,
    PermissionCode.MODIFY_DATABASE,
    PermissionCode.EXPORT_DATABASE
  ],
  // 数据库查看权限
  "DATABASE_VIEW": [
    PermissionCode.VIEW_DATABASE
  ],

  // 用户管理全权限
  "USER_ALL": [
    PermissionCode.MANAGE_USERS,
    PermissionCode.ASSIGN_ROLES,
    PermissionCode.VIEW_USER_LIST,
    PermissionCode.DELETE_USERS,
    PermissionCode.VIEW_LOGIN_LOG
  ],
  // 用户查看权限
  "USER_VIEW": [
    PermissionCode.VIEW_USER_LIST,
    PermissionCode.VIEW_LOGIN_LOG
  ]
};