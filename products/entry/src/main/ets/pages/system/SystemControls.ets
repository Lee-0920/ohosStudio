import { DataActionButton } from '../../components/DataActionButton';

@Component
export struct SystemHeaderCell {
  @Prop label: string = '';
  @Prop weight: number = 1;
  @Prop fontSizeValue: number = 14;

  build() {
    Text(this.label)
      .height('100%')
      .fontSize(this.fontSizeValue)
      .fontWeight(FontWeight.Bold)
      .fontColor('#222222')
      .textAlign(TextAlign.Center)
      .layoutWeight(this.weight)
  }
}

@Component
export struct SystemTextCell {
  @Prop label: string = '';
  @Prop weight: number = 1;
  @Prop fontSizeValue: number = 14;
  @Prop bold: boolean = false;

  build() {
    Text(this.label)
      .height('100%')
      .fontSize(this.fontSizeValue)
      .fontWeight(this.bold ? FontWeight.Bold : FontWeight.Normal)
      .fontColor('#222222')
      .textAlign(TextAlign.Center)
      .maxLines(2)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .layoutWeight(this.weight)
  }
}

@Component
export struct SystemValueInput {
  @Prop textValue: string = '';
  @Prop placeholderValue: string = '';
  @Prop inputWidth: number = 120;
  @Prop inputHeight: number = 36;
  @Prop fontSizeValue: number = 14;
  @Prop borderRadiusValue: number = 4;

  onValueChange: (value: string) => void = () => {};

  build() {
    TextInput({ text: this.textValue, placeholder: this.placeholderValue })
      .height(this.inputHeight)
      .width(this.inputWidth)
      .fontSize(this.fontSizeValue)
      .textAlign(TextAlign.Center)
      .backgroundColor('#FFFFFF')
      .border({ width: 1, color: '#8BC2FF' })
      .borderRadius(this.borderRadiusValue)
      .onChange((value: string) => {
        this.onValueChange(value);
      })
  }
}

@Component
export struct SystemRadioMark {
  @Prop selected: boolean = false;
  @Prop outerSize: number = 28;
  @Prop innerSize: number = 12;
  @Prop borderWidthValue: number = 2;

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column() {}
        .width(this.outerSize)
        .height(this.outerSize)
        .backgroundColor('#FFFFFF')
        .border({ width: this.borderWidthValue, color: '#333A46' })
        .borderRadius(this.outerSize / 2)

      if (this.selected) {
        Column() {}
          .width(this.innerSize)
          .height(this.innerSize)
          .backgroundColor('#333A46')
          .borderRadius(this.innerSize / 2)
      }
    }
    .width(this.outerSize + 2)
    .height(this.outerSize + 2)
  }
}

@Component
export struct SystemActionButton {
  @Prop label: string = '';
  @Prop buttonWidth: number = 100;
  @Prop buttonHeight: number = 42;
  @Prop fontSizeValue: number = 14;
  @Prop borderRadiusValue: number = 8;

  onAction: () => void = () => {};

  build() {
    DataActionButton({
      label: this.label,
      buttonWidth: this.buttonWidth,
      buttonHeight: this.buttonHeight,
      fontSizeValue: this.fontSizeValue,
      borderRadiusValue: this.borderRadiusValue,
      onAction: () => {
        this.onAction();
      }
    })
  }
}
