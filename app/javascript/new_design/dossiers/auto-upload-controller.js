import Uploader from '../../shared/activestorage/uploader';
import { show, hide, toggle } from '@utils';

// Given a file input in a champ with a selected file, upload a file,
// then attach it to the dossier.
//
// On success, the champ is replaced by an HTML fragment describing the attachment.
// On error, a error message is displayed above the input.
export default class AutoUploadController {
  constructor(input, file) {
    this.input = input;
    this.file = file;
    this.uploader = new Uploader(
      input,
      file,
      input.dataset.directUploadUrl,
      input.dataset.autoAttachUrl
    );
  }

  async start() {
    try {
      this._begin();
      await this.uploader.start();
      this._succeeded();
    } catch (error) {
      this._failed(error);
      throw error;
    } finally {
      this._done();
    }
  }

  _begin() {
    this.input.disabled = true;
    this._hideErrorMessage();
  }

  _succeeded() {
    this.input.value = null;
  }

  _failed(error) {
    if (!document.body.contains(this.input)) {
      return;
    }

    this.uploader.progressBar.destroy();

    let message = this._messageFromError(error);
    this._displayErrorMessage(message);
  }

  _done() {
    this.input.disabled = false;
  }

  _isError422(error) {
    // Ajax errors have an xhr attribute
    if (error && error.xhr && error.xhr.status == 422) return true;
    // Rails DirectUpload errors are returned as a String, e.g. 'Error creating Blob for "Demain.txt". Status: 422'
    if (error && error.toString().includes('422')) return true;

    return false;
  }

  _messageFromError(error) {
    let allowRetry = !this._isError422(error);

    if (
      error.xhr &&
      error.xhr.status == 422 &&
      error.response &&
      error.response.errors &&
      error.response.errors[0]
    ) {
      return {
        title: error.response.errors[0],
        description: '',
        retry: allowRetry
      };
    } else {
      return {
        title: 'Une erreur s’est produite pendant l’envoi du fichier.',
        description: error.message || error.toString(),
        retry: allowRetry
      };
    }
  }

  _displayErrorMessage(message) {
    let errorNode = this.input.parentElement.querySelector('.attachment-error');
    if (errorNode) {
      show(errorNode);
      errorNode.querySelector('.attachment-error-title').textContent =
        message.title || '';
      errorNode.querySelector('.attachment-error-description').textContent =
        message.description || '';
      toggle(errorNode.querySelector('.attachment-error-retry'), message.retry);
    }
  }

  _hideErrorMessage() {
    let errorElement = this.input.parentElement.querySelector(
      '.attachment-error'
    );
    if (errorElement) {
      hide(errorElement);
    }
  }
}
