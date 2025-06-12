import { ApplicationController } from './application_controller';

export class DSFRNoticeController extends ApplicationController {
  static targets = ['notice'];

  declare readonly noticeTarget: HTMLElement;

  connect() {
    if (
      this._localStorageHiddenKey &&
      localStorage.getItem(this._localStorageHiddenKey) === 'true'
    ) {
      this._removeNoticeElement();
    }
  }

  closeNotice() {
    if (this._localStorageHiddenKey) {
      localStorage.setItem(this._localStorageHiddenKey!, 'true');
    }

    const event = new CustomEvent('noticeClosed', {
      bubbles: true,
      detail: { noticeName: this._noticeName }
    });

    document.dispatchEvent(event);

    this._removeNoticeElement();
  }

  private _removeNoticeElement() {
    this.noticeTarget.parentNode?.removeChild(this.noticeTarget);
  }

  private get _noticeName() {
    return this.noticeTarget.dataset.noticeName;
  }

  private get _localStorageHiddenKey() {
    const name = this._noticeName;

    if (name) {
      return `noticeHidden_${name}`;
    }

    return undefined;
  }
}
