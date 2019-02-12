addEventListener('direct-upload:initialize', event => {
  const {
    target,
    detail: {
      id,
      file: { name: filename }
    }
  } = event;

  const errorElements = target.parentElement.querySelectorAll(
    '.direct-upload--error'
  );
  for (let element of errorElements) {
    element.remove();
  }
  target.insertAdjacentHTML('beforebegin', template(id, filename));
});

addEventListener('direct-upload:start', event => {
  const id = event.detail.id,
    element = getDirectUploadElement(id);

  element.classList.remove('direct-upload--pending');
  return false;
});

addEventListener('direct-upload:progress', event => {
  const { id, progress } = event.detail,
    progressElement = getDirectUploadProgressElement(id);

  progressElement.style.width = `${progress}%`;
});

addEventListener('direct-upload:error', event => {
  const { id, error } = event.detail,
    element = getDirectUploadElement(id);

  element.classList.add('direct-upload--error');
  element.setAttribute('title', error);
});

addEventListener('direct-upload:end', event => {
  const { id } = event.detail,
    element = getDirectUploadElement(id);

  element.classList.add('direct-upload--complete');
});

function template(id, filename) {
  return `<div id="direct-upload-${id}" class="direct-upload direct-upload--pending">
    <div class="direct-upload__progress" style="width: 0%"></div>
    <span class="direct-upload__filename">${filename}</span>
  </div>`;
}

function getDirectUploadElement(id) {
  return document.getElementById(`direct-upload-${id}`);
}

function getDirectUploadProgressElement(id) {
  return document.querySelector(
    `#direct-upload-${id} .direct-upload__progress`
  );
}
