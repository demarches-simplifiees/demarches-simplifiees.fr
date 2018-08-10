import { DirectUploadsController } from './direct_uploads_controller';
import { findElement } from './helpers';
import './progress';

// This is a patched copy of https://github.com/rails/rails/blob/master/activestorage/app/javascript/activestorage/ujs.js
// It fixes support for multiple input/button elements on direct upload forms

const processingAttribute = 'data-direct-uploads-processing';
let started = false;

export function start() {
  if (!started) {
    started = true;
    document.addEventListener('submit', didSubmitForm);
    document.addEventListener('click', didSubmitFormElement);
    document.addEventListener('ajax:before', didSubmitRemoteElement);
  }
}

export default { start };

function didSubmitForm(event) {
  handleFormSubmissionEvent(event);
}

function didSubmitFormElement(event) {
  const { target } = event;
  if (isSubmitElement(target)) {
    handleFormSubmissionEvent(formSubmitEvent(event), target);
  }
}

function didSubmitRemoteElement(event) {
  if (event.target.tagName == 'FORM') {
    handleFormSubmissionEvent(event);
  }
}

function formSubmitEvent(event) {
  return {
    target: event.target.form,
    preventDefault() {
      event.preventDefault();
    }
  };
}

function isSubmitElement({ tagName, type, form }) {
  if (form && (tagName === 'BUTTON' || tagName === 'INPUT')) {
    return type === 'submit';
  }
  return false;
}

function handleFormSubmissionEvent(event, button) {
  const form = event.target;

  if (form.hasAttribute(processingAttribute)) {
    event.preventDefault();
    return;
  }

  const controller = new DirectUploadsController(form);
  const { inputs } = controller;

  if (inputs.length) {
    event.preventDefault();
    form.setAttribute(processingAttribute, '');
    inputs.forEach(disable);
    controller.start(error => {
      form.removeAttribute(processingAttribute);
      if (error) {
        inputs.forEach(enable);
      } else {
        submitForm(form, button);
      }
    });
  }
}

function submitForm(form, button) {
  button = button || findElement(form, 'input[type=submit]');
  if (button) {
    const { disabled } = button;
    button.disabled = false;
    button.focus();
    button.click();
    button.disabled = disabled;
  } else {
    button = document.createElement('input');
    button.type = 'submit';
    button.style.display = 'none';
    form.appendChild(button);
    button.click();
    form.removeChild(button);
  }
}

function disable(input) {
  input.disabled = true;
}

function enable(input) {
  input.disabled = false;
}
