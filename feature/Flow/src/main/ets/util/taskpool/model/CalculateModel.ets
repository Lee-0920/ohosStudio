export class CalculateModel {
  private name: string = '';
  private intervalPeriod: number = -1;
  private timePointSet: string = '';
  private intervalTime: number = -1;

  public getName(): string {
    return this.name;
  }

  public setName(value: string): void {
    this.name = value;
  }


  public getIntervalPeriod(): number {
    return this.intervalPeriod;
  }

  public setIntervalPeriod(value: number): void {
    this.intervalPeriod = value;
  }

  public getTimePointSet(): string {
    return this.timePointSet;
  }

  public setTimePointSet(value: string): void {
    this.timePointSet = value;
  }

  public getIntervalTime(): number {
    return this.intervalTime;
  }

  public setIntervalTime(value: number): void {
    this.intervalTime = value;
  }
}