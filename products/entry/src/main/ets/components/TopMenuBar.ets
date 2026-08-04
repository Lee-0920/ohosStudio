import { UiUtil } from 'base';
import { WqMenuItem } from '../models/monitorTypes';

export type UserMenuAction = 'switch' | 'logout' | 'screenshot';

@Component
export struct TopMenuBar {
  // Currently selected menu id, controls active style.
  @Prop currentMenu: string = 'home';
  // Left side main navigation entries.
  @Prop leftMenus: WqMenuItem[] = [];
  // Right side user center entry.
  @Prop rightMenu: WqMenuItem = { id: '', name: '', icon: $r('app.media.user') };
  @Prop viewportWidth: number = 1024;
  @Prop viewportHeight: number = 768;
  @Prop scaleFactor: number = 1.92;
  // Keep click behavior in parent container to avoid scattering navigation state.
  onMenuClick: (menuId: string) => void = () => {
  };
  // Dropdown actions emitted from the user icon menu.
  onUserMenuAction: (action: UserMenuAction) => void = () => {
  };
  @State private userMenuVisible: boolean = false;

  @Builder
  private menuItem(label: string, action: UserMenuAction) {
    Row() {
      Text(label)
        .fontSize(UiUtil.vh(1.75, 12, 18, this.viewportHeight, this.scaleFactor))
        .fontColor('#333333')
    }
    .width('100%')
    .height(UiUtil.vh(4.4, 32, 50, this.viewportHeight, this.scaleFactor))
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#FFFFFF')
    .onClick(() => {
      this.userMenuVisible = false;
      this.onUserMenuAction(action);
    })
  }

  @Builder
  private userMenuBuilder() {
    Column() {
      this.menuItem('切换用户', 'switch')
      Divider()
        .width('90%')
        .strokeWidth(1)
        .color('#F0F0F0')
      this.menuItem('注销', 'logout')
      Divider()
        .width('90%')
        .strokeWidth(1)
        .color('#F0F0F0')
      this.menuItem('截图', 'screenshot')
    }
    .width(UiUtil.vw(11, 92, 132, this.viewportWidth, this.scaleFactor))
    .backgroundColor('#FFFFFF')
    .borderRadius(UiUtil.vh(0.7, 5, 9, this.viewportHeight, this.scaleFactor))
    .shadow({
      radius: UiUtil.vh(0.5, 3, 8, this.viewportHeight, this.scaleFactor),
      color: '#25000000',
      offsetX: 0,
      offsetY: UiUtil.vh(0.2, 1, 3, this.viewportHeight, this.scaleFactor)
    })
  }

  build() {
    // Top background panel with left navigation and right user menu.
    Stack() {
      Image($r('app.media.top'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Fill)

      Row() {
        // Main function menus on the left.
        Row() {
          ForEach(this.leftMenus, (item: WqMenuItem) => {
            Column() {
              Image(item.icon)
                .width(UiUtil.vh(3.4, 22, 38, this.viewportHeight, this.scaleFactor))
                .height(UiUtil.vh(3.4, 22, 38, this.viewportHeight, this.scaleFactor))
                .objectFit(ImageFit.Contain)
                .opacity(this.currentMenu === item.id ? 1 : 0.7)
              Text(item.name)
                .fontSize(UiUtil.vh(1.9, 12, 20, this.viewportHeight, this.scaleFactor))
                .fontWeight(this.currentMenu === item.id ? FontWeight.Bold : FontWeight.Normal)
                .fontColor('#FFFFFF')
                .margin({ top: UiUtil.vh(0.7, 3, 8, this.viewportHeight, this.scaleFactor) })
            }
            .height(UiUtil.vh(6.84, 56, 86, this.viewportHeight, this.scaleFactor))
            .width(UiUtil.vw(7.2, 64, 112, this.viewportWidth, this.scaleFactor))
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .backgroundColor(this.currentMenu === item.id ? '#4DB9B7' : 'transparent')
            .borderRadius(UiUtil.vh(0.8, 5, 10, this.viewportHeight, this.scaleFactor))
            .onClick(() => {
              this.onMenuClick(item.id);
            })
          }, (item: WqMenuItem) => item.id)
        }

        Blank()

        // User center shortcut on the right.
        Column() {
          Image(this.rightMenu.icon)
            .width(UiUtil.vh(3.4, 22, 38, this.viewportHeight, this.scaleFactor))
            .height(UiUtil.vh(3.4, 22, 38, this.viewportHeight, this.scaleFactor))
            .objectFit(ImageFit.Contain)
            .opacity(this.currentMenu === this.rightMenu.id ? 1 : 0.7)
          Text(this.rightMenu.name)
            .fontSize(UiUtil.vh(1.9, 12, 20, this.viewportHeight, this.scaleFactor))
            .fontWeight(this.currentMenu === this.rightMenu.id ? FontWeight.Bold : FontWeight.Normal)
            .fontColor('#FFFFFF')
            .margin({ top: UiUtil.vh(0.7, 3, 8, this.viewportHeight, this.scaleFactor) })
        }
        .height(UiUtil.vh(7.6, 56, 86, this.viewportHeight, this.scaleFactor))
        .width(UiUtil.vw(8.0, 64, 112, this.viewportWidth, this.scaleFactor))
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor(this.currentMenu === this.rightMenu.id ? '#4DB9B7' : 'transparent')
        .borderRadius(UiUtil.vh(0.8, 5, 10, this.viewportHeight, this.scaleFactor))
        .onClick(() => {
          this.userMenuVisible = !this.userMenuVisible;
        })
        .bindPopup(this.userMenuVisible, {
          builder: this.userMenuBuilder,
          placement: Placement.Bottom,
          enableArrow: false,
          popupColor: '#FFFFFF',
          onStateChange: (e) => {
            this.userMenuVisible = e.isVisible;
          }
        })
      }
      .height(UiUtil.vh(8.5, 50, 78, this.viewportHeight, this.scaleFactor))
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .padding({
        left: UiUtil.vw(0.7, 6, 14, this.viewportWidth, this.scaleFactor),
        right: UiUtil.vw(0.7, 6, 14, this.viewportWidth, this.scaleFactor)
      })
    }
    .height(UiUtil.vh(8.5, 50, 78, this.viewportHeight, this.scaleFactor))
    .width('100%')
  }
}
