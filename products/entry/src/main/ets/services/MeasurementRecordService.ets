import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import {
  DataPageQueryResult,
  LOG_RESULT_INFO,
  MeasurementRecord,
  MeasurementRecordInput,
  MeasurementRecordQuery,
  MeasurementTrendQuery,
  OPERATION_LOG_TYPE_RUNTIME
} from '../models/dataRecordTypes';
import { DataRecordDao } from '../dao/DataRecordDao';
import { MonitorService } from './MonitorService';
import {
  PhotoTekCodeDescription,
  PhotoTekDataFlag,
  PhotoTekMeasurementParameterInfo,
  PhotoTekTimeValue
} from './protocol/PhotoTekTypes';
import { OperationLogService } from './OperationLogService';

const DOMAIN = 0x0003;
const TAG = 'MeasurementRecordService';
const DEFAULT_FLAG_LABEL = '正常';
const SOURCE_MEASUREMENT_RECORD = 'measurement_record_service';

export class MeasurementRecordService {
  private static isCapturing: boolean = false;

  static init(context: common.Context): Promise<boolean> {
    return DataRecordDao.init(context);
  }

  static queryMeasurementRecords(query: MeasurementRecordQuery): Promise<DataPageQueryResult<MeasurementRecord>> {
    return DataRecordDao.queryMeasurementRecords(query);
  }

  static queryMeasurementTrendRecords(query: MeasurementTrendQuery): Promise<MeasurementRecord[]> {
    return DataRecordDao.queryMeasurementTrendRecords(query);
  }

  static async captureLatestMeasurementRecord(): Promise<boolean> {
    if (MeasurementRecordService.isCapturing) {
      return false;
    }
    if (!MonitorService.isConnectedToMcu()) {
      return false;
    }

    MeasurementRecordService.isCapturing = true;
    try {
      const parameter = await MonitorService.readMeasurementParameterInfo();
      if (!parameter) {
        return false;
      }

      const resultValue = await MonitorService.readCompositeMeasurementResult();
      if (resultValue === null) {
        return false;
      }

      const capturedAt = Date.now();
      const compositeTime = await MonitorService.readCompositeResultTime();
      const measurementTime = MeasurementRecordService.timeValueToTimestamp(compositeTime, capturedAt);
      const resultType = MeasurementRecordService.normalizeCodeDescription(
        await MonitorService.readMeasurementResultType(),
        '未知类型'
      );
      const dataFlag = MeasurementRecordService.normalizeDataFlag(await MonitorService.readCompositeDataFlag());
      const absorbance = await MeasurementRecordService.readAbsorbance(resultType);
      const currentRange = await MonitorService.readCurrentRange();
      const input = MeasurementRecordService.buildRecordInput(
        parameter,
        resultValue,
        resultType,
        dataFlag,
        measurementTime,
        absorbance,
        currentRange
      );

      const inserted = await DataRecordDao.insertMeasurementRecord(input);
      if (inserted) {
        await OperationLogService.record({
          logType: OPERATION_LOG_TYPE_RUNTIME,
          action: '保存测量数据',
          content: `保存测量数据：${input.resultTypeLabel} ${MeasurementRecordService.formatNumber(input.resultValue)}${input.resultUnit}`,
          source: SOURCE_MEASUREMENT_RECORD,
          detail: `uniqueKey=${input.uniqueKey}`
        }, LOG_RESULT_INFO);
      }
      return inserted;
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'capture measurement failed: %{public}s', JSON.stringify(err));
      return false;
    } finally {
      MeasurementRecordService.isCapturing = false;
    }
  }

  private static buildRecordInput(
    parameter: PhotoTekMeasurementParameterInfo,
    resultValue: number,
    resultType: PhotoTekCodeDescription,
    dataFlag: PhotoTekDataFlag,
    measurementTime: number,
    absorbance: number | null,
    currentRange: number | null
  ): MeasurementRecordInput {
    const resultTypeCode = String(resultType.code);
    const rangeLabel = currentRange === null ? '-' : MeasurementRecordService.formatNumber(currentRange);
    const uniqueKey = MeasurementRecordService.buildUniqueKey(
      measurementTime,
      parameter.code,
      resultTypeCode,
      resultValue
    );

    return {
      measurementTime: measurementTime,
      parameterCode: parameter.code,
      parameterName: parameter.name,
      resultValue: resultValue,
      resultUnit: parameter.unit,
      absorbance: absorbance,
      flagCode: dataFlag.code,
      flagLabel: dataFlag.label,
      resultTypeCode: resultTypeCode,
      resultTypeLabel: resultType.label,
      rangeValue: currentRange,
      rangeLabel: rangeLabel,
      uniqueKey: uniqueKey
    };
  }

  private static async readAbsorbance(resultType: PhotoTekCodeDescription): Promise<number | null> {
    const code = MeasurementRecordService.codeNumber(resultType);
    if (code === 0) {
      return MonitorService.readCalibrationZeroAbsorbance();
    }
    if (code === 1) {
      return MonitorService.readWaterSampleAbsorbance();
    }
    if (code === 2) {
      return MonitorService.readCalibrationSolutionAbsorbance();
    }
    if (code === 7 || code === 10) {
      return MonitorService.readCheckSolutionAbsorbance();
    }
    return MonitorService.readWaterSampleAbsorbance();
  }

  private static normalizeCodeDescription(
    value: PhotoTekCodeDescription | null,
    fallbackLabel: string
  ): PhotoTekCodeDescription {
    if (value) {
      return value;
    }
    return {
      code: '',
      label: fallbackLabel
    };
  }

  private static normalizeDataFlag(value: PhotoTekDataFlag | null): PhotoTekDataFlag {
    if (value) {
      return value;
    }
    return {
      code: '',
      label: DEFAULT_FLAG_LABEL
    };
  }

  private static codeNumber(value: PhotoTekCodeDescription): number | null {
    if (typeof value.code === 'number') {
      return value.code;
    }
    const parsed = Number(value.code);
    return Number.isNaN(parsed) ? null : parsed;
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
    measurementTime: number,
    parameterCode: number,
    resultTypeCode: string,
    resultValue: number
  ): string {
    return `${measurementTime}-${parameterCode}-${resultTypeCode}-${MeasurementRecordService.formatNumber(resultValue)}`;
  }

  static formatNumber(value: number): string {
    return Number.isNaN(value) ? '-' : value.toFixed(3);
  }
}
