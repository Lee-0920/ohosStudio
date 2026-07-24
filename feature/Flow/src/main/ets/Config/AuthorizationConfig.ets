export interface AuthorizationConfig {
  normalUserPassword: string;      // 普通用户密码
  maintenancePassword: string;     // 维护用户密码
  administratorPassword: string;   // 管理员密码
  superPassword: string;           // 超级用户密码
  usedPasswords: string[];         // 已使用过的密码列表
  usedReagentPasswords: string[];  // 已使用过的试剂密码列表
}

// 登录密码设置
export const authorizationConfig: AuthorizationConfig = {
  normalUserPassword: "000000",
  maintenancePassword: "666666",
  administratorPassword: "112008",
  superPassword: "032018",
  usedPasswords: ["000000", "111111", "222222", "333333", "444444", "555555", "666666", "777777", "888888", "999999"],
  usedReagentPasswords: ["000000", "111111", "222222", "333333", "444444", "555555", "666666", "777777", "888888", "999999"],
};
