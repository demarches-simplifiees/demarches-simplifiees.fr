import { Controller } from '@hotwired/stimulus';

export class EnableSubmitIfFilledController extends Controller {
  static targets = ['submit', 'input'];

  declare readonly submitTarget: HTMLButtonElement;
  declare readonly inputTarget: HTMLInputElement;

  fill() {
    if (this.inputTarget.value.trim() != '') {
      this.submitTarget.disabled = false;
    } else {
      this.submitTarget.disabled = true;
    }
  }

  fillCombobox() {
    const submitInput = document.querySelector(
      '#emails-submit'
    ) as HTMLButtonElement | null;

    if (submitInput) {
      if (document.querySelectorAll('.fr-ds-combobox__multiple')) {
        submitInput.disabled = false;
      } else {
        submitInput.disabled = true;
      }
    }
  }
}
