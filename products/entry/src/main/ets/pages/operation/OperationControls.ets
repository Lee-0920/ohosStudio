import { DataActionButton } from '../../components/DataActionButton';
import { OPERATION_LOG_TYPE_MAINTENANCE } from '../../models/dataRecordTypes';
import { OperationLogService } from '../../services/OperationLogService';

function recordOperationButton(label: string): void {
  const action = label.trim();
  if (action.length === 0) {
    return;
  }
  void OperationLogService.record({
    logType: OPERATION_LOG_TYPE_MAINTENANCE,
    action: action,
    content: action,
    source: 'operation_page'
  });
}

@Component
export struct OperationHeaderCell {
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
export struct OperationTextCell {
  @Prop label: string = '';
  @Prop weight: number = 1;
  @Prop fontSizeValue: number = 14;
  @Prop fontColorValue: ResourceColor = '#222222';

  build() {
    Text(this.label)
      .height('100%')
      .fontSize(this.fontSizeValue)
      .fontColor(this.fontColorValue)
      .textAlign(TextAlign.Center)
      .maxLines(2)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .layoutWeight(this.weight)
  }
}

@Component
export struct OperationInputCell {
  @Prop textValue: string = '';
  @Prop weight: number = 1;
  @Prop inputHeight: number = 36;
  @Prop fontSizeValue: number = 14;
  @Prop borderRadiusValue: number = 4;

  onValueChange: (value: string) => void = () => {};

  build() {
    Row() {
      TextInput({ text: this.textValue })
        .height(this.inputHeight)
        .width('88%')
        .fontSize(this.fontSizeValue)
        .textAlign(TextAlign.Center)
        .backgroundColor('#FFFFFF')
        .border({ width: 1, color: '#E2E2E2' })
        .borderRadius(this.borderRadiusValue)
        .onChange((value: string) => {
          this.onValueChange(value);
        })
    }
    .height('100%')
    .layoutWeight(this.weight)
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
}

@Component
export struct OperationBlueButton {
  @Prop label: string = '';
  @Prop buttonWidth: number = 80;
  @Prop buttonHeight: number = 40;
  @Prop fontSizeValue: number = 14;
  @Prop borderRadiusValue: number = 8;
  @Prop recordAction: boolean = true;

  onAction: () => void = () => {};

  build() {
    DataActionButton({
      label: this.label,
      buttonWidth: this.buttonWidth,
      buttonHeight: this.buttonHeight,
      fontSizeValue: this.fontSizeValue,
      borderRadiusValue: this.borderRadiusValue,
      onAction: () => {
        if (this.recordAction) {
          recordOperationButton(this.label);
        }
        this.onAction();
      }
    })
  }
}

@Component
export struct OperationSolidButton {
  @Prop label: string = '';
  @Prop buttonWidth: number = 80;
  @Prop buttonHeight: number = 40;
  @Prop fontSizeValue: number = 14;
  @Prop borderRadiusValue: number = 8;
  @Prop recordAction: boolean = true;

  onAction: () => void = () => {};

  build() {
    if (this.label === '停止') {
      Stack({ alignContent: Alignment.Center }) {
        Text(this.label)
          .width('100%')
          .fontSize(this.fontSizeValue)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FF4444')
          .textAlign(TextAlign.Center)
          .maxLines(1)
      }
      .width(this.buttonWidth)
      .height(this.buttonHeight)
      .backgroundColor('#FFFFFF')
      .borderRadius(this.borderRadiusValue)
      .border({ width: 1, color: '#FF4444' })
      .onClick(() => {
        if (this.recordAction) {
          recordOperationButton(this.label);
        }
        this.onAction();
      })
    } else {
      DataActionButton({
        label: this.label,
        buttonWidth: this.buttonWidth,
        buttonHeight: this.buttonHeight,
        fontSizeValue: this.fontSizeValue,
        borderRadiusValue: this.borderRadiusValue,
        onAction: () => {
          if (this.recordAction) {
            recordOperationButton(this.label);
          }
          this.onAction();
        }
      })
    }
  }
}

@Component
export struct OperationCheckCell {
  @Prop selected: boolean = false;
  @Prop weight: number = 1;
  @Prop boxSize: number = 32;
  @Prop markSize: number = 20;
  @Prop borderWidthValue: number = 2;
  @Prop borderRadiusValue: number = 4;

  onAction: () => void = () => {};

  build() {
    Row() {
      Stack({ alignContent: Alignment.Center }) {
        if (this.selected) {
          Text('√')
            .fontSize(this.markSize)
            .fontWeight(FontWeight.Bold)
            .fontColor('#0FA85D')
            .textAlign(TextAlign.Center)
        }
      }
      .width(this.boxSize)
      .height(this.boxSize)
      .border({ width: this.borderWidthValue, color: '#111111' })
      .borderRadius(this.borderRadiusValue)
      .backgroundColor('#FFFFFF')
      .onClick(() => {
        this.onAction();
      })
    }
    .height('100%')
    .layoutWeight(this.weight)
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
}

@Component
export struct OperationEmptyTableRow {
  @Prop weights: number[] = [];
  @Prop rowHeight: number = 40;
  @Prop borderWidthValue: number = 1;

  build() {
    Row() {
      ForEach(this.weights, (weight: number, index: number) => {
        Text('')
          .layoutWeight(weight)
      }, (_weight: number, index: number) => `${index}`)
    }
    .height(this.rowHeight)
    .border({ width: this.borderWidthValue, color: '#E5E5E5' })
  }
}
