import Uploader from '../../shared/activestorage/uploader';
import { show, hide, toggle } from '@utils';
import {
  ERROR_CODE_READ,
  FAILURE_CONNECTIVITY
} from '../../shared/activestorage/file-upload-error';

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

  // Create, upload and attach the file.
  // On failure, display an error message and throw a FileUploadError.
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

  _messageFromError(error) {
    let message = error.message || error.toString();
    let canRetry = error.status && error.status != 422;

    if (error.failureReason == FAILURE_CONNECTIVITY) {
      return {
        title: 'Le fichier n’a pas pu être envoyé.',
        description: 'Vérifiez votre connexion à Internet, puis ré-essayez.',
        retry: true
      };
    } else if (error.code == ERROR_CODE_READ) {
      return {
        title: 'Nous n’arrivons pas à lire ce fichier sur votre appareil.',
        description: 'Essayez à nouveau, ou sélectionnez un autre fichier.',
        retry: false
      };
    } else {
      return {
        title: 'Le fichier n’a pas pu être envoyé.',
        description: message,
        retry: canRetry
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
