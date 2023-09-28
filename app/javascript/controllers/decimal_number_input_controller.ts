import { ApplicationController } from './application_controller';

export class DecimalNumberInputController extends ApplicationController {
  connect() {
    const value = this.inputElement.value;

    if (value) {
      this.formatValue(value);
    }
  }

  formatValue(value: string) {
    const number = parseFloat(value);

    if (isNaN(number)) {
      return;
    }

    this.inputElement.value = number.toLocaleString();
    this.emitInputEvent(); // trigger format controller
  }

  private get inputElement(): HTMLInputElement {
    return this.element as HTMLInputElement;
  }

  private emitInputEvent() {
    const event = new InputEvent('input', {
      bubbles: true,
      cancelable: true
    });

    this.inputElement.dispatchEvent(event);
  }
}
