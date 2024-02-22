import { httpRequest, ResponseError, getConfig } from '@utils';
import { matchInputElement, isButtonElement } from '@coldwired/utils';

import { ApplicationController } from './application_controller';
import { AutoUpload } from '../shared/activestorage/auto-upload';
import {
  FileUploadError,
  FAILURE_CLIENT,
  ERROR_CODE_READ
} from '../shared/activestorage/file-upload-error';

const {
  autosave: { debounce_delay }
} = getConfig();

const AUTOSAVE_DEBOUNCE_DELAY = debounce_delay;
const AUTOSAVE_TIMEOUT_DELAY = 60000;
const AUTOSAVE_CONDITIONAL_SPINNER_DEBOUNCE_DELAY = 200;

// This is a controller we attach to each "champ" in the main form. It performs
// the save and dispatches a few events that allow `AutosaveStatusController` to
// coordinate notifications and retries:
// * `autosave:enqueue` - dispatched when a new save attempt starts
// * `autosave:end` - dispatched after sucessful save
// * `autosave:error` - dispatched when an error occures
//
// The controller also listens to the following events:
// * `autosave:retry` - dispatched by `AutosaveStatusController` when the user
// clicks the retry button in the form status bar
//
export class AutosaveController extends ApplicationController {
  #abortController?: AbortController;
  #latestPromise = Promise.resolve();
  #needsRetry = false;
  #pendingPromiseCount = 0;
  #spinnerTimeoutId?: ReturnType<typeof setTimeout>;

  connect() {
    this.#latestPromise = Promise.resolve();
    this.onGlobal('autosave:retry', () => this.didRequestRetry());
    this.on('change', (event) => this.onChange(event));
    this.on('input', (event) => this.onInput(event));
  }

  disconnect() {
    this.#abortController?.abort();
    this.#latestPromise = Promise.resolve();
  }

  onClickRetryButton(event: Event) {
    const target = event.target;
    if (isButtonElement(target)) {
      const inputTargetSelector = target.dataset.inputTarget;
      if (inputTargetSelector) {
        const target =
          this.element.querySelector<HTMLInputElement>(inputTargetSelector);
        if (
          target &&
          target.type == 'file' &&
          target.dataset.autoAttachUrl &&
          target.files?.length
        ) {
          this.enqueueAutouploadRequest(target, target.files[0]);
        }
      }
    }
  }

  private onChange(event: Event) {
    matchInputElement(event.target, {
      file: (target) => {
        if (target.dataset.autoAttachUrl && target.files?.length) {
          this.globalDispatch('autosave:input');
          this.enqueueAutouploadRequest(target, target.files[0]);
        }
      },
      changeable: (target) => {
        this.globalDispatch('autosave:input');

        // Wait next tick so champs having JS can interact
        // with form elements before extracting form data.
        setTimeout(() => {
          this.enqueueAutosaveRequest();
          this.showConditionnalSpinner(target);
        }, 0);
      },
      inputable: (target) => this.enqueueOnInput(target, true),
      hidden: (target) => {
        // In comboboxes we dispatch a "change" event on hidden inputs to trigger autosave.
        // We want to debounce them.
        this.enqueueOnInput(target, true);
      }
    });
  }

  private onInput(event: Event) {
    matchInputElement(event.target, {
      inputable: (target) => {
        // Ignore input from React comboboxes. We trigger "change" events on them when selection is changed.
        if (target.getAttribute('role') != 'combobox') {
          const validate = this.needsValidation(target);
          this.enqueueOnInput(target, validate);
        }
      }
    });
  }

  private enqueueOnInput(
    target: HTMLInputElement | HTMLTextAreaElement,
    validate: boolean
  ) {
    this.globalDispatch('autosave:input');

    const callback = validate
      ? this.enqueueAutosaveWithValidationRequest
      : this.enqueueAutosaveRequest;
    this.debounce(callback, AUTOSAVE_DEBOUNCE_DELAY);

    this.showConditionnalSpinner(target);
  }

  private needsValidation(target: HTMLElement) {
    return target.getAttribute('aria-invalid') == 'true';
  }

