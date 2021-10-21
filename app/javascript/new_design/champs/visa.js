import { delegate } from '@utils';

const VISA_SELECTOR = 'input[data-visa]';
const CHAMP_SELECTOR = '.editable-champ';

function freeze_field_above(visa) {
  const checked = visa.checked;
  const visibility = checked ? 'hidden' : 'visible';
  let champ = visa.closest(CHAMP_SELECTOR);
  while ((champ = champ.previousElementSibling)) {
    champ
      .querySelectorAll('input, select, button, textarea')
      .forEach((node) => (node.disabled = checked));
    champ
      .querySelectorAll('a.button')
      .forEach((node) => (node.style.visibility = visibility));
  }
}

delegate('change', VISA_SELECTOR, (evt) => {
  evt.target.closest('form').submit();
});

async function visa_initialize() {
  window.setTimeout(() => {
    let visas = document.querySelectorAll('input[data-visa]:checked');
    if (visas.length > 0) {
      let last_visa = visas[visas.length - 1];
      freeze_field_above(last_visa);
    }
  }, 1000);
}

addEventListener('DOMContentLoaded', visa_initialize);
