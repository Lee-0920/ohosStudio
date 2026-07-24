import {
  OperationBlueButton,
  OperationHeaderCell,
  OperationInputCell,
  OperationSolidButton
} from './OperationControls';
import { updateOperationRowValue, WqOperationConfigRow } from './OperationTypes';
import { WorkerManager, PipeOperationParams, liquidTypes, LiquidTypes } from 'flow';
import { UiUtil } from 'base';
import { RollDirection } from 'communication';

@Component
export struct PipeOperationPanel {
  @Link selectedPipeMode: string;
  @Link pipeRows: WqOperationConfigRow[];
  @Link operationMessage: string;
  @Prop viewportWidth: number = 1024;
  @Prop viewportHeight: number = 768;
  @Prop scaleFactor: number = 1.92;
  onRowsChange: (rows: WqOperationConfigRow[]) => void = (_rows: WqOperationConfigRow[]) => {
  };
  onModeChange: (value: string) => void = (_value: string) => {
  };
  onMessageChange: (value: string) => void = (_value: string) => {
  };
  private readonly pipeModeOptions: SelectOption[] = [
    { value: '泵计步定量' },
    { value: '精确定量' },
    { value: '光学定量' }
  ];

  private updatePipeVolume(rowId: string, value: string): void {
    const rows = updateOperationRowValue(this.pipeRows, rowId, 'value', value);
    this.pipeRows = rows;
    this.onRowsChange(rows);
  }

  /**
   * 从行数据中安全提取管道操作参数
   */
  private buildPipeParams(row: WqOperationConfigRow): PipeOperationParams | null {
    const volume = parseFloat(row.value);
    console.info(`buildPipeParams ${row}`);
    if (isNaN(volume) || volume <= 0) return null;

    const dirMap: Record<string, RollDirection> = {
      'in': RollDirection.Suck,
      'out': RollDirection.Drain,
    };

    const dir = dirMap[row.value3];

    return {
      liquidName: row.value2,
      dir,
      mode: this.selectedPipeMode,
      volume
    };
  }

  private markPipeOperationTodo(rowName: string, params: PipeOperationParams): void {
    console.info(`TLQQ, markPipeOperationTodo postMessage `);
    let postText: string =  'pipeOperator';
    if (rowName == '停止管道操作'){
      postText = 'stop';
    }

    WorkerManager.getInstance().postMessage({
      type: postText,
      data: {
        liquidName: params.liquidName,
        dir: params.dir,
        volume: params.volume,
        mode: params.mode,
      },
      timeStamp: Date.now()
    });
    // TODO: 当前协议只暴露了管道动作码读取，尚无“管道操作 + 体积 + 定量方式”的可写 API。
    const message = `${rowName} 暂未接入设备控制`;
    this.operationMessage = message;
    this.onMessageChange(message);
  }

  build() {
    Row() {
      Column() {
        Row() {
          OperationHeaderCell({
            label: '操作',
            weight: 2.6,
            fontSizeValue: UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor)
          });
          OperationHeaderCell({
            label: '体积(ml)',
            weight: 1.0,
            fontSizeValue: UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor)
          });
        }
        .height(UiUtil.vh(4.8, 36, 52, this.viewportHeight, this.scaleFactor))
        .backgroundColor('#F0F0F0')
        .border({ width: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor), color: '#DADADA' })

