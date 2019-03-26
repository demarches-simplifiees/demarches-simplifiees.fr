import { show, hide, delegate } from '@utils';

delegate('change', '#contact-form #type', event => {
  const type = event.target.value;
  const answer = document.querySelector(`[data-answer="${type}"]`);
  const card = document.querySelector('.support.card');

  for (let element of document.querySelectorAll('.card-content')) {
    hide(element);
  }

  if (answer) {
    show(card);
    show(answer);
  } else {
    hide(card);
  }
});
