import { Controller } from '@hotwired/stimulus';
import { enable, disable } from '@utils';

export class EnableSubmitIfUploadedController extends Controller {
  connect() {
    const fileInput = document.querySelector(
      'input[type="file"]'
    ) as HTMLInputElement;
    const submitButton = document.getElementById(
      'submit-button'
    ) as HTMLButtonElement;

    fileInput.addEventListener('change', function () {
      if (fileInput.files && fileInput.files.length > 0) {
        enable(submitButton);
      } else {
        disable(submitButton);
      }
    });
  }
}
