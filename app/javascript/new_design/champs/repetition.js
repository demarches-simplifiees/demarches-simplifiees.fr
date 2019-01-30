import { delegate } from '@utils';

const BUTTON_SELECTOR = '.button.remove-row';
const DESTROY_INPUT_SELECTOR = 'input[type=hidden][name*=_destroy]';
const CHAMP_SELECTOR = '.editable-champ';

addEventListener('turbolinks:load', () => {
  delegate('click', BUTTON_SELECTOR, evt => {
    evt.preventDefault();

    const row = evt.target.closest('.row');

    for (let input of row.querySelectorAll(DESTROY_INPUT_SELECTOR)) {
      input.disabled = false;
      input.value = true;
    }
    for (let champ of row.querySelectorAll(CHAMP_SELECTOR)) {
      champ.remove();
    }

    evt.target.remove();
    row.classList.remove('row');
  });
});
