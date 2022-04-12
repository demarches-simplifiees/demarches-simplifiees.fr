import { DirectUpload } from '@rails/activestorage';
import { ajax } from '@utils';
import ProgressBar from './progress-bar';
import FileUploadError, {
  errorFromDirectUploadMessage,
  ERROR_CODE_ATTACH
} from './file-upload-error';

/**
  Uploader class is a delegate for DirectUpload instance
  used to track lifecycle and progress of an upload.
  */
export default class Uploader {
  directUpload: DirectUpload;
  progressBar: ProgressBar;
  autoAttachUrl?: string;

  constructor(
    input: HTMLInputElement,
    file: File,
    directUploadUrl: string,
    autoAttachUrl?: string
  ) {
    this.directUpload = new DirectUpload(file, directUploadUrl, this);
    this.progressBar = new ProgressBar(input, this.directUpload.id + '', file);
    this.autoAttachUrl = autoAttachUrl;
  }

  /**
    Upload (and optionally attach) the file.
    Returns the blob signed id on success.
    Throws a FileUploadError on failure.
    */
  async start() {
    this.progressBar.start();

    try {
      const blobSignedId = await this._upload();

      if (this.autoAttachUrl) {
        await this._attach(blobSignedId, this.autoAttachUrl);
        // On response, the attachment HTML fragment will replace the progress bar.
      } else {
        this.progressBar.end();
        this.progressBar.destroy();
      }

      return blobSignedId;
    } catch (error) {
      this.progressBar.error((error as Error).message);
      throw error;
    }
  }

  /**
    Upload the file using the DirectUpload instance, and return the blob signed_id.
    Throws a FileUploadError on failure.
    */
  async _upload(): Promise<string> {
    return new Promise((resolve, reject) => {
      this.directUpload.create((errorMsg, attributes) => {
        if (errorMsg) {
          const error = errorFromDirectUploadMessage(errorMsg.message);
          reject(error);
        } else {
          resolve(attributes.signed_id);
        }
      });
    });
  }

  /**
    Attach the file by sending a POST request to the autoAttachUrl.
    Throws a FileUploadError on failure (containing the first validation
    error message, if any).
    */
  async _attach(blobSignedId: string, autoAttachUrl: string) {
    const attachmentRequest = {
      url: autoAttachUrl,
      type: 'PUT',
      data: `blob_signed_id=${blobSignedId}`
    };

    try {
      await ajax(attachmentRequest);
    } catch (e) {
      const error = e as {
        response?: { errors: string[] };
        xhr?: XMLHttpRequest;
      };
      const message = error.response?.errors && error.response.errors[0];
      throw new FileUploadError(
        message || 'Error attaching file.',
        error.xhr?.status,
        ERROR_CODE_ATTACH
      );
    }
  }

  uploadRequestDidProgress(event: ProgressEvent) {
    const progress = (event.loaded / event.total) * 100;
    if (progress) {
      this.progressBar.progress(progress);
    }
  }

  directUploadWillStoreFileWithXHR(xhr: XMLHttpRequest) {
    xhr.upload.addEventListener('progress', (event) =>
      this.uploadRequestDidProgress(event)
    );
  }
}
