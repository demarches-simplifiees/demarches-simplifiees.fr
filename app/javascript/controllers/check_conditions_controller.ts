import {
  httpRequest,
  isSelectElement,
  isCheckboxOrRadioInputElement,
  isTextInputElement,
  getConfig
} from '@utils';

import { ApplicationController } from './application_controller';

const {
  autosave: { debounce_delay }
} = getConfig();

const AUTOSAVE_DEBOUNCE_DELAY = debounce_delay;
const AUTOSAVE_TIMEOUT_DELAY = 60000;

export class CheckConditionsController extends ApplicationController {
  #abortController?: AbortController;
  #latestPromise = Promise.resolve();

  connect() {
    this.#latestPromise = Promise.resolve();
    this.on('change', (event) => this.onChange(event));
    this.on('input', (event) => this.onInput(event));
  }

  disconnect() {
    this.#abortController?.abort();
    this.#latestPromise = Promise.resolve();
  }

  private onChange(event: Event) {
    const target = event.target as HTMLInputElement;
    if (!target.disabled) {
      if (target.type == 'hidden') {
        this.debounce(this.enqueueCheckRequest, AUTOSAVE_DEBOUNCE_DELAY);
      } else if (
        isSelectElement(target) ||
        isCheckboxOrRadioInputElement(target)
      ) {
        this.enqueueCheckRequest();
      }
    }
  }

  private onInput(event: Event) {
    const target = event.target as HTMLInputElement;
    if (!target.disabled) {
      if (
        target.getAttribute('role') != 'combobox' &&
        isTextInputElement(target)
      ) {
        this.debounce(this.enqueueCheckRequest, AUTOSAVE_DEBOUNCE_DELAY);
      }
    }
  }

  private enqueueCheckRequest() {
    this.#latestPromise = this.#latestPromise.finally(() =>
      this.sendCheckRequest().catch(() => null)
    );
  }

  private sendCheckRequest(): Promise<void> {
    this.#abortController = new AbortController();
    const form = this.form;

    if (!form) {
      return Promise.resolve();
    }

    const fileInputs = form.querySelectorAll('input[type="file"]');
    for (const input of fileInputs) {
      input.setAttribute('disabled', 'disabled');
    }
    const formData = new FormData(form);
    for (const input of fileInputs) {
      input.removeAttribute('disabled');
    }
    formData.set('check_conditions', 'true');

    return httpRequest(form.action, {
      method: 'patch',
      body: formData,
      signal: this.#abortController.signal,
      timeout: AUTOSAVE_TIMEOUT_DELAY
    }).turbo();
  }

  private get form() {
    return this.element.closest('form');
  }
}
