import { UiUtil } from 'base';
import { DataActionButton } from '../DataActionButton';
import { CalendarPickerPanel } from './CalendarPickerPanel';

@Component
export struct DateRangeFilterBar {
  @Link startDate: string;
  @Link endDate: string;
  @Link selectedType: string;
  @Prop typeLabel: string = '类型';
  @Prop typeOptions: SelectOption[] = [];
  @Prop showTypeFilter: boolean = true;
  @Prop viewportWidth: number = 1024;
  @Prop viewportHeight: number = 768;
  @Prop scaleFactor: number = 1.92;
  @State private activePicker: string = '';
  onQuery: () => void = () => {
  };

  private togglePicker(name: string): void {
    this.activePicker = this.activePicker === name ? '' : name;
  }

  @Builder
  private dateField(name: string) {
    Text(name === 'start' ? this.startDate : this.endDate)
      .height(UiUtil.vh(4.1, 30, 42, this.viewportHeight, this.scaleFactor))
      .width(UiUtil.vw(11.4, 86, 128, this.viewportWidth, this.scaleFactor))
      .fontSize(UiUtil.vh(1.45, 11, 15, this.viewportHeight, this.scaleFactor))
      .fontColor('#222222')
      .textAlign(TextAlign.Center)
      .border({
        width: UiUtil.vh(0.1, 1, 2, this.viewportHeight, this.scaleFactor),
        color: this.activePicker === name ? '#0B9F9A' : '#0A6BFF'
      })
      .borderRadius(UiUtil.vh(0.55, 3, 6, this.viewportHeight, this.scaleFactor))
      .backgroundColor(this.activePicker === name ? '#F1FFFE' : '#FFFFFF')
      .onClick(() => {
        this.togglePicker(name);
      })
  }

  build() {
    Column() {
      this.calendarPanel()
      Row() {
        this.dateField('start');
        Text('-')
          .fontSize(UiUtil.vh(1.6, 12, 16, this.viewportHeight, this.scaleFactor))
          .margin({
            left: UiUtil.vw(0.35, 3, 6, this.viewportWidth, this.scaleFactor),
            right: UiUtil.vw(0.35, 3, 6, this.viewportWidth, this.scaleFactor)
          })
        this.dateField('end');

        if (this.showTypeFilter) {
          Text(this.typeLabel)
            .fontSize(UiUtil.vh(1.55, 12, 17, this.viewportHeight, this.scaleFactor))
            .fontWeight(FontWeight.Bold)
            .margin({
              left: UiUtil.vw(0.8, 6, 10, this.viewportWidth, this.scaleFactor),
              right: UiUtil.vw(0.35, 3, 6, this.viewportWidth, this.scaleFactor)
            })
          Select(this.typeOptions)
            .value(this.selectedType)
            .height(UiUtil.vh(4.1, 30, 42, this.viewportHeight, this.scaleFactor))
            .width(UiUtil.vw(10.6, 86, 126, this.viewportWidth, this.scaleFactor))
            .onSelect((_index: number, value?: string) => {
              this.selectedType = value ? value : this.selectedType;
            })
        }

        Blank()

        DataActionButton({
          label: '查询',
          buttonWidth: UiUtil.vw(6.4, 62, 88, this.viewportWidth, this.scaleFactor),
          buttonHeight: UiUtil.vh(4.2, 32, 46, this.viewportHeight, this.scaleFactor),
          fontSizeValue: UiUtil.vh(2.0, 12, 16, this.viewportHeight, this.scaleFactor),
          borderRadiusValue: UiUtil.vh(0.8, 5, 10, this.viewportHeight, this.scaleFactor),
          onAction: () => {
            this.activePicker = '';
            this.onQuery();
          }
        })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.Start)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private calendarPanel() {
    if (this.activePicker.length > 0) {
      CalendarPickerPanel({
        selectedDate: this.activePicker === 'start' ? this.startDate : this.endDate,
        viewportWidth: this.viewportWidth,
        viewportHeight: this.viewportHeight,
        scaleFactor: this.scaleFactor,
        onDateSelected: (value: string) => {
          if (this.activePicker === 'start') {
            this.startDate = value;
          } else {
            this.endDate = value;
          }
          this.activePicker = '';
        }
      })
    }
  }
}
