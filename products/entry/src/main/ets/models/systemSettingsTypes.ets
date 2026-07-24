export type NetworkMode = 'dhcp' | 'static';

export interface NetworkSettingsConfig {
  iface: string;
  mode: NetworkMode;
  ip: string;
  netMask: string;
  gateway: string;
  dns1: string;
  dns2: string;
}

export interface NetworkRuntimeInfo {
  ip: string;
  netMask: string;
  gateway: string;
  dns1: string;
  dns2: string;
}

export interface NetworkSettingsLoadResult {
  config: NetworkSettingsConfig;
  fromPersistence: boolean;
}
