import Rails from '@rails/ujs';
import AutoUploadController from './auto-upload-controller.js';
import { fire } from '@utils';
import {
  FAILURE_CLIENT,
  ERROR_CODE_READ
} from '../../shared/activestorage/file-upload-error';

//
// DEBUG
//
const originalImpl = FileReader.prototype.addEventListener;

// Manage multiple concurrent uploads.
//
// When the first upload starts, all the form "Submit" buttons are disabled.
// They are enabled again when the last upload ends.
export default class AutoUploadsControllers {
  constructor() {
    this.inFlightUploadsCount = 0;
  }

  async upload(input, file) {
    let form = input.form;
    this._incrementInFlightUploads(form);

    try {
      let controller = new AutoUploadController(input, file);
      await controller.start();
    } catch (err) {
      // Report unexpected client errors to Sentry.
      // (But ignore usual client errors, or errors we can monitor better on the server side.)
      if (err.failureReason == FAILURE_CLIENT && err.code != ERROR_CODE_READ) {
        throw err;
      }
    } finally {
      this._decrementInFlightUploads(form);
    }
  }

  _incrementInFlightUploads(form) {
    this.inFlightUploadsCount += 1;

    if (form) {
      form
        .querySelectorAll('button[type=submit]')
        .forEach((submitButton) => Rails.disableElement(submitButton));
    }

    //
    // DEBUG: hook into FileReader onload event
    //
    if (FileReader.prototype.addEventListener === originalImpl) {
      FileReader.prototype.addEventListener = function () {
        // When DirectUploads attempts to add an event listener for "error",
        // also insert a custom event listener of our that will report errors to Sentry.
        if (arguments[0] == 'error') {
          let handler = (event) => {
            let message = `FileReader ${event.target.error.name}: ${event.target.error.message}`;
            fire(document, 'sentry:capture-exception', new Error(message));
          };
          originalImpl.apply(this, ['error', handler]);
        }
        // Add the originally requested event listener
        return originalImpl.apply(this, arguments);
      };
    }
  }

  _decrementInFlightUploads(form) {
    if (this.inFlightUploadsCount > 0) {
      this.inFlightUploadsCount -= 1;
    }

    if (this.inFlightUploadsCount == 0 && form) {
      form
        .querySelectorAll('button[type=submit]')
        .forEach((submitButton) => Rails.enableElement(submitButton));
    }

    //
    // DEBUG: remove the FileReader hook we set before.
    //
    if (this.inFlightUploadsCount == 0) {
      FileReader.prototype.addEventListener = originalImpl;
    }
  }
}
