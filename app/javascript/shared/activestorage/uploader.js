import { DirectUpload } from '@rails/activestorage';
import { ajax } from '@utils';
import ProgressBar from './progress-bar';
import errorFromDirectUploadMessage from './errors';

/**
  Uploader class is a delegate for DirectUpload instance
  used to track lifecycle and progress of an upload.
  */
export default class Uploader {
  constructor(input, file, directUploadUrl, autoAttachUrl) {
    this.directUpload = new DirectUpload(file, directUploadUrl, this);
    this.progressBar = new ProgressBar(input, this.directUpload.id, file);
    this.autoAttachUrl = autoAttachUrl;
  }

  /**
    Upload (and optionally attach) the file.
    Returns the blob signed id on success.
    */
  async start() {
    this.progressBar.start();

    try {
      let blobSignedId = await this._upload();

      if (this.autoAttachUrl) {
        await this._attach(blobSignedId);
      }

      this.progressBar.end();
      this.progressBar.destroy();

      return blobSignedId;
    } catch (error) {
      this.progressBar.error(error.message);
      throw error;
    }
  }

  /**
    Upload the file using the DirectUpload instance, and return the blob signed_id.
    */
  async _upload() {
    return new Promise((resolve, reject) => {
      this.directUpload.create((errorMsg, attributes) => {
        if (errorMsg) {
          let error = errorFromDirectUploadMessage(errorMsg);
          reject(error);
        } else {
          resolve(attributes.signed_id);
        }
      });
    });
  }

  /**
    Attach the file by sending a POST request to the autoAttachUrl.
    */
  async _attach(blobSignedId) {
    const attachmentRequest = {
      url: this.autoAttachUrl,
      type: 'PUT',
      data: `blob_signed_id=${blobSignedId}`
    };

    await ajax(attachmentRequest);
  }

  uploadRequestDidProgress(event) {
    const progress = (event.loaded / event.total) * 100;
    if (progress) {
      this.progressBar.progress(progress);
    }
  }

  directUploadWillStoreFileWithXHR(xhr) {
    xhr.upload.addEventListener('progress', event =>
      this.uploadRequestDidProgress(event)
    );
  }
}
