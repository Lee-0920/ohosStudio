import { GradientSideTabBar } from '../components/GradientSideTabBar';
import {
  DeviceEvent, SignalSnapshot, TemperatureSnapshot
} from '../models/deviceStateTypes';
import { DeviceEventBus } from '../services/DeviceEventBus';
import { DevicePollingCoordinator } from '../services/DevicePollingCoordinator';
import { DeviceStateStore } from '../services/DeviceStateStore';
import { PT63EventService } from '../services/PT63EventService';
import { PhotoTekTemperatureValue } from '../services/protocol/PhotoTekTypes';
import {
  EventPack,
  type Temperature,
  type ThermostatParam,
  type TempCalibrateFactor,
  type ThermostatResult, //温度接口结构体导入
  type OpticalAD,
  type AcquiredResult,
  type LedParam,
  type RefADParam, //光学结构体导入
} from 'communication'; //导入类型->结构体，枚举(结构体前必须加type，枚举体不需要加type)
import { UiUtil } from 'base';

interface WqSignalRecord {
  category: string;
  name: string;
  value: string;
  unit: string;
}

@Component
export struct SignalPage {
  @Prop viewportWidth: number = 1024;
  @Prop viewportHeight: number = 768;
  @Prop scaleFactor: number = 1.92;
  @State private signalRows: WqSignalRecord[] = [
    { category: '测量模块', name: '参考AD', value: '-', unit: '' },
    { category: '', name: '测量AD', value: '-', unit: '' },
    { category: '', name: '绝对吸光度', value: '-', unit: 'mAbs' },
    { category: '定量模块', name: '定量点1', value: '-', unit: '' },
    { category: '', name: '定量点2', value: '-', unit: '' },
    { category: '消解器', name: '消解温度', value: '-', unit: '℃' },
    { category: '仪器', name: '环境温度', value: '-', unit: '℃' }
  ];
  private isSignalPageActive: boolean = false;
  private unsubscribeSignal: (() => void) | null = null;
  private unsubscribeTemperature: (() => void) | null = null;
  private unsubscribePt63: (() => void) | null = null;
  private releaseSignalInterest: (() => void) | null = null;
  private releaseTemperatureInterest: (() => void) | null = null;
  private readonly signalTabs: string[] = ['基本信号'];
  private readonly emptyValue: string = '-';

  private formatNumber(value: number | null, fractionDigits: number): string {
    return value === null ? this.emptyValue : value.toFixed(fractionDigits);
  }

  private temperatureUnit(value: PhotoTekTemperatureValue | null): string {
    if (!value) {
      return '℃';
    }
    const unit = value.unit.trim();
    return unit.length > 0 ? unit : '℃';
  }

  private areSignalRowsEqual(left: WqSignalRecord[], right: WqSignalRecord[]): boolean {
    if (left.length !== right.length) {
      return false;
    }

    for (let i = 0; i < left.length; i++) {
      if (
        left[i].category !== right[i].category ||
          left[i].name !== right[i].name ||
          left[i].value !== right[i].value ||
          left[i].unit !== right[i].unit
      ) {
        return false;
      }
    }
    return true;
  }

  private updateSignalRow(name: string, value: string): void {
    const index = this.signalRows.findIndex(row => row.name === name);

    if (index === -1 || this.signalRows[index].value === value) {
      return;
    }

    // ✅ ArkTS 兼容写法：手动构造新对象，替代 { ...obj, value }
    const oldRow = this.signalRows[index];
    const newRow: WqSignalRecord = {
      category: oldRow.category,
      name: oldRow.name,
      value: value,
      unit: oldRow.unit
    };

    // ✅ 数组浅拷贝在 ArkTS 中是允许的
    const updated: WqSignalRecord[] = this.signalRows.slice();
    updated[index] = newRow;
    this.signalRows = updated;
  }

