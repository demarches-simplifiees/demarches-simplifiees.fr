import { httpRequest, ResponseError } from '@utils';
import { z } from 'zod';

import { ApplicationController } from './application_controller';
import { AutoUpload } from '../shared/activestorage/auto-upload';
import {
  FileUploadError,
  FAILURE_CLIENT,
  ERROR_CODE_READ
} from '../shared/activestorage/file-upload-error';

const Gon = z.object({ autosave: z.object({ debounce_delay: z.number() }) });

declare const window: Window & typeof globalThis & { gon: unknown };
const { debounce_delay } = Gon.parse(window.gon).autosave;

const AUTOSAVE_DEBOUNCE_DELAY = debounce_delay;
const AUTOSAVE_TIMEOUT_DELAY = 60000;

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

  connect() {
    this.#latestPromise = Promise.resolve();
    this.onGlobal('autosave:retry', () => this.didRequestRetry());
    this.on('change', (event) => this.onInputChange(event));
    this.on('input', (event) => this.onInputChange(event));
  }

  disconnect() {
    this.#abortController?.abort();
    this.#latestPromise = Promise.resolve();
  }

  onClickRetryButton(event: Event) {
    const target = event.target as HTMLButtonElement;
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

  private onInputChange(event: Event) {
    const target = event.target as HTMLInputElement;
    if (target.disabled) {
      return;
    }
    if (
      target.type == 'file' &&
      target.dataset.autoAttachUrl &&
      target.files?.length
    ) {
      this.enqueueAutouploadRequest(target, target.files[0]);
    } else if (target.type != 'file') {
      this.debounce(this.enqueueAutosaveRequest, AUTOSAVE_DEBOUNCE_DELAY);
    }
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
    this.globalDispatch('autosave:end');
  }

  private didFail(error: ResponseError) {
    this.#needsRetry = true;
    this.globalDispatch('autosave:error', { error });
  }

  private enqueueAutouploadRequest(target: HTMLInputElement, file: File) {
    const autoupload = new AutoUpload(target, file);
    try {
      autoupload.start();
    } catch (e) {
      const error = e as FileUploadError;
      // Report unexpected client errors to Sentry.
      // (But ignore usual client errors, or errors we can monitor better on the server side.)
      if (
        error.failureReason == FAILURE_CLIENT &&
        error.code != ERROR_CODE_READ
      ) {
        throw error;
      }
    }
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

  // Create a fetch request that saves the form.
  // Returns a promise fulfilled when the request completes.
  private sendAutosaveRequest(): Promise<void> {
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
        formData.append(input.name, input.value);
      }
    }

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

  private get inputs() {
    const element = this.element as HTMLElement;
    const inputs = [
      ...element.querySelectorAll<HTMLInputElement>(
        'input:not([type=file]), textarea, select'
      )
    ];
    const parent = this.element.closest('.editable-champ-repetition');
    if (parent) {
      return [
        ...inputs,
        ...parent.querySelectorAll<HTMLInputElement>('input[data-id]')
      ];
    }
    return inputs.filter((element) => !element.disabled);
  }
}
