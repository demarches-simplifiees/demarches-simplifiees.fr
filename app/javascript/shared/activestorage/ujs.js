import ProgressBar from './progress-bar';
import { fire } from '@utils';

const INITIALIZE_EVENT = 'direct-upload:initialize';
const START_EVENT = 'direct-upload:start';
const PROGRESS_EVENT = 'direct-upload:progress';
const ERROR_EVENT = 'direct-upload:error';
const END_EVENT = 'direct-upload:end';

function addUploadEventListener(type, handler) {
  addEventListener(type, event => {
    // Internet Explorer and Edge will sometime replay Javascript events
    // that were dispatched just before a page navigation (!), but without
    // the event payload.
    //
    // Ignore these replayed events.
    const isEventValid = event && event.detail && event.detail.id != undefined;
    if (!isEventValid) return;

    handler(event);
  });
}

addUploadEventListener(INITIALIZE_EVENT, ({ target, detail: { id, file } }) => {
  ProgressBar.init(target, id, file);
});

addUploadEventListener(START_EVENT, ({ target, detail: { id } }) => {
  ProgressBar.start(id);
  // At the end of the upload, the form will be submitted again.
  // Avoid the confirm dialog to be presented again then.
  const button = target.form.querySelector('button.primary');
  if (button) {
    button.removeAttribute('data-confirm');
  }
});

addUploadEventListener(PROGRESS_EVENT, ({ detail: { id, progress } }) => {
  ProgressBar.progress(id, progress);
});

addUploadEventListener(ERROR_EVENT, event => {
  // Display an error message
  alert(
    `Nous sommes désolés, une erreur s’est produite lors de l’envoi du fichier.

    (${event.detail.error})`
  );
  // Prevent ActiveStorage from displaying its own error message
  event.preventDefault();

  ProgressBar.error(event.detail.id, event.detail.error);
  fire(document, 'sentry:capture-exception', new Error(event.detail.error));
});

addUploadEventListener(END_EVENT, ({ detail: { id } }) => {
  ProgressBar.end(id);
});
