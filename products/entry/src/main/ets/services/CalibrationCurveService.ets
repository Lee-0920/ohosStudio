import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import {
  CalibrationCurveInput,
  CalibrationCurveQuery,
  CalibrationCurveRecord,
  CurrentCalibrationCurveSummary,
  DataPageQueryResult,
  LOG_RESULT_FAILED,
  LOG_RESULT_INFO,
  LOG_RESULT_SUCCESS,
  OPERATION_LOG_TYPE_PARAMETER,
  OPERATION_LOG_TYPE_RUNTIME
} from '../models/dataRecordTypes';
import { DataRecordDao } from '../dao/DataRecordDao';
import { MonitorService } from './MonitorService';
import { PhotoTekTimeValue } from './protocol/PhotoTekTypes';
import { OperationLogService } from './OperationLogService';

const DOMAIN = 0x0003;
const TAG = 'CalibrationCurveService';
const DEFAULT_OPERATOR = 'admin';
const SOURCE_CALIBRATION_CURVE = 'calibration_curve_service';

export class CalibrationCurveService {
  private static isCapturing: boolean = false;
  private static isSettingCurrent: boolean = false;

  static init(context: common.Context): Promise<boolean> {
    return DataRecordDao.init(context);
  }

  static queryCalibrationCurveRecords(
    query: CalibrationCurveQuery
  ): Promise<DataPageQueryResult<CalibrationCurveRecord>> {
    return DataRecordDao.queryCalibrationCurveRecords(query);
  }

  static async readCurrentCalibrationCurveSummary(): Promise<CurrentCalibrationCurveSummary | null> {
    if (!MonitorService.isConnectedToMcu()) {
      return null;
    }
    const slope = await MonitorService.readCalibrationCurveSlope();
    const intercept = await MonitorService.readCalibrationCurveIntercept();
    if (slope === null || intercept === null) {
      return null;
    }
    const zeroConcentration = await MonitorService.readCalibrationZeroConcentration();
    const spanConcentration = await MonitorService.readCalibrationSpanConcentration();
    return {
      slope: slope,
      intercept: intercept,
      zeroConcentration: zeroConcentration,
      spanConcentration: spanConcentration
    };
  }

  static async captureCurrentCalibrationCurve(operatorName: string = DEFAULT_OPERATOR): Promise<boolean> {
    if (CalibrationCurveService.isCapturing) {
      return false;
    }
    if (!MonitorService.isConnectedToMcu()) {
      return false;
    }

    CalibrationCurveService.isCapturing = true;
    try {
      const input = await CalibrationCurveService.readCurrentCalibrationCurveInput(operatorName);
      if (!input) {
        await CalibrationCurveService.recordCaptureFailure('读取校准曲线关键字段失败', operatorName);
        return false;
      }

      const inserted = await DataRecordDao.insertCalibrationCurveRecord(input);
      if (inserted) {
        const marked = await DataRecordDao.markCurrentCalibrationCurveByUniqueKey(input.uniqueKey);
        await OperationLogService.record({
          logType: OPERATION_LOG_TYPE_RUNTIME,
          action: '保存校准曲线',
          content: marked ?
            `保存校准曲线：斜率=${CalibrationCurveService.formatNumber(input.slope)}，截距=${CalibrationCurveService.formatNumber(input.intercept)}，量程=${input.rangeLabel}` :
            '保存校准曲线失败：数据库当前标记更新失败',
          source: SOURCE_CALIBRATION_CURVE,
          operatorName: operatorName,
          detail: `uniqueKey=${input.uniqueKey}; calibrationTime=${input.calibrationTime}`
        }, marked ? LOG_RESULT_INFO : LOG_RESULT_FAILED);
        return marked;
      }
      return inserted;
    } catch (err) {
      const detail = JSON.stringify(err);
      hilog.error(DOMAIN, TAG, 'capture calibration curve failed: %{public}s', detail);
      await CalibrationCurveService.recordCaptureFailure(detail, operatorName);
      return false;
    } finally {
      CalibrationCurveService.isCapturing = false;
    }
  }

  static async setCurrentCalibrationCurve(id: number, operatorName: string = DEFAULT_OPERATOR): Promise<boolean> {
    if (CalibrationCurveService.isSettingCurrent) {
      return false;
    }

    CalibrationCurveService.isSettingCurrent = true;
    try {
      const record = await DataRecordDao.getCalibrationCurveRecord(id);
      if (!record) {
        await CalibrationCurveService.recordSetCurrentFailure(id, '未找到校准曲线记录', operatorName);
        return false;
      }
      if (!MonitorService.isConnectedToMcu()) {
        await CalibrationCurveService.recordSetCurrentFailure(id, '设备未连接', operatorName);
        return false;
      }

      const oldSlope = await MonitorService.readCalibrationCurveSlope();
      const oldIntercept = await MonitorService.readCalibrationCurveIntercept();
      if (oldSlope === null || oldIntercept === null) {
        await CalibrationCurveService.recordSetCurrentFailure(id, '读取当前斜率或截距失败', operatorName);
        return false;
      }

      const slopeWritten = await MonitorService.writeCalibrationCurveSlope(record.slope);
      if (!slopeWritten) {
        await CalibrationCurveService.recordSetCurrentFailure(id, '写入斜率失败', operatorName, record, oldSlope, oldIntercept);
        return false;
      }

      const interceptWritten = await MonitorService.writeCalibrationCurveIntercept(record.intercept);
      if (!interceptWritten) {
        const rollbackSlope = await MonitorService.writeCalibrationCurveSlope(oldSlope);
        await CalibrationCurveService.recordSetCurrentFailure(
          id,
          `写入截距失败，斜率回滚${rollbackSlope ? '成功' : '失败'}`,
          operatorName,
          record,
          oldSlope,
          oldIntercept
        );
        return false;
      }

      const marked = await DataRecordDao.markCurrentCalibrationCurve(id);
      await OperationLogService.record({
        logType: OPERATION_LOG_TYPE_PARAMETER,
        action: '设为当前校准曲线',
        content: marked ?
          `设为当前校准曲线：斜率=${CalibrationCurveService.formatNumber(record.slope)}，截距=${CalibrationCurveService.formatNumber(record.intercept)}，量程=${record.rangeLabel}` :
          `设为当前校准曲线失败：数据库当前标记更新失败`,
        source: SOURCE_CALIBRATION_CURVE,
        operatorName: operatorName,
        detail: `recordId=${id}; oldSlope=${CalibrationCurveService.formatNumber(oldSlope)}; oldIntercept=${CalibrationCurveService.formatNumber(oldIntercept)}; newSlope=${CalibrationCurveService.formatNumber(record.slope)}; newIntercept=${CalibrationCurveService.formatNumber(record.intercept)}`
      }, marked ? LOG_RESULT_SUCCESS : LOG_RESULT_FAILED);
      return marked;
    } catch (err) {
      const detail = JSON.stringify(err);
      hilog.error(DOMAIN, TAG, 'set current calibration curve failed: %{public}s', detail);
      await CalibrationCurveService.recordSetCurrentFailure(id, detail, operatorName);
      return false;
    } finally {
      CalibrationCurveService.isSettingCurrent = false;
    }
  }

