import Uploader from '../../shared/activestorage/uploader';
import ProgressBar from '../../shared/activestorage/progress-bar';
import { ajax, show, hide, toggle } from '@utils';

// Given a file input in a champ with a selected file, upload a file,
// then attach it to the dossier.
//
// On success, the champ is replaced by an HTML fragment describing the attachment.
// On error, a error message is displayed above the input.
export default class AutoUploadController {
  constructor(input, file) {
    this.input = input;
    this.file = file;
  }

  async start() {
    try {
      this._begin();

      // Sanity checks
      const autoAttachUrl = this.input.dataset.autoAttachUrl;
      if (!autoAttachUrl) {
        throw new Error('L’attribut "data-auto-attach-url" est manquant');
      }

      const champ = this.input.closest('.editable-champ[data-champ-id]');
      if (!champ) {
        throw new Error('Impossible de trouver l’élément ".editable-champ"');
      }
      const champId = champ.dataset.champId;

      // Upload the file (using Direct Upload)
      let blobSignedId = await this._upload();

      // Attach the blob to the champ
      // (The request responds with Javascript, which displays the attachment HTML fragment).
      await this._attach(champId, blobSignedId, autoAttachUrl);

      // Everything good: clear the original file input value
      this.input.value = null;
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

  async _upload() {
    const uploader = new Uploader(
      this.input,
      this.file,
      this.input.dataset.directUploadUrl
    );
    return await uploader.start();
  }

  async _attach(champId, blobSignedId, autoAttachUrl) {
    // Now that the upload is done, display a new progress bar
    // to show that the attachment request is still pending.
    const progressBar = new ProgressBar(this.input, champId, this.file);
    progressBar.progress(100);
    progressBar.end();

    const attachmentRequest = {
      url: autoAttachUrl,
      type: 'PUT',
      data: `blob_signed_id=${blobSignedId}`
    };
    await ajax(attachmentRequest);

    // The progress bar has been destroyed by the attachment HTML fragment that replaced the input,
    // so no further cleanup is needed.
  }

  _failed(error) {
    if (!document.body.contains(this.input)) {
      return;
    }

    let progressBar = this.input.parentElement.querySelector('.direct-upload');
    if (progressBar) {
      progressBar.remove();
    }

    this._displayErrorMessage(error);
  }

  _done() {
    this.input.disabled = false;
  }

  _messageFromError(error) {
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
        retry: false
      };
    } else {
      return {
        title: 'Une erreur s’est produite pendant l’envoi du fichier.',
        description: error.message || error.toString(),
        retry: true
      };
    }
  }

  _displayErrorMessage(error) {
    let errorNode = this.input.parentElement.querySelector('.attachment-error');
    if (errorNode) {
      show(errorNode);
      let message = this._messageFromError(error);
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
