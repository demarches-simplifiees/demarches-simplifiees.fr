import { ApplicationController } from './application_controller';

export class DSFRHeaderController extends ApplicationController {
  static targets = ['notice'];

  declare readonly noticeTarget: HTMLElement;

  closeNotice() {
    this.noticeTarget.parentNode?.removeChild(this.noticeTarget);

    this.element.classList.remove('fr-header__with-notice-info');
  }
}
