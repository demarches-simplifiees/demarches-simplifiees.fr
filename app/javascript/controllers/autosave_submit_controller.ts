import { isButtonElement } from '@utils';

import { ApplicationController } from './application_controller';

export class AutosaveSubmitController extends ApplicationController {
  #isSaving = false;
  #shouldSubmit = true;
  #buttonText?: string;

  connect(): void {
    this.onGlobal('autosave:enqueue', () => this.didEnqueue());
    this.onGlobal('autosave:end', () => this.didSucceed());
    this.onGlobal('autosave:error', () => this.didFail());
    this.on('click', (event) => this.onClick(event));
  }

  // Intercept form submit if autosave is still in progress
  private onClick(event: Event) {
    if (this.#isSaving) {
      this.#shouldSubmit = true;
      this.disableButton();
      event.preventDefault();
    }
  }

  private didEnqueue() {
    this.#isSaving = true;
    this.#shouldSubmit = false;
  }

  // If submit was previously requested, send it, now that autosave have finished
  private didSucceed() {
    if (this.#shouldSubmit && isButtonElement(this.element)) {
      this.element.form?.requestSubmit(this.element);
    }
    this.#isSaving = false;
    this.#shouldSubmit = false;
    this.enableButton();
  }

  private didFail() {
    this.#isSaving = false;
    this.#shouldSubmit = false;
    this.enableButton();
  }

  private disableButton() {
    if (isButtonElement(this.element)) {
      this.#buttonText = this.element.value;
      this.element.value = this.element.dataset.disableWith ?? '';
      this.element.disabled = true;
    }
  }

  private enableButton() {
    if (isButtonElement(this.element) && this.#buttonText) {
      this.element.value = this.#buttonText;
      this.element.disabled = false;
    }
  }
}
