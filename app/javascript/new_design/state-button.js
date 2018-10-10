import { show, hide } from '@utils';

export function showMotivation(event, state) {
  event.preventDefault();
  show(document.querySelector(`.motivation.${state}`));
  hide(document.querySelector('.dropdown-items'));
}

export function motivationCancel() {
  document.querySelectorAll('.motivation').forEach(hide);
  show(document.querySelector('.dropdown-items'));
}
