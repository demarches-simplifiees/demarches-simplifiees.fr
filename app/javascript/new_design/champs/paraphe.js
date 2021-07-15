import { delegate } from '@utils';

const PARAPHE_SELECTOR = 'input[data-paraphe]';
const CHAMP_SELECTOR = '.editable-champ';

function freeze_field_above(paraphe) {
  const checked = paraphe.checked;
  const visibility = checked ? 'hidden' : 'visible';
  let champ = paraphe.closest(CHAMP_SELECTOR);
  while ((champ = champ.previousElementSibling)) {
    champ
      .querySelectorAll('input, select, button, textarea')
      .forEach((node) => (node.disabled = checked));
    champ
      .querySelectorAll('a.button')
      .forEach((node) => (node.style.visibility = visibility));
  }
}

delegate('change', PARAPHE_SELECTOR, (evt) => {
  evt.target.closest('form').submit();
});

async function paraphe_initialize() {
  window.setTimeout(() => {
    let paraphes = document.querySelectorAll('input[data-paraphe]:checked');
    if (paraphes.length > 0) {
      let last_paraphe = paraphes[paraphes.length - 1];
      freeze_field_above(last_paraphe);
    }
  }, 1000)
}

addEventListener('DOMContentLoaded', paraphe_initialize);
