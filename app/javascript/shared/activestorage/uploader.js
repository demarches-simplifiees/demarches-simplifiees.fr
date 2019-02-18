import { DirectUpload } from 'activestorage';
import ProgressBar from './progress-bar';

/**
  Uploader class is a delegate for DirectUpload instance
  used to track lifecycle and progress of un upload.
  */
export default class Uploader {
  constructor(input, file, directUploadUrl) {
    this.directUpload = new DirectUpload(file, directUploadUrl, this);
    this.progressBar = new ProgressBar(input, this.directUpload.id, file);
  }

  start() {
    this.progressBar.start();

    return new Promise((resolve, reject) => {
      this.directUpload.create((error, attributes) => {
        if (error) {
          this.progressBar.error(error);
          reject(error);
        } else {
          resolve(attributes.signed_id);
        }
        this.progressBar.end();
        this.progressBar.destroy();
      });
    });
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
