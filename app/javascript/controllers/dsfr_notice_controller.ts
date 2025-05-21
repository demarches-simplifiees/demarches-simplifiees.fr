import { ApplicationController } from './application_controller';

export class DSFRNoticeController extends ApplicationController {
  static targets = ['notice'];

  declare readonly noticeTarget: HTMLElement;

  closeNotice() {
    const event = new CustomEvent('noticeClosed', {
      bubbles: true,
      detail: { noticeName: this.noticeTarget.dataset.noticeName }
    });

    document.dispatchEvent(event);

    this.noticeTarget.parentNode?.removeChild(this.noticeTarget);
  }
}
