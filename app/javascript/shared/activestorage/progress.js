addEventListener('direct-upload:initialize', event => {
  const target = event.target,
    detail = event.detail,
    id = detail.id,
    file = detail.file;

  target.insertAdjacentHTML(
    'beforebegin',
    '\n<div id="direct-upload-' +
      id +
      '" class="direct-upload direct-upload--pending">\n<div id="direct-upload-progress-' +
      id +
      '" class="direct-upload__progress" style="width: 0%"></div>\n<span class="direct-upload__filename">' +
      file.name +
      '</span>\n</div>\n'
  );
});

addEventListener('direct-upload:start', event => {
  const id = event.detail.id,
    element = document.getElementById('direct-upload-' + id);

  element.classList.remove('direct-upload--pending');
});

addEventListener('direct-upload:progress', event => {
  const id = event.detail.id,
    progress = event.detail.progress,
    progressElement = document.getElementById('direct-upload-progress-' + id);

  progressElement.style.width = `${progress}%`;
});

addEventListener('direct-upload:error', event => {
  event.preventDefault();
  const id = event.detail.id,
    error = event.detail.error,
    element = document.getElementById('direct-upload-' + id);

  element.classList.add('direct-upload--error');
  element.setAttribute('title', error);
});

addEventListener('direct-upload:end', event => {
  const id = event.detail.id,
    element = document.getElementById('direct-upload-' + id);

  element.classList.add('direct-upload--complete');
});
