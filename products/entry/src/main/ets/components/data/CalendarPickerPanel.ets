import { UiUtil } from "base";

interface CalendarCell {
  id: string;
  day: number;
  currentMonth: boolean;
  selected: boolean;
}

@Component
export struct CalendarPickerPanel {
  @Prop selectedDate: string = '';
  @Prop viewportWidth: number = 1024;
  @Prop viewportHeight: number = 768;
  @Prop scaleFactor: number = 1.92;
  @State private displayYear: number = new Date().getFullYear();
  @State private displayMonth: number = new Date().getMonth() + 1;
  onDateSelected: (value: string) => void = () => {
  };

  aboutToAppear(): void {
    this.syncDisplayDate();
  }

  private syncDisplayDate(): void {
    const parsed = this.parseDateText(this.selectedDate);
    if (!parsed) {
      return;
    }
    this.displayYear = parsed.getFullYear();
    this.displayMonth = parsed.getMonth() + 1;
  }

  private parseDateText(value: string): Date | null {
    const parts = value.trim().split('-');
    if (parts.length !== 3) {
      return null;
    }
    const year = Number(parts[0]);
    const month = Number(parts[1]);
    const day = Number(parts[2]);
    if (!Number.isInteger(year) || !Number.isInteger(month) || !Number.isInteger(day)) {
      return null;
    }
    const date = new Date(year, month - 1, day, 0, 0, 0, 0);
    if (date.getFullYear() !== year || date.getMonth() !== month - 1 || date.getDate() !== day) {
      return null;
    }
    return date;
  }

  private padNumber(value: number): string {
    return value < 10 ? `0${value}` : value.toString();
  }

  private formatDate(year: number, month: number, day: number): string {
    return `${year}-${this.padNumber(month)}-${this.padNumber(day)}`;
  }

  private getDaysInMonth(year: number, month: number): number {
    return new Date(year, month, 0).getDate();
  }

  private previousMonth(): void {
    if (this.displayMonth === 1) {
      this.displayYear -= 1;
      this.displayMonth = 12;
    } else {
      this.displayMonth -= 1;
    }
  }

  private nextMonth(): void {
    if (this.displayMonth === 12) {
      this.displayYear += 1;
      this.displayMonth = 1;
    } else {
      this.displayMonth += 1;
    }
  }

  private previousYear(): void {
    this.displayYear -= 1;
  }

  private nextYear(): void {
    this.displayYear += 1;
  }

  private getWeekDays(): string[] {
    return ['一', '二', '三', '四', '五', '六', '日'];
  }

  private getCalendarRows(): CalendarCell[][] {
    const rows: CalendarCell[][] = [];
    const firstDay = new Date(this.displayYear, this.displayMonth - 1, 1).getDay();
    const firstOffset = firstDay === 0 ? 6 : firstDay - 1;
    const daysInMonth = this.getDaysInMonth(this.displayYear, this.displayMonth);
    const prevMonth = this.displayMonth === 1 ? 12 : this.displayMonth - 1;
    const prevYear = this.displayMonth === 1 ? this.displayYear - 1 : this.displayYear;
    const prevDays = this.getDaysInMonth(prevYear, prevMonth);
    let cursor = 0;

    for (let rowIndex = 0; rowIndex < 6; rowIndex++) {
      const row: CalendarCell[] = [];
      for (let colIndex = 0; colIndex < 7; colIndex++) {
        const dayIndex = cursor - firstOffset + 1;
        let day = dayIndex;
        let currentMonth = true;
        if (dayIndex <= 0) {
          day = prevDays + dayIndex;
          currentMonth = false;
        } else if (dayIndex > daysInMonth) {
          day = dayIndex - daysInMonth;
          currentMonth = false;
        }
        const dateText = currentMonth ? this.formatDate(this.displayYear, this.displayMonth, day) : '';
        const cell: CalendarCell = {
          id: `${rowIndex}-${colIndex}-${day}`,
          day: day,
          currentMonth: currentMonth,
          selected: currentMonth && dateText === this.selectedDate
        };
        row.push(cell);
        cursor++;
      }
      rows.push(row);
    }
    return rows;
  }

