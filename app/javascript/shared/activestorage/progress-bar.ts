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
  static init(input: HTMLInputElement, id: string, file: File) {
    clearErrors(input);
    const html = this.render(id, file.name);
    input.insertAdjacentHTML('beforebegin', html);
  }

  static start(id: string) {
    const element = getDirectUploadElement(id);
    if (element) {
      element.classList.remove(PENDING_CLASS);
      element.focus();
    }
  }

  static progress(id: string, progress: number) {
    const element = getDirectUploadProgressElement(id);
    if (element) {
      element.style.width = `${progress}%`;
      element.setAttribute('aria-valuenow', `${progress}`);
    }
  }

  static error(id: string, error: string) {
    const element = getDirectUploadElement(id);
    if (element) {
      element.classList.add(ERROR_CLASS);
      element.setAttribute('title', error);
    }
  }

  static end(id: string) {
    const element = getDirectUploadElement(id);
    if (element) {
      element.classList.add(COMPLETE_CLASS);
    }
  }

  static render(id: string, filename: string) {
    return `<div id="direct-upload-${id}" class="direct-upload ${PENDING_CLASS}" data-direct-upload-id="${id}">
      <div role="progressbar" aria-label="Chargement de fichier" tabindex="0" max="100" aria-valuemin="0" aria-valuemax="100" class="direct-upload__progress" style="width: 0%"></div>
      <span class="direct-upload__filename">${filename}</span>
    </div>`;
  }

  id: string;

  constructor(input: HTMLInputElement, id: string, file: File) {
    ProgressBar.init(input, id, file);
    this.id = id;
  }

  start() {
    ProgressBar.start(this.id);
  }

  progress(progress: number) {
    ProgressBar.progress(this.id, progress);
  }

  error(error: string) {
    ProgressBar.error(this.id, error);
  }

  end() {
    ProgressBar.end(this.id);
  }

  destroy() {
    const element = getDirectUploadElement(this.id);
    element?.remove();
  }
}

function clearErrors(input: HTMLInputElement) {
  const errorElements =
    input.parentElement?.querySelectorAll(`.${ERROR_CLASS}`) ?? [];
  for (const element of errorElements) {
    element.remove();
  }
}

function getDirectUploadElement(id: string) {
  return document.querySelector<HTMLDivElement>(`#direct-upload-${id}`);
}

function getDirectUploadProgressElement(id: string) {
  return document.querySelector<HTMLDivElement>(
    `#direct-upload-${id} .direct-upload__progress`
  );
}
