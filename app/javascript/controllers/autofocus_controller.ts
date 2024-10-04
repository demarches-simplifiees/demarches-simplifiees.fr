import { Controller } from '@hotwired/stimulus';

export class AutofocusController extends Controller {
  connect() {
    const element = this.element as HTMLInputElement | HTMLElement;
    element.focus();

    if ('value' in element) {
      element.setSelectionRange(0, element.value.length);
    }
  }
}
