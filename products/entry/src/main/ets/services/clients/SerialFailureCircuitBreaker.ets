export class SerialFailureCircuitBreaker {
  private readonly threshold: number;
  private failureCount: number = 0;

  constructor(threshold: number = 3) {
    this.threshold = Math.max(1, Math.floor(threshold));
  }

  recordSuccess(): void {
    this.failureCount = 0;
  }

  recordFailure(): boolean {
    this.failureCount++;
    return this.failureCount >= this.threshold;
  }

  reset(): void {
    this.failureCount = 0;
  }

  getFailureCount(): number {
    return this.failureCount;
  }
}