  private showConditionnalSpinner(
    target: HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement
  ) {
    const champWrapperElement = target.closest(
      '.editable-champ[data-dependent-conditions]'
    );

    if (!champWrapperElement) {
      return;
    }

    this.showSpinner(champWrapperElement);
  }

  private showSpinner(champElement: Element) {
    this.#spinnerTimeoutId = setTimeout(() => {
      // do not do anything if there is already a spinner for this champ, like SIRET champ
      if (!champElement.nextElementSibling?.classList.contains('spinner')) {
        const spinner = document.createElement('div');
        spinner.classList.add('spinner', 'spinner-removable');
        spinner.setAttribute('aria-live', 'live');
        spinner.setAttribute('aria-label', 'Chargement en cours…');
        champElement.insertAdjacentElement('afterend', spinner);
      }
    }, AUTOSAVE_CONDITIONAL_SPINNER_DEBOUNCE_DELAY);
  }

  private didRequestRetry() {
    if (this.#needsRetry) {
      this.enqueueAutosaveRequest();
    }
  }

  private didEnqueue() {
    this.#needsRetry = false;
    this.globalDispatch('autosave:enqueue');
  }

  private didSucceed() {
    this.#pendingPromiseCount -= 1;
    if (this.#pendingPromiseCount == 0) {
      this.globalDispatch('autosave:end');
      clearTimeout(this.#spinnerTimeoutId);
    }
  }

  private didFail(error: ResponseError) {
    this.#needsRetry = true;
    this.#pendingPromiseCount -= 1;
    this.globalDispatch('autosave:error', { error });
  }

  private enqueueAutouploadRequest(target: HTMLInputElement, file: File) {
    const autoupload = new AutoUpload(target, file);
    autoupload
      .start()
      .catch((e) => {
        const error = e as FileUploadError;

        this.globalDispatch('autosave:error');

        // Report unexpected client errors to Sentry.
        // (But ignore usual client errors, or errors we can monitor better on the server side.)
        if (
          error.failureReason == FAILURE_CLIENT &&
          error.code != ERROR_CODE_READ
        ) {
          throw error;
        }
      })
      .then(() => {
        this.globalDispatch('autosave:end');
      });
  }

  // Add a new autosave request to the queue.
  // It will be started after the previous one finishes (to prevent older form data
  // to overwrite newer data if the server does not respond in order.)
  private enqueueAutosaveRequest() {
    this.#latestPromise = this.#latestPromise.finally(() =>
      this.sendAutosaveRequest()
        .then(() => this.didSucceed())
        .catch((error) => this.didFail(error))
    );
    this.didEnqueue();
  }

  private enqueueAutosaveWithValidationRequest() {
    this.#latestPromise = this.#latestPromise.finally(() =>
      this.sendAutosaveRequest(true)
        .then(() => this.didSucceed())
        .catch((error) => this.didFail(error))
    );
    this.didEnqueue();
  }

  // Create a fetch request that saves the form.
  // Returns a promise fulfilled when the request completes.
  private sendAutosaveRequest(validate = false): Promise<void> {
    this.#abortController = new AbortController();
    const { form, inputs } = this;

    if (!form || inputs.length == 0) {
      return Promise.resolve();
    }

    const formData = new FormData();
    for (const input of inputs) {
      if (input.type == 'checkbox') {
        formData.append(input.name, input.checked ? input.value : '');
      } else if (input.type == 'radio') {
        if (input.checked) {
          formData.append(input.name, input.value);
        }
      } else {
        // NOTE: some type inputs (like number) have an empty input.value
        // when the filled value is invalid (not a number) so we avoid them
        formData.append(input.name, input.value);
      }
    }
    if (validate) {
      formData.append('validate', 'true');
    }

    this.#pendingPromiseCount++;

    return httpRequest(form.action, {
      method: 'post',
      body: formData,
      headers: { 'x-http-method-override': 'PATCH' },
      signal: this.#abortController.signal,
      timeout: AUTOSAVE_TIMEOUT_DELAY
    }).turbo();
  }

  private get form() {
    return this.element.closest('form');
  }

  private get inputs() {
    const element = this.element as HTMLElement;

    return [
      ...element.querySelectorAll<HTMLInputElement>(
        'input:not([type=file]), textarea, select'
      )
    ].filter((element) => !element.disabled);
  }
}