  @Builder
  private navButton(label: string, onAction: () => void) {
    Text(label)
      .width(UiUtil.vw(3.2, 24, 34, this.viewportWidth, this.scaleFactor))
      .height(UiUtil.vh(3.0, 22, 30, this.viewportHeight, this.scaleFactor))
      .fontSize(UiUtil.vh(1.65, 11, 15, this.viewportHeight, this.scaleFactor))
      .fontWeight(FontWeight.Bold)
      .fontColor('#0A6BFF')
      .textAlign(TextAlign.Center)
      .border({ width: UiUtil.vh(0.1, 1, 1, this.viewportHeight, this.scaleFactor), color: '#D6E4FF' })
      .borderRadius(UiUtil.vh(0.45, 3, 5, this.viewportHeight, this.scaleFactor))
      .onClick(() => {
        onAction();
      })
  }

  build() {
    Column() {
      Row() {
        this.navButton('<<', () => this.previousYear());
        this.navButton('<', () => this.previousMonth());
        Text(`${this.displayYear}年${this.padNumber(this.displayMonth)}月`)
          .layoutWeight(1)
          .height(UiUtil.vh(3.0, 22, 30, this.viewportHeight, this.scaleFactor))
          .fontSize(UiUtil.vh(1.75, 12, 16, this.viewportHeight, this.scaleFactor))
          .fontWeight(FontWeight.Bold)
          .fontColor('#222222')
          .textAlign(TextAlign.Center)
        this.navButton('>', () => this.nextMonth());
        this.navButton('>>', () => this.nextYear());
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: UiUtil.vh(0.5, 3, 6, this.viewportHeight, this.scaleFactor) })

      Row() {
        ForEach(this.getWeekDays(), (item: string) => {
          Text(item)
            .layoutWeight(1)
            .height(UiUtil.vh(2.6, 18, 26, this.viewportHeight, this.scaleFactor))
            .fontSize(UiUtil.vh(1.35, 10, 13, this.viewportHeight, this.scaleFactor))
            .fontWeight(FontWeight.Bold)
            .fontColor('#5B6675')
            .textAlign(TextAlign.Center)
        }, (item: string) => item)
      }
      .width('100%')

      ForEach(this.getCalendarRows(), (row: CalendarCell[], rowIndex: number) => {
        Row() {
          ForEach(row, (cell: CalendarCell) => {
            Text(cell.day.toString())
              .layoutWeight(1)
              .height(UiUtil.vh(3.0, 22, 30, this.viewportHeight, this.scaleFactor))
              .fontSize(UiUtil.vh(1.45, 10, 14, this.viewportHeight, this.scaleFactor))
              .fontColor(cell.currentMonth ? (cell.selected ? '#FFFFFF' : '#20242A') : '#B9C0C8')
              .fontWeight(cell.selected ? FontWeight.Bold : FontWeight.Normal)
              .textAlign(TextAlign.Center)
              .backgroundColor(cell.selected ? '#0B9F9A' : '#FFFFFF')
              .borderRadius(UiUtil.vh(0.45, 3, 5, this.viewportHeight, this.scaleFactor))
              .onClick(() => {
                if (cell.currentMonth) {
                  this.onDateSelected(this.formatDate(this.displayYear, this.displayMonth, cell.day));
                }
              })
          }, (cell: CalendarCell) => cell.id)
        }
        .width('100%')
      }, (_row: CalendarCell[], rowIndex: number) => `row-${rowIndex}`)
    }
    .width(UiUtil.vw(28.0, 230, 320, this.viewportWidth, this.scaleFactor))
    .padding({
      left: UiUtil.vw(0.8, 6, 10, this.viewportWidth, this.scaleFactor),
      right: UiUtil.vw(0.8, 6, 10, this.viewportWidth, this.scaleFactor),
      top: UiUtil.vh(0.8, 6, 10, this.viewportHeight, this.scaleFactor),
      bottom: UiUtil.vh(0.8, 6, 10, this.viewportHeight, this.scaleFactor)
    })
    .backgroundColor('#FFFFFF')
    .border({ width: UiUtil.vh(0.1, 1, 1, this.viewportHeight, this.scaleFactor), color: '#C9D8E8' })
    .borderRadius(UiUtil.vh(0.7, 5, 8, this.viewportHeight, this.scaleFactor))
    .shadow({
      radius: 8,
      color: '#22000000',
      offsetX: 0,
      offsetY: 2
    })
  }
}