        ForEach(this.pipeRows, (row: WqOperationConfigRow) => {
          Row() {
            Row() {
              OperationBlueButton({
                label: row.name,
                buttonWidth: UiUtil.vw(22.0, 170, 240, this.viewportWidth, this.scaleFactor),
                buttonHeight: UiUtil.vh(4.0, 30, 44, this.viewportHeight, this.scaleFactor),
                fontSizeValue: UiUtil.vh(1.85, 11, 15, this.viewportHeight, this.scaleFactor),
                borderRadiusValue: UiUtil.vh(0.7, 4, 8, this.viewportHeight, this.scaleFactor),
                onAction: () => {
                  const params = this.buildPipeParams(row);
                  if (params === null) {
                    const errMsg = `${row.name} 参数无效，请检查体积/类型/方向配置`;
                    this.operationMessage = errMsg;
                    this.onMessageChange(errMsg);
                    return;
                  }
                  this.markPipeOperationTodo(row.name, params);
                }
              })
            }
            .layoutWeight(2.6)
            .justifyContent(FlexAlign.Center)

            OperationInputCell({
              textValue: row.value,
              weight: 1.0,
              inputHeight: UiUtil.vh(3.7, 28, 40, this.viewportHeight, this.scaleFactor),
              fontSizeValue: UiUtil.vh(1.75, 11, 15, this.viewportHeight, this.scaleFactor),
              borderRadiusValue: UiUtil.vh(0.35, 2, 4, this.viewportHeight, this.scaleFactor),
              onValueChange: (value: string) => {
                this.updatePipeVolume(row.id, value);
              }
            })
          }
          .height(UiUtil.vh(5.0, 38, 54, this.viewportHeight, this.scaleFactor))
          .border({ width: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor), color: '#E5E5E5' })
        }, (row: WqOperationConfigRow) => `${row.id}-${row.value}-${row.status}-${row.result}`)
      }
      .layoutWeight(1)
      .height('100%')
      .clip(true)
      .border({ width: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor), color: '#CCCCCC' })

      Column() {
        Text('操作方式')
          .fontSize(UiUtil.vh(2.0, 12, 18, this.viewportHeight, this.scaleFactor))
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: UiUtil.vh(1.2, 8, 14, this.viewportHeight, this.scaleFactor) })

        Select(this.pipeModeOptions)
          .value(this.selectedPipeMode)
          .height(UiUtil.vh(4.4, 34, 46, this.viewportHeight, this.scaleFactor))
          .width(UiUtil.vw(13.0, 108, 150, this.viewportWidth, this.scaleFactor))
          .onSelect((_index: number, value?: string) => {
            const selected = value ? value : '精确定量';
            this.selectedPipeMode = selected;
            this.onModeChange(selected);
          })

        Blank()

        OperationSolidButton({
          label: '停止',
          buttonWidth: UiUtil.vw(9.0, 80, 108, this.viewportWidth, this.scaleFactor),
          buttonHeight: UiUtil.vh(4.4, 34, 48, this.viewportHeight, this.scaleFactor),
          fontSizeValue: UiUtil.vh(1.85, 11, 15, this.viewportHeight, this.scaleFactor),
          borderRadiusValue: UiUtil.vh(0.7, 4, 8, this.viewportHeight, this.scaleFactor),
          onAction: () => {
            const params = this.buildPipeParams(this.pipeRows[0]);
            if (params === null) {
              return;
            }
            this.markPipeOperationTodo('停止管道操作', params);
          }
        })
        Text(this.operationMessage)
          .fontSize(UiUtil.vh(1.55, 10, 13, this.viewportHeight, this.scaleFactor))
          .fontColor('#F01010')
          .textAlign(TextAlign.Center)
          .maxLines(3)
          .margin({ top: UiUtil.vh(1.4, 8, 14, this.viewportHeight, this.scaleFactor) })
      }
      .width(UiUtil.vw(18.0, 142, 200, this.viewportWidth, this.scaleFactor))
      .height('100%')
      .alignItems(HorizontalAlign.Center)
      .padding({
        left: UiUtil.vw(1.2, 10, 16, this.viewportWidth, this.scaleFactor),
        top: UiUtil.vh(8.0, 58, 82, this.viewportHeight, this.scaleFactor),
        bottom: UiUtil.vh(2.0, 12, 20, this.viewportHeight, this.scaleFactor)
      })
    }
    .layoutWeight(1)
    .height('100%')
    .padding({
      left: UiUtil.vw(0.8, 6, 10, this.viewportWidth, this.scaleFactor),
      right: UiUtil.vw(0.8, 6, 10, this.viewportWidth, this.scaleFactor),
      top: UiUtil.vh(0.8, 6, 10, this.viewportHeight, this.scaleFactor),
      bottom: UiUtil.vh(0.8, 6, 10, this.viewportHeight, this.scaleFactor)
    })
    .backgroundColor('#FFFFFF')
  }
}
