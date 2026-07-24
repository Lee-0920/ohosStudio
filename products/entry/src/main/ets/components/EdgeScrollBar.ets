@Component
export struct EdgeScrollBar {
  @Prop viewportLength: number = 0;
  @Prop contentLength: number = 0;
  @Prop currentOffset: number = 0;
  @Prop widthValue: number = 3;
  @Prop minThumbLength: number = 24;
  @Prop trackColor: ResourceColor = '#E6E6E6';
  @Prop thumbColor: ResourceColor = '#8A8A8A';

  private clamp(value: number, min: number, max: number): number {
    return Math.min(max, Math.max(min, value));
  }

  private hasScrollableContent(): boolean {
    return this.viewportLength > 0 && this.contentLength > this.viewportLength + 1;
  }

  private getThumbLength(): number {
    if (!this.hasScrollableContent()) {
      return 0;
    }
    const raw = (this.viewportLength * this.viewportLength) / this.contentLength;
    return this.clamp(raw, this.minThumbLength, this.viewportLength);
  }

  private getThumbOffset(): number {
    if (!this.hasScrollableContent()) {
      return 0;
    }
    const scrollableLength = this.contentLength - this.viewportLength;
    const thumbMovableLength = this.viewportLength - this.getThumbLength();
    if (scrollableLength <= 0 || thumbMovableLength <= 0) {
      return 0;
    }
    return this.clamp((this.currentOffset / scrollableLength) * thumbMovableLength, 0, thumbMovableLength);
  }

  build() {
    if (this.hasScrollableContent()) {
      Stack({ alignContent: Alignment.Top }) {
        Column() {}
          .width(this.widthValue)
          .height('100%')
          .backgroundColor(this.trackColor)

        Column() {}
          .width(this.widthValue)
          .height(this.getThumbLength())
          .backgroundColor(this.thumbColor)
          .borderRadius(this.widthValue / 2)
          .offset({ y: this.getThumbOffset() })
      }
      .width(this.widthValue)
      .height('100%')
    }
  }
}
