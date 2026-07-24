import { common } from '@kit.AbilityKit';
import { UiUtil } from 'base';
import { SettingsManager, CurveParam } from 'dataservice';

interface RangeInfoItem {
  rangeLabel: string;
  calibrationTime: string;
  zeroConcentration: number;
  spanConcentration: number;
  slope: number;
  intercept: number;
}

@Component
export struct RangeInfoPanel {
  @Prop tab: string = '';
  @Prop viewportWidth: number = 1024;
  @Prop viewportHeight: number = 768;
  @Prop scaleFactor: number = 1.92;
  @State private records: RangeInfoItem[] = [];
  @State private isLoading: boolean = false;

  // Range labels are kept unchanged; other columns are filled from MeasureParamConfig.curveParam.
  private readonly rangeLabels: string[] = ['0-100', '0-200', '0-1000', '0-2000', '0-5000', '0-10000', '0-20000'];

  async aboutToAppear(): Promise<void> {
    await this.loadRangeInfo();
  }

  private async loadRangeInfo(): Promise<void> {
    if (this.isLoading) {
      return;
    }
    this.isLoading = true;
    try {
      const settingsManager = SettingsManager.getInstance();
      const measureParamConfig = await settingsManager.getMeasureParamConfig();
      if (measureParamConfig)
      {
        const curveParams = measureParamConfig?.curveParam ?? [];
        this.records = this.buildRecords(curveParams);
      }
    } catch (err) {
      console.error('量程信息加载失败:', err);
      this.records = this.buildRecords([]);
    } finally {
      this.isLoading = false;
    }
  }

  private buildRecords(curveParams: CurveParam[]): RangeInfoItem[] {
    return this.rangeLabels.map((rangeLabel: string, index: number): RangeInfoItem => {
      const param = curveParams[index];
      return {
        rangeLabel: rangeLabel,
        calibrationTime: param?.timeStr ?? '--',
        zeroConcentration: param?.zeroConsistency ?? 0,
        spanConcentration: param?.rangeConsistency ?? 0,
        slope: param?.curveK ?? 0,
        intercept: param?.curveB ?? 0
      };
    });
  }

  private formatNumber(value: number): string {
    const fixed = value.toFixed(3);
    const trimmed = fixed.replace(/0+$/, '').replace(/\.$/, '');
    return trimmed.indexOf('.') >= 0 ? trimmed : `${trimmed}.0`;
  }

  build() {
    Column() {
      Column() {
        // Table header.
        Row() {
          Text('量程')
            .fontSize(UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor))
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1.0)
            .textAlign(TextAlign.Center)
          Text('校准时间')
            .fontSize(UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor))
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1.45)
            .textAlign(TextAlign.Center)
          Text('零点浓度')
            .fontSize(UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor))
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1.0)
            .textAlign(TextAlign.Center)
          Text('标点浓度')
            .fontSize(UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor))
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1.0)
            .textAlign(TextAlign.Center)
          Text('K')
            .fontSize(UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor))
            .fontWeight(FontWeight.Bold)
            .layoutWeight(0.8)
            .textAlign(TextAlign.Center)
          Text('B')
            .fontSize(UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor))
            .fontWeight(FontWeight.Bold)
            .layoutWeight(0.8)
            .textAlign(TextAlign.Center)
        }
        .height(UiUtil.vh(4.8, 36, 52, this.viewportHeight, this.scaleFactor))
        .backgroundColor('#F0F0F0')
        .border({ width: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor), color: '#DADADA' })

        // Table rows.
        ForEach(this.records, (item: RangeInfoItem) => {
          Row() {
            Text(item.rangeLabel)
              .fontSize(UiUtil.vh(1.8, 11, 15, this.viewportHeight, this.scaleFactor))
              .layoutWeight(1.0)
              .textAlign(TextAlign.Center)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(item.calibrationTime)
              .fontSize(UiUtil.vh(1.65, 11, 14, this.viewportHeight, this.scaleFactor))
              .layoutWeight(1.45)
              .textAlign(TextAlign.Center)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(this.formatNumber(item.zeroConcentration))
              .fontSize(UiUtil.vh(1.8, 11, 15, this.viewportHeight, this.scaleFactor))
              .layoutWeight(1.0)
              .textAlign(TextAlign.Center)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(this.formatNumber(item.spanConcentration))
              .fontSize(UiUtil.vh(1.8, 11, 15, this.viewportHeight, this.scaleFactor))
              .layoutWeight(1.0)
              .textAlign(TextAlign.Center)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(this.formatNumber(item.slope))
              .fontSize(UiUtil.vh(1.8, 11, 15, this.viewportHeight, this.scaleFactor))
              .layoutWeight(0.8)
              .textAlign(TextAlign.Center)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(this.formatNumber(item.intercept))
              .fontSize(UiUtil.vh(1.8, 11, 15, this.viewportHeight, this.scaleFactor))
              .layoutWeight(0.8)
              .textAlign(TextAlign.Center)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .height(UiUtil.vh(4.5, 34, 50, this.viewportHeight, this.scaleFactor))
          .backgroundColor('#FFFFFF')
          .border({ width: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor), color: '#E5E5E5' })
        }, (item: RangeInfoItem) => item.rangeLabel)
      }
      .layoutWeight(1)
      .height('100%')
      .clip(true)
      .border({ width: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor), color: '#CCCCCC' })

      Text(`共 ${this.records.length} 条`)
        .fontSize(UiUtil.vh(1.45, 10, 13, this.viewportHeight, this.scaleFactor))
        .fontColor('#7A818A')
        .width('100%')
        .textAlign(TextAlign.End)
        .margin({
          top: UiUtil.vh(0.5, 3, 6, this.viewportHeight, this.scaleFactor),
          right: UiUtil.vw(0.2, 2, 4, this.viewportWidth, this.scaleFactor)
        })
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .padding({
      left: UiUtil.vw(0.8, 6, 10, this.viewportWidth, this.scaleFactor),
      right: UiUtil.vw(0.8, 6, 10, this.viewportWidth, this.scaleFactor),
      top: UiUtil.vh(0.8, 6, 10, this.viewportHeight, this.scaleFactor),
      bottom: UiUtil.vh(0.8, 6, 10, this.viewportHeight, this.scaleFactor)
    })
    .backgroundColor('#FFFFFF')
  }
}