  private static async readCurrentCalibrationCurveInput(operatorName: string): Promise<CalibrationCurveInput | null> {
    const calibrationTime = await MonitorService.readCalibrationTime();
    const slope = await MonitorService.readCalibrationCurveSlope();
    const intercept = await MonitorService.readCalibrationCurveIntercept();
    if (slope === null || intercept === null) {
      return null;
    }

    const zeroAbsorbance = await MonitorService.readCalibrationZeroAbsorbance();
    const spanAbsorbance = await MonitorService.readCalibrationSpanAbsorbance();
    const zeroConcentration = await MonitorService.readCalibrationZeroConcentration();
    const spanConcentration = await MonitorService.readCalibrationSpanConcentration();
    const currentRange = await MonitorService.readCurrentRange();
    const capturedAt = Date.now();
    const timestamp = CalibrationCurveService.timeValueToTimestamp(calibrationTime, capturedAt);
    const rangeLabel = currentRange === null ? '-' : CalibrationCurveService.formatNumber(currentRange);
    const uniqueKey = CalibrationCurveService.buildUniqueKey(timestamp, slope, intercept, currentRange);

    return {
      calibrationTime: timestamp,
      slope: slope,
      intercept: intercept,
      zeroAbsorbance: zeroAbsorbance,
      spanAbsorbance: spanAbsorbance,
      zeroConcentration: zeroConcentration,
      spanConcentration: spanConcentration,
      rangeValue: currentRange,
      rangeLabel: rangeLabel,
      isCurrent: true,
      source: SOURCE_CALIBRATION_CURVE,
      operatorName: operatorName,
      uniqueKey: uniqueKey
    };
  }

  private static async recordCaptureFailure(reason: string, operatorName: string): Promise<void> {
    await OperationLogService.record({
      logType: OPERATION_LOG_TYPE_RUNTIME,
      action: '保存校准曲线',
      content: `保存校准曲线失败：${reason}`,
      source: SOURCE_CALIBRATION_CURVE,
      operatorName: operatorName,
      detail: reason
    }, LOG_RESULT_FAILED);
  }

  private static async recordSetCurrentFailure(
    id: number,
    reason: string,
    operatorName: string,
    record?: CalibrationCurveRecord,
    oldSlope?: number,
    oldIntercept?: number
  ): Promise<void> {
    const targetText = record ?
      `新斜率=${CalibrationCurveService.formatNumber(record.slope)}; 新截距=${CalibrationCurveService.formatNumber(record.intercept)}; 量程=${record.rangeLabel}` :
      '未读取到目标曲线';
    const oldText = oldSlope !== undefined && oldIntercept !== undefined ?
      `原斜率=${CalibrationCurveService.formatNumber(oldSlope)}; 原截距=${CalibrationCurveService.formatNumber(oldIntercept)}` :
      '原曲线未知';
    await OperationLogService.record({
      logType: OPERATION_LOG_TYPE_PARAMETER,
      action: '设为当前校准曲线',
      content: `设为当前校准曲线失败：${reason}`,
      source: SOURCE_CALIBRATION_CURVE,
      operatorName: operatorName,
      detail: `recordId=${id}; ${oldText}; ${targetText}; reason=${reason}`
    }, LOG_RESULT_FAILED);
  }

  private static timeValueToTimestamp(value: PhotoTekTimeValue | null, fallback: number): number {
    if (!value) {
      return fallback;
    }
    const date = new Date(value.year, value.month - 1, value.day, value.hour, value.minute, value.second, 0);
    const timestamp = date.getTime();
    if (Number.isNaN(timestamp) || timestamp <= 0) {
      return fallback;
    }
    return timestamp;
  }

  private static buildUniqueKey(
    calibrationTime: number,
    slope: number,
    intercept: number,
    rangeValue: number | null
  ): string {
    const rangePart = rangeValue === null ? '-' : CalibrationCurveService.formatNumber(rangeValue);
    return `${calibrationTime}-${CalibrationCurveService.formatNumber(slope)}-${CalibrationCurveService.formatNumber(intercept)}-${rangePart}`;
  }

  static formatNumber(value: number): string {
    return Number.isNaN(value) ? '-' : value.toFixed(3);
  }
}
