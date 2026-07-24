import { GradientSideTabBar } from '../components/GradientSideTabBar';
import { MeasurementDataPanel } from './data/MeasurementDataPanel';
import { HistoryTrendPanel } from './data/HistoryTrendPanel';
import { CalibrationCurvePanel } from './data/CalibrationCurvePanel';
import { RangeInfoPanel } from './data/RangeInfoPanel';
import { OperationLogPanel } from './data/OperationLogPanel';
import { AlarmManagementPanel } from './data/AlarmManagementPanel';

@Component
export struct DataPage {
  // Left-side data section tabs.
  @Prop dataLeftTabs: string[] = [];
  // Currently selected tab (shared with container state).
  @Link selectedDataTab: string;
  @Prop viewportWidth: number = 1024;
  @Prop viewportHeight: number = 768;
  @Prop scaleFactor: number = 1.92;
  @Prop canSetCalibrationCurve: boolean = true;

  // Check whether current selected tab matches the tab at a fixed index.
  private isSelectedTab(index: number): boolean {
    return this.dataLeftTabs[index] !== undefined && this.selectedDataTab === this.dataLeftTabs[index];
  }

  build() {
    // Data page layout: left tabs + tab content area.
    Column() {
      Row() {
        // Left tab navigation column.
        GradientSideTabBar({
          tabs: this.dataLeftTabs,
          selectedTab: this.selectedDataTab,
          viewportWidth: this.viewportWidth,
          viewportHeight: this.viewportHeight,
          scaleFactor: this.scaleFactor,
          onTabChange: (tab: string) => {
            // Switch current data section.
            this.selectedDataTab = tab;
          }
        })

        // Tab content area.
        if (this.isSelectedTab(0)) {
          MeasurementDataPanel({
            tab: this.selectedDataTab,
            viewportWidth: this.viewportWidth,
            viewportHeight: this.viewportHeight,
            scaleFactor: this.scaleFactor
          });
        } else if (this.isSelectedTab(1)) {
          HistoryTrendPanel({
            tab: this.selectedDataTab,
            viewportWidth: this.viewportWidth,
            viewportHeight: this.viewportHeight,
            scaleFactor: this.scaleFactor
          });
        } else if (this.isSelectedTab(2)) {
          CalibrationCurvePanel({
            tab: this.selectedDataTab,
            canSetCurrent: this.canSetCalibrationCurve,
            viewportWidth: this.viewportWidth,
            viewportHeight: this.viewportHeight,
            scaleFactor: this.scaleFactor
          });
        } else if (this.isSelectedTab(3)) {
          RangeInfoPanel({
            tab: this.selectedDataTab,
            viewportWidth: this.viewportWidth,
            viewportHeight: this.viewportHeight,
            scaleFactor: this.scaleFactor
          });
        } else if (this.isSelectedTab(4)) {
          AlarmManagementPanel({
            viewportWidth: this.viewportWidth,
            viewportHeight: this.viewportHeight,
            scaleFactor: this.scaleFactor
          })
            .layoutWeight(1)
            .height('100%');
        } else if (this.isSelectedTab(5)) {
          OperationLogPanel({
            tab: this.selectedDataTab,
            viewportWidth: this.viewportWidth,
            viewportHeight: this.viewportHeight,
            scaleFactor: this.scaleFactor
          });
        } else {
          // Default fallback keeps behavior safe if tab config changes.
          MeasurementDataPanel({ tab: this.selectedDataTab });
        }
      }
      .layoutWeight(1)
      .width('100%')
      .alignItems(VerticalAlign.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F7F7')
  }
}
