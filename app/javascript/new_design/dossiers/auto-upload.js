import AutoUploadsControllers from './auto-uploads-controllers.js';
import { delegate } from '@utils';

// Create a controller responsible for managing several concurrent uploads.
const autoUploadsControllers = new AutoUploadsControllers();

function startUpload(input) {
  Array.from(input.files).forEach((file) => {
    autoUploadsControllers.upload(input, file);
  });
}

const fileInputSelector = `input[type=file][data-direct-upload-url][data-auto-attach-url]:not([disabled])`;
delegate('change', fileInputSelector, (event) => {
  startUpload(event.target);
});

const retryButtonSelector = `button.attachment-error-retry`;
delegate('click', retryButtonSelector, function () {
  const inputSelector = this.dataset.inputTarget;
  const input = document.querySelector(inputSelector);
  startUpload(input);
});
