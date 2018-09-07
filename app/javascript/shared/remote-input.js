import Rails from 'rails-ujs';
import debounce from 'debounce';

const { delegate, fire } = Rails;

const remote = 'data-remote';
const inputChangeSelector = `input[${remote}], textarea[${remote}]`;

// This is a patch for ujs remote handler. Its purpose is to add
// a debounced input listener.
function handleRemote(event) {
  const element = this;

  if (isRemote(element)) {
    fire(element, 'change', event);
  }
}

function isRemote(element) {
  const value = element.getAttribute(remote);
  return value && value !== 'false';
}

delegate(document, inputChangeSelector, 'input', debounce(handleRemote, 200));
