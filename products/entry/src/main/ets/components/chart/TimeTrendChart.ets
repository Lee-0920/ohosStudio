import { ChartPadding, ChartSeries } from '../../models/ChartTypes';

interface ChartBounds {
  plotLeft: number;
  plotTop: number;
  plotRight: number;
  plotBottom: number;
  plotWidth: number;
  plotHeight: number;
}

@Component
export struct TimeTrendChart {
  @Prop chartWidth: number = 900;
  @Prop chartHeight: number = 520;
  @Watch('onDataChange') @Prop xStartTime: number = 0;
  @Watch('onDataChange') @Prop xEndTime: number = 0;
  @Watch('onDataChange') @Prop yMin: number = 0;
  @Watch('onDataChange') @Prop yMax: number = 15;
  @Watch('onDataChange') @Prop yStep: number = 2;
  @Watch('onDataChange') @Prop series: ChartSeries[] = [];
  @Watch('onDataChange') @Prop xTickIntervalMs: number = 0;
  @Watch('onDataChange') @Prop xTickCount: number = 7;
  @Watch('onDataChange') @Prop showEmptyText: boolean = true;
  @Watch('onDataChange') @Prop emptyText: string = '暂无数据';
  @Watch('onDataChange') @Prop xTickFontSize: number = 12;
  @Watch('onDataChange') @Prop yTickFontSize: number = 13;
  @Watch('onDataChange') @Prop emptyTextFontSize: number = 16;

  private readonly settings: RenderingContextSettings = new RenderingContextSettings(true);
  private readonly context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private isCanvasReady: boolean = false;
  private drawTask: number = -1;

  private onDataChange(_propName: string): void {
    this.scheduleDraw();
  }

  private clamp(value: number, min: number, max: number): number {
    return Math.min(max, Math.max(min, value));
  }

  private getPadding(): ChartPadding {
    const compact = this.chartWidth < 640;
    return {
      left: compact ? 34 : 40,
      right: compact ? 40 : 52,
      top: compact ? 10 : 14,
      bottom: compact ? 52 : 60
    };
  }

  private font(size: number): string {
    const safeSize = this.clamp(size, 8, 40);
    return `${safeSize}px HarmonyOS Sans`;
  }

  private getChartBounds(): ChartBounds {
    const padding = this.getPadding();
    const plotLeft = padding.left;
    const plotTop = padding.top;
    const plotRight = this.chartWidth - padding.right;
    const plotBottom = this.chartHeight - padding.bottom;
    return {
      plotLeft,
      plotTop,
      plotRight,
      plotBottom,
      plotWidth: Math.max(1, plotRight - plotLeft),
      plotHeight: Math.max(1, plotBottom - plotTop)
    };
  }

  private scheduleDraw(): void {
    if (!this.isCanvasReady) {
      return;
    }
    if (this.drawTask !== -1) {
      clearTimeout(this.drawTask);
    }
    this.drawTask = setTimeout(() => {
      this.drawTask = -1;
      this.drawChart();
    }, 0);
  }

  aboutToAppear(): void {
    this.scheduleDraw();
  }

  onDidBuild(): void {
    this.scheduleDraw();
  }

  aboutToDisappear(): void {
    if (this.drawTask !== -1) {
      clearTimeout(this.drawTask);
      this.drawTask = -1;
    }
  }

  private mapTimeToX(time: number, bounds: ChartBounds): number {
    const range = this.xEndTime - this.xStartTime;
    if (range <= 0) {
      return bounds.plotLeft;
    }
    const ratio = (time - this.xStartTime) / range;
    return bounds.plotLeft + ratio * bounds.plotWidth;
  }

  private mapValueToY(value: number, bounds: ChartBounds): number {
    const range = this.yMax - this.yMin;
    if (range <= 0) {
      return bounds.plotBottom;
    }
    const ratio = (value - this.yMin) / range;
    return bounds.plotBottom - ratio * bounds.plotHeight;
  }

  private formatDateTime(time: number): string {
    const date = new Date(time);
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    return `${year}-${month}-${day} ${hours}:${minutes}`;
  }

  private buildXTicks(): number[] {
    const ticks: number[] = [];
    if (this.xEndTime <= this.xStartTime) {
      ticks.push(this.xStartTime);
      return ticks;
    }

    if (this.xTickIntervalMs > 0) {
      let cursor = this.xStartTime;
      while (cursor <= this.xEndTime) {
        ticks.push(cursor);
        cursor += this.xTickIntervalMs;
      }
      if (ticks[ticks.length - 1] !== this.xEndTime) {
        ticks.push(this.xEndTime);
      }
      return ticks;
    }

    const count = this.clamp(this.xTickCount, 6, 8);
    const interval = (this.xEndTime - this.xStartTime) / (count - 1);
    for (let i = 0; i < count; i++) {
      ticks.push(Math.round(this.xStartTime + i * interval));
    }
    return ticks;
  }

  private buildYTicks(): number[] {
    const ticks: number[] = [];
    const safeStep = this.yStep > 0 ? this.yStep : 1;
    for (let value = this.yMin; value <= this.yMax; value += safeStep) {
      ticks.push(Number(value.toFixed(6)));
    }
    if (ticks.length === 0 || ticks[ticks.length - 1] !== this.yMax) {
      ticks.push(this.yMax);
    }
    return ticks;
  }

  private drawBackground(bounds: ChartBounds): void {
    this.context.fillStyle = '#FFFFFF';
    this.context.fillRect(0, 0, this.chartWidth, this.chartHeight);
  }

