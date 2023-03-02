import { show, hide } from '@utils';

export function showMotivation(event, state) {
  event.preventDefault();
  motivationCancel();
  show(document.querySelector(`.motivation.${state}`));
  hide(document.querySelector('.dropdown-items'));
}

export function motivationCancel() {
  document.querySelectorAll('.motivation').forEach(hide);
  show(document.querySelector('.dropdown-items'));
}

export function showImportJustificatif(name) {
  show(document.querySelector('#justificatif_motivation_import_' + name));
  hide(document.querySelector('#justificatif_motivation_suggest_' + name));
}
