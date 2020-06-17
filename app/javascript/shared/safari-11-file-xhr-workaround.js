// iOS 11.3 Safari / macOS Safari 11.1 empty <input type="file"> XHR bug workaround.
// This should work with every modern browser which supports ES5 (including IE9).
// https://stackoverflow.com/questions/49614091/safari-11-1-ajax-xhr-form-submission-fails-when-inputtype-file-is-empty
// https://github.com/rails/rails/issues/32440

document.addEventListener('ajax:before', function (e) {
  let inputs = e.target.querySelectorAll('input[type="file"]:not([disabled])');
  inputs.forEach(function (input) {
    if (input.files.length > 0) {
      return;
    }
    input.setAttribute('data-safari-temp-disabled', 'true');
    input.setAttribute('disabled', '');
  });
});

// You should call this by yourself when you aborted an ajax request by stopping a event in ajax:before hook.
document.addEventListener('ajax:beforeSend', function (e) {
  let inputs = e.target.querySelectorAll(
    'input[type="file"][data-safari-temp-disabled]'
  );
  inputs.forEach(function (input) {
    input.removeAttribute('data-safari-temp-disabled');
    input.removeAttribute('disabled');
  });
});
