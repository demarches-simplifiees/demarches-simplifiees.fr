import { Controller } from '@hotwired/stimulus';

export class AutofocusController extends Controller {
  connect() {
    const element = this.element as HTMLInputElement;
    element.focus();
    element.setSelectionRange(0, element.value.length);
  }
}
