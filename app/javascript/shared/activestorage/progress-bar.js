const PENDING_CLASS = 'direct-upload--pending';
const ERROR_CLASS = 'direct-upload--error';
const COMPLETE_CLASS = 'direct-upload--complete';

/**
  ProgressBar is and utility class responsible for
  rendering upload progress bar. It is used to handle
  direct-upload form ujs events but also in the
  Uploader delegate used with uploads on json api.

  As the associated DOM element may disappear for some
  reason (a dynamic React list, an element being removed
  and recreated again later, etc.), this class doesn't
  raise any error if the associated DOM element cannot
  be found.
  */
export default class ProgressBar {
  static init(input, id, file) {
    clearErrors(input);
    const html = this.render(id, file.name);
    input.insertAdjacentHTML('beforebegin', html);
  }

  static start(id) {
    const element = getDirectUploadElement(id);
    if (element) {
      element.classList.remove(PENDING_CLASS);
    }
  }

  static progress(id, progress) {
    const element = getDirectUploadProgressElement(id);
    if (element) {
      element.style.width = `${progress}%`;
    }
  }

  static error(id, error) {
    const element = getDirectUploadElement(id);
    if (element) {
      element.classList.add(ERROR_CLASS);
      element.setAttribute('title', error);
    }
  }

  static end(id) {
    const element = getDirectUploadElement(id);
    if (element) {
      element.classList.add(COMPLETE_CLASS);
    }
  }

  static render(id, filename) {
    return `<div id="direct-upload-${id}" class="direct-upload ${PENDING_CLASS}" data-direct-upload-id="${id}">
      <div class="direct-upload__progress" style="width: 0%"></div>
      <span class="direct-upload__filename">${filename}</span>
    </div>`;
  }

  constructor(input, id, file) {
    this.constructor.init(input, id, file);
    this.id = id;
  }

  start() {
    this.constructor.start(this.id);
  }

  progress(progress) {
    this.constructor.progress(this.id, progress);
  }

  error(error) {
    this.constructor.error(this.id, error);
  }

  end() {
    this.constructor.end(this.id);
  }

  destroy() {
    const element = getDirectUploadElement(this.id);
    element.remove();
  }
}

function clearErrors(input) {
  const errorElements = input.parentElement.querySelectorAll(`.${ERROR_CLASS}`);
  for (let element of errorElements) {
    element.remove();
  }
}

function getDirectUploadElement(id) {
  return document.getElementById(`direct-upload-${id}`);
}

function getDirectUploadProgressElement(id) {
  return document.querySelector(
    `#direct-upload-${id} .direct-upload__progress`
  );
}
