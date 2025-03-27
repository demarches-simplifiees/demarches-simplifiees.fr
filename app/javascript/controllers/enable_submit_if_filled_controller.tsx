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
    if (this.submitTarget) {
      if (document.querySelectorAll('.fr-ds-combobox__multiple')) {
        this.submitTarget.disabled = false;
      } else {
        this.submitTarget.disabled = true;
      }
    }
  }
}
