import { ApplicationController } from './application_controller';

export class NotificationFormChangesController extends ApplicationController {
  static targets = ['submitButton'];

  declare readonly submitButtonTarget: HTMLButtonElement;

  private initialFormData: string = '';

  connect() {
    this.initialFormData = this.formData();
  }

  onFormChange() {
    const currentFormData = this.formData();
    this.submitButtonTarget.disabled = currentFormData === this.initialFormData;
  }

  private formData(): string {
    const form = this.element as HTMLFormElement;
    const inputs = form.querySelectorAll<HTMLInputElement>(
      'input[type="radio"]:checked'
    );
    const entries = Array.from(inputs)
      .map((input) => [input.name, input.value])
      .sort();
    return JSON.stringify(entries);
  }
}