  private applySignalRows(absorbance: number | null, temperatures: PhotoTekTemperatureValue | null): void {
    const temperatureUnit = this.temperatureUnit(temperatures);
    const nextRows: WqSignalRecord[] = [
      { category: '测量模块', name: '参考AD', value: this.emptyValue, unit: '' },
      { category: '', name: '测量AD', value: this.emptyValue, unit: '' },
      { category: '', name: '绝对吸光度', value: this.formatNumber(absorbance, 3), unit: 'mAbs' },
      { category: '定量模块', name: '定量点1', value: this.emptyValue, unit: '' },
      { category: '', name: '定量点2', value: this.emptyValue, unit: '' },
      {
        category: '消解器',
        name: '消解温度',
        value: this.formatNumber(temperatures ? temperatures.digestionTemperature : null, 1),
        unit: temperatureUnit
      },
      {
        category: '仪器',
        name: '环境温度',
        value: this.formatNumber(temperatures ? temperatures.ambientTemperature : null, 1),
        unit: temperatureUnit
      }
    ];

    if (!this.areSignalRowsEqual(this.signalRows, nextRows)) {
      this.signalRows = nextRows;
    }
  }

  private applyLatestSnapshots(): void {
    const signal = DeviceStateStore.getSignalSnapshot();
    const temperature = DeviceStateStore.getTemperatureSnapshot();
    this.applySnapshotRows(signal, temperature);
  }

  private applySnapshotRows(signal: SignalSnapshot, temperature: TemperatureSnapshot): void {
    if (this.isSignalPageActive) {
      const absorbance = signal.valid ? signal.waterSampleAbsorbance : null;
      const temperatures = temperature.valid ? temperature.temperatures : null;
      this.applySignalRows(absorbance, temperatures);
    }
  }

  aboutToAppear(): void {
    this.isSignalPageActive = true;
    this.releaseSubscriptions();
    this.applyLatestSnapshots();
    this.unsubscribeSignal = DeviceEventBus.subscribe('signal', (event: DeviceEvent) => {
      this.applySnapshotRows(event.current as SignalSnapshot, DeviceStateStore.getTemperatureSnapshot());
    });
    this.unsubscribeTemperature = DeviceEventBus.subscribe('temperature', (event: DeviceEvent) => {
      this.applySnapshotRows(DeviceStateStore.getSignalSnapshot(), event.current as TemperatureSnapshot);
    });
    this.releaseSignalInterest = DevicePollingCoordinator.registerTopicInterest('signal', 'SignalPage', 'high');
    this.releaseTemperatureInterest =
      DevicePollingCoordinator.registerTopicInterest('temperature', 'SignalPage', 'high');

    // PT63 事件统一由 PT63EventService 管理，避免多个组件重复注册覆盖回调
    this.unsubscribePt63 = PT63EventService.getInstance().subscribe((eventPack: EventPack) => {
      switch (eventPack.type) {
        case 'TEMPERATURE':
          // console.log(`TEMPERATURE : ${eventPack.thermostatTemp}°C, ${eventPack.environmentTemp}°C`);
          this.updateSignalRow('消解温度', this.formatNumber(eventPack.thermostatTemp, 2));
          this.updateSignalRow('环境温度', this.formatNumber(eventPack.environmentTemp, 2));
          break;

        case 'OPTICAL':
          // console.log(`OPTICAL: ${eventPack.reference}, ${eventPack.measure}`);
          this.updateSignalRow('参考AD', eventPack.reference.toString());
          this.updateSignalRow('测量AD', eventPack.measure.toString());
          this.updateSignalRow('绝对吸光度', this.formatNumber(Math.log10(eventPack.reference / eventPack.measure), 2));
          break;

        case 'METER':
          // console.log(`METER ${eventPack.point1}, ${eventPack.point2}`);
          this.updateSignalRow('定量点1', eventPack.point1.toString());
          this.updateSignalRow('定量点2', eventPack.point2.toString());
          break;

        default:
        // 可选：处理未知类型
        // 此时 'event' 的类型会被收窄为 'never'
          console.warn('Unhandled event type:');
      }
    });
  }

