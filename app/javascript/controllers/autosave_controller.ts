import {
  isSelectElement,
  isCheckboxOrRadioInputElement,
  isTextInputElement,
  getConfig
} from '@utils';

import { ApplicationController } from './application_controller';
import Uploader from '../shared/activestorage/uploader';
import {
  FileUploadError,
  FAILURE_CLIENT,
  ERROR_CODE_READ
} from '../shared/activestorage/file-upload-error';

const {
  autosave: { debounce_delay }
} = getConfig();

const AUTOSAVE_DEBOUNCE_DELAY = debounce_delay;

// This is a controller we attach to each "champ" in the main form. It performs
// the save and dispatches a few events that allow `AutosaveStatusController` to
// coordinate notifications and retries:
// * `autosave:enqueue` - dispatched when a new save attempt starts
// * `autosave:error` - dispatched when an error occures
//
export class AutosaveController extends ApplicationController {
  connect() {
    this.on('change', (event) => this.onChange(event));
    this.on('input', (event) => this.onInput(event));
  }

  onClickRetryButton(event: Event) {
    const target = event.target as HTMLButtonElement;
    const inputTargetSelector = target.dataset.inputTarget;
    if (inputTargetSelector) {
      const target =
        this.element.querySelector<HTMLInputElement>(inputTargetSelector);
      if (target && target.type == 'file' && target.files?.length) {
        this.uploadFile(target, target.files[0]);
      }
    }
  }

  private onChange(event: Event) {
    const target = event.target as HTMLInputElement;
    if (!target.disabled) {
      if (target.type == 'file' && target.files?.length) {
        this.uploadFile(target, target.files[0]);
      } else if (target.type == 'hidden') {
        // In React comboboxes we dispatch a "change" event on hidden inputs to trigger autosave.
        // We want to debounce them.
        this.debounce(this.enqueueAutosaveRequest, AUTOSAVE_DEBOUNCE_DELAY);
      } else if (
        isSelectElement(target) ||
        isCheckboxOrRadioInputElement(target)
      ) {
        this.enqueueAutosaveRequest();
      }
    }
  }

  private onInput(event: Event) {
    const target = event.target as HTMLInputElement;
    if (
      !target.disabled &&
      // Ignore input from React comboboxes. We trigger "change" events on them when selection is changed.
      target.getAttribute('role') != 'combobox' &&
      isTextInputElement(target)
    ) {
      this.debounce(this.enqueueAutosaveRequest, AUTOSAVE_DEBOUNCE_DELAY);
    }
  }

  private async uploadFile(target: HTMLInputElement, file: File) {
    if (target.dataset.directUploadUrl) {
      const uploader = new Uploader(
        target,
        file,
        target.dataset.directUploadUrl ?? ''
      );
      const input = document.createElement('input');

      try {
        const blobSignedId = await uploader.start();
        input.type = 'hidden';
        input.name = target.name;
        input.value = blobSignedId;
        target.disabled = true;
        target.parentElement?.append(input);
        this.dispatch('change', { target: input, bubbles: true, prefix: '' });
      } catch (e) {
        const error = e as FileUploadError;
        // Report unexpected client errors to Sentry.
        // (But ignore usual client errors, or errors we can monitor better on the server side.)
        if (
          error.failureReason == FAILURE_CLIENT &&
          error.code != ERROR_CODE_READ
        ) {
          this.globalDispatch('autosave:error', { error });
        }
      } finally {
        target.disabled = false;
        input.remove();
      }
    }
  }

  // Add a new autosave request to the queue.
  // It will be started after the previous one finishes (to prevent older form data
  // to overwrite newer data if the server does not respond in order.)
  private enqueueAutosaveRequest() {
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

    this.globalDispatch('autosave:enqueue', {
      url: form.action,
      formData
    });
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
    return inputs
      .filter((element) => !element.disabled)
      .filter((element) => !!element.name);
  }
}
