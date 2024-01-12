import invariant from 'tiny-invariant';
import { show, hide, toggle } from '@utils';

import Uploader from './uploader';
import {
  FileUploadError,
  ERROR_CODE_READ,
  FAILURE_CONNECTIVITY
} from './file-upload-error';

type ErrorMessage = {
  title: string;
  retry: boolean;
};

// Given a file input in a champ with a selected file, upload a file,
// then attach it to the dossier.
//
// On success, the champ is replaced by an HTML fragment describing the attachment.
// On error, a error message is displayed above the input.
export class AutoUpload {
  #input: HTMLInputElement;
  #uploader: Uploader;

  constructor(input: HTMLInputElement, file: File) {
    const { directUploadUrl, autoAttachUrl, maxFileSize } = input.dataset;
    invariant(directUploadUrl, 'Could not find the direct upload URL.');
    this.#input = input;
    this.#uploader = new Uploader(
      input,
      file,
      directUploadUrl,
      autoAttachUrl,
      maxFileSize
    );
  }

  // Create, upload and attach the file.
  // On failure, display an error message and throw a FileUploadError.
  async start() {
    try {
      this.begin();
      await this.#uploader.start();
      this.succeeded();
    } catch (error) {
      this.failed(error as FileUploadError);
      throw error;
    } finally {
      this.done();
    }
  }

  private begin() {
    this.#input.disabled = true;
    this.hideErrorMessage();
  }

  private succeeded() {
    this.#input.value = '';
  }

  private failed(error: FileUploadError) {
    if (!document.body.contains(this.#input)) {
      return;
    }

    this.#uploader.progressBar.destroy();

    const message = this.messageFromError(error);
    this.displayErrorMessage(message);

    this.#input.classList.toggle('fr-text-default--error', true);
  }

  private done() {
    this.#input.disabled = false;
  }

  private messageFromError(error: FileUploadError): ErrorMessage {
    const message = error.message || error.toString();
    const canRetry = error.status && error.status != 422;

    if (error.failureReason == FAILURE_CONNECTIVITY) {
      return {
        title:
          'Le fichier n’a pas pu être envoyé. Vérifiez votre connexion à Internet, puis ré-essayez. Vérifiez aussi que le pare-feu de votre appareil ou votre réseau autorise l’envoi de fichier vers ' +
          window.location.host +
          ' et static.demarches-simplifiees.fr.',
        retry: true
      };
    } else if (error.code == ERROR_CODE_READ) {
      return {
        title:
          'Nous n’arrivons pas à lire ce fichier sur votre appareil. Essayez à nouveau, ou sélectionnez un autre fichier.',
        retry: false
      };
    } else {
      return {
        title: message,
        retry: !!canRetry
      };
    }
  }

  private displayErrorMessage(message: ErrorMessage) {
    const errorElement = this.errorElement;
    if (errorElement) {
      show(errorElement);
      this.errorTitleElement.textContent = message.title || '';
      toggle(this.errorRetryButton, message.retry);
    }
  }

  private hideErrorMessage() {
    const errorElement = this.errorElement;
    if (errorElement) {
      hide(errorElement);
    }
  }

  get errorElement() {
    return this.#input
      .closest('.attachment')
      ?.querySelector<HTMLElement>('.attachment-upload-error');
  }

  get errorTitleElement() {
    const element =
      this.errorElement?.querySelector<HTMLElement>('.fr-error-text');
    invariant(element, 'Could not find the error title element.');
    return element;
  }

  get errorRetryButton() {
    const element = this.errorElement?.querySelector<HTMLButtonElement>(
      '.attachment-upload-error-retry'
    );
    invariant(element, 'Could not find the error retry button element.');
    return element;
  }
}