  aboutToDisappear(): void {
    this.isSignalPageActive = false;
    this.releaseSubscriptions();
    this.applySignalRows(null, null);
  }

  private releaseSubscriptions(): void {
    if (this.unsubscribeSignal) {
      this.unsubscribeSignal();
      this.unsubscribeSignal = null;
    }
    if (this.unsubscribeTemperature) {
      this.unsubscribeTemperature();
      this.unsubscribeTemperature = null;
    }
    if (this.unsubscribePt63) {
      this.unsubscribePt63();
      this.unsubscribePt63 = null;
    }
    if (this.releaseSignalInterest) {
      this.releaseSignalInterest();
      this.releaseSignalInterest = null;
    }
    if (this.releaseTemperatureInterest) {
      this.releaseTemperatureInterest();
      this.releaseTemperatureInterest = null;
    }
  }

  build() {
    Row() {
      // Left signal section navigation.
      GradientSideTabBar({
        tabs: this.signalTabs,
        selectedTab: this.signalTabs[0],
        viewportWidth: this.viewportWidth,
        viewportHeight: this.viewportHeight,
        scaleFactor: this.scaleFactor
      })

      // Signal table area.
      Column() {
        Row() {
          Text('类别')
            .fontSize(UiUtil.vh(1.7, 11, 15, this.viewportHeight, this.scaleFactor))
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
          Text('名称')
            .fontSize(UiUtil.vh(1.7, 11, 15, this.viewportHeight, this.scaleFactor))
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
          Text('值')
            .fontSize(UiUtil.vh(1.7, 11, 15, this.viewportHeight, this.scaleFactor))
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
          Text('单位')
            .fontSize(UiUtil.vh(1.7, 11, 15, this.viewportHeight, this.scaleFactor))
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1.2)
            .textAlign(TextAlign.Center)
        }
        .height(UiUtil.vh(3.8, 28, 40, this.viewportHeight, this.scaleFactor))
        .backgroundColor('#F0F0F0')
        .border({ width: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor), color: '#DADADA' })

        ForEach(this.signalRows, (item: WqSignalRecord) => {
          Row() {
            Text(item.category)
              .fontSize(UiUtil.vh(1.55, 10, 14, this.viewportHeight, this.scaleFactor))
              .fontWeight(item.category.length > 0 ? FontWeight.Bold : FontWeight.Normal)
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
            Text(item.name)
              .fontSize(UiUtil.vh(1.55, 10, 14, this.viewportHeight, this.scaleFactor))
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
            Text(item.value)
              .fontSize(UiUtil.vh(1.55, 10, 14, this.viewportHeight, this.scaleFactor))
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
            Text(item.unit)
              .fontSize(UiUtil.vh(1.55, 10, 14, this.viewportHeight, this.scaleFactor))
              .layoutWeight(1.2)
              .textAlign(TextAlign.Center)
          }
          .height(UiUtil.vh(4.2, 30, 42, this.viewportHeight, this.scaleFactor))
          .border({ width: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor), color: '#E5E5E5' })
        }, (item: WqSignalRecord) => `${item.name}:${item.value}:${item.unit}`)
      }
      .width(UiUtil.vw(42, 320, 430, this.viewportWidth, this.scaleFactor))
      .alignItems(HorizontalAlign.Start)
      .backgroundColor('#FFFFFF')
      .border({ width: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor), color: '#CCCCCC' })
      .margin({
        left: UiUtil.vw(0.8, 6, 10, this.viewportWidth, this.scaleFactor),
        top: UiUtil.vh(0.8, 6, 10, this.viewportHeight, this.scaleFactor)
      })

      Blank()
    }
    .layoutWeight(1)
    .width('100%')
    .height('100%')
    .alignItems(VerticalAlign.Top)
    .backgroundColor('#F7F7F7')
  }
}
