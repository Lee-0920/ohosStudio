import { common } from '@kit.AbilityKit';
import { AlarmRecordService } from './AlarmRecordService';
import { CommunicationConfigService } from './CommunicationConfigService';
import { DevicePollingCoordinator } from './DevicePollingCoordinator';
import { OperationLogService } from './OperationLogService';
import { RuntimeActionLogService } from './RuntimeActionLogService';

const DEFAULT_OPERATOR = 'admin';

export class DataRecordLifecycleService {
  private static initialized: boolean = false;
  private static loginLogged: boolean = false;

  static async start(context: common.Context, operatorName: string = DEFAULT_OPERATOR): Promise<boolean> {
    await CommunicationConfigService.initialize(context);

    if (!DataRecordLifecycleService.initialized) {
      const initialized = await OperationLogService.init(context);
      if (!initialized) {
        return false;
      }
      DataRecordLifecycleService.initialized = true;
    }

    if (!DataRecordLifecycleService.loginLogged) {
      DataRecordLifecycleService.loginLogged = true;
      await OperationLogService.recordUserLogin(operatorName);
    }
    DevicePollingCoordinator.start();
    AlarmRecordService.startPolling();
    RuntimeActionLogService.startPolling();
    return true;
  }

  static stop(): void {
    AlarmRecordService.stopPolling();
    RuntimeActionLogService.stopPolling();
    DevicePollingCoordinator.stop();
  }
}
