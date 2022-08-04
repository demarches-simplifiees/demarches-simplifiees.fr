import { DirectUpload } from '@rails/activestorage';

import ProgressBar from './progress-bar';
import {
  errorFromDirectUploadMessage,
  FileUploadError,
  ERROR_CODE_READ
} from './file-upload-error';

const BYTES_TO_MB_RATIO = 1_048_576;
/**
  Uploader class is a delegate for DirectUpload instance
  used to track lifecycle and progress of an upload.
  */
export default class Uploader {
  #directUpload: DirectUpload;
  #progressBar: ProgressBar;
  #maxFileSize: number;

  constructor(
    input: HTMLInputElement,
    file: File,
    directUploadUrl: string,
    maxFileSize?: string
  ) {
    this.#directUpload = new DirectUpload(file, directUploadUrl, this);
    this.#progressBar = new ProgressBar(
      input,
      `${this.#directUpload.id}`,
      file
    );
    try {
      this.#maxFileSize = parseInt(maxFileSize || '0', 10);
    } catch (e) {
      this.#maxFileSize = 0;
    }
  }

  /**
    Upload the file. Returns the blob signed id on success.
    Throws a FileUploadError on failure.
    */
  async start() {
    if (
      this.#maxFileSize > 0 &&
      this.#directUpload.file.size > this.#maxFileSize
    ) {
      const message = `La taille du fichier ne peut dépasser
      ${this.#maxFileSize / BYTES_TO_MB_RATIO} Mo
      (in english: File size can't be bigger than
      ${this.#maxFileSize / BYTES_TO_MB_RATIO} Mo).`;

      throw new FileUploadError(message, 0, ERROR_CODE_READ);
    }

    this.#progressBar.start();

    try {
      const blobSignedId = await this.upload();

      this.#progressBar.end();
      this.#progressBar.destroy();

      return blobSignedId;
    } catch (error) {
      this.#progressBar.error((error as Error).message);
      throw error;
    }
  }

  /**
    Upload the file using the DirectUpload instance, and return the blob signed_id.
    Throws a FileUploadError on failure.
    */
  private async upload(): Promise<string> {
    return new Promise((resolve, reject) => {
      this.#directUpload.create((errorMsg, attributes) => {
        if (errorMsg) {
          const error = errorFromDirectUploadMessage(errorMsg);
          reject(error);
        } else {
          resolve(attributes.signed_id);
        }
      });
    });
  }

  uploadRequestDidProgress(event: ProgressEvent) {
    const progress = (event.loaded / event.total) * 100;
    if (progress) {
      this.#progressBar.progress(progress);
    }
  }

  directUploadWillStoreFileWithXHR(xhr: XMLHttpRequest) {
    xhr.upload.addEventListener('progress', (event) =>
      this.uploadRequestDidProgress(event)
    );
  }
}
