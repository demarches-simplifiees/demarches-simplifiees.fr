import Rails from 'rails-ujs';
import { show, hide } from '../shared/utils';

const { delegate } = Rails;

function showSpinner() {
  [...document.querySelectorAll('.spinner')].forEach(show);
}

function hideSpinner() {
  [...document.querySelectorAll('.spinner')].forEach(hide);
}

delegate(document, '[data-spinner]', 'ajax:complete', hideSpinner);
delegate(document, '[data-spinner]', 'ajax:stopped', hideSpinner);
delegate(document, '[data-spinner]', 'ajax:send', showSpinner);
