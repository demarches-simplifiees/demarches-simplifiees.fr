import { Controller } from '@hotwired/stimulus';

export class RadioEnabledSubmitController extends Controller {
  static targets = ['submit'];
  declare readonly submitTarget: HTMLButtonElement;

  click() {
    if (
      this.element.querySelectorAll('input[type="radio"]:checked').length > 0
    ) {
      this.submitTarget.disabled = false;
    }
  }
}
