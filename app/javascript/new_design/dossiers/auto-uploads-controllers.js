import Rails from '@rails/ujs';
import AutoUploadController from './auto-upload-controller.js';

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
    } finally {
      this._decrementInFlightUploads(form);
    }
  }

  _incrementInFlightUploads(form) {
    this.inFlightUploadsCount += 1;

    if (form) {
      form
        .querySelectorAll('button[type=submit]')
        .forEach(submitButton => Rails.disableElement(submitButton));
    }
  }

  _decrementInFlightUploads(form) {
    if (this.inFlightUploadsCount > 0) {
      this.inFlightUploadsCount -= 1;
    }

    if (this.inFlightUploadsCount == 0 && form) {
      form
        .querySelectorAll('button[type=submit]')
        .forEach(submitButton => Rails.enableElement(submitButton));
    }
  }
}
