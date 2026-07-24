// Top menu and user entry metadata used by navigation bar.
export interface WqMenuItem {
  id: string;
  name: string;
  icon: Resource;
}

// Alarm row displayed in data page table.
export interface WqAlarmRecord {
  time: string;
  category: string;
  content: string;
}

// Instrument info key-value pair shown on system page.
export interface WqSystemInfoItem {
  label: string;
  value: string;
}

// Common key-value table row shown on system sub pages.
export interface WqSystemTableRow {
  id: string;
  category: string;
  item: string;
  value: string;
}

// Current login user profile shown on user page.
export interface WqUserInfo {
  username: string;
  role: string;
  department: string;
  lastLoginTime: string;
  lastLoginIp: string;
  accountStatus: string;
}
