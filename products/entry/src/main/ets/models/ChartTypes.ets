export interface ChartPoint {
  time: number;
  value: number;
}

export interface ChartSeries {
  name: string;
  color: string;
  points: ChartPoint[];
}

export interface ChartPadding {
  left: number;
  right: number;
  top: number;
  bottom: number;
}
