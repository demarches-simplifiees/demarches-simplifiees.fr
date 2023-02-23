// iOS 11.3 Safari / macOS Safari 11.1 empty <input type="file"> XHR bug workaround.
// This should work with every modern browser which supports ES5 (including IE9).
// https://stackoverflow.com/questions/49614091/safari-11-1-ajax-xhr-form-submission-fails-when-inputtype-file-is-empty
// https://github.com/rails/rails/issues/32440

document.documentElement.addEventListener(
  'turbo:before-fetch-request',
  (event) => {
    const target = event.target as Element;
    const inputs = target.querySelectorAll<HTMLInputElement>(
      'input[type="file"]:not([disabled])'
    );
    for (const input of inputs) {
      if (input.files?.length == 0) {
        input.setAttribute('data-safari-temp-disabled', 'true');
        input.setAttribute('disabled', '');
      }
    }
  }
);

document.documentElement.addEventListener(
  'turbo:before-fetch-response',
  (event) => {
    const target = event.target as Element;
    const inputs = target.querySelectorAll(
      'input[type="file"][data-safari-temp-disabled]'
    );
    for (const input of inputs) {
      input.removeAttribute('data-safari-temp-disabled');
      input.removeAttribute('disabled');
    }
  }
);

export {};
