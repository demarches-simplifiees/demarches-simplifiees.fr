import { ApplicationController } from './application_controller';

export class PersistedFormController extends ApplicationController {
  static values = {
    key: String
  };

  declare readonly keyValue: string;

  connect() {
    this.on('submit', () => this.onSubmit());
    this.on('input', () => this.debounce(this.onInput, 500));

    this.restoreInputValues();
  }

  onSubmit() {
    try {
      for (const input of this.inputs) {
        localStorage.removeItem(this.storageKey(input.name));
      }
    } catch (error) {
      console.error(error);
    }
  }

  onInput() {
    try {
      for (const input of this.inputs) {
        localStorage.setItem(this.storageKey(input.name), input.value);
      }
    } catch (error) {
      console.error(error);
    }
  }

  private restoreInputValues() {
    try {
      for (const input of this.inputs) {
        const value = localStorage.getItem(this.storageKey(input.name));
        if (value) {
          input.value = value;
        }
      }
    } catch (error) {
      console.error(error);
    }
  }

  private get inputs() {
    return this.element.querySelectorAll<
      HTMLInputElement | HTMLTextAreaElement
    >('input[type="text"], input[type="email"], textarea');
  }

  private storageKey(name: string) {
    return `persisted-value-${this.keyValue}:${name}`;
  }
}
