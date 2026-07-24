import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import {
  LOG_RESULT_FAILED,
  LOG_RESULT_INFO,
  LOG_RESULT_SUCCESS,
  OPERATION_LOG_TYPE_LOGIN,
  DataPageQueryResult,
  OperationLogQuery,
  OperationLogRecord,
  OperationLogRequest
} from '../models/dataRecordTypes';
import { DataRecordDao } from '../dao/DataRecordDao';

const DOMAIN = 0x0003;
const TAG = 'OperationLogService';
const DEFAULT_OPERATOR = 'admin';

export class OperationLogService {
  static init(context: common.Context): Promise<boolean> {
    return DataRecordDao.init(context);
  }

  static async queryOperationLogs(query: OperationLogQuery): Promise<DataPageQueryResult<OperationLogRecord>> {
    return DataRecordDao.queryOperationLogs(query);
  }

  static async record(request: OperationLogRequest, result: string = LOG_RESULT_INFO): Promise<boolean> {
    const now = Date.now();
    return DataRecordDao.insertOperationLog({
      logTime: now,
      logType: request.logType,
      action: request.action,
      content: request.content,
      result: result,
      source: request.source,
      operatorName: request.operatorName ? request.operatorName : DEFAULT_OPERATOR,
      detail: request.detail ? request.detail : ''
    });
  }

  static async recordUserLogin(operatorName: string = DEFAULT_OPERATOR): Promise<boolean> {
    return OperationLogService.record({
      logType: OPERATION_LOG_TYPE_LOGIN,
      action: '用户登录',
      content: `${operatorName}登录系统`,
      source: 'index_page',
      operatorName: operatorName
    }, LOG_RESULT_SUCCESS);
  }

  static async runWithLog(
    request: OperationLogRequest,
    task: () => Promise<boolean>
  ): Promise<boolean> {
    try {
      const ok = await task();
      await OperationLogService.record(
        request,
        ok ? LOG_RESULT_SUCCESS : LOG_RESULT_FAILED
      );
      return ok;
    } catch (err) {
      const detail = request.detail && request.detail.length > 0 ?
        `${request.detail}; error=${JSON.stringify(err)}` :
        JSON.stringify(err);
      await OperationLogService.record({
        logType: request.logType,
        action: request.action,
        content: request.content,
        source: request.source,
        operatorName: request.operatorName,
        detail: detail
      }, LOG_RESULT_FAILED);
      hilog.error(DOMAIN, TAG, 'logged action failed: %{public}s', JSON.stringify(err));
      return false;
    }
  }
}
