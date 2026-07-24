import { AuthorizationConfig, authorizationConfig } from './AuthorizationConfig';
import { consumableConfig } from './ConsumableConfig';
import { hardwareConfig } from './HardwareConfig';
import { instrumentInformation } from './InstrumentInformation';
import { interconnectionConfig } from './InterconnectionConfig';
import { mainBoardInformation } from './MainBoardInformation';
import { measureParamConfig } from './MeasureParamConfig';
import { measureRunning } from './MeasureRunning';
import { measureStatus } from './MeasureStatus';
import { remainConfig } from './RemainConfig';
import { remainStatus } from './RemainStatus';
import { systemConfig } from './SystemConfig';
import { schedulerConfig } from './SchedulerConfig';

import {
  MeasureParamConfig,
  InstrumentInfoConfig,
  MainBoardInfoConfig,
  HardwareConfig,
  InterconnectionConfig,
  SystemConfig,
  SchedulerConfig,
  MeasureRunning,
  RemainStatus,
  ConsumableConfig,
  MeasureStatus,
  RemainConfig,
} from 'dataservice';

export { MeasureMode } from './SchedulerConfig';

export interface Config {
  authorization: AuthorizationConfig;
  consumable: ConsumableConfig;
  hardware: HardwareConfig;
  instrumentInformation: InstrumentInfoConfig;
  interconnection: InterconnectionConfig;
  mainBoardInformation: MainBoardInfoConfig;
  measureParam: MeasureParamConfig;
  remain: RemainConfig;
  system: SystemConfig;
  scheduler: SchedulerConfig;
}

export interface Status {
  measureRunning: MeasureRunning;
  measureStatus: MeasureStatus;
  remainStatus: RemainStatus;
}

export const config: Config = {
  authorization: authorizationConfig,
  consumable: consumableConfig,
  hardware: hardwareConfig,
  instrumentInformation: instrumentInformation,
  interconnection: interconnectionConfig,
  mainBoardInformation: mainBoardInformation,
  measureParam: measureParamConfig,
  remain: remainConfig,
  system: systemConfig,
  scheduler: schedulerConfig,
};

export const status:Status = {
  measureRunning,
  measureStatus,
  remainStatus,
}