  private drawDashedHorizontalLine(y: number, bounds: ChartBounds): void {
    const dash = 6;
    const gap = 6;
    let x = bounds.plotLeft;
    this.context.strokeStyle = '#E6E6E6';
    this.context.lineWidth = 1;
    while (x < bounds.plotRight) {
      const segmentEnd = Math.min(bounds.plotRight, x + dash);
      this.context.beginPath();
      this.context.moveTo(x, y);
      this.context.lineTo(segmentEnd, y);
      this.context.stroke();
      x += dash + gap;
    }
  }

  private drawGrid(bounds: ChartBounds, yTicks: number[]): void {
    yTicks.forEach((tick: number) => {
      const y = this.mapValueToY(tick, bounds);
      this.drawDashedHorizontalLine(y, bounds);
    });
  }

  private drawAxes(bounds: ChartBounds): void {
    this.context.strokeStyle = '#BFBFBF';
    this.context.lineWidth = 1.2;
    this.context.beginPath();
    this.context.moveTo(bounds.plotLeft, bounds.plotTop);
    this.context.lineTo(bounds.plotLeft, bounds.plotBottom);
    this.context.lineTo(bounds.plotRight, bounds.plotBottom);
    this.context.stroke();
  }

  private drawYTicks(bounds: ChartBounds, yTicks: number[]): void {
    this.context.fillStyle = '#666666';
    this.context.font = this.font(this.yTickFontSize);
    this.context.textAlign = 'right';
    this.context.textBaseline = 'middle';

    yTicks.forEach((tick: number) => {
      const y = this.mapValueToY(tick, bounds);
      this.context.fillText(`${tick}`, bounds.plotLeft - 8, y);
      this.context.beginPath();
      this.context.strokeStyle = '#BFBFBF';
      this.context.moveTo(bounds.plotLeft - 4, y);
      this.context.lineTo(bounds.plotLeft, y);
      this.context.stroke();
    });
  }

  private drawXTicks(bounds: ChartBounds, xTicks: number[]): void {
    this.context.fillStyle = '#666666';
    this.context.font = this.font(this.xTickFontSize);
    this.context.textAlign = 'center';
    this.context.textBaseline = 'top';

    xTicks.forEach((tick: number) => {
      const x = this.mapTimeToX(tick, bounds);
      this.context.beginPath();
      this.context.strokeStyle = '#BFBFBF';
      this.context.moveTo(x, bounds.plotBottom);
      this.context.lineTo(x, bounds.plotBottom + 4);
      this.context.stroke();

      const dateTimeParts = this.formatDateTime(tick).split(' ');
      const datePart = dateTimeParts.length > 0 ? dateTimeParts[0] : '';
      const timePart = dateTimeParts.length > 1 ? dateTimeParts[1] : '';
      this.context.save();
      this.context.translate(x, bounds.plotBottom + 10);
      this.context.rotate(-Math.PI / 6);
      this.context.fillText(datePart, 0, 0);
      this.context.fillText(timePart, 0, 14);
      this.context.restore();
    });
  }

  private drawSeries(bounds: ChartBounds): void {
    this.series.forEach((line: ChartSeries) => {
      const visiblePoints = line.points
        .filter((point) => point.time >= this.xStartTime && point.time <= this.xEndTime)
        .sort((a, b) => a.time - b.time);
      if (visiblePoints.length <= 0) {
        return;
      }

      this.context.strokeStyle = line.color;
      this.context.lineWidth = 2;
      this.context.beginPath();

      visiblePoints.forEach((point, index) => {
        const x = this.mapTimeToX(point.time, bounds);
        const y = this.mapValueToY(point.value, bounds);
        if (index === 0) {
          this.context.moveTo(x, y);
        } else {
          this.context.lineTo(x, y);
        }
      });
      this.context.stroke();

      visiblePoints.forEach((point) => {
        const x = this.mapTimeToX(point.time, bounds);
        const y = this.mapValueToY(point.value, bounds);
        this.context.fillStyle = line.color;
        this.context.beginPath();
        this.context.arc(x, y, 2.5, 0, Math.PI * 2);
        this.context.fill();
      });
    });
  }

  private drawEmptyText(bounds: ChartBounds): void {
    if (!this.showEmptyText) {
      return;
    }
    const hasData = this.series.some((line: ChartSeries) => line.points.length > 0);
    if (hasData) {
      return;
    }
    this.context.fillStyle = '#A6A6A6';
    this.context.font = this.font(this.emptyTextFontSize);
    this.context.textAlign = 'center';
    this.context.textBaseline = 'middle';
    this.context.fillText(this.emptyText, bounds.plotLeft + bounds.plotWidth / 2, bounds.plotTop + bounds.plotHeight / 2);
  }

  private drawChart(): void {
    const width = Math.max(1, this.chartWidth);
    const height = Math.max(1, this.chartHeight);
    this.context.clearRect(0, 0, width, height);

    const bounds = this.getChartBounds();
    const yTicks = this.buildYTicks();
    const xTicks = this.buildXTicks();

    this.drawBackground(bounds);
    this.drawGrid(bounds, yTicks);
    this.drawAxes(bounds);
    this.drawYTicks(bounds, yTicks);
    this.drawXTicks(bounds, xTicks);
    this.drawSeries(bounds);
    this.drawEmptyText(bounds);
  }

  build() {
    Canvas(this.context)
      .width(this.chartWidth)
      .height(this.chartHeight)
      .backgroundColor('transparent')
      .onReady(() => {
        this.isCanvasReady = true;
        this.scheduleDraw();
      })
      .onAreaChange(() => {
        this.scheduleDraw();
      });
  }
}
