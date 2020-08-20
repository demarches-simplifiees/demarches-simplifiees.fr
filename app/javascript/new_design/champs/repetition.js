import { delegate } from '@utils';

const CHAMP_SELECTOR = '.editable-champ';
const BUTTON_SELECTOR = '.button.remove-row';
const DESTROY_INPUT_SELECTOR = 'input[type=hidden][name*=_destroy]';
const DOM_ID_INPUT_SELECTOR = 'input[type=hidden][name*=deleted_row_dom_ids]'

delegate('click', BUTTON_SELECTOR, (evt) => {
  evt.preventDefault();

  const row = evt.target.closest('.row');

  for (let input of row.querySelectorAll(DESTROY_INPUT_SELECTOR)) {
    input.disabled = false;
    input.value = true;
  }
  row.querySelector(DOM_ID_INPUT_SELECTOR).disabled = false;

  for (let champ of row.querySelectorAll(CHAMP_SELECTOR)) {
    champ.remove();
  }

  evt.target.remove();
  row.classList.remove('row');
});
