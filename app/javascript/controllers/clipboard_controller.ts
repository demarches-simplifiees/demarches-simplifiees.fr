import { Controller } from '@hotwired/stimulus';

const SUCCESS_MESSAGE_TIMEOUT = 1000;

export class ClipboardController extends Controller {
  static values = { text: String };
  static targets = ['success'];

  declare readonly textValue: string;
  declare readonly successTarget: HTMLElement;
  declare readonly hasSuccessTarget: boolean;

  #timer?: ReturnType<typeof setTimeout>;

  disconnect(): void {
    clearTimeout(this.#timer);
  }

  copy() {
    navigator.clipboard
      .writeText(this.textValue)
      .then(() => this.displayCopyConfirmation());
  }

  private displayCopyConfirmation() {
    if (this.hasSuccessTarget) {
      this.successTarget.classList.remove('hidden');
      clearTimeout(this.#timer);
      this.#timer = setTimeout(() => {
        this.successTarget.classList.add('hidden');
      }, SUCCESS_MESSAGE_TIMEOUT);
    }
  }
}
