import AutosaveController from './autosave-controller.js';
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
const autosaveController = new AutosaveController();

// Whenever a 'change' event is triggered on one of the form inputs, try to autosave.

const formSelector = 'form#dossier-edit-form.autosave-enabled';
const formInputsSelector = `${formSelector} input:not([type=input]), ${formSelector} select, ${formSelector} textarea`;

delegate(
  'change',
  formInputsSelector,
  debounce(() => {
    const form = document.querySelector(formSelector);
    autosaveController.enqueueAutosaveRequest(form);
  }, AUTOSAVE_DEBOUNCE_DELAY)
);

delegate('click', '.autosave-retry', () => {
  const form = document.querySelector(formSelector);
  autosaveController.enqueueAutosaveRequest(form);
});

// Display some UI during the autosave

addEventListener('autosave:enqueue', () => {
  disable(document.querySelector('button.autosave-retry'));
});

addEventListener('autosave:end', () => {
  enable(document.querySelector('button.autosave-retry'));
  setState('succeeded');
  hideSucceededStatusAfterDelay();
});

addEventListener('autosave:error', event => {
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
