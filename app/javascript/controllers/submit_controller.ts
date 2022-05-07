import { ApplicationController } from './application_controller';

export class SubmitController extends ApplicationController {
  connect() {
    this.on('change', (event) => this.onChange(event));
  }

  private onChange(event: Event): void {
    const target = event.target as HTMLInputElement;

    if (target.dataset.shouldUpdate) {
      this.save(true);
    } else {
      this.debounce(this.save, 300);
    }
  }

  private save(shouldUpdate = false): void {
    this.shouldUpdate(shouldUpdate);
    this.submitForm();
  }

  private shouldUpdate(shouldUpdate: boolean) {
    const form = this.element as HTMLFormElement;

    if (shouldUpdate) {
      const input = document.createElement('input');
      input.type = 'hidden';
      input.name = 'should_update';
      input.value = 'true';
      form.appendChild(input);
    } else {
      form.querySelector('input[name="should_update"]')?.remove();
    }
  }

  private submitForm() {
    const form = this.element as HTMLFormElement;
    form.requestSubmit();
  }
}
