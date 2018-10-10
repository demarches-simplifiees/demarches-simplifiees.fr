import { show, hide, delegate } from '@utils';

function showSpinner() {
  [...document.querySelectorAll('.spinner')].forEach(show);
}

function hideSpinner() {
  [...document.querySelectorAll('.spinner')].forEach(hide);
}

delegate('ajax:complete', '[data-spinner]', hideSpinner);
delegate('ajax:stopped', '[data-spinner]', hideSpinner);
delegate('ajax:send', '[data-spinner]', showSpinner);
