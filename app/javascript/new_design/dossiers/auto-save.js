import AutoSaveController from './auto-save-controller.js';
import {
  debounce,
  delegate,
  fire,
  enable,
  disable,
  hasClass,
  addClass,
  removeClass
} from '@utils';

const AUTOSAVE_DEBOUNCE_DELAY = gon.autosave.debounce_delay;
const AUTOSAVE_STATUS_VISIBLE_DURATION = gon.autosave.status_visible_duration;

// Create a controller responsible for queuing autosave operations.
const autoSaveController = new AutoSaveController();

function enqueueAutosaveRequest() {
  const form = document.querySelector(FORM_SELECTOR);
  autoSaveController.enqueueAutosaveRequest(form);
}

//
// Whenever a 'change' event is triggered on one of the form inputs, try to autosave.
//

const FORM_SELECTOR = 'form#dossier-edit-form.autosave-enabled';
const INPUTS_SELECTOR = `${FORM_SELECTOR} input:not([type=file]), ${FORM_SELECTOR} select, ${FORM_SELECTOR} textarea`;
const RETRY_BUTTON_SELECTOR = '.autosave-retry';

// When an autosave is requested programatically, auto-save the form immediately
addEventListener('autosave:trigger', (event) => {
  const form = event.target.closest('form');
  if (form && form.classList.contains('autosave-enabled')) {
    enqueueAutosaveRequest();
  }
});

// When the "Retry" button is clicked, auto-save the form immediately
delegate('click', RETRY_BUTTON_SELECTOR, enqueueAutosaveRequest);

// When an input changes, batches changes for N seconds, then auto-save the form
delegate(
  'change',
  INPUTS_SELECTOR,
  debounce(enqueueAutosaveRequest, AUTOSAVE_DEBOUNCE_DELAY)
);

//
// Display some UI during the autosave
//

addEventListener('autosave:enqueue', () => {
  disable(document.querySelector('button.autosave-retry'));
});

addEventListener('autosave:end', () => {
  enable(document.querySelector('button.autosave-retry'));
  setState('succeeded');
  hideSucceededStatusAfterDelay();
});

addEventListener('autosave:error', (event) => {
  enable(document.querySelector('button.autosave-retry'));
  setState('failed');
  logError(event.detail);
});

function setState(state) {
  const autosave = document.querySelector('.autosave');
  if (autosave) {
    // Re-apply the state even if already present, to get a nice animation
    removeClass(autosave, 'autosave-state-idle');
    removeClass(autosave, 'autosave-state-succeeded');
    removeClass(autosave, 'autosave-state-failed');
    autosave.offsetHeight; // flush animations
    addClass(autosave, `autosave-state-${state}`);
  }
}

function hideSucceededStatus() {
  const autosave = document.querySelector('.autosave');
  if (hasClass(autosave, 'autosave-state-succeeded')) {
    setState('idle');
  }
}
const hideSucceededStatusAfterDelay = debounce(
  hideSucceededStatus,
  AUTOSAVE_STATUS_VISIBLE_DURATION
);

function logError(error) {
  if (error && error.message) {
    error.message = `[Autosave] ${error.message}`;
    console.error(error);
    fire(document, 'sentry:capture-exception', error);
  }
}
